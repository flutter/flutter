import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(new Center(child: new Flavor()));
}

class Flavor extends StatefulWidget {
  @override
  _FlavorState createState() => new _FlavorState();
}

class _FlavorState extends State<Flavor> {
  String _flavor;

  @override
  void initState() {
    super.initState();
    const MethodChannel('flavor').invokeMethod('getFlavor').then((Object flavor) {
      setState(() {
        _flavor = flavor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.ltr,
      child: _flavor == null
        ? const Text('Awaiting flavor...')
        : new Text(_flavor, key: const ValueKey<String>('flavor')),
    );
  }
}
