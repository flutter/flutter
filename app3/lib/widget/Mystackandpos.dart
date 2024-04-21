import 'package:flutter/material.dart';

class Mystack extends StatelessWidget {
  const Mystack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text("My Stack"),
        ),
        body: Stack(
          children: [
            Positioned(
                child: Container(
              height: 200,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(
                      opacity: 0.8,
                      image: AssetImage('android/assets/download.jpg'),
                      fit: BoxFit.cover)),
            )),
            Positioned(
                top: 20,
                left: 10,
                child: Container(
                  height: 40,
                  width: 40,
                  color: Colors.white,
                )),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 40,
                width: 40,
                color: Colors.white,
              ),
            )
          ],
        ));
  }
}
