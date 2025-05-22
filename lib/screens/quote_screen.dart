// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io'; // For file operations
import 'dart:math'; // For generating random numbers
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:lottie/lottie.dart'; // Import Lottie package

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = "Click the button to fetch a quote!";
  String _author = "";
  bool _isLoading = false;
  bool _isHapticFeedbackEnabled = true; // Default to enabled

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
    _loadCachedQuote();
  }

  // Load the last cached quote from Hive
  void _loadCachedQuote() {
    final box = Hive.box('quotes');
    final cachedQuotes = box.get('cachedQuotes', defaultValue: []);
    if (cachedQuotes.isNotEmpty) {
      setState(() {
        _quote = cachedQuotes.last['quote'];
        _author = cachedQuotes.last['author'];
      });
    }
  }

  // Fetch a new quote from the API
  Future<void> fetchQuote() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnackBar('No internet connection. Showing cached quotes.');
      return;
    }

    // Map categories to API-specific keywords
    final Map<String, String> categoryKeywords = {
      "Inspiration": "inspire",
      "Love": "love",
      "Life": "life",
      "Motivation": "motivation",
      "Happiness": "happiness",
      "Wisdom": "wisdom",
    };

    final selectedKeyword = categoryKeywords[_selectedCategory] ?? "inspire";
    final url = 'https://zenquotes.io/api/random?category=$selectedKeyword';

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
          _showSnackBar('Unexpected response format.');
        }
      } else {
        _showSnackBar('Failed to fetch quote. Please try again.');
      }
    } catch (e) {
      _showSnackBar('An error occurred. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save the current quote as an image
  Future<void> saveQuoteAsImage() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(imagePath);
      await file.writeAsBytes(image);

      _showSnackBar('Quote saved as image: $imagePath');
    } catch (e) {
      _showSnackBar('Failed to save image: $e');
    }
  }

  // Share the current quote as text
  void shareQuote() {
    final text = '$_quote\n- $_author';
    Share.share(text);
  }

  // Share the current quote as an image
  Future<void> shareQuoteAsImage() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/quote_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: 'Check out this quote!');
    } catch (e) {
      _showSnackBar('Failed to share quote: $e');
    }
  }

  // Show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        shadowColor: Colors.deepPurple.withOpacity(0.4),
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
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Enable Haptic Feedback'),
              trailing: Switch(
                value: _isHapticFeedbackEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _isHapticFeedbackEnabled = value;
                  });
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Quote'),
              onTap: () {
                if (_quote != "Click the button to fetch a quote!") {
                  shareQuote();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About App'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _currentBackgroundColor,
              _currentBackgroundColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Screenshot(
            controller: _screenshotController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    SizedBox(
                      height: 100,
                      child: Lottie.asset(
                        'lib/assets/Lottie Lego.json',
                      ), // Add a Lottie file to your assets
                    )
                  else
                    Card(
                      color: Colors.white.withOpacity(0.85),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: Text(
                                _quote,
                                key: ValueKey(_quote),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                              child: Text(
                                _author.isNotEmpty ? '- $_author' : '',
                                key: ValueKey(_author),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          dropdownColor: Colors.deepPurple.shade200,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          isExpanded: true,
                          items:
                              _categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 30.0,
        ), // Adjust the bottom padding to raise the buttons
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Fetch Quote Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "fetchQuote",
                  tooltip: "Fetch a new quote",
                  onPressed: () {
                    if (_isHapticFeedbackEnabled) {
                      HapticFeedback.lightImpact();
                    }
                    fetchQuote();
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Fetch Quote",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            // Save as Image Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "saveImage",
                  onPressed: saveQuoteAsImage,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.save),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Save Image",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            // Add to Favorites Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "addToFavorites",
                  onPressed: () async {
                    if (_quote != "Click the button to fetch a quote!") {
                      await FavoritesManager.addFavorite(_quote, _author);
                      _showSnackBar('Quote added to favorites!');
                    }
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.favorite),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Add Favorite",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            // View Favorites Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "viewFavorites",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.list),
                ),
                const SizedBox(height: 5),
                const Text(
                  "View Favorites",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),

            // View Offline Quotes Button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "viewOfflineQuotes",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CachedQuotesScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.history),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Offline Quotes",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
