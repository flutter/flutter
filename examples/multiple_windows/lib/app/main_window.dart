// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'dialog_window_content.dart';
import 'dialog_window_edit_dialog.dart';
import 'models.dart';
import 'popup_button.dart';
import 'popup_window_edit_dialog.dart';
import 'regular_window_content.dart';
import 'regular_window_edit_dialog.dart';
import 'tooltip_button.dart';
import 'tooltip_window_edit_dialog.dart';
import 'window_settings_dialog.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key, required this.controller});

  final RegularWindowController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Window Reference App')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(child: _WindowsTable(mainWindow: controller)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: _WindowCreatorCard())],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowsTable extends StatelessWidget {
  const _WindowsTable({required this.mainWindow});

  final RegularWindowController mainWindow;

  DataRow _buildRow(BaseWindowController controller, BuildContext context) {
    return DataRow(
      key: ValueKey(controller.rootView.viewId),
      color: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).colorScheme.primary.withAlpha(20);
        }
        return Colors.transparent;
      }),
      cells: [
        DataCell(Text('${controller.rootView.viewId}')),
        DataCell(Text(_getWindowTypeName(controller))),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showWindowEditDialog(controller, context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                onPressed: () async {
                  controller.destroy();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildRows(WindowRegistry windowRegistry, BuildContext context) {
    final List<DataRow> rows = [_buildRow(mainWindow, context)];
    for (final WindowEntry entry in windowRegistry.windows) {
      final BaseWindowController controller = entry.controller;
      rows.add(_buildRow(controller, context));
    }

    return rows;
  }

  void _showWindowEditDialog(BaseWindowController controller, BuildContext context) {
    return switch (controller) {
      final RegularWindowController regular => showRegularWindowEditDialog(
        context: context,
        controller: regular,
      ),
      final DialogWindowController dialog => showDialogWindowEditDialog(
        context: context,
        controller: dialog,
      ),
      final TooltipWindowController tooltip => showTooltipWindowEditDialog(
        context: context,
        controller: tooltip,
      ),
      final PopupWindowController popup => showPopupWindowEditDialog(
        context: context,
        controller: popup,
      ),
      SatelliteWindowController() => null,
    };
  }

  static String _getWindowTypeName(BaseWindowController controller) {
    return switch (controller) {
      RegularWindowController() => 'Regular',
      DialogWindowController() => 'Dialog',
      TooltipWindowController() => 'Tooltip',
      PopupWindowController() => 'Popup',
      SatelliteWindowController() => 'Satellite',
    };
  }

  @override
  Widget build(BuildContext context) {
    final WindowRegistry windowRegistry = WindowRegistry.of(context);
    return ListenableBuilder(
      listenable: windowRegistry,
      builder: (BuildContext context, Widget? child) {
        return DataTable(
          showBottomBorder: true,
          columns: const [
            DataColumn(
              label: SizedBox(width: 20, child: Text('ID', style: TextStyle(fontSize: 16))),
            ),
            DataColumn(
              label: SizedBox(width: 120, child: Text('Type', style: TextStyle(fontSize: 16))),
            ),
            DataColumn(label: SizedBox(width: 20, child: Text('')), numeric: true),
          ],
          rows: _buildRows(windowRegistry, context),
        );
      },
    );
  }
}

class _WindowCreatorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final WindowRegistry windowRegistry = WindowRegistry.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
    final BaseWindowController windowController = WindowScope.of(context);

    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 5),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                'New Window',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        late final WindowEntry entry;
                        final controller = RegularWindowController(
                          delegate: CallbackRegularWindowControllerDelegate(
                            onDestroyed: () => windowRegistry.unregister(entry),
                          ),
                          title: 'Regular',
                          preferredSize: windowSettings.regularSize,
                        );

                        entry = WindowEntry(
                          controller: controller,
                          builder: (BuildContext context) =>
                              RegularWindowContent(regularWindowController: controller),
                        );
                        windowRegistry.register(entry);
                      },
                      child: const Text('Regular'),
                    ),
                    const SizedBox(height: 8),
                    TooltipButton(parentController: windowController),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        late final WindowEntry entry;
                        final controller = DialogWindowController(
                          delegate: CallbackDialogWindowControllerDelegate(
                            onDestroyed: () => windowRegistry.unregister(entry),
                          ),
                          title: 'Modeless Dialog',
                          preferredSize: windowSettings.dialogSize,
                        );

                        entry = WindowEntry(
                          controller: controller,
                          builder: (BuildContext context) =>
                              DialogWindowContent(dialogWindowController: controller),
                        );
                        windowRegistry.register(entry);
                      },
                      child: const Text('Modeless Dialog'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        late final WindowEntry entry;
                        final controller = DialogWindowController(
                          delegate: CallbackDialogWindowControllerDelegate(
                            onDestroyed: () => windowRegistry.unregister(entry),
                          ),
                          title: 'Modal Dialog',
                          preferredSize: windowSettings.dialogSize,
                          parent: windowController,
                        );

                        entry = WindowEntry(
                          controller: controller,
                          builder: (BuildContext context) =>
                              DialogWindowContent(dialogWindowController: controller),
                        );
                        windowRegistry.register(entry);
                      },
                      child: const Text('Modal Dialog'),
                    ),
                    const SizedBox(height: 8),
                    PopupButton(parentController: windowController),
                    const SizedBox(height: 8),
                    Container(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        child: const Text('SETTINGS'),
                        onPressed: () {
                          showWindowSettingsDialog(context, windowSettings);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
