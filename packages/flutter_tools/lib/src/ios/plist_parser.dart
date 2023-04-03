// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';
import 'package:xml/xml.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';

class PlistParser {
  PlistParser({
    required FileSystem fileSystem,
    required Logger logger,
    required ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager);

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;

  static const String kCFBundleIdentifierKey = 'CFBundleIdentifier';
  static const String kCFBundleShortVersionStringKey = 'CFBundleShortVersionString';
  static const String kCFBundleExecutableKey = 'CFBundleExecutable';
  static const String kCFBundleVersionKey = 'CFBundleVersion';
  static const String kCFBundleDisplayNameKey = 'CFBundleDisplayName';
  static const String kMinimumOSVersionKey = 'MinimumOSVersion';

  /// Returns the content, converted to XML, of the plist file located at
  /// [plistFilePath].
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return null.
  ///
  /// The [plistFilePath] argument must not be null.
  String? plistXmlContent(String plistFilePath) {
    const String executable = '/usr/bin/plutil';
    if (!_fileSystem.isFileSync(executable)) {
      throw const FileNotFoundException(executable);
    }
    final List<String> args = <String>[
      executable, '-convert', 'xml1', '-o', '-', plistFilePath,
    ];
    try {
      final String xmlContent = _processUtils.runSync(
        args,
        throwOnError: true,
      ).stdout.trim();
      return xmlContent;
    } on ProcessException catch (error) {
      _logger.printTrace('$error');
      return null;
    }
  }

  /// Parses the plist file located at [plistFilePath] and returns the
  /// associated map of key/value property list pairs.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return an empty map.
  ///
  /// The [plistFilePath] argument must not be null.
  Map<String, Object> parseFile(String plistFilePath) {
    assert(plistFilePath != null);
    if (!_fileSystem.isFileSync(plistFilePath)) {
      return const <String, Object>{};
    }

    final String normalizedPlistPath = _fileSystem.path.absolute(plistFilePath);

    final String? xmlContent = plistXmlContent(normalizedPlistPath);
    if (xmlContent == null) {
      return const <String, Object>{};
    }

    return _parseXml(xmlContent);
  }

  Map<String, Object> _parseXml(String xmlContent) {
    final XmlDocument document = XmlDocument.parse(xmlContent);
    // First element child is <plist>. The first element child of plist is <dict>.
    final XmlElement dictObject = document.firstElementChild!.firstElementChild!;
    return _parseXmlDict(dictObject);
  }

  Map<String, Object> _parseXmlDict(XmlElement node) {
    String? lastKey;
    final Map<String, Object> result = <String, Object>{};
    for (final XmlNode child in node.children) {
      if (child is XmlElement) {
        if (child.name.local == 'key') {
          lastKey = child.text;
        } else {
          assert(lastKey != null);
          result[lastKey!] = _parseXmlNode(child)!;
          lastKey = null;
        }
      }
    }

    return result;
  }

  static final RegExp _nonBase64Pattern = RegExp('[^a-zA-Z0-9+/=]+');

  Object? _parseXmlNode(XmlElement node) {
    switch (node.name.local){
      case 'string':
        return node.text;
      case 'real':
        return double.parse(node.text);
      case 'integer':
        return int.parse(node.text);
      case 'true':
        return true;
      case 'false':
        return false;
      case 'date':
        return DateTime.parse(node.text);
      case 'data':
        return base64.decode(node.text.replaceAll(_nonBase64Pattern, ''));
      case 'array':
        return node.children.whereType<XmlElement>().map<Object?>(_parseXmlNode).whereType<Object>().toList();
      case 'dict':
        return _parseXmlDict(node);
    }
    return null;
  }

  /// Parses the Plist file located at [plistFilePath] and returns the string
  /// value that's associated with the specified [key] within the property list.
  ///
  /// If [plistFilePath] points to a non-existent file or a file that's not a
  /// valid property list file, this will return null.
  ///
  /// If [key] is not found in the property list, this will return null.
  ///
  /// The [plistFilePath] and [key] arguments must not be null.
  String? getStringValueFromFile(String plistFilePath, String key) {
    final Map<String, dynamic> parsed = parseFile(plistFilePath);
    return parsed[key] as String?;
  }
}
