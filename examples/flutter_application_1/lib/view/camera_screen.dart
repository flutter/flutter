import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Timer
          const Padding(
            padding: EdgeInsets.only(top: 90.0),
            child: Column(
              children: [
                Text(
                  'Left Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '5', // Timer countdown value
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Center Section: Rotated Text
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: -0.2, // Rotate slightly
                child: const Text(
                  'Live Camera Screen',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Section: Photo Count and Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              children: [
                // Photo Count
                const Text(
                  '1/8', // Photo count placeholder
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Timer Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/timer-setting', // Navigate to Timer Setting Screen
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        shape: const CircleBorder(),
                      ),
                      child: const Text(
                        'Timer',
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Start Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/select-photo', // Navigate to Select Photo Screen
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 70,
                          vertical: 20,
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

                    // Rotate Button
                    ElevatedButton(
                      onPressed: () {
                        // Handle Rotate action
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        shape: const CircleBorder(),
                      ),
                      child: const Text(
                        'Rotate',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
