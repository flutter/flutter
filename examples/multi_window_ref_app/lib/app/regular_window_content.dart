import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_metadata_content.dart';

class RegularWindowContent extends StatefulWidget {
  const RegularWindowContent({super.key, required this.window});

  final RegularWindowController window;

  @override
  State<RegularWindowContent> createState() => _RegularWindowContentState();
}

class _RegularWindowContentState extends State<RegularWindowContent> {
  List<WindowController> children = <WindowController>[];

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
                  children = [...children, RegularWindowController()];
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
        children.map((WindowController childWindow) {
      return WindowMetadataContent(controller: childWindow);
    }).toList();

    return ViewAnchor(view: ViewCollection(views: childViews), child: child);
  }
}
