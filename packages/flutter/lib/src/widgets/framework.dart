// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'debug.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

export 'dart:ui' show hashValues, hashList;
export 'package:flutter/rendering.dart' show RenderObject, RenderBox, debugPrint;
export 'package:flutter/foundation.dart' show FlutterError;

// KEYS

/// A [Key] is an identifier for [Widget]s and [Element]s.
///
/// A new widget will only be used to update an existing element if its key is
/// the same as the key of the current widget associted with the element.
///
/// Keys must be unique amongst the [Element]s with the same parent.
///
/// Subclasses of [Key] should either subclass [LocalKey] or [GlobalKey].
abstract class Key {
  /// Construct a [ValueKey<String>] with the given [String].
  ///
  /// This is the simplest way to create keys.
  factory Key(String value) => new ValueKey<String>(value);

  /// Default constructor, used by subclasses.
  ///
  /// Useful so that subclasses can call us, because the Key() factory
  /// constructor shadows the implicit constructor.
  const Key._();
}

/// A key that is not a [GlobalKey].
///
/// Keys must be unique amongst the [Element]s with the same parent. By
/// contrast, [GlobalKey]s must be unique across the entire app.
abstract class LocalKey extends Key {
  /// Default constructor, used by subclasses.
  const LocalKey() : super._();
}

/// A key that uses a value of a particular type to identify itself.
///
/// A [ValueKey<T>] is equal to another [ValueKey<T>] if, and only if, their
/// values are [operator==].
class ValueKey<T> extends LocalKey {
  /// Creates a key that delgates its [operator==] to the given value.
  const ValueKey(this.value);

  /// The value to which this key delegates its [operator==]
  final T value;

  @override
  bool operator ==(dynamic other) {
    if (other is! ValueKey<T>)
      return false;
    final ValueKey<T> typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[\'$value\']';
}

/// A key that is only equal to itself.
class UniqueKey extends LocalKey {
  /// Creates a key that is equal only to itself.
  UniqueKey();

  @override
  String toString() => '[$hashCode]';
}

/// A key that takes its identity from the object used as its value.
///
/// Used to tie the identity of a widget to the identity of an object used to
/// generate that widget.
class ObjectKey extends LocalKey {
  /// Creates a key that uses [identical] on [value] for its [operator==].
  const ObjectKey(this.value);

  /// The object whose identity is used by this key's [operator==].
  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other is! ObjectKey)
      return false;
    final ObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
}

/// Signature for a callback when a global key is removed from the tree.
typedef void GlobalKeyRemoveListener(GlobalKey key);

/// A key that is unique across the entire app.
///
/// Global keys uniquely indentify elements. Global keys provide access to other
/// objects that are associated with elements, such as the a [BuildContext] and,
/// for [StatefulWidget]s, a [State].
///
/// Widgets that have global keys reparent their subtrees when they are moved
/// from one location in the tree to another location in the tree. In order to
/// reparent its subtree, a widget must arrive at its new location in the tree
/// in the same animation frame in which it was removed from its old location in
/// the tree.
///
/// Global keys are relatively expensive. If you don't need any of the features
/// listed above, consider using a [Key], [ValueKey], [ObjectKey], or
/// [UniqueKey] instead.
@optionalTypeArgs
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {
  /// Creates a [LabeledGlobalKey], which is a [GlobalKey] with a label used for debugging.
  ///
  /// The label is purely for debugging and not used for comparing the identity
  /// of the key.
  factory GlobalKey({ String debugLabel }) => new LabeledGlobalKey<T>(debugLabel); // the label is purely for debugging purposes and is otherwise ignored

  /// Creates a global key without a label.
  ///
  /// Used by subclasss because the factory constructor shadows the implicit
  /// constructor.
  const GlobalKey.constructor() : super._();

  static final Map<GlobalKey, Element> _registry = new Map<GlobalKey, Element>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeyRemoveListener>> _removeListeners = new Map<GlobalKey, Set<GlobalKeyRemoveListener>>();
  static final Set<GlobalKey> _removedKeys = new HashSet<GlobalKey>();

  void _register(Element element) {
    assert(() {
      if (_registry.containsKey(this)) {
        int oldCount = _debugDuplicates.putIfAbsent(this, () => 1);
        assert(oldCount >= 1);
        _debugDuplicates[this] = oldCount + 1;
      }
      return true;
    });
    _registry[this] = element;
  }

  void _unregister(Element element) {
    assert(() {
      if (_registry.containsKey(this) && _debugDuplicates.containsKey(this)) {
        int oldCount = _debugDuplicates[this];
        assert(oldCount >= 2);
        if (oldCount == 2) {
          _debugDuplicates.remove(this);
        } else {
          _debugDuplicates[this] = oldCount - 1;
        }
      }
      return true;
    });
    if (_registry[this] == element) {
      _registry.remove(this);
      _removedKeys.add(this);
    }
  }

  Element get _currentElement => _registry[this];

  /// The build context in which the widget with this key builds.
  ///
  /// The current context is null if there is no widget in the tree that matches
  /// this global key.
  BuildContext get currentContext => _currentElement;

  /// The widget in the tree that currently has this global key.
  ///
  /// The current widget is null if there is no widget in the tree that matches
  /// this global key.
  Widget get currentWidget => _currentElement?.widget;

  /// The [State] for the widget in the tree that currently has this global key.
  ///
  /// The current state is null if (1) there is no widget in the tree that
  /// matches this global key, (2) that widget is not a [StatefulWidget], or the
  /// assoicated [State] object is not a subtype of `T`.
  T get currentState {
    Element element = _currentElement;
    if (element is StatefulElement) {
      StatefulElement statefulElement = element;
      State state = statefulElement.state;
      if (state is T)
        return state;
    }
    return null;
  }

  /// Calls `listener` whenever a widget with the given global key is removed
  /// from the tree.
  ///
  /// Listeners can be removed with [unregisterRemoveListener].
  static void registerRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    Set<GlobalKeyRemoveListener> listeners =
        _removeListeners.putIfAbsent(key, () => new HashSet<GlobalKeyRemoveListener>());
    bool added = listeners.add(listener);
    assert(added);
  }

  /// Stop calling `listener` whenever a widget with the given global key is
  /// removed from the tree.
  ///
  /// Listeners can be added with [addListener].
  static void unregisterRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    assert(_removeListeners.containsKey(key));
    assert(_removeListeners[key].contains(listener));
    bool removed = _removeListeners[key].remove(listener);
    if (_removeListeners[key].isEmpty)
      _removeListeners.remove(key);
    assert(removed);
  }

  static bool _debugCheckForDuplicates() {
    String message = '';
    for (GlobalKey key in _debugDuplicates.keys) {
      message += 'The following GlobalKey was found multiple times among mounted elements: $key (${_debugDuplicates[key]} instances)\n';
      message += 'The most recently registered instance is: ${_registry[key]}\n';
    }
    if (_debugDuplicates.isNotEmpty) {
      throw new FlutterError(
        'Incorrect GlobalKey usage.\n'
        '$message'
      );
    }
    return true;
  }

  static void _notifyListeners() {
    if (_removedKeys.isEmpty)
      return;
    try {
      for (GlobalKey key in _removedKeys) {
        if (!_registry.containsKey(key) && _removeListeners.containsKey(key)) {
          Set<GlobalKeyRemoveListener> localListeners = new HashSet<GlobalKeyRemoveListener>.from(_removeListeners[key]);
          for (GlobalKeyRemoveListener listener in localListeners)
            listener(key);
        }
      }
    } catch (e, stack) {
      _debugReportException('while notifying GlobalKey listeners', e, stack);
    } finally {
      _removedKeys.clear();
    }
  }

}

/// A global key with a debugging label.
///
/// The debug label is useful for documentation and for debugging. The label
/// does not affect the key's identity.
class LabeledGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  /// Creates a global key with a debugging label.
  ///
  /// The label does not affect the key's identity.
  const LabeledGlobalKey(this._debugLabel) : super.constructor();

  final String _debugLabel;

  @override
  String toString() => '[GlobalKey ${_debugLabel != null ? _debugLabel : hashCode}]';
}

/// A global key that takes its identity from the object used as its value.
///
/// Used to tie the identity of a widget to the identity of an object used to
/// generate that widget.
class GlobalObjectKey extends GlobalKey {
  /// Creates a global key that uses [identical] on [value] for its [operator==].
  const GlobalObjectKey(this.value) : super.constructor();

  /// The object whose identity is used by this key's [operator==].
  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other is! GlobalObjectKey)
      return false;
    final GlobalObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() => '[$runtimeType ${value.runtimeType}(${value.hashCode})]';
}

/// This class is a work-around for the "is" operator not accepting a variable value as its right operand
@optionalTypeArgs
class TypeMatcher<T> {
  /// Creates a type matcher for the given type parameter.
  const TypeMatcher();

  /// Returns `true` if the given object is of type `T`.
  bool check(dynamic object) => object is T;
}

