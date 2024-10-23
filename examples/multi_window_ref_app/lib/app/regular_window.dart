import 'package:flutter/material.dart';

class RegularWindowContent extends StatelessWidget {
  const RegularWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final Window window = WindowContext.of(context)!.window;
    final widget = Scaffold(
      appBar: AppBar(title: Text('${window.archetype}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await createRegular(
                    context: context,
                    size: const Size(400, 300),
                    builder: (BuildContext context) =>
                        const MaterialApp(home: RegularWindowContent()));
              },
              child: const Text('Create Regular Window'),
            ),
            const SizedBox(height: 20),
            Text(
              'View #${window.view.viewId}\n'
              'Parent View: ${window.parent?.view.viewId}\n'
              'Logical Size: ${window.size.width}\u00D7${window.size.height}\n'
              'DPR: ${MediaQuery.of(context).devicePixelRatio}',
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
