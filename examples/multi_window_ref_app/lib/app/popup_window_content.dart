import 'package:flutter/material.dart';
import 'window_settings.dart';
import 'window_manager_model.dart';

class PopupWindowContent extends StatelessWidget {
  const PopupWindowContent({super.key});

  final RegularWindowController window;
  final WindowSettings windowSettings;
  final WindowManagerModel windowManagerModel;

  @override
  Widget build(BuildContext context) {
    final window = WindowContext.of(context)!.window;

    final widget = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Popup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  await createPopup(
                      context: context,
                      parent: window,
                      size: const Size(200, 200),
                      anchorRect: Rect.fromLTWH(
                          0, 0, window.size.width, window.size.height),
                      positioner: const WindowPositioner(
                        parentAnchor: WindowPositionerAnchor.center,
                        childAnchor: WindowPositionerAnchor.center,
                        offset: Offset(100, 100),
                        constraintAdjustment: <WindowPositionerConstraintAdjustment>{
                          WindowPositionerConstraintAdjustment.slideX,
                          WindowPositionerConstraintAdjustment.slideY,
                        },
                      ),
                      builder: (BuildContext context) =>
                          const PopupWindowContent());
                },
                child: const Text('Another popup'),
              ),
              const SizedBox(height: 16.0),
              Text(
                'View #${window.view.viewId}\n'
                'Parent View: ${window.parent?.view.viewId}\n'
                'Logical Size: ${window.size.width}\u00D7${window.size.height}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ],
          ),
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