/// Describes the configuration for an [Element].
///
/// Widgets are the central class hierarchy in the Flutter framework. A widget
/// is an immutable description of part of a user interface. Widgets can be
/// inflated into elements, which manage the underlying render tree.
///
/// Widgets themselves have no mutable state. If you wish to associate
/// mutatable state with a widget, consider using a [StatefulWidget], which
/// creates a [State] object (via [StatefulWidget.createState]) whenever it is
/// inflated into an element and incorporated into the tree.
///
/// A given widget can be included in the tree zero or more times. In particular
/// a given widget can be placed in the tree multiple times. Each time a widget
/// is placed in the tree, it is inflated into an [Element], which means a
/// widget that is incorporated into the tree multiple times will be inflated
/// multiple times.
///
/// The [key] property controls how one widget replaces another widget in the
/// tree. If the [runtimeType] and [key] properties of the two widgets are
/// [operator==], respectively, then the new widget replaces the old widget by
/// updating the underlying element (i.e., by calling [Element.update] with the
/// new widget). Otherwise, the old element is removed from the tree, the new
/// widget is inflated into an element, and the new element is inserted into the
/// tree.
///
/// See also:
///
///  * [StatelessWidget]
///  * [StatefulWidget]
///  * [InheritedWidget]
abstract class Widget {
  /// Initializes [key] for subclasses.
  const Widget({ this.key });

  /// Controls how one widget replaces another widget in the tree.
  ///
  /// If the [runtimeType] and [key] properties of the two widgets are
  /// [operator==], respectively, then the new widget replaces the old widget by
  /// updating the underlying element (i.e., by calling [Element.update] with the
  /// new widget). Otherwise, the old element is removed from the tree, the new
  /// widget is inflated into an element, and the new element is inserted into the
  /// tree.
  final Key key;

  /// Inflates this configuration to a concrete instance.
  ///
  /// A given widget can be included in the tree zero or more times. In particular
  /// a given widget can be placed in the tree multiple times. Each time a widget
  /// is placed in the tree, it is inflated into an [Element], which means a
  /// widget that is incorporated into the tree multiple times will be inflated
  /// multiple times.
  @protected
  Element createElement();

  /// A short, textual description of this widget.
  String toStringShort() {
    return key == null ? '$runtimeType' : '$runtimeType-$key';
  }

  @override
  String toString() {
    final String name = toStringShort();
    final List<String> data = <String>[];
    debugFillDescription(data);
    if (data.isEmpty)
      return '$name';
    return '$name(${data.join("; ")})';
  }

  /// Accumulates a list of strings describing the current widget's fields, one
  /// field per string.
  ///
  /// Subclasses should override this to have their information included in
  /// [toString].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) { }

  /// Whether the `newWidget` can be used to update an [Element] that currently
  /// has the `oldWidget` as its configuration.
  ///
  /// An element that uses a given widget as its configuration can be updated to
  /// use another widget as its configuration if, and only if, the two widgets
  /// have [runtimeType] and [key] properties that are [operator==].
  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }
}

/// A widget that does not require mutable state.
///
/// A stateless widget is a widget that describes part of the user interface by
/// building a constellation of other widgets that describe the user interface
/// more concretely. The building process continues recursively until the
/// description of the user interface is fully concrete (e.g., consists
/// enitrely of [RenderObjectWidget]s, which describe concrete [RenderObject]s).
///
/// Stateless widget are useful when the part of the user interface you are
/// describing does not depend on anything other than the configuration
/// information in the object itself and the [BuildContext] in which the widget
/// is inflated. For compositions that can change dynamically, e.g. due to
/// having an internal clock-driven state, or depending on some system state,
/// consider using [StatefulWidget].
///
/// See also:
///
///  * [StatefulWidget]
abstract class StatelessWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatelessWidget({ Key key }) : super(key: key);

  /// Creates a [StatelessElement] to manage this widget's location in the tree.
  ///
  /// It is uncommon for subclasses to override this method.
  @override
  StatelessElement createElement() => new StatelessElement(this);

  /// Describes the part of the user interface represented by this widget.
  ///
  /// The framework calls this method when this widget is inserted into the
  /// tree in a given [BuildContext] and when the dependencies of this widget
  /// change (e.g., an [InheritedWidget] referenced by this widget changes).
  ///
  /// The framework replaces the subtree below this widget with the widget
  /// returned by this method, either by updating the existing subtree or by
  /// removing the subtree and inflating a new subtree, depending on whether the
  /// widget returned by this method can update the root of the existing
  /// subtree, as determined by calling [Widget.canUpdate].
  ///
  /// Typically implementations return a newly created constellation of widgets
  /// that are configured with information from this widget's constructor and
  /// from the given [BuildContext].
  ///
  /// The given [BuildContext] contains information about the location in the
  /// tree at which this widget is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree. A
  /// given widget might be with multiple different [BuildContext] arguments
  /// over time if the widget is moved around the tree or if the widget is
  /// inserted into the tree in multiple places at once.
  @protected
  Widget build(BuildContext context);
}

/// A widget that has mutable state.
///
/// State is information (1) that can be read synchronously when the widget is
/// built and (2) for which we will be notified when it changes.
///
/// A stateful widget is a widget that describes part of the user interface by
/// building a constellation of other widgets that describe the user interface
/// more concretely. The building process continues recursively until the
/// description of the user interface is fully concrete (e.g., consists
/// enitrely of [RenderObjectWidget]s, which describe concrete [RenderObject]s).
///
/// Stateless widget are useful when the part of the user interface you are
/// describing can change dynamically, e.g. due to having an internal
/// clock-driven state, or depending on some system state. For compositions that
/// depend only on the configuration information in the object itself and the
/// [BuildContext] in which the widget is inflated, consider using
/// [StatelessWidget].
///
/// [StatefulWidget] instances themselves are immutable and store their mutable
/// state in separate [State] objects that are created by the [createState]
/// method. The framework calls [createState] whenever it inflates a
/// [StatefulWidget], which means that multiple [State] objects might be
/// associated with the same [StatefulWidget] if that widget has been inserted
/// into the tree in multiple places. Similarly, if a [StatefulWidget] is
/// removed from the tree and later inserted in to the tree again, the framework
/// will call [createState] again to create a fresh [State] object, simplifying
/// the lifecycle of [State] objects.
///
/// A [StatefulWidget] keeps the same [State] object when moving from one
/// location in the tree to another if its creator used a [GlobalKey] for its
/// [key]. Because a widget with a [GlobalKey] can be used in at most one
/// location in the tree, a widget that uses a [GlobalKey] has at most one
/// associated element. The framework takes advantage of this property when
/// moving a widget with a global key from one location in the tree to another
/// by grafting the (unique) subtree associated with that widget from the old
/// location to the new location (instead of recreating the subtree at the new
/// location). The [State] objects associated with [StatefulWidget] are grafted
/// along with the rest of the subtree, which means the [State] object is reused
/// (instead of being recreated) in the new location. However, in order to be
/// eligible for grafting, the widget might be inserted into the new location in
/// the same animation frame in which it was removed from the old location.
///
/// See also:
///
///  * [State]
///  * [StatelessWidget]
abstract class StatefulWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatefulWidget({ Key key }) : super(key: key);

  /// Creates a [StatefulElement] to manage this widget's location in the tree.
  ///
  /// It is uncommon for subclasses to override this method.
  @override
  StatefulElement createElement() => new StatefulElement(this);

  /// Creates the mutable state for this widget at a given location in the tree.
  ///
  /// Subclasses should override this method to return a newly created
  /// instance of their associated [State] subclass:
  ///
  /// ```dart
  /// @override
  /// _MyState createState() => new _MyState();
  /// ```
  ///
  /// The framework can call this method multiple times over the lifetime of
  /// a [StatefulWidget]. For example, if the widget is inserted into the tree
  /// in multiple locations, the framework will create a separate [State] object
  /// for each location. Similarly, if the widget is removed from the tree and
  /// later inserted into the tree again, the framework will call [createState]
  /// again to create a fresh [State] object, simplifying the lifecycle of
  /// [State] objects.
  @protected
  State createState();
}

/// Tracks the lifecycle of [State] objects when asserts are enabled.
enum _StateLifecycle {
  /// The [State] object has been created but [State.initState] has not yet been
  /// called.
  created,

  /// The [State.initState] method has been called but the [State] object is
  /// not yet ready to build.
  initialized,

  /// The [State] object is ready to build and [State.dispose] has not yet been
  /// called.
  ready,

  /// The [State.dispose] method has been called and the [State] object is
  /// no longer able to build.
  defunct,
}

/// The signature of [State.setState] functions.
typedef void StateSetter(VoidCallback fn);

