import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Mydrawer extends StatefulWidget {
  const Mydrawer({super.key});

  @override
  State<Mydrawer> createState() => _MydrawerState();
}

class _MydrawerState extends State<Mydrawer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.blue,
        child: ListView(
          children: [
            DrawerHeader(
                padding: EdgeInsets.zero,
                child: Container(
                  color: Colors.black,
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRIdoay7VbsVZzZ1bZkX4k0T77hp5sb_ciXdQ&s'),
                        radius: 40,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Wrap(children: [
                        SizedBox(
                          height: 55,
                          width: 100,
                          child: Text(
                            'Shobhit Mhase',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 39),
                        child: Icon(Icons.exit_to_app),
                      ),
                    ],
                  ),
                )),
            const ListTile(
              leading: Icon(Icons.folder),
              title: Text('MyFiles'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.file_copy),
              title: Text('MyFiles'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.photo),
              title: Text('MyFiles'),
            ),
            const Divider(),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Drawer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        toolbarHeight: 100,
      ),
    );
  }
}
