import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quote_app/screens/quote_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open a box for storing quotes
  await Hive.openBox('quotes');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const QuoteScreen(),
    );
  }
}
