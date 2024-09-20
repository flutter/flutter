// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The package:analyzer parse of the `libraries` field depends on the current
// use of const.
// ignore_for_file: unnecessary_const

/// A bit flag used by [LibraryInfo] indicating that a library is used by
/// dart2js.
const int DART2JS_PLATFORM = 1;

/// A bit flag used by [LibraryInfo] indicating that a library is used by the
/// VM.
const int VM_PLATFORM = 2;

/// The contexts that a library can be used from.
enum Category {
  /// Indicates that a library can be used in a browser context.
  client,

  /// Indicates that a library can be used in a command line context.
  server,

  /// Indicates that a library can be used from embedded devices.
  embedded,
}

Category? parseCategory(String name) {
  switch (name) {
    case 'Client':
      return Category.client;
    case 'Server':
      return Category.server;
    case 'Embedded':
      return Category.embedded;
    default:
      return null;
  }
}

/// Mapping of "dart:" library name (e.g. "core") to information about that
/// library.
const Map<String, LibraryInfo> libraries = const {
  'async': const LibraryInfo(
    'async/async.dart',
    categories: 'Client,Server',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/async_patch.dart',
  ),
  'collection': const LibraryInfo(
    'collection/collection.dart',
    categories: 'Client,Server,Embedded',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/collection_patch.dart',
  ),
  'convert': const LibraryInfo(
    'convert/convert.dart',
    categories: 'Client,Server',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/convert_patch.dart',
  ),
  'core': const LibraryInfo(
    'core/core.dart',
    categories: 'Client,Server,Embedded',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/core_patch.dart',
  ),
  'developer': const LibraryInfo(
    'developer/developer.dart',
    categories: 'Client,Server,Embedded',
    maturity: Maturity.UNSTABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/developer_patch.dart',
  ),
  'ffi': const LibraryInfo(
    'ffi/ffi.dart',
    categories: 'Server',
    maturity: Maturity.STABLE,
  ),
  'html': const LibraryInfo(
    'html/dart2js/html_dart2js.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  'html_common': const LibraryInfo(
    'html/html_common/html_common.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    dart2jsPath: 'html/html_common/html_common_dart2js.dart',
    documented: false,
    implementation: true,
  ),
  'indexed_db': const LibraryInfo(
    'indexed_db/dart2js/indexed_db_dart2js.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  '_http': const LibraryInfo(
    '_http/http.dart',
    categories: '',
    documented: false,
  ),
  'io': const LibraryInfo(
    'io/io.dart',
    categories: 'Server',
    dart2jsPatchPath: '_internal/js_runtime/lib/io_patch.dart',
  ),
  'isolate': const LibraryInfo(
    'isolate/isolate.dart',
    categories: 'Client,Server',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/isolate_patch.dart',
  ),
  'js': const LibraryInfo(
    'js/js.dart',
    categories: 'Client',
    maturity: Maturity.STABLE,
    platforms: DART2JS_PLATFORM,
    dart2jsPatchPath: '_internal/js_runtime/lib/js_patch.dart',
  ),
  '_js': const LibraryInfo(
    'js/_js.dart',
    categories: 'Client',
    dart2jsPatchPath: 'js/_js_client.dart',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  'js_interop': const LibraryInfo(
    'js_interop/js_interop.dart',
    categories: 'Client',
    maturity: Maturity.EXPERIMENTAL,
    platforms: DART2JS_PLATFORM,
  ),
  'js_interop_unsafe': const LibraryInfo(
    'js_interop_unsafe/js_interop_unsafe.dart',
    categories: 'Client',
    maturity: Maturity.EXPERIMENTAL,
    platforms: DART2JS_PLATFORM,
  ),
  'js_util': const LibraryInfo(
    'js_util/js_util.dart',
    categories: 'Client',
    maturity: Maturity.STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  'math': const LibraryInfo(
    'math/math.dart',
    categories: 'Client,Server,Embedded',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/math_patch.dart',
  ),
  'mirrors': const LibraryInfo(
    'mirrors/mirrors.dart',
    categories: 'Client,Server',
    maturity: Maturity.UNSTABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/mirrors_patch_cfe.dart',
  ),
  'nativewrappers': const LibraryInfo(
    'html/dartium/nativewrappers.dart',
    categories: 'Client',
    implementation: true,
    documented: false,
    platforms: VM_PLATFORM,
  ),
  'typed_data': const LibraryInfo(
    'typed_data/typed_data.dart',
    categories: 'Client,Server,Embedded',
    maturity: Maturity.STABLE,
    dart2jsPatchPath: '_internal/js_runtime/lib/typed_data_patch.dart',
  ),
  '_native_typed_data': const LibraryInfo(
    '_internal/js_runtime/lib/native_typed_data.dart',
    categories: '',
    implementation: true,
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  'cli': const LibraryInfo(
    'cli/cli.dart',
    categories: 'Server',
    platforms: VM_PLATFORM,
  ),
  'svg': const LibraryInfo(
    'svg/dart2js/svg_dart2js.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  'web_audio': const LibraryInfo(
    'web_audio/dart2js/web_audio_dart2js.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  'web_gl': const LibraryInfo(
    'web_gl/dart2js/web_gl_dart2js.dart',
    categories: 'Client',
    maturity: Maturity.WEB_STABLE,
    platforms: DART2JS_PLATFORM,
  ),
  '_internal': const LibraryInfo(
    'internal/internal.dart',
    categories: '',
    documented: false,
    dart2jsPatchPath: '_internal/js_runtime/lib/internal_patch.dart',
  ),
  '_js_helper': const LibraryInfo(
    '_internal/js_runtime/lib/js_helper.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_late_helper': const LibraryInfo(
    '_internal/js_runtime/lib/late_helper.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_rti': const LibraryInfo(
    '_internal/js_shared/lib/rti.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_dart2js_only': const LibraryInfo(
    '_internal/js_runtime/lib/dart2js_only.dart',
    categories: '',
    implementation: true,
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_dart2js_runtime_metrics': const LibraryInfo(
    '_internal/js_runtime/lib/dart2js_runtime_metrics.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_interceptors': const LibraryInfo(
    '_internal/js_runtime/lib/interceptors.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_foreign_helper': const LibraryInfo(
    '_internal/js_runtime/lib/foreign_helper.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_names': const LibraryInfo(
    '_internal/js_runtime/lib/js_names.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_primitives': const LibraryInfo(
    '_internal/js_runtime/lib/js_primitives.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_embedded_names': const LibraryInfo(
    '_internal/js_runtime/lib/synced/embedded_names.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_shared_embedded_names': const LibraryInfo(
    '_internal/js_shared/lib/synced/embedded_names.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_types': const LibraryInfo(
    '_internal/js_shared/lib/js_types.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_async_status_codes': const LibraryInfo(
    '_internal/js_runtime/lib/synced/async_status_codes.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_invocation_mirror_constants': const LibraryInfo(
    '_internal/js_runtime/lib/synced/invocation_mirror_constants.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_recipe_syntax': const LibraryInfo(
    '_internal/js_shared/lib/synced/recipe_syntax.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_load_library_priority': const LibraryInfo(
    '_internal/js_runtime/lib/synced/load_library_priority.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_metadata': const LibraryInfo(
    'html/html_common/metadata.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  '_js_annotations': const LibraryInfo(
    'js/_js_annotations.dart',
    categories: '',
    documented: false,
    platforms: DART2JS_PLATFORM,
  ),
  "_wasm": const LibraryInfo(
    '_wasm/wasm_types.dart',
    categories: '',
    documented: false,
  ),
  "_macros": const LibraryInfo(
    '_macros/macros.dart',
    documented: false,
    platforms: VM_PLATFORM,
    maturity: Maturity.EXPERIMENTAL,
  ),
};

/// Information about a "dart:" library.
class LibraryInfo {
  /// Path to the library's *.dart file relative to this file.
  final String path;

  /// The categories in which the library can be used encoded as a
  /// comma-separated String.
  final String _categories;

  /// States the current maturity of this library.
  final Maturity maturity;

  /// Path to the dart2js library's *.dart file relative to this file
  /// or null if dart2js uses the common library path defined above.
  /// Access using the [#getDart2JsPath()] method.
  final String? dart2jsPath;

  /// Path to the dart2js library's patch file relative to this file
  /// or null if no dart2js patch file associated with this library.
  /// Access using the [#getDart2JsPatchPath()] method.
  final String? dart2jsPatchPath;

  /// True if this library is documented and should be shown to the user.
  final bool documented;

  /// Bit flags indicating which platforms consume this library.
  /// See [DART2JS_LIBRARY] and [VM_LIBRARY].
  final int platforms;

  /// True if the library contains implementation details for another library.
  /// The implication is that these libraries are less commonly used
  /// and that tools like Dart Editor should not show these libraries
  /// in a list of all libraries unless the user specifically asks the tool to
  /// do so.
  final bool implementation;

  const LibraryInfo(
    this.path, {
    String categories = '',
    this.dart2jsPath,
    this.dart2jsPatchPath,
    this.implementation = false,
    this.documented = true,
    this.maturity = Maturity.UNSPECIFIED,
    this.platforms = DART2JS_PLATFORM | VM_PLATFORM,
  }) : _categories = categories;

  bool get isDart2jsLibrary => (platforms & DART2JS_PLATFORM) != 0;
  bool get isVmLibrary => (platforms & VM_PLATFORM) != 0;

  /// The categories in which the library can be used.
  ///
  /// If no categories are specified, the library is internal and can not be
  /// loaded by user code.
  List<Category> get categories {
    // `"".split(,)` returns [""] not [], so we handle that case separately.
    if (_categories.isEmpty) {
      return const <Category>[];
    } else {
      return _categories
          .split(',')
          .map(parseCategory)
          .whereType<Category>()
          .toList();
    }
  }

  bool get isInternal => categories.isEmpty;

  /// The original "categories" String that was passed to the constructor.
  ///
  /// Can be used to construct a slightly modified copy of this LibraryInfo.
  String get categoriesString => _categories;
}

/// Abstraction to capture the maturity of a library.
class Maturity {
  final int level;
  final String name;
  final String description;

  const Maturity(this.level, this.name, this.description);

  @override
  String toString() => '$name: $level\n$description\n';

  static const Maturity DEPRECATED = Maturity(0, 'Deprecated',
      'This library will be remove before next major release.');

  static const Maturity EXPERIMENTAL = Maturity(
      1,
      'Experimental',
      'This library is experimental and will likely change or be removed\n'
          'in future versions.');

  static const Maturity UNSTABLE = Maturity(
      2,
      'Unstable',
      'This library is in still changing and have not yet endured\n'
          'sufficient real-world testing.\n'
          'Backwards-compatibility is NOT guaranteed.');

  static const Maturity WEB_STABLE = Maturity(
      3,
      'Web Stable',
      'This library is tracking the DOM evolution as defined by WC3.\n'
          'Backwards-compatibility is NOT guaranteed.');

  static const Maturity STABLE = Maturity(
      4,
      'Stable',
      'The library is stable. API backwards-compatibility is guaranteed.\n'
          'However implementation details might change.');

  static const Maturity LOCKED = Maturity(5, 'Locked',
      'This library will not change except when serious bugs are encountered.');

  static const Maturity UNSPECIFIED = Maturity(-1, 'Unspecified',
      'The maturity for this library has not been specified.');
}
