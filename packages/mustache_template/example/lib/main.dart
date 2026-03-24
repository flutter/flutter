// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Example demonstrating mustache_template usage.
library;

import 'package:mustache_template/mustache_template.dart';

void main() {
  // Basic variable interpolation
  basicVariableExample();

  // Sections (conditionals and loops)
  sectionsExample();

  // Inverted sections
  invertedSectionsExample();

  // Lambdas
  lambdasExample();

  // Partials
  partialsExample();
}

// #docregion basic-variable
/// Demonstrates basic variable interpolation.
void basicVariableExample() {
  final template = Template('Hello {{name}}!');
  final output = template.renderString({'name': 'World'});
  print(output); // Output: Hello World!
}
// #enddocregion basic-variable

// #docregion sections
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
// #enddocregion sections

// #docregion inverted-sections
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
// #enddocregion inverted-sections

// #docregion lambdas
/// Demonstrates lambda functions for dynamic content.
void lambdasExample() {
  final template = Template('{{#bold}}Hello{{/bold}}');
  final output = template.renderString({
    'bold': (LambdaContext ctx) => '<b>${ctx.renderString()}</b>',
  });
  print(output); // Output: <b>Hello</b>
}
// #enddocregion lambdas

// #docregion partials
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
// #enddocregion partials
