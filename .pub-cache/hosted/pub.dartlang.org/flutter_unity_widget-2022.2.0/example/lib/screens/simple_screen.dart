import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class SimpleScreen extends StatefulWidget {
  SimpleScreen({Key key}) : super(key: key);

  @override
  _SimpleScreenState createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  UnityWidgetController _unityWidgetController;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _unityWidgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Simple Screen'),
      ),
      body: Card(
          margin: const EdgeInsets.all(0),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            children: [
              UnityWidget(
                onUnityCreated: _onUnityCreated,
                onUnityMessage: onUnityMessage,
                onUnitySceneLoaded: onUnitySceneLoaded,
                useAndroidViewSurface: false,
                borderRadius: BorderRadius.all(Radius.circular(70)),
              ),
              PointerInterceptor(
                child: Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Card(
                    elevation: 10,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text("Rotation speed:"),
                        ),
                        Slider(
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                            setRotationSpeed(value.toString());
                          },
                          value: _sliderValue,
                          min: 0.0,
                          max: 1.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  void setRotationSpeed(String speed) {
    _unityWidgetController.postMessage(
      'Cube',
      'SetRotationSpeed',
      speed,
    );
  }

  void onUnityMessage(message) {
    print('Received message from unity: ${message.toString()}');
  }

  void onUnitySceneLoaded(SceneLoaded scene) {
    print('Received scene loaded from unity: ${scene.name}');
    print('Received scene loaded from unity buildIndex: ${scene.buildIndex}');
  }

  // Callback that connects the created controller to the unity controller
  void _onUnityCreated(controller) {
    controller.resume();
    this._unityWidgetController = controller;
  }
}
