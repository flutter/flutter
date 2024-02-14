// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/demos/material/material_demo_types.dart';

class ChipDemo extends StatelessWidget {
  const ChipDemo({
    super.key,
    required this.type,
  });

  final ChipDemoType type;

  String _title(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    switch (type) {
      case ChipDemoType.action:
        return localizations.demoActionChipTitle;
      case ChipDemoType.choice:
        return localizations.demoChoiceChipTitle;
      case ChipDemoType.filter:
        return localizations.demoFilterChipTitle;
      case ChipDemoType.input:
        return localizations.demoInputChipTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? buttons;
    switch (type) {
      case ChipDemoType.action:
        buttons = _ActionChipDemo();
        break;
      case ChipDemoType.choice:
        buttons = _ChoiceChipDemo();
        break;
      case ChipDemoType.filter:
        buttons = _FilterChipDemo();
        break;
      case ChipDemoType.input:
        buttons = _InputChipDemo();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title(context)),
      ),
      body: buttons,
    );
  }
}

// BEGIN chipDemoAction

class _ActionChipDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ActionChip(
        onPressed: () {},
        avatar: const Icon(
          Icons.brightness_5,
          color: Colors.black54,
        ),
        label: Text(GalleryLocalizations.of(context)!.chipTurnOnLights),
      ),
    );
  }
}

// END

// BEGIN chipDemoChoice

class _ChoiceChipDemo extends StatefulWidget {
  @override
  _ChoiceChipDemoState createState() => _ChoiceChipDemoState();
}

class _ChoiceChipDemoState extends State<_ChoiceChipDemo>
    with RestorationMixin {
  final RestorableIntN _indexSelected = RestorableIntN(null);

  @override
  String get restorationId => 'choice_chip_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_indexSelected, 'choice_chip');
  }

  @override
  void dispose() {
    _indexSelected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            children: [
              ChoiceChip(
                label: Text(localizations.chipSmall),
                selected: _indexSelected.value == 0,
                onSelected: (value) {
                  setState(() {
                    _indexSelected.value = value ? 0 : -1;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(localizations.chipMedium),
                selected: _indexSelected.value == 1,
                onSelected: (value) {
                  setState(() {
                    _indexSelected.value = value ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(localizations.chipLarge),
                selected: _indexSelected.value == 2,
                onSelected: (value) {
                  setState(() {
                    _indexSelected.value = value ? 2 : -1;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Disabled chips
          Wrap(
            children: [
              ChoiceChip(
                label: Text(localizations.chipSmall),
                selected: _indexSelected.value == 0,
                onSelected: null,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(localizations.chipMedium),
                selected: _indexSelected.value == 1,
                onSelected: null,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(localizations.chipLarge),
                selected: _indexSelected.value == 2,
                onSelected: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// END

// BEGIN chipDemoFilter

class _FilterChipDemo extends StatefulWidget {
  @override
  _FilterChipDemoState createState() => _FilterChipDemoState();
}

class _FilterChipDemoState extends State<_FilterChipDemo>
    with RestorationMixin {
  final RestorableBool isSelectedElevator = RestorableBool(false);
  final RestorableBool isSelectedWasher = RestorableBool(false);
  final RestorableBool isSelectedFireplace = RestorableBool(false);

  @override
  String get restorationId => 'filter_chip_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(isSelectedElevator, 'selected_elevator');
    registerForRestoration(isSelectedWasher, 'selected_washer');
    registerForRestoration(isSelectedFireplace, 'selected_fireplace');
  }

  @override
  void dispose() {
    isSelectedElevator.dispose();
    isSelectedWasher.dispose();
    isSelectedFireplace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: Text(localizations.chipElevator),
                selected: isSelectedElevator.value,
                onSelected: (value) {
                  setState(() {
                    isSelectedElevator.value = !isSelectedElevator.value;
                  });
                },
              ),
              FilterChip(
                label: Text(localizations.chipWasher),
                selected: isSelectedWasher.value,
                onSelected: (value) {
                  setState(() {
                    isSelectedWasher.value = !isSelectedWasher.value;
                  });
                },
              ),
              FilterChip(
                label: Text(localizations.chipFireplace),
                selected: isSelectedFireplace.value,
                onSelected: (value) {
                  setState(() {
                    isSelectedFireplace.value = !isSelectedFireplace.value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Disabled chips
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: Text(localizations.chipElevator),
                selected: isSelectedElevator.value,
                onSelected: null,
              ),
              FilterChip(
                label: Text(localizations.chipWasher),
                selected: isSelectedWasher.value,
                onSelected: null,
              ),
              FilterChip(
                label: Text(localizations.chipFireplace),
                selected: isSelectedFireplace.value,
                onSelected: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// END

// BEGIN chipDemoInput

class _InputChipDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InputChip(
            onPressed: () {},
            onDeleted: () {},
            avatar: const Icon(
              Icons.directions_bike,
              size: 20,
              color: Colors.black54,
            ),
            deleteIconColor: Colors.black54,
            label: Text(GalleryLocalizations.of(context)!.chipBiking),
          ),
          const SizedBox(height: 12),
          // Disabled chip
          InputChip(
            onPressed: null,
            onDeleted: null,
            avatar: const Icon(
              Icons.directions_bike,
              size: 20,
              color: Colors.black54,
            ),
            deleteIconColor: Colors.black54,
            label: Text(GalleryLocalizations.of(context)!.chipBiking),
          ),
        ],
      ),
    );
  }
}

// END
