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

  Future<void> _loadFavorites() async {
    final favorites = await FavoritesManager.getFavorites();
    setState(() {
      _favorites = favorites;
      _filteredFavorites = favorites;
    });
  }

  Future<void> _clearFavorites() async {
    await FavoritesManager.clearFavorites();
    setState(() {
      _favorites = [];
      _filteredFavorites = [];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All favorites cleared!')));
  }

  Future<void> _exportFavorites() async {
    final filePath = await FavoritesManager.exportFavorites();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Favorites exported to $filePath')));
  }

  Future<void> _importFavorites() async {
    await FavoritesManager.importFavorites();
    await _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorites imported successfully!')),
    );
  }

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
                    ? const Center(child: Text('No favorites found.'))
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
                                await FavoritesManager.removeFavorite(
                                  favorite['quote']!,
                                );
                                await _loadFavorites();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Favorite removed!'),
                                  ),
                                );
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
}
