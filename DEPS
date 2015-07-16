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
  'dart_svn': 'https://dart.googlecode.com',
  'skia_revision': '2ced78866fcadd98895777c8dffe92e229775181',
  'angle_revision': 'bdd419f9f5b006e913606e7363125942c8ae06bc',
  'dart_revision': 'e5e3d161e70d862608e6597facdf5ac8ae9ab2c3',
  'dart_observatory_packages_revision': '45565',
  'boringssl_revision': '642f1498d056dbba3e50ed5a232ab2f482626dec',

  'buildtools_revision': 'fa660d47fa1a6c649d5c29e001348447c55709e6',

  'archive_dart_revision': '07ffd98c5403b7f9ae067b57dc9487611be420f5',
  'args_dart_revision': 'e0e8377412ee6cd6a5a4a8632848181c1db91f44',
  'box2d_dart_revision': 'c5e65d9546275e78ad2a1d51b459e7638f6e4323',
  'cassowary_dart_revision': '7e5afc5b3956a18636d5b37b1dcba1705865564b',
  'collection_dart_revision': '79ebc6fc2dae581cb23ad50a5c600c1b7dd132f8',
  'crypto_dart_revision': 'd4558dea1639e5ad2a41d045265b8ece270c2d90',
  'newton_dart_revision': '26da04f0c441d005a6ecbf62ae047cd02ec9abc5',
  'path_dart_revision': '2f3dcdec32011f1bc41194ae3640d6d9292a7096',
  'quiver_dart_revision': '6bab7dec34189eee579178eb16d3063c8ae69031',
  'source_span_dart_revision': '5c6c13f62fc111adaace3aeb4a38853d64481d06',
  'string_scanner_dart_revision': '9f00056b32f41efc376adecfb696a01bc7c593d7',
  'vector_math_dart_revision': '65915583f7aa606cb47ed265f853c18c60102b81',
  'yaml_dart_revision': 'd8c1ce75edf051ea1d5583b24474f8656abb4920',
}

# Only these hosts are allowed for dependencies in this DEPS file.
# If you need to add a new host, contact chrome infrastructure team.
allowed_hosts = [
  'chromium.googlesource.com',
  'dart.googlecode.com',
]

