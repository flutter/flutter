part of widgets;

class MenuDivider extends Component {

  static Style _style = new Style('''
    margin: 8px 0;
    border-bottom: 1px solid rgba(0, 0, 0, 0.12);'''
  );

  MenuDivider({ Object key }) : super(key: key);

  Node render() {
    return new Container(
      style: _style
    );
  }
}
