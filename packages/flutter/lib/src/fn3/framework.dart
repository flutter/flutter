// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/rendering.dart';

/// A Key is an identifier for [Widget]s and [Element]s. A new Widget will only
/// be used to reconfigure an existing Element if its Key is the same as its
/// original Widget's Key.
///
/// Keys must be unique amongst the Elements with the same parent.
abstract class Key {
  /// Default constructor, used by subclasses.
  const Key.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor

  /// Construct a ValueKey<String> with the given String.
  /// This is the simplest way to create keys.
  factory Key(String value) => new ValueKey<String>(value);
}

/// A kind of [Key] that uses a value of a particular type to identify itself.
///
/// For example, a ValueKey<String> is equal to another ValueKey<String> if
/// their values match.
class ValueKey<T> extends Key {
  const ValueKey(this.value) : super.constructor();
  final T value;
  String toString() => '[\'${value}\']';
  bool operator==(other) => other is ValueKey<T> && other.value == value;
  int get hashCode => value.hashCode;
}

/// A kind of [Key] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class ObjectKey extends Key {
  const ObjectKey(this.value) : super.constructor();
  final Object value;
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
  bool operator==(other) => other is ObjectKey && identical(other.value, value);
  int get hashCode => identityHashCode(value);
}

typedef void GlobalKeyRemoveListener(GlobalKey key);

/// A GlobalKey is one that must be unique across the entire application. It is
/// used by components that need to communicate with other components across the
/// application's element tree.
abstract class GlobalKey extends Key {
  const GlobalKey.constructor() : super.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor

  /// Constructs a LabeledGlobalKey, which is a GlobalKey with a label used for debugging.
  /// The label is not used for comparing the identity of the key.
  factory GlobalKey({ String label }) => new LabeledGlobalKey(label); // the label is purely for debugging purposes and is otherwise ignored

  static final Map<GlobalKey, Element> _registry = new Map<GlobalKey, Element>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeyRemoveListener>> _removeListeners = new Map<GlobalKey, Set<GlobalKeyRemoveListener>>();
  static final Set<GlobalKey> _removedKeys = new Set<GlobalKey>();

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

  Element get currentElement => _registry[this];
  Widget get currentWidget => currentElement?.widget;
  State get currentState {
    Element element = currentElement;
    if (element is StatefulComponentElement)
      return element.state;
    return null;
  }

  static void registerRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    Set<GlobalKeyRemoveListener> listeners =
        _removeListeners.putIfAbsent(key, () => new Set<GlobalKeyRemoveListener>());
    bool added = listeners.add(listener);
    assert(added);
  }

  static void unregisterRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    assert(_removeListeners.containsKey(key));
    bool removed = _removeListeners[key].remove(listener);
    if (_removeListeners[key].isEmpty)
      _removeListeners.remove(key);
    assert(removed);
  }

  // TODO(ianh): call this
  static void _notifyListeners() {
    assert(() {
      String message = '';
      for (GlobalKey key in _debugDuplicates.keys) {
        message += 'Duplicate GlobalKey found amongst mounted elements: $key (${_debugDuplicates[key]} instances)\n';
        message += 'Most recently registered instance is:\n${_registry[key]}\n';
      }
      if (!_debugDuplicates.isEmpty)
        throw message;
      return true;
    });
    if (_removedKeys.isEmpty)
      return;
    try {
      for (GlobalKey key in _removedKeys) {
        if (!_registry.containsKey(key) && _removeListeners.containsKey(key)) {
          Set<GlobalKeyRemoveListener> localListeners = new Set<GlobalKeyRemoveListener>.from(_removeListeners[key]);
          for (GlobalKeyRemoveListener listener in localListeners)
            listener(key);
        }
      }
    } finally {
      _removedKeys.clear();
    }
  }

}

/// Each LabeledGlobalKey instance is a unique key.
/// The optional label can be used for documentary purposes. It does not affect
/// the key's identity.
class LabeledGlobalKey extends GlobalKey {
  const LabeledGlobalKey(this._label) : super.constructor();
  final String _label;
  String toString() => '[GlobalKey ${_label != null ? _label : hashCode}]';
}

