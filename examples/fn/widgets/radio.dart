part of widgets;

class Radio extends ButtonBase {

  Object value;
  Object groupValue;
  ValueChanged onChanged;

  static Style _style = new Style('''
    display: inline-block;
    -webkit-user-select: none;
    width: 14px;
    height: 14px;
    border-radius: 7px;
    border: 1px solid blue;
    margin: 0 5px;'''
  );

  static Style _highlightStyle = new Style('''
    display: inline-block;
    -webkit-user-select: none;
    width: 14px;
    height: 14px;
    border-radius: 7px;
    border: 1px solid blue;
    margin: 0 5px;
    background-color: orange;'''
  );

  static Style _dotStyle = new Style('''
    -webkit-user-select: none;
    width: 10px;
    height: 10px;
    border-radius: 5px;
    background-color: black;
    margin: 2px;'''
  );

  Radio({
    Object key,
    this.onChanged,
    this.value,
    this.groupValue
  }) : super(key: key);

  Node render() {
    return new Container(
      style: _highlight ? _highlightStyle : _style,
      onClick: _handleClick,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      children: value == groupValue ?
          [new Container( style : _dotStyle )] : null
    );
  }

  void _handleClick(sky.Event e) {
    onChanged(value);
  }
}
