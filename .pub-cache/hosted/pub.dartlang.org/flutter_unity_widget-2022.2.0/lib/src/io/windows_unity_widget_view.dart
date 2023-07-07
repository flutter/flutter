import 'package:flutter/material.dart';

class WindowsUnityWidgetView extends StatefulWidget {
  const WindowsUnityWidgetView({Key? key}) : super(key: key);

  @override
  State<WindowsUnityWidgetView> createState() => _WindowsUnityWidgetViewState();
}

class _WindowsUnityWidgetViewState extends State<WindowsUnityWidgetView> {
  @override
  Widget build(BuildContext context) {
    // TODO: Rex Update windows view
    return MouseRegion(
      child: Texture(
        textureId: 0,
      ),
    );
  }
}