/// A kind of [GlobalKey] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class GlobalObjectKey extends GlobalKey {
  const GlobalObjectKey(this.value) : super.constructor();
  final Object value;
  String toString() => '[GlobalKey ${value.runtimeType}(${value.hashCode})]';
  bool operator==(other) => other is GlobalObjectKey && identical(other.value, value);
  int get hashCode => identityHashCode(value);
}


/// A Widget object describes the configuration for an [Element].
/// Widget subclasses should be immutable with const constructors.
/// Widgets form a tree that is then inflated into an Element tree.
abstract class Widget {
  const Widget({ this.key });
  final Key key;

  /// Inflates this configuration to a concrete instance.
  Element createElement();
}

/// RenderObjectWidgets provide the configuration for [RenderObjectElement]s,
/// which wrap [RenderObject]s, which provide the actual rendering of the
/// application.
abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({ Key key }) : super(key: key);

  /// RenderObjectWidgets always inflate to a RenderObjectElement subclass.
  RenderObjectElement createElement();

  /// Constructs an instance of the RenderObject class that this
  /// RenderObjectWidget represents, using the configuration described by this
  /// RenderObjectWidget.
  RenderObject createRenderObject();

  /// Copies the configuration described by this RenderObjectWidget to the given
  /// RenderObject, which must be of the same type as returned by this class'
  /// createRenderObject().
  void updateRenderObject(RenderObject renderObject, RenderObjectWidget oldWidget) { }

  void didUnmountRenderObject(RenderObject renderObject) { }
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({ Key key }) : super(key: key);

  LeafRenderObjectElement createElement() => new LeafRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single child slot. (This superclass only provides the storage
/// for that child, it doesn't actually provide the updating logic.)
abstract class OneChildRenderObjectWidget extends RenderObjectWidget {
  const OneChildRenderObjectWidget({ Key key, Widget this.child }) : super(key: key);

  final Widget child;

  OneChildRenderObjectElement createElement() => new OneChildRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  const MultiChildRenderObjectWidget({ Key key, List<Widget> this.children })
    : super(key: key);

  final List<Widget> children;

  MultiChildRenderObjectElement createElement() => new MultiChildRenderObjectElement(this);
}

/// StatelessComponents describe a way to compose other Widgets to form reusable
/// parts, which doesn't depend on anything other than the configuration
/// information in the object itself. (For compositions that can change
/// dynamically, e.g. due to having an internal clock-driven state, or depending
/// on some system state, use [StatefulComponent].)
abstract class StatelessComponent extends Widget {
  const StatelessComponent({ Key key }) : super(key: key);

  /// StatelessComponents always use StatelessComponentElements to represent
  /// themselves in the Element tree.
  StatelessComponentElement createElement() => new StatelessComponentElement(this);

  /// Returns another Widget out of which this StatelessComponent is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this component is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);
}

/// StatefulComponents provide the configuration for
/// [StatefulComponentElement]s, which wrap [State]s, which hold mutable state
/// and can dynamically and spontaneously ask to be rebuilt.
abstract class StatefulComponent extends Widget {
  const StatefulComponent({ Key key }) : super(key: key);

  /// StatefulComponents always use StatefulComponentElements to represent
  /// themselves in the Element tree.
  StatefulComponentElement createElement() => new StatefulComponentElement(this);

  /// Returns an instance of the state to which this StatefulComponent is
  /// related, using this object as the configuration. Subclasses should
  /// override this to return a new instance of the State class associated with
  /// this StatefulComponent class, like this:
  ///
  ///   MyState createState() => new MyState(this);
  State createState();
}

enum _StateLifecycle {
  created,
  initialized,
  ready,
  defunct,
}

/// The logic and internal state for a StatefulComponent.
abstract class State<T extends StatefulComponent> {
  /// The current configuration (an instance of the corresponding
  /// StatefulComponent class).
  T get config => _config;
  T _config;

  /// This is used to verify that State objects move through life in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Pointer to the owner Element object
  StatefulComponentElement _element;

  /// The context in which this object will be built
  BuildContext get context => _element;

  /// Called when this object is inserted into the tree. Override this function
  /// to perform initialization that depends on the location at which this
  /// object was inserted into the tree or on the widget configuration object.
  ///
  /// If you override this, make sure your method starts with a call to
  /// super.initState(context).
  void initState(BuildContext context) {
    assert(_debugLifecycleState == _StateLifecycle.created);
    assert(() { _debugLifecycleState = _StateLifecycle.initialized; return true; });
  }

  /// Called whenever the configuration changes. Override this method to update
  /// additional state when the config field's value is changed.
  void didUpdateConfig(T oldConfig) { }

  /// Whenever you need to change internal state for a State object, make the
  /// change in a function that you pass to setState(), as in:
  ///
  ///    setState(() { myState = newValue });
  ///
  /// If you just change the state directly without calling setState(), then the
  /// component will not be scheduled for rebuilding, meaning that its rendering
  /// will not be updated.
  void setState(void fn()) {
    assert(_debugLifecycleState != _StateLifecycle.defunct);
    fn();
    if (_element._builder != null) {
      // _element._builder is set after initState(). We verify that we're past
      // that before calling markNeedsBuild() so that setState()s triggered
      // during initState() during lockState() don't cause any trouble.
      _element.markNeedsBuild();
    }
  }

  /// Called when this object is removed from the tree. Override this to clean
  /// up any resources allocated by this object.
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.dispose().
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() { _debugLifecycleState = _StateLifecycle.defunct; return true; });
  }

  /// Returns another Widget out of which this StatefulComponent is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this component is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);
}

