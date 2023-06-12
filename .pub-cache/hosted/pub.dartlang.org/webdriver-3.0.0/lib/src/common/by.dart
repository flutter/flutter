class By {
  final String using;
  final String value;

  const By(this.using, this.value);

  /// Returns an element whose ID attribute matches the search value.
  const By.id(String id) : this('id', id);

  /// Returns an element matching an XPath expression.
  const By.xpath(String xpath) : this('xpath', xpath);

  /// Returns an anchor element whose visible text matches the search value.
  const By.linkText(String linkText) : this('link text', linkText);

  /// Returns an anchor element whose visible text partially matches the search
  /// value.
  const By.partialLinkText(String partialLinkText)
      : this('partial link text', partialLinkText);

  /// Returns an element whose NAME attribute matches the search value.
  const By.name(String name) : this('name', name);

  /// Returns an element whose tag name matches the search value.
  const By.tagName(String tagName) : this('tag name', tagName);

  /// Returns an element whose class name contains the search value; compound
  /// class names are not permitted
  const By.className(String className) : this('class name', className);

  /// Returns an element matching a CSS selector.
  const By.cssSelector(String cssSelector) : this('css selector', cssSelector);

  Map<String, String> toJson() => {'using': using, 'value': value};

  @override
  String toString() {
    var constructor = using;
    switch (using) {
      case 'link text':
        constructor = 'linkText';
        break;
      case 'partial link text':
        constructor = 'partialLinkText';
        break;
      case 'tag name':
        constructor = 'tagName';
        break;
      case 'class name':
        constructor = 'className';
        break;
      case 'css selector':
        constructor = 'cssSelector';
        break;
    }
    return 'By.$constructor($value)';
  }

  @override
  int get hashCode => using.hashCode * 3 + value.hashCode;

  @override
  bool operator ==(other) =>
      other is By && other.using == using && other.value == value;
}
