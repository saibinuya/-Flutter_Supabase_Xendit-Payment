import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ilagay dito ang iyong BAGONG Supabase Project URL at Anon Key
  await Supabase.initialize(
    url: 'https://lsuewmygkauwgwfnxzgo.supabase.co',
    anonKey: 'sb_publishable_CvmNSkAySK3u5oww4n1h3w_dTiwbBmR',
  );

  runApp(const DogFoodApp());
}

class DogFoodApp extends StatelessWidget {
  const DogFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bark & Bites Dog Food Store',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.brown[50],
      ),
      home: const ProductCatalogScreen(),
    );
  }
}

class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Premium Puppy Dry Kibbles (3kg)', 'price': 650.0, 'icon': Icons.pets},
      {'name': 'Grain-Free Adult Dog Food (5kg)', 'price': 1200.0, 'icon': Icons.set_meal},
      {'name': 'Organic Salmon Dog Treats (500g)', 'price': 350.0, 'icon': Icons.cookie},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐶 Bark & Bites Dog Food Store'),
        backgroundColor: Colors.brown[700],
        elevation: 2,
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.brown[100],
                child: Icon(item['icon'] as IconData, color: Colors.brown[800]),
              ),
              title: Text(
                item['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '₱${(item['price'] as double).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.brown[600], fontSize: 15, fontWeight: FontWeight.w600),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
    // Ilagay dito ang iyong Xendit Secret API Key
    const apiKey = 'xnd_development_F7bHMvShsQ5auhlihiFlJtn2ebhpdQETntbEa56GwALLlo6qGweoNcM9R9MaU6MH';
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
          'description': 'Payment for Dog Food Order $orderId',
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
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: Colors.brown[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selected Item:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(widget.productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  const Text('Total Amount:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('₱${widget.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, color: Colors.brown[800], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Spacer(),
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.brown))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      setState(() => isLoading = true);
                      String orderId = 'dog_order_${DateTime.now().millisecondsSinceEpoch}';
                      
                      try {
                        // I-save sa iyong bagong Supabase orders table
                        await Supabase.instance.client.from('orders').insert({
                          'order_id': orderId,
                          'product': widget.productName,
                          'amount': widget.amount,
                          'status': 'PENDING',
                        });
                      } catch (dbError) {
                        print('Supabase Insert Error: $dbError');
                      }

                      // Tawagin ang Xendit Payment Gateway
                      await createXenditPayment(orderId, widget.amount);

                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    },
                    child: const Text('Proceed to GCash / Xendit Payment', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}