abstract class ProxyWidget extends StatelessComponent {
  const ProxyWidget({ Key key, Widget this.child }) : super(key: key);

  final Widget child;

  Widget build(BuildContext context) => child;
}

abstract class ParentDataWidget extends ProxyWidget {
  ParentDataWidget({ Key key, Widget child })
    : super(key: key, child: child);

  ParentDataElement createElement() => new ParentDataElement(this);

  /// Subclasses should override this function to ensure that they are placed
  /// inside widgets that expect them.
  ///
  /// The given ancestor is the first RenderObjectWidget ancestor of this widget.
  void debugValidateAncestor(RenderObjectWidget ancestor);

  void applyParentData(RenderObject renderObject);
}

abstract class InheritedWidget extends ProxyWidget {
  const InheritedWidget({ Key key, Widget child })
    : super(key: key, child: child);

  InheritedElement createElement() => new InheritedElement(this);

  bool updateShouldNotify(InheritedWidget oldWidget);
}

bool _canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType &&
         oldWidget.key == newWidget.key;
}

enum _ElementLifecycle {
  initial,
  mounted,
  defunct,
}

typedef void ElementVisitor(Element element);

abstract class BuildContext {
  InheritedWidget inheritedWidgetOfType(Type targetType);
  RenderObject findRenderObject();
}

