part of widgets;

class Toolbar extends Component {

  List<Node> children;

  static final Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 56px;
    z-index: 1;
    background-color: ${Purple[500]};
    color: white;
    box-shadow: ${Shadow[2]};'''
  );

  Toolbar({String key, this.children}) : super(key: key);

  Node build() {
    return new Container(
      style: _style,
      children: children
    );
  }
}
