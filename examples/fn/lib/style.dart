part of fn;

class Style {
  final String _className;
  static Map<String, Style> _cache = null;

  static int nextStyleId = 1;

  static String nextClassName(String styles) {
    assert(sky.document != null);
    var className = "style$nextStyleId";
    nextStyleId++;

    var styleNode = sky.document.createElement('style');
    styleNode.setChild(new sky.Text(".$className { $styles }"));
    sky.document.appendChild(styleNode);

    return className;
  }

  factory Style(String styles) {
    if (_cache == null) {
      _cache = new HashMap<String, Style>();
    }

    var style = _cache[styles];
    if (style == null) {
      style = new Style._internal(nextClassName(styles));
      _cache[styles] = style;
    }

    return style;
  }

  Style._internal(this._className);
}