/// Elements are the instantiations of Widget configurations.
///
/// Elements can, in principle, have children. Only subclasses of
/// RenderObjectElement are allowed to have more than one child.
abstract class Element<T extends Widget> implements BuildContext {
  Element(T widget) : _widget = widget {
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
  T get widget => _widget;
  T _widget;

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

  /// Calls the argument for each descendant, depth-first pre-order.
  void visitDescendants(ElementVisitor visitor) {
    void visit(Element element) {
      visitor(element);
      element.visitChildren(visit);
    }
    visitChildren(visit);
  }

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
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    if (newWidget == null) {
      if (child != null)
        _detachChild(child);
      return null;
    }
    if (child != null) {
      if (child.widget == newWidget) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        return child;
      }
      if (_canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        return child;
      }
      _detachChild(child);
      assert(child._parent == null);
    }
    child = newWidget.createElement();
    child.mount(this, newSlot);
    assert(child._debugLifecycleState == _ElementLifecycle.mounted);
    return child;
  }

  /// Called when an Element is given a new parent shortly after having been
  /// created. Use this to initialize state that depends on having a parent. For
  /// state that is independent of the position in the tree, it's better to just
  /// initialize the Element in the constructor.
  void mount(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.initial);
    assert(widget != null);
    assert(_parent == null);
    assert(parent == null || parent._debugLifecycleState == _ElementLifecycle.mounted);
    assert(slot == null);
    assert(depth == null);
    _parent = parent;
    _slot = newSlot;
    _depth = _parent != null ? _parent.depth + 1 : 1;
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._register(this);
    }
    assert(() { _debugLifecycleState = _ElementLifecycle.mounted; return true; });
  }

  /// Called when an Element receives a new configuration widget.
  void update(T newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(widget != null);
    assert(newWidget != null);
    assert(depth != null);
    assert(_canUpdate(widget, newWidget));
    _widget = newWidget;
  }

  /// Called by MultiChildRenderObjectElement, and other RenderObjectElement
  /// subclasses that have multiple children, to update the slot of a particular
  /// child when the child is moved in its child list.
  void updateSlotForChild(Element child, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
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
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(widget != null);
    assert(_parent != null);
    assert(_parent._debugLifecycleState == _ElementLifecycle.mounted);
    assert(depth != null);
    _slot = newSlot;
  }

  void _detachChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;

    bool haveDetachedRenderObject = false;
    void detach(Element descendant) {
      if (!haveDetachedRenderObject) {
        descendant._slot = null;
        if (descendant is RenderObjectElement) {
          descendant.detachRenderObject();
          haveDetachedRenderObject = true;
        }
      }
      descendant.unmount();
      assert(descendant._debugLifecycleState == _ElementLifecycle.defunct);
    }

    detach(child);
    child.visitDescendants(detach);
  }

  /// Called when an Element is removed from the tree.
  /// Currently, an Element removed from the tree never returns.
  void unmount() {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(widget != null);
    assert(depth != null);
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._unregister(this);
    }
    assert(() { _debugLifecycleState = _ElementLifecycle.defunct; return true; });
  }

  Set<Type> _dependencies;
  InheritedWidget inheritedWidgetOfType(Type targetType) {
    if (_dependencies == null)
      _dependencies = new Set<Type>();
    _dependencies.add(targetType);
    Element ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != targetType)
      ancestor = ancestor._parent;
    return ancestor?.widget;
  }

  RenderObject findRenderObject() => renderObject;

  void dependenciesChanged() {
    assert(false);
  }
}

class ErrorWidget extends LeafRenderObjectWidget {
  RenderBox createRenderObject() => new RenderErrorBox();
}

typedef Widget WidgetBuilder(BuildContext context);
typedef void BuildScheduler(BuildableElement element);

/// Base class for the instantiation of StatelessComponent and StatefulComponent
/// widgets.
abstract class BuildableElement<T extends Widget> extends Element<T> {
  BuildableElement(T widget) : super(widget);

  WidgetBuilder _builder;
  Element _child;

  /// Returns true if the element has been marked as needing rebuilding.
  bool get dirty => _dirty;
  bool _dirty = true;

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    rebuild();
    assert(_child != null);
  }

  /// Reinvokes the build() method of the StatelessComponent object (for
  /// stateless components) or the State object (for stateful components) and
  /// then updates the widget tree.
  ///
  /// Called automatically during mount() to generate the first build, by the
  /// binding when scheduleBuild() has been called to mark this element dirty,
  /// and by update() when the Widget has changed.
  void rebuild() {
    assert(_debugLifecycleState != _ElementLifecycle.initial);
    if (!_dirty)
      return;
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    _dirty = false;
    Widget built;
    try {
      built = _builder(this);
      assert(built != null);
    } catch (e, stack) {
      _debugReportException('building $this', e, stack);
      built = new ErrorWidget();
    }

    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      _debugReportException('building $this', e, stack);
      built = new ErrorWidget();
      _child = updateChild(null, built, slot);
    }
  }

  static BuildScheduler scheduleBuildFor;

  static int _debugStateLockLevel = 0;
  static bool get _debugStateLocked => _debugStateLockLevel > 0;

  /// Calls the callback argument synchronously, but in a context where calls to
  /// State.setState() will fail. Use this when it is possible that you will
  /// trigger code in components but want to make sure that there is no
  /// possibility that any components will be marked dirty, for example because
  /// you are in the middle of layout and you are not going to be flushing the
  /// build queue (since that could mutate the layout tree).
  static void lockState(void callback()) {
    _debugStateLockLevel += 1;
    try {
      callback();
    } finally {
      _debugStateLockLevel -= 1;
    }
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and components should be structured so as to only mark
  /// components dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    assert(!_debugStateLocked);
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    if (_dirty)
      return;
    _dirty = true;
    assert(scheduleBuildFor != null);
    scheduleBuildFor(this);
  }

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void unmount() {
    super.unmount();
    _dirty = false; // so that we don't get rebuilt even if we're already marked dirty
  }

  void dependenciesChanged() {
    markNeedsBuild();
  }
}

