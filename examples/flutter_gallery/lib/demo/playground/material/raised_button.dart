import 'package:flutter/material.dart';

class MaterialRaisedButtonDemo extends StatefulWidget {
  const MaterialRaisedButtonDemo({Key key}) : super(key: key);

  @override
  _MaterialRaisedButtonDemoState createState() => _MaterialRaisedButtonDemoState();
}

class _MaterialRaisedButtonDemoState extends State<MaterialRaisedButtonDemo> {
  String selectedWidget = 'FlatButton';
  String selectedProperty = 'Elevation';

  double configuredPadding = 8.0;

  String _getCode(double padding) {
    return """
FlatButton(
  child: Text('Button'),
  elevation: $padding,
),
""";
  }

  Widget _widgetListTile() {
    return ListTile(
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
    );
  }

  Widget _propertyListTile() {
    return ListTile(
      title: const Text('Property:'),
      trailing: DropdownButton<String>(
        value: selectedProperty,
        onChanged: (String newValue) {
          setState(() {
            selectedProperty = newValue;
          });
        },
        items: <String>['Elevation', 'BorderShape', 'Color', 'SplashColor']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _propertyValueListTile() {
    return ListTile(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          // PRIMARY WIDGET, breakout
          Padding(
            padding: const EdgeInsets.only(top: 20.0).copyWith(bottom: 20.0),
            child: Center(
              child: RaisedButton(
                child: const Text('Button'),
                onPressed: () {},
                elevation: configuredPadding,
              ),
            ),
          ),
          const Divider(),
          _widgetListTile(),
          _propertyListTile(),
          _propertyValueListTile(),

          // TODO breakout to code panel
          // see TabbedComponentDemoScaffold._showExampleCode
          const Divider(),
          const Text('Code:'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getCode(configuredPadding),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
