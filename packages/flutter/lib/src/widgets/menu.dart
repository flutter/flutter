// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A Mixin class used to provide menu items with an interface for listening to
/// changes.
mixin _MenuChangeNotifier<T> {
  final List<ValueChanged<MenuItem<T>>> _listeners =
      <ValueChanged<MenuItem<T>>>[];

  final List<ValueChanged<MenuItem<T>>> _selectionListeners =
  <ValueChanged<MenuItem<T>>>[];

  /// Register a listener that is called every time the model changes.
  ///
  /// Listeners can be removed with [removeChangeListener].
  void addChangeListener(ValueChanged<MenuItem<T>> listener) {
    _listeners.add(listener);
  }

  /// Stop calling the given listener every time the model changes.
  ///
  /// Listeners can be added with [addChangeListener].
  void removeChangeListener(ValueChanged<MenuItem<T>> listener) {
    _listeners.remove(listener);
  }

  /// Call all the registered listeners.
  ///
  /// Call this method whenever the menu changes, to notify any clients the menu
  /// item may have changed. Listeners that are added during this iteration will
  /// not be visited. Listeners that are removed during this iteration will not
  /// be visited after they are removed.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// Surprising behavior can result when reentrantly removing a listener (e.g.
  /// in response to a notification) that has been registered multiple times.
  /// See the discussion at [removeChangeListener].
  void notifyChangeListeners(MenuItem<T> item) {
    // Send the event to passive listeners.
    for (final ValueChanged<MenuItem<T>> listener
        in List<ValueChanged<MenuItem<T>>>.from(_listeners)) {
      if (_listeners.contains(listener)) {
        try {
          listener(item);
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'widget library',
            context: ErrorDescription(
                'while dispatching notifications for $runtimeType'),
            informationCollector: () sync* {
              yield DiagnosticsProperty<_MenuChangeNotifier<T>>(
                'The $runtimeType sending notification was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              );
            },
          ));
        }
      }
    }
  }


  /// Register a listener that is called every time the menu item is selected.
  ///
  /// Listeners can be removed with [removeChangeListener].
  void addSelectionListener(ValueChanged<MenuItem<T>> listener) {
    _selectionListeners.add(listener);
    print('$this has ${_selectionListeners.length} selection listeners.');
  }

  /// Stop calling the given listener every time the menu item is selected.
  ///
  /// For [MenuItem]s, this is notified every time the submenu is opened.
  ///
  /// Listeners can be added with [addChangeListener].
  void removeSelectionListener(ValueChanged<MenuItem<T>> listener) {
    _selectionListeners.remove(listener);
  }

  /// Call all the registered selection listeners.
  ///
  /// Call this method whenever the menu changes, to notify any clients the menu
  /// item may have changed. Listeners that are added during this iteration will
  /// not be visited. Listeners that are removed during this iteration will not
  /// be visited after they are removed.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// Surprising behavior can result when reentrantly removing a listener (e.g.
  /// in response to a notification) that has been registered multiple times.
  /// See the discussion at [removeChangeListener].
  void notifySelectionListeners(MenuItem<T> item) {
    // Send the event to passive listeners.
    for (final ValueChanged<MenuItem<T>> listener
    in List<ValueChanged<MenuItem<T>>>.from(_selectionListeners)) {
      if (_selectionListeners.contains(listener)) {
        try {
          listener(item);
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'widget library',
            context: ErrorDescription(
                'while dispatching notifications for $runtimeType'),
            informationCollector: () sync* {
              yield DiagnosticsProperty<_MenuChangeNotifier<T>>(
                'The $runtimeType sending notification was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              );
            },
          ));
        }
      }
    }
  }
}

///
typedef MenuItemSelectCallback<T> = void Function(MenuItem<T> item);

/// Represents a submenu.
class MenuItem<T> with DiagnosticableTreeMixin, _MenuChangeNotifier<T> {
  /// Creates a menu model that contains child menu items.
  MenuItem(
    T value, {
    this.description,
    List<MenuItem<T>>? items,
    MenuItemSelectCallback<T>? selectCallback,
    IconData? icon,
  })  : _value = value,
        _icon = icon,
        _selectCallback = selectCallback,
        _items = items ?? <MenuItem<T>>[];

