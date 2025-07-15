// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

// A command that will return typical-looking 'clang++ --version' output with
// the given version number.
FakeCommand _clangPresentCommand(String version) {
  return FakeCommand(
    command: const <String>['clang++', '--version'],
    stdout:
        '''
clang version $version-6+build1
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
''',
  );
}

// A command that will return typical-looking 'cmake --version' output with the
// given version number.
FakeCommand _cmakePresentCommand(String version) {
  return FakeCommand(
    command: const <String>['cmake', '--version'],
    stdout:
        '''
cmake version $version

CMake suite maintained and supported by Kitware (kitware.com/cmake).
''',
  );
}

// A command that will return typical-looking 'ninja --version' output with the
// given version number.
FakeCommand _ninjaPresentCommand(String version) {
  return FakeCommand(command: const <String>['ninja', '--version'], stdout: version);
}

// A command that will return typical-looking 'pkg-config --version' output with
// the given version number.
FakeCommand _pkgConfigPresentCommand(String version) {
  return FakeCommand(command: const <String>['pkg-config', '--version'], stdout: version);
}

/// A command that returns either success or failure for a pkg-config query
/// for [library], depending on [exists].
FakeCommand _libraryCheckCommand(String library, {bool exists = true}) {
  return FakeCommand(
    command: <String>['pkg-config', '--exists', library],
    exitCode: exists ? 0 : 1,
  );
}

// Commands that give positive replies for all the GTK library pkg-config queries.
List<FakeCommand> _gtkLibrariesPresentCommands() {
  return <FakeCommand>[
    _libraryCheckCommand('gtk+-3.0'),
    _libraryCheckCommand('glib-2.0'),
    _libraryCheckCommand('gio-2.0'),
  ];
}

// A command that will return typical-looking 'eglinfo' output
FakeCommand _eglinfoPresentCommand({
  bool wayland = true,
  bool x11 = true,
  bool core = true,
  bool es = true,
}) {
  var stdout = '''
EGL client extensions string:
    EGL_EXT_client_extensions
''';

  if (wayland) {
    stdout += '''

Wayland platform:
EGL API version: 1.5
EGL vendor string: Mesa Project
EGL version string: 1.5
EGL driver name: iris
''';
    if (core) {
      stdout += '''
OpenGL core profile vendor: Intel
OpenGL core profile renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)
OpenGL core profile version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1
OpenGL core profile shading language version: 4.60
OpenGL core profile extensions:
    GL_ARB_blend_func_extended, GL_EXT_framebuffer_blit
''';
    }
    if (es) {
      stdout += '''
OpenGL ES profile vendor: Intel
OpenGL ES profile renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)
OpenGL ES profile version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1
OpenGL ES profile shading language version: OpenGL ES GLSL ES 3.20
OpenGL ES profile extensions:
    GL_EXT_EGL_image_storage, GL_EXT_texture_format_BGRA8888
''';
    }
    stdout += '''
Configurations:
     bf lv colorbuffer dp st  ms    vis   cav bi  renderable  supported
  id sz  l  r  g  b  a th cl ns b    id   eat nd gl es es2 vg surfaces
---------------------------------------------------------------------
0x01 32  0 10 10 10  2  0  0  0 0 0x00--         y  y  y     win
''';
  }

  if (x11) {
    stdout += '''

X11 platform:
EGL API version: 1.5
EGL vendor string: Mesa Project
EGL version string: 1.5
EGL driver name: iris
''';
    if (core) {
      stdout += '''
OpenGL core profile vendor: Intel
OpenGL core profile renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)
OpenGL core profile version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1
OpenGL core profile shading language version: 4.60
OpenGL core profile extensions:
    GL_ARB_blend_func_extended, GL_EXT_framebuffer_blit
''';
    }
    if (es) {
      stdout += '''
OpenGL ES profile vendor: Intel
OpenGL ES profile renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)
OpenGL ES profile version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1
OpenGL ES profile shading language version: OpenGL ES GLSL ES 3.20
OpenGL ES profile extensions:
    GL_EXT_EGL_image_storage, GL_EXT_texture_format_BGRA8888
''';
    }
    stdout += '''
Configurations:
     bf lv colorbuffer dp st  ms    vis   cav bi  renderable  supported
  id sz  l  r  g  b  a th cl ns b    id   eat nd gl es es2 vg surfaces
---------------------------------------------------------------------
0x01 32  0 10 10 10  2  0  0  0 0 0x00--         y  y  y     win
''';
  }

  return FakeCommand(command: const <String>['eglinfo'], stdout: stdout);
}

