import 'dart:async';

import 'package:flutter/material.dart';

String message = 'Flutter Debug Loader';
String explanation = 'Please stand by...';
double progress = 0.0;
double progressMax = 0.0;
StateSetter setState = (VoidCallback fn) => fn();
Timer connectionTimeout;

void main() {
  new LoaderBinding();
  runApp(
    new MaterialApp(
      title: 'Flutter Debug Loader',
      debugShowCheckedModeBanner: false,
      home: new Scaffold(
        body: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateRef) {
            setState = setStateRef;
            return new Column(
              children: <Widget>[
                new Flexible(
                  child: new Center(
                    child: new FlutterLogo(size: 100.0),
                  ),
                ),
                new Flexible(
                  child: new Builder(
                    builder: (BuildContext context) {
                      List<Widget> children = <Widget>[];
                      children.add(new Text(
                        message,
                        style: new TextStyle(fontSize: 24.0),
                        textAlign: TextAlign.center
                      ));
                      if (progressMax >= 0.0) {
                        children.add(new SizedBox(height: 18.0));
                        children.add(new Center(child: new CircularProgressIndicator(value: progressMax > 0 ? progress / progressMax : null)));
                      }
                      return new Block(children: children);
                    },
                  ),
                ),
                new Flexible(
                  child: new Block(
                    padding: new EdgeInsets.symmetric(horizontal: 24.0),
                    children: <Widget>[ new Text(explanation, textAlign: TextAlign.center) ]
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  connectionTimeout = new Timer(const Duration(seconds: 8), () {
    setState(() {
      explanation =
        'This is a hot-reload-enabled debug-mode Flutter application. '
        'To launch this application, please use the "flutter run" command. '
        'To be able to launch a Flutter application in debug mode from the '
        'device, please use "flutter run --no-hot". To install a release '
        'mode build of this application on your device, use "flutter install".';
      progressMax = -1.0;
    });
  });
}

class LoaderBinding extends WidgetsFlutterBinding {
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    registerStringServiceExtension(
      name: 'loaderShowMessage',
      getter: () => message,
      setter: (String value) {
        connectionTimeout?.cancel();
        connectionTimeout = null;
        setState(() {
          message = value;
        });
      }
    );
    registerStringServiceExtension(
      name: 'loaderShowExplanation',
      getter: () => explanation,
      setter: (String value) {
        connectionTimeout?.cancel();
        connectionTimeout = null;
        setState(() {
          explanation = value;
        });
      }
    );
    registerNumericServiceExtension(
      name: 'loaderSetProgress',
      getter: () => progress,
      setter: (double value) {
        setState(() {
          progress = value;
        });
      }
    );
    registerNumericServiceExtension(
      name: 'loaderSetProgressMax',
      getter: () => progressMax,
      setter: (double value) {
        setState(() {
          progressMax = value;
        });
      }
    );
  }
}