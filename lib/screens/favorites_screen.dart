// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:quote_app/managers/favorites_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, String>> _favorites = [];
  List<Map<String, String>> _filteredFavorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Load favorites from the FavoritesManager
  Future<void> _loadFavorites() async {
    try {
      final favorites = await FavoritesManager.getFavorites();
      setState(() {
        _favorites = favorites;
        _filteredFavorites = favorites;
      });
    } catch (e) {
      _showSnackBar('Failed to load favorites: $e');
    }
  }

  // Clear all favorites
  Future<void> _clearFavorites() async {
    try {
      await FavoritesManager.clearFavorites();
      setState(() {
        _favorites = [];
        _filteredFavorites = [];
      });
      _showSnackBar('All favorites cleared!');
    } catch (e) {
      _showSnackBar('Failed to clear favorites: $e');
    }
  }

  // Export favorites to a file
  Future<void> _exportFavorites() async {
    try {
      final filePath = await FavoritesManager.exportFavorites();
      _showSnackBar('Favorites exported to $filePath');
    } catch (e) {
      _showSnackBar('Failed to export favorites: $e');
    }
  }

  // Import favorites from a file
  Future<void> _importFavorites() async {
    try {
      await FavoritesManager.importFavorites();
      await _loadFavorites();
      _showSnackBar('Favorites imported successfully!');
    } catch (e) {
      _showSnackBar('Failed to import favorites: $e');
    }
  }

  // Search favorites by query
  void _searchFavorites(String query) {
    setState(() {
      _filteredFavorites =
          _favorites
              .where(
                (item) =>
                    item['quote']!.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    item['author']!.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  // Show a SnackBar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _exportFavorites,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importFavorites,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearFavorites,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Favorites',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchFavorites,
            ),
          ),
          Expanded(
            child:
                _filteredFavorites.isEmpty
                    ? const Center(
                      child: Text(
                        'No favorites found.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredFavorites.length,
                      itemBuilder: (context, index) {
                        final favorite = _filteredFavorites[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(favorite['quote']!),
                            subtitle: Text('- ${favorite['author']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await _removeFavorite(favorite['quote']!);
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Remove a single favorite
  Future<void> _removeFavorite(String quote) async {
    try {
      await FavoritesManager.removeFavorite(quote);
      await _loadFavorites();
      _showSnackBar('Favorite removed!');
    } catch (e) {
      _showSnackBar('Failed to remove favorite: $e');
    }
  }
}
