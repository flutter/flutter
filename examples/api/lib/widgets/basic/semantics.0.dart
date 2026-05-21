// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for a custom button that uses [Semantics].
///
/// This sample shows how to expose a custom interactive control as a button to
/// assistive technologies. [Semantics] supplies the button role, enabled state,
/// and tap action, while [FocusableActionDetector] and [GestureDetector] handle
/// keyboard focus, hover, shortcuts, and pointer taps.

void main() => runApp(const SemanticsExampleApp());

class SemanticsExampleApp extends StatelessWidget {
  const SemanticsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SemanticsExample());
  }
}

class SemanticsExample extends StatefulWidget {
  const SemanticsExample({super.key});

  @override
  State<SemanticsExample> createState() => _SemanticsExampleState();
}

class _SemanticsExampleState extends State<SemanticsExample> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semantics Sample')),
      body: Center(
        child: AccessibleButton(
          onPressed: _increment,
          child: Text('Count: $_count'),
        ),
      ),
    );
  }
}

class AccessibleButton extends StatefulWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  bool _focused = false;
  bool _hovering = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    widget.onPressed?.call();
  }

  void _handleFocusHighlight(bool value) {
    setState(() {
      _focused = value;
    });
  }

  void _handleHoverHighlight(bool value) {
    setState(() {
      _hovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    if (!_enabled) {
      background = colors.surfaceContainerHighest;
      foreground = colors.onSurfaceVariant;
    } else if (_hovering) {
      background = colors.primaryContainer;
      foreground = colors.onPrimaryContainer;
    } else {
      background = colors.primary;
      foreground = colors.onPrimary;
    }

    return Semantics(
      button: true,
      container: true,
      enabled: _enabled,
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              _activate();
              return null;
            },
          ),
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: _handleFocusHighlight,
        onShowHoverHighlight: _handleHoverHighlight,
        child: GestureDetector(
          // The enclosing Semantics widget supplies the button role and semantic
          // tap action, so this detector only handles pointer input.
          excludeFromSemantics: true,
          onTap: _enabled ? _activate : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: _focused ? colors.secondary : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
