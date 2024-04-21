import 'package:flutter/material.dart';

class Myalert extends StatelessWidget {
  const Myalert({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.image),
          backgroundColor: Colors.blue,
          title: const Text(
            'Image Widgets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          toolbarHeight: 100,
        ),
        body: Center(
          child: TextButton(
            style: ButtonStyle(
                overlayColor: MaterialStatePropertyAll(Colors.black),
                backgroundColor: MaterialStatePropertyAll(Colors.blue)),
            child: Text('Click me'),
            onPressed: () {
              _showMydialog(context);
            },
          ),
        ));
  }
}

Future<void> _showMydialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'This is an alert',
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                  'Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.Flutter CircularProgressIndicator is a material widget that indicates that the application is busy. Firstly, we create a new project using Visual Studio Code(IDE) with the name “progressindicator”. You can choose any name.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('CLose')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Agree'))
        ],
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
    },
  );
}
