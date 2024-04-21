import 'package:flutter/material.dart';

// ignore: camel_case_types
class list_grid extends StatefulWidget {
  const list_grid({super.key});

  @override
  State<list_grid> createState() => _list_gridState();
}

// ignore: camel_case_types
class _list_gridState extends State<list_grid> {
  List<String> names = ["Shobhit", "Rohan"];
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
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        title: const Text('List and grid'),
      ),
      body: ListView.builder(
        itemCount: names.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
                leading: const Icon(Icons.person),
                title: Column(
                  children: [
                    Text(
                      mp1['names']?[index],
                    ),
                    Text(
                      mp1['describ']?[index],
                    ),
                    const SizedBox(
                      height: 20,
                      width: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(0)),
                          overlayColor: MaterialStateProperty.all(Colors.black),
                          elevation: MaterialStateProperty.all(0),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue)),
                      child: const Text('click me'),
                    ),
                  ],
                )),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 10.0,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          fixedColor: Colors.blue,
          items: const [
            BottomNavigationBarItem(
              label: "Home",
              icon: Icon(Icons.home),
            ),
            BottomNavigationBarItem(
              label: "Search",
              icon: Icon(Icons.search),
            ),
            BottomNavigationBarItem(
              label: "Profile",
              icon: Icon(Icons.account_circle),
            ),
          ],
          onTap: (int indexOfItem) {}),
    );
  }
}