// A command that will failure when running 'eglinfo'.
FakeCommand _eglinfoMissingCommand() {
  return const FakeCommand(
    command: <String>['eglinfo'],
    exitCode: 1,
    exception: ProcessException('eglinfo', <String>[]),
  );
}

// Commands that give some failures for the GTK library pkg-config queries.
List<FakeCommand> _gtkLibrariesMissingCommands() {
  return <FakeCommand>[
    _libraryCheckCommand('gtk+-3.0'),
    _libraryCheckCommand('glib-2.0', exists: false),
    // No more entries, since the first missing GTK library stops the
    // checks.
  ];
}

// A command that will failure when running '[binary] --version'.
FakeCommand _missingBinaryCommand(String binary) {
  return FakeCommand(command: <String>[binary, '--version'], exitCode: 1);
}

FakeCommand _missingBinaryException(String binary) {
  return FakeCommand(
    command: <String>[binary, '--version'],
    exitCode: 1,
    exception: ProcessException(binary, <String>[]),
  );
}

void main() {
  testWithoutContext(
    'Full validation when everything is available at the necessary version',
    () async {
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        _clangPresentCommand('4.0.1'),
        _cmakePresentCommand('3.16.3'),
        _ninjaPresentCommand('1.10.0'),
        _pkgConfigPresentCommand('0.29'),
        ..._gtkLibrariesPresentCommands(),
        _eglinfoPresentCommand(),
      ]);
      final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
        processManager: processManager,
        userMessages: UserMessages(),
      );
      final ValidationResult result = await linuxDoctorValidator.validate();

      expect(result.type, ValidationType.success);
      expect(result.messages, const <ValidationMessage>[
        ValidationMessage('clang version 4.0.1-6+build1'),
        ValidationMessage('cmake version 3.16.3'),
        ValidationMessage('ninja version 1.10.0'),
        ValidationMessage('pkg-config version 0.29'),
        ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
        ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
        ValidationMessage('OpenGL core shading language version: 4.60'),
        ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
        ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
        ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
        ValidationMessage('GL_EXT_framebuffer_blit: yes'),
        ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
      ]);
    },
  );

  testWithoutContext('Partial validation when clang++ version is too old', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('2.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.partial);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 2.0.1-6+build1'),
      ValidationMessage.error('clang++ 3.4.0 or later is required.'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL core shading language version: 4.60'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Partial validation when CMake version is too old', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.2.0'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.partial);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.2.0'),
      ValidationMessage.error('cmake 3.10.0 or later is required.'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL core shading language version: 4.60'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Partial validation when ninja version is too old', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('0.8.1'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.partial);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 0.8.1'),
      ValidationMessage.error('ninja 1.8.0 or later is required.'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL core shading language version: 4.60'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Partial validation when pkg-config version is too old', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.27.0'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.partial);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.27.0'),
      ValidationMessage.error('pkg-config 0.29.0 or later is required.'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL core shading language version: 4.60'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when pkg-config is missing', () async {
    final userMessages = UserMessages();
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _missingBinaryException('pkg-config'),
      // We never check libraries because pkg-config is not present
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      ValidationMessage.error(userMessages.pkgConfigMissing),
    ]);
  });

  testWithoutContext('Missing validation when CMake is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _missingBinaryCommand('cmake'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage.error(userMessages.cmakeMissing),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when CMake version is unparsable', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('bogus'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage.error(userMessages.cmakeMissing),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when clang++ is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _missingBinaryException('clang++'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      ValidationMessage.error(userMessages.clangMissing),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when clang++ version is unparsable', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('bogus'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      ValidationMessage.error(userMessages.clangMissing),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when ninja is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _missingBinaryCommand('ninja'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      ValidationMessage.error(userMessages.ninjaMissing),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when ninja version is unparsable', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('bogus'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      ValidationMessage.error(userMessages.ninjaMissing),
      const ValidationMessage('pkg-config version 0.29'),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when pkg-config is not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _missingBinaryCommand('pkg-config'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      ValidationMessage.error(userMessages.pkgConfigMissing),
    ]);
  });

  testWithoutContext('Missing validation when pkg-config version is unparsable', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('bogus'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      ValidationMessage.error(userMessages.pkgConfigMissing),
    ]);
  });

  testWithoutContext('Missing validation when GTK libraries are not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesMissingCommands(),
      _eglinfoPresentCommand(),
    ]);
    final userMessages = UserMessages();
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.missing);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      ValidationMessage.error(userMessages.gtkLibrariesMissing),
      const ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1',
      ),
      const ValidationMessage('OpenGL core shading language version: 4.60'),
      const ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      const ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      const ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      const ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      const ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });

  testWithoutContext('Missing validation when multiple dependencies are not available', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _missingBinaryCommand('clang++'),
      _missingBinaryCommand('cmake'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );

    final ValidationResult result = await linuxDoctorValidator.validate();
    expect(result.type, ValidationType.missing);
  });

  testWithoutContext('Warning when eglinfo not available', () async {
    final userMessages = UserMessages();
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoMissingCommand(),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: userMessages,
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.success);
    expect(result.messages, <ValidationMessage>[
      const ValidationMessage('clang version 4.0.1-6+build1'),
      const ValidationMessage('cmake version 3.16.3'),
      const ValidationMessage('ninja version 1.10.0'),
      const ValidationMessage('pkg-config version 0.29'),
      ValidationMessage.hint(userMessages.eglinfoMissing),
    ]);
  });

  testWithoutContext('Wayland only platform', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(x11: false),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.success);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2) (Wayland)'),
      ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1 (Wayland)',
      ),
      ValidationMessage('OpenGL core shading language version: 4.60 (Wayland)'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2) (Wayland)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1 (Wayland)'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20 (Wayland)'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes (Wayland)'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes (Wayland)'),
    ]);
  });

  testWithoutContext('X11 only platform', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(wayland: false),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.success);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2) (X11)'),
      ValidationMessage(
        'OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1 (X11)',
      ),
      ValidationMessage('OpenGL core shading language version: 4.60 (X11)'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2) (X11)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1 (X11)'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20 (X11)'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes (X11)'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes (X11)'),
    ]);
  });

  testWithoutContext('No OpenGL ES', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(es: false),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.success);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL core renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL core version: 4.6 (Core Profile) Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL core shading language version: 4.60'),
      ValidationMessage('GL_EXT_framebuffer_blit: yes'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: no'),
    ]);
  });

  testWithoutContext('No OpenGL core', () async {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      _clangPresentCommand('4.0.1'),
      _cmakePresentCommand('3.16.3'),
      _ninjaPresentCommand('1.10.0'),
      _pkgConfigPresentCommand('0.29'),
      ..._gtkLibrariesPresentCommands(),
      _eglinfoPresentCommand(core: false),
    ]);
    final DoctorValidator linuxDoctorValidator = LinuxDoctorValidator(
      processManager: processManager,
      userMessages: UserMessages(),
    );
    final ValidationResult result = await linuxDoctorValidator.validate();

    expect(result.type, ValidationType.success);
    expect(result.messages, const <ValidationMessage>[
      ValidationMessage('clang version 4.0.1-6+build1'),
      ValidationMessage('cmake version 3.16.3'),
      ValidationMessage('ninja version 1.10.0'),
      ValidationMessage('pkg-config version 0.29'),
      ValidationMessage('OpenGL ES renderer: Mesa Intel(R) UHD Graphics 620 (KBL GT2)'),
      ValidationMessage('OpenGL ES version: OpenGL ES 3.2 Mesa 24.2.8-1ubuntu1~24.10.1'),
      ValidationMessage('OpenGL ES shading language version: OpenGL ES GLSL ES 3.20'),
      ValidationMessage('GL_EXT_framebuffer_blit: no'),
      ValidationMessage('GL_EXT_texture_format_BGRA8888: yes'),
    ]);
  });
}
