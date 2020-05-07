// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';

void errorExit(String message) {
  stderr.writeln(message);
  exit(1);
}

// A Tuple containing the name and contents associated with a code block in a
// snippet.
class _ComponentTuple {
  _ComponentTuple(this.name, this.contents, {String language}) : language = language ?? '';
  final String name;
  final List<String> contents;
  final String language;
  String get mergedContent => contents.join('\n').trim();
}

/// Generates the snippet HTML, as well as saving the output snippet main to
/// the output directory.
class SnippetGenerator {
  SnippetGenerator({Configuration configuration})
      : configuration = configuration ??
            // Flutter's root is four directories up from this script.
            Configuration(flutterRoot: Directory(Platform.environment['FLUTTER_ROOT']
                ?? path.canonicalize(path.join(path.dirname(path.fromUri(Platform.script)), '..', '..', '..')))) {
    this.configuration.createOutputDirectory();
  }

  /// The configuration used to determine where to get/save data for the
  /// snippet.
  final Configuration configuration;

  static const JsonEncoder jsonEncoder = JsonEncoder.withIndent('    ');

  /// A Dart formatted used to format the snippet code and finished application
  /// code.
  static DartFormatter formatter = DartFormatter(pageWidth: 80, fixes: StyleFix.all);

  /// This returns the output file for a given snippet ID. Only used for
  /// [SnippetType.sample] snippets.
  File getOutputFile(String id) => File(path.join(configuration.outputDirectory.path, '$id.dart'));

  /// Gets the path to the template file requested.
  File getTemplatePath(String templateName, {Directory templatesDir}) {
    final Directory templateDir = templatesDir ?? configuration.templatesDirectory;
    final File templateFile = File(path.join(templateDir.path, '$templateName.tmpl'));
    return templateFile.existsSync() ? templateFile : null;
  }

