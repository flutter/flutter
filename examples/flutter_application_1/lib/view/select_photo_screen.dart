import 'package:flutter/material.dart';

class SelectPhotoScreen extends StatefulWidget {
  const SelectPhotoScreen({super.key});

  @override
  State<SelectPhotoScreen> createState() => _SelectPhotoScreenState();
}

class _SelectPhotoScreenState extends State<SelectPhotoScreen> {
  int selectedPhotoCount = 4; // Default number of photos to use

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // Padding above the title
            const SizedBox(height: 40),
            // Title
            const Text(
              'Select Photos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of Photos
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  mainAxisSpacing: 10, // Vertical spacing
                  crossAxisSpacing: 10, // Horizontal spacing
                  childAspectRatio: 1, // Aspect ratio of each grid item
                ),
                itemCount: 8, // Number of photos in the grid
                itemBuilder: (context, index) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255), // Placeholder photo color
                    ),
                    child: Center(
                      child: Text(
                        'Photo ${index + 1}', // Placeholder text for each photo
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Row: Back, Dropdown, and Next Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/camera'); // Navigate back to Camera Screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Back'),
                ),

                // Dropdown for photo count
                Row(
                  children: [
                    const Text(
                      'Use:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    DropdownButton<int>(
                      value: selectedPhotoCount,
                      icon: const Icon(Icons.arrow_drop_down),
                      underline: Container(
                        height: 2,
                        color: Colors.black54,
                      ),
                      items: [2, 4, 6].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPhotoCount = value!; // Update selected photo count
                        });
                      },
                    ),
                  ],
                ),

                // Next Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/select-frame', // Navigate to Select Frame Screen
                      arguments: selectedPhotoCount, // Pass selected photo count as argument
                    );
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
