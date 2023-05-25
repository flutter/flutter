import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter LinkedText.spans Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  void _onTapUrl (String urlString) {
    debugPrint('Tapped the URl $urlString.');
    // Use a package like url_launcher here to open the link.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LinkedText.spans(
                  onTap: _onTapUrl,
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'https://www.',
                      style: DefaultTextStyle.of(context).style,
                      children: const <InlineSpan>[
                        TextSpan(
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                          text: 'example',
                        ),
                      ],
                    ),
                    TextSpan(
                      text: '.com',
                      style: DefaultTextStyle.of(context).style,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
