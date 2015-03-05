part of widgets;

class MenuItem extends ButtonBase {

  static Style _style = new Style('''
    transform: translateX(0);
    display: flex;
    align-items: center;
    height: 48px;
    -webkit-user-select: none;'''
  );

  static Style _highlightStyle = new Style('''
    transform: translateX(0);
    display: flex;
    align-items: center;
    height: 48px;
    background: rgba(153, 153, 153, 0.4);
    -webkit-user-select: none;'''
  );

  static Style _iconStyle = new Style('''
    padding: 0px 16px;'''
  );

  static Style _labelStyle = new Style('''
      font-family: 'Roboto Medium', 'Helvetica';
      color: #212121;
      padding: 0px 16px;
      flex: 1;'''
  );

  List<Node> children;
  String icon;

  MenuItem({ Object key, this.icon, this.children }) : super(key: key);

  Node render() {
    return new Container(
      style: _highlight ? _highlightStyle : _style,
      children: [
        super.render(),
        new Icon(
          style: _iconStyle,
          size: 24,
          type: "${icon}_grey600"
        ),
        new Container(
          style: _labelStyle,
          children: children
        )
      ]
    );
  }
}
