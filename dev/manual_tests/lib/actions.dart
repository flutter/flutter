// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Sets a platform override for desktop to avoid exceptions. See
// https://flutter.dev/desktop#target-platform-override for more info.
// TODO(gspencergoog): Remove once TargetPlatform includes all desktop platforms.
void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _enablePlatformOverrideForDesktop();
  runApp(const MaterialApp(
    title: 'Actions Demo',
    home: FocusDemo(),
  ));
}

/// Undoable Actions

/// An [ActionDispatcher] subclass that manages the invocation of undoable
/// actions.
class UndoableActionDispatcher extends ActionDispatcher implements Listenable {
  /// Constructs a new [UndoableActionDispatcher].
  ///
  /// The [maxUndoLevels] argument must not be null.
  UndoableActionDispatcher({
    int maxUndoLevels = _defaultMaxUndoLevels,
  })  : assert(maxUndoLevels != null),
        _maxUndoLevels = maxUndoLevels;

  // A stack of actions that have been performed. The most recent action
  // performed is at the end of the list.
  final List<UndoableAction> _completedActions = <UndoableAction>[];
  // A stack of actions that can be redone. The most recent action performed is
  // at the end of the list.
  final List<UndoableAction> _undoneActions = <UndoableAction>[];

  static const int _defaultMaxUndoLevels = 1000;

  /// The maximum number of undo levels allowed.
  ///
  /// If this value is set to a value smaller than the number of completed
  /// actions, then the stack of completed actions is truncated to only include
  /// the last [maxUndoLevels] actions.
  int get maxUndoLevels => _maxUndoLevels;
  int _maxUndoLevels;
  set maxUndoLevels(int value) {
    _maxUndoLevels = value;
    _pruneActions();
  }

  final Set<VoidCallback> _listeners = <VoidCallback>{};

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies listeners that the [ActionDispatcher] has changed state.
  ///
  /// May only be called by subclasses.
  @protected
  void notifyListeners() {
    for (VoidCallback callback in _listeners) {
      callback();
    }
  }

  @override
  bool invokeAction(Action action, Intent intent, {FocusNode focusNode}) {
    final bool result = super.invokeAction(action, intent, focusNode: focusNode);
    print('Invoking ${action is UndoableAction ? 'undoable ' : ''}$intent as $action: $this ');
    if (action is UndoableAction) {
      _completedActions.add(action);
      _undoneActions.clear();
      _pruneActions();
      notifyListeners();
    }
    return result;
  }

  // Enforces undo level limit.
  void _pruneActions() {
    while (_completedActions.length > _maxUndoLevels) {
      _completedActions.removeAt(0);
    }
  }

  /// Returns true if there is an action on the stack that can be undone.
  bool get canUndo {
    if (_completedActions.isNotEmpty) {
      final Intent lastIntent = _completedActions.last.invocationIntent;
      return lastIntent.isEnabled(primaryFocus.context);
    }
    return false;
  }

  /// Returns true if an action that has been undone can be re-invoked.
  bool get canRedo {
    if (_undoneActions.isNotEmpty) {
      final Intent lastIntent = _undoneActions.last.invocationIntent;
      return lastIntent.isEnabled(primaryFocus?.context);
    }
    return false;
  }

  /// Undoes the last action executed if possible.
  ///
  /// Returns true if the action was successfully undone.
  bool undo() {
    print('Undoing. $this');
    if (!canUndo) {
      return false;
    }
    final UndoableAction action = _completedActions.removeLast();
    action.undo();
    _undoneActions.add(action);
    notifyListeners();
    return true;
  }

  /// Re-invokes a previously undone action, if possible.
  ///
  /// Returns true if the action was successfully invoked.
  bool redo() {
    print('Redoing. $this');
    if (!canRedo) {
      return false;
    }
    final UndoableAction action = _undoneActions.removeLast();
    action.invoke(action.invocationNode, action.invocationIntent);
    _completedActions.add(action);
    _pruneActions();
    notifyListeners();
    return true;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('undoable items', _completedActions.length));
    properties.add(IntProperty('redoable items', _undoneActions.length));
    properties.add(IterableProperty<UndoableAction>('undo stack', _completedActions));
    properties.add(IterableProperty<UndoableAction>('redo stack', _undoneActions));
  }
}

