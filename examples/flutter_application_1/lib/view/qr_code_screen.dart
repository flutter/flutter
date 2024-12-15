import 'package:flutter/material.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // QR Code Placeholder
              // Container(
              //   width: 230,
              //   height: 230,
              //   decoration: BoxDecoration(
              //     color: const Color.fromARGB(255, 255, 255, 255), // Placeholder background for QR code
              //     border: Border.all(color: Colors.black, width: 2),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: const Center(
              //     child: Text(
              //       'QR',
              //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 30),

              // Example QR Code place holder
              ClipRRect(
                borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
                child: Image.asset(
                  'lib/images/example_qr.jpg', // Path to your image
                  height: 230,
                  width: 230,
                  fit: BoxFit.contain, // Adjusts how the image fits in the container
                ),
              ),
              const SizedBox(height: 30),


              // Buttons
              Column(
                children: [
                  // Back to Home Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home'); // Navigate to Home Screen
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(230, 50), // Button size
                    ),
                    child: const Text('Back to Home'),
                  ),
                  const SizedBox(height: 10),
                  // Take Again Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/camera'); // Navigate to Camera Screen
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(230, 50), // Button size
                    ),
                    child: const Text('Take Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
