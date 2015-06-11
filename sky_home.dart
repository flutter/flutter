import 'dart:sky';
import 'package:sky/framework/fn.dart';
import 'package:sky/framework/components/button.dart';
import 'package:sky/framework/components/scaffold.dart';
import 'package:sky/framework/components/tool_bar.dart';
import 'package:sky/framework/theme/colors.dart';
import 'package:sky/framework/theme/typography.dart' as typography;

class SkyLink extends Component {
  String text;
  String href;

  SkyLink(String text, this.href) : this.text = text, super(key: text);

  UINode build() {
    return new EventListenerNode(
      new Button(key: text, content: new Text(text), level: 1),
      onPointerUp: (_) => window.location.href = href
    );
  }
}

class SkyHome extends App {
  static final Style _actionBarStyle = new Style('''
    background-color: ${Green[500]};''');

  static final Style _titleStyle = new Style('''
    ${typography.white.title};''');

  UINode build() {
    List<UINode> children = [
      new SkyLink('Stocks2 App', 'examples/stocks2/lib/stock_app.dart'),
      new SkyLink('Box2D Game', 'examples/game/main.dart'),
      new SkyLink('Interactive Flex', 'examples/rendering/interactive_flex.dart'),
      new SkyLink('Sector Layout', 'examples/rendering/sector_layout.dart'),
      new SkyLink('Touch Demo', 'examples/rendering/touch_demo.dart'),

      // TODO(eseidel): We could use to separate these groups?
      new SkyLink('Stocks App (Old)', 'examples/stocks/main.sky'),
      new SkyLink('Touch Demo (Old)', 'examples/raw/touch-demo.sky'),
      new SkyLink('Spinning Square (Old)', 'examples/raw/spinning-square.sky'),

      new SkyLink('Licences (Old)', 'LICENSES.sky'),
    ];

    return new Scaffold(
      // FIXME: ActionBar should have a better default style than transparent.
      header: new StyleNode(
        // FIXME: left should be optional, but currently crashes when null.
        new ToolBar(left: new Text(''),
          center: new Container(children: [new Text('Sky Demos')], style: _titleStyle)),
        _actionBarStyle),
      content: new Container(children: children)
    );
  }
}