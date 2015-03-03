part of widgets;

class Button extends ButtonBase {

  static Style _style = new Style('''
    display: inline-flex;
    border-radius: 4px;
    justify-content: center;
    align-items: center;
    border: 1px solid blue;
    -webkit-user-select: none;
    margin: 5px;'''
  );

  static Style _highlightStyle = new Style('''
    display: inline-flex;
    border-radius: 4px;
    justify-content: center;
    align-items: center;
    border: 1px solid blue;
    -webkit-user-select: none;
    margin: 5px;
    background-color: orange;'''
  );

  Node content;
  sky.EventListener onClick;

  Button({ Object key, this.content, this.onClick }) : super(key: key);

  Node render() {
    return new Container(
      key: 'Button',
      style: _highlight ? _highlightStyle : _style,
      onClick: onClick,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      children: [content]
    );
  }
}
