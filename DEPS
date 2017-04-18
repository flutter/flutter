# This file is automatically processed to create .DEPS.git which is the file
# that gclient uses under git.
#
# See http://code.google.com/p/chromium/wiki/UsingGit
#
# To test manually, run:
#   python tools/deps2git/deps2git.py -o .DEPS.git -w <gclientdir>
# where <gcliendir> is the absolute path to the directory containing the
# .gclient file (the parent of 'src').
#
# Then commit .DEPS.git locally (gclient doesn't like dirty trees) and run
#   gclient sync
# Verify the thing happened you wanted. Then revert your .DEPS.git change
# DO NOT CHECK IN CHANGES TO .DEPS.git upstream. It will be automatically
# updated by a bot when you modify this one.
#
# When adding a new dependency, please update the top-level .gitignore file
# to list the dependency's destination directory.

vars = {
  'chromium_git': 'https://chromium.googlesource.com',
  'fuchsia_git': 'https://fuchsia.googlesource.com',
  'skia_git': 'https://skia.googlesource.com',
  'github_git': 'https://github.com',
  'skia_revision': '30229ac6282981c28ced8f513c8d09684d9d0581',

  # Note: When updating the Dart revision, ensure that all entries that are
  # dependencies of dart are also updated
  'dart_revision': '42ec925a9e8be87e515f06440e01e11c832b8da7',
  'dart_boringssl_gen_revision': '753224969dbe43dad29343146529727b5066c0f3',
  'dart_boringssl_revision': 'd519bf6be0b447fb80fbc539d4bff4479b5482a2',
  'dart_observatory_packages_revision': '26aad88f1c1915d39bbcbff3cad589e2402fdcf1',
  'dart_root_certificates_revision': 'a4c7c6f23a664a37bc1b6f15a819e3f2a292791a',

  'buildtools_revision': '5655267acc2b1c672aec43bfbd28c645908fcd74',
}

# Only these hosts are allowed for dependencies in this DEPS file.
# If you need to add a new host, contact chrome infrastructure team.
allowed_hosts = [
  'chromium.googlesource.com',
  'fuchsia.googlesource.com',
  'github.com',
  'skia.googlesource.com',
]

deps = {
  'src': 'https://github.com/flutter/buildroot.git' + '@' + 'effec4955ea3444bfc7c78a7a2f60836cf722f67',

   # Fuchsia compatibility
   #
   # The dependencies in this section should match the layout in the Fuchsia gn
   # build. Eventually, we'll manage these dependencies together with Fuchsia
   # and not have to specific specific hashes.

  'src/lib/ftl':
   Var('fuchsia_git') + '/ftl' + '@' + 'f1357b6eaa9a23cffec1645dfeba610b5f926b1d',

  'src/lib/tonic':
   Var('fuchsia_git') + '/tonic' + '@' + '82075233dc0cd23b1c8af5f694eb86dd9bd10f35',

  'src/lib/zip':
   Var('fuchsia_git') + '/zip' + '@' + '92dc87ca645fe8e9f5151ef6dac86d8311a7222f',

  'src/third_party/gtest':
   Var('fuchsia_git') + '/third_party/gtest' + '@' + 'c00f82917331efbbd27124b537e4ccc915a02b72',

  'src/third_party/rapidjson':
   Var('fuchsia_git') + '/third_party/rapidjson' + '@' + '9defbb0209a534ffeb3a2b79d5ee440a77407292',

   # Chromium-style
   #
   # As part of integrating with Fuchsia, we should eventually remove all these
   # Chromium-style dependencies.

  'src/buildtools':
   Var('fuchsia_git') + '/buildtools' + '@' +  Var('buildtools_revision'),

  'src/third_party/icu':
   Var('chromium_git') + '/chromium/deps/icu.git' + '@' + 'c3f79166089e5360c09e3053fce50e6e296c3204',

  'src/dart':
    Var('chromium_git') + '/external/github.com/dart-lang/sdk.git' + '@' + Var('dart_revision'),

  'src/third_party/boringssl':
    Var('github_git') + '/dart-lang/boringssl_gen.git' + '@' + Var('dart_boringssl_gen_revision'),

  'src/third_party/boringssl/src':
   'https://boringssl.googlesource.com/boringssl.git' + '@' + Var('dart_boringssl_revision'),

  'src/dart/third_party/observatory_pub_packages':
   Var('chromium_git') +
   '/external/github.com/dart-lang/observatory_pub_packages' + '@' +
   Var('dart_observatory_packages_revision'),

  'src/third_party/root_certificates':
   Var('chromium_git') +
   '/external/github.com/dart-lang/root_certificates' + '@' +
   Var('dart_root_certificates_revision'),

  'src/third_party/skia':
   Var('skia_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'src/third_party/libjpeg-turbo':
   Var('skia_git') + '/third_party/libjpeg-turbo.git' + '@' + 'debddedc75850bcdeb8a57258572f48b802a4bb3',

  'src/third_party/gyp':
   Var('chromium_git') + '/external/gyp.git' + '@' + '6ee91ad8659871916f9aa840d42e1513befdf638',

   # Headers for Vulkan 1.0
   'src/third_party/vulkan':
   Var('github_git') + '/KhronosGroup/Vulkan-Docs.git' + '@' + 'e29c2489e238509c41aeb8c7bce9d669a496344b',
}

recursedeps = [
  'src/buildtools',
]

deps_os = {
  'android': {
    'src/third_party/colorama/src':
     Var('chromium_git') + '/external/colorama.git' + '@' + '799604a1041e9b3bc5d2789ecbd7e8db2e18e6b8',

    'src/third_party/freetype2':
       Var('fuchsia_git') + '/third_party/freetype2' + '@' + 'e23a030e9b43c648249477fdf7bf5305d2cc8f59',
  },
}


hooks = [
  {
    # This clobbers when necessary (based on get_landmines.py). It must be the
    # first hook so that other things that get/generate into the output
    # directory will not subsequently be clobbered.
    'name': 'landmines',
    'pattern': '.',
    'action': [
        'python',
        'src/build/landmines.py',
    ],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'pattern': '.',
    'action': ['python', 'src/build/vs_toolchain.py', 'update'],
  },
  {
    'name': 'download_android_tools',
    'pattern': '.',
    'action': [
        'python',
        'src/tools/android/download_android_tools.py',
    ],
  },
  {
    'name': 'buildtools',
    'pattern': '.',
    'action': ['python', 'src/tools/buildtools/update.py'],
  },
  {
    # Pull dart sdk if needed
    'name': 'dart',
    'pattern': '.',
    'action': ['python', 'src/tools/dart/update.py'],
  },
  {
    # Ensure that we don't accidentally reference any .pyc files whose
    # corresponding .py files have already been deleted.
    'name': 'remove_stale_pyc_files',
    'pattern': 'src/tools/.*\\.py',
    'action': [
        'python',
        'src/tools/remove_stale_pyc_files.py',
        'src/tools',
    ],
  },
]
