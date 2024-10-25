import 'package:flutter/material.dart';
import 'package:multi_window_ref_app/app/popup_window.dart';

import 'custom_positioner_dialog.dart';
import 'positioner_settings.dart';
import 'regular_window.dart';
import 'window_settings.dart';
import 'window_settings_dialog.dart';

class PositionerSettingsModifier with ChangeNotifier {
  int _positionerIndex = 0;
  int get positionerIndex => _positionerIndex;

  final PositionerSettingsContainer _mapping = PositionerSettingsContainer();
  PositionerSettingsContainer get mapping => _mapping;

  void setAtIndex(PositionerSetting setting, int index) {
    if (index >= 0 && index < _mapping.positionerSettingsList.length) {
      _mapping.positionerSettingsList[index] = setting;
      notifyListeners();
    }
  }

  void setSelectedIndex(int index) {
    _positionerIndex =
        index.clamp(0, _mapping.positionerSettingsList.length - 1);
    notifyListeners();
  }

  PositionerSetting? getPositionerSetting(int? index) =>
      index == null ? null : _mapping.positionerSettingsList[index];
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  int selectedRowIndex = -1;
  final positionerSettingsModifier = PositionerSettingsModifier();
  final List<Window> _managedWindows = <Window>[];

  @override
  Widget build(BuildContext context) {
    List<Window> getWindowsInTree(List<Window> windows) {
      return windows
          .expand((window) => [window, ...getWindowsInTree(window.children)])
          .toList();
    }

    final List<Window> windows =
        getWindowsInTree(MultiWindowAppContext.of(context)!.windows);

    final widget = Scaffold(
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
              child: _ActiveWindowsTable(
                windows: windows,
                selectedRowIndex: selectedRowIndex,
                onSelectedRowIndexChanged: (int index) =>
                    setState(() => selectedRowIndex = index),
              ),
            ),
          ),
          Expanded(
            flex: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WindowCreatorCard(
                    selectedWindow: selectedRowIndex < 0 ||
                            selectedRowIndex >= windows.length
                        ? null
                        : windows[selectedRowIndex],
                    positionerSettingsModifier: positionerSettingsModifier,
                    onDialogOpened: (window) => _managedWindows.add(window),
                    onDialogClosed: (window) => _managedWindows.remove(window)),
                const SizedBox(height: 12),
                _PositionerEditorCard(
                    positionerSettingsModifier: positionerSettingsModifier)
              ],
            ),
          ),
        ],
      ),
    );

    final window = WindowContext.of(context)!.window;
    final List<Widget> childViews = <Widget>[];
    for (final Window childWindow in window.children) {
      if (!_shouldRenderWindow(childWindow)) {
        continue;
      }

      childViews.add(View(
        view: childWindow.view,
        child: WindowContext(
          window: childWindow,
          child: childWindow.builder(context),
        ),
      ));
    }

    return ViewAnchor(view: ViewCollection(views: childViews), child: widget);
  }

  bool _shouldRenderWindow(Window window) {
    return !_managedWindows.contains(window);
  }
}

class _ActiveWindowsTable extends StatelessWidget {
  const _ActiveWindowsTable(
      {required this.windows,
      required this.selectedRowIndex,
      required this.onSelectedRowIndexChanged});

