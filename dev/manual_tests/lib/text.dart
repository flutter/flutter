// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

int seed = 0;

void main() {
  runApp(new MaterialApp(
    title: 'Text tester',
    home: const Home(),
    routes: <String, WidgetBuilder>{
      'underlines': (BuildContext context) => const Underlines(),
      'fallback': (BuildContext context) => const Fallback(),
      'fuzzer': (BuildContext context) => new Fuzzer(seed: seed),
      'zalgo': (BuildContext context) => const Zalgo(),
    },
  ));
}

class Home extends StatefulWidget {
  const Home({ Key key }) : super(key: key);

  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new FlatButton(
                  child: const Text('Test Underlines'),
                  color: Colors.cyan.shade200,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('underlines'); },
                ),
                new FlatButton(
                  child: const Text('Test Font Fallback'),
                  color: Colors.pink.shade700,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('fallback'); },
                ),
                new FlatButton(
                  child: const Text('TextSpan Fuzzer'),
                  color: Colors.yellow,
                  textColor: Colors.black,
                  onPressed: () { Navigator.of(context).pushNamed('fuzzer'); },
                ),
                new FlatButton(
                  child: const Text('Diacritics Fuzzer'),
                  color: Colors.black,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('zalgo'); },
                ),
              ],
            ),
          ),
          new Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: new Slider(
              min: 0.0,
              max: 1024.0,
              value: seed.toDouble(),
              label: '${seed.round()}',
              divisions: 1025,
              onChanged: (double value) {
                setState(() {
                  seed = value.round();
                });
              },
            ),
          ),
          new Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: new Text('Random seed for fuzzers: $seed'),
          ),
        ],
      ),
    );
  }
}

class Fuzzer extends StatefulWidget {
  const Fuzzer({ Key key, this.seed }) : super(key: key);

  final int seed;

  @override
  _FuzzerState createState() => new _FuzzerState();
}

class _FuzzerState extends State<Fuzzer> with SingleTickerProviderStateMixin {
  TextSpan _textSpan = const TextSpan(text: 'Welcome to the Flutter text fuzzer.');
  Ticker _ticker;
  math.Random _random;

  @override
  void initState() {
    super.initState();
    _random = new math.Random(widget.seed); // providing a seed is important for reproducability
    _ticker = createTicker(_updateTextSpan)..start();
    _updateTextSpan(null);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _updateTextSpan(Duration duration) {
    setState(() {
      _textSpan = _fiddleWith(_textSpan);
    });
  }

  TextSpan _fiddleWith(TextSpan node) {
    return new TextSpan(
      text: _fiddleWithText(node.text),
      style: _fiddleWithStyle(node.style),
      children: _fiddleWithChildren(node.children?.map((TextSpan child) => _fiddleWith(child))?.toList() ?? <TextSpan>[]),
    );
  }

  String _fiddleWithText(String text) {
    if (_random.nextInt(10) > 0)
      return text;
    return _createRandomText();
  }

  TextStyle _fiddleWithStyle(TextStyle style) {
    if (style == null) {
      switch (_random.nextInt(20)) {
        case 0:
          return const TextStyle();
        case 1:
          style = const TextStyle();
          break; // and mutate it below
        default:
          return null;
      }
    }
    if (_random.nextInt(200) == 0)
      return null;
    return new TextStyle(
      color: _fiddleWithColor(style.color),
      decoration: _fiddleWithDecoration(style.decoration),
      decorationColor: _fiddleWithColor(style.decorationColor),
      decorationStyle: _fiddleWithDecorationStyle(style.decorationStyle),
      fontWeight: _fiddleWithFontWeight(style.fontWeight),
      fontStyle: _fiddleWithFontStyle(style.fontStyle),
      // TODO(ianh): Check textBaseline once we support that
      fontFamily: _fiddleWithFontFamily(style.fontFamily),
      fontSize: _fiddleWithDouble(style.fontSize, 14.0, 100.0),
      letterSpacing: _fiddleWithDouble(style.letterSpacing, 0.0, 30.0),
      wordSpacing: _fiddleWithDouble(style.wordSpacing, 0.0, 30.0),
      height: _fiddleWithDouble(style.height, 1.0, 1.9),
    );
  }

  Color _fiddleWithColor(Color value) {
    switch (_random.nextInt(10)) {
      case 0:
        if (value == null)
          return pickFromList(_random, Colors.primaries)[(_random.nextInt(9) + 1) * 100];
        switch (_random.nextInt(4)) {
          case 0:
            return value.withAlpha(value.alpha + _random.nextInt(10) - 5);
          case 1:
            return value.withRed(value.red + _random.nextInt(10) - 5);
          case 2:
            return value.withGreen(value.green + _random.nextInt(10) - 5);
          case 3:
            return value.withBlue(value.blue + _random.nextInt(10) - 5);
        }
        break;
      case 1:
        return null;
    }
    return value;
  }

  TextDecoration _fiddleWithDecoration(TextDecoration value) {
    if (_random.nextInt(10) > 0)
      return value;
    switch (_random.nextInt(100)) {
      case 10:
        return TextDecoration.underline;
      case 11:
        return TextDecoration.underline;
      case 12:
        return TextDecoration.underline;
      case 13:
        return TextDecoration.underline;
      case 20:
        return TextDecoration.lineThrough;
      case 30:
        return TextDecoration.overline;
      case 90:
        return new TextDecoration.combine(<TextDecoration>[TextDecoration.underline, TextDecoration.lineThrough]);
      case 91:
        return new TextDecoration.combine(<TextDecoration>[TextDecoration.underline, TextDecoration.overline]);
      case 92:
        return new TextDecoration.combine(<TextDecoration>[TextDecoration.lineThrough, TextDecoration.overline]);
      case 93:
        return new TextDecoration.combine(<TextDecoration>[TextDecoration.underline, TextDecoration.lineThrough, TextDecoration.overline]);
    }
    return null;
  }

  TextDecorationStyle _fiddleWithDecorationStyle(TextDecorationStyle value) {
    switch (_random.nextInt(10)) {
      case 0:
        return null;
      case 1:
        return pickFromList(_random, TextDecorationStyle.values);
    }
    return value;
  }

  FontWeight _fiddleWithFontWeight(FontWeight value) {
    switch (_random.nextInt(10)) {
      case 0:
        return null;
      case 1:
        return pickFromList(_random, FontWeight.values);
    }
    return value;
  }

  FontStyle _fiddleWithFontStyle(FontStyle value) {
    switch (_random.nextInt(10)) {
      case 0:
        return null;
      case 1:
        return pickFromList(_random, FontStyle.values);
    }
    return value;
  }

  String _fiddleWithFontFamily(String value) {
    switch (_random.nextInt(10)) {
      case 0:
        return null;
      case 1:
        return 'sans-serif';
      case 2:
        return 'sans-serif-condensed';
      case 3:
        return 'serif';
      case 4:
        return 'monospace';
      case 5:
        return 'serif-monospace';
      case 6:
        return 'casual';
      case 7:
        return 'cursive';
      case 8:
        return 'sans-serif-smallcaps';
    }
    return value;
  }

  double _fiddleWithDouble(double value, double defaultValue, double max) {
    switch (_random.nextInt(10)) {
      case 0:
        if (value == null)
          return math.min(defaultValue * (0.95 + _random.nextDouble() * 0.1), max);
        return math.min(value * (0.51 + _random.nextDouble()), max);
      case 1:
        return null;
    }
    return value;
  }

  List<TextSpan> _fiddleWithChildren(List<TextSpan> children) {
    switch (_random.nextInt(100)) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
        children.insert(_random.nextInt(children.length + 1), _createRandomTextSpan());
        break;
      case 10:
        children = children.reversed.toList();
        break;
      case 20:
        if (children.isEmpty)
          break;
        if (_random.nextInt(10) > 0)
          break;
        final int index = _random.nextInt(children.length);
        if (depthOf(children[index]) < 3)
          children.removeAt(index);
        break;
    }
    if (children.isEmpty && _random.nextBool())
      return null;
    return children;
  }