deps = {
  'src/buildtools':
   Var('chromium_git') + '/chromium/buildtools.git' + '@' +  Var('buildtools_revision'),

  'src/testing/gtest':
   Var('chromium_git') + '/external/googletest.git' + '@' + 'be1868139ffe0ccd0e8e3b37292b84c821d9c8ad', # from svn revision 704

  'src/testing/gmock':
   Var('chromium_git') + '/external/googlemock.git' + '@' + '29763965ab52f24565299976b936d1265cb6a271', # from svn revision 501

  'src/third_party/angle':
   Var('chromium_git') + '/angle/angle.git' + '@' +  Var('angle_revision'),

  'src/third_party/icu':
   Var('chromium_git') + '/chromium/deps/icu.git' + '@' + 'c3f79166089e5360c09e3053fce50e6e296c3204',

  'src/dart':
    Var('chromium_git') + '/external/github.com/dart-lang/sdk.git' + '@' + Var('dart_revision'),

  'src/dart/third_party/observatory_pub_packages':
    Var('dart_svn') + '/svn/third_party/observatory_pub_packages' + '@' +
    Var('dart_observatory_packages_revision'),

  'src/third_party/skia':
   Var('chromium_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'src/third_party/yasm/source/patched-yasm':
   Var('chromium_git') + '/chromium/deps/yasm/patched-yasm.git' + '@' + '4671120cd8558ce62ee8672ebf3eb6f5216f909b',

  'src/third_party/libjpeg_turbo':
   Var('chromium_git') + '/chromium/deps/libjpeg_turbo.git' + '@' + '034e9a9747e0983bc19808ea70e469bc8342081f',

  'src/third_party/smhasher/src':
    Var('chromium_git') + '/external/smhasher.git' + '@' + 'e87738e57558e0ec472b2fc3a643b838e5b6e88f',

  'src/third_party/mesa/src':
   Var('chromium_git') + '/chromium/deps/mesa.git' + '@' + '071d25db04c23821a12a8b260ab9d96a097402f0',

  'src/third_party/boringssl/src':
   'https://boringssl.googlesource.com/boringssl.git' + '@' +  Var('boringssl_revision'),

  'src/third_party/requests/src':
    Var('chromium_git') + '/external/github.com/kennethreitz/requests.git' + '@' + 'f172b30356d821d180fa4ecfa3e71c7274a32de4',

  'src/third_party/dart-pkg/archive':
    Var('chromium_git') + '/external/github.com/brendan-duncan/archive.git' + '@' + Var('archive_dart_revision'),

  'src/third_party/dart-pkg/args':
    Var('chromium_git') + '/external/github.com/dart-lang/args.git' + '@' + Var('args_dart_revision'),

  'src/third_party/dart-pkg/box2d':
    Var('chromium_git') + '/external/github.com/google/box2d.dart.git' + '@' + Var('box2d_dart_revision'),

  'src/third_party/dart-pkg/cassowary':
    Var('chromium_git') + '/external/github.com/domokit/cassowary.git' + '@' + Var('cassowary_dart_revision'),

  'src/third_party/dart-pkg/collection':
    Var('chromium_git') + '/external/github.com/dart-lang/collection.git' + '@' + Var('collection_dart_revision'),

  'src/third_party/dart-pkg/crypto':
    Var('chromium_git') + '/external/github.com/dart-lang/crypto.git' + '@' + Var('crypto_dart_revision'),

  'src/third_party/dart-pkg/newton':
    Var('chromium_git') + '/external/github.com/domokit/newton.git' + '@' + Var('newton_dart_revision'),

  'src/third_party/dart-pkg/path':
    Var('chromium_git') + '/external/github.com/dart-lang/path.git' + '@' + Var('path_dart_revision'),

  'src/third_party/dart-pkg/quiver':
    Var('chromium_git') + '/external/github.com/google/quiver-dart.git' + '@' + Var('quiver_dart_revision'),

  'src/third_party/dart-pkg/source_span':
    Var('chromium_git') + '/external/github.com/dart-lang/source_span.git' + '@' + Var('source_span_dart_revision'),

  'src/third_party/dart-pkg/string_scanner':
    Var('chromium_git') + '/external/github.com/dart-lang/string_scanner.git' + '@' + Var('string_scanner_dart_revision'),

  'src/third_party/dart-pkg/vector_math':
    Var('chromium_git') + '/external/github.com/google/vector_math.dart.git' + '@' + Var('vector_math_dart_revision'),

  'src/third_party/dart-pkg/yaml':
    Var('chromium_git') + '/external/github.com/dart-lang/yaml.git' + '@' + Var('yaml_dart_revision'),
}

deps_os = {
  'android': {
    'src/third_party/colorama/src':
     Var('chromium_git') + '/external/colorama.git' + '@' + '799604a1041e9b3bc5d2789ecbd7e8db2e18e6b8',

    'src/third_party/jsr-305/src':
        Var('chromium_git') + '/external/jsr-305.git' + '@' + '642c508235471f7220af6d5df2d3210e3bfc0919',

    'src/third_party/junit/src':
      Var('chromium_git') + '/external/junit.git' + '@' + '45a44647e7306262162e1346b750c3209019f2e1',

    'src/third_party/mockito/src':
      Var('chromium_git') + '/external/mockito/mockito.git' + '@' + 'ed99a52e94a84bd7c467f2443b475a22fcc6ba8e',

    'src/third_party/robolectric/lib':
      Var('chromium_git') + '/chromium/third_party/robolectric.git' + '@' + '6b63c99a8b6967acdb42cbed0adb067c80efc810',

    'src/third_party/appurify-python/src':
     Var('chromium_git') + '/external/github.com/appurify/appurify-python.git' + '@' + 'ee7abd5c5ae3106f72b2a0b9d2cb55094688e867',

    'src/third_party/freetype-android/src':
       Var('chromium_git') + '/chromium/src/third_party/freetype.git' + '@' + 'd1028db70bea988d1022e4d463de66581c696160',

    'src/third_party/requests/src':
      Var('chromium_git') + '/external/github.com/kennethreitz/requests.git' + '@' + 'f172b30356d821d180fa4ecfa3e71c7274a32de4',
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
    # Pull clang if needed or requested via GYP_DEFINES.
    'name': 'clang',
    'pattern': '.',
    'action': ['python', 'src/tools/clang/scripts/update.py', '--if-needed'],
  },
  {
    # Pull dart sdk if needed
    'name': 'dart',
    'pattern': '.',
    'action': ['python', 'src/tools/dart/update.py'],
  },
  {
    # This downloads android_tools according to tools/android/VERSION_*.
    'name': 'android_tools',
    'pattern': '.',
    'action': ['python', 'src/tools/android/download_android_tools.py'],
  },
  {
    # This downloads SDK extras and puts them in the
    # third_party/android_tools/sdk/extras directory on the bots. Developers
    # need to manually install these packages and accept the ToS.
    'name': 'sdkextras',
    'pattern': '.',
    # When adding a new sdk extras package to download, add the package
    # directory and zip file to .gitignore in third_party/android_tools.
    'action': ['python', 'src/build/download_sdk_extras.py'],
  },
  {
    # Update LASTCHANGE. This is also run by export_tarball.py in
    # src/tools/export_tarball - please keep them in sync.
    'name': 'lastchange',
    'pattern': '.',
    'action': ['python', 'src/build/util/lastchange.py',
               '-o', 'src/build/util/LASTCHANGE'],
  },
  # Pull GN binaries. This needs to be before running GYP below.
  {
    'name': 'gn_linux64',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/linux64/gn.sha1',
    ],
  },
  {
    'name': 'gn_mac',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=darwin',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/mac/gn.sha1',
    ],
  },
  {
    'name': 'gn_win',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=win*',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/win/gn.exe.sha1',
    ],
  },
  # Pull clang-format binaries using checked-in hashes.
  {
    'name': 'clang_format_linux',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-clang-format',
                '-s', 'src/buildtools/linux64/clang-format.sha1',
    ],
  },
  {
    'name': 'clang_format_mac',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=darwin',
                '--no_auth',
                '--bucket', 'chromium-clang-format',
                '-s', 'src/buildtools/mac/clang-format.sha1',
    ],
  },
  # Pull sky_server binaries using checked-in hashes.
  {
    'name': 'sky_server_linux',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'mojo',
                '-s', 'src/sky/tools/skygo/linux64/sky_server.sha1',
    ],
  },
  {
    'name': 'sky_server_mac',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=darwin',
                '--no_auth',
                '--bucket', 'mojo',
                '-s', 'src/sky/tools/skygo/mac/sky_server.sha1',
    ],
  },
  {
    'name': 'material_design_icons',
    'pattern': '.',
    'action': [
        'python',
        'src/sky/sdk/lib/download_material_design_icons',
    ],
  },
  # Pull binutils for linux, enabled debug fission for faster linking /
  # debugging when used with clang on Ubuntu Precise.
  # https://code.google.com/p/chromium/issues/detail?id=352046
  {
    'name': 'binutils',
    'pattern': 'src/third_party/binutils',
    'action': [
        'python',
        'src/third_party/binutils/download.py',
    ],
  },
  # Pull eu-strip binaries using checked-in hashes.
  {
    'name': 'eu-strip',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-eu-strip',
                '-s', 'src/build/linux/bin/eu-strip.sha1',
    ],
  },
  # Run "pub get" on any directories with checked-in pubspec.yaml files
  # (excluding sky/, whose pubspec.yaml files are not intended for supporting
  # building in-place in the repo).
  {
    'name': 'run_dart_pub_get',
    'pattern': '',
    'action': [ 'python',
                'src/mojo/public/tools/git/dart_pub_get.py',
                '--repository-root', '../../../..',
                '--dart-sdk-directory',
                '../../../../third_party/dart-sdk/dart-sdk',
                '--dirs-to-ignore', 'sky/',
    ],
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