  final List<Window> windows;
  final int selectedRowIndex;
  final void Function(int) onSelectedRowIndexChanged;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      showBottomBorder: true,
      onSelectAll: (selected) {
        onSelectedRowIndexChanged(-1);
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
      rows: windows.asMap().entries.map<DataRow>((indexedEntry) {
        final index = indexedEntry.key;
        final Window entry = indexedEntry.value;
        final window = entry;
        final viewId = window.view.viewId;
        final archetype = window.archetype;
        final isSelected = selectedRowIndex == index;

        return DataRow(
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
            }
            return Colors.transparent;
          }),
          selected: isSelected,
          onSelectChanged: (selected) {
            if (selected != null) {
              onSelectedRowIndexChanged(selected ? index : -1);
            }
          },
          cells: [
            DataCell(
              Text('$viewId'),
            ),
            DataCell(
              Text(archetype.toString().replaceFirst('WindowArchetype.', '')),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                onPressed: () {
                  destroyWindow(context, window);
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _WindowCreatorCard extends StatefulWidget {
  const _WindowCreatorCard(
      {required this.selectedWindow,
      required this.positionerSettingsModifier,
      required this.onDialogOpened,
      required this.onDialogClosed});

  final Window? selectedWindow;
  final PositionerSettingsModifier positionerSettingsModifier;
  final void Function(Window) onDialogOpened;
  final void Function(Window) onDialogClosed;

  @override
  State<StatefulWidget> createState() => _WindowCreatorCardState();
}

class _WindowCreatorCardState extends State<_WindowCreatorCard> {
  WindowSettings _settings = WindowSettings();

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
                    await createRegular(
                        context: context,
                        size: _settings.regularSize,
                        builder: (BuildContext context) {
                          return const MaterialApp(home: RegularWindowContent());
                        });
                  },
                  child: const Text('Regular'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _canBeParentOf(WindowArchetype.popup)
                      ? () async {
                          final selectedPositionerSettings = widget
                                  .positionerSettingsModifier
                                  .mapping
                                  .positionerSettingsList[
                              widget
                                  .positionerSettingsModifier.positionerIndex];
                          if (widget.selectedWindow == null) {
                            return;
                          }

                          await createPopup(
                              context: context,
                              parent: widget.selectedWindow!,
                              size: _settings.popupSize,
                              anchorRect: _settings.anchorToWindow
                                  ? null
                                  : _clampRectToSize(_settings.anchorRect,
                                      widget.selectedWindow!.size),
                              positioner: WindowPositioner(
                                parentAnchor:
                                    selectedPositionerSettings.parentAnchor,
                                childAnchor:
                                    selectedPositionerSettings.childAnchor,
                                offset: selectedPositionerSettings.offset,
                                constraintAdjustment: selectedPositionerSettings
                                    .constraintAdjustments,
                              ),
                              builder: (BuildContext context) {
                                return const PopupWindowContent();
                              });
                        }
                      : null,
                  child: Text(_canBeParentOf(WindowArchetype.popup)
                      ? 'Popup of ID ${widget.selectedWindow!.view.viewId}'
                      : 'Popup'),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    child: const Text('SETTINGS'),
                    onPressed: () {
                      windowSettingsDialog(context, _settings,
                              widget.onDialogOpened, widget.onDialogClosed)
                          .then(
                        (WindowSettings? settings) {
                          if (settings != null) {
                            _settings = settings;
                          }
                        },
                      );
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

  // Check if the currently selected window can be made the parent of a
  // window with the specified archetype.
  bool _canBeParentOf(WindowArchetype archetype) {
    return widget.selectedWindow?.canBeParentOf(archetype) ?? false;
  }

  Rect _clampRectToSize(Rect anchorRect, Size? size) {
    double left = anchorRect.left.clamp(0, size?.width as double);
    double top = anchorRect.top.clamp(0, size?.height as double);
    double right = anchorRect.right.clamp(0, size?.width as double);
    double bottom = anchorRect.bottom.clamp(0, size?.height as double);
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _PositionerEditorCard extends StatefulWidget {
  const _PositionerEditorCard({required this.positionerSettingsModifier});

  final PositionerSettingsModifier positionerSettingsModifier;

  @override
  State<_PositionerEditorCard> createState() => _PositionerEditorCardState();
}

class _PositionerEditorCardState extends State<_PositionerEditorCard> {
  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 15, 5),
          child: ListenableBuilder(
              listenable: widget.positionerSettingsModifier,
              builder: (BuildContext context, _) {
                final positionerSettingsList = widget
                    .positionerSettingsModifier.mapping.positionerSettingsList;
                final selectedName = positionerSettingsList[
                        widget.positionerSettingsModifier.positionerIndex]
                    .name;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Positioner',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Preset'),
                      subtitle: DropdownButton(
                        items: positionerSettingsList
                            .map((PositionerSetting setting) =>
                                DropdownMenuItem<String>(
                                  value: setting.name,
                                  child: Text(setting.name),
                                ))
                            .toList(),
                        value: selectedName,
                        isExpanded: true,
                        focusColor: Colors.transparent,
                        onChanged: (String? value) {
                          setState(() {
                            widget.positionerSettingsModifier.setSelectedIndex(
                              positionerSettingsList.indexWhere(
                                  (setting) => setting.name == value),
                            );
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextButton(
                          child: const Text('CUSTOM PRESET'),
                          onPressed: () async {
                            final settings = await customPositionerDialog(
                              context,
                              positionerSettingsList.last,
                            );
                            if (settings != null) {
                              setState(() {
                                final pos = positionerSettingsList.length - 1;
                                widget.positionerSettingsModifier
                                    .setAtIndex(settings, pos);
                                widget.positionerSettingsModifier
                                    .setSelectedIndex(pos);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              })),
    );
  }
}
