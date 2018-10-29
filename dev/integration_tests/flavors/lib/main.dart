import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(Center(child: Flavor()));
}

class Flavor extends StatefulWidget {
  @override
  _FlavorState createState() => _FlavorState();
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _flavor == null
        ? const Text('Awaiting flavor...')
        : Text(_flavor, key: const ValueKey<String>('flavor')),
    );
  }
}
