import 'package:flutter/material.dart';

class DialogWindowContent extends StatelessWidget {
  const DialogWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final window = WindowContext.of(context)!.window;

    final widget = Scaffold(
      appBar: AppBar(title: Text('${window.archetype}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'View #${window.view.viewId}\n'
              'Parent View: ${window.parent?.view.viewId}\n'
              'Logical Size: ${window.size.width}\u00D7${window.size.height}\n'
              'DPR: ${MediaQuery.of(context).devicePixelRatio}',
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
