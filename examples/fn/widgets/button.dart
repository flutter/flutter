part of widgets;

class Button extends ButtonBase {

  static Style _style = new Style('''
    transform: translateX(0);
    display: inline-flex;
    border-radius: 4px;
    justify-content: center;
    align-items: center;
    border: 1px solid blue;
    -webkit-user-select: none;
    margin: 5px;'''
  );

  static Style _highlightStyle = new Style('''
    transform: translateX(0);
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

  Button({ Object key, this.content }) : super(key: key);

  Node build() {
    return new Container(
      key: 'Button',
      style: _highlight ? _highlightStyle : _style,
      children: [super.build(), content]
    );
  }
}
