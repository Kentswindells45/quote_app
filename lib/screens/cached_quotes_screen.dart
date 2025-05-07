import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CachedQuotesScreen extends StatelessWidget {
  const CachedQuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('quotes');
    final List<dynamic> cachedQuotes = box.get(
      'cachedQuotes',
      defaultValue: [],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cached Quotes'), centerTitle: true),
      body:
          cachedQuotes.isEmpty
              ? const Center(
                child: Text(
                  'No cached quotes available.',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: cachedQuotes.length,
                itemBuilder: (context, index) {
                  final quote = cachedQuotes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        quote['quote'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        '- ${quote['author']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
