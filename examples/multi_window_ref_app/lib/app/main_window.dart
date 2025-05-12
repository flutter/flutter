// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/window_controller_render.dart';

import 'regular_window_content.dart';
import 'window_settings.dart';
import 'window_settings_dialog.dart';
import 'window_manager_model.dart';
import 'regular_window_edit_dialog.dart';

class MainWindow extends StatefulWidget {
  MainWindow({super.key, required WindowController mainController}) {
    _windowManagerModel.add(
        KeyedWindowController(isMainWindow: true, key: UniqueKey(), controller: mainController));
  }

  final WindowManagerModel _windowManagerModel = WindowManagerModel();
  final WindowSettings _settings = WindowSettings();

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(
        title: const Text('Multi Window Reference App'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: _ActiveWindowsTable(windowManagerModel: widget._windowManagerModel),
            ),
          ),
          Expanded(
            flex: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                    listenable: widget._windowManagerModel,
                    builder: (BuildContext context, Widget? child) {
                      return _WindowCreatorCard(
                          selectedWindow: widget._windowManagerModel.selected,
                          windowManagerModel: widget._windowManagerModel,
                          windowSettings: widget._settings);
                    })
              ],
            ),
          ),
        ],
      ),
    );

    return ViewAnchor(
        view: ListenableBuilder(
            listenable: widget._windowManagerModel,
            builder: (BuildContext context, Widget? _) {
              final List<Widget> childViews = <Widget>[];
              for (final KeyedWindowController controller in widget._windowManagerModel.windows) {
                if (controller.parent == null && !controller.isMainWindow) {
                  childViews.add(WindowControllerRender(
                    controller: controller.controller,
                    key: controller.key,
                    windowSettings: widget._settings,
                    windowManagerModel: widget._windowManagerModel,
                    onDestroyed: () => widget._windowManagerModel.remove(controller.key),
                    onError: () => widget._windowManagerModel.remove(controller.key),
                  ));
                }
              }

              return ViewCollection(views: childViews);
            }),
        child: child);
  }
}

class _ActiveWindowsTable extends StatelessWidget {
  const _ActiveWindowsTable({required this.windowManagerModel});

  final WindowManagerModel windowManagerModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: windowManagerModel,
        builder: (BuildContext context, Widget? widget) {
          return DataTable(
            showBottomBorder: true,
            onSelectAll: (selected) {
              windowManagerModel.select(null);
            },
            columns: const [
              DataColumn(
                label: SizedBox(
                  width: 20,
                  child: Text(
                    'ID',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              DataColumn(
                  label: SizedBox(
                    width: 20,
                    child: Text(''),
                  ),
                  numeric: true),
            ],
            rows: (windowManagerModel.windows).map<DataRow>((KeyedWindowController controller) {
              return DataRow(
                key: controller.key,
                color: WidgetStateColor.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary.withAlpha(20);
                  }
                  return Colors.transparent;
                }),
                selected: controller.controller == windowManagerModel.selected,
                onSelectChanged: (selected) {
                  if (selected != null) {
                    windowManagerModel
                        .select(selected ? controller.controller.rootView.viewId : null);
                  }
                },
                cells: [
                  DataCell(Text('$controller.controller.rootView.viewId')),
                  DataCell(
                    ListenableBuilder(
                        listenable: controller.controller,
                        builder: (BuildContext context, Widget? _) => Text(controller
                            .controller.type
                            .toString()
                            .replaceFirst('WindowArchetype.', ''))),
                  ),
                  DataCell(
                    ListenableBuilder(
                        listenable: controller.controller,
                        builder: (BuildContext context, Widget? _) => Row(children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  if (controller.controller.type == WindowArchetype.regular) {
                                    showRegularWindowEditDialog(context,
                                        initialWidth: controller.controller.contentSize.width,
                                        initialHeight: controller.controller.contentSize.height,
                                        initialTitle: "",
                                        initialState:
                                            (controller.controller as RegularWindowController)
                                                .state, onSave: (double? width, double? height,
                                            String? title, WindowState? state) {
                                      final regularController =
                                          controller.controller as RegularWindowController;
                                      if (width != null && height != null) {
                                        regularController.updateContentSize(
                                          WindowSizing(preferredSize: Size(width, height)),
                                        );
                                      }
                                      if (title != null) {
                                        regularController.setTitle(title);
                                      }
                                      if (state != null) {
                                        regularController.setState(state);
                                      }
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outlined),
                                onPressed: () async {
                                  controller.controller.destroy();
                                },
                              )
                            ])),
                  ),
                ],
              );
            }).toList(),
          );
        });
  }
}

class _WindowCreatorCard extends StatelessWidget {
  const _WindowCreatorCard(
      {required this.selectedWindow,
      required this.windowManagerModel,
      required this.windowSettings});

  final WindowController? selectedWindow;
  final WindowManagerModel windowManagerModel;
  final WindowSettings windowSettings;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                'New Window',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final UniqueKey key = UniqueKey();
                    windowManagerModel.add(KeyedWindowController(
                        key: key,
                        controller: RegularWindowController(
                          delegate: WindowControllerDelegate(
                            onDestroyed: () => windowManagerModel.remove(key),
                          ),
                          title: "Regular",
                          contentSize: WindowSizing(preferredSize: windowSettings.regularSize),
                        )));
                  },
                  child: const Text('Regular'),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    child: const Text('SETTINGS'),
                    onPressed: () {
                      windowSettingsDialog(context, windowSettings);
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
