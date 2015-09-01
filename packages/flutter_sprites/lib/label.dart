part of skysprites;

class Label extends Node {

  Label(this._text, [this._textStyle]) {
    if (_textStyle == null) {
      _textStyle = new TextStyle();
    }
  }

  String _text;

  String get text => _text;

  set text(String text) {
    _text = text;
    _painter = null;
  }

  TextStyle _textStyle;

  TextStyle get textStyle => _textStyle;

  set textStyle(TextStyle textStyle) {
    _textStyle = textStyle;
    _painter = null;
  }

  TextPainter _painter;
  double _width;

  final double _maxWidth = 10000.0;

  void paint(PaintingCanvas canvas) {
    if (_painter == null) {
      PlainTextSpan textSpan = new PlainTextSpan(_text);
      StyledTextSpan styledTextSpan = new StyledTextSpan(_textStyle, [textSpan]);
      _painter = new TextPainter(styledTextSpan);

      _painter.maxWidth = _maxWidth;
      _painter.minWidth = _maxWidth;
      _painter.layout();

      _width = _painter.maxContentWidth;
    }

    Offset offset = Offset.zero;
    if (_textStyle.textAlign == TextAlign.center) {
      //canvas.translate(-_maxWidth / 2.0, 0.0);
      offset = new Offset(-_maxWidth / 2.0, 0.0);
    } else if (_textStyle.textAlign == TextAlign.right) {
      //canvas.translate(-_maxWidth, 0.0);
      offset = new Offset(-_maxWidth, 0.0);
    }

    _painter.paint(canvas, offset);
  }
}
