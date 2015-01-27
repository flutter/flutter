{
  'variables': {
    # We have to nest variables inside variables so that they can be overridden
    # through GYP_DEFINES.
    'variables': {
      'enable_dart_native_extensions%': 0,
    },

    'dart_dir': '../../../../../../dart',

    'conditions': [
      ['enable_dart_native_extensions==1', {
        'additional_target_deps': [
          # Reference Dart from a shared library which can be used outside of Dartium
          '../bindings/core/dart/dart-native-extensions.gyp:dart_library',
        ],
      }, {
        'additional_target_deps': [
          # Link in Dart directly
          '<(dart_dir)/runtime/dart-runtime.gyp:libdart',
        ],
      }],
    ],
  },
}
