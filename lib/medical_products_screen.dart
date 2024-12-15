import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;
import 'checkout_screen.dart';

class MedicalProductsScreen extends StatefulWidget {
  const MedicalProductsScreen({super.key});

  @override
  _MedicalProductsScreenState createState() => _MedicalProductsScreenState();
}

class _MedicalProductsScreenState extends State<MedicalProductsScreen> {
  List<Map<String, String>> products = [];

  @override
  void initState() {
    super.initState();
    loadProductData();
  }

  Future<void> loadProductData() async {
    try {
      // Load the XML file from the assets
      final xmlString = await rootBundle.loadString('assets/icons/ProductCatelog.xml');

      // Parse the XML
      final xml.XmlDocument document = xml.XmlDocument.parse(xmlString);

      // Extract the products (medicines) from the XML
      final medicines = document.findAllElements('medicine').map((element) {
        return {
          'name': element.getElement('name')?.text ?? 'Unknown',
          'description': element.getElement('description')?.text ?? 'No description',
          'image': element
              .getElement('image')
              ?.text
              .replaceAll('[img]', '')
              .replaceAll('[/img]', '') ?? '',
          'price': element.getElement('price')?.text ?? '0.00',
        };
      }).toList();

      // Update the state with the loaded products
      setState(() {
        products = medicines;
      });
    } catch (e) {
      print("Error loading XML data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medical Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: products.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Loading indicator
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Three items per row
                  childAspectRatio: 0.65, // Aspect ratio of each grid item
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          product['image']!, // Use network image from XML
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product['name']!, // Product name
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product['description']!, // Product description
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '\$${product['price']}', // Product price
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to CheckoutScreen and pass the product details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutScreen(),
                                settings: RouteSettings(
                                  arguments: product, // Passing product details
                                ),
                              ),
                            );
                          },
                          child: const Text('Buy'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
