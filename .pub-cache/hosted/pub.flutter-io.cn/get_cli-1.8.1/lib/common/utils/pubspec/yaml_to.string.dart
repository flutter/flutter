final _unsuportedCharacters = RegExp(
    r'''^[\n\t ,[\]{}#&*!|<>'"%@']|^[?-]$|^[?-][ \t]|[\n:][ \t]|[ \t]\n|[\n\t ]#|[\n\t :]$''');

class CliYamlToString {
  const CliYamlToString({
    this.indent = ' ',
    this.quotes = "'",
  });

  final String indent, quotes;
  static final _divider = ': ';

  String toYamlString(dynamic node) {
    final stringBuffer = StringBuffer();
    writeYamlString(node, stringBuffer);
    return stringBuffer.toString();
  }

  /// Serializes [node] into a String and writes it to the [sink].
  void writeYamlString(dynamic node, StringSink sink) {
    _writeYamlString(node, 0, sink, true, false);
  }

  void _writeYamlString(node, int indentCount, StringSink stringSink,
      bool isTopLevel, bool isList) {
    if (node is Map) {
      _mapToYamlString(node.cast<String, dynamic>(), indentCount, stringSink,
          isTopLevel, isList);
    } else if (node is Iterable) {
      _listToYamlString(node, indentCount, stringSink, isTopLevel);
    } else if (node is String) {
      stringSink.writeln(_escapeString(node));
    } else if (node is double) {
      stringSink.writeln('!!float $node');
    } else {
      stringSink.writeln(node);
    }
  }

  String _escapeString(String line) {
    line = line.replaceAll('"', r'\"').replaceAll('\n', r'\n');

    if (line.contains(_unsuportedCharacters)) {
      line = quotes + line + quotes;
    }

    return line;
  }

  void _mapToYamlString(
    Map<String, dynamic> node,
    int indentCount,
    StringSink stringSink,
    bool isTopLevel,
    bool isList,
  ) {
    if (!isTopLevel) {
      if (!isList) {
        stringSink.writeln();
      }
      indentCount += 2;
    }
    final keys = _sortKeys(node);

    if (isList) {
      for (var key in keys) {
        final value = node[key];
        if (value is Iterable || value is Map) {
          _writeIndent(indentCount, stringSink);
        }
        stringSink
          ..write(key)
          ..write(_divider);
        _writeYamlString(value, indentCount, stringSink, false, false);
      }
    } else {
      for (var key in keys) {
        final value = node[key];
        _writeIndent(indentCount, stringSink);
        stringSink
          ..write(key)
          ..write(_divider);
        _writeYamlString(value, indentCount, stringSink, false, false);
        if (value is Map || value is Iterable) {
          if (isTopLevel) {
            stringSink.writeln('');
          }
        }
      }
    }
  }

  Iterable<String> _sortKeys(Map<String, dynamic> map) {
    final simple = <String>[],
        maps = <String>[],
        lists = <String>[],
        other = <String>[];

    map.forEach((key, value) {
      if (value is String) {
        simple.add(key);
      } else if (value is Map) {
        maps.add(key);
      } else if (value is Iterable) {
        lists.add(key);
      } else {
        other.add(key);
      }
    });

    return [...simple, ...maps, ...lists, ...other];
  }

  void _listToYamlString(
    Iterable node,
    int indentCount,
    StringSink stringSink,
    bool isTopLevel,
  ) {
    if (!isTopLevel) {
      stringSink.writeln();
      indentCount += 2;
    }

    for (var value in node) {
      _writeIndent(indentCount, stringSink);
      stringSink.write('- ');
      _writeYamlString(value, indentCount, stringSink, false, true);
    }
  }

  void _writeIndent(int indentCount, StringSink stringSink) =>
      stringSink.write(indent * indentCount);
}
