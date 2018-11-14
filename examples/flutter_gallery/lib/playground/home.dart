import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Widget Playground',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Material Widget Playground'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum SupportedWidgets { FlatButton, RaisedButton }

class _MyHomePageState extends State<MyHomePage> {
  String selectedWidget = 'FlatButton';
  String selectedProperty = 'Elevation';
  double configuredPadding = 8.0;

  String getCode(double padding) {
    return """
FlatButton(
  child: Text('Button label'),
  elevation: $padding,
),
""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Configuration:'),
            ListTile(
              title: const Text('Widget:'),
              trailing: DropdownButton<String>(
                value: selectedWidget,
                onChanged: (String newValue) {
                  setState(() {
                    selectedWidget = newValue;
                  });
                },
                items: <String>[
                  'FlatButton',
                  'RaisedButton',
                  'Checkbox',
                  'Radio',
                  'Switch'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: const Text('Property:'),
              trailing: DropdownButton<String>(
                value: selectedProperty,
                onChanged: (String newValue) {
                  setState(() {
                    selectedProperty = newValue;
                  });
                },
                items: <String>[
                  'Elevation',
                  'BorderShape',
                  'Color',
                  'SplashColor'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text('Property value: ${configuredPadding.toString()}'),
              trailing: SizedBox(
                width: 180.0,
                child: Slider(
                  value: configuredPadding,
                  min: 0.0,
                  max: 24.0,
                  divisions: 3,
                  onChanged: (double value) {
                    setState(() {
                      configuredPadding = value;
                    });
                  },
                ),
              ),
            ),
            Divider(),
            Text('Output:'),
            Center(
              child: RaisedButton(
                child: Text('Button label'),
                onPressed: () {},
                elevation: configuredPadding,
              ),
            ),
            Divider(),
            Text('Code:'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                getCode(configuredPadding),
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}