/// The logic and internal state for a [StatefulWidget].
///
/// State is information (1) that can be read synchronously when the widget is
/// built and (2) for which we will be notified when it changes.
///
/// [State] objects are created by the framework by calling the
/// [StatefulWidget.createState] method when inflating a [StatefulWidget] to
/// insert it into the tree. Because a given [StatefulWidget] instance can be
/// inflated multiple times (e.g., the widget is incorporated into the tree in
/// multiple places at once), there might be more than one [State] object
/// associated with a given [StatefulWidget] instance. Similarly, if a
/// [StatefulWidget] is removed from the tree and later inserted in to the tree
/// again, the framework will call [StatefulWidget.createState] again to create
/// a fresh [State] object, simplifying the lifecycle of [State] objects.
///
/// [State] objects have the following lifecycle:
///
///  * The framework creates a [State] object by calling
///    [StatefulWidget.createState].
///  * The newly created [State] object is associated with a [BuildContext].
///    This association is permanent: the [State] object will never change its
///    [BuildContext]. However, the [BuildContext] itself can be moved around
///    the tree along with its subtree. At this point, the [State] object is
///    considered [mounted].
///  * The framework calls [initState]. Subclasses of [State] should override
///    [initState] to perform one-time initialization that depends on the
///    [BuildContext] or the widget, which are available as the [context] and
///    [config] properties, respectively, when the [initState] method is
///    called.
///  * At this point, the [State] object is fully initialized and the framework
///    might call its [build] method any number of times to obtain a
///    description of the user interface for this subtree. [State] objects can
///    spontanteously request to rebuild their subtree by callings their
///    [setState] method, which indicates that some of their internal state
///    has changed in a way that might impact the user interface in this
///    subtree.
///  * During this time, a parent widget might rebuild and request that this
///    location in the tree update to display a new widget with the same
///    [runtimeType] and [key]. When this happens, the framework will update the
///    [config] property to refer to the new widget and then call the
///    [didUpdateConfig] method with the previous widget as an argument.
///    [State] objects should override [didUpdateConfig] to respond to changes
///    in their associated wiget (e.g., to start implicit animations).
///    The framework always calls [build] after calling [didUpdateConfig], which
///    means any calls to [setState] in [didUpdateConfig] are redundant.
///  * If the subtree containing the [State] object is removed from the tree
///    (e.g., because the parent built a widget with a different [runtimeType]
///    or [key]), the framework calls the [deactivate] method. Subclasses
///    should override this method to clean up any links between this object
///    and other elements in the tree (e.g. if you have provided an ancestor
///    with a pointer to a descendant's [RenderObject]).
///  * At this point, the framework might reinsert this subtree into another
///    part of the tree. If that happens, the framework will ensure that it
///    calls [build] to give the [State] object a chance to adapt to its new
///    location in the tree. If the framework does reinsert this subtree, it
///    will do so before the end of the animation frame in which the subtree was
///    removed from the tree. For this reason, [State] objects can defer
///    releasing most resources until the framework calls their [dispose]
///    method.
///  * If the framework does not reinsert this subtree by the end of the current
///    animation frame, the framework will call [dispose], which indiciates that
///    this [State] object will never build again. Subclasses should override
///    this method to release any resources retained by this object (e.g.,
///    stop any active animations).
///  * After the framework calls [dispose], the [State] object is considered
///    unmounted and the [mounted] property is false. It is an error to call
///    [setState] at this point. This stage of the lifecycle is terminal: there
///    is no way to remount a [State] object that has been disposed.
///
/// See also:
///
///  * [StatefulWidget]
///  * [StatelessWidget]
@optionalTypeArgs
abstract class State<T extends StatefulWidget> {
  /// The current configuration.
  ///
  /// A [State] object's configuration is the corresponding [StatefulWidget]
  /// instance. This property is initialized by the framework before calling
  /// [initState]. If the parent updates this location in the tree to a new
  /// widget with the same [runtimeType] and [key] as the current configuration,
  /// the framework will update this property to refer to the new widget and
  /// then call [didUpdateConfig], passing the old configuration as an argument.
  T get config => _config;
  T _config;

  /// The current stage in the lifecycle for this state object.
  ///
  /// This field is used by the framework when asserts are enabled to verify
  /// that [State] objects move through their lifecycle in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Verifies that the [State] that was created is one that expects to be
  /// created for that particular [Widget].
  bool _debugTypesAreRight(Widget widget) => widget is T;

  /// The [StatefulElement] that owns this [State] object.
  ///
  /// The framework associates [State] objects with an element after creating
  /// them with [StatefulWidget.createState] and before calling [initState]. The
  /// association is permanent: the [State] object will never change its
  /// element. However, the element itself can be moved around the tree.
  ///
  /// After calling [dispose], the framework severs the [State] object's
  /// connection with the element.
  StatefulElement _element;

  /// The location in the tree where this widget builds.
  ///
  /// The framework associates [State] objects with a [BuildContext] after
  /// creating them with [StatefulWidget.createState] and before calling
  /// [initState]. The association is permanent: the [State] object will never
  /// change its [BuildContext]. However, the [BuildContext] itself can be moved
  /// around the tree.
  ///
  /// After calling [dispose], the framework severs the [State] object's
  /// connection with the [BuildContext].
  BuildContext get context => _element;

  /// Whether this [State] object is currently in a tree.
  ///
  /// After creating a [State] object and before calling [initState], the
  /// framework "mounts" the [State] object by associating it with a
  /// [BuildContext]. The [State] object remains mounted until the framework
  /// calls [dispose], after which time the framework will never ask the [State]
  /// object to [build] again.
  ///
  /// It is an error to call [setState] unless [mounted] is true.
  bool get mounted => _element != null;

  /// Called when this object is inserted into the tree.
  ///
  /// Override this method to perform initialization that depends on the
  /// location at which this object was inserted into the tree (i.e., [context])
  /// or on the widget used to configure this object (i.e., [config])
  ///
  /// The framework will call this method exactly once for each [State] object
  /// it creates.
  ///
  /// If you override this, make sure your method starts with a call to
  /// super.initState().
  @protected
  @mustCallSuper
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
    assert(() { _debugLifecycleState = _StateLifecycle.initialized; return true; });
  }

  /// Called whenever the configuration changes.
  ///
  /// If the parent widget rebuilds and request that this location in the tree
  /// update to display a new widget with the same [runtimeType] and [key], the
  /// framework will update the [config] property of this [State] object to
  /// refer to the new widget and then call the this method with the previous
  /// widget as an argument.
  ///
  /// Override this metthod to respond to changes in the [config] widget (e.g.,
  /// to start implicit animations).
  ///
  /// The framework always calls [build] after calling [didUpdateConfig], which
  /// means any calls to [setState] in [didUpdateConfig] are redundant.
  ///
  /// If you override this, make sure your method starts with a call to
  /// super.didUpdateConfig(oldConfig).
  // TODO(abarth): Add @mustCallSuper.
  @protected
  void didUpdateConfig(T oldConfig) { }

  /// Called whenever the application is reassembled during debugging.
  ///
  /// This method should rerun any initialization logic that depends on global
  /// state, for example, image loading from asset bundles (since the asset
  /// bundle may have changed).
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signalled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// This function will only be called during development. In release builds,
  /// the `ext.flutter.reassemble` hook is not available, and so this code will
  /// never execute.
  ///
  /// See also:
  ///
  /// * [BindingBase.reassembleApplication]
  /// * [Image], which uses this to reload images
  @protected
  @mustCallSuper
  void reassemble() { }

  /// Notify the framework that the internal state of this object has changed.
  ///
  /// Whenever you change the internal state of a [State] object, make the
  /// change in a function that you pass to [setState]:
  ///
  /// ```dart
  /// setState(() { _myState = newValue });
  /// ```
  ///
  /// Calling [setState] notifies the framework that the internal state of this
  /// object has changed in a way that might impact the user interface in this
  /// subtree, which causes the framework to schedule a [build] for this [State]
  /// object.
  ///
  /// If you just change the state directly without calling [setState], the
  /// framework might not schedule a [build] and the user interface for this
  /// subtree might not be updated to reflect the new state.
  ///
  /// It is an error to call this method after the framework calls [dispose].
  /// You can determine whether it is legal to call this method by checking
  /// whether the [mounted] property is true.
  @protected
  void setState(VoidCallback fn) {
    assert(() {
      if (_debugLifecycleState == _StateLifecycle.defunct) {
        throw new FlutterError(
          'setState() called after dispose(): $this\n'
          'This error happens if you call setState() on State object for a widget that '
          'no longer appears in the widget tree (e.g., whose parent widget no longer '
          'includes the widget in its build). This error can occur when code calls '
          'setState() from a timer or an animation callback. The preferred solution is '
          'to cancel the timer or stop listening to the animation in the dispose() '
          'callback. Another solution is to check the "mounted" property of this '
          'object before calling setState() to ensure the object is still in the '
          'tree.\n'
          '\n'
          'This error might indicate a memory leak if setState() is being called '
          'because another object is retaining a reference to this State object '
          'after it has been removed from the tree. To avoid memory leaks, '
          'consider breaking the reference to this object during dipose().'
        );
      }
      return true;
    });
    dynamic result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        throw new FlutterError(
          'setState() callback argument returned a Future.\n'
          'The setState() method on $this was called with a closure or method that '
          'returned a Future. Maybe it is marked as "async".\n'
          'Instead of performing asynchronous work inside a call to setState(), first '
          'execute the work (without updating the widget state), and then synchronously '
          'update the state inside a call to setState().'
        );
      }
      // We ignore other types of return values so that you can do things like:
      //   setState(() => x = 3);
      return true;
    });
    _element.markNeedsBuild();
  }

  /// Called when this object is removed from the tree.
  ///
  /// The framework calls this method whenever it removes this [State] object
  /// from the tree. In some cases, the framework will reinsert the [State]
  /// object into another part of the tree (e.g., if the subtree containing this
  /// [State] object is grafted from one location in the tree to another). If
  /// that happens, the framework will ensure that it calls [build] to give the
  /// [State] object a chance to adapt to its new location in the tree. If
  /// the framework does reinsert this subtree, it will do so before the end of
  /// the animation frame in which the subtree was removed from the tree. For
  /// this reason, [State] objects can defer releasing most resources until the
  /// framework calls their [dispose] method.
  ///
  /// Subclasses should override this method to clean up any links between
  /// this object and other elements in the tree (e.g. if you have provided an
  /// ancestor with a pointer to a descendant's [RenderObject]).
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.deactivate().
  @protected
  @mustCallSuper
  void deactivate() { }

  /// Called when this object is removed from the tree permanently.
  ///
  /// The framework calls this method when this [State] object will never
  /// build again. After the framework calls [dispose], the [State] object is
  /// considered unmounted and the [mounted] property is false. It is an error
  /// to call [setState] at this point. This stage of the lifecycle is terminal:
  /// there is no way to remount a [State] object that has been disposed.
  ///
  /// Subclasses should override this method to release any resources retained
  /// by this object (e.g., stop any active animations).
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.dispose().
  @protected
  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() { _debugLifecycleState = _StateLifecycle.defunct; return true; });
  }

  /// Describes the part of the user interface represented by this widget.
  ///
  /// The framework calls this method in a number of different situations:
  ///
  ///  * After calling [initState].
  ///  * After calling [didUpdateConfig].
  ///  * After receiving a call to [setState].
  ///  * After a dependency of this [State] object changes (e.g., an
  ///    [InheritedWidget] referenced by the previous [build] changes).
  ///  * After calling [deactivate] and then reinserting the [State] object into
  ///    the tree at another location.
  ///
  /// The framework replaces the subtree below this widget with the widget
  /// returned by this method, either by updating the existing subtree or by
  /// removing the subtree and inflating a new subtree, depending on whether the
  /// widget returned by this method can update the root of the existing
  /// subtree, as determined by calling [Widget.canUpdate].
  ///
  /// Typically implementations return a newly created constellation of widgets
  /// that are configured with information from this widget's constructor, the
  /// given [BuildContext], and the internal state of this [State] object.
  ///
  /// The given [BuildContext] contains information about the location in the
  /// tree at which this widget is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree. The
  /// [BuildContext] argument is always the same as the [context] property of
  /// this [State] object and will remain the same for the lifetime of this
  /// object. The [BuildContext] argument is provided redundantly here so that
  /// this method matches the signature for a [WidgetBuilder].
  @protected
  Widget build(BuildContext context);

  /// Called when a dependencies of this [State] object changes.
  ///
  /// For example, if the previous call to [build] referenced an
  /// [InheritedWidget] that later changed, the framework would call this
  /// method to notify this object about the change.
  ///
  /// Subclasses rarely override this method because the framework always
  /// calls [build] after a dependency changes. Some subclasses do override
  /// this method because they need to do some expensive work (e.g., network
  /// fetches) when their dependencies change, and that work would be too
  /// expensive to do for every build.
  @protected
  @mustCallSuper
  void dependenciesChanged() { }

  @override
  String toString() {
    final List<String> data = <String>[];
    debugFillDescription(data);
    return '$runtimeType(${data.join("; ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [State] base class calls [debugFillDescription] to collect useful
  /// information from subclasses to incorporate into its return value.
  ///
  /// If you override this, make sure to start your method with a call to
  /// super.debugFillDescription(description).
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    description.add('$hashCode');
    assert(() {
      if (_debugLifecycleState != _StateLifecycle.ready)
        description.add('$_debugLifecycleState');
      return true;
    });
    if (_config == null)
      description.add('no config');
    if (_element == null)
      description.add('not mounted');
  }
}

