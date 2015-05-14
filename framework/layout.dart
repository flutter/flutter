library layout;

import 'node.dart';
import 'dart:sky' as sky;
import 'dart:collection';

// UTILS

// Bridge to legacy CSS-like style specification
// Eventually we'll replace this with something else
class Style {
  final String _className;
  static final Map<String, Style> _cache = new HashMap<String, Style>();

  static int _nextStyleId = 1;

  static String _getNextClassName() { return "style${_nextStyleId++}"; }

  Style extend(Style other) {
    var className = "$_className ${other._className}";

    return _cache.putIfAbsent(className, () {
      return new Style._internal(className);
    });
  }

  factory Style(String styles) {
    return _cache.putIfAbsent(styles, () {
      var className = _getNextClassName();
      sky.Element styleNode = sky.document.createElement('style');
      styleNode.setChild(new sky.Text(".$className { $styles }"));
      sky.document.appendChild(styleNode);
      return new Style._internal(className);
    });
  }

  Style._internal(this._className);
}

class Rect {
  const Rect(this.x, this.y, this.width, this.height);
  final double x;
  final double y;
  final double width;
  final double height;
}


// ABSTRACT LAYOUT

class ParentData {
  void detach() {
    detachSiblings();
  }
  void detachSiblings() { } // workaround for lack of inter-class mixins in Dart
  void merge(ParentData other) {
    // override this in subclasses to merge in data from other into this
    assert(other.runtimeType == this.runtimeType);
  }
}

abstract class RenderNode extends Node {

  // LAYOUT

  // parentData is only for use by the RenderNode that actually lays this
  // node out, and any other nodes who happen to know exactly what
  // kind of node that is.
  ParentData parentData;
  void setupPos(RenderNode child) {
    // override this to setup .parentData correctly for your class
    if (child.parentData is! ParentData)
      child.parentData = new ParentData();
  }

  void setAsChild(RenderNode child) { // only for use by subclasses
    // call this whenever you decide a node is a child
    assert(child != null);
    setupPos(child);
    super.setAsChild(child);
  }
  void dropChild(RenderNode child) { // only for use by subclasses
    assert(child != null);
    assert(child.parentData != null);
    child.parentData.detach();
    super.dropChild(child);
  }

}

abstract class RenderBox extends RenderNode { }


// GENERIC MIXIN FOR RENDER NODES THAT TAKE A LIST OF CHILDREN

abstract class ContainerParentDataMixin<ChildType extends RenderNode> {
  ChildType previousSibling;
  ChildType nextSibling;
  void detachSiblings() {
    if (previousSibling != null) {
      assert(previousSibling.parentData is ContainerParentDataMixin<ChildType>);
      assert(previousSibling != this);
      assert(previousSibling.parentData.nextSibling == this);
      previousSibling.parentData.nextSibling = nextSibling;
    }
    if (nextSibling != null) {
      assert(nextSibling.parentData is ContainerParentDataMixin<ChildType>);
      assert(nextSibling != this);
      assert(nextSibling.parentData.previousSibling == this);
      nextSibling.parentData.previousSibling = previousSibling;
    }
    previousSibling = null;
    nextSibling = null;
  }
}

abstract class ContainerRenderNodeMixin<ChildType extends RenderNode, ParentDataType extends ContainerParentDataMixin<ChildType>> implements RenderNode {
  // abstract class that has only InlineNode children

  bool _debugUltimatePreviousSiblingOf(ChildType child, { ChildType equals }) {
    assert(child.parentData is ParentDataType);
    while (child.parentData.previousSibling != null) {
      assert(child.parentData.previousSibling != child);
      child = child.parentData.previousSibling;
      assert(child.parentData is ParentDataType);
    }
    return child == equals;
  }
  bool _debugUltimateNextSiblingOf(ChildType child, { ChildType equals }) {
    assert(child.parentData is ParentDataType);
    while (child.parentData.nextSibling != null) {
      assert(child.parentData.nextSibling != child);
      child = child.parentData.nextSibling;
      assert(child.parentData is ParentDataType);
    }
    return child == equals;
  }

