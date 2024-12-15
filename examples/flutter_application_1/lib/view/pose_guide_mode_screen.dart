import 'package:flutter/material.dart';

class PoseGuideModeScreen extends StatelessWidget {
  const PoseGuideModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Padding above the title
            const SizedBox(height: 40),
            
            // Title
            const Text(
              'Select a Pose Guide to Use',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Scrollable Pose Guide List
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Adjust this count to match the number of pose guides
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Handle pose guide selection
                      print('Selected Pose Guide ${index + 1}');
                    },
                    child: Container(
                      height: 165,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Placeholder color for pose guide
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color.fromARGB(255, 116, 116, 116), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'Pose Guide ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home'); // Navigate to Home Screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Home'),
                ),

                // Next Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/camera'); // Navigate to Camera Screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