abstract class _ProxyWidget extends Widget {
  const _ProxyWidget({ Key key, this.child }) : super(key: key);

  final Widget child;
}

abstract class ParentDataWidget<T extends RenderObjectWidget> extends _ProxyWidget {
  const ParentDataWidget({ Key key, Widget child })
    : super(key: key, child: child);

  @override
  ParentDataElement<T> createElement() => new ParentDataElement<T>(this);

  /// Subclasses should override this method to return true if the given
  /// ancestor is a RenderObjectWidget that wraps a RenderObject that can handle
  /// the kind of ParentData widget that the ParentDataWidget subclass handles.
  ///
  /// The default implementation uses the type argument.
  bool debugIsValidAncestor(RenderObjectWidget ancestor) {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    return ancestor is T;
  }

  /// Subclasses should override this to describe the requirements for using the
  /// ParentDataWidget subclass. It is called when debugIsValidAncestor()
  /// returned false for an ancestor, or when there are extraneous
  /// ParentDataWidgets in the ancestor chain.
  String debugDescribeInvalidAncestorChain({ String description, String ownershipChain, bool foundValidAncestor, Iterable<Widget> badAncestors }) {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    String result;
    if (!foundValidAncestor) {
      result = '$runtimeType widgets must be placed inside $T widgets.\n'
               '$description has no $T ancestor at all.\n';
    } else {
      assert(badAncestors.isNotEmpty);
      result = '$runtimeType widgets must be placed directly inside $T widgets.\n'
               '$description has a $T ancestor, but there are other widgets between them:\n';
      for (Widget ancestor in badAncestors) {
        if (ancestor.runtimeType == runtimeType) {
          result += '  $ancestor (this is a different $runtimeType than the one with the problem)\n';
        } else {
          result += '  $ancestor\n';
        }
      }
      result += 'These widgets cannot come between a $runtimeType and its $T.\n';
    }
    result += 'The ownership chain for the parent of the offending $runtimeType was:\n  $ownershipChain';
    return result;
  }

  @protected
  void applyParentData(RenderObject renderObject);
}

abstract class InheritedWidget extends _ProxyWidget {
  const InheritedWidget({ Key key, Widget child })
    : super(key: key, child: child);

  @override
  InheritedElement createElement() => new InheritedElement(this);

  @protected
  bool updateShouldNotify(InheritedWidget oldWidget);
}

/// RenderObjectWidgets provide the configuration for [RenderObjectElement]s,
/// which wrap [RenderObject]s, which provide the actual rendering of the
/// application.
abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({ Key key }) : super(key: key);

  /// RenderObjectWidgets always inflate to a [RenderObjectElement] subclass.
  @override
  RenderObjectElement createElement();

  /// Creates an instance of the [RenderObject] class that this
  /// [RenderObjectWidget] represents, using the configuration described by this
  /// [RenderObjectWidget].
  @protected
  RenderObject createRenderObject(BuildContext context);

  /// Copies the configuration described by this [RenderObjectWidget] to the
  /// given [RenderObject], which will be of the same type as returned by this
  /// object's [createRenderObject].
  @protected
  void updateRenderObject(BuildContext context, RenderObject renderObject) { }

  @protected
  void didUnmountRenderObject(RenderObject renderObject) { }
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({ Key key }) : super(key: key);

  @override
  LeafRenderObjectElement createElement() => new LeafRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single child slot. (This superclass only provides the storage
/// for that child, it doesn't actually provide the updating logic.)
abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  const SingleChildRenderObjectWidget({ Key key, this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  SingleChildRenderObjectElement createElement() => new SingleChildRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({ Key key, this.children })
    : super(key: key) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  final List<Widget> children;

  @override
  MultiChildRenderObjectElement createElement() => new MultiChildRenderObjectElement(this);
}


// ELEMENTS

enum _ElementLifecycle {
  initial,
  active,
  inactive,
  defunct,
}

class _InactiveElements {
  bool _locked = false;
  final Set<Element> _elements = new HashSet<Element>();

  void _unmount(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.unmount();
    assert(element._debugLifecycleState == _ElementLifecycle.defunct);
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
  }

  void _unmountAll() {
    try {
      _locked = true;
      for (Element element in _elements)
        _unmount(element);
    } finally {
      _elements.clear();
      _locked = false;
    }
  }

  void _deactivateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.deactivate();
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.visitChildren(_deactivateRecursively);
    assert(() { element.debugDeactivated(); return true; });
  }

  void add(Element element) {
    assert(!_locked);
    assert(!_elements.contains(element));
    assert(element._parent == null);
    if (element._active)
      _deactivateRecursively(element);
    _elements.add(element);
  }

  void remove(Element element) {
    assert(!_locked);
    assert(_elements.contains(element));
    assert(element._parent == null);
    _elements.remove(element);
    assert(!element._active);
  }
}

/// Signature for the callback to [BuildContext.visitChildElements].
///
/// The argument is the child being visited.
///
/// It is safe to call `element.visitChildElements` reentrantly within
/// this callback.
typedef void ElementVisitor(Element element);

abstract class BuildContext {
  Widget get widget;
  RenderObject findRenderObject();
  InheritedWidget inheritFromWidgetOfExactType(Type targetType);
  Widget ancestorWidgetOfExactType(Type targetType);
  State ancestorStateOfType(TypeMatcher matcher);
  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher);
  void visitAncestorElements(bool visitor(Element element));
  void visitChildElements(ElementVisitor visitor);
}

class BuildOwner {
  BuildOwner({ this.onBuildScheduled });

