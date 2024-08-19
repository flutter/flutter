import 'package:flutter/material.dart';

class DynamicTitle extends StatelessWidget {
  const DynamicTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title,
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}