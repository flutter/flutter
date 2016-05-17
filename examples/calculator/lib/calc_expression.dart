// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A token that composes an expression. There are several kinds of tokens
/// that represent arithmetic operation symbols, numbers and pieces of numbers.
/// We need to represent pieces of numbers because the user may have only
/// entered a partial expression so far.
class ExpressionToken {
  String stringRep;

  ExpressionToken(this.stringRep);

  String toString() {
    return stringRep;
  }
}

// A token that represents an integer.
class IntToken extends ExpressionToken {
  int number;

  IntToken(String stringRep) : super(stringRep) {
    number = int.parse(stringRep);
  }
}

// A token that represents a floating point number.
class FloatToken extends ExpressionToken {
  double number;

  FloatToken(String stringRep) : super(stringRep) {
    var toParse = stringRep;
    if (toParse.startsWith(".")) {
      toParse = "0" + toParse;
    }
    if (toParse.endsWith(".")) {
      toParse = toParse + "0";
    }
    number = double.parse(toParse);
  }
}

// A token that represents a number that is the result of a computation.
class ResultToken extends ExpressionToken {
  num number;

  ResultToken(num number)
      : super("$number"),
        this.number = number;
}

// A token that represents the unary minus prefix.
class LeadingNegToken extends ExpressionToken {
  LeadingNegToken() : super("-");
}

enum Operation { Addition, Subtraction, Multiplication, Division }

// A token that represents an arithmetic operation symbol.
class OperationToken extends ExpressionToken {
  Operation operation;

  OperationToken(Operation operation)
      : super(opString(operation)),
        this.operation = operation;

  static String opString(Operation operation) {
    switch (operation) {
      case Operation.Addition:
        return " + ";
      case Operation.Subtraction:
        return " - ";
      case Operation.Multiplication:
        return "  \u00D7  ";
      case Operation.Division:
        return "  \u00F7  ";
    }
  }
}

// As the user taps different keys the current expression can be in one
// of several states.
enum ExpressionState {
  // The expression is empty or an operation symbol was just entered.
  // A new number must be started now.
  Start,
  // A minus sign was entered as a leading negative prefix.
  LeadingNeg,
  // We are in the midst of a number without a point.
  Number,
  // A point was just entered.
  Point,
  // We are in the midst of a number with a point.
  NumberWithPoint,
  // A result is being displayed
  Result,
}

// An expression that can be displayed in a calculator. It is the result
// of a sequence of user entries. It is represented by a sequence of tokens.
// Note that the tokens are not in one to one correspondence with the
// key taps because we use one token per number, not one token per digit.
// A CalcExpression is immutable. The append* methods return a new
// CalcExpression that represents the appropriate expression when one
// additional key tap occurs.
class CalcExpression {
  // The tokens comprising the expression.
  final List<ExpressionToken> _list;
  // The state of the expression.
  final ExpressionState state;

  CalcExpression(this._list, this.state);

  CalcExpression.Empty()
      : this(new List<ExpressionToken>(), ExpressionState.Start);

  CalcExpression.Result(FloatToken result)
      : _list = new List<ExpressionToken>(),
        state = ExpressionState.Result {
    _list.add(result);
  }

  // The string representation of the expression. This will be displayed
  // in the calculator's display panel.
  String toString() {
    var buffer = new StringBuffer("");
    buffer.writeAll(_list);
    return buffer.toString();
  }

  // Append a digit to the current expression and return a new expression
  // representing the result. Returns null to indicate that it is not legal
  // to append a digit in the current state.
  CalcExpression appendDigit(int digit) {
    var newState = ExpressionState.Number;
    var newToken;
    var outList = _list.toList();
    switch (state) {
      case ExpressionState.Start:
        // Start a new number with digit.
        newToken = new IntToken("$digit");
        break;
      case ExpressionState.LeadingNeg:
        // Replace the leading neg with a negative number starting with digit.
        outList.removeLast();
        newToken = new IntToken("-$digit");
        break;
      case ExpressionState.Number:
        var last = outList.removeLast();
        newToken = new IntToken(last.stringRep + "$digit");
        break;
      case ExpressionState.Point:
      case ExpressionState.NumberWithPoint:
        var last = outList.removeLast();
        newState = ExpressionState.NumberWithPoint;
        newToken = new FloatToken(last.stringRep + "$digit");
        break;
      case ExpressionState.Result:
        // Cannot enter a number now
        return null;
    }
    outList.add(newToken);
    return new CalcExpression(outList, newState);
  }

  // Append a point to the current expression and return a new expression
  // representing the result. Returns null to indicate that it is not legal
  // to append a point in the current state.
  CalcExpression appendPoint() {
    var newToken;
    var outList = _list.toList();
    switch (state) {
      case ExpressionState.Start:
        newToken = new FloatToken(".");
        break;
      case ExpressionState.LeadingNeg:
      case ExpressionState.Number:
        var last = outList.removeLast();
        newToken = new FloatToken(last.stringRep + ".");
        break;
      case ExpressionState.Point:
      case ExpressionState.NumberWithPoint:
      case ExpressionState.Result:
        // Cannot enter a point now
        return null;
    }
    outList.add(newToken);
    return new CalcExpression(outList, ExpressionState.Point);
  }

