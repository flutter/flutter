// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:collection/collection.dart';

import 'configuration/skip.dart';
import 'configuration/timeout.dart';
import 'platform_selector.dart';
import 'suite_platform.dart';
import 'util/identifier_regex.dart';
import 'util/pretty_print.dart';

/// Metadata for a test or test suite.
///
/// This metadata comes from declarations on the test itself; it doesn't include
/// configuration from the user.
class Metadata {
  /// Empty metadata with only default values.
  ///
  /// Using this is slightly more efficient than manually constructing a new
  /// metadata with no arguments.
  static final empty = Metadata._();

  /// The selector indicating which platforms the suite supports.
  final PlatformSelector testOn;

  /// The modification to the timeout for the test or suite.
  final Timeout timeout;

  /// Whether the test or suite should be skipped.
  bool get skip => _skip ?? false;
  final bool? _skip;

  /// The reason the test or suite should be skipped, if given.
  final String? skipReason;

  /// Whether to use verbose stack traces.
  bool get verboseTrace => _verboseTrace ?? false;
  final bool? _verboseTrace;

  /// Whether to chain stack traces.
  bool get chainStackTraces => _chainStackTraces ?? _verboseTrace ?? false;
  final bool? _chainStackTraces;

  /// The user-defined tags attached to the test or suite.
  final Set<String> tags;

  /// The number of times to re-run a test before being marked as a failure.
  int get retry => _retry ?? 0;
  final int? _retry;

  /// Platform-specific metadata.
  ///
  /// Each key identifies a platform, and its value identifies the specific
  /// metadata for that platform. These can be applied by calling [forPlatform].
  final Map<PlatformSelector, Metadata> onPlatform;

  /// Metadata that applies only when specific tags are applied.
  ///
  /// Tag-specific metadata is applied when merging this with other metadata.
  /// Note that unlike [onPlatform], the base metadata takes precedence over any
  /// tag-specific metadata.
  ///
  /// This is guaranteed not to have any keys that match [tags]; those are
  /// resolved when the metadata is constructed.
  final Map<BooleanSelector, Metadata> forTag;

  /// The language version comment, if one is present.
  ///
  /// Only available for test suites and not individual tests.
  final String? languageVersionComment;

  /// Parses a user-provided map into the value for [onPlatform].
  static Map<PlatformSelector, Metadata> _parseOnPlatform(
      Map<String, dynamic>? onPlatform) {
    if (onPlatform == null) return {};

    var result = <PlatformSelector, Metadata>{};
    onPlatform.forEach((platform, metadata) {
      var selector = PlatformSelector.parse(platform);
      if (metadata is Timeout || metadata is Skip) {
        result[selector] = _parsePlatformOptions(platform, [metadata]);
      } else if (metadata is List) {
        result[selector] = _parsePlatformOptions(platform, metadata);
      } else {
        throw ArgumentError('Metadata for platform "$platform" must be a '
            'Timeout, Skip, or List of those; was "$metadata".');
      }
    });
    return result;
  }

  static Metadata _parsePlatformOptions(
      String platform, List<dynamic> metadata) {
    Timeout? timeout;
    dynamic skip;
    for (var metadatum in metadata) {
      if (metadatum is Timeout) {
        if (timeout != null) {
          throw ArgumentError('Only a single Timeout may be declared for '
              '"$platform".');
        }

        timeout = metadatum;
      } else if (metadatum is Skip) {
        if (skip != null) {
          throw ArgumentError('Only a single Skip may be declared for '
              '"$platform".');
        }

        skip = metadatum.reason ?? true;
      } else {
        throw ArgumentError('Metadata for platform "$platform" must be a '
            'Timeout, Skip, or List of those; was "$metadata".');
      }
    }

    return Metadata.parse(timeout: timeout, skip: skip);
  }

  /// Parses a user-provided [String] or [Iterable] into the value for [tags].
  ///
  /// Throws an [ArgumentError] if [tags] is not a [String] or an [Iterable].
  static Set<String> _parseTags(tags) {
    if (tags == null) return {};
    if (tags is String) return {tags};
    if (tags is! Iterable) {
      throw ArgumentError.value(
          tags, 'tags', 'must be either a String or an Iterable.');
    }

    if (tags.any((tag) => tag is! String)) {
      throw ArgumentError.value(tags, 'tags', 'must contain only Strings.');
    }

    return Set.from(tags);
  }

