part of widgets;

abstract class FixedHeightScrollable extends Component {

  static Style _style = new Style('''
    overflow: hidden;
    position: relative;
    will-change: transform;'''
  );

  static Style _scrollAreaStyle = new Style('''
    position:relative;
    will-change: transform;'''
  );

  double itemHeight;
  double height;
  double minOffset;
  double maxOffset;

  double _scrollOffset = 0.0;
  FlingCurve _flingCurve;
  int _flingAnimationId;

  FixedHeightScrollable({
    Object key,
    this.itemHeight,
    this.height,
    this.minOffset,
    this.maxOffset
  }) : super(key: key) {}


  List<Node> renderItems(int start, int count);

  Node render() {
    int drawCount = (height / itemHeight).round() + 1;
    double alignmentDelta = -_scrollOffset % itemHeight;
    if (alignmentDelta != 0.0) {
      alignmentDelta -= itemHeight;
    }

    double drawStart = _scrollOffset + alignmentDelta;
    int itemNumber = (drawStart / itemHeight).floor();

    var transformStyle =
        'transform: translateY(${(alignmentDelta).toStringAsFixed(2)}px)';

    var items = renderItems(itemNumber, drawCount);

    return new Container(
      style: _style,
      onFlingStart: _handleFlingStart,
      onFlingCancel: _handleFlingCancel,
      onScrollUpdate: _handleScrollUpdate,
      onWheel: _handleWheel,
      children: [
        new Container(
          style: _scrollAreaStyle,
          inlineStyle: transformStyle,
          children: items
        )
      ]
    );
  }

  void willUnmount() {
    _stopFling();
  }

  bool _scrollBy(double scrollDelta) {
    var newScrollOffset = _scrollOffset + scrollDelta;
    if (minOffset != null && newScrollOffset < minOffset) {
      newScrollOffset = minOffset;
    } else if (maxOffset != null && newScrollOffset > maxOffset) {
      newScrollOffset = maxOffset;
    }
    if (newScrollOffset == _scrollOffset) {
      return false;
    }

    setState(() {
      _scrollOffset = newScrollOffset;
    });
    return true;
  }

  void _scheduleFlingUpdate() {
    _flingAnimationId = sky.window.requestAnimationFrame(_updateFling);
  }

  void _stopFling() {
    if (_flingAnimationId == null) {
      return;
    }

    sky.window.cancelAnimationFrame(_flingAnimationId);
    _flingCurve = null;
    _flingAnimationId = null;
  }

  void _updateFling(double timeStamp) {
    double scrollDelta = _flingCurve.update(timeStamp);
    if (!_scrollBy(scrollDelta))
      return _stopFling();
    _scheduleFlingUpdate();
  }

  void _handleScrollUpdate(sky.Event event) {
    _scrollBy(-event.dy);
  }

  void _handleFlingStart(sky.Event event) {
    setState(() {
      _flingCurve = new FlingCurve(-event.velocityY, event.timeStamp);
      _scheduleFlingUpdate();
    });
  }

  void _handleFlingCancel(sky.Event event) {
    _stopFling();
  }

  void _handleWheel(sky.Event event) {
    _scrollBy(-event.offsetY);
  }
}
