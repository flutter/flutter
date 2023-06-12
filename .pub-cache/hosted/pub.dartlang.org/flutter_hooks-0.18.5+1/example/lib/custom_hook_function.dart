// ignore_for_file: omit_local_variable_types
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// This example demonstrates how to write a hook function that enhances the
/// useState hook with logging functionality.
class CustomHookFunctionExample extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Next, invoke the custom `useLoggedState` hook with a default value to
    // create a `counter` variable that contains a `value`. Whenever the value
    // is changed, this Widget will be rebuilt and the result will be logged!
    final counter = useLoggedState(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Hook: Function'),
      ),
      body: Center(
        // Read the current value from the counter
        child: Text('Button tapped ${counter.value} times'),
      ),
      floatingActionButton: FloatingActionButton(
        // When the button is pressed, update the value of the counter! This
        // will trigger a rebuild as well as printing the latest value to the
        // console!
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A custom hook that wraps the useState hook to add logging. Hooks can be
/// composed -- meaning you can use hooks within hooks!
ValueNotifier<T> useLoggedState<T>([T initialData]) {
  // First, call the useState hook. It will create a ValueNotifier for you that
  // rebuilds the Widget whenever the value changes.
  final result = useState<T>(initialData);

  // Next, call the useValueChanged hook to print the state whenever it changes
  useValueChanged<T, void>(result.value, (_, __) {
    print(result.value);
  });

  return result;
}
