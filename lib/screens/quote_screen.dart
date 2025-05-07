// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io'; // For file operations
import 'dart:math'; // For generating random numbers
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quote_app/screens/cached_quotes_screen.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart'; // For sharing quotes
import 'package:screenshot/screenshot.dart'; // For capturing screenshots
import 'package:path_provider/path_provider.dart'; // For accessing device storage
import 'package:quote_app/managers/favorites_manager.dart';
import 'package:quote_app/screens/favorites_screen.dart';
// Import AboutScreen
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quote_app/screens/about_screen.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = "Click the button to fetch a quote!";
  String _author = "";
  bool _isLoading = false;

  // List of categories
  final List<String> _categories = [
    "Inspiration",
    "Love",
    "Life",
    "Motivation",
    "Happiness",
    "Wisdom",
  ];

  // Selected category
  String _selectedCategory = "Inspiration";

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

  @override
  void initState() {
    super.initState();

    // Load cached quotes
    final box = Hive.box('quotes');
    final cachedQuotes = box.get('cachedQuotes', defaultValue: []);
    if (cachedQuotes.isNotEmpty) {
      setState(() {
        _quote = cachedQuotes.last['quote'];
        _author = cachedQuotes.last['author'];
      });
    }
  }

  Future<void> fetchQuote() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Showing cached quotes.'),
        ),
      );
      return;
    }

    // Fetch quote from API
    final url = 'https://zenquotes.io/api/random?category=$_selectedCategory';
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

          // Save the quote to Hive
          final box = Hive.box('quotes');
          List<dynamic> cachedQuotes = box.get(
            'cachedQuotes',
            defaultValue: [],
          );
          cachedQuotes.add({'quote': _quote, 'author': _author});
          box.put('cachedQuotes', cachedQuotes);
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

  Future<void> shareQuoteAsImage() async {
    try {
      // Capture the widget as an image
      final image = await _screenshotController.capture();
      if (image == null) return;

      // Save the image to a temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/quote_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);

      // Share the image
      await Share.shareXFiles([
        XFile(imagePath),
      ], text: 'Check out this quote!');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share quote: $e')));
    }
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
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch, // Stretch buttons to fill width
                    children: [
                      // Category Dropdown
                      Column(
                        children: [
                          const Text(
                            "Select a Category:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.1,
                              ), // Semi-transparent background
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              dropdownColor: Colors.blue.shade700,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              underline:
                                  const SizedBox(), // Remove default underline
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              isExpanded:
                                  true, // Make the dropdown take full width
                              items:
                                  _categories.map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      // Fetch Quote Button
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: fetchQuote,
                          splashColor: Colors.purple.withOpacity(0.3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Fetch Quote',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between buttons
                      // Save as Image Button
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: saveQuoteAsImage,
                          splashColor: Colors.teal.withOpacity(
                            0.3,
                          ), // Ripple effect
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.teal],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save as Image',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between buttons
                      // Add to Favorites Button
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (_quote !=
                                "Click the button to fetch a quote!") {
                              await FavoritesManager.addFavorite(
                                _quote,
                                _author,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Quote added to favorites!'),
                                ),
                              );
                            }
                          },
                          splashColor: Colors.orange.withOpacity(
                            0.3,
                          ), // Ripple effect
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.red, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add to Favorites',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between buttons
                      // View Favorites Button
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                          splashColor: Colors.cyan.withOpacity(
                            0.3,
                          ), // Ripple effect
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.indigo, Colors.cyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'View Favorites',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Add spacing between buttons
                      // View Cached Quotes Button
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const CachedQuotesScreen(),
                              ),
                            );
                          },
                          splashColor: Colors.amber.withOpacity(0.3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'View offline Quotes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