  /// Creates new Metadata.
  ///
  /// [testOn] defaults to [PlatformSelector.all].
  ///
  /// If [forTag] contains metadata that applies to [tags], that metadata is
  /// included inline in the returned value. The values directly passed to the
  /// constructor take precedence over tag-specific metadata.
  factory Metadata(
      {PlatformSelector? testOn,
      Timeout? timeout,
      bool? skip,
      bool? verboseTrace,
      bool? chainStackTraces,
      int? retry,
      String? skipReason,
      Iterable<String>? tags,
      Map<PlatformSelector, Metadata>? onPlatform,
      Map<BooleanSelector, Metadata>? forTag,
      String? languageVersionComment}) {
    // Returns metadata without forTag resolved at all.
    Metadata unresolved() => Metadata._(
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        verboseTrace: verboseTrace,
        chainStackTraces: chainStackTraces,
        retry: retry,
        skipReason: skipReason,
        tags: tags,
        onPlatform: onPlatform,
        forTag: forTag,
        languageVersionComment: languageVersionComment);

    // If there's no tag-specific metadata, or if none of it applies, just
    // return the metadata as-is.
    if (forTag == null || tags == null) return unresolved();
    tags = Set.from(tags);
    forTag = Map.from(forTag);

    // Otherwise, resolve the tag-specific components. Doing this eagerly means
    // we only have to resolve suite- or group-level tags once, rather than
    // doing it for every test individually.
    var empty = Metadata._();
    var merged = forTag.keys.toList().fold(empty, (Metadata merged, selector) {
      if (!selector.evaluate(tags!.contains)) return merged;
      return merged.merge(forTag!.remove(selector)!);
    });

    if (merged == empty) return unresolved();
    return merged.merge(unresolved());
  }

  /// Creates new Metadata.
  ///
  /// Unlike [new Metadata], this assumes [forTag] is already resolved.
  Metadata._({
    PlatformSelector? testOn,
    Timeout? timeout,
    bool? skip,
    this.skipReason,
    bool? verboseTrace,
    bool? chainStackTraces,
    int? retry,
    Iterable<String>? tags,
    Map<PlatformSelector, Metadata>? onPlatform,
    Map<BooleanSelector, Metadata>? forTag,
    this.languageVersionComment,
  })  : testOn = testOn ?? PlatformSelector.all,
        timeout = timeout ?? const Timeout.factor(1),
        _skip = skip,
        _verboseTrace = verboseTrace,
        _chainStackTraces = chainStackTraces,
        _retry = retry,
        tags = UnmodifiableSetView(tags == null ? {} : tags.toSet()),
        onPlatform =
            onPlatform == null ? const {} : UnmodifiableMapView(onPlatform),
        forTag = forTag == null ? const {} : UnmodifiableMapView(forTag) {
    if (retry != null) RangeError.checkNotNegative(retry, 'retry');
    _validateTags();
  }

  /// Creates a new Metadata, but with fields parsed from caller-friendly values
  /// where applicable.
  ///
  /// Throws a [FormatException] if any field is invalid.
  Metadata.parse(
      {String? testOn,
      Timeout? timeout,
      dynamic skip,
      bool? verboseTrace,
      bool? chainStackTraces,
      int? retry,
      Map<String, dynamic>? onPlatform,
      tags,
      this.languageVersionComment})
      : testOn = testOn == null
            ? PlatformSelector.all
            : PlatformSelector.parse(testOn),
        timeout = timeout ?? const Timeout.factor(1),
        _skip = skip == null ? null : skip != false,
        _verboseTrace = verboseTrace,
        _chainStackTraces = chainStackTraces,
        _retry = retry,
        skipReason = skip is String ? skip : null,
        onPlatform = _parseOnPlatform(onPlatform),
        tags = _parseTags(tags),
        forTag = const {} {
    if (skip != null && skip is! String && skip is! bool) {
      throw ArgumentError('"skip" must be a String or a bool, was "$skip".');
    }

    if (retry != null) RangeError.checkNotNegative(retry, 'retry');

    _validateTags();
  }

  /// Deserializes the result of [Metadata.serialize] into a new [Metadata].
  Metadata.deserialize(serialized)
      : testOn = serialized['testOn'] == null
            ? PlatformSelector.all
            : PlatformSelector.parse(serialized['testOn'] as String),
        timeout = _deserializeTimeout(serialized['timeout']),
        _skip = serialized['skip'] as bool?,
        skipReason = serialized['skipReason'] as String?,
        _verboseTrace = serialized['verboseTrace'] as bool?,
        _chainStackTraces = serialized['chainStackTraces'] as bool?,
        _retry = serialized['retry'] as int?,
        tags = Set.from(serialized['tags'] as Iterable),
        onPlatform = {
          for (var pair in serialized['onPlatform'] as List)
            PlatformSelector.parse(pair.first as String):
                Metadata.deserialize(pair.last)
        },
        forTag = (serialized['forTag'] as Map).map((key, nested) => MapEntry(
            BooleanSelector.parse(key as String),
            Metadata.deserialize(nested))),
        languageVersionComment =
            serialized['languageVersionComment'] as String?;

  /// Deserializes timeout from the format returned by [_serializeTimeout].
  static Timeout _deserializeTimeout(serialized) {
    if (serialized == 'none') return Timeout.none;
    var scaleFactor = serialized['scaleFactor'];
    if (scaleFactor != null) return Timeout.factor(scaleFactor as num);
    return Timeout(Duration(microseconds: serialized['duration'] as int));
  }

