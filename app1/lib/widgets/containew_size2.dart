import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

class Containew_size2 extends StatelessWidget {
  const Containew_size2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Container_size',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AutofillHints.addressCity,
          ),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(10),
          height: 100,
          width: 100,
          decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              boxShadow: [BoxShadow(color: Colors.white, blurRadius: 20)]),
          child: const Center(
              child: Text('Hello',
                  style: TextStyle(color: Colors.black, fontSize: 30))),
        ),
      ),
    );
  }
}
