# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This gyp file contains the platform-specific optimizations for Skia
{
  'variables': {
      'skia_src_path': '../third_party/skia/src',
      'includes': [ '../third_party/skia/gyp/opts.gypi' ],
      'include_dirs': [
        '../third_party/skia/include/core',
        '../third_party/skia/include/effects',
        '../third_party/skia/include/utils',
        '../third_party/skia/src/core',
        '../third_party/skia/src/opts',
        '../third_party/skia/src/utils',
      ],
   },

  'targets': [
    # Due to an unfortunate intersection of lameness between gcc and gyp,
    # we have to build the *_SSE2.cpp files in a separate target.  The
    # gcc lameness is that, in order to compile SSE2 intrinsics code, it
    # must be passed the -msse2 flag.  However, with this flag, it may
    # emit SSE2 instructions even for scalar code, such as the CPUID
    # test used to test for the presence of SSE2.  So that, and all other
    # code must be compiled *without* -msse2.  The gyp lameness is that it
    # does not allow file-specific CFLAGS, so we must create this extra
    # target for those files to be compiled with -msse2.
    #
    # This is actually only a problem on 32-bit Linux (all Intel Macs have
    # SSE2, Linux x86_64 has SSE2 by definition, and MSC will happily emit
    # SSE2 from instrinsics, which generating plain ol' 386 for everything
    # else).  However, to keep the .gyp file simple and avoid platform-specific
    # build breakage, we do this on all platforms.

    # For about the same reason, we need to compile the ARM opts files
    # separately as well.
    {
      'target_name': 'skia_opts',
      'type': 'static_library',
      'includes': [
        'skia_common.gypi',
        '../build/android/increase_size_for_speed.gypi',
        # Disable LTO due to compiler error
        # in mems_in_disjoint_alias_sets_p, at alias.c:393
        # crbug.com/422255
        '../build/android/disable_lto.gypi',
      ],
      'include_dirs': [ '<@(include_dirs)' ],
      'conditions': [
        [ 'os_posix == 1 and OS != "mac" and OS != "android" and \
           target_arch != "arm" and target_arch != "arm64" and \
           target_arch != "mipsel" and target_arch != "mips64el"', {
          'cflags': [ '-msse2' ],
        }],
        [ 'target_arch != "arm" and target_arch != "mipsel" and \
           target_arch != "arm64" and target_arch != "mips64el"', {
          'sources': [ '<@(sse2_sources)' ],
          'dependencies': [
            'skia_opts_ssse3',
            'skia_opts_sse41',
          ],
        }],
        [ 'target_arch == "arm"', {
          'conditions': [
            [ 'arm_version >= 7', {
              'sources': [ '<@(armv7_sources)' ],
            }, {  # arm_version < 7
              'sources': [ '<@(none_sources)' ],
            }],
            [ 'arm_version >= 7 and (arm_neon == 1 or arm_neon_optional == 1)', {
              'dependencies': [
                'skia_opts_neon',
              ]
            }],
          ],
          # The assembly uses the frame pointer register (r7 in Thumb/r11 in
          # ARM), the compiler doesn't like that. Explicitly remove the
          # -fno-omit-frame-pointer flag for Android, as that gets added to all
          # targets via common.gypi.
          'cflags!': [
            '-fno-omit-frame-pointer',
            '-marm',
            '-mapcs-frame',
          ],
          'cflags': [
            '-fomit-frame-pointer',
          ],
        }],
        [ 'target_arch == "mipsel"',{
          'cflags': [ '-fomit-frame-pointer' ],
          'conditions': [
            [ 'mips_dsp_rev >= 1', {
              'sources': [ '<@(mips_dsp_sources)' ],
            }, {  # mips_dsp_rev == 0
              'sources': [ '<@(none_sources)' ],
            }],
          ],
        }],
        [ 'target_arch == "mips64el"',{
          'cflags': [ '-fomit-frame-pointer' ],
          'sources': [ '<@(none_sources)' ],
        }],
        [ 'target_arch == "arm64"', {
          'sources': [ '<@(arm64_sources)' ],
        }],
      ],
    },
    # For the same lame reasons as what is done for skia_opts, we have to
    # create another target specifically for SSSE3 code as we would not want
    # to compile the SSE2 code with -mssse3 which would potentially allow
    # gcc to generate SSSE3 code.
    {
      'target_name': 'skia_opts_ssse3',
      'type': 'static_library',
      'includes': [
        'skia_common.gypi',
        '../build/android/increase_size_for_speed.gypi',
      ],
      'include_dirs': [ '<@(include_dirs)' ],
      'conditions': [
        [ 'OS in ["linux", "freebsd", "openbsd", "solaris", "android"]', {
          'cflags': [ '-mssse3' ],
        }],
        [ 'OS == "mac"', {
          'xcode_settings': {
            'GCC_ENABLE_SUPPLEMENTAL_SSE3_INSTRUCTIONS': 'YES',
          },
        }],
        [ 'OS == "win" and clang == 1', {
          # cl.exe's /arch flag doesn't have a setting for SSSE3, and cl.exe
          # doesn't need it for intrinsics. clang-cl does need it, though.
          'msvs_settings': {
            'VCCLCompilerTool': { 'AdditionalOptions': [ '-mssse3' ] },
          },
        }],
        [ 'OS == "win"', {
          'defines' : [ 'SK_CPU_SSE_LEVEL=31' ],
        }],
        [ 'target_arch != "arm" and target_arch != "arm64" and \
           target_arch != "mipsel" and target_arch != "mips64el"', {
          'sources': [ '<@(ssse3_sources)' ],
        }],
      ],
    },
    # For the same lame reasons as what is done for skia_opts, we also have to
    # create another target specifically for SSE4.1 code as we would not want
    # to compile the SSE2 code with -msse4.1 which would potentially allow
    # gcc to generate SSE4.1 code.
    {
      'target_name': 'skia_opts_sse41',
      'type': 'static_library',
      'includes': [
        'skia_common.gypi',
        '../build/android/increase_size_for_speed.gypi',
      ],
      'include_dirs': [ '<@(include_dirs)' ],
      'sources': [ '<@(sse41_sources)' ],
      'conditions': [
        [ 'OS in ["linux", "freebsd", "openbsd", "solaris", "android"]', {
          'cflags': [ '-msse4.1' ],
        }],
        [ 'OS == "mac"', {
          'xcode_settings': {
            'GCC_ENABLE_SSE41_EXTENSIONS': 'YES',
          },
        }],
        [ 'OS == "win" and clang == 1', {
          # cl.exe's /arch flag doesn't have a setting for SSE4.1, and cl.exe
          # doesn't need it for intrinsics. clang-cl does need it, though.
          'msvs_settings': {
            'VCCLCompilerTool': { 'AdditionalOptions': [ '-msse4.1' ] },
          },
        }],
        [ 'OS == "win"', {
          'defines' : [ 'SK_CPU_SSE_LEVEL=41' ],
        }],
      ],
    },
    {
      'target_name': 'skia_opts_none',
      'type': 'static_library',
      'includes': [
        'skia_common.gypi',
        '../build/android/increase_size_for_speed.gypi',
      ],
      'include_dirs': [ '<@(include_dirs)' ],
      'sources': [ '<@(none_sources)' ],
    },
  ],
  'conditions': [
    # NEON code must be compiled with -mfpu=neon which also affects scalar
    # code. To support dynamic NEON code paths, we need to build all
    # NEON-specific sources in a separate static library. The situation
    # is very similar to the SSSE3 one.
    ['target_arch == "arm" and (arm_neon == 1 or arm_neon_optional == 1)', {
      'targets': [
        {
          'target_name': 'skia_opts_neon',
          'type': 'static_library',
          'includes': [
            'skia_common.gypi',
            '../build/android/increase_size_for_speed.gypi',
            # Disable LTO due to Neon issues
            # crbug.com/408997
            '../build/android/disable_lto.gypi',
          ],
          'include_dirs': [ '<@(include_dirs)' ],
          'cflags!': [
            '-fno-omit-frame-pointer',
            '-mfpu=vfp',  # remove them all, just in case.
            '-mfpu=vfpv3',
            '-mfpu=vfpv3-d16',
          ],
          'cflags': [
            '-mfpu=neon',
            '-fomit-frame-pointer',
          ],
          'ldflags': [
            '-march=armv7-a',
            '-Wl,--fix-cortex-a8',
          ],
          'sources': [ '<@(neon_sources)' ],
        },
      ],
    }],
  ],
}
