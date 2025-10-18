import 'package:flutter/material.dart'; import 'package:google_fonts/google_fonts.dart';

void main() { runApp(const AliBhaiTopUpApp()); }

class AliBhaiTopUpApp extends StatelessWidget { const AliBhaiTopUpApp({super.key});

@override Widget build(BuildContext context) { return MaterialApp( debugShowCheckedModeBanner: false, title: 'ALI BHAI TOP UP', theme: ThemeData.dark().copyWith( scaffoldBackgroundColor: Colors.black, textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme), ), home: const HomeScreen(), ); } }

class HomeScreen extends StatelessWidget { const HomeScreen({super.key});

@override Widget build(BuildContext context) { return Scaffold( appBar: AppBar( title: const Text('ALI BHAI TOP UP ⚡'), backgroundColor: Colors.black, centerTitle: true, elevation: 10, shadowColor: Colors.blueAccent.withOpacity(0.6), ), body: Padding( padding: const EdgeInsets.all(12.0), child: GridView.count( crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: const [ OfferCard( title: 'Diamond Top-Up BD', imageUrl: 'https://i.ibb.co/XztcQFM/diamond.png', ), OfferCard( title: 'Combo Offer BD', imageUrl: 'https://i.ibb.co/2v2mZn8/combo.png', ), OfferCard( title: 'Level Up Pass BD', imageUrl: 'https://i.ibb.co/0JQZ5Fy/levelup.png', ), OfferCard( title: 'Mystery Package', imageUrl: 'https://i.ibb.co/0mwcBfm/mystery.png', ), ], ), ), bottomNavigationBar: BottomNavigationBar( backgroundColor: Colors.black, type: BottomNavigationBarType.fixed, selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.white54, items: const [ BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Add Money'), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Orders'), BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offers'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'), ], ), ); } }

class OfferCard extends StatelessWidget { final String title; final String imageUrl;

const OfferCard({super.key, required this.title, required this.imageUrl});

@override Widget build(BuildContext context) { return Container( decoration: BoxDecoration( borderRadius: BorderRadius.circular(20), gradient: const LinearGradient( colors: [Colors.black, Colors
