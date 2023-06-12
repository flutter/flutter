// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package, lines_longer_than_80_chars, require_trailing_commas, unnecessary_cast

part of 'pubspec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pubspec _$PubspecFromJson(Map json) => $checkedCreate(
      'Pubspec',
      json,
      ($checkedConvert) {
        final val = Pubspec(
          $checkedConvert('name', (v) => v as String),
          version: $checkedConvert(
              'version', (v) => _versionFromString(v as String?)),
          publishTo: $checkedConvert('publish_to', (v) => v as String?),
          author: $checkedConvert('author', (v) => v as String?),
          authors: $checkedConvert('authors',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          environment:
              $checkedConvert('environment', (v) => _environmentMap(v as Map?)),
          homepage: $checkedConvert('homepage', (v) => v as String?),
          repository: $checkedConvert(
              'repository', (v) => v == null ? null : Uri.parse(v as String)),
          issueTracker: $checkedConvert('issue_tracker',
              (v) => v == null ? null : Uri.parse(v as String)),
          funding: $checkedConvert(
              'funding',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Uri.parse(e as String))
                  .toList()),
          screenshots: $checkedConvert(
              'screenshots', (v) => parseScreenshots(v as List?)),
          documentation: $checkedConvert('documentation', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
          dependencies:
              $checkedConvert('dependencies', (v) => parseDeps(v as Map?)),
          devDependencies:
              $checkedConvert('dev_dependencies', (v) => parseDeps(v as Map?)),
          dependencyOverrides: $checkedConvert(
              'dependency_overrides', (v) => parseDeps(v as Map?)),
          flutter: $checkedConvert(
              'flutter',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'publishTo': 'publish_to',
        'issueTracker': 'issue_tracker',
        'devDependencies': 'dev_dependencies',
        'dependencyOverrides': 'dependency_overrides'
      },
    );
