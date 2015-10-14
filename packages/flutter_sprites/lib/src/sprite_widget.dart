part of flutter_sprites;

/// A widget that uses a [SpriteBox] to render a sprite node tree to the screen.
class SpriteWidget extends OneChildRenderObjectWidget {

  /// The rootNode of the sprite node tree.
  ///
  ///     var node = mySpriteWidget.rootNode;
  final NodeWithSize rootNode;

  /// The transform mode used to fit the sprite node tree to the size of the widget.
  final SpriteBoxTransformMode transformMode;

  /// Creates a new sprite widget with [rootNode] as its content.
  ///
  /// The widget will setup the coordinate space for the sprite node tree using the size of the [rootNode] in
  /// combination with the supplied [transformMode]. By default the letterbox transform mode is used. See
  /// [SpriteBoxTransformMode] for more details on the different modes.
  ///
  /// The most common way to setup the sprite node graph is to subclass [NodeWithSize] and pass it to the sprite widget.
  /// In the custom subclass it's possible to build the node graph, do animations and handle user events.
  ///
  ///     var mySpriteTree = new MyCustomNodeWithSize();
  ///     var mySpriteWidget = new SpriteWidget(mySpriteTree, SpriteBoxTransformMode.fixedHeight);
  SpriteWidget(this.rootNode, [this.transformMode = SpriteBoxTransformMode.letterbox]);

  SpriteBox createRenderObject() => new SpriteBox(rootNode, transformMode);

  void updateRenderObject(SpriteBox renderObject, SpriteWidget oldWidget) {
    renderObject.rootNode = rootNode;
    renderObject.transformMode = transformMode;
  }
}
