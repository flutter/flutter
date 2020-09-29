import 'package:flutter/material.dart';

const backKey = ValueKey('backKey');

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          key: backKey,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          'This is a sample app.',
          style: Theme.of(context).textTheme.headline3,
        ),
      ),
    );
  }
}