  int depthOf(TextSpan node) {
    if (node.children == null || node.children.isEmpty)
      return 0;
    int result = 0;
    for (TextSpan child in node.children)
      result = math.max(result, depthOf(child));
    return result;
  }

  TextSpan _createRandomTextSpan() {
    return new TextSpan(
      text: _createRandomText(),
    );
  }

  String _createRandomText() {
    switch (_random.nextInt(80)) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return 'ABC';
      case 7:
      case 8:
      case 9:
      case 10:
        return 'أمثولة'; // "Example" or "lesson" in Arabic
      case 11:
      case 12:
      case 13:
      case 14:
        return 'אבג'; // Hebrew ABC
      case 15:
        return '';
      case 16:
        return ' ';
      case 17:
        return '\n';
      case 18:
        return '\t';
      case 19:
        return '\r';
      case 20:
        return Unicode.RLE;
      case 21:
        return Unicode.LRE;
      case 22:
        return Unicode.LRO;
      case 23:
        return Unicode.RLO;
      case 24:
      case 25:
      case 26:
      case 27:
        return Unicode.PDF;
      case 28:
        return Unicode.LRM;
      case 29:
        return Unicode.RLM;
      case 30:
        return Unicode.RLI;
      case 31:
        return Unicode.LRI;
      case 32:
        return Unicode.FSI;
      case 33:
      case 34:
      case 35:
        return Unicode.PDI;
      case 36:
      case 37:
      case 38:
      case 39:
      case 40:
        return ' Hello ';
      case 41:
      case 42:
      case 43:
      case 44:
      case 45:
        return ' World ';
      case 46:
        return 'Flutter';
      case 47:
        return 'Fuzz';
      case 48:
        return 'Test';
      case 49:
        return '𠜎𠜱𠝹𠱓𠱸𠲖𠳏𠳕𠴕𠵼𠵿𠸎𠸏𠹷𠺝𠺢𠻗𠻹𠻺𠼭𠼮𠽌𠾴𠾼𠿪𡁜𡁯𡁵𡁶𡁻𡃁𡃉𡇙𢃇𢞵𢫕𢭃𢯊𢱑𢱕𢳂𢴈𢵌𢵧𢺳𣲷𤓓𤶸𤷪𥄫𦉘𦟌𦧲𦧺𧨾𨅝𨈇𨋢𨳊𨳍𨳒𩶘'; // http://www.i18nguy.com/unicode/supplementary-test.html
      case 50: // any random character
        return new String.fromCharCode(_random.nextInt(0x10FFFF + 1));
      case 51:
        return '\u00DF'; // SS
      case 52:
        return '\u2002'; // En space
      case 53:
        return '\u2003'; // Em space
      case 54:
        return '\u200B'; // zero-width space
      case 55:
        return '\u00A0'; // non-breaking space
      case 56:
        return '\u00FF'; // y-diaresis
      case 57:
        return '\u0178'; // Y-diaresis
      case 58:
        return '\u2060'; // Word Joiner
      case 59: // random BMP character
      case 60: // random BMP character
      case 61: // random BMP character
      case 62: // random BMP character
      case 63: // random BMP character
        return new String.fromCharCode(_random.nextInt(0xFFFF));
      case 64: // random emoji
      case 65: // random emoji
        return new String.fromCharCode(0x1F000 + _random.nextInt(0x9FF));
      case 66:
        return 'Z{' + zalgo(_random, _random.nextInt(4) + 2) + '}Z';
      case 67:
        return 'Οὐχὶ ταὐτὰ παρίσταταί μοι γιγνώσκειν';
      case 68:
        return 'გთხოვთ ახლავე გაიაროთ რეგისტრაცია';
      case 69:
        return 'Зарегистрируйтесь сейчас';
      case 70:
        return 'แผ่นดินฮั่นเสื่อมโทรมแสนสังเวช';
      case 71:
        return 'ᚻᛖ ᚳᚹᚫᚦ ᚦᚫᛏ ᚻᛖ ᛒᚢᛞᛖ ᚩᚾ ᚦᚫᛗ ᛚᚪᚾᛞᛖ ᚾᚩᚱᚦᚹᛖᚪᚱᛞᚢᛗ ᚹᛁᚦ ᚦᚪ ᚹᛖᛥᚫ';
      case 72:
        return '⡌⠁⠧⠑ ⠼⠁⠒  ⡍⠜⠇⠑⠹⠰⠎ ⡣⠕⠌';
      case 73:
        return 'コンニチハ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.black,
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new SingleChildScrollView(
              child: new SafeArea(
                child: new Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: new RichText(text: _textSpan),
                ),
              ),
            ),
          ),
          new Material(
            child: new SwitchListTile(
              title: const Text('Enable Fuzzer'),
              value: _ticker.isActive,
              onChanged: (bool value) {
                setState(() {
                  if (value) {
                    _ticker.start();
                  } else {
                    _ticker.stop();
                    debugPrint(_textSpan.toStringDeep());
                  }
                });
              }
            ),
          ),
        ],
      ),
    );
  }
}

class Underlines extends StatefulWidget {
  const Underlines({ Key key }) : super(key: key);

  @override
  _UnderlinesState createState() => new _UnderlinesState();
}

class _UnderlinesState extends State<Underlines> {

  String _text = 'i';

  final TextStyle _style = new TextStyle(
    inherit: false,
    color: Colors.yellow.shade200,
    fontSize: 48.0,
    fontFamily: 'sans-serif',
    decorationColor: Colors.yellow.shade500,
  );

