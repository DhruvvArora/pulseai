import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _creditCardNumber = '';

  void _submitOrder(Map<String, dynamic> medicine) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Prepare order data
      final orderData = {
        "name": _name,
        "address": _address,
        "creditCardNumber": _creditCardNumber,
        "medicine": {
          "name": medicine['name'],
          "price": medicine['price'],
          "image": medicine['image'],
        },
      };

      try {
        // Send order data to the backend
        final response = await http.post(
          Uri.parse("http://127.0.0.1:5000/submit_order/"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(orderData),
        );

        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          final orderNumber = responseData['orderNumber'];

          // Navigate to the Order Confirmation Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                name: _name,
                address: _address,
                creditCardNumber: _creditCardNumber,
                orderNumber: int.parse(orderNumber),
              ),
            ),
          );
        } else {
          // Handle errors
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: const Text("Failed to submit the order. Please try again."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print("Error submitting order: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get medicine data passed via arguments
    final medicine = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row to display the medicine details and image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image aligned on the left
                Image.network(
                  medicine['image']!,
                  width: 100, // Set the width to make the image smaller
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 16), // Space between image and text
                // Text content on the right of the image
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are buying: ${medicine['name']}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('Price: \$${medicine['price']}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form to enter details
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _name = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Shipping Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _address = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Credit Card Number'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 16) {
                        return 'Please enter a valid 16-digit credit card number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _creditCardNumber = value!;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _submitOrder(medicine),
                    child: const Text('Submit Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final String name;
  final String address;
  final String creditCardNumber;
  final int orderNumber;

  const OrderConfirmationScreen({super.key, 
    required this.name,
    required this.address,
    required this.creditCardNumber,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Thank you for your order, $name!', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Order Number: $orderNumber'),
            const SizedBox(height: 10),
            Text('Shipping to: $address'),
            const SizedBox(height: 10),
            Text('Payment made with card ending in: ${creditCardNumber.substring(12)}'), // Display last 4 digits
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
