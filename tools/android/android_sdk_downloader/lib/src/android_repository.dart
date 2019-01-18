// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart' as xml show parse;
import 'package:xml/xml.dart';

// see https://android.googlesource.com/platform/tools/base/+/master/sdklib/src/main/java/com/android/sdklib/repository/sdk-repository-10.xsd

const String _kXsi = 'http://www.w3.org/2001/XMLSchema-instance';
const String _kSdk = 'http://schemas.android.com/sdk/android/repo/repository2/01';

void _debugCheckElement(
  XmlElement element,
  String name, {
  String namespace,
}) {
  assert(element != null);
  assert(element.name.local == name, '${element.name.local} != $name');
  assert(element.name.namespaceUri == namespace,
      '${element.name.namespaceUri} != $namespace');
}

XmlElement _firstOrDefault(Iterable<XmlElement> list) {
  if (list?.isEmpty == true) {
    return null;
  }
  return list.first;
}

String _getChildText(
  XmlElement parent,
  String childName, {
  String def = '',
  String namespace,
}) {
  final String value = _firstOrDefault(
    parent.findElements(
      childName,
      namespace: namespace,
    ),
  )?.text;
  return value ?? def;
}

OSType _parseHostType(String value) {
  switch (value) {
    case 'linux':
      return OSType.linux;
    case 'windows':
      return OSType.windows;
    case 'macosx':
      return OSType.mac;
    default:
      return OSType.any;
  }
}

/// Parses a the Android SDK's https://dl.google.com/android/repository/repository2-1.xml
/// into an [AndroidRepository] object.
AndroidRepository parseAndroidRepositoryXml(String rawXml) {
  final XmlDocument doc = xml.parse(rawXml);
  return AndroidRepository.fromXml(doc.rootElement);
}

XmlElement _getTypeDetails(XmlElement parent) {
  final XmlElement typeDetails =
      _firstOrDefault(parent.findAllElements('type-details'));
  if (typeDetails == null) {
    throw StateError('Missing <type-details>.');
  }
  return typeDetails;
}

String _getTypeDetailsType(XmlElement typeDetails) {
  return typeDetails.getAttribute('type', namespace: _kXsi);
}

Iterable<XmlElement> _getArchives(XmlElement parent) {
  assert(parent != null);
  final XmlElement archives =
      _firstOrDefault(parent.findAllElements('archives'));
  if (archives == null) {
    return null;
  }
  return archives.findElements('archive');
}

/// Object class for https://dl.google.com/android/repository/repository2-1.xml.
class AndroidRepository {
  const AndroidRepository(
    this.licenses,
    this.platforms,
    this.buildTools,
    this.platformTools,
    this.tools,
    this.ndkBundles,
  ) : assert(licenses != null),
      assert(platforms != null),
      assert(buildTools != null),
      assert(platformTools != null),
      assert(tools != null),
      assert(ndkBundles != null);

