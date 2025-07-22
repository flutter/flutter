// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

// Helper method used by internal libraries.
regExpGetNative(JSSyntaxRegExp regexp) => regexp._nativeRegExp;

/// Returns a native version of the RegExp with the global flag set.
///
/// The RegExp's `lastIndex` property is zero when it is returned.
///
/// The returned regexp is shared, and its `lastIndex` property may be
/// modified by other uses, so the returned regexp must be used immediately
/// when it's returned, with no user-provided code run in between.
regExpGetGlobalNative(JSSyntaxRegExp regexp) {
  var nativeRegexp = regexp._nativeGlobalVersion;
  JS('void', '#.lastIndex = 0', nativeRegexp);
  return nativeRegexp;
}

// Helper method used by internal libraries ([String.split])
bool regExpHasCaptures(JSSyntaxRegExp regexp) => regexp._hasCaptures;

class JSSyntaxRegExp implements RegExp {
  final String pattern;
  final _nativeRegExp;
  var _nativeGlobalRegExp;
  var _nativeAnchoredRegExp;
  bool? _hasCapturesCache;

  String toString() =>
      'RegExp/$pattern/' + JS('String', '#.flags', _nativeRegExp);

  JSSyntaxRegExp(
    String source, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) : this.pattern = source,
       this._nativeRegExp = makeNative(
         source,
         multiLine,
         caseSensitive,
         unicode,
         dotAll,
         '',
       );

  get _nativeGlobalVersion {
    if (_nativeGlobalRegExp != null) return _nativeGlobalRegExp;
    return _nativeGlobalRegExp = makeNative(
      pattern,
      _isMultiLine,
      _isCaseSensitive,
      _isUnicode,
      _isDotAll,
      'g',
    );
  }

  get _nativeAnchoredVersion {
    if (_nativeAnchoredRegExp != null) return _nativeAnchoredRegExp;
    // A sticky regexp is created by adding the "sticky" `y` flag.
    // Such a RegExp can only match exactly at the `lastIndex` position.
    return _nativeAnchoredRegExp = makeNative(
      pattern,
      _isMultiLine,
      _isCaseSensitive,
      _isUnicode,
      _isDotAll,
      'y',
    );
  }

  bool get _isMultiLine => JS('bool', '#.multiline', _nativeRegExp);
  bool get _isCaseSensitive => JS('bool', '!#.ignoreCase', _nativeRegExp);
  bool get _isUnicode => JS('bool', '#.unicode', _nativeRegExp);
  bool get _isDotAll => JS('bool', '#.dotAll', _nativeRegExp);

  /// Used by [String.split] to determine whether it can use the JavaScript
  /// `String.prototype.split` directly. It cannot if the RegExp has capture
  /// groups.
  bool get _hasCaptures => _hasCapturesCache ??= _computeHasCaptures();

  static makeNative(
    String source,
    bool multiLine,
    bool caseSensitive,
    bool unicode,
    bool dotAll,
    String extraFlags,
  ) {
    checkString(source);
    String m = multiLine ? 'm' : '';
    String i = caseSensitive ? '' : 'i';
    String u = unicode ? 'u' : '';
    String s = dotAll ? 's' : '';
    // We're using the JavaScript's try catch instead of the Dart one to avoid
    // dragging in Dart runtime support just because of using RegExp.
    var regexp = JS(
      '',
      r'''
          (function(source, modifiers) {
            try {
              return new RegExp(source, modifiers);
            } catch (e) {
              return e;
            }
          })(#, # + # + # + # + #)''',
      source,
      m,
      i,
      u,
      s,
      extraFlags,
    );
    if (JS('bool', '# instanceof RegExp', regexp)) return regexp;
    // The returned value is the JavaScript exception. Turn it into a
    // Dart exception.
    String errorMessage = JS('String', r'String(#)', regexp);
    throw FormatException('Illegal RegExp pattern ($errorMessage)', source);
  }

  bool _computeHasCaptures() {
    // Should only be called once, the first time [_hasCaptures] is read.
    assert(_hasCapturesCache == null);
    // No captures without parentheses.
    if (!pattern.contains('(')) return false;
    // Do not try to parse the RegExp, leave that to the RegExp compiler.
    // It's more future proof.

    // Create RegExp with same capture groups, which always (and quickly)
    // matches the empty string, and do that match to get a match array.
    // Currently supported flags do not affect capture syntax, and only the
    // unicode flag affects parsing at all, so use no other flags.
    // The length of the match array is the number of capture groups plus one.
    JSArray match = JS(
      'JSExtendableArray',
      r'new RegExp("(?:)|" + #, #).exec("")',
      pattern,
      _isUnicode ? 'u' : '',
    );
    return match.length > 1;
  }

  RegExpMatch? firstMatch(String string) {
    JSArray? m = JS(
      'JSExtendableArray|Null',
      r'#.exec(#)',
      _nativeRegExp,
      checkString(string),
    );
    if (m == null) return null;
    return _MatchImplementation(this, m);
  }

  bool hasMatch(String string) {
    return JS('bool', r'#.test(#)', _nativeRegExp, checkString(string));
  }

  String? stringMatch(String string) {
    var match = firstMatch(string);
    if (match != null) return match.group(0);
    return null;
  }

