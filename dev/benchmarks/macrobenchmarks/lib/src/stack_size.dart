// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'dart:io' as io;

import 'package:flutter/material.dart';

import '../common.dart';

typedef GetStackPointerCallback = int Function();

// c interop function:
// void* mmap(void* addr, size_t len, int prot, int flags, int fd, off_t offset);
typedef CMmap = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>, ffi.IntPtr, ffi.Int32, ffi.Int32, ffi.Int32, ffi.IntPtr);
typedef DartMmap = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<ffi.Void>, int, int, int, int, int);
final DartMmap mmap = ffi.DynamicLibrary.process().lookupFunction<CMmap, DartMmap>('mmap');

// c interop function:
// int mprotect(void* addr, size_t len, int prot);
typedef CMprotect = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.IntPtr, ffi.Int32);
typedef DartMprotect = int Function(ffi.Pointer<ffi.Void>, int, int);
final DartMprotect mprotect = ffi.DynamicLibrary.process()
    .lookupFunction<CMprotect, DartMprotect>('mprotect');

const int protRead = 1;
const int protWrite = 2;
const int protExec = 4;

const int mapPrivate = 0x02;
const int mapJit = 0x0;
const int mapAnon = 0x20;

String get currentArch {
  return ffi.sizeOf<ffi.IntPtr>() == 4 ? 'arm' : 'arm64';
}

final GetStackPointerCallback getStackPointer = () {
  if (!io.Platform.isAndroid) {
    throw 'This benchmark test can only be run on Android.';
  }
  // Creates a block of memory to store the assembly code.
  final ffi.Pointer<ffi.Void> region = mmap(ffi.nullptr, 4096, protRead | protWrite,
      mapPrivate | mapAnon | mapJit, -1, 0);
  // Write the assembly code into the memory block. This assembly code returns
  // the memory address of stack pointer.
  region.cast<ffi.Uint8>().asTypedList(4096).setAll(
      0,
      const <String, List<int>>{
        'arm64': <int>[
          // "mov x0, sp"  in machine code: E0030091.
          0xe0, 0x03, 0x00, 0x91,
          // "ret"         in machine code: C0035FD6.
          0xc0, 0x03, 0x5f, 0xd6],
        // ARM32: mov r0, sp; ret;
        'arm': <int>[
          // "mov r0, sp" in machine code: 0D00A0E1.
          0x0d, 0x00, 0xa0, 0xe1,
          // "bx lr"      in machine code: 1EFF2FE1.
          0x1e, 0xff, 0x2f, 0xe1],
      }[currentArch]);
  // Makes sure the memory block is executable.
  if (mprotect(region, 4096, protRead | protExec) != 0) {
    throw 'Failed to mark code as executable.';
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
