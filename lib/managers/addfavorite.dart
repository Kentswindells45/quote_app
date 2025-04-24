import 'dart:async';

class FavoritesManager {
  static final List<Map<String, String>> _favorites = [];

  static Future<void> addFavorite(String quote, String author) async {
    _favorites.add({'quote': quote, 'author': author});
  }

  static List<Map<String, String>> getFavorites() {
    return _favorites;
  }
}
