import 'framework.dart';

/// A mixin for a [RenderObjectWidget] that configures a [RenderObject]
/// subclass, which organizes its children in different slots.
///
/// Implementors of this mixin have to provide the list of available slots by
/// overriding [slots]. The list of slots must never change for a given class
/// implementing this mixin. In the common case, [Enum] values are used as slots
/// and [slots] is typically implemented to return the value of the enum's
/// `values` getter.
///
/// Furthermore, [childForSlot] must be implemented to return the current
/// widget configuration for a given slot.
///
/// The [RenderObject] returned by [createRenderObject] and updated by
/// [updateRenderObject] must implement the [SlottedContainerRenderObjectMixin].
///
/// The type parameter `S` is the type for the slots to be used by this
/// [RenderObjectWidget] and the [RenderObject] it configures. In the typical
/// case, `S` is an [Enum] type.
mixin SlottedMultiChildRenderObjectWidgetMixin<S> on RenderObjectWidget {
  /// Returns a list of all available slots.
  ///
  /// The list of slots must be static and must never change for a given class
  /// implementing this mixin.
  ///
  /// Typically, an [Enum] is used to identify the different slots. In that case
  /// this getter can be implemented by returning what the `value` getter
  /// of the enum used returns.
  @protected
  Iterable<S> get slots;

  /// Returns the widget that is currently occupying the provided `slot`.
  ///
  /// The [RenderObject] configured by this class will be configured to have
  /// the [RenderObject] produced by the returned [Widget] in the provided
  /// `slot`.
  @protected
  Widget? childForSlot(S slot);

  @override
  SlottedContainerRenderObjectMixin<S> createRenderObject(BuildContext context);

  @override
  void updateRenderObject(BuildContext context, SlottedContainerRenderObjectMixin<S> renderObject);

  @override
  RenderObjectElement createElement() => _SlottedRenderObjectElement<S>(this);
}

/// Mixin for a [RenderBox] configured by a [SlottedMultiChildRenderObjectWidgetMixin].
///
/// The [RenderBox] child currently occupying a given slot can be obtained by
/// calling [childForSlot]. A list of all non-null child [RenderBox]es is
/// available via the [children] getter.
///
/// The type parameter `S` is the type for the slots to be used by this
/// [RenderObject] and the [SlottedMultiChildRenderObjectWidgetMixin] it was
/// configured by. In the typical case, `S` is an [Enum] type.
mixin SlottedContainerRenderObjectMixin<S> on RenderBox {
  /// Returns the [RenderBox] child that it currently occupying the provided
  /// `slot`.
  ///
  /// Returns null if no [RenderBox] is configured for the given slot.
  @protected
  RenderBox? childForSlot(S slot) => _slotToChild[slot];

  /// Returns all non-null [RenderBox] children of this render object.
  ///
  /// The order in which the children are returned is not guaranteed and no
  /// assumption should be made about the order.
  ///
  /// See also:
  ///
  ///  * [childForSlot] to obtain the child occupying a given slot.
  @protected
  Iterable<RenderBox> get children => _slotToChild.values.where((RenderBox? child) => child != null).cast<RenderBox>();

  final Map<S, RenderBox?> _slotToChild = <S, RenderBox?>{};

  void _setChild(RenderBox? child, S slot) {
    final RenderBox? oldChild = _slotToChild[slot];
    if (oldChild != null) {
      dropChild(oldChild);
      _slotToChild.remove(slot);
    }
    if (child != null) {
      _slotToChild[slot] = child;
      adoptChild(child);
    }
  }
}

class _SlottedRenderObjectElement<S> extends RenderObjectElement {
  _SlottedRenderObjectElement(SlottedMultiChildRenderObjectWidgetMixin<S> widget) : super(widget);

  final Map<S, Element> _slotToChild = <S, Element>{};

  @override
  SlottedMultiChildRenderObjectWidgetMixin<S> get widget => super.widget as SlottedMultiChildRenderObjectWidgetMixin<S>;

  @override
  SlottedContainerRenderObjectMixin<S> get renderObject => super.renderObject as SlottedContainerRenderObjectMixin<S>;

  @override
  void visitChildren(ElementVisitor visitor) {
    _slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(_slotToChild.containsValue(child));
    assert(child.slot is S);
    assert(_slotToChild.containsKey(child.slot));
    _slotToChild.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _updateChildren();
  }

  @override
  void update(SlottedMultiChildRenderObjectWidgetMixin<S> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChildren();
  }

  void _updateChildren() {
    for (final S slot in widget.slots) {
      _updateChild(widget.childForSlot(slot), slot);
    }
  }

  void _updateChild(Widget? widget, S slot) {
    final Element? oldChild = _slotToChild[slot];
    final Element? newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      _slotToChild.remove(slot);
    }
    if (newChild != null) {
      _slotToChild[slot] = newChild;
    }
  }

  @override
  void insertRenderObjectChild(RenderBox child, S slot) {
    renderObject._setChild(child, slot);
    assert(renderObject._slotToChild[slot] == child);
  }

  @override
  void removeRenderObjectChild(RenderBox child, S slot) {
    assert(renderObject._slotToChild[slot] == child);
    renderObject._setChild(null, slot);
    assert(renderObject._slotToChild[slot] == null);
  }

  @override
  void moveRenderObjectChild(RenderBox child, Object? oldSlot, Object? newSlot) {
    // TODO(goderbauer): Figure out if we should support this. It is probably doable.
    assert(false, 'Moving render objects is not supported by the SlottedContainerRenderObjectMixin.');
  }
}