/// Instantiation of StatelessComponent widgets.
class StatelessComponentElement<T extends StatelessComponent> extends BuildableElement<T> {
  StatelessComponentElement(StatelessComponent widget) : super(widget) {
    _builder = widget.build;
  }

  void update(StatelessComponent newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _builder = widget.build;
    _dirty = true;
    rebuild();
  }
}

/// Instantiation of StatefulComponent widgets.
class StatefulComponentElement extends BuildableElement<StatefulComponent> {
  StatefulComponentElement(StatefulComponent widget)
    : _state = widget.createState(), super(widget) {
    assert(_state._element == null);
    _state._element = this;
    assert(_state._config == null);
    _state._config = widget;
    assert(_state._debugLifecycleState == _StateLifecycle.created);
    _state.initState(this);
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.initialized)
        return true;
      print('${_state.runtimeType}.initState failed to call super.initState');
      return false;
    });
    assert(() { _state._debugLifecycleState = _StateLifecycle.ready; return true; });
    assert(_builder == null);
    // see State.setState() for why it's important that _builder be set after
    // initState() is called.
    _builder = _state.build;
  }

  State get state => _state;
  State _state;

  void update(StatefulComponent newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    StatefulComponent oldConfig = _state._config;
    _state._config = widget;
    _state.didUpdateConfig(oldConfig);
    _dirty = true;
    rebuild();
  }

  void unmount() {
    super.unmount();
    _state.dispose();
    assert(_state._debugLifecycleState == _StateLifecycle.defunct);
    _state._element = null;
    _state = null;
  }
}

class ParentDataElement extends StatelessComponentElement<ParentDataWidget> {
  ParentDataElement(ParentDataWidget widget) : super(widget);

  void mount(Element parent, dynamic slot) {
    assert(() {
      Element ancestor = parent;
      while (ancestor is! RenderObjectElement) {
        assert(ancestor != null);
        assert(() {
          'You cannot nest parent data widgets inside one another.';
          return ancestor is! ParentDataElement;
        });
        ancestor = ancestor._parent;
      }
      _widget.debugValidateAncestor(ancestor._widget);
      return true;
    });
    super.mount(parent, slot);
  }

  void update(ParentDataWidget newWidget) {
    ParentDataWidget oldWidget = widget;
    super.update(newWidget);
    assert(widget == newWidget);
    if (widget != oldWidget)
      _notifyDescendants();
  }

  void _notifyDescendants() {
    void notifyChildren(Element child) {
      if (child is RenderObjectElement)
        child.updateParentData(widget);
      else if (child is! ParentDataElement)
        child.visitChildren(notifyChildren);
    }
    visitChildren(notifyChildren);
  }
}

class InheritedElement extends StatelessComponentElement<InheritedWidget> {
  InheritedElement(InheritedWidget widget) : super(widget);

  void update(StatelessComponent newWidget) {
    InheritedWidget oldWidget = widget;
    super.update(newWidget);
    assert(widget == newWidget);
    if (widget.updateShouldNotify(oldWidget))
      _notifyDescendants();
  }

