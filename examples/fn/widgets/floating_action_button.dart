part of widgets;

class FloatingActionButton extends StyleComponent {
  static final Style _style = new Style('''
    position: absolute;
    display: flex;
    justify-content: center;
    align-items: center;
    bottom: 16px;
    right: 16px;
    width: 56px;
    height: 56px;
    background-color: #F44336;
    color: white;
    border-radius: 28px;
    box-shadow: 0 10px 20px rgba(0,0,0,0.19), 0 6px 6px rgba(0,0,0,0.23);'''
  );

  Style get style => _style;

  FloatingActionButton({ Object key, Node content }) : super(key: key, content: content);
}
