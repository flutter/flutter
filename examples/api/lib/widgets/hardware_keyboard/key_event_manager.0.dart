// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// This example app demonstrates a use case of patching
// `KeyEventManager.keyMessageHandler`: be notified of key events that are not
// handled by any focus handlers (such as shortcuts).
//
// See [KeyEventManager.keyMessageHandler].

void main() => runApp(
  const MaterialApp(
    home: Scaffold(
      body: Center(
        child: FallbackDemo(),
      )
    ),
  ),
);

class FallbackDemo extends StatefulWidget {
  const FallbackDemo({super.key});

  @override
  State<StatefulWidget> createState() => FallbackDemoState();
}

class FallbackDemoState extends State<FallbackDemo> {
  String? _capture;
  late final FallbackFocusNode _node = FallbackFocusNode(
    onKeyEvent: (KeyEvent event) {
      if (event is! KeyDownEvent) {
        return false;
      }
      setState(() {
        _capture = event.logicalKey.keyLabel;
      });
      // TRY THIS: Change the return value to true. You will no longer be able
      // to input text, because rhese key events will no longer be sent to the
      // text input system.
      return false;
    }
  );

  @override
  Widget build(BuildContext context) {
    return FallbackFocus(
      node: _node,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.red)),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 200),
        child: Column(
          children: <Widget>[
            const Text('This area handles key pressses that are unhandled by any shortcuts by displaying them below. '
              'Try text shortcuts such as Ctrl-A!'),
            Text(_capture == null ? '' : '$_capture is not handled by shortcuts.'),
            const TextField(decoration: InputDecoration(label: Text('Text field 1'))),
            Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                const SingleActivator(LogicalKeyboardKey.keyQ): VoidCallbackIntent(() {}),
              },
              child: const TextField(
                decoration: InputDecoration(label: Text('This field also considers key Q as a shortcut (that does nothing).')),
              ),
            ),
          ],
        ),
      )
    );
  }
}

/// A node used by [FallbackKeyEventRegistrar] to register fallback key handlers.
class FallbackFocusNode {
  FallbackFocusNode({required this.onKeyEvent});

  final KeyEventCallback onKeyEvent;
}

/// A global singleton class that allows [FallbackFocus] to register fallback
/// key event handlers.
///
/// This class is initialized when [instance] is first called, at which time it
/// patches [ServicesBinding.instance.keyEventManager.keyMessageHandler] with
/// its own handler.
class FallbackKeyEventRegistrar {
  FallbackKeyEventRegistrar._();
  static FallbackKeyEventRegistrar get instance {
    if (!_initialized) {
      final KeyMessageHandler? existing = ServicesBinding.instance.keyEventManager.keyMessageHandler;
      assert(existing != null);
      ServicesBinding.instance.keyEventManager.keyMessageHandler = _instance._buildHandler(existing!);
      _initialized = true;
    }
    return _instance;
  }
  static bool _initialized = false;
  static final FallbackKeyEventRegistrar _instance = FallbackKeyEventRegistrar._();

  final List<FallbackFocusNode> _fallbackNodes = <FallbackFocusNode>[];

  KeyMessageHandler _buildHandler(KeyMessageHandler existing) {
    return (KeyMessage message) {
      if (existing(message)) {
        return true;
      }
      if (_fallbackNodes.isNotEmpty) {
        for (final KeyEvent event in message.events) {
          if (_fallbackNodes.last.onKeyEvent(event)) {
            return true;
          }
        }
      }
      return false;
    };
  }
}

/// A widget that, when focused, handles key events only if no other handlers
/// do.
///
/// If a [FallbackFocus] is being focused on, then key events that are not
/// handled by other handlers will be dispatched to the `onKeyEvent` of [node].
/// If `onKeyEvent` returns true, this event is considered "handled" and will
/// not move forward with the text input system.
///
/// If multiple [FallbackFocus] nest, then only the innermost takes effect.
class FallbackFocus extends StatelessWidget {
  const FallbackFocus({
    super.key,
    required this.node,
    required this.child,
  });

  final Widget child;
  final FallbackFocusNode node;

  void _onFocusChange(bool focused) {
    if (focused) {
      FallbackKeyEventRegistrar.instance._fallbackNodes.add(node);
    } else {
      assert(FallbackKeyEventRegistrar.instance._fallbackNodes.last == node);
      FallbackKeyEventRegistrar.instance._fallbackNodes.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _onFocusChange,
      child: child,
    );
  }
}
