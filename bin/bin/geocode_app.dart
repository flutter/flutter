import 'package:flutter/material.dart';

void main() =>
    runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: GeoCodingProMaster()));

class GeoEntity {

  GeoEntity({required this.code, required this.name, required this.category, required this.type});
  final String code;
  final String name;
  final String category;
  final String type;
}

class GeoCodingProMaster extends StatefulWidget {
  const GeoCodingProMaster({super.key});

  @override
  State<GeoCodingProMaster> createState() => _GeoCodingProMasterState();
}

class _GeoCodingProMasterState extends State<GeoCodingProMaster> {
  // 1. initState spelling and override fix
  @override
  void initState() {
    super.initState();
    // Unga initialization code inga varanum
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GeoCoding Pro Master'), backgroundColor: Colors.teal),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to GeoCoding Pro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Button Clicked!');
              },
              child: const Text('Start Search'),
            ),
          ],
        ),
      ),
    );
  }
}
