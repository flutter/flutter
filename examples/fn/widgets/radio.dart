part of widgets;

class Radio extends ButtonBase {

  Object value;
  Object groupValue;
  ValueChanged onChanged;

  static Style _style = new Style('''
    transform: translateX(0);
    display: inline-block;
    -webkit-user-select: none;
    width: 14px;
    height: 14px;
    border-radius: 7px;
    border: 1px solid blue;
    margin: 0 5px;'''
  );

  static Style _highlightStyle = new Style('''
    transform: translateX(0);
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

  Node build() {
    return new Container(
      style: _highlight ? _highlightStyle : _style,
      children: value == groupValue ?
          [super.build(), new Container( style : _dotStyle )] : [super.build()]
    )..events.listen('click', _handleClick);
  }

  void _handleClick(_) {
    onChanged(value);
  }
}
