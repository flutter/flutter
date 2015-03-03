part of widgets;

class Checkbox extends ButtonBase {

  bool checked;
  ValueChanged onChanged;

  static Style _style = new Style('''
    display: flex;
    justify-content: center;
    align-items: center;
    -webkit-user-select: none;
    cursor: pointer;
    width: 30px;
    height: 30px;'''
  );

  static Style _containerStyle = new Style('''
    border: solid 2px;
    border-color: rgba(90, 90, 90, 0.25);
    width: 10px;
    height: 10px;'''
  );

  static Style _containerHighlightStyle = new Style('''
    border: solid 2px;
    border-color: rgba(90, 90, 90, 0.25);
    width: 10px;
    height: 10px;
    border-radius: 10px;
    background-color: orange;
    border-color: orange;'''
  );

  static Style _uncheckedStyle = new Style('''
    top: 0px;
    left: 0px;'''
  );

  static Style _checkedStyle = new Style('''
    top: 0px;
    left: 0px;
    transform: translate(2px, -15px) rotate(45deg);
    width: 10px;
    height: 20px;
    border-style: solid;
    border-top: none;
    border-left: none;
    border-right-width: 2px;
    border-bottom-width: 2px;
    border-color: #0f9d58;'''
  );

  Checkbox({ Object key, this.onChanged, this.checked }) : super(key: key);

  Node render() {
    return new Container(
      style: _style,
      onClick: _handleClick,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      children: [
        new Container(
          style: _highlight ? _containerHighlightStyle : _containerStyle,
          children: [
            new Container(
              style: checked ? _checkedStyle : _uncheckedStyle
            )
          ]
        )
      ]
    );
  }

  void _handleClick(sky.Event e) {
    onChanged(!checked);
  }
}
