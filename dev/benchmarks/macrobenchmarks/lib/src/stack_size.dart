// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'dart:io' as io;

import 'package:flutter/material.dart';

import '../common.dart';

// void *mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
typedef c_mmap = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>, ffi.IntPtr, ffi.Int32, ffi.Int32, ffi.Int32, ffi.IntPtr);
typedef dart_mmap = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>, int, int, int, int, int);
final mmap = ffi.DynamicLibrary.process().lookupFunction<c_mmap, dart_mmap>("mmap");

// int mprotect(void *addr, size_t len, int prot);
typedef c_mprotect = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.IntPtr, ffi.Int32);
typedef dart_mprotect = int Function(ffi.Pointer<ffi.Void>, int, int);
final mprotect = ffi.DynamicLibrary.process()
    .lookupFunction<c_mprotect, dart_mprotect>("mprotect");

const protRead = 1;
const protWrite = 2;
const protExec = 4;

const mapPrivate = 0x02;
final mapJit = io.Platform.isMacOS ? 0x0800 : 0x0;
final mapAnon = io.Platform.isMacOS ? 0x1000 : 0x20;

String get currentArch {
  // Can probably use uname from libc for better detection logic. For now
  // just assume that we only expect to run this test on native hardware.
  if (io.Platform.isMacOS || io.Platform.isLinux || io.Platform.isWindows) {
    return 'x64'; // TODO: need to support Apple Silicon Macs as well
  } else if (io.Platform.isAndroid) {
    // Ignore x86 Android.
    return ffi.sizeOf<ffi.IntPtr>() == 4 ? 'arm' : 'arm64';
  }
  throw 'Failed to detect current arch';
}

final getStackPointer = () {
  final region = mmap(ffi.nullptr, 4096, protRead | protWrite,
      mapPrivate | mapAnon | mapJit, -1, 0);
  region.cast<ffi.Uint8>().asTypedList(4096).setAll(
      0,
      const {
        // X64: mov rax, rsp; ret;
        'x64': [0x48, 0x89, 0xe0, 0xc3],
        // ARM64: mov x0, sp; ret;
        'arm64': [0xe0, 0x03, 0x00, 0x91, 0xc0, 0x03, 0x5f, 0xd6],
        // ARM32: mov r0, sp; ret;
        'arm': [0x0d, 0x00, 0xa0, 0xe1, 0x1e, 0xff, 0x2f, 0xe1],
      }[currentArch]);
  if (mprotect(region, 4096, protRead | protExec) != 0) {
    throw "Failed to mark code as executable";
  }
  return region
      .cast<ffi.NativeFunction<ffi.IntPtr Function()>>()
      .asFunction<int Function()>();
}();

class StackSizePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Container(
            width: 200,
            height: 100,
            child: ParentWidget(),
          ),
        ],
      ),
    );
  }
}

class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int myStackSize = getStackPointer();//io.ProcessInfo.currentStackSize;
    return ChildWidget(parentStackSize: myStackSize);
  }
}

class ChildWidget extends StatelessWidget {
  const ChildWidget({this.parentStackSize, Key key}) : super(key: key);
  final int parentStackSize;

  @override
  Widget build(BuildContext context) {
    final int myStackSize = getStackPointer(); //io.ProcessInfo.currentStackSize;
    // Captures the stack size difference between parent widget and child widget
    // during the rendering pipeline, i.e. one layer of stateless widget.
    // print('parentStackSize: $parentStackSize, myStackSize $myStackSize');
    return Text(
      '${parentStackSize - myStackSize}',
      key: const ValueKey<String>(kStackSizeKey),
    );
  }
}