  ChildType _firstChild;
  ChildType _lastChild;
  void add(ChildType child, { ChildType before }) {
    assert(child != this);
    assert(before != this);
    assert(child != before);
    assert(child != _firstChild);
    assert(child != _lastChild);
    setAsChild(child);
    assert(child.parentData is ParentDataType);
    assert(child.parentData.nextSibling == null);
    assert(child.parentData.previousSibling == null);
    if (before == null) {
      // append at the end (_lastChild)
      child.parentData.previousSibling = _lastChild;
      if (_lastChild != null) {
        assert(_lastChild.parentData is ParentDataType);
        _lastChild.parentData.nextSibling = child;
      }
      _lastChild = child;
      if (_firstChild == null)
        _firstChild = child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(before, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(before, equals: _lastChild));
      assert(before.parentData is ParentDataType);
      if (before.parentData.previousSibling == null) {
        // insert at the start (_firstChild); we'll end up with two or more children
        assert(before == _firstChild);
        child.parentData.nextSibling = before;
        before.parentData.previousSibling = child;
        _firstChild = child;
      } else {
        // insert in the middle; we'll end up with three or more children
        // set up links from child to siblings
        child.parentData.previousSibling = before.parentData.previousSibling;
        child.parentData.nextSibling = before;
        // set up links from siblings to child
        assert(child.parentData.previousSibling.parentData is ParentDataType);
        assert(child.parentData.nextSibling.parentData is ParentDataType);
        child.parentData.previousSibling.parentData.nextSibling = child;
        child.parentData.nextSibling.parentData.previousSibling = child;
        assert(before.parentData.previousSibling == child);
      }
    }
    markNeedsLayout();
  }
  void remove(ChildType child) {
    assert(child.parentData is ParentDataType);
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    if (child.parentData.previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child.parentData.nextSibling;
    } else {
      assert(child.parentData.previousSibling.parentData is ParentDataType);
      child.parentData.previousSibling.parentData.nextSibling = child.parentData.nextSibling;
    }
    if (child.parentData.nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = child.parentData.previousSibling;
    } else {
      assert(child.parentData.nextSibling.parentData is ParentDataType);
      child.parentData.nextSibling.parentData.previousSibling = child.parentData.previousSibling;
    }
    child.parentData.previousSibling = null;
    child.parentData.nextSibling = null;
    dropChild(child);
    markNeedsLayout();
  }
  void redepthChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      redepthChild(child);
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }
  void attachChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      child.attach();
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }
  void detachChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      child.detach();
      assert(child.parentData is ParentDataType);
      child = child.parentData.nextSibling;
    }
  }

  ChildType get firstChild => _firstChild;
  ChildType get lastChild => _lastChild;
  ChildType childAfter(ChildType child) {
    assert(child.parentData is ParentDataType);
    return child.parentData.nextSibling;
  }

}


// CSS SHIMS

abstract class RenderCSS extends RenderBox {

  dynamic debug;
  sky.Element _skyElement;

  RenderCSS(this.debug) {
    _skyElement = createSkyElement();
    registerEventTarget(_skyElement, this);
  }

  sky.Element createSkyElement();

  void updateStyles(List<Style> styles) {
    _skyElement.setAttribute('class', stylesToClasses(styles));
  }

  String stylesToClasses(List<Style> styles) {
    return styles.map((s) => s._className).join(' ');
  }

  String _inlineStyles = '';
  String _additionalStylesFromParent = ''; // used internally to propagate parentData settings to the child

  void updateInlineStyle(String newStyle) {
    _inlineStyles = newStyle != null ? newStyle : '';
    _updateInlineStyleAttribute();
  }

  void _updateInlineStyleAttribute() {
    if ((_inlineStyles != '') && (_additionalStylesFromParent != ''))
      _skyElement.setAttribute('style', "$_inlineStyles;$_additionalStylesFromParent");
    else
      _skyElement.setAttribute('style', "$_inlineStyles$_additionalStylesFromParent");
  }

  double get width {
    sky.ClientRect rect = _skyElement.getBoundingClientRect();
    return rect.width;
  }

  double get height {
    sky.ClientRect rect = _skyElement.getBoundingClientRect();
    return rect.height;
  }

  Rect get rect {
    sky.ClientRect rect = _skyElement.getBoundingClientRect();
    return new Rect(rect.left, rect.top, rect.width, rect.height);
  }

}

class CSSParentData extends ParentData with ContainerParentDataMixin<RenderCSS> { }

class RenderCSSContainer extends RenderCSS with ContainerRenderNodeMixin<RenderCSS, CSSParentData> {

  RenderCSSContainer(debug) : super(debug);

  void setupPos(RenderNode child) {
    if (child.parentData is! CSSParentData)
      child.parentData = new CSSParentData();
  }

  sky.Element createSkyElement() => sky.document.createElement('div')
                                               ..setAttribute('debug', debug.toString());

  void markNeedsLayout() { }

