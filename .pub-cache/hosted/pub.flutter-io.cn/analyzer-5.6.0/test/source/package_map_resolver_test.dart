// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_PackageMapUriResolverTest);
  });
}

@reflectiveTest
class _PackageMapUriResolverTest {
  static const Map<String, List<Folder>> emptyMap = {};
  MemoryResourceProvider provider = MemoryResourceProvider();

  void test_isPackageUri() {
    Uri uri = Uri.parse('package:test/test.dart');
    expect(uri.scheme, 'package');
    expect(PackageMapUriResolver.isPackageUri(uri), isTrue);
  }

  void test_isPackageUri_null_scheme() {
    Uri uri = Uri.parse('foo.dart');
    expect(uri.scheme, '');
    expect(PackageMapUriResolver.isPackageUri(uri), isFalse);
  }

  void test_isPackageUri_other_scheme() {
    Uri uri = Uri.parse('memfs:/foo.dart');
    expect(uri.scheme, 'memfs');
    expect(PackageMapUriResolver.isPackageUri(uri), isFalse);
  }

  void test_pathToUri() {
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/src/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[provider.getFolder(provider.convertPath('/pkgA/lib'))],
      'pkgB': <Folder>[provider.getFolder(provider.convertPath('/pkgB/lib'))]
    });
    {
      var path = provider.convertPath('/pkgA/lib/libA.dart');
      var uri = resolver.pathToUri(path);
      expect(uri, Uri.parse('package:pkgA/libA.dart'));
    }
    {
      var path = provider.convertPath('/pkgB/lib/src/libB.dart');
      var uri = resolver.pathToUri(path);
      expect(uri, Uri.parse('package:pkgB/src/libB.dart'));
    }
    {
      var path = provider.convertPath('/no/such/file');
      var uri = resolver.pathToUri(path);
      expect(uri, isNull);
    }
  }

  void test_resolve_multiple_folders() {
    var a = provider.newFile(provider.convertPath('/aaa/a.dart'), '');
    var b = provider.newFile(provider.convertPath('/bbb/b.dart'), '');
    expect(() {
      PackageMapUriResolver(provider, <String, List<Folder>>{
        'pkg': <Folder>[a.parent, b.parent]
      });
    }, throwsArgumentError);
  }

  void test_resolve_nonPackage() {
    UriResolver resolver = PackageMapUriResolver(provider, emptyMap);
    Uri uri = Uri.parse('dart:core');
    var result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_OK() {
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[provider.getFolder(provider.convertPath('/pkgA/lib'))],
      'pkgB': <Folder>[provider.getFolder(provider.convertPath('/pkgB/lib'))]
    });
    {
      Uri uri = Uri.parse('package:pkgA/libA.dart');
      var result = resolver.resolveAbsolute(uri)!;
      expect(result.exists(), isTrue);
      expect(result.uri, uri);
      expect(result.fullName, pkgFileA);
    }
    {
      Uri uri = Uri.parse('package:pkgB/libB.dart');
      var result = resolver.resolveAbsolute(uri)!;
      expect(result.exists(), isTrue);
      expect(result.uri, uri);
      expect(result.fullName, pkgFileB);
    }
  }

  void test_resolve_OK_withNonAscii() {
    var resolver = PackageMapUriResolver(provider, {
      'aaa': <Folder>[
        provider.getFolder(
          provider.convertPath('/packages/aaa/lib'),
        ),
      ],
    });

    var uri = Uri.parse('package:aaa/проба/a.dart');
    var result = resolver.resolveAbsolute(uri)!;
    expect(
      result.fullName,
      provider.convertPath('/packages/aaa/lib/проба/a.dart'),
    );
  }

  void test_resolve_OK_withSpace() {
    var resolver = PackageMapUriResolver(provider, {
      'aaa': <Folder>[
        provider.getFolder(
          provider.convertPath('/packages/aaa/lib'),
        ),
      ],
    });

    var uri = Uri.parse('package:aaa/with space/a.dart');
    var result = resolver.resolveAbsolute(uri)!;
    expect(
      result.fullName,
      provider.convertPath('/packages/aaa/lib/with space/a.dart'),
    );
  }

  void test_resolve_package_invalid_leadingSlash() {
    UriResolver resolver = PackageMapUriResolver(provider, emptyMap);
    Uri uri = Uri.parse('package:/foo');
    var result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_noSlash() {
    UriResolver resolver = PackageMapUriResolver(provider, emptyMap);
    Uri uri = Uri.parse('package:foo');
    var result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_onlySlash() {
    UriResolver resolver = PackageMapUriResolver(provider, emptyMap);
    Uri uri = Uri.parse('package:/');
    var result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_notInMap() {
    UriResolver resolver = PackageMapUriResolver(provider, emptyMap);
    Uri uri = Uri.parse('package:analyzer/analyzer.dart');
    var result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }
}
