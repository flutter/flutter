import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parkngo/login.dart';
import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Attendre 3 secondes puis naviguer vers l'écran principal
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png',
                width:
                    200), // Assurez-vous d'avoir le bon chemin pour votre image
            SizedBox(height: 20),
            CircularProgressIndicator(), // Indicateur de chargement
          ],
        ),
      ),
    );
  }
}