  void add(RenderCSS child, { RenderCSS before }) {
    if (before != null) {
      assert(before._skyElement.parentNode != null);
      assert(before._skyElement.parentNode == _skyElement);
    }
    super.add(child, before: before);
    if (before != null) {
      before._skyElement.insertBefore([child._skyElement]);
      assert(child._skyElement.parentNode != null);
      assert(child._skyElement.parentNode == _skyElement);
      assert(child._skyElement.parentNode == before._skyElement.parentNode);
    } else {
      _skyElement.appendChild(child._skyElement);
    }    
  }
  void remove(RenderCSS child) {
    child._skyElement.remove();
    super.remove(child);
  }

}

class FlexBoxParentData extends CSSParentData {
  int flex;
  void merge(FlexBoxParentData other) {
    if (other.flex != null)
      flex = other.flex;
    super.merge(other);
  }
}

enum FlexDirection { Row, Column }

class RenderCSSFlex extends RenderCSSContainer {

  RenderCSSFlex(debug, FlexDirection direction) : _direction = direction, super(debug);

  FlexDirection _direction;
  FlexDirection get direction => _direction;
  void set direction (FlexDirection value) {
    _direction = value;
    markNeedsLayout();
  }

  void setupPos(RenderNode child) {
    if (child.parentData is! FlexBoxParentData)
      child.parentData = new FlexBoxParentData();
  }

  static final Style _displayFlex = new Style('display:flex');
  static final Style _displayFlexRow = new Style('flex-direction:row');
  static final Style _displayFlexColumn = new Style('flex-direction:column');

  String stylesToClasses(List<Style> styles) {
    var settings = _displayFlex._className;
    switch (_direction) {
      case FlexDirection.Row: settings += ' ' + _displayFlexRow._className; break;
      case FlexDirection.Column: settings += ' ' + _displayFlexColumn._className; break;
    }
    return super.stylesToClasses(styles) + ' ' + settings;
  }

  void markNeedsLayout() {
    super.markNeedsLayout();

    // pretend we did the layout:
    RenderCSS child = _firstChild;
    while (child != null) {
      assert(child.parentData is FlexBoxParentData);
      if (child.parentData.flex != null) {
        child._additionalStylesFromParent = 'flex:${child.parentData.flex}';
        child._updateInlineStyleAttribute();
      }
      child = child.parentData.nextSibling;
    }
  }

}

class RenderCSSText extends RenderCSS {

  RenderCSSText(debug, String newData) : super(debug) {
    data = newData;
  }

  static final Style _displayParagraph = new Style('display:paragraph');

  String stylesToClasses(List<Style> styles) {
    return super.stylesToClasses(styles) + ' ' + _displayParagraph._className;
  }

  sky.Element createSkyElement() {
    return sky.document.createElement('div')
                      ..setChild(new sky.Text())
                      ..setAttribute('debug', debug.toString());
  }

  void set data (String value) {
    (_skyElement.firstChild as sky.Text).data = value;
  }

}

class RenderCSSImage extends RenderCSS {

  RenderCSSImage(debug, String src, num width, num height) : super(debug) {
    configure(src, width, height);
  }

  sky.Element createSkyElement() {
    return sky.document.createElement('img')
                      ..setAttribute('debug', debug.toString());
  }

  void configure(String src, num width, num height) {
    if (_skyElement.getAttribute('src') != src)
      _skyElement.setAttribute('src', src);
    _skyElement.style['width'] = '${width}px';
    _skyElement.style['height'] = '${height}px';
  }

}

class RenderCSSRoot extends RenderCSSContainer {
  RenderCSSRoot(debug) : super(debug);
  sky.Element createSkyElement() {
    var result = super.createSkyElement();
    assert(result != null);
    sky.document.appendChild(result);
    return result;
  }
}


// legacy tools
Map<sky.EventTarget, RenderNode> _eventTargetRegistry = {};
void registerEventTarget(sky.EventTarget e, RenderNode n) {
  _eventTargetRegistry[e] = n;
}
RenderNode bridgeEventTargetToRenderNode(sky.EventTarget e) {
  return _eventTargetRegistry[e];
}




String _attributes(node) {
  if (node is! sky.Element) return '';
  var result = '';
  var attrs = node.getAttributes();
  for (var attr in attrs)
    result += ' ${attr.name}="${attr.value}"';
  return result;
}

void _serialiseDOM(node, [String prefix = '']) {
  if (node is sky.Text) {
    print(prefix + 'text: "' + node.data.replaceAll('\n', '\\n') + '"');
    return;
  }
  print(prefix + node.toString() + _attributes(node));
  var children = node.getChildNodes();
  prefix = prefix + '  ';
  for (var child in children)
    _serialiseDOM(child, prefix);
}

void dumpState() {
  _serialiseDOM(sky.document);
}