  /// Called on each build pass when the first buildable element is marked dirty
  VoidCallback onBuildScheduled;

  final _InactiveElements _inactiveElements = new _InactiveElements();

  final List<BuildableElement> _dirtyElements = <BuildableElement>[];

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when buildDirtyElements is called.
  void scheduleBuildFor(BuildableElement element) {
    assert(() {
      if (_dirtyElements.contains(element)) {
        throw new FlutterError(
          'scheduleBuildFor() called for a widget for which a build was already scheduled.\n'
          'The method was called for the following element:\n'
          '  $element\n'
          'The current dirty list consists of:\n'
          '  $_dirtyElements\n'
          'This should not be possible and probably indicates a bug in the widgets framework. '
          'Please report it: https://github.com/flutter/flutter/issues/new'
        );
      }
      if (!element.dirty) {
        throw new FlutterError(
          'scheduleBuildFor() called for a widget that is not marked as dirty.\n'
          'The method was called for the following element:\n'
          '  $element\n'
          'This element is not current marked as dirty. Make sure to set the dirty flag before '
          'calling scheduleBuildFor().\n'
          'If you did not attempt to call scheduleBuildFor() yourself, then this probably '
          'indicates a bug in the widgets framework. Please report it: '
          'https://github.com/flutter/flutter/issues/new'
        );
      }
      return true;
    });
    if (_dirtyElements.isEmpty && onBuildScheduled != null)
      onBuildScheduled();
    _dirtyElements.add(element);
  }

  int _debugStateLockLevel = 0;
  bool get _debugStateLocked => _debugStateLockLevel > 0;
  bool _debugBuilding = false;
  BuildableElement _debugCurrentBuildTarget;

  /// Establishes a scope in which calls to [State.setState] are forbidden.
  ///
  /// This mechanism prevents build functions from transitively requiring other
  /// build functions to run, potentially causing infinite loops.
  ///
  /// If the building argument is true, then this function enables additional
  /// asserts that check invariants that should apply during building.
  ///
  /// The context argument is used to describe the scope in case an exception is
  /// caught while invoking the callback.
  void lockState(void callback(), { bool building: false }) {
    bool debugPreviouslyBuilding;
    assert(_debugStateLockLevel >= 0);
    assert(() {
      if (building) {
        debugPreviouslyBuilding = _debugBuilding;
        _debugBuilding = true;
      }
      _debugStateLockLevel += 1;
      return true;
    });
    try {
      callback();
    } finally {
      assert(() {
        _debugStateLockLevel -= 1;
        if (building) {
          assert(_debugBuilding);
          _debugBuilding = debugPreviouslyBuilding;
        }
        return true;
      });
    }
    assert(_debugStateLockLevel >= 0);
  }

  static int _elementSort(BuildableElement a, BuildableElement b) {
    if (a.depth < b.depth)
      return -1;
    if (b.depth < a.depth)
      return 1;
    if (b.dirty && !a.dirty)
      return -1;
    if (a.dirty && !b.dirty)
      return 1;
    return 0;
  }

  /// Builds all the elements that were marked as dirty using schedule(), in depth order.
  /// If elements are marked as dirty while this runs, they must be deeper than the algorithm
  /// has yet reached.
  /// This is called by beginFrame().
  void buildDirtyElements() {
    if (_dirtyElements.isEmpty)
      return;
    Timeline.startSync('Build');
    try {
      lockState(() {
        _dirtyElements.sort(_elementSort);
        int dirtyCount = _dirtyElements.length;
        int index = 0;
        while (index < dirtyCount) {
          assert(() {
            if (debugPrintRebuildDirtyWidgets)
              debugPrint('Rebuilding ${_dirtyElements[index].widget}');
            return true;
          });
          _dirtyElements[index].rebuild();
          index += 1;
          if (dirtyCount < _dirtyElements.length) {
            _dirtyElements.sort(_elementSort);
            dirtyCount = _dirtyElements.length;
          }
        }
        assert(!_dirtyElements.any((BuildableElement element) => element.dirty));
      }, building: true);
    } finally {
      _dirtyElements.clear();
      Timeline.finishSync();
    }
  }

  /// Complete the element build pass by unmounting any elements that are no
  /// longer active.
  ///
  /// This is called by beginFrame().
  ///
  /// In checked mode, this also verifies that each global key is used at most
  /// once.
  ///
  /// After the current call stack unwinds, a microtask that notifies listeners
  /// about changes to global keys will run.
  void finalizeTree() {
    Timeline.startSync('Finalize tree');
    try {
      lockState(() {
        _inactiveElements._unmountAll();
      });
      assert(GlobalKey._debugCheckForDuplicates);
      scheduleMicrotask(GlobalKey._notifyListeners);
    } catch (e, stack) {
      _debugReportException('while finalizing the widget tree', e, stack);
    } finally {
      Timeline.finishSync();
    }
  }

  /// Cause the entire subtree rooted at the given [Element] to
  /// be entirely rebuilt. This is used by development tools when
  /// the application code has changed, to cause the widget tree to
  /// pick up any changed implementations.
  ///
  /// This is expensive and should not be called except during
  /// development.
  void reassemble(Element root) {
    assert(root._parent == null);
    assert(root.owner == this);
    root._reassemble();
  }
}

/// Elements are the instantiations of Widget configurations.
///
/// Elements can, in principle, have children. Only subclasses of
/// RenderObjectElement are allowed to have more than one child.
abstract class Element implements BuildContext {
  Element(Widget widget) : _widget = widget {
    assert(widget != null);
  }

  Element _parent;

  /// Information set by parent to define where this child fits in its parent's
  /// child list.
  ///
  /// Subclasses of Element that only have one child should use null for
  /// the slot for that child.
  dynamic get slot => _slot;
  dynamic _slot;

  /// An integer that is guaranteed to be greater than the parent's, if any.
  /// The element at the root of the tree must have a depth greater than 0.
  int get depth => _depth;
  int _depth;

  /// The configuration for this element.
  @override
  Widget get widget => _widget;
  Widget _widget;

  /// The owner for this node (null if unattached).
  BuildOwner get owner => _owner;
  BuildOwner _owner;

  bool _active = false;

  void _reassemble() {
    assert(_active);
    visitChildren((Element child) {
      child._reassemble();
    });
  }

  RenderObject get renderObject {
    RenderObject result;
    void visit(Element element) {
      assert(result == null); // this verifies that there's only one child
      if (element is RenderObjectElement)
        result = element.renderObject;
      else
        element.visitChildren(visit);
    }
    visit(this);
    return result;
  }

  /// This is used to verify that Element objects move through life in an orderly fashion.
  _ElementLifecycle _debugLifecycleState = _ElementLifecycle.initial;

  /// Calls the argument for each child. Must be overridden by subclasses that support having children.
  void visitChildren(ElementVisitor visitor) { }

  /// Wrapper around visitChildren for BuildContext.
  @override
  void visitChildElements(void visitor(Element element)) {
    // don't allow visitChildElements() during build, since children aren't necessarily built yet
    assert(owner == null || !owner._debugStateLocked);
    visitChildren(visitor);
  }

  bool detachChild(Element child) => false;

