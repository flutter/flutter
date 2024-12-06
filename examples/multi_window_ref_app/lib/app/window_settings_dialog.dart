import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_settings.dart';

Future<void> windowSettingsDialog(
    BuildContext context, WindowSettings settings) async {
  return await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(4),
          titlePadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          title: const Center(
            child: Text('Window Settings'),
          ),
          children: [
            SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: _RegularWindowSettingsTile(settings: settings),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _PopupWindowSettingsTile(settings: settings),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    const Divider(),
                    Row(children: [
                      Expanded(
                        child: _AnchorSettingsTile(settings: settings),
                      ),
                    ]),
                    const SizedBox(
                      height: 2,
                    ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text('Apply'),
              ),
            ),
            const SizedBox(
              height: 2,
            ),
          ],
        );
      });
}

class _RegularWindowSettingsTile extends StatelessWidget {
  const _RegularWindowSettingsTile({required this.settings});

  final WindowSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Regular'),
      subtitle: ListenableBuilder(
          listenable: settings.regularSizeNotifier,
          builder: (BuildContext ctx, Widget? _) {
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue:
                        settings.regularSizeNotifier.value.width.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Initial width',
                    ),
                    onChanged: (String value) => settings.regularSize = Size(
                        double.tryParse(value) ?? 0,
                        settings.regularSizeNotifier.value.height),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        settings.regularSizeNotifier.value.height.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Initial height',
                    ),
                    onChanged: (String value) => settings.regularSize = Size(
                        settings.regularSizeNotifier.value.width,
                        double.tryParse(value) ?? 0),
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class _PopupWindowSettingsTile extends StatelessWidget {
  const _PopupWindowSettingsTile({required this.settings});

  final WindowSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Popup'),
      subtitle: ListenableBuilder(
          listenable: settings.popupSizeNotifier,
          builder: (BuildContext context, Widget? _) => Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          settings.popupSizeNotifier.value.width.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Initial width',
                      ),
                      onChanged: (String value) => settings.popupSize = Size(
                          double.tryParse(value) ?? 0,
                          settings.popupSizeNotifier.value.height),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          settings.popupSizeNotifier.value.height.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Initial height',
                      ),
                      onChanged: (String value) => settings.popupSize = Size(
                          settings.popupSizeNotifier.value.width,
                          double.tryParse(value) ?? 0),
                    ),
                  ),
                ],
              )),
    );
  }
}

class _AnchorSettingsTile extends StatelessWidget {
  const _AnchorSettingsTile({required this.settings});

  final WindowSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: settings.anchorRectNotifier,
        builder: (BuildContext context, Widget? _) {
          return ListenableBuilder(
              listenable: settings.anchorToWindowNotifier,
              builder: (BuildContext context, Widget? _) {
                return ListTile(
                  title: const Text('Anchoring'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CheckboxListTile(
                          title: const Text('Anchor to Window'),
                          subtitle: const Text(
                              "Use the parent's window frame as the anchor rectangle"),
                          contentPadding: EdgeInsets.zero,
                          value: settings.anchorToWindowNotifier.value,
                          onChanged: (bool? value) {
                            settings.anchorToWindow = value ?? false;
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "View Anchor Rectangle (values will be clamped to the size of the parent view)",
                          style: TextStyle(
                            color: settings.anchorToWindowNotifier.value
                                ? Theme.of(context).disabledColor
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: !settings.anchorToWindowNotifier.value,
                              initialValue: settings
                                  .anchorRectNotifier.value.left
                                  .toString(),
                              decoration: const InputDecoration(
                                labelText: 'Left',
                              ),
                              onChanged: settings.anchorToWindowNotifier.value
                                  ? null
                                  : (String value) => settings.anchorRect =
                                      Rect.fromLTWH(
                                          double.tryParse(value) ?? 0,
                                          settings.anchorRectNotifier.value.top,
                                          settings
                                              .anchorRectNotifier.value.width,
                                          settings
                                              .anchorRectNotifier.value.height),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: !settings.anchorToWindowNotifier.value,
                              initialValue: settings
                                  .anchorRectNotifier.value.top
                                  .toString(),
                              decoration: const InputDecoration(
                                labelText: 'Top',
                              ),
                              onChanged: settings.anchorToWindowNotifier.value
                                  ? null
                                  : (String value) => settings.anchorRect =
                                      Rect.fromLTWH(
                                          settings
                                              .anchorRectNotifier.value.left,
                                          double.tryParse(value) ?? 0,
                                          settings
                                              .anchorRectNotifier.value.width,
                                          settings
                                              .anchorRectNotifier.value.height),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: !settings.anchorToWindowNotifier.value,
                              initialValue: settings
                                  .anchorRectNotifier.value.width
                                  .toString(),
                              decoration: const InputDecoration(
                                labelText: 'Width',
                              ),
                              onChanged: settings.anchorToWindowNotifier.value
                                  ? null
                                  : (String value) => settings.anchorRect =
                                      Rect.fromLTWH(
                                          settings
                                              .anchorRectNotifier.value.left,
                                          settings.anchorRectNotifier.value.top,
                                          double.tryParse(value) ?? 0,
                                          settings
                                              .anchorRectNotifier.value.height),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: !settings.anchorToWindowNotifier.value,
                              initialValue: settings
                                  .anchorRectNotifier.value.height
                                  .toString(),
                              decoration: const InputDecoration(
                                labelText: 'Height',
                              ),
                              onChanged: settings.anchorToWindowNotifier.value
                                  ? null
                                  : (String value) => settings
                                          .anchorRectNotifier.value =
                                      Rect.fromLTWH(
                                          settings
                                              .anchorRectNotifier.value.left,
                                          settings.anchorRectNotifier.value.top,
                                          settings
                                              .anchorRectNotifier.value.width,
                                          double.tryParse(value) ?? 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              });
        });
  }
}