  // Append an operation symbol to the current expression and return a new
  // expression representing the result. Returns null to indicate that it is not
  // legal to append an operation symbol in the current state.
  CalcExpression appendOperation(Operation op) {
    switch (state) {
      case ExpressionState.Start:
      case ExpressionState.LeadingNeg:
      case ExpressionState.Point:
        // Cannot enter operation now.
        return null;
      case ExpressionState.Number:
      case ExpressionState.NumberWithPoint:
      case ExpressionState.Result:
        break;
    }
    var outList = _list.toList();
    outList.add(new OperationToken(op));
    return new CalcExpression(outList, ExpressionState.Start);
  }

  // Append a leading minus sign to the current expression and return a new
  // expression representing the result. Returns null to indicate that it is not
  // legal to append a leading minus sign in the current state.
  CalcExpression appendLeadingNeg() {
    switch (state) {
      case ExpressionState.Start:
        break;
      case ExpressionState.LeadingNeg:
      case ExpressionState.Point:
      case ExpressionState.Number:
      case ExpressionState.NumberWithPoint:
      case ExpressionState.Result:
        // Cannot enter leading neg now.
        return null;
    }
    var outList = _list.toList();
    outList.add(new LeadingNegToken());
    return new CalcExpression(outList, ExpressionState.LeadingNeg);
  }

  // Append a minus sign to the current expression and return a new expression
  // representing the result. Returns null to indicate that it is not legal
  // to append a minus sign in the current state. Depending on the current
  // state the minus sign will be interpretted as either a leading negative
  // sign or a subtraction operation.
  CalcExpression appendMinus() {
    switch (state) {
      case ExpressionState.Start:
        return appendLeadingNeg();
      case ExpressionState.LeadingNeg:
      case ExpressionState.Point:
      case ExpressionState.Number:
      case ExpressionState.NumberWithPoint:
      case ExpressionState.Result:
        return appendOperation(Operation.Subtraction);
    }
  }

  // Computes the result of the current expression and returns a new
  // ResultExpression containing the result. Returns null to indicate that
  // it is not legal to compute a result in the current state.
  CalcExpression computeResult() {
    switch (state) {
      case ExpressionState.Start:
      case ExpressionState.LeadingNeg:
      case ExpressionState.Point:
      case ExpressionState.Result:
        // Cannot compute result now.
        return null;
      case ExpressionState.Number:
      case ExpressionState.NumberWithPoint:
        break;
    }

    // We make a copy of _list because CalcExpressions are supposed to
    // be immutable.
    var list = _list.toList();
    // We obey order-of-operations by computing the sum of the "terms",
    // where a "term" is defined to be a sequence of numbers separated by
    // multiplcation or division symbols.
    var currentTermValue = removeNextTerm(list);
    while (list.length > 0) {
      var opToken = list.removeAt(0);
      assert(opToken is OperationToken);
      var nextTermValue = removeNextTerm(list);
      switch (opToken.operation) {
        case Operation.Addition:
          currentTermValue += nextTermValue;
          break;
        case Operation.Subtraction:
          currentTermValue -= nextTermValue;
          break;
        case Operation.Multiplication:
        case Operation.Division:
          // Logic error.
          assert(false);
      }
    }
    var outList = new List<ExpressionToken>();
    outList.add(new ResultToken(currentTermValue));
    return new CalcExpression(outList, ExpressionState.Result);
  }

  // Removes the next "term" from |list| and returns its numeric value.
  // A "term" is a sequence of number tokens separated by multiplication
  // and division symbols.
  static num removeNextTerm(List<ExpressionToken> list) {
    assert(list != null && list.length >= 1);
    var firstNumToken = list.removeAt(0);
    assert(firstNumToken is IntToken || firstNumToken is FloatToken);
    var currentValue = firstNumToken.number;
    while (list.length > 0) {
      var isDivision = false;
      switch ((list[0] as OperationToken).operation) {
        case Operation.Addition:
        case Operation.Subtraction:
          // We have reached the end of the current term
          return currentValue;
        case Operation.Multiplication:
          break;
        case Operation.Division:
          isDivision = true;
      }
      // Remove the operation token.
      list.removeAt(0);
      // Remove the next number token.
      var nextNumToken = list.removeAt(0);
      assert(nextNumToken is IntToken || nextNumToken is FloatToken);
      var nextNumber = nextNumToken.number;
      if (isDivision) {
        currentValue /= nextNumber;
      } else {
        currentValue *= nextNumber;
      }
    }
    return currentValue;
  }
}