  /// The value that this menu item represents.
  T get value => _value;
  T _value;
  set value(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      notifyChangeListeners(this);
    }
  }

  /// The label displayed on the entry for this item in the menu. Defaults to
  /// the string representation of [value].
  String get label => value.toString();

  /// An optional string description for this model.
  ///
  /// This is meant to be a slightly longer description than the label, telling
  /// the user what this item represents. For example, this can be used when
  /// describing the menu item in a preference UI for assigning a shortcut.
  final String? description;

  /// The callback invoked if this menu item is selected.
  MenuItemSelectCallback<T>? get selectCallback => _selectCallback;
  MenuItemSelectCallback<T>? _selectCallback;
  set selectCallback(MenuItemSelectCallback<T>? value) {
    if (value != _selectCallback) {
      _selectCallback = value;
      notifyChangeListeners(this);
    }
  }

  /// The optional icon to place before the label in the menu.
  IconData? get icon => _icon;
  IconData? _icon;
  set icon(IconData? icon) {
    if (icon != _icon) {
      _icon = icon;
      notifyChangeListeners(this);
    }
  }

  /// Selects the menu item by invoking the associated callback and notifying
  /// any selection listeners.
  ///
  /// Calling [select] on a [MenuItem] with sub-items toggles whether or not
  /// the submenu is open.
  @mustCallSuper
  void select() {
    if (isNotEmpty) {
      isOpen = !_isOpen;
    }
    selectCallback?.call(this);
    notifySelectionListeners(this);
  }

  /// Whether this entry represents a particular value. The default
  /// implementation just compares the given `testValue` with [value] using
  /// operator ==.
  bool represents(T? testValue) => testValue == value;

  ///
  @mustCallSuper
  void added() => items.forEach(_notifyItemAdded);

  ///
  @mustCallSuper
  void removed() => items.forEach(_notifyItemRemoved);

  /// The menu items that are children of this menu, in the order they appear.
  /// Order of appearance in this list isn't necessarily the order visually laid
  /// out on the screen. Visual order is affected by the layout anchor and
  /// direction of the [MenuBar] that they are managed by. The getter returns a
  /// copy of the actual list, to avoid inadvertent modification of the order or
  /// contents without notifying listeners. Use add/insert/remove to modify the
  /// order of items.
  Iterable<MenuItem<T>> get items => _items.toList();
  List<MenuItem<T>> _items;
  set items(Iterable<MenuItem<T>> value) {
    if (value != _items) {
      _items.forEach(_notifyItemRemoved);
      _items = value.toList();
      _items.forEach(_notifyItemAdded);
      notifyChangeListeners(this);
    }
  }

  /// Returns the `i`th element in the list of child menu items.
  MenuItem<T> operator [](int i) => _items[i];

  /// Returns the number of child menu items.
  int get length => items.length;

  /// Returns true if the submenu item list is empty
  bool get isEmpty => items.isEmpty;

  /// Returns true if the submenu item list is not empty.
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether or not this submenu is currently open.
  bool get isOpen => _isOpen;
  bool _isOpen = false;
  set isOpen(bool value) {
    if (_isOpen != value) {
      _isOpen = value;
      notifyChangeListeners(this);
    }
  }

  ///
  void closeAll() {
    for (final MenuItem<T> item in items) {
      item.isOpen = false;
      item.closeAll();
    }
  }

  void _notifyItemRemoved(MenuItem<T> item) {
    item.removeChangeListener(notifyChangeListeners);
    item.removeSelectionListener(notifySelectionListeners);
    item.removed();
  }

  void _notifyItemAdded(MenuItem<T> item) {
    item.added();
    item.addChangeListener(notifyChangeListeners);
    item.addSelectionListener(notifySelectionListeners);
  }

  /// Append an item at the end of this sub menu.
  void add(MenuItem<T> item) {
    _items.add(item);
    _notifyItemAdded(item);
  }

  /// Insert an item at a particular index to this sub menu.
  void insert(int index, MenuItem<T> item) {
    _items.insert(index, item);
    _notifyItemAdded(item);
  }

  /// Removes an item from the sub menu.
  /// Returns true if it found the item and removed it.
  bool remove(MenuItem<T> item) {
    final bool removed = _items.remove(item);
    if (removed) {
      _notifyItemRemoved(item);
    }
    return removed;
  }

  /// Removes the item at `index`.
  void removeAt(int index) {
    final MenuItem<T> removed = _items[index];
    _items.removeAt(index);
    _notifyItemRemoved(removed);
  }

  /// Removes an item by value.
  /// Returns true if it found an and removed it.
  bool removeByValue(T value) {
    bool removed = false;
    _items.removeWhere((MenuItem<T> item) {
      if (item.represents(value)) {
        _notifyItemRemoved(item);
        removed = true;
        return true;
      }
      return false;
    });
    notifyChangeListeners(this);
    return removed;
  }

  /// Removes an item by value.
  /// Returns true if it found an and removed it.
  MenuItem<T> findByValue(T value) {
    return _items.firstWhere((MenuItem<T> item) {
      if (item.represents(value)) {
        _notifyItemRemoved(item);
        return true;
      }
      return false;
    });
  }

  /// Removes an item by value.
  /// Returns true if it found an and removed it.
  int findIndexByValue(T value) {
    return _items.indexWhere((MenuItem<T> item) {
      if (item.represents(value)) {
        _notifyItemRemoved(item);
        return true;
      }
      return false;
    });
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      ...items.map<DiagnosticsNode>((MenuItem<T> item) {
        return item.toDiagnosticsNode();
      }),
    ];
  }
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
    properties.add(StringProperty('description', description));
    properties.add(DiagnosticsProperty<IconData>('icon', icon));
    properties.add(IntProperty('length', length));
  }
}
