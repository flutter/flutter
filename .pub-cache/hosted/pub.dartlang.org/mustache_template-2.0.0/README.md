# Mustache templates

A Dart library to parse and render [mustache templates](https://mustache.github.io/).

See the [mustache manual](http://mustache.github.com/mustache.5.html) for detailed usage information.

This library passes all [mustache specification](https://github.com/mustache/spec/tree/master/specs) tests.

## Example usage
```dart
import 'package:mustache/mustache.dart';

main() {
	var source = '''
	  {{# names }}
            <div>{{ lastname }}, {{ firstname }}</div>
	  {{/ names }}
	  {{^ names }}
	    <div>No names.</div>
	  {{/ names }}
	  {{! I am a comment. }}
	''';

	var template = new Template(source, name: 'template-filename.html');

	var output = template.renderString({'names': [
		{'firstname': 'Greg', 'lastname': 'Lowe'},
		{'firstname': 'Bob', 'lastname': 'Johnson'}
	]});

	print(output);
}
```

A template is parsed when it is created, after parsing it can be rendered any number of times with different values. A TemplateException is thrown if there is a problem parsing or rendering the template.

The Template contstructor allows passing a name, this name will be used in error messages. When working with a number of templates, it is important to pass a name so that the error messages specify which template caused the error.

By default all output from `{{variable}}` tags is html escaped, this behaviour can be changed by passing htmlEscapeValues : false to the Template constructor. You can also use a `{{{triple mustache}}}` tag, or a unescaped variable tag `{{&unescaped}}`, the output from these tags is not escaped.

## Differences between strict mode and lenient mode.

### Strict mode (default)

* Tag names may only contain the characters a-z, A-Z, 0-9, underscore, period and minus. Other characters in tags will cause a TemplateException to be thrown during parsing.

* During rendering, if no map key or object member which matches the tag name is found, then a TemplateException will be thrown.

### Lenient mode

* Tag names may use any characters.
* During rendering, if no map key or object member which matches the tag name is found, then silently ignore and output nothing.

## Nested paths

```dart
  var t = new Template('{{ author.name }}');
  var output = template.renderString({'author': {'name': 'Greg Lowe'}});
```

## Partials - example usage

```dart

var partial = new Template('{{ foo }}', name: 'partial');

var resolver = (String name) {
   if (name == 'partial-name') { // Name of partial tag.
     return partial;
   }
};

var t = new Template('{{> partial-name }}', partialResolver: resolver);

var output = t.renderString({'foo': 'bar'}); // bar

```

## Lambdas - example usage

```dart
var t = new Template('{{# foo }}');
var lambda = (_) => 'bar';
t.renderString({'foo': lambda}); // bar
```

```dart
var t = new Template('{{# foo }}hidden{{/ foo }}');
var lambda = (_) => 'shown'};
t.renderString({'foo': lambda); // shown
```

```dart
var t = new Template('{{# foo }}oi{{/ foo }}');
var lambda = (LambdaContext ctx) => '<b>${ctx.renderString().toUpperCase()}</b>';
t.renderString({'foo': lambda}); // <b>OI</b>
```

```dart
var t = new Template('{{# foo }}{{bar}}{{/ foo }}');
var lambda = (LambdaContext ctx) => '<b>${ctx.renderString().toUpperCase()}</b>';
t.renderString({'foo': lambda, 'bar': 'pub'}); // <b>PUB</b>
```

```dart
var t = new Template('{{# foo }}{{bar}}{{/ foo }}');
var lambda = (LambdaContext ctx) => '<b>${ctx.renderString().toUpperCase()}</b>';
t.renderString({'foo': lambda, 'bar': 'pub'}); // <b>PUB</b>
```

In the following example `LambdaContext.renderSource(source)` re-parses the source string in the current context, this is the default behaviour in many mustache implementations. Since re-parsing the content is slow, and often not required, this library makes this step optional.

```dart
var t = new Template('{{# foo }}{{bar}}{{/ foo }}');
var lambda = (LambdaContext ctx) => ctx.renderSource(ctx.source + ' {{cmd}}')};
t.renderString({'foo': lambda, 'bar': 'pub', 'cmd': 'build'}); // pub build
```
