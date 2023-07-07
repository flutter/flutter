import 'src/template.dart' as t;

/// A Template can be efficiently rendered multiple times with different
/// values.
abstract class Template {
  /// The constructor parses the template source and throws [TemplateException]
  /// if the syntax of the source is invalid.
  /// Tag names may only contain characters a-z, A-Z, 0-9, underscore, and minus,
  /// unless lenient mode is specified.
  factory Template(String source,
      {bool lenient,
      bool htmlEscapeValues,
      String name,
      PartialResolver? partialResolver,
      String delimiters}) = t.Template.fromSource;

  String? get name;
  String get source;

  /// [values] can be a combination of Map, List, String. Any non-String object
  /// will be converted using toString(). Null values will cause a
  /// [TemplateException], unless lenient module is enabled.
  String renderString(values);

  /// [values] can be a combination of Map, List, String. Any non-String object
  /// will be converted using toString(). Null values will cause a
  /// [TemplateException], unless lenient module is enabled.
  void render(values, StringSink sink);
}

typedef PartialResolver = Template? Function(String);

typedef LambdaFunction = Object Function(LambdaContext context);

/// Passed as an argument to a mustache lambda function. The methods on
/// this object may only be called before the lambda function returns. If a
/// method is called after it has returned an exception will be thrown.
abstract class LambdaContext {
  /// Render the current section tag in the current context and return the
  /// result as a string. If provided, value will be added to the top of the
  /// context's stack.
  String renderString({Object? value});

  /// Render and directly output the current section tag. If provided, value
  /// will be added to the top of the context's stack.
  void render({Object value});

  /// Output a string. The output will not be html escaped, and will be written
  /// before the output returned from the lambda.
  void write(Object object);

  /// Get the unevaluated template source for the current section tag.
  String get source;

  /// Evaluate the string as a mustache template using the current context. If
  /// provided, value will be added to the top of the context's stack.
  String renderSource(String source, {Object? value});

  /// Lookup the value of a variable in the current context.
  Object? lookup(String variableName);
}

/// [TemplateException] is used to obtain the line and column numbers
/// of the token which caused parse or render to fail.
abstract class TemplateException implements Exception {
  /// A message describing the problem parsing or rendering the template.
  String get message;

  /// The name used to identify the template, as passed to the Template
  /// constructor.
  String? get templateName;

  /// The 1-based line number of the token where formatting error was found.
  int get line;

  /// The 1-based column number of the token where formatting error was found.
  int get column;

  /// The character offset within the template source.
  int? get offset;

  /// The template source.
  String? get source;

  /// A short source substring of the source at the point the problem occurred
  /// with parsing or rendering.
  String get context;
}
