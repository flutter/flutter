part of widgets;

class DrawerHeader extends Component {

  static Style _style = new Style('''
    display: flex;
    flex-direction: column;
    height: 140px;
    -webkit-user-select: none;
    background-color: #E3ECF5;
    border-bottom: 1px solid #D1D9E1;
    padding-bottom: 7px;
    margin-bottom: 8px;'''
  );

  static Style _spacerStyle = new Style('''
    flex: 1'''
  );

  static Style _labelStyle = new Style('''
    padding: 0 16px;
    font-family: 'Roboto Medium', 'Helvetica';
    color: #212121;'''
  );

  List<Node> children;

  DrawerHeader({ Object key, this.children }) : super(key: key);

  Node render() {
    return new Container(
      style: _style,
      children: [
        new Container(
          key: 'Spacer',
          style: _spacerStyle
        ),
        new Container(
          key: 'Label',
          style: _labelStyle,
          children: children
        )
      ]
    );
  }
}
