import 'package:flutter/material.dart';

class SatelliteWindowContent extends StatelessWidget {
  const SatelliteWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final window = WindowContext.of(context)!.window;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final widget = Scaffold(
      appBar: AppBar(title: const Text('Satellite')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'View ID: ${window.view.viewId}\n'
              'Parent View ID: ${window.parent?.view.viewId}\n'
              'View Size:\n${(window.view.physicalSize.width / dpr).toStringAsFixed(1)}\u00D7${(window.view.physicalSize.height / dpr).toStringAsFixed(1)}\n'
              'Window Size:\n${window.size.width}\u00D7${window.size.height}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final List<Widget> childViews = window.children.map((childWindow) {
      return View(
        view: childWindow.view,
        child: WindowContext(
          window: childWindow,
          child: childWindow.builder(context),
        ),
      );
    }).toList();

    return ViewAnchor(view: ViewCollection(views: childViews), child: widget);
  }
}