  /// Injects the [injections] into the [template], and turning the
  /// "description" injection into a comment. Only used for
  /// [SnippetType.sample] snippets.
  String interpolateTemplate(List<_ComponentTuple> injections, String template, Map<String, Object> metadata) {
    final RegExp moustacheRegExp = RegExp('{{([^}]+)}}');
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
        while (description.isNotEmpty && description.last == '// ') {
          description.removeLast();
        }
        while (description.isNotEmpty && description.first == '// ') {
          description.removeAt(0);
        }
        return description.join('\n').trim();
      } else {
        // If the match isn't found in the injections, then just remove the
        // mustache reference, since we want to allow the sections to be
        // "optional" in the input: users shouldn't be forced to add an empty
        // "```dart preamble" section if that section would be empty.
        final _ComponentTuple result = injections
            .firstWhere((_ComponentTuple tuple) => tuple.name == match[1], orElse: () => null);
        return result?.mergedContent ?? (metadata[match[1]] ?? '').toString();
      }
    }).trim();
  }

  /// Interpolates the [injections] into an HTML skeleton file.
  ///
  /// Similar to interpolateTemplate, but we are only looking for `code-`
  /// components, and we care about the order of the injections.
  ///
  /// Takes into account the [type] and doesn't substitute in the id and the app
  /// if not a [SnippetType.sample] snippet.
  String interpolateSkeleton(SnippetType type, List<_ComponentTuple> injections, String skeleton, Map<String, Object> metadata) {
    final List<String> result = <String>[];
    const HtmlEscape htmlEscape = HtmlEscape();
    String language;
    for (final _ComponentTuple injection in injections) {
      if (!injection.name.startsWith('code')) {
        continue;
      }
      result.addAll(injection.contents);
      if (injection.language.isNotEmpty) {
        language = injection.language;
      }
      result.addAll(<String>['', '// ...', '']);
    }
    if (result.length > 3) {
      result.removeRange(result.length - 3, result.length);
    }
    // Only insert a div for the description if there actually is some text there.
    // This means that the {{description}} marker in the skeleton needs to
    // be inside of an {@inject-html} block.
    String description = injections.firstWhere((_ComponentTuple tuple) => tuple.name == 'description').mergedContent;
    description = description.trim().isNotEmpty
        ? '<div class="snippet-description">{@end-inject-html}$description{@inject-html}</div>'
        : '';

    // DartPad only supports stable or master as valid channels. Use master
    // if not on stable so that local runs will work (although they will
    // still take their sample code from the master docs server).
    final String channel = metadata['channel'] == 'stable' ? 'stable' : 'master';

    final Map<String, String> substitutions = <String, String>{
      'description': description,
      'code': htmlEscape.convert(result.join('\n')),
      'language': language ?? 'dart',
      'serial': '',
      'id': metadata['id'] as String,
      'channel': channel,
      'element': metadata['element'] as String ?? '',
      'app': '',
    };
    if (type == SnippetType.sample) {
      substitutions
        ..['serial'] = metadata['serial']?.toString() ?? '0'
        ..['app'] = htmlEscape.convert(injections.firstWhere((_ComponentTuple tuple) => tuple.name == 'app').mergedContent);
    }
    return skeleton.replaceAllMapped(RegExp('{{(${substitutions.keys.join('|')})}}'), (Match match) {
      return substitutions[match[1]];
    });
  }

  /// Parses the input for the various code and description segments, and
  /// returns them in the order found.
  List<_ComponentTuple> parseInput(String input) {
    bool inCodeBlock = false;
    input = input.trim();
    final List<String> description = <String>[];
    final List<_ComponentTuple> components = <_ComponentTuple>[];
    String language;
    final RegExp codeStartEnd = RegExp(r'^\s*```([-\w]+|[-\w]+ ([-\w]+))?\s*$');
    for (final String line in input.split('\n')) {
      final Match match = codeStartEnd.firstMatch(line);
      if (match != null) { // If we saw the start or end of a code block
        inCodeBlock = !inCodeBlock;
        if (match[1] != null) {
          language = match[1];
          if (match[2] != null) {
            components.add(_ComponentTuple('code-${match[2]}', <String>[], language: language));
          } else {
            components.add(_ComponentTuple('code', <String>[], language: language));
          }
        } else {
          language = null;
        }
        continue;
      }
      if (!inCodeBlock) {
        description.add(line);
      } else {
        assert(language != null);
        components.last.contents.add(line);
      }
    }
    return <_ComponentTuple>[
      _ComponentTuple('description', description),
      ...components,
    ];
  }

  String _loadFileAsUtf8(File file) {
    return file.readAsStringSync(encoding: Encoding.getByName('utf-8'));
  }

  String _addLineNumbers(String app) {
    final StringBuffer buffer = StringBuffer();
    int count = 0;
    for (final String line in app.split('\n')) {
      count++;
      buffer.writeln('${count.toString().padLeft(5, ' ')}: $line');
    }
    return buffer.toString();
  }

  /// The main routine for generating snippets.
  ///
  /// The [input] is the file containing the dartdoc comments (minus the leading
  /// comment markers).
  ///
  /// The [type] is the type of snippet to create: either a
  /// [SnippetType.sample] or a [SnippetType.snippet].
  ///
  /// [showDartPad] indicates whether DartPad should be shown where possible.
  /// Currently, this value only has an effect if [type] is
  /// [SnippetType.sample], in which case an alternate skeleton file is
  /// used to create the final HTML output.
  ///
  /// The [template] must not be null if the [type] is
  /// [SnippetType.sample], and specifies the name of the template to use
  /// for the application code.
  ///
  /// The [id] is a string ID to use for the output file, and to tell the user
  /// about in the `flutter create` hint. It must not be null if the [type] is
  /// [SnippetType.sample].
  String generate(
    File input,
    SnippetType type, {
    bool showDartPad = false,
    String template,
    File output,
    @required Map<String, Object> metadata,
  }) {
    assert(template != null || type != SnippetType.sample);
    assert(metadata != null && metadata['id'] != null);
    assert(input != null);
    assert(!showDartPad || type == SnippetType.sample, 'Only application samples work with dartpad.');
    final List<_ComponentTuple> snippetData = parseInput(_loadFileAsUtf8(input));
    switch (type) {
      case SnippetType.sample:
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
        final String templateContents = _loadFileAsUtf8(templateFile);
        String app = interpolateTemplate(snippetData, templateContents, metadata);

        try {
          app = formatter.format(app);
        } on FormatterException catch (exception) {
          stderr.write('Code to format:\n${_addLineNumbers(app)}\n');
          errorExit('Unable to format snippet app template: $exception');
        }

        snippetData.add(_ComponentTuple('app', app.split('\n')));
        final File outputFile = output ?? getOutputFile(metadata['id'] as String);
        stderr.writeln('Writing to ${outputFile.absolute.path}');
        outputFile.writeAsStringSync(app);

        final File metadataFile = File(path.join(path.dirname(outputFile.path),
            '${path.basenameWithoutExtension(outputFile.path)}.json'));
        stderr.writeln('Writing metadata to ${metadataFile.absolute.path}');
        final _ComponentTuple description = snippetData.firstWhere(
          (_ComponentTuple data) => data.name == 'description',
          orElse: () => null,
        );
        metadata.addAll(<String, Object>{
          'file': path.basename(outputFile.path),
          'description': description?.mergedContent,
        });
        metadataFile.writeAsStringSync(jsonEncoder.convert(metadata));
        break;
      case SnippetType.snippet:
        break;
    }
    final String skeleton =
        _loadFileAsUtf8(configuration.getHtmlSkeletonFile(type, showDartPad: showDartPad));
    return interpolateSkeleton(type, snippetData, skeleton, metadata);
  }
}