  Iterable<RegExpMatch> allMatches(String string, [int start = 0]) {
    checkString(string);
    checkInt(start);
    if (start < 0 || start > string.length) {
      throw RangeError.range(start, 0, string.length);
    }
    return _AllMatchesIterable(this, string, start);
  }

  RegExpMatch? _execGlobal(String string, int start) {
    Object regexp = _nativeGlobalVersion;
    JS('void', '#.lastIndex = #', regexp, start);
    JSArray? match = JS('JSExtendableArray|Null', '#.exec(#)', regexp, string);
    if (match == null) return null;
    return _MatchImplementation(this, match);
  }

  RegExpMatch? _execAnchored(String string, int start) {
    Object regexp = _nativeAnchoredVersion;
    JS('void', '#.lastIndex = #', regexp, start);
    JSArray? match = JS('JSExtendableArray|Null', '#.exec(#)', regexp, string);
    if (match == null) return null;
    return _MatchImplementation(this, match);
  }

  RegExpMatch? matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw RangeError.range(start, 0, string.length);
    }
    return _execAnchored(string, start);
  }

  bool get isMultiLine => _isMultiLine;
  bool get isCaseSensitive => _isCaseSensitive;
  bool get isUnicode => _isUnicode;
  bool get isDotAll => _isDotAll;
}

class _MatchImplementation implements RegExpMatch {
  final RegExp pattern;
  // Contains a JS RegExp match object.
  // It is an Array of String values with extra 'index' and 'input' properties.
  // If there were named capture groups, there will also be an extra 'groups'
  // property containing an object with capture group names as keys and
  // matched strings as values.
  // We didn't force it to be JSArray<String>, so it is JSArray<dynamic>, but
  // containing String or `undefined` values.
  final JSArray _match;

  _MatchImplementation(this.pattern, this._match) {
    assert(JS('var', '#.input', _match) is String);
    assert(JS('var', '#.index', _match) is int);
  }

  String get input => JS('String', '#.input', _match);

  int get start =>
      JS('returns:int;depends:none;effects:none;gvn:true', '#.index', _match);

  int get end =>
      (start +
              JS(
                'returns:int;depends:none;effects:none;gvn:true',
                '#[0].length',
                _match,
              ))
          as int;

  // The JS below changes the static type to avoid an implicit cast.
  // TODO(sra): Find a nicer way to do this, e.g. unsafeCast.
  String? group(int index) => JS('String|Null', '#', _match[index]);

  String? operator [](int index) => group(index);

  int get groupCount => _match.length - 1;

  List<String?> groups(List<int> groups) {
    List<String?> out = [];
    for (int i in groups) {
      out.add(group(i));
    }
    return out;
  }

  String? namedGroup(String name) {
    var groups = JS('=Object|Null', '#.groups', _match);
    if (groups != null) {
      String? result = JS('String|Null', '#[#]', groups, name);
      if (result != null || JS('bool', '# in #', name, groups)) {
        return result;
      }
    }
    throw ArgumentError.value(name, "name", "Not a capture group name");
  }

  Iterable<String> get groupNames {
    var groups = JS('=Object|Null', '#.groups', _match);
    if (groups != null) {
      var keys = JSArray<String>.markGrowable(
        JS('returns:JSExtendableArray;new:true', 'Object.keys(#)', groups),
      );
      return SubListIterable(keys, 0, null);
    }
    return Iterable.empty();
  }
}

class _AllMatchesIterable extends Iterable<RegExpMatch> {
  final JSSyntaxRegExp _re;
  final String _string;
  final int _start;

  _AllMatchesIterable(this._re, this._string, this._start);

  Iterator<RegExpMatch> get iterator =>
      _AllMatchesIterator(_re, _string, _start);
}

class _AllMatchesIterator implements Iterator<RegExpMatch> {
  final JSSyntaxRegExp _regExp;
  String? _string;
  int _nextIndex;
  RegExpMatch? _current;

  _AllMatchesIterator(this._regExp, this._string, this._nextIndex);

  RegExpMatch get current => _current as RegExpMatch;

  static bool _isLeadSurrogate(int c) {
    return c >= 0xd800 && c <= 0xdbff;
  }

  static bool _isTrailSurrogate(int c) {
    return c >= 0xdc00 && c <= 0xdfff;
  }

  bool moveNext() {
    var string = _string;
    if (string == null) return false;
    if (_nextIndex <= string.length) {
      RegExpMatch? match = _regExp._execGlobal(string, _nextIndex);
      if (match != null) {
        _current = match;
        int nextIndex = match.end;
        if (match.start == nextIndex) {
          // Zero-width match. Advance by one more, unless the regexp
          // is in unicode mode and it would put us within a surrogate
          // pair. In that case, advance past the code point as a whole.
          if (_regExp.isUnicode &&
              _nextIndex + 1 < string.length &&
              _isLeadSurrogate(string.codeUnitAt(_nextIndex)) &&
              _isTrailSurrogate(string.codeUnitAt(_nextIndex + 1))) {
            nextIndex++;
          }
          nextIndex++;
        }
        _nextIndex = nextIndex;
        return true;
      }
    }
    _current = null;
    _string = null; // Marks iteration as ended.
    return false;
  }
}

/// Find the first match of [regExp] in [string] at or after [start].
RegExpMatch? firstMatchAfter(JSSyntaxRegExp regExp, String string, int start) {
  return regExp._execGlobal(string, start);
}
