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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton(
                        label: 'Fetch Quote',
                        icon: Icons.refresh,
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        onTap: () {
                          if (_isHapticFeedbackEnabled) {
                            HapticFeedback.lightImpact();
                          }
                          fetchQuote();
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildButton(
                        label: 'Save as Image',
                        icon: Icons.save,
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.teal],
                        ),
                        onTap: saveQuoteAsImage,
                      ),
                      const SizedBox(height: 10),
                      _buildButton(
                        label: 'Add to Favorites',
                        icon: Icons.favorite,
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                        onTap: () async {
                          if (_quote != "Click the button to fetch a quote!") {
                            await FavoritesManager.addFavorite(_quote, _author);
                            _showSnackBar('Quote added to favorites!');
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildButton(
                        label: 'View Favorites',
                        icon: Icons.list,
                        gradient: const LinearGradient(
                          colors: [Colors.indigo, Colors.cyan],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildButton(
                        label: 'View Offline Quotes',
                        icon: Icons.history,
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CachedQuotesScreen(),
                            ),
                          );
                        },
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

  // Helper method to build buttons
  Widget _buildButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
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
    );
  }
}
