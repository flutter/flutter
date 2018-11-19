import 'package:flutter/material.dart';

class MaterialRaisedButtonDemo extends StatefulWidget {
  const MaterialRaisedButtonDemo({Key key}) : super(key: key);

  @override
  _MaterialRaisedButtonDemoState createState() =>
      _MaterialRaisedButtonDemoState();
}

class _MaterialRaisedButtonDemoState extends State<MaterialRaisedButtonDemo> {
  double elevation = 8.0;

  final List<String> properties = <String>[
    'Elevation',
    'BorderShape',
    'Color',
    'SplashColor'
  ];

  static const double labelFontSize = 16.0;
  static const Color labelColor = Colors.blue;

  String _getCode(double padding) {
    return """
FlatButton(
  child: Text('Button'),
  elevation: $elevation,
),
""";
  }

  Widget _propertyColumn(String label, Widget widget) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 15.0).copyWith(top: 10.0),
            child: Text(
              label,
              style: const TextStyle(
                color: labelColor,
                fontSize: labelFontSize,
              ),
            ),
          ),
          widget,
        ]);
  }

  Widget _primaryWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 19.0).copyWith(bottom: 20.0),
      child: Center(
        child: RaisedButton(
          child: const Text('Button'),
          onPressed: () {},
          elevation: elevation,
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
          _primaryWidget(),
          const Divider(),
          _propertyColumn(
            'Elevation',
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Slider(
                value: elevation,
                min: 0.0,
                max: 24.0,
                divisions: 3,
                onChanged: (double value) {
                  setState(() {
                    elevation = value;
                  });
                },
              ),
            ),
          ),
          _propertyColumn(
            'Color',
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Slider(
                value: elevation,
                min: 0.0,
                max: 24.0,
                divisions: 3,
                onChanged: (double value) {
                  setState(() {
                    elevation = value;
                  });
                },
              ),
            ),
          ),

          // TODO breakout to code panel
          // see TabbedComponentDemoScaffold._showExampleCode
          const Divider(),
          const Text('Code:'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _getCode(elevation),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
