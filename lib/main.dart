import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://npgllbayatxvptaftfti.supabase.co',
    anonKey: 'sb_publishable_iVtphsgA3F1bhqPfaSv8_A_88xFm-o0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clothing App Store',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ProductCatalogScreen(),
    );
  }
}

class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Oversized Streetwear Hoodie', 'price': 1200.0},
      {'name': 'Cargo Pants with Multiple Pockets', 'price': 950.0},
      {'name': 'Minimalist Graphic Crewneck', 'price': 750.0},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Clothing App Store')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(item['name'] as String),
              subtitle: Text('₱${item['price']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        productName: item['name'] as String,
                        amount: item['price'] as double,
                      ),
                    ),
                  );
                },
                child: const Text('Buy Now'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.productName, required this.amount});
  
  final String productName;
  final double amount;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isLoading = false;

  Future<void> createXenditPayment(String orderId, double amount) async {
    const apiKey = 'xnd_development_jCN6vxTy1GrEiqLEGQJlj7CzArZkAxLBmfRctrtBio0AKZk3RdjlORUA38qFmZ';
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$apiKey:'));

    try {
      final response = await http.post(
        Uri.parse('https://api.xendit.co/v2/invoices'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id': orderId,
          'amount': amount,
          'currency': 'PHP',
          'description': 'Payment for Clothing App Order $orderId',
          'payment_methods': ['GCASH', 'GRABPAY', 'PAYMAYA'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final invoiceUrl = data['invoice_url'];
        
        if (await canLaunchUrl(Uri.parse(invoiceUrl))) {
          await launchUrl(Uri.parse(invoiceUrl), mode: LaunchMode.externalApplication);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xendit Error: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Amount: ₱${widget.amount}', style: const TextStyle(fontSize: 20, color: Colors.indigo)),
            const Spacer(),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: () async {
                      setState(() => isLoading = true);
                      String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
                      
                      try {
                        // 1. I-save muna sa Supabase bilang PENDING order
                        await Supabase.instance.client.from('orders').insert({
                          'order_id': orderId,
                          'product': widget.productName,
                          'amount': widget.amount,
                          'status': 'PENDING',
                        });
                      } catch (dbError) {
                        print('Supabase Insert Error: $dbError');
                      }

                      // 2. Tawagin ang Xendit Payment Gateway
                      await createXenditPayment(orderId, widget.amount);

                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    },
                    child: const Text('Proceed to GCash / Xendit Payment'),
                  ),
          ],
        ),
      ),
    );
  }
}