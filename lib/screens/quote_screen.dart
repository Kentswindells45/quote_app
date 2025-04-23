import 'dart:io'; // For file operations
import 'dart:math'; // For generating random numbers
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart'; // For sharing quotes
import 'package:screenshot/screenshot.dart'; // For capturing screenshots
import 'package:path_provider/path_provider.dart'; // For accessing device storage

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = "Click the button to fetch a quote!";
  String _author = "";
  bool _isLoading = false;

  // List of background colors
  final List<Color> _backgroundColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
  ];

  // Variable to store the current background color
  Color _currentBackgroundColor = Colors.blue;

  // Screenshot controller
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> fetchQuote() async {
    const url = 'https://zenquotes.io/api/random';
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['q'] != null && data[0]['a'] != null) {
          setState(() {
            _quote = data[0]['q'];
            _author = data[0]['a'];
            _currentBackgroundColor =
                _backgroundColors[Random().nextInt(_backgroundColors.length)];
          });
        } else {
          setState(() {
            _quote = "Unexpected response format.";
            _author = "";
          });
        }
      } else {
        setState(() {
          _quote = "Failed to fetch quote. Please try again.";
          _author = "";
        });
      }
    } catch (e) {
      setState(() {
        _quote = "An error occurred. Please check your connection.";
        _author = "";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveQuoteAsImage() async {
    try {
      // Capture the widget as an image
      final image = await _screenshotController.capture();
      if (image == null) return;

      // Get the directory to save the image
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Save the image to the directory
      final file = File(imagePath);
      await file.writeAsBytes(image);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote saved as image: $imagePath')),
      );
    } catch (e) {
      // Show an error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  void shareQuote() {
    final text = '$_quote\n- $_author';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Quote App',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed:
                _quote != "Click the button to fetch a quote!"
                    ? shareQuote
                    : null,
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        color: _currentBackgroundColor,
        child: Center(
          child: Screenshot(
            controller: _screenshotController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        Text(
                          _quote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _author.isNotEmpty ? '- $_author' : '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchQuote,
                    child: const Text('Fetch Quote'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: saveQuoteAsImage,
                    icon: const Icon(Icons.save),
                    label: const Text('Save as Image'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
