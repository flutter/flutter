// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'calc_expression.dart';

// A calculator application.
void main() {
  runApp(new MaterialApp(
      title: 'Calculator',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Calculator()));
}

class Calculator extends StatefulWidget {
  Calculator({Key key}) : super(key: key);

  @override
  _CalculatorState createState() => new _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  // As the user taps keys we update the current |_expression| and we also
  // keep a stack of previous expressions so we can return to earlier states
  // when the user hits the DEL key.
  List<CalcExpression> _expressionStack = <CalcExpression>[];
  CalcExpression _expression = new CalcExpression.Empty();

  // Make |expression| the current expression and push the previous current
  // expression onto the stack.
  pushExpression(CalcExpression expression) {
    _expressionStack.add(_expression);
    _expression = expression;
  }

  // Pop the top expression off of the stack and make it the current expression.
  popCalcExpression() {
    if (_expressionStack.length > 0) {
      _expression = _expressionStack.removeLast();
    } else {
      _expression = new CalcExpression.Empty();
    }
  }

  // Set |resultExpression| to the currrent expression and clear the stack.
  setResult(CalcExpression resultExpression) {
    _expressionStack.clear();
    _expression = resultExpression;
  }

  onNumberTap(int n) {
    var expression = _expression.appendDigit(n);
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onPointTap() {
    var expression = _expression.appendPoint();
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onPlusTap() {
    var expression = _expression.appendOperation(Operation.Addition);
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onMinusTap() {
    var expression = _expression.appendMinus();
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onMultTap() {
    var expression = _expression.appendOperation(Operation.Multiplication);
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onDivTap() {
    var expression = _expression.appendOperation(Operation.Division);
    if (expression != null) {
      setState(() {
        pushExpression(expression);
      });
    }
  }

  onEqualsTap() {
    var resultExpression = _expression.computeResult();
    if (resultExpression != null) {
      setState(() {
        setResult(resultExpression);
      });
    }
  }

  onDelTap() {
    setState(() {
      popCalcExpression();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text('Calculator')),
        body: new Column(children: <Widget>[
          // Give the key-pad 3/5 of the vertical space and the display
          // 2/5.
          new CalcDisplay(2, _expression.toString()),
          new KeyPad(3, calcState: this)
        ]));
  }
}

class CalcDisplay extends StatelessWidget {
  CalcDisplay(this._flex, this._contents);

  int _flex;
  String _contents;

  @override
  Widget build(BuildContext context) {
    return new Flexible(
        flex: _flex,
        child: new Center(child: new Text(_contents,
            style: new TextStyle(color: Colors.black, fontSize: 24.0))));
  }
}

class KeyPad extends StatelessWidget {
  KeyPad(this._flex, {this.calcState});

  final int _flex;
  final _CalculatorState calcState;

  Widget build(BuildContext context) {
    return new Flexible(
        flex: _flex,
        child: new Row(children: <Widget>[
          new MainKeyPad(calcState: calcState),
          new OpKeyPad(calcState: calcState),
        ]));
  }
}

class MainKeyPad extends StatelessWidget {
  final _CalculatorState calcState;

  MainKeyPad({this.calcState});

  Widget build(BuildContext context) {
    return new Flexible(
        // We set flex equal to the number of columns so that the main keypad
        // and the op keypad have sizes proportional to their number of
        // columns.
        flex: 3,
        child: new Material(
            type: MaterialType.canvas,
            elevation: 12,
            color: Colors.grey[800],
            child: new Column(children: <Widget>[
              new KeyRow(<Widget>[
                new NumberKey(7, calcState),
                new NumberKey(8, calcState),
                new NumberKey(9, calcState)
              ]),
              new KeyRow(<Widget>[
                new NumberKey(4, calcState),
                new NumberKey(5, calcState),
                new NumberKey(6, calcState)
              ]),
              new KeyRow(<Widget>[
                new NumberKey(1, calcState),
                new NumberKey(2, calcState),
                new NumberKey(3, calcState)
              ]),
              new KeyRow(<Widget>[
                new CalcKey(".", calcState.onPointTap),
                new NumberKey(0, calcState),
                new CalcKey("=", calcState.onEqualsTap),
              ])
            ])));
  }
}

class OpKeyPad extends StatelessWidget {
  final _CalculatorState calcState;

  OpKeyPad({this.calcState});

  Widget build(BuildContext context) {
    return new Flexible(child: new Material(
        type: MaterialType.canvas,
        elevation: 24,
        color: Colors.grey[700],
        child: new Column(children: <Widget>[
          new CalcKey("DEL", calcState.onDelTap),
          new CalcKey("\u00F7", calcState.onDivTap),
          new CalcKey("\u00D7", calcState.onMultTap),
          new CalcKey("-", calcState.onMinusTap),
          new CalcKey("+", calcState.onPlusTap)
        ])));
  }
}

class KeyRow extends StatelessWidget {
  List<Widget> keys;

  KeyRow(this.keys);

  Widget build(BuildContext context) {
    return new Flexible(child: new Row(
        mainAxisAlignment: MainAxisAlignment.center, children: this.keys));
  }
}

class CalcKey extends StatelessWidget {
  String text;
  GestureTapCallback onTap;
  CalcKey(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return new Flexible(child: new Container(
        child: new InkResponse(
            onTap: this.onTap,
            child: new Center(child: new Text(this.text,
                style: new TextStyle(
                    color: Colors.white,
                    fontSize: 32.0))))));
  }
}

class NumberKey extends CalcKey {
  NumberKey(int value, _CalculatorState calcState)
      : super("$value", () {
          calcState.onNumberTap(value);
        });
}
