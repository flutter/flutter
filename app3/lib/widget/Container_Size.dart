import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Container_Size extends StatelessWidget {
  const Container_Size({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () {},
        ),
        backgroundColor: Colors.blue,
        title: const Text(
          'MyApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4),
          margin: const EdgeInsets.all(5),
          height: 70,
          width: 70,
          decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.pink,
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                )
              ],
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20))),
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
