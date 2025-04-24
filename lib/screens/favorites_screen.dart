import 'package:flutter/material.dart';
import 'package:quote_app/managers/favorites_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, String>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoritesManager.getFavorites();
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _removeFavorite(String quote) async {
    await FavoritesManager.removeFavorite(quote);
    _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote removed from favorites!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body:
          _favorites.isEmpty
              ? const Center(child: Text('No favorites yet!'))
              : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(
                        favorite['quote']!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      subtitle: Text('- ${favorite['author']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFavorite(favorite['quote']!),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
