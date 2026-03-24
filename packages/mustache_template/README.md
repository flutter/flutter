# mustache_template

A Dart implementation of the [Mustache](https://mustache.github.io/) templating language.

## Features

- Variable interpolation with `{{variable}}`
- Sections for conditionals and loops with `{{#section}}...{{/section}}`
- Inverted sections with `{{^section}}...{{/section}}`
- Lambda functions for dynamic content
- Partials for template composition
- HTML escaping by default, with `{{{raw}}}` for unescaped output

## Getting Started

Add `mustache_template` to your `pubspec.yaml`:

yaml
dependencies:
  mustache_template: ^2.0.0


## Usage

### Basic Variable Interpolation

<?code-excerpt "lib/main.dart (basic-variable)"?>
dart
/// Demonstrates basic variable interpolation.
void basicVariableExample() {
  final template = Template('Hello {{name}}!');
  final output = template.renderString({'name': 'World'});
  print(output); // Output: Hello World!
}


### Sections

Sections render blocks of text based on the value of a key. They can be used for conditionals and loops.

<?code-excerpt "lib/main.dart (sections)"?>
dart
/// Demonstrates sections for conditionals and loops.
void sectionsExample() {
  // Conditional section
  final conditionalTemplate = Template('''
{{#showGreeting}}
Hello, {{name}}!
{{/showGreeting}}
''');
  print(conditionalTemplate.renderString({
    'showGreeting': true,
    'name': 'Alice',
  }));

  // Loop section
  final loopTemplate = Template('''
{{#items}}
- {{name}}: {{price}}
{{/items}}
''');
  print(loopTemplate.renderString({
    'items': [
      {'name': 'Apple', 'price': r'$1.00'},
      {'name': 'Banana', 'price': r'$0.50'},
    ],
  }));
}


### Inverted Sections

Inverted sections render when a key is false, null, or an empty list.

<?code-excerpt "lib/main.dart (inverted-sections)"?>
dart
/// Demonstrates inverted sections for handling empty or false values.
void invertedSectionsExample() {
  final template = Template('''
{{#items}}
- {{.}}
{{/items}}
{{^items}}
No items found.
{{/items}}
''');

  // With items
  print(template.renderString({
    'items': ['One', 'Two'],
  }));

  // Without items
  print(template.renderString({
    'items': <String>[],
  }));
}


### Lambdas

Lambdas allow dynamic content generation.

<?code-excerpt "lib/main.dart (lambdas)"?>
dart
/// Demonstrates lambda functions for dynamic content.
void lambdasExample() {
  final template = Template('{{#bold}}Hello{{/bold}}');
  final output = template.renderString({
    'bold': (LambdaContext ctx) => '<b>${ctx.renderString()}</b>',
  });
  print(output); // Output: <b>Hello</b>
}


### Partials

Partials allow template composition by including other templates.

<?code-excerpt "lib/main.dart (partials)"?>
dart
/// Demonstrates partials for template composition.
void partialsExample() {
  final baseTemplate = Template(
    '{{> header}}\nContent here\n{{> footer}}',
    partialResolver: (String name) {
      switch (name) {
        case 'header':
          return Template('=== Header ===');
        case 'footer':
          return Template('=== Footer ===');
        default:
          return Template('');
      }
    },
  );
  print(baseTemplate.renderString({}));
}


## Example

See the [example](example/) directory for a complete example application.

## Additional Resources

- [Mustache Manual](https://mustache.github.io/mustache.5.html)
- [API Documentation](https://pub.dev/documentation/mustache_template/latest/)
