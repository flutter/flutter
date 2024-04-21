import 'package:flutter/material.dart';

class Mydropdown extends StatefulWidget {
  const Mydropdown({super.key});

  @override
  State<Mydropdown> createState() => _MydropdownState();
}

class _MydropdownState extends State<Mydropdown> {
  String selectedvalue = 'Cricket';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.image),
        backgroundColor: Colors.blue,
        title: const Text(
          'Drop down list',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        toolbarHeight: 100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 300,
              color: Colors.black,
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedvalue,
                icon: Icon(Icons.arrow_circle_down),
                onChanged: (String? newvalue) {
                  setState(() {
                    selectedvalue = newvalue!;
                  });
                },
                items: <String>[
                  'Cricket',
                  'football',
                  'Badminton',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
