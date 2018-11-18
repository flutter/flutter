import 'package:flutter/material.dart';

// TODO accept `type` and make this more generic to support both "material" and "cupertino"
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({Key key, this.title, this.type}) : super(key: key);

  final String title;
  final String type;

  @override
  _PlaygroundPageState createState() => _PlaygroundPageState();
}

enum SupportedWidgets { FlatButton, RaisedButton }

class _PlaygroundPageState extends State<PlaygroundPage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedWidget = 'FlatButton';
  String selectedProperty = 'Elevation';

  double configuredPadding = 8.0;

  // TODO move to specific widget examples
  String getCode(double padding) {
    return """
FlatButton(
  child: Text('Button'),
  elevation: $padding,
),
""";
  }

  // TODO build from widget examples
  Widget _playgroundChild() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 20.0).copyWith(bottom: 20.0),
            child: Center(
              child: RaisedButton(
                child: const Text('Button label'),
                onPressed: () {},
                elevation: configuredPadding,
              ),
            ),
          ),
          const Divider(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: 'Back',
          onPressed: () {
            Navigator.maybePop(context);
          }
        ),
      ),
      body: _playgroundChild(),
    );
  }
}
