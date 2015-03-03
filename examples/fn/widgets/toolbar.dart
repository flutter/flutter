part of widgets;

class Toolbar extends Component {

  List<Node> children;

  static final Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 84px;
    z-index: 1;
    background-color: #9C27B0; // Purple 500
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
