// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart' as xml show parse;
import 'package:xml/xml.dart' hide parse;

/// Interprets some subset of an SVG* file.
///
/// Recursively goes over the SVG tree, applying transforms and opacities,
/// and build a FrameData which is a flat representation of the paths in the SVG
/// file, after applying transformations and converting relative coordinates to
/// absolute.
///
/// * Note that this does not support the SVG specification, but is just built to
/// support SVG files exported by a specific tool the motion design team is
/// using.
FrameData interpretSvg(String svgFilePath) {
  final File file = new File(svgFilePath);
  if (!file.existsSync()) {
    throw new ArgumentError('$file does not exist');
  }
  final String fileData = file.readAsStringSync();
  final XmlElement svgElement = _extractSvgElement(xml.parse(fileData));
  final double width = parsePixels(_extractAttr(svgElement, 'width')).toDouble();
  final double height = parsePixels(_extractAttr(svgElement, 'height')).toDouble();

  final List<SvgPath> paths = <SvgPath>[];
  for (XmlNode child in svgElement.children) {
    if (child.nodeType != XmlNodeType.ELEMENT)
      continue;
    final XmlElement childElement = child;

    // TODO(amirh): recrusively parse groups and apply transforms
    if (childElement.name.local == 'path') {
      paths.add(SvgPath.fromElement(childElement));
    }
  }
  return new FrameData(new Point<double>(width, height), paths);
}

// Given a points list in the form e.g: "25.0, 1.0 12.0, 12.0 23.0, 9.0" matches
// the coordinated of the first point and the rest of the string, for the
// example above:
// group 1 will match "25.0"
// group 2 will match "1.0"
// group 3 will match "12.0, 12.0 23.0, 9.0"
final RegExp _pointMatcher = new RegExp(r' *([\-\.0-9]+) *, *([\-\.0-9]+)(.*)');

/// Parse a string with a list of points, e.g:
/// '25.0, 1.0 12.0, 12.0 23.0, 9.0' will be parsed to:
/// [Point(25.0, 1.0), Point(12.0, 12.0), Point(23.0, 9.0)].
List<Point<double>> parsePoints(String points) {
  String unParsed = points;
  final List<Point<double>> result = <Point<double>>[];
  while(unParsed.isNotEmpty && _pointMatcher.hasMatch(unParsed)) {
    final Match m = _pointMatcher.firstMatch(unParsed);
    result.add(new Point<double>(
        double.parse(m.group(1)),
        double.parse(m.group(2))
    ));
    unParsed = m.group(3);
  }
  return result;
}

/// Data for a single animation frame.
class FrameData {
  const FrameData(this.size, this.paths);

  final Point<double> size;
  final List<SvgPath> paths;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FrameData &&
              runtimeType == other.runtimeType &&
              size == other.size &&
              const ListEquality<SvgPath>().equals(paths, other.paths);

  @override
  int get hashCode =>
      size.hashCode ^
      paths.hashCode;

  @override
  String toString() {
    return 'FrameData{size: $size, paths: $paths}';
  }
}

/// Represents an SVG path element.
class SvgPath {
  const SvgPath(this.id, this.commands);

  final String id;
  final List<SvgPathCommand> commands;

  static final RegExp _pathCommandMatcher = new RegExp(r'([MmLlQqCcAZz]) *([\-\.0-9 ,]*)');

  static SvgPath fromElement(XmlElement pathElement) {
    assert(pathElement.name.local == 'path');
    final String id = _extractAttr(pathElement, 'id');
    final String dAttr = _extractAttr(pathElement, 'd');
    final List<SvgPathCommand> commands = <SvgPathCommand> [];
    for (Match match in _pathCommandMatcher.allMatches(dAttr)) {
      final String commandType = match.group(1);
      final String pointStr = match.group(2);
      commands.add(new SvgPathCommand(commandType, parsePoints(pointStr)));
    }
    return new SvgPath(id, commands);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (
          other is SvgPath &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          const ListEquality<SvgPathCommand>().equals(commands, other.commands)
      );

  @override
  int get hashCode =>
      id.hashCode ^
      commands.hashCode;

  @override
  String toString() {
    return 'SvgPath(id: $id, commands: $commands)';
  }
}

/// Represents a single SVG path command from an SVG d element.
///
/// This class normalizes all the 'd' commands into a single type, that has
/// a command type and a list of points.
///
/// Some examples of how d commands translated to SvgPathCommand:
///   * "M 0.0, 1.0" => SvgPathCommand('M', [Point(0.0, 1.0)])
///   * "Z" => SvgPathCommand('Z', [])
///   * "C 1.0, 1.0 2.0, 2.0 3.0, 3.0" SvgPathCommand('C', [Point(1.0, 1.0),
///      Point(2.0, 2.0), Point(3.0, 3.0)])
class SvgPathCommand {
  const SvgPathCommand(this.type, this.points);

  /// The command type.
  final String type;

  /// List of points used by this command.
  final List<Point<double>> points;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SvgPathCommand &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              const ListEquality<Point<double>>().equals(points, other.points);

  @override
  int get hashCode =>
      type.hashCode ^
      points.hashCode;

  @override
  String toString() {
    return 'SvgPathCommand{command: $type, points: $points}';
  }
}

// Matches a pixels expression e.g "14px".
// First group is just the number.
final RegExp _pixelsExp = new RegExp('^([0-9]+)px\$');

/// Parses a pixel expression, e.g "14px", and returns the number.
/// Throws an [ArgumentError] if the given string doesn't match the pattern.
int parsePixels(String pixels) {
  if (!_pixelsExp.hasMatch(pixels))
    throw new ArgumentError('illegal pixels expression: \'$pixels\'');
  return int.parse(_pixelsExp.firstMatch(pixels).group(1));
}

String _extractAttr(XmlElement element, String name) {
  try {
    return element.attributes.singleWhere((XmlAttribute x) => x.name.local == name)
        .value;
  } catch (e) {
    throw new ArgumentError(
        'Can\'t find a single \'$name\' attributes in ${element.name}, '
        'attributes were: ${element.attributes}'
    );
  }
}

XmlElement _extractSvgElement(XmlDocument document) {
  return document.children.singleWhere(
          (XmlNode node) => node.nodeType  == XmlNodeType.ELEMENT
          && _asElement(node).name.local == 'svg'
  );
}

XmlElement _asElement(XmlNode node) => node;