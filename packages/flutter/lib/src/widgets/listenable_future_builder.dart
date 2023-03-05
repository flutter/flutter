// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ListenableFutureBuilder<T extends Listenable> extends StatefulWidget {
  const ListenableFutureBuilder({
    required this.future,
    required this.builder,
    this.child,
    super.key,
  });

  ///Set this to a fixed function. The widget will only call this once
  final Future<T> Function() future;

  final Widget Function(
    BuildContext context,
    Widget? child,
    AsyncSnapshot<T> notifier,
  ) builder;

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
    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    // ignore: discarded_futures
    widget.future().then<void>(
      (data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
            _snapshot.data!.addListener(_handleChange);
          });
        }
      },
      // ignore: avoid_types_on_closure_parameters
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
