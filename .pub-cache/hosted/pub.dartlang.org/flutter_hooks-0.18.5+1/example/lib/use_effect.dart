// ignore_for_file: omit_local_variable_types
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This example demonstrates how to create a custom Hook.
class CustomHookExample extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Consume the custom hook. It returns a StreamController that we can use
    // within this Widget.
    //
    // To update the stored value, `add` data to the StreamController. To get
    // the latest value from the StreamController, listen to the Stream with
    // the useStream hook.
    // ignore: close_sinks
    final StreamController<int> countController =
        _useLocalStorageInt('counter');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Hook example'),
      ),
      body: Center(
        // Use a HookBuilder Widget to listen to the Stream. This ensures a
        // smaller portion of the Widget tree is rebuilt when the stream emits a
        // new value
        child: HookBuilder(
          builder: (context) {
            final AsyncSnapshot<int> count =
                useStream(countController.stream, initialData: 0);

            return !count.hasData
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: () => countController.add(count.data + 1),
                    child: Text('You tapped me ${count.data} times.'),
                  );
          },
        ),
      ),
    );
  }
}

// A custom hook that will read and write values to local storage using the
// SharedPreferences package.
StreamController<int> _useLocalStorageInt(
  String key, {
  int defaultValue = 0,
}) {
  // Custom hooks can use additional hooks internally!
  final controller = useStreamController<int>(keys: [key]);

  // Pass a callback to the useEffect hook. This function should be called on
  // first build and every time the controller or key changes
  useEffect(
    () {
      // Listen to the StreamController, and when a value is added, store it
      // using SharedPrefs.
      final sub = controller.stream.listen((data) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, data);
      });
      // Unsubscribe when the widget is disposed
      // or on controller/key change
      return sub.cancel;
    },
    // Pass the controller and key to the useEffect hook. This will ensure the
    // useEffect hook is only called the first build or when one of the the
    // values changes.
    [controller, key],
  );

  // Load the initial value from local storage and add it as the initial value
  // to the controller
  useEffect(
    () {
      SharedPreferences.getInstance().then<void>((prefs) async {
        final int valueFromStorage = prefs.getInt(key);
        controller.add(valueFromStorage ?? defaultValue);
      }).catchError(controller.addError);
      return null;
    },
    // Pass the controller and key to the useEffect hook. This will ensure the
    // useEffect hook is only called the first build or when one of the the
    // values changes.
    [controller, key],
  );

  // Finally, return the StreamController. This allows users to add values from
  // the Widget layer and listen to the stream for changes.
  return controller;
}
