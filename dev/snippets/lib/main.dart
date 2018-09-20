// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' hide Platform;

import 'package:args/args.dart';
import 'package:platform/platform.dart';

import 'configuration.dart';
import 'snippets.dart';

/// Generates snippet dartdoc output for a given input, and creates any sample
/// applications needed by the snippet.
void main(List<String> argList) {
  const Platform platform = LocalPlatform();
  final Map<String, String> environment = platform.environment;
  final ArgParser parser = ArgParser();
  final List<String> snippetTypes =
      SnippetType.values.map<String>((SnippetType type) => getEnumName(type)).toList();
  parser.addOption(
    'type',
    defaultsTo: 'application',
    allowed: snippetTypes,
    allowedHelp: <String, String>{
      getEnumName(SnippetType.application):
          'Produce a code snippet complete with embedding the sample in an '
          'application template.',
      getEnumName(SnippetType.sample):
          'Produce a nicely formatted piece of sample code. Does not embed the '
          'sample into an application template.'
    },
    help: 'The type of snippet to produce.',
  );
  parser.addOption(
    'template',
    defaultsTo: null,
    help: 'The name of the template to inject the code into.',
  );
  parser.addOption(
    'input',
    defaultsTo: environment['INPUT'],
    help: 'The input file containing the snippet code to inject.',
  );
  parser.addOption(
    'package',
    defaultsTo: environment['PACKAGE_NAME'],
    help: 'The name of the package that this snippet belongs to.',
  );
  parser.addOption(
    'library',
    defaultsTo: environment['LIBRARY_NAME'],
    help: 'The name of the library that this snippet belongs to.',
  );
  parser.addOption(
    'element',
    defaultsTo: environment['ELEMENT_NAME'],
    help: 'The name of the element that this snippet belongs to.',
  );

  final ArgResults args = parser.parse(argList);

  SnippetType snippetType;
  for (SnippetType type in SnippetType.values) {
    if (getEnumName(type) == args['type']) {
      snippetType = type;
    }
  }
  assert(snippetType != null, "Unable to find '${args['type']}' in SnippetType enum.");

  if (args['input'] == null) {
    stderr.writeln(parser.usage);
    errorExit('The --input option must be specified, either on the command '
        'line, or in the INPUT environment variable.');
  }

  final File input = File(args['input']);
  if (!input.existsSync()) {
    errorExit('The input file ${input.path} does not exist.');
  }

  String template;
  if (snippetType == SnippetType.application) {
    if (args['template'] == null || args['template'].isEmpty) {
      stderr.writeln(parser.usage);
      errorExit(
          'The --template option must be specified on the command line for application snippets.');
    }
    template = args['template'].toString().replaceAll(RegExp(r'.tmpl$'), '');
  }

  final List<String> id = <String>[];
  if (args['package'] != null && args['package'].isNotEmpty && args['package'] != 'flutter') {
    id.add(args['package']);
  }
  if (args['library'] != null && args['library'].isNotEmpty) {
    id.add(args['library']);
  }
  if (args['element'] != null && args['element'].isNotEmpty) {
    id.add(args['element']);
  }

  if (id.isEmpty) {
    errorExit('Unable to determine ID. At least one of --package, --library, '
        '--element, or the environment variables PACKAGE_NAME, LIBRARY_NAME, or '
        'ELEMENT_NAME must be non-empty.');
  }

  final SnippetGenerator generator = SnippetGenerator();
  stdout.write(generator.generate(
    input,
    snippetType,
    template: template,
    id: id.join('.'),
  ));
  exit(0);
}
