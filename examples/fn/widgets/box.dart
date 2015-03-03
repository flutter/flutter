part of widgets;

class Box extends Component {

  static Style _style = new Style('''
    display: flex;
    flex-direction: column;
    border-radius: 4px;
    border: 1px solid gray;
    margin: 10px;'''
  );

  static Style _titleStyle = new Style('''
    flex: 1;
    text-align: center;
    font-size: 10px;
    padding: 8px 8px 4px 8px;'''
  );

  static Style _contentStyle = new Style('''
    flex: 1;
    padding: 4px 8px 8px 8px;'''
  );

  String title;
  List<Node> children;

  Box({String key, this.title, this.children }) : super(key: key);

  Node render() {
    return new Container(
      style: _style,
      children: [
        new Container(
          key: 'Title',
          style: _titleStyle,
          children: [new Text(title)]
        ),
        new Container(
          key: 'Content',
          style: _contentStyle,
          children: children
        ),
      ]
    );
  }
}
