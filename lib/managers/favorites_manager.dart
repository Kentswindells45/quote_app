import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const _favoritesKey = 'favorite_quotes';

  // Save a new favorite quote
  static Future<void> addFavorite(String quote, String author) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.add({'quote': quote, 'author': author});
    await prefs.setString(_favoritesKey, json.encode(favorites));
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
}
