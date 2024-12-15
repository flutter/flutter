import 'package:flutter/material.dart';

class TimerSettingScreen extends StatefulWidget {
  const TimerSettingScreen({super.key});

  @override
  State<TimerSettingScreen> createState() => _TimerSettingScreenState();
}

class _TimerSettingScreenState extends State<TimerSettingScreen> {
  int timerValue = 5; // Default timer value

  void increaseTimer() {
    setState(() {
      timerValue++;
    });
  }

  void decreaseTimer() {
    setState(() {
      if (timerValue > 1) timerValue--; // Ensure timer doesn't go below 1
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Set Timer Duration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Timer Value with Up and Down Arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_up, size: 40),
                      onPressed: increaseTimer,
                    ),
                    Text(
                      '$timerValue',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down, size: 40),
                      onPressed: decreaseTimer,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Home and Next Buttons
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
