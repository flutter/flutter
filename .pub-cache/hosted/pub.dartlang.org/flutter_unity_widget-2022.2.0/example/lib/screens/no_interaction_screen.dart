import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class NoInteractionScreen extends StatefulWidget {
  NoInteractionScreen({Key key}) : super(key: key);

  @override
  _NoInteractionScreenState createState() => _NoInteractionScreenState();
}

class _NoInteractionScreenState extends State<NoInteractionScreen> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  UnityWidgetController _unityWidgetController;

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
        title: Text('No Interaction Screen'),
      ),
      body: Card(
        margin: const EdgeInsets.all(8),
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
              useAndroidViewSurface: true,
              borderRadius: BorderRadius.all(Radius.circular(70)),
            ),
            PointerInterceptor(
              child: Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/simple');
                  },
                  child: Text('Switch Flutter Screen'),
                ),
              ),
            ),
          ],
        ),
      ),
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