  void _notifyDescendants() {
    final Type ourRuntimeType = runtimeType;
    void notifyChildren(Element child) {
      if (child._dependencies != null &&
          child._dependencies.contains(ourRuntimeType))
        child.dependenciesChanged();
      if (child.runtimeType != ourRuntimeType)
        child.visitChildren(notifyChildren);
    }
    visitChildren(notifyChildren);
  }
}

/// Base class for instantiations of RenderObjectWidget subclasses
abstract class RenderObjectElement<T extends RenderObjectWidget> extends Element<T> {
  RenderObjectElement(T widget)
    : _renderObject = widget.createRenderObject(), super(widget);

  /// The underlying [RenderObject] for this element
  RenderObject get renderObject => _renderObject;
  final RenderObject _renderObject;

  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  ParentDataElement _findAncestorParentDataElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement)
        return ancestor;
      ancestor = ancestor._parent;
    }
    return null;
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_ancestorRenderObjectElement == null);
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(renderObject, newSlot);
    ParentDataElement parentDataElement = _findAncestorParentDataElement();
    if (parentDataElement != null)
      updateParentData(parentDataElement.widget);
  }

  void update(T newWidget) {
    T oldWidget = widget;
    super.update(newWidget);
    assert(widget == newWidget);
    widget.updateRenderObject(renderObject, oldWidget);
  }

  /// Utility function for subclasses that have one or more lists of children.
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  List<Element> updateChildren(List<Element> oldChildren, List<Widget> newWidgets) {
    assert(oldChildren != null);
    assert(newWidgets != null);

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
    // 1. Walk the lists from the top until you no longer have
    //    matching nodes. We don't sync these yet, but we now know to
    //    skip them below. We do this because at each sync we need to
    //    pass the pointer to the new next widget as the slot, which
    //    we can't do until we've synced the next child.
    // 2. Walk the lists from the bottom, syncing nodes, until you no
    //    longer have matching nodes.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list backwards:
    //     * Sync unkeyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the top list again but backwards, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    final ContainerRenderObjectMixin renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);

    int childrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    // top of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[childrenTop];
      Widget newWidget = newWidgets[childrenTop];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.mounted);
      if (!_canUpdate(oldChild.widget, newWidget))
        break;
      childrenTop += 1;
    }

    List<Element> newChildren = oldChildren.length == newWidgets.length ?
        oldChildren : new List<Element>(newWidgets.length);

    Element nextSibling;

    // bottom of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[oldChildrenBottom];
      Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.mounted);
      if (!_canUpdate(oldChild.widget, newWidget))
        break;
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.mounted);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // middle of the lists - old list
    bool haveOldNodes = childrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldNodes) {
      oldKeyedChildren = new Map<Key, Element>();
      while (childrenTop <= oldChildrenBottom) {
        Element oldChild = oldChildren[oldChildrenBottom];
        assert(oldChild._debugLifecycleState == _ElementLifecycle.mounted);
        if (oldChild.widget.key != null)
          oldKeyedChildren[oldChild.widget.key] = oldChild;
        else
          _detachChild(oldChild);
        oldChildrenBottom -= 1;
      }
    }

    // middle of the lists - new list
    while (childrenTop <= newChildrenBottom) {
      Element oldChild;
      Widget newWidget = newWidgets[newChildrenBottom];
      if (haveOldNodes) {
        Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[newWidget.key];
          if (oldChild != null) {
            if (_canUpdate(oldChild.widget, newWidget)) {
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
      assert(oldChild == null || _canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.mounted);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.mounted);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      newChildrenBottom -= 1;
    }
    assert(oldChildrenBottom == newChildrenBottom);
    assert(childrenTop == newChildrenBottom + 1);

    // now sync the top of the list
    while (childrenTop > 0) {
      childrenTop -= 1;
      Element oldChild = oldChildren[childrenTop];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.mounted);
      Widget newWidget = newWidgets[childrenTop];
      assert(_canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.mounted);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.mounted);
      newChildren[childrenTop] = newChild;
      nextSibling = newChild;
    }

    // clean up any of the remaining middle nodes from the old list
    if (haveOldNodes && !oldKeyedChildren.isEmpty) {
      for (Element oldChild in oldKeyedChildren.values)
        _detachChild(oldChild);
    }

    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
    return newChildren;
  }

  void unmount() {
    super.unmount();
    assert(!renderObject.attached);
    widget.didUnmountRenderObject(renderObject);
  }

  void updateParentData(ParentDataWidget parentData) {
    parentData.applyParentData(renderObject);
  }

  void _updateSlot(dynamic newSlot) {
    assert(slot != newSlot);
    super._updateSlot(newSlot);
    assert(slot == newSlot);
    _ancestorRenderObjectElement.moveChildRenderObject(renderObject, slot);
  }

  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
  }

  void insertChildRenderObject(RenderObject child, dynamic slot);
  void moveChildRenderObject(RenderObject child, dynamic slot);
  void removeChildRenderObject(RenderObject child);
}

