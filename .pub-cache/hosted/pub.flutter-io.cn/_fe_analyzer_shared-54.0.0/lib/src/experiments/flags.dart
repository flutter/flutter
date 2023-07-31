// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

/// Enum for experimental flags shared between the CFE and the analyzer.
enum ExperimentalFlag {
  classModifiers(
      name: 'class-modifiers',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  constFunctions(
      name: 'const-functions',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  constantUpdate2018(
      name: 'constant-update-2018',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 0),
      experimentReleasedVersion: const Version(2, 0)),

  constructorTearoffs(
      name: 'constructor-tearoffs',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 15),
      experimentReleasedVersion: const Version(2, 15)),

  controlFlowCollections(
      name: 'control-flow-collections',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 0),
      experimentReleasedVersion: const Version(2, 0)),

  enhancedEnums(
      name: 'enhanced-enums',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 17),
      experimentReleasedVersion: const Version(2, 17)),

  extensionMethods(
      name: 'extension-methods',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 6),
      experimentReleasedVersion: const Version(2, 6)),

  extensionTypes(
      name: 'extension-types',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  genericMetadata(
      name: 'generic-metadata',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 14),
      experimentReleasedVersion: const Version(2, 14)),

  inferenceUpdate1(
      name: 'inference-update-1',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 18),
      experimentReleasedVersion: const Version(2, 18)),

  inferenceUpdate2(
      name: 'inference-update-2',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  inlineClass(
      name: 'inline-class',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  macros(
      name: 'macros',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  namedArgumentsAnywhere(
      name: 'named-arguments-anywhere',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 17),
      experimentReleasedVersion: const Version(2, 17)),

  nonNullable(
      name: 'non-nullable',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 12),
      experimentReleasedVersion: const Version(2, 10)),

  nonfunctionTypeAliases(
      name: 'nonfunction-type-aliases',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 13),
      experimentReleasedVersion: const Version(2, 13)),

  patterns(
      name: 'patterns',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  records(
      name: 'records',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(2, 19)),

  sealedClass(
      name: 'sealed-class',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  setLiterals(
      name: 'set-literals',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 0),
      experimentReleasedVersion: const Version(2, 0)),

  spreadCollections(
      name: 'spread-collections',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 0),
      experimentReleasedVersion: const Version(2, 0)),

  superParameters(
      name: 'super-parameters',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 17),
      experimentReleasedVersion: const Version(2, 17)),

  testExperiment(
      name: 'test-experiment',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  tripleShift(
      name: 'triple-shift',
      isEnabledByDefault: true,
      isExpired: true,
      experimentEnabledVersion: const Version(2, 14),
      experimentReleasedVersion: const Version(2, 14)),

  unnamedLibraries(
      name: 'unnamed-libraries',
      isEnabledByDefault: true,
      isExpired: false,
      experimentEnabledVersion: const Version(2, 19),
      experimentReleasedVersion: const Version(2, 19)),

  valueClass(
      name: 'value-class',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),

  variance(
      name: 'variance',
      isEnabledByDefault: false,
      isExpired: false,
      experimentEnabledVersion: const Version(3, 0),
      experimentReleasedVersion: const Version(3, 0)),
  ;

  final String name;
  final bool isEnabledByDefault;
  final bool isExpired;
  final Version experimentEnabledVersion;
  final Version experimentReleasedVersion;

  const ExperimentalFlag(
      {required this.name,
      required this.isEnabledByDefault,
      required this.isExpired,
      required this.experimentEnabledVersion,
      required this.experimentReleasedVersion});
}

class Version {
  final int major;
  final int minor;

  const Version(this.major, this.minor);

  String toText() => '$major.$minor';

  @override
  String toString() => toText();
}
