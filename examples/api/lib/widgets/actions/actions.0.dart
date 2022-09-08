// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Actions

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

// A simple model class that notifies listeners when it changes.
class Model {
  ValueNotifier<bool> isDirty = ValueNotifier<bool>(false);
  ValueNotifier<int> data = ValueNotifier<int>(0);

  int save() {
    if (isDirty.value) {
      debugPrint('Saved Data: ${data.value}');
      isDirty.value = false;
    }
    return data.value;
  }

  void setValue(int newValue) {
    isDirty.value = data.value != newValue;
    data.value = newValue;
  }
}

class ModifyIntent extends Intent {
  const ModifyIntent(this.value);

  final int value;
}

// An Action that modifies the model by setting it to the value that it gets
// from the Intent passed to it when invoked.
class ModifyAction extends Action<ModifyIntent> {
  ModifyAction(this.model);

  final Model model;

  @override
  void invoke(covariant ModifyIntent intent) {
    model.setValue(intent.value);
  }
}

// An intent for saving data.
class SaveIntent extends Intent {
  const SaveIntent();
}

// An Action that saves the data in the model it is created with.
class SaveAction extends Action<SaveIntent> {
  SaveAction(this.model);

  final Model model;

  @override
  int invoke(covariant SaveIntent intent) => model.save();
}

class SaveButton extends StatefulWidget {
  const SaveButton(this.valueNotifier, {super.key});

  final ValueNotifier<bool> valueNotifier;

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  int savedValue = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.valueNotifier,
      builder: (BuildContext context, Widget? child) {
        return TextButton.icon(
          icon: const Icon(Icons.save),
          label: Text('$savedValue'),
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll<Color>(
              widget.valueNotifier.value ? Colors.red : Colors.green,
            ),
          ),
          onPressed: () {
            setState(() {
              savedValue = Actions.invoke(context, const SaveIntent())! as int;
            });
          },
        );
      },
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  Model model = Model();
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ModifyIntent: ModifyAction(model),
        SaveIntent: SaveAction(model),
      },
      child: Builder(
        builder: (BuildContext context) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.exposure_plus_1),
                    onPressed: () {
                      Actions.invoke(context, ModifyIntent(++count));
                    },
                  ),
                  AnimatedBuilder(
                      animation: model.data,
                      builder: (BuildContext context, Widget? child) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${model.data.value}',
                              style: Theme.of(context).textTheme.headlineMedium),
                        );
                      }),
                  IconButton(
                    icon: const Icon(Icons.exposure_minus_1),
                    onPressed: () {
                      Actions.invoke(context, ModifyIntent(--count));
                    },
                  ),
                ],
              ),
              SaveButton(model.isDirty),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}
