Built-In Elements
=================

```dart
SKY MODULE

<script>
import 'dart:sky';

class ImportElement extends Element {
  ImportElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

class TemplateElement extends Element {
  TemplateElement = Element;

  // TODO(ianh): convert <template> to using a token stream instead of a Fragment

  external Fragment get content; // O(1)

  @override
  Type getLayoutManager() => null; // O(1)
}

class ScriptElement extends Element {
  ScriptElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

class StyleElement extends Element {
  StyleElement = Element;

  external List<Rule> getRules(); // O(N) in rules

  @override
  Type getLayoutManager() => null; // O(1)
}

class ContentElement extends Element {
  ContentElement = Element;

  external List<Node> getDistributedNodes(); // O(N) in distributed nodes

  @override
  Type getLayoutManager() => null; // O(1)
}

class ImgElement extends Element {
  ImgElement = Element;

  @override
  Type getLayoutManager() => ImgElementLayoutManager; // O(1)
}

class DivElement extends Element {
  DivElement = Element;
}

class SpanElement extends Element {
  SpanElement = Element;
}

class IframeElement extends Element {
  IframeElement = Element;

  @override
  Type getLayoutManager() => IframeElementLayoutManager; // O(1)
}

class TElement extends Element {
  TElement = Element;
}

class AElement extends Element {
  AElement = Element;
}

class TitleElement extends Element {
  TitleElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

class _ErrorElement extends Element {
  _ErrorElement._create();

  @override
  Type getLayoutManager() => _ErrorElementLayoutManager; // O(1)
}

void _init(script) {
  module.registerElement('import', ImportElement);
  module.registerElement('template', TemplateElement);
  module.registerElement('script', ScriptElement);
  module.registerElement('style', StyleElement);
  module.registerElement('content', ContentElement);
  module.registerElement('img', ImgElement);
  module.registerElement('div', DivElement);
  module.registerElement('span', SpanElement);
  module.registerElement('iframe', IframeElement);
  module.registerElement('t', TElement);
  module.registerElement('a', AElement);
  module.registerElement('title', TitleElement);
}
</script>
```