class UndoIntent extends Intent {
  const UndoIntent() : super(kUndoActionKey);

  @override
  bool isEnabled(BuildContext context) {
    final UndoableActionDispatcher manager = Actions.of(context, nullOk: true);
    return manager.canUndo;
  }
}

class RedoIntent extends Intent {
  const RedoIntent() : super(kRedoActionKey);

  @override
  bool isEnabled(BuildContext context) {
    final UndoableActionDispatcher manager = Actions.of(context, nullOk: true);
    return manager.canRedo;
  }
}

const LocalKey kUndoActionKey = ValueKey<String>('Undo');
const Intent kUndoIntent = UndoIntent();
final Action kUndoAction = CallbackAction(
  kUndoActionKey,
  onInvoke: (FocusNode node, Intent tag) {
    if (node?.context == null) {
      return;
    }
    final UndoableActionDispatcher manager = Actions.of(node.context, nullOk: true);
    manager?.undo();
  },
);

const LocalKey kRedoActionKey = ValueKey<String>('Redo');
const Intent kRedoIntent = RedoIntent();
final Action kRedoAction = CallbackAction(
  kRedoActionKey,
  onInvoke: (FocusNode node, Intent tag) {
    if (node?.context == null) {
      return;
    }
    final UndoableActionDispatcher manager = Actions.of(node.context, nullOk: true);
    manager?.redo();
  },
);

/// An action that can be undone.
abstract class UndoableAction extends Action {
  /// A const constructor to [UndoableAction].
  ///
  /// The [intentKey] parameter must not be null.
  UndoableAction(LocalKey intentKey) : super(intentKey);

  /// The node supplied when this command was invoked.
  FocusNode get invocationNode => _invocationNode;
  FocusNode _invocationNode;

  @protected
  set invocationNode(FocusNode value) => _invocationNode = value;

  /// The [Intent] this action was originally invoked with.
  Intent get invocationIntent => _invocationTag;
  Intent _invocationTag;

  @protected
  set invocationIntent(Intent value) => _invocationTag = value;

  /// Returns true if the data model can be returned to the state it was in
  /// previous to this action being executed.
  ///
  /// Default implementation returns true.
  bool get undoable => true;

  /// Reverts the data model to the state before this command executed.
  @mustCallSuper
  void undo();

  @override
  @mustCallSuper
  void invoke(FocusNode node, Intent intent) {
    invocationNode = node;
    invocationIntent = intent;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('invocationNode', invocationNode));
  }
}

class UndoableFocusActionBase extends UndoableAction {
  UndoableFocusActionBase(LocalKey name) : super(name);

  FocusNode _previousFocus;

  @override
  void invoke(FocusNode node, Intent intent) {
    super.invoke(node, intent);
    _previousFocus = primaryFocus;
    node.requestFocus();
  }

  @override
  void undo() {
    if (_previousFocus == null) {
      primaryFocus?.unfocus();
      return;
    }
    if (_previousFocus is FocusScopeNode) {
      // The only way a scope can be the _previousFocus is if there was no
      // focusedChild for the scope when we invoked this action, so we need to
      // return to that state.

      // Unfocus the current node to remove it from the focused child list of
      // the scope.
      primaryFocus?.unfocus();
      // and then let the scope node be focused...
    }
    _previousFocus.requestFocus();
    _previousFocus = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('previous', _previousFocus));
  }
}

class UndoableRequestFocusAction extends UndoableFocusActionBase {
  UndoableRequestFocusAction() : super(RequestFocusAction.key);

  @override
  void invoke(FocusNode node, Intent intent) {
    super.invoke(node, intent);
    node.requestFocus();
  }
}

/// Actions for manipulating focus.
class UndoableNextFocusAction extends UndoableFocusActionBase {
  UndoableNextFocusAction() : super(NextFocusAction.key);

  @override
  void invoke(FocusNode node, Intent intent) {
    super.invoke(node, intent);
    node.nextFocus();
  }
}

