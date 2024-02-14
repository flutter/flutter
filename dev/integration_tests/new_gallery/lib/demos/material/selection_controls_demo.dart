// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/demos/material/material_demo_types.dart';

class SelectionControlsDemo extends StatelessWidget {
  const SelectionControlsDemo({super.key, required this.type});

  final SelectionControlsDemoType type;

  String _title(BuildContext context) {
    switch (type) {
      case SelectionControlsDemoType.checkbox:
        return GalleryLocalizations.of(context)!
            .demoSelectionControlsCheckboxTitle;
      case SelectionControlsDemoType.radio:
        return GalleryLocalizations.of(context)!
            .demoSelectionControlsRadioTitle;
      case SelectionControlsDemoType.switches:
        return GalleryLocalizations.of(context)!
            .demoSelectionControlsSwitchTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? controls;
    switch (type) {
      case SelectionControlsDemoType.checkbox:
        controls = _CheckboxDemo();
        break;
      case SelectionControlsDemoType.radio:
        controls = _RadioDemo();
        break;
      case SelectionControlsDemoType.switches:
        controls = _SwitchDemo();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title(context)),
      ),
      body: controls,
    );
  }
}

// BEGIN selectionControlsDemoCheckbox

class _CheckboxDemo extends StatefulWidget {
  @override
  _CheckboxDemoState createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> with RestorationMixin {
  RestorableBoolN checkboxValueA = RestorableBoolN(true);
  RestorableBoolN checkboxValueB = RestorableBoolN(false);
  RestorableBoolN checkboxValueC = RestorableBoolN(null);

  @override
  String get restorationId => 'checkbox_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(checkboxValueA, 'checkbox_a');
    registerForRestoration(checkboxValueB, 'checkbox_b');
    registerForRestoration(checkboxValueC, 'checkbox_c');
  }

  @override
  void dispose() {
    checkboxValueA.dispose();
    checkboxValueB.dispose();
    checkboxValueC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: checkboxValueA.value,
              onChanged: (value) {
                setState(() {
                  checkboxValueA.value = value;
                });
              },
            ),
            Checkbox(
              value: checkboxValueB.value,
              onChanged: (value) {
                setState(() {
                  checkboxValueB.value = value;
                });
              },
            ),
            Checkbox(
              value: checkboxValueC.value,
              tristate: true,
              onChanged: (value) {
                setState(() {
                  checkboxValueC.value = value;
                });
              },
            ),
          ],
        ),
        // Disabled checkboxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: checkboxValueA.value,
              onChanged: null,
            ),
            Checkbox(
              value: checkboxValueB.value,
              onChanged: null,
            ),
            Checkbox(
              value: checkboxValueC.value,
              tristate: true,
              onChanged: null,
            ),
          ],
        ),
      ],
    );
  }
}

// END

// BEGIN selectionControlsDemoRadio

class _RadioDemo extends StatefulWidget {
  @override
  _RadioDemoState createState() => _RadioDemoState();
}

class _RadioDemoState extends State<_RadioDemo> with RestorationMixin {
  final RestorableInt radioValue = RestorableInt(0);

  @override
  String get restorationId => 'radio_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(radioValue, 'radio_value');
  }

  void handleRadioValueChanged(int? value) {
    setState(() {
      radioValue.value = value!;
    });
  }

  @override
  void dispose() {
    radioValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int index = 0; index < 2; ++index)
              Radio<int>(
                value: index,
                groupValue: radioValue.value,
                onChanged: handleRadioValueChanged,
              ),
          ],
        ),
        // Disabled radio buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int index = 0; index < 2; ++index)
              Radio<int>(
                value: index,
                groupValue: radioValue.value,
                onChanged: null,
              ),
          ],
        ),
      ],
    );
  }
}

// END

// BEGIN selectionControlsDemoSwitches

class _SwitchDemo extends StatefulWidget {
  @override
  _SwitchDemoState createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> with RestorationMixin {
  RestorableBool switchValueA = RestorableBool(true);
  RestorableBool switchValueB = RestorableBool(false);

  @override
  String get restorationId => 'switch_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(switchValueA, 'switch_value1');
    registerForRestoration(switchValueB, 'switch_value2');
  }

  @override
  void dispose() {
    switchValueA.dispose();
    switchValueB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch(
              value: switchValueA.value,
              onChanged: (value) {
                setState(() {
                  switchValueA.value = value;
                });
              },
            ),
            Switch(
              value: switchValueB.value,
              onChanged: (value) {
                setState(() {
                  switchValueB.value = value;
                });
              },
            ),
          ],
        ),
        // Disabled switches
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch(
              value: switchValueA.value,
              onChanged: null,
            ),
            Switch(
              value: switchValueB.value,
              onChanged: null,
            ),
          ],
        ),
      ],
    );
  }
}

// END
