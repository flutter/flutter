part of fn;

List<Component> _dirtyComponents = new List<Component>();
bool _renderScheduled = false;

void _renderDirtyComponents() {
  Stopwatch sw = new Stopwatch()..start();

  _dirtyComponents.sort((a, b) => a._order - b._order);
  for (var comp in _dirtyComponents) {
    comp._renderIfDirty();
  }

  _dirtyComponents.clear();
  _renderScheduled = false;
  sw.stop();
  print("Render took ${sw.elapsedMicroseconds} microseconds");
}

void _scheduleComponentForRender(Component c) {
  _dirtyComponents.add(c);

  if (!_renderScheduled) {
    _renderScheduled = true;
    new Future.microtask(_renderDirtyComponents);
  }
}

abstract class Component extends Node {
  bool _dirty = true; // components begin dirty because they haven't rendered.
  Node _rendered = null;
  bool _removed = false;
  int _order;
  static int _currentOrder = 0;
  bool _stateful;
  static Component _currentlyRendering;

  Component({ Object key, bool stateful })
      : _stateful = stateful != null ? stateful : false,
        _order = _currentOrder + 1,
        super(key:key);

  void willUnmount() {}

  void _remove() {
    assert(_rendered != null);
    assert(_root != null);
    willUnmount();
    _rendered._remove();
    _rendered = null;
    _root = null;
    _removed = true;
  }

  // TODO(rafaelw): It seems wrong to expose DOM at all. This is presently
  // needed to get sizing info.
  sky.Node getRoot() => _root;

  bool _sync(Node old, sky.Node host, sky.Node insertBefore) {
    Component oldComponent = old as Component;

    if (oldComponent == null || oldComponent == this) {
      _renderInternal(host, insertBefore);
      return false;
    }

    assert(oldComponent != null);
    assert(_dirty);
    assert(_rendered == null);

    if (oldComponent._stateful) {
      _stateful = false; // prevent iloop from _renderInternal below.

      reflect.copyPublicFields(this, oldComponent);

      oldComponent._dirty = true;
      _dirty = false;

      oldComponent._renderInternal(host, insertBefore);
      return true;  // Must retain old component
    }

    _rendered = oldComponent._rendered;
    _renderInternal(host, insertBefore);
    return false;
  }

  void _renderInternal(sky.Node host, sky.Node insertBefore) {
    if (!_dirty) {
      assert(_rendered != null);
      return;
    }

    var oldRendered = _rendered;
    int lastOrder = _currentOrder;
    _currentOrder = _order;
    _currentlyRendering = this;
    _rendered = render();
    _currentlyRendering = null;
    _currentOrder = lastOrder;

    _dirty = false;

    // TODO(rafaelw): This prevents components from returning different node
    // types as their root node at different times. Consider relaxing.
    assert(oldRendered == null ||
           _rendered.runtimeType == oldRendered.runtimeType);

    if (_rendered._sync(oldRendered, host, insertBefore)) {
      _rendered = oldRendered; // retain stateful component
    }
    _root = _rendered._root;
    assert(_rendered._root is sky.Node);
  }

  void _renderIfDirty() {
    assert(_rendered != null);
    assert(!_removed);

    var rendered = _rendered;
    while (rendered is Component) {
      rendered = rendered._rendered;
    }
    sky.Node root = rendered._root;

    _renderInternal(root.parentNode, root.nextSibling);
  }

  void setState(Function fn()) {
    assert(_rendered != null); // cannot setState before mounting.
    _stateful = true;
    fn();
    if (_currentlyRendering != this) {
      _dirty = true;
      _scheduleComponentForRender(this);
    }
  }

  Node render();
}

abstract class App extends Component {
  sky.Node _host = null;
  App()
    : super(stateful: true) {

    _host = sky.document.createElement('div');
    sky.document.appendChild(_host);

    new Future.microtask(() {
      Stopwatch sw = new Stopwatch()..start();
      _sync(null, _host, null);
      assert(_root is sky.Node);
      sw.stop();
      print("Initial render: ${sw.elapsedMicroseconds} microseconds");
    });
  }
}
