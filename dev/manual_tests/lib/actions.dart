// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Actions Demo',
    home: FocusDemo(),
  ));
}

/// Undoable Actions

/// An [ActionDispatcher] subclass that manages the invocation of undoable
/// actions.
class UndoableActionDispatcher extends ActionDispatcher {
  /// Constructs a new [UndoableActionDispatcher].
  ///
  /// The [maxUndoLevels] argument must not be null.
  UndoableActionDispatcher({
    Map<String, ActionFactory> actions = const <String, ActionFactory>{},
    int maxUndoLevels = _defaultMaxUndoLevels,
  })  : assert(maxUndoLevels != null),
        _maxUndoLevels = maxUndoLevels,
        super(actions: actions);

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

  @override
  Action invokeAction(ActionTag tag, {FocusNode node}) {
    print('Invoking $tag: $this');
    final Action action = super.invokeAction(tag, node: node);
    if (action is UndoableAction) {
      _completedActions.add(action);
      _undoneActions.clear();
      _pruneActions();
    }
    return action;
  }

  // Enforces undo level limit.
  void _pruneActions() {
    while (_completedActions.length > _maxUndoLevels) {
      _completedActions.removeAt(0);
    }
  }

  /// Returns true if there is an action on the stack that can be undone.
  bool get canUndo {
    return _completedActions.isNotEmpty ? _completedActions.last.undoable && _completedActions.last.invocationTag.enabled : false;
  }

  /// Returns true if an action that has been undone can be re-invoked.
  bool get canRedo => _undoneActions.isNotEmpty ? _undoneActions.last.invocationTag.enabled : false;

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
    action.invoke(action.invocationNode, action.invocationTag);
    _completedActions.add(action);
    _pruneActions();
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

final Action kUndoAction = CallbackAction(
    name: 'Undo',
    onInvoke: (FocusNode node, ActionTag tag) {
      if (node?.context == null) {
        return;
      }
      final UndoableActionDispatcher manager = Actions.of(node.context, nullOk: true);
      manager?.undo();
    });

final Action kRedoAction = CallbackAction(
    name: 'Redo',
    onInvoke: (FocusNode node, ActionTag tag) {
      if (node?.context == null) {
        return;
      }
      final UndoableActionDispatcher manager = Actions.of(node.context, nullOk: true);
      manager?.redo();
    });

/// An action that can be undone.
abstract class UndoableAction extends Action {
  /// A const constructor to [UndoableAction].
  ///
  /// The [name] parameter must not be null.
  UndoableAction(String name) : super(name);

  /// The node supplied when this command was invoked.
  FocusNode get invocationNode => _invocationNode;
  FocusNode _invocationNode;

  @protected
  set invocationNode(FocusNode value) => _invocationNode = value;

  /// The [ActionTag] this action was originally invoked with.
  ActionTag get invocationTag => _invocationTag;
  ActionTag _invocationTag;

  @protected
  set invocationTag(ActionTag value) => _invocationTag = value;

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
  void invoke(FocusNode node, ActionTag tag) {
    invocationNode = node;
    invocationTag = tag;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('invocationNode', invocationNode));
  }
}

class SetFocusActionBase extends UndoableAction {
  SetFocusActionBase(String name) : super(name);

  FocusNode _previousFocus;

  @override
  void invoke(FocusNode node, ActionTag tag) {
    super.invoke(node, tag);
    _previousFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    node.requestFocus();
  }

  @override
  void undo() {
    if (_previousFocus == null) {
      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
      return;
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

class SetFocusAction extends SetFocusActionBase {
  SetFocusAction() : super('SetFocus');

  @override
  void invoke(FocusNode node, ActionTag tag) {
    super.invoke(node, tag);
    node.requestFocus();
  }
}

/// Actions for manipulating focus.
class NextFocusAction extends SetFocusActionBase {
  NextFocusAction() : super('NextFocus');

  @override
  void invoke(FocusNode node, ActionTag tag) {
    super.invoke(node, tag);
    node.nextFocus();
  }
}

class PreviousFocusAction extends SetFocusActionBase {
  PreviousFocusAction() : super('PreviousFocus');

  @override
  void invoke(FocusNode node, ActionTag tag) {
    super.invoke(node, tag);
    node.previousFocus();
  }
}

class DirectionalFocusActionTag extends ActionTag {
  const DirectionalFocusActionTag(this.direction) : super('DirectionalFocus');

  final TraversalDirection direction;
}

class DirectionalFocusAction extends SetFocusActionBase {
  DirectionalFocusAction() : super('DirectionalFocus');

  TraversalDirection direction;

  @override
  void invoke(FocusNode node, DirectionalFocusActionTag tag) {
    super.invoke(node, tag);
    final DirectionalFocusActionTag args = tag;
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
    final UndoableActionDispatcher manager = Actions.of(context, nullOk: true);
    setState(() {
      manager?.invokeAction(const ActionTag('SetFocus'), node: _focusNode);
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

  @override
  void initState() {
    super.initState();
    outlineFocus = FocusNode(debugLabel: 'Demo Focus Node');
  }

  @override
  void dispose() {
    outlineFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Shortcuts(
      shortcuts: <LogicalKeySet, ActionTag>{
        LogicalKeySet(LogicalKeyboardKey.tab): const ActionTag('NextFocus'),
        LogicalKeySet(LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.tab): const ActionTag('PreviousFocus'),
        LogicalKeySet(LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.tab): const ActionTag('PreviousFocus'),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusActionTag(TraversalDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusActionTag(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusActionTag(TraversalDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusActionTag(TraversalDirection.right),
      },
      child: Actions(
        dispatcher: UndoableActionDispatcher(actions: <String, ActionFactory>{
          'SetFocus': () => SetFocusAction(),
          'NextFocus': () => NextFocusAction(),
          'PreviousFocus': () => PreviousFocusAction(),
          'DirectionalFocus': () => DirectionalFocusAction(),
          'Undo': () => kUndoAction,
          'Redo': () => kRedoAction,
        }),
        child: DefaultFocusTraversal(
          policy: ReadingOrderTraversalPolicy(),
          child: Shortcuts(
            shortcuts: <LogicalKeySet, ActionTag>{
              LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyZ): const ActionTag('Redo'),
              LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.keyZ): const ActionTag('Redo'),
              LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyZ): const ActionTag('Redo'),
              LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.keyZ): const ActionTag('Redo'),
              LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyZ): const ActionTag('Undo'),
              LogicalKeySet(LogicalKeyboardKey.controlRight, LogicalKeyboardKey.keyZ): const ActionTag('Undo'),
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
                                  onPressed: () {
                                    Actions.of(context)?.invokeFocusedAction(const ActionTag('Undo'));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RaisedButton(
                                  child: const Text('REDO'),
                                  onPressed: () {
                                    Actions.of(context)?.invokeFocusedAction(const ActionTag('Redo'));
                                  },
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
      ),
    );
  }
}
