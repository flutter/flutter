// // Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// import 'dart:async';
// import 'dart:typed_data';
//
// import 'package:vm_service/vm_service.dart';
// import 'package:vm_service/vm_service_io.dart';
//
// Future<List<ByteData>> loadFromUri(Uri uri) async {
//   final Uri wsUri;
//   if (uri.isScheme("ws")) {
//     wsUri = uri;
//   } else {
//     if (uri.path.isEmpty || uri.path == "/") {
//       uri = uri.replace(path: "/ws");
//     } else if (uri.path.endsWith("/")) {
//       uri = uri.replace(path: "${uri.path}ws");
//     } else {
//       uri = uri.replace(path: "${uri.path}/ws");
//     }
//     wsUri = uri.replace(scheme: 'ws');
//   }
//   final service = await vmServiceConnectUri(wsUri.toString());
//   try {
//     final r = await _getHeapsnapshot(service);
//     return r;
//   } finally {
//     await service.dispose();
//   }
// }
//
// Future<List<ByteData>> _getHeapsnapshot(VmService service) async {
//   final vm = await service.getVM();
//   final vmIsolates = vm.isolates!;
//   if (vmIsolates.isEmpty) {
//     throw 'Could not find first isolate (expected it to be running already)';
//   }
//   final isolateRef = vmIsolates.first;
//
//   await service.streamListen(EventStreams.kHeapSnapshot);
//
//   final chunks = <ByteData>[];
//   final done = Completer();
//   late StreamSubscription streamSubscription;
//   streamSubscription = service.onHeapSnapshotEvent.listen((e) async {
//     chunks.add(e.data!);
//     if (e.last!) {
//       await service.streamCancel(EventStreams.kHeapSnapshot);
//       await streamSubscription.cancel();
//       done.complete();
//     }
//   });
//
//   await service.requestHeapSnapshot(isolateRef.id!);
//   await done.future;
//
//   return chunks;
// }
