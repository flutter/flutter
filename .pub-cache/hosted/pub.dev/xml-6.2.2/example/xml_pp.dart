/// XML pretty printer and highlighter.
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:xml/xml.dart';

const entityMapping = XmlDefaultEntityMapping.xml();

const String ansiReset = '\u001b[0m';
const String ansiRed = '\u001b[31m';
const String ansiGreen = '\u001b[32m';
const String ansiYellow = '\u001b[33m';
const String ansiBlue = '\u001b[34m';
const String ansiMagenta = '\u001b[35m';
const String ansiCyan = '\u001b[36m';

const String attributeStyle = ansiBlue;
const String cdataStyle = ansiYellow;
const String commentStyle = ansiGreen;
const String declarationStyle = ansiCyan;
const String doctypeStyle = ansiCyan;
const String documentStyle = ansiReset;
const String documentFragmentStyle = ansiCyan;
const String elementStyle = ansiMagenta;
const String nameStyle = ansiRed;
const String processingStyle = ansiCyan;
const String textStyle = ansiReset;

final args.ArgParser argumentParser = args.ArgParser()
  ..addFlag(
    'color',
    abbr: 'c',
    help: 'Colorize the output.',
    defaultsTo: stdout.supportsAnsiEscapes,
  )
  ..addOption(
    'indent',
    abbr: 'i',
    help: 'Customize the indention when pretty printing.',
    defaultsTo: '  ',
  )
  ..addOption(
    'newline',
    abbr: 'n',
    help: 'Change the newline character when pretty printing.',
    defaultsTo: '\n',
  )
  ..addFlag(
    'pretty',
    abbr: 'p',
    help: 'Reformat the output to be pretty.',
    defaultsTo: true,
  );

void printUsage() {
  stdout.writeln('Usage: xml_pp [options] {files}');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

void main(List<String> arguments) {
  final files = <File>[];
  final results = argumentParser.parse(arguments);
  final color = results['color'];
  final indent = results['indent'];
  final newLine = results['newline'];
  final pretty = results['pretty'];

  for (final argument in results.rest) {
    final file = File(argument);
    if (file.existsSync()) {
      files.add(file);
    } else {
      stderr.writeln('File not found: $file');
      exit(2);
    }
  }
  if (files.isEmpty) {
    printUsage();
  }

  // Select the appropriate printing visitor. For simpler use-cases one would
  // just call `document.toXmlString(pretty: true, indent: '  ')`.
  final visitor = pretty
      ? (color
          ? XmlColoredPrettyWriter(stdout,
              entityMapping: entityMapping, indent: indent, newLine: newLine)
          : XmlPrettyWriter(stdout,
              entityMapping: entityMapping, indent: indent, newLine: newLine))
      : (color
          ? XmlColoredWriter(stdout, entityMapping: entityMapping)
          : XmlWriter(stdout, entityMapping: entityMapping));
  for (final file in files) {
    visitor.visit(XmlDocument.parse(file.readAsStringSync()));
  }
}

mixin ColoredWriter {
  StringSink get buffer;

  List<String> get styles;

  void style(String style, void Function() callback) {
    styles.add(style);
    buffer.write(style);
    callback();
    styles.removeLast();
    buffer.write(styles.isEmpty ? ansiReset : styles.last);
  }
}

class XmlColoredWriter extends XmlWriter with ColoredWriter {
  XmlColoredWriter(super.buffer, {super.entityMapping});

  @override
  final List<String> styles = [];

  @override
  void visitAttribute(XmlAttribute node) =>
      style(attributeStyle, () => super.visitAttribute(node));

  @override
  void visitCDATA(XmlCDATA node) =>
      style(cdataStyle, () => super.visitCDATA(node));

  @override
  void visitComment(XmlComment node) =>
      style(commentStyle, () => super.visitComment(node));

  @override
  void visitDeclaration(XmlDeclaration node) =>
      style(declarationStyle, () => super.visitDeclaration(node));

  @override
  void visitDocument(XmlDocument node) =>
      style(documentStyle, () => super.visitDocument(node));

  @override
  void visitDocumentFragment(XmlDocumentFragment node) =>
      style(documentFragmentStyle, () => super.visitDocumentFragment(node));

  @override
  void visitDoctype(XmlDoctype node) =>
      style(doctypeStyle, () => super.visitDoctype(node));

  @override
  void visitElement(XmlElement node) =>
      style(elementStyle, () => super.visitElement(node));

  @override
  void visitName(XmlName name) => style(nameStyle, () => super.visitName(name));

  @override
  void visitProcessing(XmlProcessing node) =>
      style(processingStyle, () => super.visitProcessing(node));

  @override
  void visitText(XmlText node) => style(textStyle, () => super.visitText(node));
}

class XmlColoredPrettyWriter extends XmlPrettyWriter with ColoredWriter {
  XmlColoredPrettyWriter(super.buffer,
      {super.entityMapping, super.indent, super.newLine});
  @override
  final List<String> styles = [];

  @override
  void visitAttribute(XmlAttribute node) =>
      style(attributeStyle, () => super.visitAttribute(node));

  @override
  void visitCDATA(XmlCDATA node) =>
      style(cdataStyle, () => super.visitCDATA(node));

  @override
  void visitComment(XmlComment node) =>
      style(commentStyle, () => super.visitComment(node));

  @override
  void visitDeclaration(XmlDeclaration node) =>
      style(declarationStyle, () => super.visitDeclaration(node));

  @override
  void visitDocument(XmlDocument node) =>
      style(documentStyle, () => super.visitDocument(node));

  @override
  void visitDocumentFragment(XmlDocumentFragment node) =>
      style(documentFragmentStyle, () => super.visitDocumentFragment(node));

  @override
  void visitDoctype(XmlDoctype node) =>
      style(doctypeStyle, () => super.visitDoctype(node));

  @override
  void visitElement(XmlElement node) =>
      style(elementStyle, () => super.visitElement(node));

  @override
  void visitName(XmlName name) => style(nameStyle, () => super.visitName(name));

  @override
  void visitProcessing(XmlProcessing node) =>
      style(processingStyle, () => super.visitProcessing(node));

  @override
  void visitText(XmlText node) => style(textStyle, () => super.visitText(node));
}
