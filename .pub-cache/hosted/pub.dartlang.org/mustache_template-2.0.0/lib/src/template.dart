import 'package:mustache_template/mustache.dart' as m;
import 'node.dart';
import 'parser.dart' as parser;
import 'renderer.dart';

class Template implements m.Template {
  Template.fromSource(String source,
      {bool lenient = false,
      bool htmlEscapeValues = true,
      String? name,
      m.PartialResolver? partialResolver,
      String delimiters = '{{ }}'})
      : source = source,
        _nodes = parser.parse(source, lenient, name, delimiters),
        _lenient = lenient,
        _htmlEscapeValues = htmlEscapeValues,
        _name = name,
        _partialResolver = partialResolver;

  @override
  final String source;
  final List<Node> _nodes;
  final bool _lenient;
  final bool _htmlEscapeValues;
  final String? _name;
  final m.PartialResolver? _partialResolver;

  @override
  String? get name => _name;

  @override
  String renderString(values) {
    var buf = StringBuffer();
    render(values, buf);
    return buf.toString();
  }

  @override
  void render(values, StringSink sink) {
    var renderer = Renderer(sink, [values], _lenient, _htmlEscapeValues,
        _partialResolver, _name, '', source);
    renderer.render(_nodes);
  }
}

// Expose getter for nodes internally within this package.
List<Node> getTemplateNodes(Template template) => template._nodes;
