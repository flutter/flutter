import 'package:flutter/material.dart';

class Mysnackbar extends StatelessWidget {
  const Mysnackbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
          title: const Text('SnackBar'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // ignore: non_constant_identifier_names
              final Scnackbar = SnackBar(
                  action: SnackBarAction(label: 'Undo', onPressed: () {}),
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  backgroundColor: Colors.black,
                  duration: const Duration(milliseconds: 5000),
                  content: const Text(
                    "Error: Wrong! Login details",
                    style: TextStyle(color: Colors.white),
                  ));

              ScaffoldMessenger.of(context).showSnackBar(Scnackbar);
            },
            style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(Colors.blue),
                overlayColor: MaterialStatePropertyAll(Colors.white)),
            child: const Text(
              'Click me',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ));
  }
}
