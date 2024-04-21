import 'package:flutter/material.dart';

class Mygrid1 extends StatefulWidget {
  const Mygrid1({super.key});

  @override
  State<Mygrid1> createState() => _Mygrid1State();
}

class _Mygrid1State extends State<Mygrid1> {
  List<String> names = ["Shobhit", "Rohan", "Rahul"];
  Map<String, List> mp1 = {
    'names': ["Shobhit", "Rohan"],
    'describ': [
      "I am Shobiht",
      "I am Shobiht",
    ],
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu),
          ),
          title: const Text(
            'This is my Grid',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          //child: GridView.count(
          //  padding: EdgeInsets.symmetric(vertical: 20),
          //  crossAxisCount: 3,
          //  scrollDirection: Axis.vertical,
          //  crossAxisSpacing: 10,
          //  mainAxisSpacing: 10,
          //
          //  childAspectRatio: 4 / 2,
          //  children: <Widget>[
          //    for (int i = 0; i < 50; i++)
          //      const Card(
          //        color: Colors.blue,
          //        child: Center(child: Text('Hello Shobhit')),
          //        shadowColor: Colors.white,
          //      ),
          //  ],
          //),
          child: GridView.builder(
            itemCount: names.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemBuilder: (context, index) {
              return Card(
                color: Colors.blue,
                child: Center(child: Text(names[index])),
              );
            },
          ),
        ));
  }
}
