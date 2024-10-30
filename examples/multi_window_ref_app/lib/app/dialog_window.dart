import 'package:flutter/material.dart';

class DialogWindowContent extends StatelessWidget {
  const DialogWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final window = WindowContext.of(context)!.window;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final widget = Scaffold(
      appBar: AppBar(title: const Text('Dialog')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'View ID: ${window.view.viewId}\n'
              'Parent View ID: ${window.parent?.view.viewId}\n'
              'View Size: ${(window.view.physicalSize.width / dpr).toStringAsFixed(1)}\u00D7${(window.view.physicalSize.height / dpr).toStringAsFixed(1)}\n'
              'Window Size: ${window.size.width}\u00D7${window.size.height}\n'
              'Device Pixel Ratio: $dpr',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await destroyWindow(context, window);
              },
              child: const Text('Close'),
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
