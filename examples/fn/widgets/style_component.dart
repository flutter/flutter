part of widgets;

abstract class StyleComponent extends Component {
  Node content;

  // Subclasses should implement this getter to provide their style information.
  Style get style => null;

  StyleComponent({ Object key, this.content }) : super(key: key);

  Node render() {
    return new Container(
      style: style,
      children: content == null ? [] : [content]
    );
  }
}
