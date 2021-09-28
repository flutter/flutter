import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Desktop app for managing a release of the Flutter SDK, currently in development',
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    );
  }
}