/// Instantiation of RenderObjectWidgets that have no children
class LeafRenderObjectElement<T extends RenderObjectWidget> extends RenderObjectElement<T> {
  LeafRenderObjectElement(T widget): super(widget);

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }
}

/// Instantiation of RenderObjectWidgets that have up to one child
class OneChildRenderObjectElement<T extends OneChildRenderObjectWidget> extends RenderObjectElement<T> {
  OneChildRenderObjectElement(T widget) : super(widget);

  Element _child;

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }
}

/// Instantiation of RenderObjectWidgets that can have a list of children
class MultiChildRenderObjectElement<T extends MultiChildRenderObjectWidget> extends RenderObjectElement<T> {
  MultiChildRenderObjectElement(T widget) : super(widget) {
    assert(!_debugHasDuplicateIds());
  }

  List<Element> _children;

  void insertChildRenderObject(RenderObject child, Element slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    RenderObject nextSibling = slot?.renderObject;
    assert(renderObject is ContainerRenderObjectMixin);
    renderObject.add(child, before: nextSibling);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    RenderObject nextSibling = slot?.renderObject;
    assert(renderObject is ContainerRenderObjectMixin);
    renderObject.move(child, before: nextSibling);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChildRenderObject(RenderObject child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  bool _debugHasDuplicateIds() {
    var idSet = new HashSet<Key>();
    for (Widget child in widget.children) {
      assert(child != null);
      if (child.key == null)
        continue; // when these nodes are reordered, we just reassign the data

      if (!idSet.add(child.key)) {
        throw 'If multiple keyed nodes exist as children of another node, they must have unique keys. $widget has multiple children with key "${child.key}".';
      }
    }
    return false;
  }

  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new List<Element>(widget.children.length);
    Element previousChild;
    for (int i = _children.length - 1; i >= 0; --i) {
      Element newChild = widget.children[i].createElement();
      newChild.mount(this, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.mounted);
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _children = updateChildren(_children, widget.children);
  }
}

typedef void WidgetsExceptionHandler(String context, dynamic exception, StackTrace stack);
/// This callback is invoked whenever an exception is caught by the widget
/// system. The 'context' argument is a description of what was happening when
/// the exception occurred, and may include additional details such as
/// descriptions of the objects involved. The 'exception' argument contains the
/// object that was thrown, and the 'stack' argument contains the stack trace.
/// If no callback is set, then a default behaviour consisting of dumping the
/// context, exception, and stack trace to the console is used instead.
WidgetsExceptionHandler debugWidgetsExceptionHandler;
void _debugReportException(String context, dynamic exception, StackTrace stack) {
  if (debugWidgetsExceptionHandler != null) {
    debugWidgetsExceptionHandler(context, exception, stack);
  } else {
    print('------------------------------------------------------------------------');
    'Exception caught while $context'.split('\n').forEach(print);
    print('$exception');
    print('Stack trace:');
    '$stack'.split('\n').forEach(print);
    print('------------------------------------------------------------------------');
  }
}
