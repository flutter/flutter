import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(title: Text('Parent Child Checkox')),
        body: Column(
          children: [
            ParentChildCheckbox(
              parent: const Text('Parent 1'),
              children: [
                Text('Children 1.1'),
                Text('Children 1.2'),
                Text('Children 1.3'),
                Text('Children 1.4'),
              ],
              parentCheckboxColor: Colors.orange,
              childrenCheckboxColor: Colors.red,
            ),
            ParentChildCheckbox(
              parent: Text('Parent 2'),
              children: [
                Text('Children 2.1'),
                Text('Children 2.2'),
                Text('Children 2.3'),
                Text('Children 2.4'),
              ],
            ),
            ElevatedButton(
              child: Text('Get Data'),
              onPressed: () {
                log(ParentChildCheckbox.isParentSelected.toString());
                log(ParentChildCheckbox.selectedChildrens.toString());
              },
            ),
          ],
        ),
      ),
    );
  }
}
