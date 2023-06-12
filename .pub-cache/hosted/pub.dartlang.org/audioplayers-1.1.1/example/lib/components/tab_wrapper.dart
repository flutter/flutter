import 'package:flutter/material.dart';

class TabWrapper extends StatelessWidget {
  final List<Widget> children;

  const TabWrapper({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: children
                .map(
                  (w) => Container(
                    padding: const EdgeInsets.all(6.0),
                    child: w,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