  Widget _wrap(TextDecorationStyle style) {
    return new Align(
      alignment: Alignment.centerLeft,
      heightFactor: 1.0,
      child: new Container(
        decoration: const BoxDecoration(color: const Color(0xFF333333), border: const Border(right: const BorderSide(color: Colors.white, width: 0.0))),
        child: new Text(_text, style: style != null ? _style.copyWith(decoration: TextDecoration.underline, decorationStyle: style) : _style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = <Widget>[_wrap(null)];
    for (TextDecorationStyle style in TextDecorationStyle.values)
      lines.add(_wrap(style));
    final Size size = MediaQuery.of(context).size;
    return new Container(
      color: Colors.black,
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new SingleChildScrollView(
              child: new Padding(
                padding: new EdgeInsets.symmetric(
                  horizontal: size.width * 0.1,
                  vertical: size.height * 0.1,
                ),
                child: new ListBody(
                  children: lines,
                )
              ),
            ),
          ),
          new Material(
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  onPressed: () {
                    setState(() {
                      _text += 'i';
                    });
                  },
                  color: Colors.yellow,
                  child: const Text('ADD i'),
                ),
                new FlatButton(
                  onPressed: () {
                    setState(() {
                      _text += 'w';
                    });
                  },
                  color: Colors.yellow,
                  child: const Text('ADD w'),
                ),
                new FlatButton(
                  onPressed: _text == '' ? null : () {
                    setState(() {
                      _text = _text.substring(0, _text.length - 1);
                    });
                  },
                  color: Colors.red,
                  textColor: Colors.white,
                  child: const Text('REMOVE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Fallback extends StatefulWidget {
  const Fallback({ Key key }) : super(key: key);

  @override
  _FallbackState createState() => new _FallbackState();
}

class _FallbackState extends State<Fallback> {
  static const String multiScript = 'A1!aÀàĀāƁƀḂⱠꜲꬰəͲἀἏЀЖԠꙐꙮՁخ‎ࡔࠇܦআਉઐଘஇఘಧൺඣᭆᯔᮯ᳇ꠈᜅᩌꪈ༇ꥄꡙꫤ᧰៘꧁꧂ᜰᨏᯤᢆᣭᗗꗃⵞ𐒎߷ጩꬤ𖠺‡₩℻Ⅷ↹⋇⏳ⓖ╋▒◛⚧⑆שׁ🅕㊼龜ポ䷤🂡';

  static const List<String> androidFonts = const <String>[
    'sans-serif',
    'sans-serif-condensed',
    'serif',
    'monospace',
    'serif-monospace',
    'casual',
    'cursive',
    'sans-serif-smallcaps',
  ];

  static const TextStyle style = const TextStyle(
    inherit: false,
    color: Colors.white,
  );

  double _fontSize = 3.0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = <Widget>[];
    for (String font in androidFonts)
      lines.add(new Text(multiScript, style: style.copyWith(fontFamily: font, fontSize: math.exp(_fontSize))));
    final Size size = MediaQuery.of(context).size;
    return new Container(
      color: Colors.black,
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: new SingleChildScrollView(
                child: new Padding(
                  padding: new EdgeInsets.symmetric(
                    horizontal: size.width * 0.1,
                    vertical: size.height * 0.1,
                  ),
                  child: new IntrinsicWidth(
                    child: new ListBody(
                      children: lines,
                    ),
                  )
                ),
              ),
            ),
          ),
          new Material(
            child: new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: const Text('Font size'),
                  ),
                  new Expanded(
                    child: new Slider(
                      min: 2.0,
                      max: 5.0,
                      value: _fontSize,
                      label: '${math.exp(_fontSize).round()}',
                      onChanged: (double value) {
                        setState(() {
                          _fontSize = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Zalgo extends StatefulWidget {
  const Zalgo({ Key key, this.seed }) : super(key: key);

  final int seed;

  @override
  _ZalgoState createState() => new _ZalgoState();
}

class _ZalgoState extends State<Zalgo> with SingleTickerProviderStateMixin {
  String _text;
  Ticker _ticker;
  math.Random _random;

  @override
  void initState() {
    super.initState();
    _random = new math.Random(widget.seed); // providing a seed is important for reproducability
    _ticker = createTicker(_update)..start();
    _update(null);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool _allowSpacing = false;

  void _update(Duration duration) {
    setState(() {
      _text = zalgo(_random, 6 + _random.nextInt(10), includeSpacingCombiningMarks: _allowSpacing);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.black,
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new Center(
              child: new RichText(
                text: new TextSpan(
                  text: _text,
                  style: new TextStyle(
                    inherit: false,
                    fontSize: 96.0,
                    color: Colors.red.shade200,
                  ),
                ),
              ),
            ),
          ),
          new Material(
            child: new Column(
              children: <Widget>[
                new SwitchListTile(
                  title: const Text('Enable Fuzzer'),
                  value: _ticker.isActive,
                  onChanged: (bool value) {
                    setState(() {
                      if (value) {
                        _ticker.start();
                      } else {
                        _ticker.stop();
                      }
                    });
                  },
                ),
                new SwitchListTile(
                  title: const Text('Allow spacing combining marks'),
                  value: _allowSpacing,
                  onChanged: (bool value) {
                    setState(() {
                      _allowSpacing = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String zalgo(math.Random random, int target, { bool includeSpacingCombiningMarks: false }) {
  // The following three tables are derived from UnicodeData.txt:
  //   http://unicode.org/Public/UNIDATA/UnicodeData.txt
  // There are three groups, character classes Mc, Me, and Mn.
  const List<int> enclosingCombiningMarks = const <int>[ // Me
    0x00488, 0x00489, 0x01ABE, 0x020DD, 0x020DE, 0x020DF, 0x020E0,
    0x020E2, 0x020E3, 0x020E4, 0x0A670, 0x0A671, 0x0A672,
  ];
  const List<int> nonspacingCombiningMarks = const <int>[ // Mn
    0x00300, 0x00301, 0x00302, 0x00303, 0x00304, 0x00305, 0x00306,
    0x00307, 0x00308, 0x00309, 0x0030A, 0x0030B, 0x0030C, 0x0030D,
    0x0030E, 0x0030F, 0x00310, 0x00311, 0x00312, 0x00313, 0x00314,
    0x00315, 0x00316, 0x00317, 0x00318, 0x00319, 0x0031A, 0x0031B,
    0x0031C, 0x0031D, 0x0031E, 0x0031F, 0x00320, 0x00321, 0x00322,
    0x00323, 0x00324, 0x00325, 0x00326, 0x00327, 0x00328, 0x00329,
    0x0032A, 0x0032B, 0x0032C, 0x0032D, 0x0032E, 0x0032F, 0x00330,
    0x00331, 0x00332, 0x00333, 0x00334, 0x00335, 0x00336, 0x00337,
    0x00338, 0x00339, 0x0033A, 0x0033B, 0x0033C, 0x0033D, 0x0033E,
    0x0033F, 0x00340, 0x00341, 0x00342, 0x00343, 0x00344, 0x00345,
    0x00346, 0x00347, 0x00348, 0x00349, 0x0034A, 0x0034B, 0x0034C,
    0x0034D, 0x0034E, 0x0034F, 0x00350, 0x00351, 0x00352, 0x00353,
    0x00354, 0x00355, 0x00356, 0x00357, 0x00358, 0x00359, 0x0035A,
    0x0035B, 0x0035C, 0x0035D, 0x0035E, 0x0035F, 0x00360, 0x00361,
    0x00362, 0x00363, 0x00364, 0x00365, 0x00366, 0x00367, 0x00368,
    0x00369, 0x0036A, 0x0036B, 0x0036C, 0x0036D, 0x0036E, 0x0036F,
    0x00483, 0x00484, 0x00485, 0x00486, 0x00487, 0x00591, 0x00592,
    0x00593, 0x00594, 0x00595, 0x00596, 0x00597, 0x00598, 0x00599,
    0x0059A, 0x0059B, 0x0059C, 0x0059D, 0x0059E, 0x0059F, 0x005A0,
    0x005A1, 0x005A2, 0x005A3, 0x005A4, 0x005A5, 0x005A6, 0x005A7,
    0x005A8, 0x005A9, 0x005AA, 0x005AB, 0x005AC, 0x005AD, 0x005AE,
    0x005AF, 0x005B0, 0x005B1, 0x005B2, 0x005B3, 0x005B4, 0x005B5,
    0x005B6, 0x005B7, 0x005B8, 0x005B9, 0x005BA, 0x005BB, 0x005BC,
    0x005BD, 0x005BF, 0x005C1, 0x005C2, 0x005C4, 0x005C5, 0x005C7,
    0x00610, 0x00611, 0x00612, 0x00613, 0x00614, 0x00615, 0x00616,
    0x00617, 0x00618, 0x00619, 0x0061A, 0x0064B, 0x0064C, 0x0064D,
    0x0064E, 0x0064F, 0x00650, 0x00651, 0x00652, 0x00653, 0x00654,
    0x00655, 0x00656, 0x00657, 0x00658, 0x00659, 0x0065A, 0x0065B,
    0x0065C, 0x0065D, 0x0065E, 0x0065F, 0x00670, 0x006D6, 0x006D7,
    0x006D8, 0x006D9, 0x006DA, 0x006DB, 0x006DC, 0x006DF, 0x006E0,
    0x006E1, 0x006E2, 0x006E3, 0x006E4, 0x006E7, 0x006E8, 0x006EA,
    0x006EB, 0x006EC, 0x006ED, 0x00711, 0x00730, 0x00731, 0x00732,
    0x00733, 0x00734, 0x00735, 0x00736, 0x00737, 0x00738, 0x00739,
    0x0073A, 0x0073B, 0x0073C, 0x0073D, 0x0073E, 0x0073F, 0x00740,
    0x00741, 0x00742, 0x00743, 0x00744, 0x00745, 0x00746, 0x00747,
    0x00748, 0x00749, 0x0074A, 0x007A6, 0x007A7, 0x007A8, 0x007A9,
    0x007AA, 0x007AB, 0x007AC, 0x007AD, 0x007AE, 0x007AF, 0x007B0,
    0x007EB, 0x007EC, 0x007ED, 0x007EE, 0x007EF, 0x007F0, 0x007F1,
    0x007F2, 0x007F3, 0x00816, 0x00817, 0x00818, 0x00819, 0x0081B,
    0x0081C, 0x0081D, 0x0081E, 0x0081F, 0x00820, 0x00821, 0x00822,
    0x00823, 0x00825, 0x00826, 0x00827, 0x00829, 0x0082A, 0x0082B,
    0x0082C, 0x0082D, 0x00859, 0x0085A, 0x0085B, 0x008D4, 0x008D5,
    0x008D6, 0x008D7, 0x008D8, 0x008D9, 0x008DA, 0x008DB, 0x008DC,
    0x008DD, 0x008DE, 0x008DF, 0x008E0, 0x008E1, 0x008E3, 0x008E4,
    0x008E5, 0x008E6, 0x008E7, 0x008E8, 0x008E9, 0x008EA, 0x008EB,
    0x008EC, 0x008ED, 0x008EE, 0x008EF, 0x008F0, 0x008F1, 0x008F2,
    0x008F3, 0x008F4, 0x008F5, 0x008F6, 0x008F7, 0x008F8, 0x008F9,
    0x008FA, 0x008FB, 0x008FC, 0x008FD, 0x008FE, 0x008FF, 0x00900,
    0x00901, 0x00902, 0x0093A, 0x0093C, 0x00941, 0x00942, 0x00943,
    0x00944, 0x00945, 0x00946, 0x00947, 0x00948, 0x0094D, 0x00951,
    0x00952, 0x00953, 0x00954, 0x00955, 0x00956, 0x00957, 0x00962,
    0x00963, 0x00981, 0x009BC, 0x009C1, 0x009C2, 0x009C3, 0x009C4,
    0x009CD, 0x009E2, 0x009E3, 0x00A01, 0x00A02, 0x00A3C, 0x00A41,
    0x00A42, 0x00A47, 0x00A48, 0x00A4B, 0x00A4C, 0x00A4D, 0x00A51,
    0x00A70, 0x00A71, 0x00A75, 0x00A81, 0x00A82, 0x00ABC, 0x00AC1,
    0x00AC2, 0x00AC3, 0x00AC4, 0x00AC5, 0x00AC7, 0x00AC8, 0x00ACD,
    0x00AE2, 0x00AE3, 0x00AFA, 0x00AFB, 0x00AFC, 0x00AFD, 0x00AFE,
    0x00AFF, 0x00B01, 0x00B3C, 0x00B3F, 0x00B41, 0x00B42, 0x00B43,
    0x00B44, 0x00B4D, 0x00B56, 0x00B62, 0x00B63, 0x00B82, 0x00BC0,
    0x00BCD, 0x00C00, 0x00C3E, 0x00C3F, 0x00C40, 0x00C46, 0x00C47,
    0x00C48, 0x00C4A, 0x00C4B, 0x00C4C, 0x00C4D, 0x00C55, 0x00C56,
    0x00C62, 0x00C63, 0x00C81, 0x00CBC, 0x00CBF, 0x00CC6, 0x00CCC,
    0x00CCD, 0x00CE2, 0x00CE3, 0x00D00, 0x00D01, 0x00D3B, 0x00D3C,
    0x00D41, 0x00D42, 0x00D43, 0x00D44, 0x00D4D, 0x00D62, 0x00D63,
    0x00DCA, 0x00DD2, 0x00DD3, 0x00DD4, 0x00DD6, 0x00E31, 0x00E34,
    0x00E35, 0x00E36, 0x00E37, 0x00E38, 0x00E39, 0x00E3A, 0x00E47,
    0x00E48, 0x00E49, 0x00E4A, 0x00E4B, 0x00E4C, 0x00E4D, 0x00E4E,
    0x00EB1, 0x00EB4, 0x00EB5, 0x00EB6, 0x00EB7, 0x00EB8, 0x00EB9,
    0x00EBB, 0x00EBC, 0x00EC8, 0x00EC9, 0x00ECA, 0x00ECB, 0x00ECC,
    0x00ECD, 0x00F18, 0x00F19, 0x00F35, 0x00F37, 0x00F39, 0x00F71,
    0x00F72, 0x00F73, 0x00F74, 0x00F75, 0x00F76, 0x00F77, 0x00F78,
    0x00F79, 0x00F7A, 0x00F7B, 0x00F7C, 0x00F7D, 0x00F7E, 0x00F80,
    0x00F81, 0x00F82, 0x00F83, 0x00F84, 0x00F86, 0x00F87, 0x00F8D,
    0x00F8E, 0x00F8F, 0x00F90, 0x00F91, 0x00F92, 0x00F93, 0x00F94,
    0x00F95, 0x00F96, 0x00F97, 0x00F99, 0x00F9A, 0x00F9B, 0x00F9C,
    0x00F9D, 0x00F9E, 0x00F9F, 0x00FA0, 0x00FA1, 0x00FA2, 0x00FA3,
    0x00FA4, 0x00FA5, 0x00FA6, 0x00FA7, 0x00FA8, 0x00FA9, 0x00FAA,
    0x00FAB, 0x00FAC, 0x00FAD, 0x00FAE, 0x00FAF, 0x00FB0, 0x00FB1,
    0x00FB2, 0x00FB3, 0x00FB4, 0x00FB5, 0x00FB6, 0x00FB7, 0x00FB8,
    0x00FB9, 0x00FBA, 0x00FBB, 0x00FBC, 0x00FC6, 0x0102D, 0x0102E,
    0x0102F, 0x01030, 0x01032, 0x01033, 0x01034, 0x01035, 0x01036,
    0x01037, 0x01039, 0x0103A, 0x0103D, 0x0103E, 0x01058, 0x01059,
    0x0105E, 0x0105F, 0x01060, 0x01071, 0x01072, 0x01073, 0x01074,
    0x01082, 0x01085, 0x01086, 0x0108D, 0x0109D, 0x0135D, 0x0135E,
    0x0135F, 0x01712, 0x01713, 0x01714, 0x01732, 0x01733, 0x01734,
    0x01752, 0x01753, 0x01772, 0x01773, 0x017B4, 0x017B5, 0x017B7,
    0x017B8, 0x017B9, 0x017BA, 0x017BB, 0x017BC, 0x017BD, 0x017C6,
    0x017C9, 0x017CA, 0x017CB, 0x017CC, 0x017CD, 0x017CE, 0x017CF,
    0x017D0, 0x017D1, 0x017D2, 0x017D3, 0x017DD, 0x0180B, 0x0180C,
    0x0180D, 0x01885, 0x01886, 0x018A9, 0x01920, 0x01921, 0x01922,
    0x01927, 0x01928, 0x01932, 0x01939, 0x0193A, 0x0193B, 0x01A17,
    0x01A18, 0x01A1B, 0x01A56, 0x01A58, 0x01A59, 0x01A5A, 0x01A5B,
    0x01A5C, 0x01A5D, 0x01A5E, 0x01A60, 0x01A62, 0x01A65, 0x01A66,
    0x01A67, 0x01A68, 0x01A69, 0x01A6A, 0x01A6B, 0x01A6C, 0x01A73,
    0x01A74, 0x01A75, 0x01A76, 0x01A77, 0x01A78, 0x01A79, 0x01A7A,
    0x01A7B, 0x01A7C, 0x01A7F, 0x01AB0, 0x01AB1, 0x01AB2, 0x01AB3,
    0x01AB4, 0x01AB5, 0x01AB6, 0x01AB7, 0x01AB8, 0x01AB9, 0x01ABA,
    0x01ABB, 0x01ABC, 0x01ABD, 0x01B00, 0x01B01, 0x01B02, 0x01B03,
    0x01B34, 0x01B36, 0x01B37, 0x01B38, 0x01B39, 0x01B3A, 0x01B3C,
    0x01B42, 0x01B6B, 0x01B6C, 0x01B6D, 0x01B6E, 0x01B6F, 0x01B70,
    0x01B71, 0x01B72, 0x01B73, 0x01B80, 0x01B81, 0x01BA2, 0x01BA3,
    0x01BA4, 0x01BA5, 0x01BA8, 0x01BA9, 0x01BAB, 0x01BAC, 0x01BAD,
    0x01BE6, 0x01BE8, 0x01BE9, 0x01BED, 0x01BEF, 0x01BF0, 0x01BF1,
    0x01C2C, 0x01C2D, 0x01C2E, 0x01C2F, 0x01C30, 0x01C31, 0x01C32,
    0x01C33, 0x01C36, 0x01C37, 0x01CD0, 0x01CD1, 0x01CD2, 0x01CD4,
    0x01CD5, 0x01CD6, 0x01CD7, 0x01CD8, 0x01CD9, 0x01CDA, 0x01CDB,
    0x01CDC, 0x01CDD, 0x01CDE, 0x01CDF, 0x01CE0, 0x01CE2, 0x01CE3,
    0x01CE4, 0x01CE5, 0x01CE6, 0x01CE7, 0x01CE8, 0x01CED, 0x01CF4,
    0x01CF8, 0x01CF9, 0x01DC0, 0x01DC1, 0x01DC2, 0x01DC3, 0x01DC4,
    0x01DC5, 0x01DC6, 0x01DC7, 0x01DC8, 0x01DC9, 0x01DCA, 0x01DCB,
    0x01DCC, 0x01DCD, 0x01DCE, 0x01DCF, 0x01DD0, 0x01DD1, 0x01DD2,
    0x01DD3, 0x01DD4, 0x01DD5, 0x01DD6, 0x01DD7, 0x01DD8, 0x01DD9,
    0x01DDA, 0x01DDB, 0x01DDC, 0x01DDD, 0x01DDE, 0x01DDF, 0x01DE0,
    0x01DE1, 0x01DE2, 0x01DE3, 0x01DE4, 0x01DE5, 0x01DE6, 0x01DE7,
    0x01DE8, 0x01DE9, 0x01DEA, 0x01DEB, 0x01DEC, 0x01DED, 0x01DEE,
    0x01DEF, 0x01DF0, 0x01DF1, 0x01DF2, 0x01DF3, 0x01DF4, 0x01DF5,
    0x01DF6, 0x01DF7, 0x01DF8, 0x01DF9, 0x01DFB, 0x01DFC, 0x01DFD,
    0x01DFE, 0x01DFF, 0x020D0, 0x020D1, 0x020D2, 0x020D3, 0x020D4,
    0x020D5, 0x020D6, 0x020D7, 0x020D8, 0x020D9, 0x020DA, 0x020DB,
    0x020DC, 0x020E1, 0x020E5, 0x020E6, 0x020E7, 0x020E8, 0x020E9,
    0x020EA, 0x020EB, 0x020EC, 0x020ED, 0x020EE, 0x020EF, 0x020F0,
    0x02CEF, 0x02CF0, 0x02CF1, 0x02D7F, 0x02DE0, 0x02DE1, 0x02DE2,
    0x02DE3, 0x02DE4, 0x02DE5, 0x02DE6, 0x02DE7, 0x02DE8, 0x02DE9,
    0x02DEA, 0x02DEB, 0x02DEC, 0x02DED, 0x02DEE, 0x02DEF, 0x02DF0,
    0x02DF1, 0x02DF2, 0x02DF3, 0x02DF4, 0x02DF5, 0x02DF6, 0x02DF7,
    0x02DF8, 0x02DF9, 0x02DFA, 0x02DFB, 0x02DFC, 0x02DFD, 0x02DFE,
    0x02DFF, 0x0302A, 0x0302B, 0x0302C, 0x0302D, 0x03099, 0x0309A,
    0x0A66F, 0x0A674, 0x0A675, 0x0A676, 0x0A677, 0x0A678, 0x0A679,
    0x0A67A, 0x0A67B, 0x0A67C, 0x0A67D, 0x0A69E, 0x0A69F, 0x0A6F0,
    0x0A6F1, 0x0A802, 0x0A806, 0x0A80B, 0x0A825, 0x0A826, 0x0A8C4,
    0x0A8C5, 0x0A8E0, 0x0A8E1, 0x0A8E2, 0x0A8E3, 0x0A8E4, 0x0A8E5,
    0x0A8E6, 0x0A8E7, 0x0A8E8, 0x0A8E9, 0x0A8EA, 0x0A8EB, 0x0A8EC,
    0x0A8ED, 0x0A8EE, 0x0A8EF, 0x0A8F0, 0x0A8F1, 0x0A926, 0x0A927,
    0x0A928, 0x0A929, 0x0A92A, 0x0A92B, 0x0A92C, 0x0A92D, 0x0A947,
    0x0A948, 0x0A949, 0x0A94A, 0x0A94B, 0x0A94C, 0x0A94D, 0x0A94E,
    0x0A94F, 0x0A950, 0x0A951, 0x0A980, 0x0A981, 0x0A982, 0x0A9B3,
    0x0A9B6, 0x0A9B7, 0x0A9B8, 0x0A9B9, 0x0A9BC, 0x0A9E5, 0x0AA29,
    0x0AA2A, 0x0AA2B, 0x0AA2C, 0x0AA2D, 0x0AA2E, 0x0AA31, 0x0AA32,
    0x0AA35, 0x0AA36, 0x0AA43, 0x0AA4C, 0x0AA7C, 0x0AAB0, 0x0AAB2,
    0x0AAB3, 0x0AAB4, 0x0AAB7, 0x0AAB8, 0x0AABE, 0x0AABF, 0x0AAC1,
    0x0AAEC, 0x0AAED, 0x0AAF6, 0x0ABE5, 0x0ABE8, 0x0ABED, 0x0FB1E,
    0x0FE00, 0x0FE01, 0x0FE02, 0x0FE03, 0x0FE04, 0x0FE05, 0x0FE06,
    0x0FE07, 0x0FE08, 0x0FE09, 0x0FE0A, 0x0FE0B, 0x0FE0C, 0x0FE0D,
    0x0FE0E, 0x0FE0F, 0x0FE20, 0x0FE21, 0x0FE22, 0x0FE23, 0x0FE24,
    0x0FE25, 0x0FE26, 0x0FE27, 0x0FE28, 0x0FE29, 0x0FE2A, 0x0FE2B,
    0x0FE2C, 0x0FE2D, 0x0FE2E, 0x0FE2F, 0x101FD, 0x102E0, 0x10376,
    0x10377, 0x10378, 0x10379, 0x1037A, 0x10A01, 0x10A02, 0x10A03,
    0x10A05, 0x10A06, 0x10A0C, 0x10A0D, 0x10A0E, 0x10A0F, 0x10A38,
    0x10A39, 0x10A3A, 0x10A3F, 0x10AE5, 0x10AE6, 0x11001, 0x11038,
    0x11039, 0x1103A, 0x1103B, 0x1103C, 0x1103D, 0x1103E, 0x1103F,
    0x11040, 0x11041, 0x11042, 0x11043, 0x11044, 0x11045, 0x11046,
    0x1107F, 0x11080, 0x11081, 0x110B3, 0x110B4, 0x110B5, 0x110B6,
    0x110B9, 0x110BA, 0x11100, 0x11101, 0x11102, 0x11127, 0x11128,
    0x11129, 0x1112A, 0x1112B, 0x1112D, 0x1112E, 0x1112F, 0x11130,
    0x11131, 0x11132, 0x11133, 0x11134, 0x11173, 0x11180, 0x11181,
    0x111B6, 0x111B7, 0x111B8, 0x111B9, 0x111BA, 0x111BB, 0x111BC,
    0x111BD, 0x111BE, 0x111CA, 0x111CB, 0x111CC, 0x1122F, 0x11230,
    0x11231, 0x11234, 0x11236, 0x11237, 0x1123E, 0x112DF, 0x112E3,
    0x112E4, 0x112E5, 0x112E6, 0x112E7, 0x112E8, 0x112E9, 0x112EA,
    0x11300, 0x11301, 0x1133C, 0x11340, 0x11366, 0x11367, 0x11368,
    0x11369, 0x1136A, 0x1136B, 0x1136C, 0x11370, 0x11371, 0x11372,
    0x11373, 0x11374, 0x11438, 0x11439, 0x1143A, 0x1143B, 0x1143C,
    0x1143D, 0x1143E, 0x1143F, 0x11442, 0x11443, 0x11444, 0x11446,
    0x114B3, 0x114B4, 0x114B5, 0x114B6, 0x114B7, 0x114B8, 0x114BA,
    0x114BF, 0x114C0, 0x114C2, 0x114C3, 0x115B2, 0x115B3, 0x115B4,
    0x115B5, 0x115BC, 0x115BD, 0x115BF, 0x115C0, 0x115DC, 0x115DD,
    0x11633, 0x11634, 0x11635, 0x11636, 0x11637, 0x11638, 0x11639,
    0x1163A, 0x1163D, 0x1163F, 0x11640, 0x116AB, 0x116AD, 0x116B0,
    0x116B1, 0x116B2, 0x116B3, 0x116B4, 0x116B5, 0x116B7, 0x1171D,
    0x1171E, 0x1171F, 0x11722, 0x11723, 0x11724, 0x11725, 0x11727,
    0x11728, 0x11729, 0x1172A, 0x1172B, 0x11A01, 0x11A02, 0x11A03,
    0x11A04, 0x11A05, 0x11A06, 0x11A09, 0x11A0A, 0x11A33, 0x11A34,
    0x11A35, 0x11A36, 0x11A37, 0x11A38, 0x11A3B, 0x11A3C, 0x11A3D,
    0x11A3E, 0x11A47, 0x11A51, 0x11A52, 0x11A53, 0x11A54, 0x11A55,
    0x11A56, 0x11A59, 0x11A5A, 0x11A5B, 0x11A8A, 0x11A8B, 0x11A8C,
    0x11A8D, 0x11A8E, 0x11A8F, 0x11A90, 0x11A91, 0x11A92, 0x11A93,
    0x11A94, 0x11A95, 0x11A96, 0x11A98, 0x11A99, 0x11C30, 0x11C31,
    0x11C32, 0x11C33, 0x11C34, 0x11C35, 0x11C36, 0x11C38, 0x11C39,
    0x11C3A, 0x11C3B, 0x11C3C, 0x11C3D, 0x11C3F, 0x11C92, 0x11C93,
    0x11C94, 0x11C95, 0x11C96, 0x11C97, 0x11C98, 0x11C99, 0x11C9A,
    0x11C9B, 0x11C9C, 0x11C9D, 0x11C9E, 0x11C9F, 0x11CA0, 0x11CA1,
    0x11CA2, 0x11CA3, 0x11CA4, 0x11CA5, 0x11CA6, 0x11CA7, 0x11CAA,
    0x11CAB, 0x11CAC, 0x11CAD, 0x11CAE, 0x11CAF, 0x11CB0, 0x11CB2,
    0x11CB3, 0x11CB5, 0x11CB6, 0x11D31, 0x11D32, 0x11D33, 0x11D34,
    0x11D35, 0x11D36, 0x11D3A, 0x11D3C, 0x11D3D, 0x11D3F, 0x11D40,
    0x11D41, 0x11D42, 0x11D43, 0x11D44, 0x11D45, 0x11D47, 0x16AF0,
    0x16AF1, 0x16AF2, 0x16AF3, 0x16AF4, 0x16B30, 0x16B31, 0x16B32,
    0x16B33, 0x16B34, 0x16B35, 0x16B36, 0x16F8F, 0x16F90, 0x16F91,
    0x16F92, 0x1BC9D, 0x1BC9E, 0x1D167, 0x1D168, 0x1D169, 0x1D17B,
    0x1D17C, 0x1D17D, 0x1D17E, 0x1D17F, 0x1D180, 0x1D181, 0x1D182,
    0x1D185, 0x1D186, 0x1D187, 0x1D188, 0x1D189, 0x1D18A, 0x1D18B,
    0x1D1AA, 0x1D1AB, 0x1D1AC, 0x1D1AD, 0x1D242, 0x1D243, 0x1D244,
    0x1DA00, 0x1DA01, 0x1DA02, 0x1DA03, 0x1DA04, 0x1DA05, 0x1DA06,
    0x1DA07, 0x1DA08, 0x1DA09, 0x1DA0A, 0x1DA0B, 0x1DA0C, 0x1DA0D,
    0x1DA0E, 0x1DA0F, 0x1DA10, 0x1DA11, 0x1DA12, 0x1DA13, 0x1DA14,
    0x1DA15, 0x1DA16, 0x1DA17, 0x1DA18, 0x1DA19, 0x1DA1A, 0x1DA1B,
    0x1DA1C, 0x1DA1D, 0x1DA1E, 0x1DA1F, 0x1DA20, 0x1DA21, 0x1DA22,
    0x1DA23, 0x1DA24, 0x1DA25, 0x1DA26, 0x1DA27, 0x1DA28, 0x1DA29,
    0x1DA2A, 0x1DA2B, 0x1DA2C, 0x1DA2D, 0x1DA2E, 0x1DA2F, 0x1DA30,
    0x1DA31, 0x1DA32, 0x1DA33, 0x1DA34, 0x1DA35, 0x1DA36, 0x1DA3B,
    0x1DA3C, 0x1DA3D, 0x1DA3E, 0x1DA3F, 0x1DA40, 0x1DA41, 0x1DA42,
    0x1DA43, 0x1DA44, 0x1DA45, 0x1DA46, 0x1DA47, 0x1DA48, 0x1DA49,
    0x1DA4A, 0x1DA4B, 0x1DA4C, 0x1DA4D, 0x1DA4E, 0x1DA4F, 0x1DA50,
    0x1DA51, 0x1DA52, 0x1DA53, 0x1DA54, 0x1DA55, 0x1DA56, 0x1DA57,
    0x1DA58, 0x1DA59, 0x1DA5A, 0x1DA5B, 0x1DA5C, 0x1DA5D, 0x1DA5E,
    0x1DA5F, 0x1DA60, 0x1DA61, 0x1DA62, 0x1DA63, 0x1DA64, 0x1DA65,
    0x1DA66, 0x1DA67, 0x1DA68, 0x1DA69, 0x1DA6A, 0x1DA6B, 0x1DA6C,
    0x1DA75, 0x1DA84, 0x1DA9B, 0x1DA9C, 0x1DA9D, 0x1DA9E, 0x1DA9F,
    0x1DAA1, 0x1DAA2, 0x1DAA3, 0x1DAA4, 0x1DAA5, 0x1DAA6, 0x1DAA7,
    0x1DAA8, 0x1DAA9, 0x1DAAA, 0x1DAAB, 0x1DAAC, 0x1DAAD, 0x1DAAE,
    0x1DAAF, 0x1E000, 0x1E001, 0x1E002, 0x1E003, 0x1E004, 0x1E005,
    0x1E006, 0x1E008, 0x1E009, 0x1E00A, 0x1E00B, 0x1E00C, 0x1E00D,
    0x1E00E, 0x1E00F, 0x1E010, 0x1E011, 0x1E012, 0x1E013, 0x1E014,
    0x1E015, 0x1E016, 0x1E017, 0x1E018, 0x1E01B, 0x1E01C, 0x1E01D,
    0x1E01E, 0x1E01F, 0x1E020, 0x1E021, 0x1E023, 0x1E024, 0x1E026,
    0x1E027, 0x1E028, 0x1E029, 0x1E02A, 0x1E8D0, 0x1E8D1, 0x1E8D2,
    0x1E8D3, 0x1E8D4, 0x1E8D5, 0x1E8D6, 0x1E944, 0x1E945, 0x1E946,
    0x1E947, 0x1E948, 0x1E949, 0x1E94A, 0xE0100, 0xE0101, 0xE0102,
    0xE0103, 0xE0104, 0xE0105, 0xE0106, 0xE0107, 0xE0108, 0xE0109,
    0xE010A, 0xE010B, 0xE010C, 0xE010D, 0xE010E, 0xE010F, 0xE0110,
    0xE0111, 0xE0112, 0xE0113, 0xE0114, 0xE0115, 0xE0116, 0xE0117,
    0xE0118, 0xE0119, 0xE011A, 0xE011B, 0xE011C, 0xE011D, 0xE011E,
    0xE011F, 0xE0120, 0xE0121, 0xE0122, 0xE0123, 0xE0124, 0xE0125,
    0xE0126, 0xE0127, 0xE0128, 0xE0129, 0xE012A, 0xE012B, 0xE012C,
    0xE012D, 0xE012E, 0xE012F, 0xE0130, 0xE0131, 0xE0132, 0xE0133,
    0xE0134, 0xE0135, 0xE0136, 0xE0137, 0xE0138, 0xE0139, 0xE013A,
    0xE013B, 0xE013C, 0xE013D, 0xE013E, 0xE013F, 0xE0140, 0xE0141,
    0xE0142, 0xE0143, 0xE0144, 0xE0145, 0xE0146, 0xE0147, 0xE0148,
    0xE0149, 0xE014A, 0xE014B, 0xE014C, 0xE014D, 0xE014E, 0xE014F,
    0xE0150, 0xE0151, 0xE0152, 0xE0153, 0xE0154, 0xE0155, 0xE0156,
    0xE0157, 0xE0158, 0xE0159, 0xE015A, 0xE015B, 0xE015C, 0xE015D,
    0xE015E, 0xE015F, 0xE0160, 0xE0161, 0xE0162, 0xE0163, 0xE0164,
    0xE0165, 0xE0166, 0xE0167, 0xE0168, 0xE0169, 0xE016A, 0xE016B,
    0xE016C, 0xE016D, 0xE016E, 0xE016F, 0xE0170, 0xE0171, 0xE0172,
    0xE0173, 0xE0174, 0xE0175, 0xE0176, 0xE0177, 0xE0178, 0xE0179,
    0xE017A, 0xE017B, 0xE017C, 0xE017D, 0xE017E, 0xE017F, 0xE0180,
    0xE0181, 0xE0182, 0xE0183, 0xE0184, 0xE0185, 0xE0186, 0xE0187,
    0xE0188, 0xE0189, 0xE018A, 0xE018B, 0xE018C, 0xE018D, 0xE018E,
    0xE018F, 0xE0190, 0xE0191, 0xE0192, 0xE0193, 0xE0194, 0xE0195,
    0xE0196, 0xE0197, 0xE0198, 0xE0199, 0xE019A, 0xE019B, 0xE019C,
    0xE019D, 0xE019E, 0xE019F, 0xE01A0, 0xE01A1, 0xE01A2, 0xE01A3,
    0xE01A4, 0xE01A5, 0xE01A6, 0xE01A7, 0xE01A8, 0xE01A9, 0xE01AA,
    0xE01AB, 0xE01AC, 0xE01AD, 0xE01AE, 0xE01AF, 0xE01B0, 0xE01B1,
    0xE01B2, 0xE01B3, 0xE01B4, 0xE01B5, 0xE01B6, 0xE01B7, 0xE01B8,
    0xE01B9, 0xE01BA, 0xE01BB, 0xE01BC, 0xE01BD, 0xE01BE, 0xE01BF,
    0xE01C0, 0xE01C1, 0xE01C2, 0xE01C3, 0xE01C4, 0xE01C5, 0xE01C6,
    0xE01C7, 0xE01C8, 0xE01C9, 0xE01CA, 0xE01CB, 0xE01CC, 0xE01CD,
    0xE01CE, 0xE01CF, 0xE01D0, 0xE01D1, 0xE01D2, 0xE01D3, 0xE01D4,
    0xE01D5, 0xE01D6, 0xE01D7, 0xE01D8, 0xE01D9, 0xE01DA, 0xE01DB,
    0xE01DC, 0xE01DD, 0xE01DE, 0xE01DF, 0xE01E0, 0xE01E1, 0xE01E2,
    0xE01E3, 0xE01E4, 0xE01E5, 0xE01E6, 0xE01E7, 0xE01E8, 0xE01E9,
    0xE01EA, 0xE01EB, 0xE01EC, 0xE01ED, 0xE01EE, 0xE01EF,
  ];
  const List<int> spacingCombiningMarks = const <int>[ // Mc
    0x00903, 0x0093B, 0x0093E, 0x0093F, 0x00940, 0x00949, 0x0094A,
    0x0094B, 0x0094C, 0x0094E, 0x0094F, 0x00982, 0x00983, 0x009BE,
    0x009BF, 0x009C0, 0x009C7, 0x009C8, 0x009CB, 0x009CC, 0x009D7,
    0x00A03, 0x00A3E, 0x00A3F, 0x00A40, 0x00A83, 0x00ABE, 0x00ABF,
    0x00AC0, 0x00AC9, 0x00ACB, 0x00ACC, 0x00B02, 0x00B03, 0x00B3E,
    0x00B40, 0x00B47, 0x00B48, 0x00B4B, 0x00B4C, 0x00B57, 0x00BBE,
    0x00BBF, 0x00BC1, 0x00BC2, 0x00BC6, 0x00BC7, 0x00BC8, 0x00BCA,
    0x00BCB, 0x00BCC, 0x00BD7, 0x00C01, 0x00C02, 0x00C03, 0x00C41,
    0x00C42, 0x00C43, 0x00C44, 0x00C82, 0x00C83, 0x00CBE, 0x00CC0,
    0x00CC1, 0x00CC2, 0x00CC3, 0x00CC4, 0x00CC7, 0x00CC8, 0x00CCA,
    0x00CCB, 0x00CD5, 0x00CD6, 0x00D02, 0x00D03, 0x00D3E, 0x00D3F,
    0x00D40, 0x00D46, 0x00D47, 0x00D48, 0x00D4A, 0x00D4B, 0x00D4C,
    0x00D57, 0x00D82, 0x00D83, 0x00DCF, 0x00DD0, 0x00DD1, 0x00DD8,
    0x00DD9, 0x00DDA, 0x00DDB, 0x00DDC, 0x00DDD, 0x00DDE, 0x00DDF,
    0x00DF2, 0x00DF3, 0x00F3E, 0x00F3F, 0x00F7F, 0x0102B, 0x0102C,
    0x01031, 0x01038, 0x0103B, 0x0103C, 0x01056, 0x01057, 0x01062,
    0x01063, 0x01064, 0x01067, 0x01068, 0x01069, 0x0106A, 0x0106B,
    0x0106C, 0x0106D, 0x01083, 0x01084, 0x01087, 0x01088, 0x01089,
    0x0108A, 0x0108B, 0x0108C, 0x0108F, 0x0109A, 0x0109B, 0x0109C,
    0x017B6, 0x017BE, 0x017BF, 0x017C0, 0x017C1, 0x017C2, 0x017C3,
    0x017C4, 0x017C5, 0x017C7, 0x017C8, 0x01923, 0x01924, 0x01925,
    0x01926, 0x01929, 0x0192A, 0x0192B, 0x01930, 0x01931, 0x01933,
    0x01934, 0x01935, 0x01936, 0x01937, 0x01938, 0x01A19, 0x01A1A,
    0x01A55, 0x01A57, 0x01A61, 0x01A63, 0x01A64, 0x01A6D, 0x01A6E,
    0x01A6F, 0x01A70, 0x01A71, 0x01A72, 0x01B04, 0x01B35, 0x01B3B,
    0x01B3D, 0x01B3E, 0x01B3F, 0x01B40, 0x01B41, 0x01B43, 0x01B44,
    0x01B82, 0x01BA1, 0x01BA6, 0x01BA7, 0x01BAA, 0x01BE7, 0x01BEA,
    0x01BEB, 0x01BEC, 0x01BEE, 0x01BF2, 0x01BF3, 0x01C24, 0x01C25,
    0x01C26, 0x01C27, 0x01C28, 0x01C29, 0x01C2A, 0x01C2B, 0x01C34,
    0x01C35, 0x01CE1, 0x01CF2, 0x01CF3, 0x01CF7, 0x0302E, 0x0302F,
    0x0A823, 0x0A824, 0x0A827, 0x0A880, 0x0A881, 0x0A8B4, 0x0A8B5,
    0x0A8B6, 0x0A8B7, 0x0A8B8, 0x0A8B9, 0x0A8BA, 0x0A8BB, 0x0A8BC,
    0x0A8BD, 0x0A8BE, 0x0A8BF, 0x0A8C0, 0x0A8C1, 0x0A8C2, 0x0A8C3,
    0x0A952, 0x0A953, 0x0A983, 0x0A9B4, 0x0A9B5, 0x0A9BA, 0x0A9BB,
    0x0A9BD, 0x0A9BE, 0x0A9BF, 0x0A9C0, 0x0AA2F, 0x0AA30, 0x0AA33,
    0x0AA34, 0x0AA4D, 0x0AA7B, 0x0AA7D, 0x0AAEB, 0x0AAEE, 0x0AAEF,
    0x0AAF5, 0x0ABE3, 0x0ABE4, 0x0ABE6, 0x0ABE7, 0x0ABE9, 0x0ABEA,
    0x0ABEC, 0x11000, 0x11002, 0x11082, 0x110B0, 0x110B1, 0x110B2,
    0x110B7, 0x110B8, 0x1112C, 0x11182, 0x111B3, 0x111B4, 0x111B5,
    0x111BF, 0x111C0, 0x1122C, 0x1122D, 0x1122E, 0x11232, 0x11233,
    0x11235, 0x112E0, 0x112E1, 0x112E2, 0x11302, 0x11303, 0x1133E,
    0x1133F, 0x11341, 0x11342, 0x11343, 0x11344, 0x11347, 0x11348,
    0x1134B, 0x1134C, 0x1134D, 0x11357, 0x11362, 0x11363, 0x11435,
    0x11436, 0x11437, 0x11440, 0x11441, 0x11445, 0x114B0, 0x114B1,
    0x114B2, 0x114B9, 0x114BB, 0x114BC, 0x114BD, 0x114BE, 0x114C1,
    0x115AF, 0x115B0, 0x115B1, 0x115B8, 0x115B9, 0x115BA, 0x115BB,
    0x115BE, 0x11630, 0x11631, 0x11632, 0x1163B, 0x1163C, 0x1163E,
    0x116AC, 0x116AE, 0x116AF, 0x116B6, 0x11720, 0x11721, 0x11726,
    0x11A07, 0x11A08, 0x11A39, 0x11A57, 0x11A58, 0x11A97, 0x11C2F,
    0x11C3E, 0x11CA9, 0x11CB1, 0x11CB4, 0x16F51, 0x16F52, 0x16F53,
    0x16F54, 0x16F55, 0x16F56, 0x16F57, 0x16F58, 0x16F59, 0x16F5A,
    0x16F5B, 0x16F5C, 0x16F5D, 0x16F5E, 0x16F5F, 0x16F60, 0x16F61,
    0x16F62, 0x16F63, 0x16F64, 0x16F65, 0x16F66, 0x16F67, 0x16F68,
    0x16F69, 0x16F6A, 0x16F6B, 0x16F6C, 0x16F6D, 0x16F6E, 0x16F6F,
    0x16F70, 0x16F71, 0x16F72, 0x16F73, 0x16F74, 0x16F75, 0x16F76,
    0x16F77, 0x16F78, 0x16F79, 0x16F7A, 0x16F7B, 0x16F7C, 0x16F7D,
    0x16F7E, 0x1D165, 0x1D166, 0x1D16D, 0x1D16E, 0x1D16F, 0x1D170,
    0x1D171, 0x1D172,
  ];
  final Set<int> these = new Set<int>();
  int combiningCount = enclosingCombiningMarks.length + nonspacingCombiningMarks.length;
  if (includeSpacingCombiningMarks)
    combiningCount += spacingCombiningMarks.length;
  for (int count = 0; count < target; count += 1) {
    int characterCode = random.nextInt(combiningCount);
    if (characterCode < enclosingCombiningMarks.length) {
      these.add(enclosingCombiningMarks[characterCode]);
    } else {
      characterCode -= enclosingCombiningMarks.length;
      if (characterCode < nonspacingCombiningMarks.length) {
        these.add(nonspacingCombiningMarks[characterCode]);
      } else {
        characterCode -= nonspacingCombiningMarks.length;
        these.add(spacingCombiningMarks[characterCode]);
      }
    }
  }
  final List<int> characters = <int>[0x41 + random.nextInt(26)];
  characters.addAll(these);
  return new String.fromCharCodes(characters);
}

T pickFromList<T>(math.Random random, List<T> list) {
  return list[random.nextInt(list.length)];
}
