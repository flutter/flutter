// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Builds a [Widget] when given a concrete value of a [AsyncSnapshot<T>] where
/// `T` is a `Listenable`.
///
/// If the `child` parameter provided to the [AsyncListenableBuilder] is not
/// null, the same `child` widget is passed back to this [ListenableFutureBuilder]
/// and should typically be incorporated in the returned widget tree.
///
/// See also:
///
///  * [ListenableFutureBuilder], a widget which invokes this builder each time
///  after the initial future completes and a value is emited on the [Listener].
typedef AsyncListenableBuilder<T extends Listenable> = Widget Function(
  BuildContext context,
  Widget? child,
  AsyncSnapshot<T> listenableSnapshot,
);

/// A widget that awaits initialization and then rebuilds when the it receives
/// a notification from the `Listenable`. Use this widget with `ChangeNotifier`
/// `ValueNotifier`, or other `Listenable` controllers to rebuild the widget
/// when the value changes.
///
/// Given a [AsyncListenableBuilder<T>] and a [builder] which builds widgets from
/// the state of the `Listenable`, this class will automatically register itself as a
/// listener of the [Listenable] and call the [builder] with updated values
/// when the value changes.
///
/// ## Performance optimizations
///
/// If your [builder] function contains a subtree that does not depend on the
/// value of the [Listenable], it's more efficient to build that subtree
/// once instead of rebuilding it on every animation tick.
///
/// If you pass the pre-built subtree as the [child] parameter, the
/// [ListenableFutureBuilder] will pass it back to your [builder] function so
/// that you can incorporate it into your build.
///
/// Using this pre-built child is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
///
/// {@tool snippet}
///
/// This sample demonstrates how you could use a [ListenableFutureBuilder] to wait
/// for the initialization to complete, show a [CircularProgressIndicator] while
/// waiting, and trigger rebuild on state changes without the need for setState
///
/// ```dart
// import 'package:flutter/material.dart';
// import 'package:notifier_builder/notifier_future_builder.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) => MaterialApp(
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: ListenableFutureBuilder(
//           listenable: getValueNotifier,
//           builder: (context, child, notifierSnapshot) => Scaffold(
//             appBar: AppBar(
//               title: const Text('ListenableFutureBuilder Example'),
//             ),
//             body: Center(
//               child: notifierSnapshot.connectionState == ConnectionState.done
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         const Text(
//                           'You have pushed the button this many times:',
//                         ),
//                         Text(
//                           '${notifierSnapshot.data!.value}',
//                           style: Theme.of(context).textTheme.headlineMedium,
//                         ),
//                       ],
//                     )
//                   : const CircularProgressIndicator.adaptive(),
//             ),
//             floatingActionButton: FloatingActionButton(
//               onPressed: () => notifierSnapshot.data?.value++,
//               tooltip: 'Increment',
//               child: const Icon(Icons.add),
//             ),
//           ),
//         ),
//       );
// }

// ///This gets a [ValueNotifier<int>] after 3 seconds
// Future<ValueNotifier<int>> getValueNotifier() =>
//     Future<ValueNotifier<int>>.delayed(
//       const Duration(seconds: 3),
//       () => ValueNotifier<int>(0),
//     );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedBuilder], which also triggers rebuilds from a [Listenable]
///    without passing back a specific value from a [ValueListenable].
///  * [ValueListenableBuilder], which also triggers rebuilds from a [ValueListenable]
///  * [NotificationListener], which lets you rebuild based on [Notification]
///    coming from its descendant widgets rather than a [ValueListenable] that
///    you have a direct reference to.
class ListenableFutureBuilder<T extends Listenable> extends StatefulWidget {
  /// Creates a [ListenableFutureBuilder].
  ///
  /// The [listenable] and [builder] arguments must not be null. [listenable]
  /// should perform initialization logic for the [Listenable] and return the
  /// instance.
  ///
  /// The [child] is optional but is good practice to use if part of the widget
  /// subtree does not depend on the value of the [listenable].
  const ListenableFutureBuilder({
    required this.listenable,
    required this.builder,
    this.child,
    super.key,
  });

  /// Instantiates the [Future] whose return value you depend on in order to build.
  /// This should perform initialization logic for the [Listenable] and return it
  final Future<T> Function() listenable;

  /// A [AsyncListenableBuilder] which builds a widget depending on the
  /// [Listenable] such as a [ChangeNotifier]
  ///
  /// Exposes a [AsyncSnapshot] which contains the [Listenable] instance once the
  /// initialization completes. It is important to check the `connectionState` of the
  /// snapshot, and the `data` and `error` properties of the snapshot to determine
  /// if the [Listenable] is ready to be used. The builder should usually return a
  /// progress indicator until the connection state is [ConnectionState.done].
  ///
  /// Can incorporate the [child] parameter into the returned widget tree to improve
  /// performance.
  final AsyncListenableBuilder<T> builder;

  /// A predefined widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [Listenable]. For
  /// example, in the case where the [Listenable] has a [String] and the
  /// [builder] returns a [Text] widget with the current [String] value, there
  /// would be no useful [child].
  final Widget? child;

  @override
  State<ListenableFutureBuilder<T>> createState() =>
      _ListenableFutureBuilderState<T>();
}

class _ListenableFutureBuilderState<T extends Listenable>
    extends State<ListenableFutureBuilder<T>> {
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  ///Use this to access the last snapshot that was passed to the builder
  AsyncSnapshot<T> get lastSnapshot => _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.nothing();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (BuildContext context) =>
            widget.builder(context, widget.child, _snapshot),
      );

  @override
  void dispose() {
    _unsubscribe();
    _snapshot = AsyncSnapshot<T>.nothing();
    super.dispose();
  }

  void _handleChange() => setState(() {});

  void _subscribe() {
    final Object callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    widget.listenable().then<void>(
      (T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
            _snapshot.data!.addListener(_handleChange);
          });
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(
              ConnectionState.done,
              error,
              stackTrace,
            );
          });
        }
      },
    );

    if (_snapshot.connectionState != ConnectionState.done) {
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
    if (_snapshot.connectionState == ConnectionState.done &&
        _snapshot.data != null) {
      _snapshot.data!.removeListener(_handleChange);
    }
  }
}
