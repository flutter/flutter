// ignore: file_names
import 'package:flutter/material.dart';

class Button12 extends StatelessWidget {
  const Button12({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () {},
          ),
          title: const Text('Buttons'),
          backgroundColor: Colors.blue,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 50,
                width: 200,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                      overlayColor: MaterialStateProperty.all(Colors.black),
                      elevation: MaterialStateProperty.all(20),
                      backgroundColor: MaterialStateProperty.all(Colors.blue)),
                  child: const Text(
                    "Click me",
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
