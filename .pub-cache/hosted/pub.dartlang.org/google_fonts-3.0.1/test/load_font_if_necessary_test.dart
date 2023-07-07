import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/asset_manifest.dart';
import 'package:google_fonts/src/google_fonts_base.dart';
import 'package:google_fonts/src/google_fonts_descriptor.dart';
import 'package:google_fonts/src/google_fonts_family_with_variant.dart';
import 'package:google_fonts/src/google_fonts_variant.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHttpClient extends Mock implements http.Client {
  Future<http.Response> gets(dynamic uri, {dynamic headers}) {
    super.noSuchMethod(Invocation.method(#get, [uri], {#headers: headers}));
    return Future.value(http.Response('', 200));
  }
}

class MockAssetManifest extends Mock implements AssetManifest {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this._applicationSupportPath);

  final String _applicationSupportPath;

  @override
  Future<String?> getApplicationSupportPath() async {
    return _applicationSupportPath;
  }
}

const _fakeResponse = 'fake response body - success';
// The number of bytes in _fakeResponse.
const _fakeResponseLengthInBytes = 28;
// Computed by converting _fakeResponse to bytes and getting sha 256 hash.
const _fakeResponseHash =
    '1194f6ffe4d2f05258573616a77932c38041f3102763096c19437c3db1818a04';
const expectedCachedFile =
    'Foo_regular_1194f6ffe4d2f05258573616a77932c38041f3102763096c19437c3db1818a04.ttf';
// ignore: unused_element
const _fakeResponseDifferent = 'different response';
// The number of bytes in _fakeResponseDifferent.
const _fakeResponseDifferentLengthInBytes = 18;
// Computed by converting _fakeResponseDifferent to bytes and getting sha 256 hash.
const _fakeResponseDifferentHash =
    '2a989d235f2408511069bc7d8460c62aec1a75ac399bd7f2a2ae740c4326dadf';
const expectedDifferentCachedFile =
    'Foo_regular_2a989d235f2408511069bc7d8460c62aec1a75ac399bd7f2a2ae740c4326dadf.ttf';

final _fakeResponseFile = GoogleFontsFile(
  _fakeResponseHash,
  _fakeResponseLengthInBytes,
);
final _fakeResponseDifferentFile = GoogleFontsFile(
  _fakeResponseDifferentHash,
  _fakeResponseDifferentLengthInBytes,
);

final fakeDescriptor = GoogleFontsDescriptor(
  familyWithVariant: const GoogleFontsFamilyWithVariant(
      family: 'Foo',
      googleFontsVariant: GoogleFontsVariant(
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.normal,
      )),
  file: _fakeResponseFile,
);

// Same family & variant, different file.
final fakeDescriptorDifferentFile = GoogleFontsDescriptor(
  familyWithVariant: fakeDescriptor.familyWithVariant,
  file: _fakeResponseDifferentFile,
);

var printLog = <String>[];

void overridePrint(Future<void> Function() testFn) => () {
      var spec = ZoneSpecification(print: (_, __, ___, msg) {
        // Add to log instead of printing to stdout
        printLog.add(msg);
      });
      return Zone.current.fork(specification: spec).run(testFn);
    };

