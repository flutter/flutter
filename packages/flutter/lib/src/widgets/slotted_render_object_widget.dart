// ignore_for_file: public_member_api_docs

import 'framework.dart';

mixin SlottedMultiChildRenderObjectWidgetMixin<S> on RenderObjectWidget {

  @protected
  Iterable<S> get slots;

  @protected
  Widget? childForSlot(S slot);

  @override
  SlottedRenderObjectElement<S> createElement() => SlottedRenderObjectElement<S>(this);
}

class SlottedRenderObjectElement<S> extends RenderObjectElement {
  SlottedRenderObjectElement(SlottedMultiChildRenderObjectWidgetMixin<S> widget) : super(widget);

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
    assert(false, 'not reachable');
  }
}

mixin SlottedContainerRenderObjectMixin<S> on RenderBox {
  @protected
  RenderBox? childForSlot(S slot) {
    assert(_slotToChild.containsKey(slot));
    return _slotToChild[slot];
  }

  @protected

  final Map<S, RenderBox?> _slotToChild = <S, RenderBox?>{};

  void _setChild(RenderBox? child, S slot) {
    final RenderBox? oldChild = _slotToChild[slot];
    if (oldChild != null) {
      dropChild(oldChild);
      _slotToChild[slot] = null;
    }
    if (child != null) {
      _slotToChild[slot] = child;
      adoptChild(child);
    }
  }
}
