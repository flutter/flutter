part of widgets;

class Toolbar extends Component {

  List<Node> children;

  static Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 84px;
    z-index: 1;
    background-color: #3F51B5;
    color: white;
    box-shadow: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23);'''
  );

  Toolbar({String key, this.children}) : super(key: key);

  Node render() {
    return new Container(
      style: _style,
      children: children
    );
  }
}
