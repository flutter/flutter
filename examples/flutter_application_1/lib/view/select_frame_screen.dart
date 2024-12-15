import 'package:flutter/material.dart';

class SelectFrameScreen extends StatefulWidget {
  const SelectFrameScreen({super.key});

  @override
  State<SelectFrameScreen> createState() => _SelectFrameScreenState();
}

class _SelectFrameScreenState extends State<SelectFrameScreen> {
  Color selectedColor = const Color.fromARGB(255, 160, 210, 250); // Default frame color

  // List of colors for the frame picker
  final List<Color> frameColors = [
    const Color.fromARGB(255, 240, 232, 140),
    const Color.fromARGB(255, 103, 139, 105),
    const Color.fromARGB(255, 144, 228, 213),
    const Color.fromARGB(255, 160, 210, 250),
    const Color.fromARGB(255, 87, 102, 174),
    const Color.fromARGB(255, 103, 103, 103),
    const Color.fromARGB(255, 180, 135, 252),
    const Color.fromARGB(255, 255, 179, 221),
  ];

  int layoutOption = 4; // Default to 4-photo layout

  
  // // Method to calculate dynamic screenHeight based on layoutOption
  // double calculateScreenHeight(BuildContext context) {
  //   double screenHeight = MediaQuery.of(context).size.height;

  //   if (layoutOption == 2) {
  //     return screenHeight * 0.6; // 40% height for 2-photo layout
  //   } else if (layoutOption == 4) {
  //     return screenHeight * 0.7; // 60% height for 4-photo layout
  //   } else {
  //     return screenHeight * 0.8; // 80% height for 6-photo layout
  //   }
  // }


  // Method to build frames dynamically based on the selected layout
  Widget buildFrames() {
    // Calculate frame dimensions dynamically based on layoutOption and screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Aspect ratio for each frame is approximately 3:4 (portrait photo size)
    double frameWidth;
    double frameHeight;

    if (layoutOption == 2) {
      frameWidth = screenWidth * 0.35; 
      frameHeight = screenHeight * 0.30; 
      screenHeight *= 0.6;
    } else if (layoutOption == 4) {
      frameWidth = screenWidth * 0.35; 
      frameHeight = screenHeight * 0.21;
      screenHeight *= 0.7;
    } else {
      frameWidth = screenWidth * 0.38; 
      frameHeight = screenHeight * 0.12;
      screenHeight *= 0.8;
    }

    // Generate frames
    List<Widget> frames = List.generate(
      layoutOption,
      (index) => Container(
        margin: const EdgeInsets.all(4.0),
        width: frameWidth,
        height: frameHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: const Center(
        ),
      ),
    );

    // Distribute frames in rows
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (layoutOption >= 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: frames.take(2).toList(),
          ),
        if (layoutOption >= 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: frames.skip(2).take(2).toList(),
          ),
        if (layoutOption == 6)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: frames.skip(4).take(2).toList(),
          ),
          const SizedBox(height: 20), // Space between frames and text
          const Text(
          'Lopes 4 Cuts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // double screenHeight = calculateScreenHeight(context); 

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // Padding above the title
            const SizedBox(height: 40),

            // Title
            const Text(
              'Select Frame',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Frame container
            Expanded(
              child: Container(
                // height: screenHeight,
                color: selectedColor.withOpacity(1.0), // Frame background color
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildFrames(),
              ),
            ),
            const SizedBox(height: 50),

            // Horizontally Scrollable Color Picker
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: frameColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color; // Update selected color
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(0, 255, 255, 255),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Layout Selector and Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Back'),
                ),

                // Layout Selector
                DropdownButton<int>(
                  value: layoutOption,
                  items: [2, 4, 6].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value Photos'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      layoutOption = value!; // Update layout option
                    });
                  },
                ),

                // Next Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/result'); // Navigate to Result Screen
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
