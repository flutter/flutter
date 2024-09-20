// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// An application binary interface (ABI).
///
/// An ABI defines the memory layout of data
/// and the function call protocol for native code.
/// It is usually defined by the an operating system for each
/// architecture that operating system runs on.
///
/// The Dart VM can run on a variety of operating systems and architectures.
/// Supported ABIs are represented by `Abi` objects.
/// See [values] for all the supported ABIs.
@Since('2.16')
class Abi {
  /// The application binary interface for Android on the Arm architecture.
  static const androidArm = _androidArm;

  /// The application binary interface for Android on the Arm64 architecture.
  static const androidArm64 = _androidArm64;

  /// The application binary interface for Android on the IA32 architecture.
  static const androidIA32 = _androidIA32;

  /// The application binary interface for Android on the X64 architecture.
  static const androidX64 = _androidX64;

  /// The application binary interface for Android on 64-bit RISC-V.
  static const androidRiscv64 = _androidRiscv64;

  /// The application binary interface for Fuchsia on the Arm64 architecture.
  static const fuchsiaArm64 = _fuchsiaArm64;

  /// The application binary interface for Fuchsia on the X64 architecture.
  static const fuchsiaX64 = _fuchsiaX64;

  /// The application binary interface for Fuchsia on the Riscv64 architecture.
  static const fuchsiaRiscv64 = _fuchsiaRiscv64;

  /// The application binary interface for iOS on the Arm architecture.
  static const iosArm = _iosArm;

  /// The application binary interface for iOS on the Arm64 architecture.
  static const iosArm64 = _iosArm64;

  /// The application binary interface for iOS on the X64 architecture.
  static const iosX64 = _iosX64;

  /// The application binary interface for Linux on the Arm architecture.
  ///
  /// Does not distinguish between hard and soft fp. Currently, no uses of Abi
  /// require this distinction.
  static const linuxArm = _linuxArm;

  /// The application binary interface for linux on the Arm64 architecture.
  static const linuxArm64 = _linuxArm64;

  /// The application binary interface for linux on the IA32 architecture.
  static const linuxIA32 = _linuxIA32;

  /// The application binary interface for linux on the X64 architecture.
  static const linuxX64 = _linuxX64;

  /// The application binary interface for linux on 32-bit RISC-V.
  static const linuxRiscv32 = _linuxRiscv32;

  /// The application binary interface for linux on 64-bit RISC-V.
  static const linuxRiscv64 = _linuxRiscv64;

  /// The application binary interface for MacOS on the Arm64 architecture.
  static const macosArm64 = _macosArm64;

  /// The application binary interface for MacOS on the X64 architecture.
  static const macosX64 = _macosX64;

  /// The application binary interface for Windows on the Arm64 architecture.
  static const windowsArm64 = _windowsArm64;

  /// The application binary interface for Windows on the IA32 architecture.
  static const windowsIA32 = _windowsIA32;

  /// The application binary interface for Windows on the X64 architecture.
  static const windowsX64 = _windowsX64;

  /// The ABIs that the DartVM can run on.
  ///
  /// Does not contain a `macosIA32`. We have stopped supporting 32-bit MacOS.
  static const values = [
    androidArm,
    androidArm64,
    androidIA32,
    androidX64,
    androidRiscv64,
    fuchsiaArm64,
    fuchsiaX64,
    fuchsiaRiscv64,
    iosArm,
    iosArm64,
    iosX64,
    linuxArm,
    linuxArm64,
    linuxIA32,
    linuxX64,
    linuxRiscv32,
    linuxRiscv64,
    macosArm64,
    macosX64,
    windowsArm64,
    windowsIA32,
    windowsX64,
  ];

  /// The ABI the Dart VM is currently running on.
  external factory Abi.current();

  /// A string representation of this ABI.
  ///
  /// The string is equal to the 'on' part from `Platform.version` and
  /// `dart --version`.
  @override
  String toString() => '${_os.name}_${_architecture.name}';

  /// The operating system of this [Abi].
  final _OS _os;

  /// The architecture of this [Abi].
  final _Architecture _architecture;

  /// The constructor is private so that we can use [Abi.values] as opaque
  /// tokens.
  const Abi._(this._architecture, this._os);

  static const _androidArm = Abi._(_Architecture.arm, _OS.android);
  static const _androidArm64 = Abi._(_Architecture.arm64, _OS.android);
  static const _androidIA32 = Abi._(_Architecture.ia32, _OS.android);
  static const _androidX64 = Abi._(_Architecture.x64, _OS.android);
  static const _androidRiscv64 = Abi._(_Architecture.riscv64, _OS.android);
  static const _fuchsiaArm64 = Abi._(_Architecture.arm64, _OS.fuchsia);
  static const _fuchsiaX64 = Abi._(_Architecture.x64, _OS.fuchsia);
  static const _fuchsiaRiscv64 = Abi._(_Architecture.riscv64, _OS.fuchsia);
  static const _iosArm = Abi._(_Architecture.arm, _OS.ios);
  static const _iosArm64 = Abi._(_Architecture.arm64, _OS.ios);
  static const _iosX64 = Abi._(_Architecture.x64, _OS.ios);
  static const _linuxArm = Abi._(_Architecture.arm, _OS.linux);
  static const _linuxArm64 = Abi._(_Architecture.arm64, _OS.linux);
  static const _linuxIA32 = Abi._(_Architecture.ia32, _OS.linux);
  static const _linuxX64 = Abi._(_Architecture.x64, _OS.linux);
  static const _linuxRiscv32 = Abi._(_Architecture.riscv32, _OS.linux);
  static const _linuxRiscv64 = Abi._(_Architecture.riscv64, _OS.linux);
  static const _macosArm64 = Abi._(_Architecture.arm64, _OS.macos);
  static const _macosX64 = Abi._(_Architecture.x64, _OS.macos);
  static const _windowsArm64 = Abi._(_Architecture.arm64, _OS.windows);
  static const _windowsIA32 = Abi._(_Architecture.ia32, _OS.windows);
  static const _windowsX64 = Abi._(_Architecture.x64, _OS.windows);
}

/// The hardware architectures the Dart VM runs on.
enum _Architecture {
  arm,
  arm64,
  ia32,
  x64,
  riscv32,
  riscv64,
}

/// The operating systems the Dart VM runs on.
enum _OS {
  android,
  fuchsia,
  ios,
  linux,
  macos,
  windows,
}
