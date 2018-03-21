// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

int seed = 0;

void main() {
  runApp(new MaterialApp(
    title: 'Text tester',
    home: const Home(),
    routes: <String, WidgetBuilder>{
      'underlines': (BuildContext context) => const Underlines(),
      'fallback': (BuildContext context) => const Fallback(),
      'bidi': (BuildContext context) => const Bidi(),
      'fuzzer': (BuildContext context) => new Fuzzer(seed: seed),
      'zalgo': (BuildContext context) => new Zalgo(seed: seed),
      'painting': (BuildContext context) => new Painting(seed: seed),
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
                  color: Colors.red.shade800,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('underlines'); },
                ),
                new FlatButton(
                  child: const Text('Test Font Fallback'),
                  color: Colors.orange.shade700,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('fallback'); },
                ),
                new FlatButton(
                  child: const Text('Test Bidi Formatting'),
                  color: Colors.yellow.shade700,
                  textColor: Colors.black,
                  onPressed: () { Navigator.of(context).pushNamed('bidi'); },
                ),
                new FlatButton(
                  child: const Text('TextSpan Fuzzer'),
                  color: Colors.green.shade400,
                  textColor: Colors.black,
                  onPressed: () { Navigator.of(context).pushNamed('fuzzer'); },
                ),
                new FlatButton(
                  child: const Text('Diacritics Fuzzer'),
                  color: Colors.blue.shade400,
                  textColor: Colors.white,
                  onPressed: () { Navigator.of(context).pushNamed('zalgo'); },
                ),
                new FlatButton(
                  child: const Text('Painting Fuzzer'),
                  color: Colors.purple.shade200,
                  textColor: Colors.black,
                  onPressed: () { Navigator.of(context).pushNamed('painting'); },
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
    _random = new math.Random(widget.seed); // providing a seed is important for reproducibility
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
    switch (_random.nextInt(90)) {
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
      case 74:
      case 75:
      case 76:
      case 77:
      case 78:
      case 79:
      case 80:
      case 81:
      case 82:
        final StringBuffer buffer = new StringBuffer();
        final int targetLength = _random.nextInt(8) + 1;
        for (int index = 0; index < targetLength; index += 1) {
          if (_random.nextInt(20) > 0) {
            buffer.writeCharCode(randomCharacter(_random));
          } else {
            buffer.write(zalgo(_random, _random.nextInt(2) + 1, includeSpacingCombiningMarks: true));
          }
        }
        return buffer.toString();
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
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
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

class Bidi extends StatefulWidget {
  const Bidi({ Key key }) : super(key: key);

  @override
  _BidiState createState() => new _BidiState();
}

class _BidiState extends State<Bidi> {
  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.black,
      child: new ListView(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        children: <Widget>[
          new RichText(
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(text: 'abc', style: new TextStyle(fontWeight: FontWeight.w100, fontSize: 40.0, color: Colors.blue.shade100)),
                new TextSpan(text: 'ghi', style: new TextStyle(fontWeight: FontWeight.w400, fontSize: 40.0, color: Colors.blue.shade500)),
                new TextSpan(text: 'mno', style: new TextStyle(fontWeight: FontWeight.w900, fontSize: 40.0, color: Colors.blue.shade900)),
                new TextSpan(text: 'LKJ', style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 40.0, color: Colors.blue.shade700)),
                new TextSpan(text: 'FED', style: new TextStyle(fontWeight: FontWeight.w300, fontSize: 40.0, color: Colors.blue.shade300)),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          new RichText(
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(text: '${Unicode.LRO}abc', style: new TextStyle(fontWeight: FontWeight.w100, fontSize: 40.0, color: Colors.blue.shade100)),
                new TextSpan(text: '${Unicode.RLO}DEF', style: new TextStyle(fontWeight: FontWeight.w300, fontSize: 40.0, color: Colors.blue.shade300)),
                new TextSpan(text: '${Unicode.LRO}ghi', style: new TextStyle(fontWeight: FontWeight.w400, fontSize: 40.0, color: Colors.blue.shade500)),
                new TextSpan(text: '${Unicode.RLO}JKL', style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 40.0, color: Colors.blue.shade700)),
                new TextSpan(text: '${Unicode.LRO}mno', style: new TextStyle(fontWeight: FontWeight.w900, fontSize: 40.0, color: Colors.blue.shade900)),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 40.0),
          new RichText(
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(text: '${Unicode.LRO}abc${Unicode.RLO}D', style: new TextStyle(fontWeight: FontWeight.w100, fontSize: 40.0, color: Colors.orange.shade100)),
                new TextSpan(text: 'EF${Unicode.LRO}gh', style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 50.0, color: Colors.orange.shade500)),
                new TextSpan(text: 'i${Unicode.RLO}JKL${Unicode.LRO}mno', style: new TextStyle(fontWeight: FontWeight.w900, fontSize: 60.0, color: Colors.orange.shade900)),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          new RichText(
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(text: 'abc', style: new TextStyle(fontWeight: FontWeight.w100, fontSize: 40.0, color: Colors.orange.shade100)),
                new TextSpan(text: 'gh', style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 50.0, color: Colors.orange.shade500)),
                new TextSpan(text: 'imno', style: new TextStyle(fontWeight: FontWeight.w900, fontSize: 60.0, color: Colors.orange.shade900)),
                new TextSpan(text: 'LKJ', style: new TextStyle(fontWeight: FontWeight.w900, fontSize: 60.0, color: Colors.orange.shade900)),
                new TextSpan(text: 'FE', style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 50.0, color: Colors.orange.shade500)),
                new TextSpan(text: 'D', style: new TextStyle(fontWeight: FontWeight.w100, fontSize: 40.0, color: Colors.orange.shade100)),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 40.0),
          const Text('The pairs of lines above should match exactly.', textAlign: TextAlign.center, style: const TextStyle(inherit: false, fontSize: 14.0, color: Colors.white)),
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
    _random = new math.Random(widget.seed); // providing a seed is important for reproducibility
    _ticker = createTicker(_update)..start();
    _update(null);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool _allowSpacing = false;
  bool _varyBase = false;

  void _update(Duration duration) {
    setState(() {
      _text = zalgo(
        _random,
        6 + _random.nextInt(10),
        includeSpacingCombiningMarks: _allowSpacing,
        base: _varyBase ? null : 'O',
      );
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
                      _random = new math.Random(widget.seed); // reset for reproducibility
                    });
                  },
                ),
                new SwitchListTile(
                  title: const Text('Vary base character'),
                  value: _varyBase,
                  onChanged: (bool value) {
                    setState(() {
                      _varyBase = value;
                      _random = new math.Random(widget.seed); // reset for reproducibility
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

class Painting extends StatefulWidget {
  const Painting({ Key key, this.seed }) : super(key: key);

  final int seed;

  @override
  _PaintingState createState() => new _PaintingState();
}

class _PaintingState extends State<Painting> with SingleTickerProviderStateMixin {
  String _text;
  Ticker _ticker;
  math.Random _random;

  @override
  void initState() {
    super.initState();
    _random = new math.Random(widget.seed); // providing a seed is important for reproducibility
    _ticker = createTicker(_update)..start();
    _update(null);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  final GlobalKey intrinsicKey = new GlobalKey();
  final GlobalKey controlKey = new GlobalKey();

  bool _ellipsize = false;

  void _update(Duration duration) {
    setState(() {
      final StringBuffer buffer = new StringBuffer();
      final int targetLength = _random.nextInt(20) + (_ellipsize ? MediaQuery.of(context).size.width.round() : 1);
      for (int index = 0; index < targetLength; index += 1) {
        if (_random.nextInt(5) > 0) {
          buffer.writeCharCode(randomCharacter(_random));
        } else {
          buffer.write(zalgo(_random, _random.nextInt(2) + 1, includeSpacingCombiningMarks: true));
        }
      }
      _text = buffer.toString();
    });
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      if (mounted && intrinsicKey.currentContext.size.height != controlKey.currentContext.size.height) {
        debugPrint('Found some text that unexpectedly renders at different heights.');
        debugPrint('Text: $_text');
        debugPrint(_text.runes.map((int index) => 'U+' + index.toRadixString(16).padLeft(4, '0')).join(' '));
        setState(() {
          _ticker.stop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return new Container(
      color: Colors.black,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Expanded(
            child: new Padding(
              padding: new EdgeInsets.only(top: size.height * 0.1),
              child: new Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  new Positioned(
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: new Align(
                      alignment: Alignment.topCenter,
                      child: new IntrinsicWidth( // to test shrink-wrap vs rendering
                        child: new RichText(
                          key: intrinsicKey,
                          textAlign: TextAlign.center,
                          overflow: _ellipsize ? TextOverflow.ellipsis : TextOverflow.clip,
                          text: new TextSpan(
                            text: _text,
                            style: const TextStyle(
                              inherit: false,
                              fontSize: 28.0,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  new Positioned(
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: new RichText(
                      key: controlKey,
                      textAlign: TextAlign.center,
                      overflow: _ellipsize ? TextOverflow.ellipsis : TextOverflow.clip,
                      text: new TextSpan(
                        text: _text,
                        style: const TextStyle(
                          inherit: false,
                          fontSize: 28.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  title: const Text('Enable Ellipses'),
                  value: _ellipsize,
                  onChanged: (bool value) {
                    setState(() {
                      _ellipsize = value;
                      _random = new math.Random(widget.seed); // reset for reproducibility
                      if (!_ticker.isActive)
                        _update(null);
                    });
                  },
                ),
                const ListTile(
                  title: const Text('There should be no red visible.'),
                ),
                new ButtonBar(
                  children: <Widget>[
                    new FlatButton(
                      onPressed: _ticker.isActive ? null : () => _update(null),
                      child: const Text('ITERATE'),
                    ),
                    new FlatButton(
                      onPressed: _ticker.isActive ? null : () {
                        print('The currently visible text is: $_text');
                        print(_text.runes.map((int value) => 'U+${value.toRadixString(16).padLeft(4, '0').toUpperCase()}').join(' '));
                      },
                      child: const Text('DUMP TEXT TO LOGS'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String zalgo(math.Random random, int targetLength, { bool includeSpacingCombiningMarks: false, String base }) {
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
  for (int count = 0; count < targetLength; count += 1) {
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
  base ??= new String.fromCharCode(randomCharacter(random));
  final List<int> characters = <int>[];
  characters.addAll(these);
  return base + new String.fromCharCodes(characters);
}

T pickFromList<T>(math.Random random, List<T> list) {
  return list[random.nextInt(list.length)];
}

class Range {
  const Range(this.start, this.end);
  final int start;
  final int end;
}

int randomCharacter(math.Random random) {
  // all ranges of non-control, non-combining characters
  const List<Range> characterRanges = const <Range>[
    const Range(0x00020, 0x0007e),
    const Range(0x000a0, 0x000ac),
    const Range(0x000ae, 0x002ff),
    const Range(0x00370, 0x00377),
    const Range(0x0037a, 0x0037f),
    const Range(0x00384, 0x0038a),
    const Range(0x0038c, 0x0038c),
    const Range(0x0038e, 0x003a1),
    const Range(0x003a3, 0x00482),
    const Range(0x0048a, 0x0052f),
    const Range(0x00531, 0x00556),
    const Range(0x00559, 0x0055f),
    const Range(0x00561, 0x00587),
    const Range(0x00589, 0x0058a),
    const Range(0x0058d, 0x0058f),
    const Range(0x005be, 0x005be),
    const Range(0x005c0, 0x005c0),
    const Range(0x005c3, 0x005c3),
    const Range(0x005c6, 0x005c6),
    const Range(0x005d0, 0x005ea),
    const Range(0x005f0, 0x005f4),
    const Range(0x00606, 0x0060f),
    const Range(0x0061b, 0x0061b),
    const Range(0x0061e, 0x0064a),
    const Range(0x00660, 0x0066f),
    const Range(0x00671, 0x006d5),
    const Range(0x006de, 0x006de),
    const Range(0x006e5, 0x006e6),
    const Range(0x006e9, 0x006e9),
    const Range(0x006ee, 0x0070d),
    const Range(0x00710, 0x00710),
    const Range(0x00712, 0x0072f),
    const Range(0x0074d, 0x007a5),
    const Range(0x007b1, 0x007b1),
    const Range(0x007c0, 0x007ea),
    const Range(0x007f4, 0x007fa),
    const Range(0x00800, 0x00815),
    const Range(0x0081a, 0x0081a),
    const Range(0x00824, 0x00824),
    const Range(0x00828, 0x00828),
    const Range(0x00830, 0x0083e),
    const Range(0x00840, 0x00858),
    const Range(0x0085e, 0x0085e),
    const Range(0x00860, 0x0086a),
    const Range(0x008a0, 0x008b4),
    const Range(0x008b6, 0x008bd),
    const Range(0x00904, 0x00939),
    const Range(0x0093d, 0x0093d),
    const Range(0x00950, 0x00950),
    const Range(0x00958, 0x00961),
    const Range(0x00964, 0x00980),
    const Range(0x00985, 0x0098c),
    const Range(0x0098f, 0x00990),
    const Range(0x00993, 0x009a8),
    const Range(0x009aa, 0x009b0),
    const Range(0x009b2, 0x009b2),
    const Range(0x009b6, 0x009b9),
    const Range(0x009bd, 0x009bd),
    const Range(0x009ce, 0x009ce),
    const Range(0x009dc, 0x009dd),
    const Range(0x009df, 0x009e1),
    const Range(0x009e6, 0x009fd),
    const Range(0x00a05, 0x00a0a),
    const Range(0x00a0f, 0x00a10),
    const Range(0x00a13, 0x00a28),
    const Range(0x00a2a, 0x00a30),
    const Range(0x00a32, 0x00a33),
    const Range(0x00a35, 0x00a36),
    const Range(0x00a38, 0x00a39),
    const Range(0x00a59, 0x00a5c),
    const Range(0x00a5e, 0x00a5e),
    const Range(0x00a66, 0x00a6f),
    const Range(0x00a72, 0x00a74),
    const Range(0x00a85, 0x00a8d),
    const Range(0x00a8f, 0x00a91),
    const Range(0x00a93, 0x00aa8),
    const Range(0x00aaa, 0x00ab0),
    const Range(0x00ab2, 0x00ab3),
    const Range(0x00ab5, 0x00ab9),
    const Range(0x00abd, 0x00abd),
    const Range(0x00ad0, 0x00ad0),
    const Range(0x00ae0, 0x00ae1),
    const Range(0x00ae6, 0x00af1),
    const Range(0x00af9, 0x00af9),
    const Range(0x00b05, 0x00b0c),
    const Range(0x00b0f, 0x00b10),
    const Range(0x00b13, 0x00b28),
    const Range(0x00b2a, 0x00b30),
    const Range(0x00b32, 0x00b33),
    const Range(0x00b35, 0x00b39),
    const Range(0x00b3d, 0x00b3d),
    const Range(0x00b5c, 0x00b5d),
    const Range(0x00b5f, 0x00b61),
    const Range(0x00b66, 0x00b77),
    const Range(0x00b83, 0x00b83),
    const Range(0x00b85, 0x00b8a),
    const Range(0x00b8e, 0x00b90),
    const Range(0x00b92, 0x00b95),
    const Range(0x00b99, 0x00b9a),
    const Range(0x00b9c, 0x00b9c),
    const Range(0x00b9e, 0x00b9f),
    const Range(0x00ba3, 0x00ba4),
    const Range(0x00ba8, 0x00baa),
    const Range(0x00bae, 0x00bb9),
    const Range(0x00bd0, 0x00bd0),
    const Range(0x00be6, 0x00bfa),
    const Range(0x00c05, 0x00c0c),
    const Range(0x00c0e, 0x00c10),
    const Range(0x00c12, 0x00c28),
    const Range(0x00c2a, 0x00c39),
    const Range(0x00c3d, 0x00c3d),
    const Range(0x00c58, 0x00c5a),
    const Range(0x00c60, 0x00c61),
    const Range(0x00c66, 0x00c6f),
    const Range(0x00c78, 0x00c80),
    const Range(0x00c85, 0x00c8c),
    const Range(0x00c8e, 0x00c90),
    const Range(0x00c92, 0x00ca8),
    const Range(0x00caa, 0x00cb3),
    const Range(0x00cb5, 0x00cb9),
    const Range(0x00cbd, 0x00cbd),
    const Range(0x00cde, 0x00cde),
    const Range(0x00ce0, 0x00ce1),
    const Range(0x00ce6, 0x00cef),
    const Range(0x00cf1, 0x00cf2),
    const Range(0x00d05, 0x00d0c),
    const Range(0x00d0e, 0x00d10),
    const Range(0x00d12, 0x00d3a),
    const Range(0x00d3d, 0x00d3d),
    const Range(0x00d4e, 0x00d4f),
    const Range(0x00d54, 0x00d56),
    const Range(0x00d58, 0x00d61),
    const Range(0x00d66, 0x00d7f),
    const Range(0x00d85, 0x00d96),
    const Range(0x00d9a, 0x00db1),
    const Range(0x00db3, 0x00dbb),
    const Range(0x00dbd, 0x00dbd),
    const Range(0x00dc0, 0x00dc6),
    const Range(0x00de6, 0x00def),
    const Range(0x00df4, 0x00df4),
    const Range(0x00e01, 0x00e30),
    const Range(0x00e32, 0x00e33),
    const Range(0x00e3f, 0x00e46),
    const Range(0x00e4f, 0x00e5b),
    const Range(0x00e81, 0x00e82),
    const Range(0x00e84, 0x00e84),
    const Range(0x00e87, 0x00e88),
    const Range(0x00e8a, 0x00e8a),
    const Range(0x00e8d, 0x00e8d),
    const Range(0x00e94, 0x00e97),
    const Range(0x00e99, 0x00e9f),
    const Range(0x00ea1, 0x00ea3),
    const Range(0x00ea5, 0x00ea5),
    const Range(0x00ea7, 0x00ea7),
    const Range(0x00eaa, 0x00eab),
    const Range(0x00ead, 0x00eb0),
    const Range(0x00eb2, 0x00eb3),
    const Range(0x00ebd, 0x00ebd),
    const Range(0x00ec0, 0x00ec4),
    const Range(0x00ec6, 0x00ec6),
    const Range(0x00ed0, 0x00ed9),
    const Range(0x00edc, 0x00edf),
    const Range(0x00f00, 0x00f17),
    const Range(0x00f1a, 0x00f34),
    const Range(0x00f36, 0x00f36),
    const Range(0x00f38, 0x00f38),
    const Range(0x00f3a, 0x00f3d),
    const Range(0x00f40, 0x00f47),
    const Range(0x00f49, 0x00f6c),
    const Range(0x00f85, 0x00f85),
    const Range(0x00f88, 0x00f8c),
    const Range(0x00fbe, 0x00fc5),
    const Range(0x00fc7, 0x00fcc),
    const Range(0x00fce, 0x00fda),
    const Range(0x01000, 0x0102a),
    const Range(0x0103f, 0x01055),
    const Range(0x0105a, 0x0105d),
    const Range(0x01061, 0x01061),
    const Range(0x01065, 0x01066),
    const Range(0x0106e, 0x01070),
    const Range(0x01075, 0x01081),
    const Range(0x0108e, 0x0108e),
    const Range(0x01090, 0x01099),
    const Range(0x0109e, 0x010c5),
    const Range(0x010c7, 0x010c7),
    const Range(0x010cd, 0x010cd),
    const Range(0x010d0, 0x01248),
    const Range(0x0124a, 0x0124d),
    const Range(0x01250, 0x01256),
    const Range(0x01258, 0x01258),
    const Range(0x0125a, 0x0125d),
    const Range(0x01260, 0x01288),
    const Range(0x0128a, 0x0128d),
    const Range(0x01290, 0x012b0),
    const Range(0x012b2, 0x012b5),
    const Range(0x012b8, 0x012be),
    const Range(0x012c0, 0x012c0),
    const Range(0x012c2, 0x012c5),
    const Range(0x012c8, 0x012d6),
    const Range(0x012d8, 0x01310),
    const Range(0x01312, 0x01315),
    const Range(0x01318, 0x0135a),
    const Range(0x01360, 0x0137c),
    const Range(0x01380, 0x01399),
    const Range(0x013a0, 0x013f5),
    const Range(0x013f8, 0x013fd),
    const Range(0x01400, 0x0169c),
    const Range(0x016a0, 0x016f8),
    const Range(0x01700, 0x0170c),
    const Range(0x0170e, 0x01711),
    const Range(0x01720, 0x01731),
    const Range(0x01735, 0x01736),
    const Range(0x01740, 0x01751),
    const Range(0x01760, 0x0176c),
    const Range(0x0176e, 0x01770),
    const Range(0x01780, 0x017b3),
    const Range(0x017d4, 0x017dc),
    const Range(0x017e0, 0x017e9),
    const Range(0x017f0, 0x017f9),
    const Range(0x01800, 0x0180a),
    const Range(0x01810, 0x01819),
    const Range(0x01820, 0x01877),
    const Range(0x01880, 0x01884),
    const Range(0x01887, 0x018a8),
    const Range(0x018aa, 0x018aa),
    const Range(0x018b0, 0x018f5),
    const Range(0x01900, 0x0191e),
    const Range(0x01940, 0x01940),
    const Range(0x01944, 0x0196d),
    const Range(0x01970, 0x01974),
    const Range(0x01980, 0x019ab),
    const Range(0x019b0, 0x019c9),
    const Range(0x019d0, 0x019da),
    const Range(0x019de, 0x01a16),
    const Range(0x01a1e, 0x01a54),
    const Range(0x01a80, 0x01a89),
    const Range(0x01a90, 0x01a99),
    const Range(0x01aa0, 0x01aad),
    const Range(0x01b05, 0x01b33),
    const Range(0x01b45, 0x01b4b),
    const Range(0x01b50, 0x01b6a),
    const Range(0x01b74, 0x01b7c),
    const Range(0x01b83, 0x01ba0),
    const Range(0x01bae, 0x01be5),
    const Range(0x01bfc, 0x01c23),
    const Range(0x01c3b, 0x01c49),
    const Range(0x01c4d, 0x01c88),
    const Range(0x01cc0, 0x01cc7),
    const Range(0x01cd3, 0x01cd3),
    const Range(0x01ce9, 0x01cec),
    const Range(0x01cee, 0x01cf1),
    const Range(0x01cf5, 0x01cf6),
    const Range(0x01d00, 0x01dbf),
    const Range(0x01e00, 0x01f15),
    const Range(0x01f18, 0x01f1d),
    const Range(0x01f20, 0x01f45),
    const Range(0x01f48, 0x01f4d),
    const Range(0x01f50, 0x01f57),
    const Range(0x01f59, 0x01f59),
    const Range(0x01f5b, 0x01f5b),
    const Range(0x01f5d, 0x01f5d),
    const Range(0x01f5f, 0x01f7d),
    const Range(0x01f80, 0x01fb4),
    const Range(0x01fb6, 0x01fc4),
    const Range(0x01fc6, 0x01fd3),
    const Range(0x01fd6, 0x01fdb),
    const Range(0x01fdd, 0x01fef),
    const Range(0x01ff2, 0x01ff4),
    const Range(0x01ff6, 0x01ffe),
    const Range(0x02000, 0x0200a),
    const Range(0x02010, 0x02029),
    const Range(0x0202f, 0x0205f),
    const Range(0x02070, 0x02071),
    const Range(0x02074, 0x0208e),
    const Range(0x02090, 0x0209c),
    const Range(0x020a0, 0x020bf),
    const Range(0x02100, 0x0218b),
    const Range(0x02190, 0x02426),
    const Range(0x02440, 0x0244a),
    const Range(0x02460, 0x02b73),
    const Range(0x02b76, 0x02b95),
    const Range(0x02b98, 0x02bb9),
    const Range(0x02bbd, 0x02bc8),
    const Range(0x02bca, 0x02bd2),
    const Range(0x02bec, 0x02bef),
    const Range(0x02c00, 0x02c2e),
    const Range(0x02c30, 0x02c5e),
    const Range(0x02c60, 0x02cee),
    const Range(0x02cf2, 0x02cf3),
    const Range(0x02cf9, 0x02d25),
    const Range(0x02d27, 0x02d27),
    const Range(0x02d2d, 0x02d2d),
    const Range(0x02d30, 0x02d67),
    const Range(0x02d6f, 0x02d70),
    const Range(0x02d80, 0x02d96),
    const Range(0x02da0, 0x02da6),
    const Range(0x02da8, 0x02dae),
    const Range(0x02db0, 0x02db6),
    const Range(0x02db8, 0x02dbe),
    const Range(0x02dc0, 0x02dc6),
    const Range(0x02dc8, 0x02dce),
    const Range(0x02dd0, 0x02dd6),
    const Range(0x02dd8, 0x02dde),
    const Range(0x02e00, 0x02e49),
    const Range(0x02e80, 0x02e99),
    const Range(0x02e9b, 0x02ef3),
    const Range(0x02f00, 0x02fd5),
    const Range(0x02ff0, 0x02ffb),
    const Range(0x03000, 0x03029),
    const Range(0x03030, 0x0303f),
    const Range(0x03041, 0x03096),
    const Range(0x0309b, 0x030ff),
    const Range(0x03105, 0x0312e),
    const Range(0x03131, 0x0318e),
    const Range(0x03190, 0x031ba),
    const Range(0x031c0, 0x031e3),
    const Range(0x031f0, 0x0321e),
    const Range(0x03220, 0x032fe),
    const Range(0x03300, 0x04db5),
    const Range(0x04dc0, 0x09fea),
    const Range(0x0a000, 0x0a48c),
    const Range(0x0a490, 0x0a4c6),
    const Range(0x0a4d0, 0x0a62b),
    const Range(0x0a640, 0x0a66e),
    const Range(0x0a673, 0x0a673),
    const Range(0x0a67e, 0x0a69d),
    const Range(0x0a6a0, 0x0a6ef),
    const Range(0x0a6f2, 0x0a6f7),
    const Range(0x0a700, 0x0a7ae),
    const Range(0x0a7b0, 0x0a7b7),
    const Range(0x0a7f7, 0x0a801),
    const Range(0x0a803, 0x0a805),
    const Range(0x0a807, 0x0a80a),
    const Range(0x0a80c, 0x0a822),
    const Range(0x0a828, 0x0a82b),
    const Range(0x0a830, 0x0a839),
    const Range(0x0a840, 0x0a877),
    const Range(0x0a882, 0x0a8b3),
    const Range(0x0a8ce, 0x0a8d9),
    const Range(0x0a8f2, 0x0a8fd),
    const Range(0x0a900, 0x0a925),
    const Range(0x0a92e, 0x0a946),
    const Range(0x0a95f, 0x0a97c),
    const Range(0x0a984, 0x0a9b2),
    const Range(0x0a9c1, 0x0a9cd),
    const Range(0x0a9cf, 0x0a9d9),
    const Range(0x0a9de, 0x0a9e4),
    const Range(0x0a9e6, 0x0a9fe),
    const Range(0x0aa00, 0x0aa28),
    const Range(0x0aa40, 0x0aa42),
    const Range(0x0aa44, 0x0aa4b),
    const Range(0x0aa50, 0x0aa59),
    const Range(0x0aa5c, 0x0aa7a),
    const Range(0x0aa7e, 0x0aaaf),
    const Range(0x0aab1, 0x0aab1),
    const Range(0x0aab5, 0x0aab6),
    const Range(0x0aab9, 0x0aabd),
    const Range(0x0aac0, 0x0aac0),
    const Range(0x0aac2, 0x0aac2),
    const Range(0x0aadb, 0x0aaea),
    const Range(0x0aaf0, 0x0aaf4),
    const Range(0x0ab01, 0x0ab06),
    const Range(0x0ab09, 0x0ab0e),
    const Range(0x0ab11, 0x0ab16),
    const Range(0x0ab20, 0x0ab26),
    const Range(0x0ab28, 0x0ab2e),
    const Range(0x0ab30, 0x0ab65),
    const Range(0x0ab70, 0x0abe2),
    const Range(0x0abeb, 0x0abeb),
    const Range(0x0abf0, 0x0abf9),
    const Range(0x0ac00, 0x0d7a3),
    const Range(0x0d7b0, 0x0d7c6),
    const Range(0x0d7cb, 0x0d7fb),
    const Range(0x0f900, 0x0fa6d),
    const Range(0x0fa70, 0x0fad9),
    const Range(0x0fb00, 0x0fb06),
    const Range(0x0fb13, 0x0fb17),
    const Range(0x0fb1d, 0x0fb1d),
    const Range(0x0fb1f, 0x0fb36),
    const Range(0x0fb38, 0x0fb3c),
    const Range(0x0fb3e, 0x0fb3e),
    const Range(0x0fb40, 0x0fb41),
    const Range(0x0fb43, 0x0fb44),
    const Range(0x0fb46, 0x0fbc1),
    const Range(0x0fbd3, 0x0fd3f),
    const Range(0x0fd50, 0x0fd8f),
    const Range(0x0fd92, 0x0fdc7),
    const Range(0x0fdf0, 0x0fdfd),
    const Range(0x0fe10, 0x0fe19),
    const Range(0x0fe30, 0x0fe52),
    const Range(0x0fe54, 0x0fe66),
    const Range(0x0fe68, 0x0fe6b),
    const Range(0x0fe70, 0x0fe74),
    const Range(0x0fe76, 0x0fefc),
    const Range(0x0ff01, 0x0ffbe),
    const Range(0x0ffc2, 0x0ffc7),
    const Range(0x0ffca, 0x0ffcf),
    const Range(0x0ffd2, 0x0ffd7),
    const Range(0x0ffda, 0x0ffdc),
    const Range(0x0ffe0, 0x0ffe6),
    const Range(0x0ffe8, 0x0ffee),
    const Range(0x0fffc, 0x0fffd),
    const Range(0x10000, 0x1000b),
    const Range(0x1000d, 0x10026),
    const Range(0x10028, 0x1003a),
    const Range(0x1003c, 0x1003d),
    const Range(0x1003f, 0x1004d),
    const Range(0x10050, 0x1005d),
    const Range(0x10080, 0x100fa),
    const Range(0x10100, 0x10102),
    const Range(0x10107, 0x10133),
    const Range(0x10137, 0x1018e),
    const Range(0x10190, 0x1019b),
    const Range(0x101a0, 0x101a0),
    const Range(0x101d0, 0x101fc),
    const Range(0x10280, 0x1029c),
    const Range(0x102a0, 0x102d0),
    const Range(0x102e1, 0x102fb),
    const Range(0x10300, 0x10323),
    const Range(0x1032d, 0x1034a),
    const Range(0x10350, 0x10375),
    const Range(0x10380, 0x1039d),
    const Range(0x1039f, 0x103c3),
    const Range(0x103c8, 0x103d5),
    const Range(0x10400, 0x1049d),
    const Range(0x104a0, 0x104a9),
    const Range(0x104b0, 0x104d3),
    const Range(0x104d8, 0x104fb),
    const Range(0x10500, 0x10527),
    const Range(0x10530, 0x10563),
    const Range(0x1056f, 0x1056f),
    const Range(0x10600, 0x10736),
    const Range(0x10740, 0x10755),
    const Range(0x10760, 0x10767),
    const Range(0x10800, 0x10805),
    const Range(0x10808, 0x10808),
    const Range(0x1080a, 0x10835),
    const Range(0x10837, 0x10838),
    const Range(0x1083c, 0x1083c),
    const Range(0x1083f, 0x10855),
    const Range(0x10857, 0x1089e),
    const Range(0x108a7, 0x108af),
    const Range(0x108e0, 0x108f2),
    const Range(0x108f4, 0x108f5),
    const Range(0x108fb, 0x1091b),
    const Range(0x1091f, 0x10939),
    const Range(0x1093f, 0x1093f),
    const Range(0x10980, 0x109b7),
    const Range(0x109bc, 0x109cf),
    const Range(0x109d2, 0x10a00),
    const Range(0x10a10, 0x10a13),
    const Range(0x10a15, 0x10a17),
    const Range(0x10a19, 0x10a33),
    const Range(0x10a40, 0x10a47),
    const Range(0x10a50, 0x10a58),
    const Range(0x10a60, 0x10a9f),
    const Range(0x10ac0, 0x10ae4),
    const Range(0x10aeb, 0x10af6),
    const Range(0x10b00, 0x10b35),
    const Range(0x10b39, 0x10b55),
    const Range(0x10b58, 0x10b72),
    const Range(0x10b78, 0x10b91),
    const Range(0x10b99, 0x10b9c),
    const Range(0x10ba9, 0x10baf),
    const Range(0x10c00, 0x10c48),
    const Range(0x10c80, 0x10cb2),
    const Range(0x10cc0, 0x10cf2),
    const Range(0x10cfa, 0x10cff),
    const Range(0x10e60, 0x10e7e),
    const Range(0x11003, 0x11037),
    const Range(0x11047, 0x1104d),
    const Range(0x11052, 0x1106f),
    const Range(0x11083, 0x110af),
    const Range(0x110bb, 0x110bc),
    const Range(0x110be, 0x110c1),
    const Range(0x110d0, 0x110e8),
    const Range(0x110f0, 0x110f9),
    const Range(0x11103, 0x11126),
    const Range(0x11136, 0x11143),
    const Range(0x11150, 0x11172),
    const Range(0x11174, 0x11176),
    const Range(0x11183, 0x111b2),
    const Range(0x111c1, 0x111c9),
    const Range(0x111cd, 0x111cd),
    const Range(0x111d0, 0x111df),
    const Range(0x111e1, 0x111f4),
    const Range(0x11200, 0x11211),
    const Range(0x11213, 0x1122b),
    const Range(0x11238, 0x1123d),
    const Range(0x11280, 0x11286),
    const Range(0x11288, 0x11288),
    const Range(0x1128a, 0x1128d),
    const Range(0x1128f, 0x1129d),
    const Range(0x1129f, 0x112a9),
    const Range(0x112b0, 0x112de),
    const Range(0x112f0, 0x112f9),
    const Range(0x11305, 0x1130c),
    const Range(0x1130f, 0x11310),
    const Range(0x11313, 0x11328),
    const Range(0x1132a, 0x11330),
    const Range(0x11332, 0x11333),
    const Range(0x11335, 0x11339),
    const Range(0x1133d, 0x1133d),
    const Range(0x11350, 0x11350),
    const Range(0x1135d, 0x11361),
    const Range(0x11400, 0x11434),
    const Range(0x11447, 0x11459),
    const Range(0x1145b, 0x1145b),
    const Range(0x1145d, 0x1145d),
    const Range(0x11480, 0x114af),
    const Range(0x114c4, 0x114c7),
    const Range(0x114d0, 0x114d9),
    const Range(0x11580, 0x115ae),
    const Range(0x115c1, 0x115db),
    const Range(0x11600, 0x1162f),
    const Range(0x11641, 0x11644),
    const Range(0x11650, 0x11659),
    const Range(0x11660, 0x1166c),
    const Range(0x11680, 0x116aa),
    const Range(0x116c0, 0x116c9),
    const Range(0x11700, 0x11719),
    const Range(0x11730, 0x1173f),
    const Range(0x118a0, 0x118f2),
    const Range(0x118ff, 0x118ff),
    const Range(0x11a00, 0x11a00),
    const Range(0x11a0b, 0x11a32),
    const Range(0x11a3a, 0x11a3a),
    const Range(0x11a3f, 0x11a46),
    const Range(0x11a50, 0x11a50),
    const Range(0x11a5c, 0x11a83),
    const Range(0x11a86, 0x11a89),
    const Range(0x11a9a, 0x11a9c),
    const Range(0x11a9e, 0x11aa2),
    const Range(0x11ac0, 0x11af8),
    const Range(0x11c00, 0x11c08),
    const Range(0x11c0a, 0x11c2e),
    const Range(0x11c40, 0x11c45),
    const Range(0x11c50, 0x11c6c),
    const Range(0x11c70, 0x11c8f),
    const Range(0x11d00, 0x11d06),
    const Range(0x11d08, 0x11d09),
    const Range(0x11d0b, 0x11d30),
    const Range(0x11d46, 0x11d46),
    const Range(0x11d50, 0x11d59),
    const Range(0x12000, 0x12399),
    const Range(0x12400, 0x1246e),
    const Range(0x12470, 0x12474),
    const Range(0x12480, 0x12543),
    const Range(0x13000, 0x1342e),
    const Range(0x14400, 0x14646),
    const Range(0x16800, 0x16a38),
    const Range(0x16a40, 0x16a5e),
    const Range(0x16a60, 0x16a69),
    const Range(0x16a6e, 0x16a6f),
    const Range(0x16ad0, 0x16aed),
    const Range(0x16af5, 0x16af5),
    const Range(0x16b00, 0x16b2f),
    const Range(0x16b37, 0x16b45),
    const Range(0x16b50, 0x16b59),
    const Range(0x16b5b, 0x16b61),
    const Range(0x16b63, 0x16b77),
    const Range(0x16b7d, 0x16b8f),
    const Range(0x16f00, 0x16f44),
    const Range(0x16f50, 0x16f50),
    const Range(0x16f93, 0x16f9f),
    const Range(0x16fe0, 0x16fe1),
    const Range(0x17000, 0x187ec),
    const Range(0x18800, 0x18af2),
    const Range(0x1b000, 0x1b11e),
    const Range(0x1b170, 0x1b2fb),
    const Range(0x1bc00, 0x1bc6a),
    const Range(0x1bc70, 0x1bc7c),
    const Range(0x1bc80, 0x1bc88),
    const Range(0x1bc90, 0x1bc99),
    const Range(0x1bc9c, 0x1bc9c),
    const Range(0x1bc9f, 0x1bc9f),
    const Range(0x1d000, 0x1d0f5),
    const Range(0x1d100, 0x1d126),
    const Range(0x1d129, 0x1d164),
    const Range(0x1d16a, 0x1d16c),
    const Range(0x1d183, 0x1d184),
    const Range(0x1d18c, 0x1d1a9),
    const Range(0x1d1ae, 0x1d1e8),
    const Range(0x1d200, 0x1d241),
    const Range(0x1d245, 0x1d245),
    const Range(0x1d300, 0x1d356),
    const Range(0x1d360, 0x1d371),
    const Range(0x1d400, 0x1d454),
    const Range(0x1d456, 0x1d49c),
    const Range(0x1d49e, 0x1d49f),
    const Range(0x1d4a2, 0x1d4a2),
    const Range(0x1d4a5, 0x1d4a6),
    const Range(0x1d4a9, 0x1d4ac),
    const Range(0x1d4ae, 0x1d4b9),
    const Range(0x1d4bb, 0x1d4bb),
    const Range(0x1d4bd, 0x1d4c3),
    const Range(0x1d4c5, 0x1d505),
    const Range(0x1d507, 0x1d50a),
    const Range(0x1d50d, 0x1d514),
    const Range(0x1d516, 0x1d51c),
    const Range(0x1d51e, 0x1d539),
    const Range(0x1d53b, 0x1d53e),
    const Range(0x1d540, 0x1d544),
    const Range(0x1d546, 0x1d546),
    const Range(0x1d54a, 0x1d550),
    const Range(0x1d552, 0x1d6a5),
    const Range(0x1d6a8, 0x1d7cb),
    const Range(0x1d7ce, 0x1d9ff),
    const Range(0x1da37, 0x1da3a),
    const Range(0x1da6d, 0x1da74),
    const Range(0x1da76, 0x1da83),
    const Range(0x1da85, 0x1da8b),
    const Range(0x1e800, 0x1e8c4),
    const Range(0x1e8c7, 0x1e8cf),
    const Range(0x1e900, 0x1e943),
    const Range(0x1e950, 0x1e959),
    const Range(0x1e95e, 0x1e95f),
    const Range(0x1ee00, 0x1ee03),
    const Range(0x1ee05, 0x1ee1f),
    const Range(0x1ee21, 0x1ee22),
    const Range(0x1ee24, 0x1ee24),
    const Range(0x1ee27, 0x1ee27),
    const Range(0x1ee29, 0x1ee32),
    const Range(0x1ee34, 0x1ee37),
    const Range(0x1ee39, 0x1ee39),
    const Range(0x1ee3b, 0x1ee3b),
    const Range(0x1ee42, 0x1ee42),
    const Range(0x1ee47, 0x1ee47),
    const Range(0x1ee49, 0x1ee49),
    const Range(0x1ee4b, 0x1ee4b),
    const Range(0x1ee4d, 0x1ee4f),
    const Range(0x1ee51, 0x1ee52),
    const Range(0x1ee54, 0x1ee54),
    const Range(0x1ee57, 0x1ee57),
    const Range(0x1ee59, 0x1ee59),
    const Range(0x1ee5b, 0x1ee5b),
    const Range(0x1ee5d, 0x1ee5d),
    const Range(0x1ee5f, 0x1ee5f),
    const Range(0x1ee61, 0x1ee62),
    const Range(0x1ee64, 0x1ee64),
    const Range(0x1ee67, 0x1ee6a),
    const Range(0x1ee6c, 0x1ee72),
    const Range(0x1ee74, 0x1ee77),
    const Range(0x1ee79, 0x1ee7c),
    const Range(0x1ee7e, 0x1ee7e),
    const Range(0x1ee80, 0x1ee89),
    const Range(0x1ee8b, 0x1ee9b),
    const Range(0x1eea1, 0x1eea3),
    const Range(0x1eea5, 0x1eea9),
    const Range(0x1eeab, 0x1eebb),
    const Range(0x1eef0, 0x1eef1),
    const Range(0x1f000, 0x1f02b),
    const Range(0x1f030, 0x1f093),
    const Range(0x1f0a0, 0x1f0ae),
    const Range(0x1f0b1, 0x1f0bf),
    const Range(0x1f0c1, 0x1f0cf),
    const Range(0x1f0d1, 0x1f0f5),
    const Range(0x1f100, 0x1f10c),
    const Range(0x1f110, 0x1f12e),
    const Range(0x1f130, 0x1f16b),
    const Range(0x1f170, 0x1f1ac),
    const Range(0x1f1e6, 0x1f202),
    const Range(0x1f210, 0x1f23b),
    const Range(0x1f240, 0x1f248),
    const Range(0x1f250, 0x1f251),
    const Range(0x1f260, 0x1f265),
    const Range(0x1f300, 0x1f6d4),
    const Range(0x1f6e0, 0x1f6ec),
    const Range(0x1f6f0, 0x1f6f8),
    const Range(0x1f700, 0x1f773),
    const Range(0x1f780, 0x1f7d4),
    const Range(0x1f800, 0x1f80b),
    const Range(0x1f810, 0x1f847),
    const Range(0x1f850, 0x1f859),
    const Range(0x1f860, 0x1f887),
    const Range(0x1f890, 0x1f8ad),
    const Range(0x1f900, 0x1f90b),
    const Range(0x1f910, 0x1f93e),
    const Range(0x1f940, 0x1f94c),
    const Range(0x1f950, 0x1f96b),
    const Range(0x1f980, 0x1f997),
    const Range(0x1f9c0, 0x1f9c0),
    const Range(0x1f9d0, 0x1f9e6),
    const Range(0x20000, 0x2a6d6),
    const Range(0x2a700, 0x2b734),
    const Range(0x2b740, 0x2b81d),
    const Range(0x2b820, 0x2cea1),
    const Range(0x2ceb0, 0x2ebe0),
    const Range(0x2f800, 0x2fa1d),
  ];
  final Range range = pickFromList(random, characterRanges);
  if (range.start == range.end)
    return range.start;
  return range.start + random.nextInt(range.end - range.start);
}