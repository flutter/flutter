import 'package:flutter/material.dart';

class Mybottomsheet extends StatelessWidget {
  const Mybottomsheet({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> list = ['Shobhit', 'Rohan', 'Rahul', 'Raman'];
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
        child: Container(
            child: TextButton(
          onPressed: () {
            showModalBottomSheet(
              enableDrag: false,
              context: context,
              builder: (context) {
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(list[index]),
                          subtitle: Text('Hello ${list[index]}'),
                          shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        )
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Text('Click Me'),
        )),
      ),
    );
  }
}
