import 'package:flutter/material.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Lopes 4 Cuts'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'How to Use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Position yourself in front of the camera.\n'
              '2. Take the photos.\n'
              '3. Select photos to use for the collage.\n'
              '4. Select a frame for your photo.\n'
              '5. Share your final photo using the QR Code option.\n'
              '+ Use the Timer to set the countdown.\n'
              '+ Choose a Pose Guide to help with posing.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),

            // Insert image below instructions
            Image.asset(
              'lib/images/example_photo.JPG', // Path to your image
              height: 260,
              width: 130,
              fit: BoxFit.contain, // Adjusts how the image fits in the container
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to Camera Screen
                Navigator.pushNamed(context, '/camera');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
