import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_controller_render.dart';
import 'package:multi_window_ref_app/app/window_settings.dart';

class RegularWindowContent extends StatefulWidget {
  const RegularWindowContent({super.key, required this.window, required this.windowSettings});

  final RegularWindowController window;
  final WindowSettings windowSettings;

  @override
  State<RegularWindowContent> createState() => _RegularWindowContentState();
}

class _RegularWindowContentState extends State<RegularWindowContent> {
  List<WindowController> childControllers = <WindowController>[];

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(title: Text('${widget.window.type}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  childControllers = [
                    ...childControllers,
                    RegularWindowController()
                  ];
                });
              },
              child: const Text('Create Regular Window'),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
                listenable: widget.window,
                builder: (BuildContext context, Widget? _) {
                  return Text(
                    'View #${widget.window.view?.viewId ?? "Unknown"}\n'
                    'Parent View: ${widget.window.parentViewId}\n'
                    'Logical Size: ${widget.window.size?.width ?? "?"}\u00D7${widget.window.size?.height ?? "?"}\n'
                    'DPR: ${MediaQuery.of(context).devicePixelRatio}',
                    textAlign: TextAlign.center,
                  );
                })
          ],
        ),
      ),
    );

    final List<Widget> childViews =
        childControllers.map((WindowController controller) {
      return WindowControllerRender(
          controller: controller,
          windowSettings: widget.windowSettings,
          onDestroyed: () {
            childControllers.remove(controller);
          });
    }).toList();

    return ViewAnchor(view: ViewCollection(views: childViews), child: child);
  }
}