  /// Parses the `<sdk-repository>` element.
  factory AndroidRepository.fromXml(XmlElement element) {
    _debugCheckElement(element, 'sdk-repository', namespace: _kSdk);
    final List<AndroidRepositoryLicense> licenses =
        <AndroidRepositoryLicense>[];
    final List<AndroidRepositoryPlatform> platforms =
        <AndroidRepositoryPlatform>[];
    final List<AndroidRepositoryRemotePackage> buildTools =
        <AndroidRepositoryRemotePackage>[];
    final List<AndroidRepositoryRemotePackage> platformTools =
        <AndroidRepositoryRemotePackage>[];
    final List<AndroidRepositoryRemotePackage> tools =
        <AndroidRepositoryRemotePackage>[];

    final List<AndroidRepositoryRemotePackage> ndkBundles =
        <AndroidRepositoryRemotePackage>[];
    for (final XmlElement child in element.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'license':
          licenses.add(AndroidRepositoryLicense.fromXml(child));
          break;
        case 'remotePackage':
          final XmlElement typeDetails = _getTypeDetails(child);
          switch (_getTypeDetailsType(typeDetails)) {
            case 'sdk:platformDetailsType':
              platforms.add(
                AndroidRepositoryPlatform.fromXml(child, typeDetails),
              );
              break;
            case 'generic:genericDetailsType':
              final String path = child.getAttribute('path');
              if (path.startsWith('build-tools;')) {
                buildTools.add(AndroidRepositoryRemotePackage.fromXml(child));
              } else if (path.startsWith('platform-tools')) {
                platformTools
                    .add(AndroidRepositoryRemotePackage.fromXml(child));
              } else if (path.startsWith('tools')) {
                tools.add(AndroidRepositoryRemotePackage.fromXml(child));
              } else if (path.startsWith('ndk-bundle')) {
                ndkBundles.add(AndroidRepositoryRemotePackage.fromXml(child));
              }
              break;
            default:
              break;
          }
          break;
        default:
          break;
      }
    }
    return AndroidRepository(
      licenses,
      platforms,
      buildTools,
      platformTools,
      tools,
      ndkBundles,
    );
  }

  /// Licenses from the repository XML.
  final List<AndroidRepositoryLicense> licenses;

  /// Platform information from the repository XML.
  final List<AndroidRepositoryPlatform> platforms;

  /// Build tools information from the repostiory XML.
  final List<AndroidRepositoryRemotePackage> buildTools;

  /// Platform tools information from the repostiory XML.
  final List<AndroidRepositoryRemotePackage> platformTools;

  /// Tools information from the repostiory XML.
  final List<AndroidRepositoryRemotePackage> tools;

  /// Tools information from the repostiory XML.
  final List<AndroidRepositoryRemotePackage> ndkBundles;
}

/// Object class for the `<license>` element in the Android repo XML.
///
/// This node contains license information for the packages in the SDK.
class AndroidRepositoryLicense {
  /// Creates a new RepositoryLicense holder.
  const AndroidRepositoryLicense(this.id, this.text)
      : assert(id != null),
        assert(text != null);

  /// Parses a `<license>` element.
  factory AndroidRepositoryLicense.fromXml(XmlElement element) {
    _debugCheckElement(element, 'license');
    return AndroidRepositoryLicense(element.getAttribute('id'), element.text);
  }

  /// The identifier for this license.
  final String id;

  /// The text of the license.
  final String text;
}

/// Object class for the `<remotePackage>` nodes in the repo XML.
///
/// These nodes contain information about where to download the zipped
/// binaries for various components of the SDK.
class AndroidRepositoryRemotePackage {
  const AndroidRepositoryRemotePackage(
    this.revision,
    this.displayName,
    this.archives, {
    this.isObsolete = false,
  }) : assert(revision != null),
       assert(displayName != null),
       assert(archives != null),
       assert(isObsolete != null);

  factory AndroidRepositoryRemotePackage.fromXml(XmlElement element) {
    _debugCheckElement(element, 'remotePackage');

    return AndroidRepositoryRemotePackage(
      AndroidRepositoryRevision.fromXml(
          _firstOrDefault(element.findElements('revision'))),
      _getChildText(element, 'display-name'),
      _getArchives(element)
          .map(
            (XmlElement archive) => AndroidRepositoryArchive.fromXml(archive),
          )
          .toList(),
      isObsolete: element.getAttribute('obsolete') == 'true',
    );
  }

  /// The `<revision>` element, if any.
  final AndroidRepositoryRevision revision;

  /// The `<display-name>` element.
  final String displayName;

  /// The list of archives available for this package.
  final List<AndroidRepositoryArchive> archives;

  /// Whether this package is marked as obsolete.
  final bool isObsolete;

  @override
  String toString() => '$runtimeType{revision: $revision, displayName: $displayName, archives: $archives}';
}

/// Object class for instances of `<remotePackage>` elements that are for the
/// platform package.
class AndroidRepositoryPlatform extends AndroidRepositoryRemotePackage {
  const AndroidRepositoryPlatform(
    AndroidRepositoryRevision revision,
    String displayName,
    List<AndroidRepositoryArchive> archives,
    this.apiLevel, {
    bool isObsolete = false,
  }) : assert(apiLevel != null),
       super(revision, displayName, archives, isObsolete: isObsolete);