  /// This method is the core of the system.
  ///
  /// It is called each time we are to add, update, or remove a child based on
  /// an updated configuration.
  ///
  /// If the child is null, and the newWidget is not null, then we have a new
  /// child for which we need to create an Element, configured with newWidget.
  ///
  /// If the newWidget is null, and the child is not null, then we need to
  /// remove it because it no longer has a configuration.
  ///
  /// If neither are null, then we need to update the child's configuration to
  /// be the new configuration given by newWidget. If newWidget can be given to
  /// the existing child, then it is so given. Otherwise, the old child needs
  /// to be disposed and a new child created for the new configuration.
  ///
  /// If both are null, then we don't have a child and won't have a child, so
  /// we do nothing.
  ///
  /// The updateChild() method returns the new child, if it had to create one,
  /// or the child that was passed in, if it just had to update the child, or
  /// null, if it removed the child and did not replace it.
  @protected
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    if (newWidget == null) {
      if (child != null)
        deactivateChild(child);
      return null;
    }
    if (child != null) {
      if (child.widget == newWidget) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        return child;
      }
      if (Widget.canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        return child;
      }
      deactivateChild(child);
      assert(child._parent == null);
    }
    return inflateWidget(newWidget, newSlot);
  }

  /// Called when an Element is given a new parent shortly after having been
  /// created. Use this to initialize state that depends on having a parent. For
  /// state that is independent of the position in the tree, it's better to just
  /// initialize the Element in the constructor.
  @mustCallSuper
  void mount(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.initial);
    assert(widget != null);
    assert(_parent == null);
    assert(parent == null || parent._debugLifecycleState == _ElementLifecycle.active);
    assert(slot == null);
    assert(depth == null);
    assert(!_active);
    _parent = parent;
    _slot = newSlot;
    _depth = _parent != null ? _parent.depth + 1 : 1;
    _active = true;
    if (parent != null) // Only assign ownership if the parent is non-null
      _owner = parent.owner;
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._register(this);
    }
    _updateInheritance();
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  /// Called when an Element receives a new configuration widget.
  @mustCallSuper
  void update(Widget newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(newWidget != null);
    assert(newWidget != widget);
    assert(depth != null);
    assert(_active);
    assert(Widget.canUpdate(widget, newWidget));
    _widget = newWidget;
  }

  /// Called by MultiChildRenderObjectElement, and other RenderObjectElement
  /// subclasses that have multiple children, to update the slot of a particular
  /// child when the child is moved in its child list.
  @protected
  void updateSlotForChild(Element child, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(child != null);
    assert(child._parent == this);
    void visit(Element element) {
      element._updateSlot(newSlot);
      if (element is! RenderObjectElement)
        element.visitChildren(visit);
    }
    visit(child);
  }

  void _updateSlot(dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(_parent != null);
    assert(_parent._debugLifecycleState == _ElementLifecycle.active);
    assert(depth != null);
    _slot = newSlot;
  }

  void _updateDepth(int parentDepth) {
    int expectedDepth = parentDepth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth(expectedDepth);
      });
    }
  }

  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
    _slot = null;
  }

  void attachRenderObject(dynamic newSlot) {
    assert(_slot == null);
    visitChildren((Element child) {
      child.attachRenderObject(newSlot);
    });
    _slot = newSlot;
  }

  Element _retakeInactiveElement(GlobalKey key, Widget newWidget) {
    Element element = key._currentElement;
    if (element == null)
      return null;
    if (!Widget.canUpdate(element.widget, newWidget))
      return null;
    if (element._parent != null && !element._parent.detachChild(element))
      return null;
    assert(element._parent == null);
    owner._inactiveElements.remove(element);
    return element;
  }

  @protected
  Element inflateWidget(Widget newWidget, dynamic newSlot) {
    assert(newWidget != null);
    Key key = newWidget.key;
    if (key is GlobalKey) {
      Element newChild = _retakeInactiveElement(key, newWidget);
      if (newChild != null) {
        assert(newChild._parent == null);
        assert(() { _debugCheckForCycles(newChild); return true; });
        newChild._activateWithParent(this, newSlot);
        Element updatedChild = updateChild(newChild, newWidget, newSlot);
        assert(newChild == updatedChild);
        return updatedChild;
      }
    }
    Element newChild = newWidget.createElement();
    assert(() { _debugCheckForCycles(newChild); return true; });
    newChild.mount(this, newSlot);
    assert(newChild._debugLifecycleState == _ElementLifecycle.active);
    return newChild;
  }

  void _debugCheckForCycles(Element newChild) {
    assert(newChild._parent == null);
    assert(() {
      Element node = this;
      while (node._parent != null)
        node = node._parent;
      assert(node != newChild); // indicates we are about to create a cycle
      return true;
    });
  }

  @protected
  void deactivateChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner._inactiveElements.add(child); // this eventually calls child.deactivate()
  }

  void _activateWithParent(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    _parent = parent;
    _updateDepth(_parent.depth);
    _activateRecursively(this);
    attachRenderObject(newSlot);
    assert(_debugLifecycleState == _ElementLifecycle.active);
  }

  static void _activateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.activate();
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.visitChildren(_activateRecursively);
  }

  /// Called when a previously de-activated widget (see [deactivate]) is reused
  /// instead of being unmounted (see [unmount]).
  @mustCallSuper
  void activate() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    _active = true;
    // We unregistered our dependencies in deactivate, but never cleared the list.
    // Since we're going to be reused, let's clear our list now.
    _dependencies?.clear();
    _updateInheritance();
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  // TODO(ianh): Define activation/deactivation thoroughly (other methods point
  // here for details).
  @mustCallSuper
  void deactivate() {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(depth != null);
    assert(_active);
    if (_dependencies != null && _dependencies.length > 0) {
      for (InheritedElement dependency in _dependencies)
        dependency._dependents.remove(this);
      // For expediency, we don't actually clear the list here, even though it's
      // no longer representative of what we are registered with. If we never
      // get re-used, it doesn't matter. If we do, then we'll clear the list in
      // activate(). The benefit of this is that it allows BuildableElement's
      // activate() implementation to decide whether to rebuild based on whether
      // we had dependencies here.
    }
    _inheritedWidgets = null;
    _active = false;
    assert(() { _debugLifecycleState = _ElementLifecycle.inactive; return true; });
  }

  /// Called after children have been deactivated (see [deactivate]).
  @mustCallSuper
  void debugDeactivated() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
  }

  /// Called when an Element is removed from the tree permanently after having
  /// been deactivated (see [deactivate]).
  @mustCallSuper
  void unmount() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._unregister(this);
    }
    assert(() { _debugLifecycleState = _ElementLifecycle.defunct; return true; });
  }

  @override
  RenderObject findRenderObject() => renderObject;

  Map<Type, InheritedElement> _inheritedWidgets;
  Set<InheritedElement> _dependencies;
  bool _hadUnsatisfiedDependencies = false;

  @override
  InheritedWidget inheritFromWidgetOfExactType(Type targetType) {
    InheritedElement ancestor = _inheritedWidgets == null ? null : _inheritedWidgets[targetType];
    if (ancestor != null) {
      assert(ancestor is InheritedElement);
      _dependencies ??= new HashSet<InheritedElement>();
      _dependencies.add(ancestor);
      ancestor._dependents.add(this);
      return ancestor.widget;
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

  void _updateInheritance() {
    assert(_active);
    _inheritedWidgets = _parent?._inheritedWidgets;
  }

  @override
  Widget ancestorWidgetOfExactType(Type targetType) {
    Element ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != targetType)
      ancestor = ancestor._parent;
    return ancestor?.widget;
  }

  @override
  State ancestorStateOfType(TypeMatcher matcher) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && matcher.check(ancestor.state))
        break;
      ancestor = ancestor._parent;
    }
    StatefulElement statefulAncestor = ancestor;
    return statefulAncestor?.state;
  }

  @override
  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && matcher.check(ancestor.renderObject))
        break;
      ancestor = ancestor._parent;
    }
    RenderObjectElement renderObjectAncestor = ancestor;
    return renderObjectAncestor?.renderObject;
  }

  /// Calls visitor for each ancestor element.
  ///
  /// Continues until visitor reaches the root or until visitor returns false.
  @override
  void visitAncestorElements(bool visitor(Element element)) {
    Element ancestor = _parent;
    while (ancestor != null && visitor(ancestor))
      ancestor = ancestor._parent;
  }

  @mustCallSuper
  void dependenciesChanged() { }

  String debugGetCreatorChain(int limit) {
    List<String> chain = <String>[];
    Element node = this;
    while (chain.length < limit && node != null) {
      chain.add(node.toStringShort());
      node = node._parent;
    }
    if (node != null)
      chain.add('\u22EF');
    return chain.join(' \u2190 ');
  }

  String toStringShort() {
    return widget != null ? '${widget.toStringShort()}' : '[$runtimeType]';
  }

  @override
  String toString() {
    final List<String> data = <String>[];
    debugFillDescription(data);
    final String name = widget != null ? '${widget.runtimeType}' : '[$runtimeType]';
    return '$name(${data.join("; ")})';
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (depth == null)
      description.add('no depth');
    if (widget == null) {
      description.add('no widget');
    } else {
      if (widget.key != null)
        description.add('${widget.key}');
      widget.debugFillDescription(description);
    }
  }

  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    String result = '$prefixLineOne$this\n';
    List<Element> children = <Element>[];
    visitChildren(children.add);
    if (children.length > 0) {
      Element last = children.removeLast();
      for (Element child in children)
        result += '${child.toStringDeep("$prefixOtherLines \u251C", "$prefixOtherLines \u2502")}';
      result += '${last.toStringDeep("$prefixOtherLines \u2514", "$prefixOtherLines  ")}';
    }
    return result;
  }
}

/// A widget that renders an exception's message. This widget is used when a
/// build function fails, to help with determining where the problem lies.
/// Exceptions are also logged to the console, which you can read using `flutter
/// logs`. The console will also include additional information such as the
/// stack trace for the exception.
class ErrorWidget extends LeafRenderObjectWidget {
  ErrorWidget(
    Object exception
  ) : message = _stringify(exception),
      super(key: new UniqueKey());

  final String message;

  static String _stringify(Object exception) {
    try {
      return exception.toString();
    } catch (e) { }
    return 'Error';
  }

  @override
  RenderBox createRenderObject(BuildContext context) => new RenderErrorBox(message);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('message: ' + _stringify(message));
  }
}

/// Base class for instantiations of widgets that have builders and can be
/// marked dirty.
abstract class BuildableElement extends Element {
  BuildableElement(Widget widget) : super(widget);

  /// Returns true if the element has been marked as needing rebuilding.
  bool get dirty => _dirty;
  bool _dirty = true;

