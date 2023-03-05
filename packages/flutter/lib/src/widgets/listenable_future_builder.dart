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
/// or `ValueNotifier` to rebuild the widget when the value changes.
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
  const ListenableFutureBuilder({
    required this.future,
    required this.builder,
    this.child,
    super.key,
  });

  ///Set this to a fixed function. The widget will only call this once
  final Future<T> Function() future;

  final AsyncListenableBuilder builder;

  final Widget? child;

  @override
  State<ListenableFutureBuilder<T>> createState() =>
      _ListenableFutureBuilderState<T>();
}

class _ListenableFutureBuilderState<T extends Listenable>
    extends State<ListenableFutureBuilder<T>> {
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.nothing();
    _subscribe();
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (context) => widget.builder(context, widget.child, _snapshot),
      );

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _handleChange() => setState(() {});

  void _subscribe() {
    final Object callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    widget.future().then<void>(
      (data) {
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
