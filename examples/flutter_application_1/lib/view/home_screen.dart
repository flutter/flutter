import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Lopes 4 Cuts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Lopes 4 Cuts is a fun and interactive photo booth application. '
                'Choose your pose, set a timer, and enjoy creating your perfect photo memories!',
                style: TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(230, 50), // Width: 200, Height: 50
              ),
              child: const Text('Start'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pose-guide-mode');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(230, 50), // Width: 200, Height: 50
              ),
              child: const Text('Pose Guide Mode'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/timer-setting');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(230, 50), // Width: 200, Height: 50
              ),
              child: const Text('Timer Setting'),
            ),
          ],
        ),
      ),
    );
  }
}
