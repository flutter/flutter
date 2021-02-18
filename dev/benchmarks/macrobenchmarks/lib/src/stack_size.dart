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

const int kProtRead = 1;
const int kProtWrite = 2;
const int kProtExec = 4;

const int kMapPrivate = 0x02;
const int kMapJit = 0x0;
const int kMapAnon = 0x20;

const int kMemorySize = 16;
const int kInvalidFileDescriptor = -1;
const int kkFileMappingOffset = 0;

const int kMemoryStartingIndex = 0;

const int kExitCodeSuccess = 0;

final GetStackPointerCallback getStackPointer = () {
  // Makes sure we are running on an Android arm64 device.
  if (!io.Platform.isAndroid)
    throw 'This benchmark test can only be run on Android arm devices.';
  final io.ProcessResult result = io.Process.runSync('getprop', <String>['ro.product.cpu.abi']);
  if (result.exitCode != 0)
    throw 'Failed to retrieve CPU information.';
  if (!result.stdout.toString().contains('armeabi'))
    throw 'This benchmark test can only be run on Android arm devices.';

  // Creates a block of memory to store the assembly code.
  final ffi.Pointer<ffi.Void> region = mmap(ffi.nullptr, kMemorySize, kProtRead | kProtWrite,
      kMapPrivate | kMapAnon | kMapJit, kInvalidFileDescriptor, kkFileMappingOffset);
  if (region == ffi.nullptr) {
    throw 'Failed to acquire memory for the test.';
  }

  // Writes the assembly code into the memory block. This assembly code returns
  // the memory address of the stack pointer.
  region.cast<ffi.Uint8>().asTypedList(kMemorySize).setAll(
    kMemoryStartingIndex,
    <int>[
      // "mov r0, sp"  in machine code: 0D00A0E1.
      0x0d, 0x00, 0xa0, 0xe1,
      // "bx lr"       in machine code: 1EFF2FE1.
      0x1e, 0xff, 0x2f, 0xe1
    ]
  );

  // Makes sure the memory block is executable.
  if (mprotect(region, kMemorySize, kProtRead | kProtExec) != kExitCodeSuccess) {
    throw 'Failed to write executable code to the memory.';
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
    final int myStackSize = getStackPointer();
    return ChildWidget(parentStackSize: myStackSize);
  }
}

class ChildWidget extends StatelessWidget {
  const ChildWidget({this.parentStackSize, Key key}) : super(key: key);
  final int parentStackSize;

  @override
  Widget build(BuildContext context) {
    final int myStackSize = getStackPointer();
    // Captures the stack size difference between parent widget and child widget
    // during the rendering pipeline, i.e. one layer of stateless widget.
    return Text(
      '${parentStackSize - myStackSize}',
      key: const ValueKey<String>(kStackSizeKey),
    );
  }
}
