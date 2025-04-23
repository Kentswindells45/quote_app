import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main screen for displaying quotes
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  // Variables to store the quote and author
  String _quote = "Click the button to fetch a quote!";
  String _author = "";

  // Variable to track loading state
  bool _isLoading = false;

  // Function to fetch a random quote from the ZenQuotes API
  Future<void> fetchQuote() async {
    const url = 'https://zenquotes.io/api/random'; // API endpoint for random quotes
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Make an HTTP GET request to the API
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['q'] != null && data[0]['a'] != null) {
          // Update the state with the fetched quote and author
          setState(() {
            _quote = data[0]['q']; // Quote text
            _author = data[0]['a']; // Author name
          });
        } else {
          // Handle unexpected response format
          setState(() {
            _quote = "Unexpected response format.";
            _author = "";
          });
        }
      } else {
        // Handle HTTP errors
        setState(() {
          _quote = "Failed to fetch quote. Please try again.";
          _author = "";
        });
      }
    } catch (e) {
      // Handle network or parsing errors
      setState(() {
        _quote = "An error occurred. Please check your connection.";
        _author = "";
      });
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote App')), // App bar with title
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding around the content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: [
              // Show a loading spinner if fetching a quote
              if (_isLoading)
                const CircularProgressIndicator()
              else
                // Display the quote and author
                Column(
                  children: [
                    Text(
                      _quote, // Display the quote text
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10), // Add spacing
                    Text(
                      _author.isNotEmpty ? '- $_author' : '', // Display the author if available
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20), // Add spacing
              // Button to fetch a new quote
              ElevatedButton(
                onPressed: fetchQuote, // Call fetchQuote when pressed
                child: const Text('Fetch Quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