class UndoablePreviousFocusAction extends UndoableFocusActionBase {
  UndoablePreviousFocusAction() : super(PreviousFocusAction.key);

  @override
  void invoke(FocusNode node, Intent intent) {
    super.invoke(node, intent);
    node.previousFocus();
  }
}

class UndoableDirectionalFocusAction extends UndoableFocusActionBase {
  UndoableDirectionalFocusAction() : super(DirectionalFocusAction.key);

  TraversalDirection direction;

  @override
  void invoke(FocusNode node, DirectionalFocusIntent intent) {
    super.invoke(node, intent);
    final DirectionalFocusIntent args = intent;
    node.focusInDirection(args.direction);
  }
}

/// A button class that takes focus when clicked.
class DemoButton extends StatefulWidget {
  const DemoButton({this.name});

  final String name;

  @override
  _DemoButtonState createState() => _DemoButtonState();
}

class _DemoButtonState extends State<DemoButton> {
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: widget.name);
  }

  void _handleOnPressed() {
    print('Button ${widget.name} pressed.');
    setState(() {
      Actions.invoke(context, const Intent(RequestFocusAction.key), focusNode: _focusNode);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      focusNode: _focusNode,
      focusColor: Colors.red,
      hoverColor: Colors.blue,
      onPressed: () => _handleOnPressed(),
      child: Text(widget.name),
    );
  }
}

class FocusDemo extends StatefulWidget {
  const FocusDemo({Key key}) : super(key: key);

  @override
  _FocusDemoState createState() => _FocusDemoState();
}

class _FocusDemoState extends State<FocusDemo> {
  FocusNode outlineFocus;
  UndoableActionDispatcher dispatcher;
  bool canUndo;
  bool canRedo;

  @override
  void initState() {
    super.initState();
    outlineFocus = FocusNode(debugLabel: 'Demo Focus Node');
    dispatcher = UndoableActionDispatcher();
    canUndo = dispatcher.canUndo;
    canRedo = dispatcher.canRedo;
    dispatcher.addListener(_handleUndoStateChange);
  }

  void _handleUndoStateChange() {
    if (dispatcher.canUndo != canUndo) {
      setState(() {
        canUndo = dispatcher.canUndo;
      });
    }
    if (dispatcher.canRedo != canRedo) {
      setState(() {
        canRedo = dispatcher.canRedo;
      });
    }
  }

  @override
  void dispose() {
    dispatcher.removeListener(_handleUndoStateChange);
    outlineFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Actions(
      dispatcher: dispatcher,
      actions: <LocalKey, ActionFactory>{
        RequestFocusAction.key: () => UndoableRequestFocusAction(),
        NextFocusAction.key: () => UndoableNextFocusAction(),
        PreviousFocusAction.key: () => UndoablePreviousFocusAction(),
        DirectionalFocusAction.key: () => UndoableDirectionalFocusAction(),
        kUndoActionKey: () => kUndoAction,
        kRedoActionKey: () => kRedoAction,
      },
      child: DefaultFocusTraversal(
        policy: ReadingOrderTraversalPolicy(),
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): kRedoIntent,
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): kUndoIntent,
          },
          child: FocusScope(
            debugLabel: 'Scope',
            autofocus: true,
            child: DefaultTextStyle(
              style: textTheme.display1,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Actions Demo'),
                ),
                body: Center(
                  child: Builder(builder: (BuildContext context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            DemoButton(name: 'One'),
                            DemoButton(name: 'Two'),
                            DemoButton(name: 'Three'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            DemoButton(name: 'Four'),
                            DemoButton(name: 'Five'),
                            DemoButton(name: 'Six'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            DemoButton(name: 'Seven'),
                            DemoButton(name: 'Eight'),
                            DemoButton(name: 'Nine'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RaisedButton(
                                child: const Text('UNDO'),
                                onPressed: canUndo
                                    ? () {
                                        Actions.invoke(context, kUndoIntent);
                                      }
                                    : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RaisedButton(
                                child: const Text('REDO'),
                                onPressed: canRedo
                                    ? () {
                                        Actions.invoke(context, kRedoIntent);
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
