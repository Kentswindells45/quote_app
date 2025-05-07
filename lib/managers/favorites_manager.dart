import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class FavoritesManager {
  static const _favoritesKey = 'favorite_quotes';
  static const int _maxFavorites = 50;

  // Save a new favorite quote with a limit
  static Future<void> addFavorite(String quote, String author) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    // Check if the quote already exists
    final isDuplicate = favorites.any((item) => item['quote'] == quote);
    if (!isDuplicate) {
      if (favorites.length >= _maxFavorites) {
        // Remove the oldest favorite if the limit is exceeded
        favorites.removeAt(0);
      }
      favorites.add({'quote': quote, 'author': author});
      await prefs.setString(_favoritesKey, json.encode(favorites));
    }
  }

  // Retrieve all favorite quotes
  static Future<List<Map<String, String>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = prefs.getString(_favoritesKey);
    if (favoritesString == null) {
      return [];
    }
    final List<dynamic> favoritesJson = json.decode(favoritesString);
    return favoritesJson.map((e) => Map<String, String>.from(e)).toList();
  }

  // Remove a favorite quote
  static Future<void> removeFavorite(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.removeWhere((item) => item['quote'] == quote);
    await prefs.setString(_favoritesKey, json.encode(favorites));
  }

  // Clear all favorite quotes
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }

  // Check if a quote is a favorite
  static Future<bool> isFavorite(String quote) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item['quote'] == quote);
  }

  // Search favorite quotes by keyword or author
  static Future<List<Map<String, String>>> searchFavorites(String query) async {
    final favorites = await getFavorites();
    return favorites.where((item) {
      final quote = item['quote']?.toLowerCase() ?? '';
      final author = item['author']?.toLowerCase() ?? '';
      return quote.contains(query.toLowerCase()) ||
          author.contains(query.toLowerCase());
    }).toList();
  }

  // Export favorite quotes to a JSON file
  static Future<String> exportFavorites() async {
    final favorites = await getFavorites();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/favorite_quotes.json';
    final file = File(filePath);
    await file.writeAsString(json.encode(favorites));
    return filePath; // Return the file path for sharing or other purposes
  }

  // Import favorite quotes from a JSON file
  static Future<void> importFavorites() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> importedFavorites = json.decode(content);

      final prefs = await SharedPreferences.getInstance();
      final existingFavorites = await getFavorites();

      // Merge imported favorites with existing ones
      for (var item in importedFavorites) {
        if (!existingFavorites.any((fav) => fav['quote'] == item['quote'])) {
          existingFavorites.add(Map<String, String>.from(item));
        }
      }

      await prefs.setString(_favoritesKey, json.encode(existingFavorites));
    }
  }
}