  /// Throws an [ArgumentError] if any tags in [tags] aren't hyphenated
  /// identifiers.
  void _validateTags() {
    var invalidTags = tags
        .where((tag) => !tag.contains(anchoredHyphenatedIdentifier))
        .map((tag) => '"$tag"')
        .toList();

    if (invalidTags.isEmpty) return;

    throw ArgumentError("Invalid ${pluralize('tag', invalidTags.length)} "
        '${toSentence(invalidTags)}. Tags must be (optionally hyphenated) '
        'Dart identifiers.');
  }

  /// Throws a [FormatException] if any [PlatformSelector]s use any variables
  /// that don't appear either in [validVariables] or in the set of variables
  /// that are known to be valid for all selectors.
  void validatePlatformSelectors(Set<String> validVariables) {
    testOn.validate(validVariables);
    onPlatform.forEach((selector, metadata) {
      selector.validate(validVariables);
      metadata.validatePlatformSelectors(validVariables);
    });
  }

  /// Return a new [Metadata] that merges [this] with [other].
  ///
  /// If the two [Metadata]s have conflicting properties, [other] wins. If
  /// either has a [forTag] metadata for one of the other's tags, that metadata
  /// is merged as well.
  Metadata merge(Metadata other) => Metadata(
      testOn: testOn.intersection(other.testOn),
      timeout: timeout.merge(other.timeout),
      skip: other._skip ?? _skip,
      skipReason: other.skipReason ?? skipReason,
      verboseTrace: other._verboseTrace ?? _verboseTrace,
      chainStackTraces: other._chainStackTraces ?? _chainStackTraces,
      retry: other._retry ?? _retry,
      tags: tags.union(other.tags),
      onPlatform: mergeMaps(onPlatform, other.onPlatform,
          value: (metadata1, metadata2) => metadata1.merge(metadata2)),
      forTag: mergeMaps(forTag, other.forTag,
          value: (metadata1, metadata2) => metadata1.merge(metadata2)),
      languageVersionComment:
          other.languageVersionComment ?? languageVersionComment);

  /// Returns a copy of [this] with the given fields changed.
  Metadata change(
      {PlatformSelector? testOn,
      Timeout? timeout,
      bool? skip,
      bool? verboseTrace,
      bool? chainStackTraces,
      int? retry,
      String? skipReason,
      Map<PlatformSelector, Metadata>? onPlatform,
      Set<String>? tags,
      Map<BooleanSelector, Metadata>? forTag,
      String? languageVersionComment}) {
    testOn ??= this.testOn;
    timeout ??= this.timeout;
    skip ??= _skip;
    verboseTrace ??= _verboseTrace;
    chainStackTraces ??= _chainStackTraces;
    retry ??= _retry;
    skipReason ??= this.skipReason;
    onPlatform ??= this.onPlatform;
    tags ??= this.tags;
    forTag ??= this.forTag;
    languageVersionComment ??= this.languageVersionComment;
    return Metadata(
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        verboseTrace: verboseTrace,
        chainStackTraces: chainStackTraces,
        skipReason: skipReason,
        onPlatform: onPlatform,
        tags: tags,
        forTag: forTag,
        retry: retry,
        languageVersionComment: languageVersionComment);
  }

  /// Returns a copy of [this] with all platform-specific metadata from
  /// [onPlatform] resolved.
  Metadata forPlatform(SuitePlatform platform) {
    if (onPlatform.isEmpty) return this;

    var metadata = this;
    onPlatform.forEach((platformSelector, platformMetadata) {
      if (!platformSelector.evaluate(platform)) return;
      metadata = metadata.merge(platformMetadata);
    });
    return metadata.change(onPlatform: {});
  }

  /// Serializes [this] into a JSON-safe object that can be deserialized using
  /// [Metadata.deserialize].
  Map<String, dynamic> serialize() {
    // Make this a list to guarantee that the order is preserved.
    var serializedOnPlatform = [];
    onPlatform.forEach((key, value) {
      serializedOnPlatform.add([key.toString(), value.serialize()]);
    });

    return {
      'testOn': testOn == PlatformSelector.all ? null : testOn.toString(),
      'timeout': _serializeTimeout(timeout),
      'skip': _skip,
      'skipReason': skipReason,
      'verboseTrace': _verboseTrace,
      'chainStackTraces': _chainStackTraces,
      'retry': _retry,
      'tags': tags.toList(),
      'onPlatform': serializedOnPlatform,
      'forTag': forTag.map((selector, metadata) =>
          MapEntry(selector.toString(), metadata.serialize())),
      'languageVersionComment': languageVersionComment,
    };
  }

  /// Serializes timeout into a JSON-safe object.
  dynamic _serializeTimeout(Timeout timeout) {
    if (timeout == Timeout.none) return 'none';
    return {
      'duration': timeout.duration?.inMicroseconds,
      'scaleFactor': timeout.scaleFactor
    };
  }
}
