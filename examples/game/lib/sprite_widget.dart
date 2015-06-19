part of sprites;

class SpriteWidget extends OneChildRenderObjectWrapper {

  final NodeWithSize rootNode;
  final SpriteBoxTransformMode transformMode;

  SpriteWidget(this.rootNode, [this.transformMode = SpriteBoxTransformMode.letterbox]);

  SpriteBox get root => super.root;

  SpriteBox createNode() => new SpriteBox(rootNode, transformMode);

  void syncRenderObject(SpriteWidget old) {
    super.syncRenderObject(old);

    // SpriteBox doesn't allow mutation of these properties
    assert(rootNode == root.rootNode);
    assert(transformMode == root.transformMode);
  }
}