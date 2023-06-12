// ifiledialogcustomize.dart

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
import 'iunknown.dart';

/// @nodoc
const IID_IFileDialogCustomize = '{E6FDD21A-163F-4975-9C8C-A69F1BA37034}';

/// {@category Interface}
/// {@category com}
class IFileDialogCustomize extends IUnknown {
  // vtable begins at 3, is 27 entries long.
  IFileDialogCustomize(super.ptr);

  factory IFileDialogCustomize.from(IUnknown interface) =>
      IFileDialogCustomize(interface.toInterface(IID_IFileDialogCustomize));

  int enableOpenDropDown(int dwIDCtl) => ptr.ref.vtable
      .elementAt(3)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int addMenu(int dwIDCtl, Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszLabel);

  int addPushButton(int dwIDCtl, Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszLabel);

  int addComboBox(int dwIDCtl) => ptr.ref.vtable
      .elementAt(6)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int addRadioButtonList(int dwIDCtl) => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int addCheckButton(int dwIDCtl, Pointer<Utf16> pszLabel, int bChecked) =>
      ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl,
                          Pointer<Utf16> pszLabel, Int32 bChecked)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszLabel,
                  int bChecked)>()(ptr.ref.lpVtbl, dwIDCtl, pszLabel, bChecked);

  int addEditBox(int dwIDCtl, Pointer<Utf16> pszText) => ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszText)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszText)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszText);

  int addSeparator(int dwIDCtl) => ptr.ref.vtable
      .elementAt(10)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int addText(int dwIDCtl, Pointer<Utf16> pszText) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszText)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszText)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszText);

  int setControlLabel(int dwIDCtl, Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszLabel);

  int getControlState(int dwIDCtl, Pointer<Int32> pdwState) => ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Int32> pdwState)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Int32> pdwState)>()(
      ptr.ref.lpVtbl, dwIDCtl, pdwState);

  int setControlState(int dwIDCtl, int dwState) =>
      ptr.ref.vtable
              .elementAt(14)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Uint32 dwIDCtl, Int32 dwState)>>>()
              .value
              .asFunction<int Function(Pointer, int dwIDCtl, int dwState)>()(
          ptr.ref.lpVtbl, dwIDCtl, dwState);

  int getEditBoxText(int dwIDCtl, Pointer<Pointer<Uint16>> ppszText) => ptr
          .ref.vtable
          .elementAt(15)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl,
                          Pointer<Pointer<Uint16>> ppszText)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int dwIDCtl, Pointer<Pointer<Uint16>> ppszText)>()(
      ptr.ref.lpVtbl, dwIDCtl, ppszText);

  int setEditBoxText(int dwIDCtl, Pointer<Utf16> pszText) => ptr.ref.vtable
          .elementAt(16)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszText)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszText)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszText);

  int getCheckButtonState(int dwIDCtl, Pointer<Int32> pbChecked) => ptr
      .ref.vtable
      .elementAt(17)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Uint32 dwIDCtl, Pointer<Int32> pbChecked)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl,
              Pointer<Int32> pbChecked)>()(ptr.ref.lpVtbl, dwIDCtl, pbChecked);

  int setCheckButtonState(int dwIDCtl, int bChecked) =>
      ptr.ref.vtable
              .elementAt(18)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Uint32 dwIDCtl, Int32 bChecked)>>>()
              .value
              .asFunction<int Function(Pointer, int dwIDCtl, int bChecked)>()(
          ptr.ref.lpVtbl, dwIDCtl, bChecked);

  int addControlItem(int dwIDCtl, int dwIDItem, Pointer<Utf16> pszLabel) => ptr
          .ref.vtable
          .elementAt(19)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl, Uint32 dwIDItem,
                          Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, int dwIDItem,
                  Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, dwIDCtl, dwIDItem, pszLabel);

  int removeControlItem(int dwIDCtl, int dwIDItem) =>
      ptr.ref.vtable
              .elementAt(20)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Uint32 dwIDCtl, Uint32 dwIDItem)>>>()
              .value
              .asFunction<int Function(Pointer, int dwIDCtl, int dwIDItem)>()(
          ptr.ref.lpVtbl, dwIDCtl, dwIDItem);

  int removeAllControlItems(int dwIDCtl) => ptr.ref.vtable
      .elementAt(21)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int getControlItemState(int dwIDCtl, int dwIDItem, Pointer<Int32> pdwState) =>
      ptr.ref.vtable
          .elementAt(22)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl, Uint32 dwIDItem,
                          Pointer<Int32> pdwState)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  int dwIDCtl,
                  int dwIDItem,
                  Pointer<Int32>
                      pdwState)>()(ptr.ref.lpVtbl, dwIDCtl, dwIDItem, pdwState);

  int setControlItemState(int dwIDCtl, int dwIDItem, int dwState) =>
      ptr.ref.vtable
          .elementAt(23)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl, Uint32 dwIDItem,
                          Int32 dwState)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, int dwIDItem,
                  int dwState)>()(ptr.ref.lpVtbl, dwIDCtl, dwIDItem, dwState);

  int getSelectedControlItem(int dwIDCtl, Pointer<Uint32> pdwIDItem) => ptr
      .ref.vtable
      .elementAt(24)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Uint32 dwIDCtl, Pointer<Uint32> pdwIDItem)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl,
              Pointer<Uint32> pdwIDItem)>()(ptr.ref.lpVtbl, dwIDCtl, pdwIDItem);

  int setSelectedControlItem(int dwIDCtl, int dwIDItem) =>
      ptr.ref.vtable
              .elementAt(25)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Uint32 dwIDCtl, Uint32 dwIDItem)>>>()
              .value
              .asFunction<int Function(Pointer, int dwIDCtl, int dwIDItem)>()(
          ptr.ref.lpVtbl, dwIDCtl, dwIDItem);

  int startVisualGroup(int dwIDCtl, Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(26)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwIDCtl, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwIDCtl, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, dwIDCtl, pszLabel);

  int endVisualGroup() => ptr.ref.vtable
      .elementAt(27)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int makeProminent(int dwIDCtl) => ptr.ref.vtable
      .elementAt(28)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwIDCtl)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwIDCtl)>()(ptr.ref.lpVtbl, dwIDCtl);

  int setControlItemText(int dwIDCtl, int dwIDItem, Pointer<Utf16> pszLabel) =>
      ptr.ref.vtable
          .elementAt(29)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwIDCtl, Uint32 dwIDItem,
                          Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  int dwIDCtl,
                  int dwIDItem,
                  Pointer<Utf16>
                      pszLabel)>()(ptr.ref.lpVtbl, dwIDCtl, dwIDItem, pszLabel);
}
