// ifileopendialog.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../structs.g.dart';
import '../utils.dart';
import '../variant.dart';
import '../win32/ole32.g.dart';
import 'ifiledialog.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IFileOpenDialog = '{d57c7288-d4ad-4768-be02-9d969532d960}';

/// {@category Interface}
/// {@category com}
class IFileOpenDialog extends IFileDialog {
  // vtable begins at 27, is 2 entries long.
  IFileOpenDialog(super.ptr);

  factory IFileOpenDialog.from(IUnknown interface) =>
      IFileOpenDialog(interface.toInterface(IID_IFileOpenDialog));

  int getResults(Pointer<Pointer<COMObject>> ppenum) => ptr.ref.vtable
          .elementAt(27)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppenum)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppenum)>()(
      ptr.ref.lpVtbl, ppenum);

  int getSelectedItems(Pointer<Pointer<COMObject>> ppsai) => ptr.ref.vtable
          .elementAt(28)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppsai)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppsai)>()(
      ptr.ref.lpVtbl, ppsai);
}

/// @nodoc
const CLSID_FileOpenDialog = '{dc1c5a9c-e88a-4dde-a5a1-60f82a20aef7}';

/// {@category com}
class FileOpenDialog extends IFileOpenDialog {
  FileOpenDialog(super.ptr);

  factory FileOpenDialog.createInstance() => FileOpenDialog(
      COMObject.createFromID(CLSID_FileOpenDialog, IID_IFileOpenDialog));
}
