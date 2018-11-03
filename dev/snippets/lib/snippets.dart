// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:dart_style/dart_style.dart';

import 'configuration.dart';

void errorExit(String message) {
  stderr.writeln(message);
  exit(1);
}

// A Tuple containing the name and contents associated with a code block in a
// snippet.
class _ComponentTuple {
  _ComponentTuple(this.name, this.contents);
  final String name;
  final List<String> contents;
  String get mergedContent => contents.join('\n').trim();
}

/// Generates the snippet HTML, as well as saving the output snippet main to
/// the output directory.
class SnippetGenerator {
  SnippetGenerator({Configuration configuration})
      : configuration = configuration ?? const Configuration() {
    this.configuration.createOutputDirectory();
  }

  /// The configuration used to determine where to get/save data for the
  /// snippet.
  final Configuration configuration;

  /// A Dart formatted used to format the snippet code and finished application
  /// code.
  static DartFormatter formatter = DartFormatter(pageWidth: 80, fixes: StyleFix.all);

  /// This returns the output file for a given snippet ID. Only used for
  /// [SnippetType.application] snippets.
  File getOutputFile(String id) => File(path.join(configuration.outputDirectory.path, '$id.dart'));

  /// Gets the path to the template file requested.
  File getTemplatePath(String templateName, {Directory templatesDir}) {
    final Directory templateDir = templatesDir ?? configuration.templatesDirectory;
    final File templateFile = File(path.join(templateDir.path, '$templateName.tmpl'));
    return templateFile.existsSync() ? templateFile : null;
  }

  /// Injects the [injections] into the [template], and turning the
  /// "description" injection into a comment. Only used for
  /// [SnippetType.application] snippets.
  String interpolateTemplate(List<_ComponentTuple> injections, String template) {
    final String injectionMatches =
        injections.map<String>((_ComponentTuple tuple) => RegExp.escape(tuple.name)).join('|');
    final RegExp moustacheRegExp = RegExp('{{($injectionMatches)}}');
    return template.replaceAllMapped(moustacheRegExp, (Match match) {
      if (match[1] == 'description') {
        // Place the description into a comment.
        final List<String> description = injections
            .firstWhere((_ComponentTuple tuple) => tuple.name == match[1])
            .contents
            .map<String>((String line) => '// $line')
            .toList();
        // Remove any leading/trailing empty comment lines.
        // We don't want to remove ALL empty comment lines, only the ones at the
        // beginning and the end.
        while (description.last == '// ') {
          description.removeLast();
        }
        while (description.first == '// ') {
          description.removeAt(0);
        }
        return description.join('\n').trim();
      } else {
        return injections
            .firstWhere((_ComponentTuple tuple) => tuple.name == match[1])
            .mergedContent;
      }
    }).trim();
  }

  /// Interpolates the [injections] into an HTML skeleton file.
  ///
  /// Similar to interpolateTemplate, but we are only looking for `code-`
  /// components, and we care about the order of the injections.
  ///
  /// Takes into account the [type] and doesn't substitute in the id and the app
  /// if not a [SnippetType.application] snippet.
  String interpolateSkeleton(SnippetType type, List<_ComponentTuple> injections, String skeleton) {
    final List<String> result = <String>[];
    for (_ComponentTuple injection in injections) {
      if (!injection.name.startsWith('code')) {
        continue;
      }
      result.addAll(injection.contents);
      result.addAll(<String>['', '// ...', '']);
    }
    if (result.length > 3) {
      result.removeRange(result.length - 3, result.length);
    }
    String formattedCode;
    try {
      formattedCode = formatter.format(result.join('\n'));
    } on FormatterException catch (exception) {
      errorExit('Unable to format snippet code: $exception');
    }
    final Map<String, String> substitutions = <String, String>{
      'description': injections
          .firstWhere((_ComponentTuple tuple) => tuple.name == 'description')
          .mergedContent,
      'code': formattedCode,
    }..addAll(type == SnippetType.application
        ? <String, String>{
            'id':
                injections.firstWhere((_ComponentTuple tuple) => tuple.name == 'id').mergedContent,
            'app':
                injections.firstWhere((_ComponentTuple tuple) => tuple.name == 'app').mergedContent,
          }
        : <String, String>{'id': '', 'app': ''});
    return skeleton.replaceAllMapped(RegExp(r'{{(code|app|id|description)}}'), (Match match) {
      return substitutions[match[1]];
    });
  }

  /// Parses the input for the various code and description segments, and
  /// returns them in the order found.
  List<_ComponentTuple> parseInput(String input) {
    bool inSnippet = false;
    input = input.trim();
    final List<String> description = <String>[];
    final List<_ComponentTuple> components = <_ComponentTuple>[];
    String currentComponent;
    for (String line in input.split('\n')) {
      final Match match = RegExp(r'^\s*```(dart|dart (\w+))?\s*$').firstMatch(line);
      if (match != null) {
        inSnippet = !inSnippet;
        if (match[1] != null) {
          currentComponent = match[1];
          if (match[2] != null) {
            components.add(_ComponentTuple('code-${match[2]}', <String>[]));
          } else {
            components.add(_ComponentTuple('code', <String>[]));
          }
        } else {
          currentComponent = null;
        }
        continue;
      }
      if (!inSnippet) {
        description.add(line);
      } else {
        assert(currentComponent != null);
        components.last.contents.add(line);
      }
    }
    return <_ComponentTuple>[
      _ComponentTuple('description', description),
    ]..addAll(components);
  }

  String _loadFileAsUtf8(File file) {
    return file.readAsStringSync(encoding: Encoding.getByName('utf-8'));
  }

  /// The main routine for generating snippets.
  ///
  /// The [input] is the file containing the dartdoc comments (minus the leading
  /// comment markers).
  ///
  /// The [type] is the type of snippet to create: either a
  /// [SnippetType.application] or a [SnippetType.sample].
  ///
  /// The [template] must not be null if the [type] is
  /// [SnippetType.application], and specifies the name of the template to use
  /// for the application code.
  ///
  /// The [id] is a string ID to use for the output file, and to tell the user
  /// about in the `flutter create` hint. It must not be null if the [type] is
  /// [SnippetType.application].
  String generate(File input, SnippetType type, {String template, String id}) {
    assert(template != null || type != SnippetType.application);
    assert(id != null || type != SnippetType.application);
    assert(input != null);
    final List<_ComponentTuple> snippetData = parseInput(_loadFileAsUtf8(input));
    switch (type) {
      case SnippetType.application:
        final Directory templatesDir = configuration.templatesDirectory;
        if (templatesDir == null) {
          stderr.writeln('Unable to find the templates directory.');
          exit(1);
        }
        final File templateFile = getTemplatePath(template, templatesDir: templatesDir);
        if (templateFile == null) {
          stderr.writeln(
              'The template $template was not found in the templates directory ${templatesDir.path}');
          exit(1);
        }
        snippetData.add(_ComponentTuple('id', <String>[id]));
        final String templateContents = _loadFileAsUtf8(templateFile);
        String app = interpolateTemplate(snippetData, templateContents);

        try {
          app = formatter.format(app);
        } on FormatterException catch (exception) {
          errorExit('Unable to format snippet app template: $exception');
        }

        snippetData.add(_ComponentTuple('app', app.split('\n')));
        getOutputFile(id).writeAsStringSync(app);
        break;
      case SnippetType.sample:
        break;
    }
    final String skeleton = _loadFileAsUtf8(configuration.getHtmlSkeletonFile(type));
    return interpolateSkeleton(type, snippetData, skeleton);
  }
}
