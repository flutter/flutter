// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package, lines_longer_than_80_chars, require_trailing_commas, unnecessary_cast

part of 'dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SdkDependency _$SdkDependencyFromJson(Map json) => $checkedCreate(
      'SdkDependency',
      json,
      ($checkedConvert) {
        final val = SdkDependency(
          $checkedConvert('sdk', (v) => v as String),
          version: $checkedConvert(
              'version', (v) => _constraintFromString(v as String?)),
        );
        return val;
      },
    );

GitDependency _$GitDependencyFromJson(Map json) => $checkedCreate(
      'GitDependency',
      json,
      ($checkedConvert) {
        final val = GitDependency(
          $checkedConvert('url', (v) => parseGitUri(v as String)),
          ref: $checkedConvert('ref', (v) => v as String?),
          path: $checkedConvert('path', (v) => v as String?),
        );
        return val;
      },
    );

HostedDependency _$HostedDependencyFromJson(Map json) => $checkedCreate(
      'HostedDependency',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['version', 'hosted'],
          disallowNullValues: const ['hosted'],
        );
        final val = HostedDependency(
          version: $checkedConvert(
              'version', (v) => _constraintFromString(v as String?)),
          hosted: $checkedConvert('hosted',
              (v) => v == null ? null : HostedDetails.fromJson(v as Object)),
        );
        return val;
      },
    );

HostedDetails _$HostedDetailsFromJson(Map json) => $checkedCreate(
      'HostedDetails',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['name', 'url'],
          disallowNullValues: const ['url'],
        );
        final val = HostedDetails(
          $checkedConvert('name', (v) => v as String?),
          $checkedConvert('url', (v) => parseGitUriOrNull(v as String?)),
        );
        return val;
      },
      fieldKeyMap: const {'declaredName': 'name'},
    );
