import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_settings.dart';

Future<WindowSettings?> windowSettingsDialog(
    BuildContext context, WindowSettings settings) async {
  return await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext ctx) {
        Size regularSize = settings.regularSize;
        Size floatingRegularSize = settings.floatingRegularSize;
        Size dialogSize = settings.dialogSize;
        Size satelliteSize = settings.satelliteSize;
        Size popupSize = settings.popupSize;
        Size tipSize = settings.tipSize;
        Rect anchorRect = settings.anchorRect;
        bool anchorToWindow = settings.anchorToWindow;

        return StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setState) {
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
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Regular'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: regularSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => regularSize = Size(
                                          double.tryParse(value) ?? 0,
                                          regularSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: regularSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => regularSize = Size(
                                          regularSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Floating Regular'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        floatingRegularSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => floatingRegularSize = Size(
                                          double.tryParse(value) ?? 0,
                                          floatingRegularSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        floatingRegularSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => floatingRegularSize = Size(
                                          regularSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Dialog'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: dialogSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => dialogSize = Size(
                                          double.tryParse(value) ?? 0,
                                          dialogSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: dialogSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => dialogSize = Size(dialogSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Satellite'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        satelliteSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => satelliteSize = Size(
                                          double.tryParse(value) ?? 0,
                                          satelliteSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        satelliteSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => satelliteSize = Size(
                                          satelliteSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Popup'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: popupSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => popupSize = Size(
                                          double.tryParse(value) ?? 0,
                                          popupSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: popupSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => popupSize = Size(popupSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Tip'),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: tipSize.width.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial width',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => tipSize = Size(
                                          double.tryParse(value) ?? 0,
                                          tipSize.height),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: tipSize.height.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Initial height',
                                    ),
                                    onChanged: (String value) => setState(
                                      () => tipSize = Size(tipSize.width,
                                          double.tryParse(value) ?? 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
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
                                    value: anchorToWindow,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        anchorToWindow = value ?? false;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "View Anchor Rectangle (values will be clamped to the size of the parent view)",
                                    style: TextStyle(
                                      color: anchorToWindow
                                          ? Theme.of(context).disabledColor
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        enabled: !anchorToWindow,
                                        initialValue:
                                            anchorRect.left.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Left',
                                        ),
                                        onChanged: anchorToWindow
                                            ? null
                                            : (String value) => setState(
                                                  () => anchorRect =
                                                      Rect.fromLTWH(
                                                          double.tryParse(
                                                                  value) ??
                                                              0,
                                                          anchorRect.top,
                                                          anchorRect.width,
                                                          anchorRect.height),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        enabled: !anchorToWindow,
                                        initialValue: anchorRect.top.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Top',
                                        ),
                                        onChanged: anchorToWindow
                                            ? null
                                            : (String value) => setState(
                                                  () => anchorRect =
                                                      Rect.fromLTWH(
                                                          anchorRect.left,
                                                          double.tryParse(
                                                                  value) ??
                                                              0,
                                                          anchorRect.width,
                                                          anchorRect.height),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        enabled: !anchorToWindow,
                                        initialValue:
                                            anchorRect.width.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Width',
                                        ),
                                        onChanged: anchorToWindow
                                            ? null
                                            : (String value) => setState(
                                                  () => anchorRect =
                                                      Rect.fromLTWH(
                                                          anchorRect.left,
                                                          anchorRect.top,
                                                          double.tryParse(
                                                                  value) ??
                                                              0,
                                                          anchorRect.height),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        enabled: !anchorToWindow,
                                        initialValue:
                                            anchorRect.height.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Height',
                                        ),
                                        onChanged: anchorToWindow
                                            ? null
                                            : (String value) => setState(
                                                  () => anchorRect =
                                                      Rect.fromLTWH(
                                                          anchorRect.left,
                                                          anchorRect.top,
                                                          anchorRect.width,
                                                          double.tryParse(
                                                                  value) ??
                                                              0),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true)
                        .pop(WindowSettings(
                      regularSize: regularSize,
                      floatingRegularSize: floatingRegularSize,
                      dialogSize: dialogSize,
                      satelliteSize: satelliteSize,
                      popupSize: popupSize,
                      tipSize: tipSize,
                      anchorRect: anchorRect,
                      anchorToWindow: anchorToWindow,
                    ));
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
      });
}
