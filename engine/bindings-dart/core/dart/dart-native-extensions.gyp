{
  'variables': {
    'dart_dir': '../../../../../../dart',
  },

  'targets': [
    {
      'target_name': 'dart_library',
      'type': 'shared_library',
      'dependencies': [
        '<(dart_dir)/runtime/dart-runtime.gyp:libdart',
      ],
      'sources': [
        'shared_lib/DartLibraryMain.cpp',
      ],
      'conditions': [
        ['OS=="linux"', {
          'cflags': [
            '-fPIC',
          ],
          'ldflags!': [
            # Remove to allow Dart_ APIs to be exported.
            '-Wl,--exclude-libs=ALL',
          ],
        }],
        ['OS=="android"', {
          'cflags': [
            '-fPIC',
          ],
          'link_settings': {
            'libraries': [
              '-landroid',
              '-llog',
            ],
          },
          'ldflags!': [
            # Remove to allow Dart_ APIs to be exported.
            '-Wl,--exclude-libs=ALL',
          ],
          'ldflags': [
            '-rdynamic',
          ],
          'all_dependent_settings': {
            'ldflags!': [
              # See https://code.google.com/p/chromium/issues/detail?id=266155
              # When compiling dependent shared libraries, Android's GCC linker
              # reports a warning that this library is referencing isspace from
              # libjingle.
              # isspace should be inlined and is not reported as unresolved in
              # this library.
              '-Wl,--fatal-warnings',
            ],
          },
        }],
      ],
    },
  ],
}
