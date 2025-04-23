import 'package:flutter/material.dart';

import 'package:quote_app/screens/quote_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote App',
      debugShowCheckedModeBanner: false, // Disable the debug banner
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QuoteScreen(),
    );
  }
}
