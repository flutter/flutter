import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final quotes = [
    '"The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart." - Helen Keller',
    '"The only person you are destined to become is the person you decide to be." - Ralph Waldo Emerson',
    '"Twenty years from now you will be more disappointed by the things that you didn\'t do than by the ones you did do. So throw off the bowlines, sail away from safe harbor, catch the trade winds in your sails. Explore, Dream, Discover." - Mark Twain',
  ];

  MyApp({super.key});

  String getRandomQuote() {
    final randomIndex = Random().nextInt(quotes.length);
    return quotes[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Quote Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(quote: getRandomQuote()),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String quote;

  const MyHomePage({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Quote'),
      ),
      body: Center(
        child: Text(
          quote,
          style: const TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }
}