  // We let widget authors call setState from initState, didUpdateConfig, and
  // build even when state is locked because its convenient and a no-op anyway.
  // This flag ensures that this convenience is only allowed on the element
  // currently undergoing initState, didUpdateConfig, or build.
  bool _debugAllowIgnoredCallsToMarkNeedsBuild = false;
  bool _debugSetAllowIgnoredCallsToMarkNeedsBuild(bool value) {
    assert(_debugAllowIgnoredCallsToMarkNeedsBuild == !value);
    _debugAllowIgnoredCallsToMarkNeedsBuild = value;
    return true;
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and widgets should be structured so as to only mark
  /// widgets dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    assert(_debugLifecycleState != _ElementLifecycle.defunct);
    if (!_active)
      return;
    assert(owner != null);
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(() {
      if (owner._debugBuilding) {
        if (owner._debugCurrentBuildTarget == null) {
          // If _debugCurrentBuildTarget is null, we're not actually building a
          // widget but instead building the root of the tree via runApp.
          // TODO(abarth): Remove these cases and ensure that we always have
          // a current build target when we're building.
          return true;
        }
        bool foundTarget = false;
        visitAncestorElements((Element element) {
          if (element == owner._debugCurrentBuildTarget) {
            foundTarget = true;
            return false;
          }
          return true;
        });
        if (foundTarget)
          return true;
      }
      if (owner._debugStateLocked && (!_debugAllowIgnoredCallsToMarkNeedsBuild || !dirty)) {
        throw new FlutterError(
          'setState() or markNeedsBuild() called during build.\n'
          'This widget cannot be marked as needing to build because the framework '
          'is already in the process of building widgets. A widget can be marked as '
          'needing to be built during the build phase only if one if its ancestors '
          'is currently building. This exception is allowed because the framework '
          'builds parent widgets before children, which means a dirty descendant '
          'will always be built. Otherwise, the framework might not visit this '
          'widget during this build phase.'
        );
      }
      return true;
    });
    if (dirty)
      return;
    _dirty = true;
    owner.scheduleBuildFor(this);
  }

  /// Called by the binding when scheduleBuild() has been called to mark this
  /// element dirty, and, in components, by update() when the widget has
  /// changed.
  void rebuild() {
    assert(_debugLifecycleState != _ElementLifecycle.initial);
    if (!_active || !_dirty) {
      _dirty = false;
      return;
    }
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(owner._debugStateLocked);
    BuildableElement debugPreviousBuildTarget;
    assert(() {
      debugPreviousBuildTarget = owner._debugCurrentBuildTarget;
      owner._debugCurrentBuildTarget = this;
     return true;
    });
    _hadUnsatisfiedDependencies = false;
    // In theory, we would also clear our actual _dependencies here. However, to
    // clear it we'd have to notify each of them, unregister from them, and then
    // reregister as soon as the build function re-dependended on it. So to
    // avoid faffing around we just never unregister our dependencies except
    // when we're deactivated. In principle this means we might be getting
    // notified about widget types we once inherited from but no longer do, but
    // in practice this is so rare that the extra cost when it does happen is
    // far outweighed by the avoided work in the common case.
    // We _do_ clear the list properly any time our ancestor chain changes in a
    // way that might result in us getting a different Element's Widget for a
    // particular Type. This avoids the potential of being registered to
    // multiple identically-typed Widgets' Elements at the same time.
    performRebuild();
    assert(() {
      assert(owner._debugCurrentBuildTarget == this);
      owner._debugCurrentBuildTarget = debugPreviousBuildTarget;
      return true;
    });
    assert(!_dirty);
  }

  /// Called by rebuild() after the appropriate checks have been made.
  @protected
  void performRebuild();

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    assert(_active);
    markNeedsBuild();
  }

  @override
  void activate() {
    final bool shouldRebuild = ((_dependencies != null && _dependencies.length > 0) || _hadUnsatisfiedDependencies);
    super.activate(); // clears _dependencies, and sets active to true
    if (shouldRebuild) {
      assert(_active); // otherwise markNeedsBuild is a no-op
      markNeedsBuild();
    }
  }

  @override
  void _reassemble() {
    assert(_active); // otherwise markNeedsBuild is a no-op
    markNeedsBuild();
    super._reassemble();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dirty)
      description.add('dirty');
  }
}

typedef Widget WidgetBuilder(BuildContext context);
typedef Widget IndexedWidgetBuilder(BuildContext context, int index);

// See ComponentElement._builder.
Widget _buildNothing(BuildContext context) => null;

/// Base class for the instantiation of [StatelessWidget], [StatefulWidget],
/// and [_ProxyWidget] widgets.
abstract class ComponentElement extends BuildableElement {
  ComponentElement(Widget widget) : super(widget);

  // Initializing this field with _buildNothing helps the compiler prove that
  // this field always holds a closure.
  WidgetBuilder _builder = _buildNothing;

  Element _child;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    assert(_active);
    _firstBuild();
    assert(_child != null);
  }

  void _firstBuild() {
    rebuild();
  }

  /// Calls the build() method of the [StatelessWidget] object (for
  /// stateless widgets) or the [State] object (for stateful widgets) and
  /// then updates the widget tree.
  ///
  /// Called automatically during mount() to generate the first build, and by
  /// rebuild() when the element needs updating.
  @override
  void performRebuild() {
    assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(true));
    Widget built;
    try {
      built = _builder(this);
      debugWidgetBuilderValue(widget, built);
    } catch (e, stack) {
      _debugReportException('building $_widget', e, stack);
      built = new ErrorWidget(e);
    } finally {
      // We delay marking the element as clean until after calling _builder so
      // that attempts to markNeedsBuild() during build() will be ignored.
      _dirty = false;
      assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(false));
    }
    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      _debugReportException('building $_widget', e, stack);
      built = new ErrorWidget(e);
      _child = updateChild(null, built, slot);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  bool detachChild(Element child) {
    assert(child == _child);
    deactivateChild(_child);
    _child = null;
    return true;
  }
}

/// Instantiation of [StatelessWidget]s.
class StatelessElement extends ComponentElement {
  StatelessElement(StatelessWidget widget) : super(widget) {
    _builder = widget.build;
  }

  @override
  StatelessWidget get widget => super.widget;

  @override
  void update(StatelessWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _builder = widget.build;
    _dirty = true;
    rebuild();
  }

  @override
  void _reassemble() {
    _builder = widget.build;
    super._reassemble();
  }
}

/// Instantiation of [StatefulWidget]s.
class StatefulElement extends ComponentElement {
  StatefulElement(StatefulWidget widget)
    : _state = widget.createState(), super(widget) {
    assert(_state._debugTypesAreRight(widget));
    assert(_state._element == null);
    _state._element = this;
    assert(_builder == _buildNothing);
    _builder = _state.build;
    assert(_state._config == null);
    _state._config = widget;
    assert(_state._debugLifecycleState == _StateLifecycle.created);
  }

  State<StatefulWidget> get state => _state;
  State<StatefulWidget> _state;

  @override
  void _reassemble() {
    _builder = state.build;
    state.reassemble();
    super._reassemble();
  }

  @override
  void _firstBuild() {
    assert(_state._debugLifecycleState == _StateLifecycle.created);
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      _state.initState();
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.initialized)
        return true;
      throw new FlutterError(
        '${_state.runtimeType}.initState failed to call super.initState.\n'
        'initState() implementations must always call their superclass initState() method, to ensure '
        'that the entire widget is initialized correctly.'
      );
    });
    assert(() { _state._debugLifecycleState = _StateLifecycle.ready; return true; });
    super._firstBuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    StatefulWidget oldConfig = _state._config;
    // Notice that we mark ourselves as dirty before calling didUpdateConfig to
    // let authors call setState from within didUpdateConfig without triggering
    // asserts.
    _dirty = true;
    _state._config = widget;
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      _state.didUpdateConfig(oldConfig);
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    rebuild();
  }

  @override
  void activate() {
    super.activate();
    // Since the State could have observed the deactivate() and thus disposed of
    // resources allocated in the build function, we have to rebuild the widget
    // so that its State can reallocate its resources.
    assert(_active); // otherwise markNeedsBuild is a no-op
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _state.dispose();
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.defunct)
        return true;
      throw new FlutterError(
        '${_state.runtimeType}.dispose failed to call super.dispose.\n'
        'dispose() implementations must always call their superclass dispose() method, to ensure '
        'that all the resources used by the widget are fully released.'
      );
    });
    assert(!dirty); // See BuildableElement.unmount for why this is important.
    _state._element = null;
    _state = null;
  }

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _state.dependenciesChanged();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (state != null)
      description.add('state: $state');
  }
}

abstract class _ProxyElement extends ComponentElement {
  _ProxyElement(_ProxyWidget widget) : super(widget) {
    _builder = _build;
  }

  @override
  _ProxyWidget get widget => super.widget;

  Widget _build(BuildContext context) => widget.child;

  @override
  void _reassemble() {
    _builder = _build;
    super._reassemble();
  }

  @override
  void update(_ProxyWidget newWidget) {
    _ProxyWidget oldWidget = widget;
    assert(widget != null);
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    notifyClients(oldWidget);
    _dirty = true;
    rebuild();
  }

  @protected
  void notifyClients(_ProxyWidget oldWidget);
}

class ParentDataElement<T extends RenderObjectWidget> extends _ProxyElement {
  ParentDataElement(ParentDataWidget<T> widget) : super(widget);

  @override
  ParentDataWidget<T> get widget => super.widget;

