import 'package:flutter/material.dart';

class Mydismissible extends StatefulWidget {
  const Mydismissible({super.key});

  @override
  State<Mydismissible> createState() => _MydismissibleState();
}

class _MydismissibleState extends State<Mydismissible> {
  List<String> names = ['Shobhit', 'Aman', 'Rahul', 'Arjun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
          title: const Text('Dismissible Widget'),
        ),
        body: ListView.builder(
          itemCount: names.length,
          itemBuilder: (context, index) {
            final name = names[index];
            return Dismissible(
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        duration: Duration(milliseconds: 100),
                        backgroundColor: Colors.red,
                        content: Text('Call End')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: Duration(milliseconds: 100),
                        backgroundColor: Colors.green,
                        content: Text('Call start')));
                  }
                },
                key: Key(name),
                background: Container(
                  color: Colors.green,
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                ),
                child: Card(
                  child: ListTile(
                    title: Text(names[index]),
                    leading: IconButton(
                      icon: Icon(Icons.person),
                      onPressed: () {},
                    ),
                  ),
                ));
          },
        ));
  }
}