void main() {
  late Directory directory;
  late MockHttpClient mockHttpClient;

  setUp(() async {
    mockHttpClient = MockHttpClient();
    httpClient = mockHttpClient;
    assetManifest = MockAssetManifest();
    GoogleFonts.config.allowRuntimeFetching = true;
    when(mockHttpClient.gets(any)).thenAnswer((_) async {
      return http.Response(_fakeResponse, 200);
    });

    directory = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = FakePathProviderPlatform(directory.path);
  });

  tearDown(() {
    printLog.clear();
    clearCache();
  });

  test('loadFontIfNecessary method calls http get', () async {
    await loadFontIfNecessary(fakeDescriptor);

    verify(mockHttpClient.gets(anything)).called(1);
  });

  test('loadFontIfNecessary method throws if font cannot be loaded', () async {
    // Mock a bad response.
    when(mockHttpClient.gets(any)).thenAnswer((_) async {
      return http.Response('fake response body - failure', 300);
    });

    final descriptorInAssets = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
      file: _fakeResponseFile,
    );

    // Call loadFontIfNecessary and verify that it prints an error.
    overridePrint(() async {
      await loadFontIfNecessary(descriptorInAssets);
      expect(printLog.length, 1);
      expect(
        printLog[0],
        startsWith('google_fonts was unable to load font Foo-BlackItalic'),
      );
    });
  });

  test('does not call http if config is false', () async {
    final fakeDescriptor = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      file: _fakeResponseFile,
    );

    GoogleFonts.config.allowRuntimeFetching = false;

    // Call loadFontIfNecessary and verify that it prints an error.
    overridePrint(() async {
      await loadFontIfNecessary(fakeDescriptor);
      expect(printLog.length, 1);
      expect(
        printLog[0],
        startsWith('google_fonts was unable to load font Foo-Regular'),
      );
      expect(
        printLog[0],
        endsWith(
          "Ensure Foo-Regular.ttf exists in a folder that is included in your pubspec's assets.",
        ),
      );
    });

    verifyNever(mockHttpClient.gets(anything));
  });

  test(
      'loadFontIfNecessary method does not make http get request on '
      'subsequent calls', () async {
    final fakeDescriptor = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      file: _fakeResponseFile,
    );

    // 1st call.
    await loadFontIfNecessary(fakeDescriptor);
    verify(mockHttpClient.gets(anything)).called(1);

    // 2nd call.
    await loadFontIfNecessary(fakeDescriptor);
    verifyNever(mockHttpClient.gets(anything));

    // 3rd call.
    await loadFontIfNecessary(fakeDescriptor);
    verifyNever(mockHttpClient.gets(anything));
  });

  test(
      'loadFontIfNecessary does not make more than 1 http get request on '
      'parallel calls', () async {
    final fakeDescriptor = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      file: _fakeResponseFile,
    );

    await Future.wait([
      loadFontIfNecessary(fakeDescriptor),
      loadFontIfNecessary(fakeDescriptor),
      loadFontIfNecessary(fakeDescriptor)
    ]);
    verify(mockHttpClient.gets(anything)).called(1);
  });

  test('loadFontIfNecessary makes second attempt if the first attempt failed ',
      () async {
    final fakeDescriptor = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      file: _fakeResponseFile,
    );

    // Have the first call throw an error.
    when(mockHttpClient.gets(any)).thenThrow('error');
    await loadFontIfNecessary(fakeDescriptor);
    verify(mockHttpClient.gets(any)).called(1);

    // The second call will retry the http fetch.
    when(mockHttpClient.gets(any)).thenAnswer((_) async {
      return http.Response(_fakeResponse, 200);
    });
    await loadFontIfNecessary(fakeDescriptor);
    verify(mockHttpClient.gets(any)).called(1);
  });

  test('loadFontIfNecessary method correctly stores in cache', () async {
    var directoryContents = await getApplicationSupportDirectory();
    expect(directoryContents.listSync().isEmpty, isTrue);

    await loadFontIfNecessary(fakeDescriptor);
    // Give enough time for the file to be saved
    await Future.delayed(const Duration(seconds: 1), () {});
    directoryContents = await getApplicationSupportDirectory();

    expect(directoryContents.listSync().isNotEmpty, isTrue);

    expect(directoryContents.listSync().single.toString(),
        contains(expectedCachedFile));
  });

  test('loadFontIfNecessary method correctly uses cache', () async {
    var directoryContents = await getApplicationSupportDirectory();
    expect(directoryContents.listSync().isEmpty, isTrue);

    final cachedFile = File(
      '${directoryContents.path}/$expectedCachedFile',
    );
    cachedFile.createSync();
    cachedFile.writeAsStringSync('file contents');

    // Should use cache from now on.
    await loadFontIfNecessary(fakeDescriptor);
    await loadFontIfNecessary(fakeDescriptor);
    await loadFontIfNecessary(fakeDescriptor);
    verifyNever(mockHttpClient.gets(anything));
  });

  test('loadFontIfNecessary method re-caches when font file changes', () async {
    when(mockHttpClient.gets(any)).thenAnswer((_) async {
      return http.Response(_fakeResponseDifferent, 200);
    });

    var directoryContents = await getApplicationSupportDirectory();
    expect(directoryContents.listSync().isEmpty, isTrue);

    final cachedFile = File(
      '${directoryContents.path}/$expectedCachedFile',
    );
    cachedFile.createSync();
    cachedFile.writeAsStringSync('file contents');

    // What if the file is different (e.g. the font has been improved)?
    await loadFontIfNecessary(fakeDescriptorDifferentFile);
    verify(mockHttpClient.gets(any)).called(1);

    // Give enough time for the file to be saved
    await Future.delayed(const Duration(seconds: 1), () {});
    expect(directoryContents.listSync().length == 2, isTrue);
    expect(
      directoryContents.listSync().toString(),
      contains(expectedDifferentCachedFile),
    );

    // Should use cache from now on.
    await loadFontIfNecessary(fakeDescriptorDifferentFile);
    await loadFontIfNecessary(fakeDescriptorDifferentFile);
    await loadFontIfNecessary(fakeDescriptorDifferentFile);
    verifyNever(mockHttpClient.gets(anything));
  });

  test(
      'loadFontIfNecessary does not save anything to disk if the file does not '
      'match the expected hash', () async {
    when(mockHttpClient.gets(any)).thenAnswer((_) async {
      return http.Response('malicious intercepted response', 200);
    });
    final fakeDescriptor = GoogleFontsDescriptor(
      familyWithVariant: const GoogleFontsFamilyWithVariant(
        family: 'Foo',
        googleFontsVariant: GoogleFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      file: _fakeResponseFile,
    );

    var directoryContents = await getApplicationSupportDirectory();
    expect(directoryContents.listSync().isEmpty, isTrue);

    await loadFontIfNecessary(fakeDescriptor);
    directoryContents = await getApplicationSupportDirectory();
    expect(directoryContents.listSync().isEmpty, isTrue);
  });

  test("loadFontByteData doesn't fail", () {
    expect(
      () async => loadFontByteData('fontFamily', Future.value(ByteData(0))),
      returnsNormally,
    );
    expect(
      () async => loadFontByteData('fontFamily', Future.value(null)),
      returnsNormally,
    );
    expect(
      () async => loadFontByteData('fontFamily', null),
      returnsNormally,
    );

    expect(
      () async => loadFontByteData('fontFamily',
          Future.delayed(const Duration(milliseconds: 100), () => null)),
      returnsNormally,
    );
  });
}
