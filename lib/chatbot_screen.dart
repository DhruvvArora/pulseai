import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final String _apiUrl = 'http://127.0.0.1:5000/recommendation/';

  String? _selectedImagePath;
  Uint8List? _webImage;
  bool get isWeb => kIsWeb;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (isWeb) {
      final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;
      if (input.files?.isNotEmpty ?? false) {
        final file = input.files![0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        
        setState(() {
          _webImage = base64Decode(reader.result.toString().split(',')[1]);
          _selectedImagePath = file.name;
        });
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _webImage = imageBytes;
          _selectedImagePath = image.path;
        });
      }
    }
  }

  Future<void> _sendMessageToBackend(String message) async {
    final currentImageData = _webImage;
    
    setState(() {
      _messages.add({
        'role': 'user', 
        'content': message,
        'imagePath': _selectedImagePath,
        'imageData': currentImageData,
      });
    });

    try {
      Map<String, dynamic> requestBody = {'message': message};
      
      if (currentImageData != null) {
        final base64Image = base64Encode(currentImageData);
        requestBody['image'] = base64Image;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var aiResponse = data['response']['summary'] ?? 'No summary available.';
        bool hasSummary = data['response']['summary'] != null;

        if ((aiResponse is String) && hasSummary) {
          aiResponse = aiResponse.replaceAll(RegExp(r'```json|```'), '').trim();
          aiResponse = json.decode(aiResponse);

          final List medicines = aiResponse['medicines'] ?? [];
          final String note = aiResponse['disclaimer'] ?? '';

          if (medicines.isEmpty) {
            setState(() {
              _messages.add({'role': 'assistant', 'content': aiResponse['message']});
            });
          } else {
            setState(() {
              _messages.add({
                'role': 'assistant',
                'content': aiResponse['message'],
                'medicines': medicines,
                'note': note,
              });
            });
          }
        } else {
          var aiResponse = data['response'] ?? 'No response available.';
          setState(() {
            _messages.add({'role': 'assistant', 'content': aiResponse['message']});
          });
        }
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: Unable to connect to backend.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: Failed to send message.'});
      });
    } finally {
      setState(() {
        _selectedImagePath = null;
        _webImage = null;
      });
    }
  }

  void _handleSendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _controller.clear();
      _sendMessageToBackend(message);
      _focusNode.requestFocus();
    }
  }

  void _buyMedicine(Map<String, dynamic> medicine) {
    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: medicine,
    );
  }

  Widget _buildImagePreview() {
    if (_webImage == null) return const SizedBox.shrink();

    return Container(
      height: 80,
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _webImage!,
              fit: BoxFit.cover,
              width: 120,
              height: 80,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            iconSize: 20,
            onPressed: () => setState(() => _webImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageImage(Map<String, dynamic> message) {
    if (message['imageData'] == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      width: 120,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          message['imageData'],
          fit: BoxFit.cover,
          width: 120,
          height: 80,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Health Assistant'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                if (message['role'] == 'assistant') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: SelectableText(
                            message['content']!,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      if (message['medicines'] != null && message['medicines'].isNotEmpty)
                        ...message['medicines'].map<Widget>((medicine) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.5,
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                title: SelectableText(medicine['name']),
                                subtitle: SelectableText("Price: \$${medicine['price']}"),
                                leading: (medicine['image'] != null && medicine['image'].isNotEmpty)
                                    ? Image.network(
                                        medicine['image']!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                trailing: ElevatedButton(
                                  onPressed: () => _buyMedicine(medicine),
                                  child: const Text('Buy'),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      if (message['note'] != null && message['note'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SelectableText(
                            message['note']!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                    ],
                  );
                } else {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message['imageData'] != null)
                          _buildMessageImage(message),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: SelectableText(
                              message['content']!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          _buildImagePreview(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Describe your symptoms...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _handleSendMessage();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}