  /// Parses an platform from a `<remotePackage>` element.
  factory AndroidRepositoryPlatform.fromXml(
    XmlElement element,
    XmlElement typeDetails,
  ) {
    _debugCheckElement(element, 'remotePackage');
    assert(typeDetails != null);

    return AndroidRepositoryPlatform(
      AndroidRepositoryRevision.fromXml(
          _firstOrDefault(element.findElements('revision'))),
      _getChildText(element, 'display-name'),
      _getArchives(element)
          .map(
            (XmlElement archive) => AndroidRepositoryArchive.fromXml(archive),
          )
          .toList(),
      int.parse(_getChildText(typeDetails, 'api-level', def: '0')),
      isObsolete: element.getAttribute('obsolete') == 'true',
    );
  }

  /// The API level for this Platform.
  final int apiLevel;

  @override
  String toString() => '$runtimeType{revision: $revision, displayName: $displayName, archives: $archives, apiLevel: $apiLevel}';
}

/// The OS types supported by Android.
enum OSType {
  /// Any OS is supported.
  any,

  /// Suppoorts Linux only.
  linux,

  /// Supports macOS only.
  mac,

  /// Supports windows only.
  windows,
}

/// Object class for the `<archive>` element in the Android repo XML.
///
/// Contains information about the size, checksum, and location of a binary
/// zip archive. Optionally contains information about what host OS is
/// supported.
class AndroidRepositoryArchive {
  /// Creates a new AndroidRepositoryArchive.
  const AndroidRepositoryArchive(
    this.size,
    this.checksum,
    this.url, {
    this.hostOS = OSType.any,
  }) : assert(size != null),
       assert(checksum != null),
       assert(url != null),
       assert(hostOS != null);

  /// Parses an `<archive>` element.
  factory AndroidRepositoryArchive.fromXml(XmlElement element) {
    _debugCheckElement(element, 'archive');
    final XmlElement complete =
        _firstOrDefault(element.findElements('complete'));
    if (complete == null) {
      throw StateError('Found <archive> element without a <complete> node!');
    }

    return AndroidRepositoryArchive(
      int.parse(_getChildText(complete, 'size', def: '0')),
      _getChildText(complete, 'checksum'),
      _getChildText(complete, 'url'),
      hostOS: _parseHostType(_getChildText(element, 'host-os')),
    );
  }

  /// The download size in bytes of the archive.
  final int size;

  /// The SHA-1 checksum of the archive.
  final String checksum;

  /// The absolute or relative URL of the file.
  final String url;

  /// The OS type, if applicable, for this archive.
  final OSType hostOS;

  @override
  String toString() => '$runtimeType{size: $size, checksum: $checksum, url: $url, hostOS: $hostOS}';
}

/// Object class for a `<revision>` node in the Android repo XML.
///
/// Contains information about the revision of the archive.
///
/// In the case of the platform package, this is the revision of the platform.
///
/// In all other cases, this basically works like semver.
class AndroidRepositoryRevision {
  /// Creates a new Android repository revision object. All values are required.
  const AndroidRepositoryRevision(
    this.major, [
    this.minor = 0,
    this.micro = 0,
    this.preview = 0,
  ]) : assert(major != null),
       assert(minor != null),
       assert(micro != null),
       assert(preview != null);

  /// Parses a `<revision>` element from the Android repository XML.
  factory AndroidRepositoryRevision.fromXml(XmlElement element) {
    if (element == null) {
      return const AndroidRepositoryRevision(0);
    }
    _debugCheckElement(element, 'revision');
    return AndroidRepositoryRevision(
      int.tryParse(_getChildText(element, 'major', def: '0')),
      int.tryParse(_getChildText(element, 'minor', def: '0')),
      int.tryParse(_getChildText(element, 'micro', def: '0')),
    );
  }

  /// The major revision value.
  final int major;

  /// The minor revision value.
  final int minor;

  /// The micro revision.
  final int micro;

  /// Preview/Release candidate version. A value of 0 indicates that
  /// this is not a preview.
  final int preview;

  /// Whether this revision represents a preview or release.
  bool get isPreview => preview > 0;

  bool matches(int major, int minor, int micro, [int preview = 0]) {
    return this.major == major &&
        this.minor == minor &&
        this.micro == micro &&
        this.preview == preview;
  }

  @override
  String toString() => '$runtimeType:{$major.$minor.$micro.$preview}';
}