  @override
  void mount(Element parent, dynamic slot) {
    assert(() {
      List<Widget> badAncestors = <Widget>[];
      Element ancestor = parent;
      while (ancestor != null) {
        if (ancestor is ParentDataElement<RenderObjectWidget>) {
          badAncestors.add(ancestor.widget);
        } else if (ancestor is RenderObjectElement) {
          if (widget.debugIsValidAncestor(ancestor.widget))
            break;
          badAncestors.add(ancestor.widget);
        }
        ancestor = ancestor._parent;
      }
      if (ancestor != null && badAncestors.isEmpty)
        return true;
      throw new FlutterError(
        'Incorrect use of ParentDataWidget.\n' +
        widget.debugDescribeInvalidAncestorChain(
          description: "$this",
          ownershipChain: parent.debugGetCreatorChain(10),
          foundValidAncestor: ancestor != null,
          badAncestors: badAncestors
        )
      );
    });
    super.mount(parent, slot);
  }

  @override
  void notifyClients(ParentDataWidget<T> oldWidget) {
    void notifyChildren(Element child) {
      if (child is RenderObjectElement) {
        child._updateParentData(widget);
      } else {
        assert(child is! ParentDataElement<RenderObjectWidget>);
        child.visitChildren(notifyChildren);
      }
    }
    visitChildren(notifyChildren);
  }
}


class InheritedElement extends _ProxyElement {
  InheritedElement(InheritedWidget widget) : super(widget);

  @override
  InheritedWidget get widget => super.widget;

  final Set<Element> _dependents = new HashSet<Element>();

  @override
  void _updateInheritance() {
    assert(_active);
    final Map<Type, InheritedElement> incomingWidgets = _parent?._inheritedWidgets;
    if (incomingWidgets != null)
      _inheritedWidgets = new Map<Type, InheritedElement>.from(incomingWidgets);
    else
      _inheritedWidgets = new Map<Type, InheritedElement>();
    _inheritedWidgets[widget.runtimeType] = this;
  }

  @override
  void debugDeactivated() {
    assert(() {
      assert(_dependents.isEmpty);
      return true;
    });
    super.debugDeactivated();
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    if (!widget.updateShouldNotify(oldWidget))
      return;
    dispatchDependenciesChanged();
  }

  /// Notifies all dependent elements that this inherited widget has changed.
  ///
  /// [InheritedElement] calls this function if [InheritedWidget.updateShouldNotify]
  /// returns true. Subclasses of [InheritedElement] might wish to call this
  /// function at other times if their inherited information changes outside of
  /// the build phase.
  @protected
  void dispatchDependenciesChanged() {
    for (Element dependent in _dependents) {
      assert(() {
        // check that it really is our descendant
        Element ancestor = dependent._parent;
        while (ancestor != this && ancestor != null)
          ancestor = ancestor._parent;
        return ancestor == this;
      });
      // check that it really deepends on us
      assert(dependent._dependencies.contains(this));
      dependent.dependenciesChanged();
    }
  }
}

/// Base class for instantiations of RenderObjectWidget subclasses
abstract class RenderObjectElement extends BuildableElement {
  RenderObjectElement(RenderObjectWidget widget) : super(widget);

  @override
  RenderObjectWidget get widget => super.widget;

  /// The underlying [RenderObject] for this element
  @override
  RenderObject get renderObject => _renderObject;
  RenderObject _renderObject;

  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  ParentDataElement<RenderObjectWidget> _findAncestorParentDataElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement<RenderObjectWidget>)
        return ancestor;
      ancestor = ancestor._parent;
    }
    return null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _renderObject = widget.createRenderObject(this);
    assert(() { _debugUpdateRenderObjectOwner(); return true; });
    assert(_slot == newSlot);
    attachRenderObject(newSlot);
    _dirty = false;
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    assert(() { _debugUpdateRenderObjectOwner(); return true; });
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  void _debugUpdateRenderObjectOwner() {
    _renderObject.debugCreator = debugGetCreatorChain(10);
  }

  @override
  void performRebuild() {
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  /// Utility function for subclasses that have one or more lists of children.
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  @protected
  List<Element> updateChildren(List<Element> oldChildren, List<Widget> newWidgets, { Set<Element> detachedChildren }) {
    assert(oldChildren != null);
    assert(newWidgets != null);

    Element replaceWithNullIfDetached(Element child) {
      return detachedChildren != null && detachedChildren.contains(child) ? null : child;
    }

    // This attempts to diff the new child list (this.children) with
    // the old child list (old.children), and update our renderObject
    // accordingly.

    // The cases it tries to optimise for are:
    //  - the old list is empty
    //  - the lists are identical
    //  - there is an insertion or removal of one or more widgets in
    //    only one place in the list
    // If a widget with a key is in both lists, it will be synced.
    // Widgets without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the top, syncing nodes, until you no longer have
    //    matching nodes.
    // 2. Walk the lists from the bottom, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning ot end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Sync unkeyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the bottom of the list again, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    List<Element> newChildren = oldChildren.length == newWidgets.length ?
        oldChildren : new List<Element>(newWidgets.length);

    Element previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenTop]);
      Widget newWidget = newWidgets[newChildrenTop];
      assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenBottom]);
      Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = new Map<Key, Element>();
      while (oldChildrenTop <= oldChildrenBottom) {
        Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenTop]);
        assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.widget.key != null)
            oldKeyedChildren[oldChild.widget.key] = oldChild;
          else
            deactivateChild(oldChild);
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element oldChild;
      Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[newWidget.key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scaned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newWidgets.length - newChildrenTop == oldChildren.length - oldChildrenTop);
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfDetached(oldChild) != null);
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      Widget newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // clean up any of the remaining middle nodes from the old list
    if (haveOldChildren && oldKeyedChildren.isNotEmpty) {
      for (Element oldChild in oldKeyedChildren.values) {
        if (detachedChildren == null || !detachedChildren.contains(oldChild))
          deactivateChild(oldChild);
      }
    }

    return newChildren;
  }

  @override
  void deactivate() {
    super.deactivate();
    assert(!renderObject.attached);
  }

  @override
  void unmount() {
    super.unmount();
    assert(!renderObject.attached);
    widget.didUnmountRenderObject(renderObject);
  }

  void _updateParentData(ParentDataWidget<RenderObjectWidget> parentData) {
    parentData.applyParentData(renderObject);
  }

  @override
  void _updateSlot(dynamic newSlot) {
    assert(slot != newSlot);
    super._updateSlot(newSlot);
    assert(slot == newSlot);
    _ancestorRenderObjectElement.moveChildRenderObject(renderObject, slot);
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    assert(_ancestorRenderObjectElement == null);
    _slot = newSlot;
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(renderObject, newSlot);
    ParentDataElement<RenderObjectWidget> parentDataElement = _findAncestorParentDataElement();
    if (parentDataElement != null)
      _updateParentData(parentDataElement.widget);
  }

  @override
  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
    _slot = null;
  }

  @protected
  void insertChildRenderObject(RenderObject child, dynamic slot);

  @protected
  void moveChildRenderObject(RenderObject child, dynamic slot);

  @protected
  void removeChildRenderObject(RenderObject child);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (renderObject != null)
      description.add('renderObject: $renderObject');
  }
}

/// Instantiation of RenderObjectWidgets at the root of the tree
///
/// Only root elements may have their owner set explicitly. All other
/// elements inherit their owner from their parent.
abstract class RootRenderObjectElement extends RenderObjectElement {
  RootRenderObjectElement(RenderObjectWidget widget): super(widget);

  void assignOwner(BuildOwner owner) {
    _owner = owner;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    // Root elements should never have parents
    assert(parent == null);
    assert(newSlot == null);
    super.mount(parent, newSlot);
  }
}

/// Instantiation of RenderObjectWidgets that have no children
class LeafRenderObjectElement extends RenderObjectElement {
  LeafRenderObjectElement(LeafRenderObjectWidget widget): super(widget);

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }
}

/// Instantiation of RenderObjectWidgets that have up to one child
class SingleChildRenderObjectElement extends RenderObjectElement {
  SingleChildRenderObjectElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  SingleChildRenderObjectWidget get widget => super.widget;

  Element _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  bool detachChild(Element child) {
    assert(child == _child);
    deactivateChild(_child);
    _child = null;
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

/// Instantiation of RenderObjectWidgets that can have a list of children
class MultiChildRenderObjectElement extends RenderObjectElement {
  MultiChildRenderObjectElement(MultiChildRenderObjectWidget widget) : super(widget) {
    assert(!debugChildrenHaveDuplicateKeys(widget, widget.children));
  }

  @override
  MultiChildRenderObjectWidget get widget => super.widget;

  List<Element> _children;
  // We keep a set of detached children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _detachedChildren = new HashSet<Element>();

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    renderObject.insert(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children) {
      if (!_detachedChildren.contains(child))
        visitor(child);
    }
  }

  @override
  bool detachChild(Element child) {
    _detachedChildren.add(child);
    deactivateChild(child);
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new List<Element>(widget.children.length);
    Element previousChild;
    for (int i = 0; i < _children.length; ++i) {
      Element newChild = inflateWidget(widget.children[i], previousChild);
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _children = updateChildren(_children, widget.children, detachedChildren: _detachedChildren);
    _detachedChildren.clear();
  }
}

void _debugReportException(String context, dynamic exception, StackTrace stack) {
  FlutterError.reportError(new FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context
  ));
}
