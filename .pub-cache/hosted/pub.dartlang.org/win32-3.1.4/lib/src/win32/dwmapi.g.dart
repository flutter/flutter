// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../guid.dart';
import '../structs.g.dart';
import '../variant.dart';

final _dwmapi = DynamicLibrary.open('dwmapi.dll');

/// Enables the blur effect on a specified window.
///
/// ```c
/// DWMAPI DwmEnableBlurBehindWindow(
///   HWND                 hWnd,
///   const DWM_BLURBEHIND *pBlurBehind
/// );
/// ```
/// {@category dwmapi}
int DwmEnableBlurBehindWindow(int hWnd, Pointer<DWM_BLURBEHIND> pBlurBehind) =>
    _DwmEnableBlurBehindWindow(hWnd, pBlurBehind);

final _DwmEnableBlurBehindWindow = _dwmapi.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<DWM_BLURBEHIND> pBlurBehind),
    int Function(int hWnd,
        Pointer<DWM_BLURBEHIND> pBlurBehind)>('DwmEnableBlurBehindWindow');

/// Notifies the Desktop Window Manager (DWM) to opt in to or out of
/// Multimedia Class Schedule Service (MMCSS) scheduling while the calling
/// process is alive.
///
/// ```c
/// DWMAPI DwmEnableMMCSS(
///   BOOL fEnableMMCSS
/// );
/// ```
/// {@category dwmapi}
int DwmEnableMMCSS(int fEnableMMCSS) => _DwmEnableMMCSS(fEnableMMCSS);

final _DwmEnableMMCSS = _dwmapi.lookupFunction<
    Int32 Function(Int32 fEnableMMCSS),
    int Function(int fEnableMMCSS)>('DwmEnableMMCSS');

/// Extends the window frame into the client area.
///
/// ```c
/// DWMAPI DwmExtendFrameIntoClientArea(
///   HWND          hWnd,
///   const MARGINS *pMarInset
/// );
/// ```
/// {@category dwmapi}
int DwmExtendFrameIntoClientArea(int hWnd, Pointer<MARGINS> pMarInset) =>
    _DwmExtendFrameIntoClientArea(hWnd, pMarInset);

final _DwmExtendFrameIntoClientArea = _dwmapi.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<MARGINS> pMarInset),
    int Function(
        int hWnd, Pointer<MARGINS> pMarInset)>('DwmExtendFrameIntoClientArea');

/// Issues a flush call that blocks the caller until the next present, when
/// all of the Microsoft DirectX surface updates that are currently
/// outstanding have been made. This compensates for very complex scenes or
/// calling processes with very low priority.
///
/// ```c
/// DWMAPI DwmFlush();
/// ```
/// {@category dwmapi}
int DwmFlush() => _DwmFlush();

final _DwmFlush =
    _dwmapi.lookupFunction<Int32 Function(), int Function()>('DwmFlush');

/// Retrieves the current color used for Desktop Window Manager (DWM) glass
/// composition. This value is based on the current color scheme and can be
/// modified by the user. Applications can listen for color changes by
/// handling the WM_DWMCOLORIZATIONCOLORCHANGED notification.
///
/// ```c
/// DWMAPI DwmGetColorizationColor(
///   DWORD *pcrColorization,
///   BOOL  *pfOpaqueBlend
/// );
/// ```
/// {@category dwmapi}
int DwmGetColorizationColor(
        Pointer<Uint32> pcrColorization, Pointer<Int32> pfOpaqueBlend) =>
    _DwmGetColorizationColor(pcrColorization, pfOpaqueBlend);

final _DwmGetColorizationColor = _dwmapi.lookupFunction<
    Int32 Function(
        Pointer<Uint32> pcrColorization, Pointer<Int32> pfOpaqueBlend),
    int Function(Pointer<Uint32> pcrColorization,
        Pointer<Int32> pfOpaqueBlend)>('DwmGetColorizationColor');

/// Retrieves transport attributes.
///
/// ```c
/// DWMAPI DwmGetTransportAttributes(
///   BOOL  *pfIsRemoting,
///   BOOL  *pfIsConnected,
///   DWORD *pDwGeneration
/// );
/// ```
/// {@category dwmapi}
int DwmGetTransportAttributes(Pointer<Int32> pfIsRemoting,
        Pointer<Int32> pfIsConnected, Pointer<Uint32> pDwGeneration) =>
    _DwmGetTransportAttributes(pfIsRemoting, pfIsConnected, pDwGeneration);

final _DwmGetTransportAttributes = _dwmapi.lookupFunction<
    Int32 Function(Pointer<Int32> pfIsRemoting, Pointer<Int32> pfIsConnected,
        Pointer<Uint32> pDwGeneration),
    int Function(Pointer<Int32> pfIsRemoting, Pointer<Int32> pfIsConnected,
        Pointer<Uint32> pDwGeneration)>('DwmGetTransportAttributes');

/// Retrieves the current value of a specified Desktop Window Manager (DWM)
/// attribute applied to a window.
///
/// ```c
/// DWMAPI DwmGetWindowAttribute(
///   HWND  hwnd,
///   DWORD dwAttribute,
///   PVOID pvAttribute,
///   DWORD cbAttribute
/// );
/// ```
/// {@category dwmapi}
int DwmGetWindowAttribute(
        int hwnd, int dwAttribute, Pointer pvAttribute, int cbAttribute) =>
    _DwmGetWindowAttribute(hwnd, dwAttribute, pvAttribute, cbAttribute);

final _DwmGetWindowAttribute = _dwmapi.lookupFunction<
    Int32 Function(IntPtr hwnd, Int32 dwAttribute, Pointer pvAttribute,
        Uint32 cbAttribute),
    int Function(int hwnd, int dwAttribute, Pointer pvAttribute,
        int cbAttribute)>('DwmGetWindowAttribute');

/// Called by an application to indicate that all previously provided iconic
/// bitmaps from a window, both thumbnails and peek representations, should
/// be refreshed.
///
/// ```c
/// DWMAPI DwmInvalidateIconicBitmaps(
///   HWND hwnd
/// );
/// ```
/// {@category dwmapi}
int DwmInvalidateIconicBitmaps(int hwnd) => _DwmInvalidateIconicBitmaps(hwnd);

final _DwmInvalidateIconicBitmaps =
    _dwmapi.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'DwmInvalidateIconicBitmaps');

/// Notifies Desktop Window Manager (DWM) that a touch contact has been
/// recognized as a gesture, and that DWM should draw feedback for that
/// gesture.
///
/// ```c
/// DWMAPI DwmRenderGesture(
///   GESTURE_TYPE gt,
///   UINT         cContacts,
///   const DWORD  *pdwPointerID,
///   const POINT  *pPoints
/// );
/// ```
/// {@category dwmapi}
int DwmRenderGesture(int gt, int cContacts, Pointer<Uint32> pdwPointerID,
        Pointer<POINT> pPoints) =>
    _DwmRenderGesture(gt, cContacts, pdwPointerID, pPoints);

final _DwmRenderGesture = _dwmapi.lookupFunction<
    Int32 Function(Int32 gt, Uint32 cContacts, Pointer<Uint32> pdwPointerID,
        Pointer<POINT> pPoints),
    int Function(int gt, int cContacts, Pointer<Uint32> pdwPointerID,
        Pointer<POINT> pPoints)>('DwmRenderGesture');

/// Sets the value of Desktop Window Manager (DWM) non-client rendering
/// attributes for a window.
///
/// ```c
/// DWMAPI DwmSetWindowAttribute(
///   HWND    hwnd,
///   DWORD   dwAttribute,
///   LPCVOID pvAttribute,
///   DWORD   cbAttribute
/// );
/// ```
/// {@category dwmapi}
int DwmSetWindowAttribute(
        int hwnd, int dwAttribute, Pointer pvAttribute, int cbAttribute) =>
    _DwmSetWindowAttribute(hwnd, dwAttribute, pvAttribute, cbAttribute);

final _DwmSetWindowAttribute = _dwmapi.lookupFunction<
    Int32 Function(IntPtr hwnd, Int32 dwAttribute, Pointer pvAttribute,
        Uint32 cbAttribute),
    int Function(int hwnd, int dwAttribute, Pointer pvAttribute,
        int cbAttribute)>('DwmSetWindowAttribute');

/// Called by an app or framework to specify the visual feedback type to
/// draw in response to a particular touch or pen contact.
///
/// ```c
/// DWMAPI DwmShowContact(
///   DWORD           dwPointerID,
///   DWM_SHOWCONTACT eShowContact
/// );
/// ```
/// {@category dwmapi}
int DwmShowContact(int dwPointerID, int eShowContact) =>
    _DwmShowContact(dwPointerID, eShowContact);

final _DwmShowContact = _dwmapi.lookupFunction<
    Int32 Function(Uint32 dwPointerID, Uint32 eShowContact),
    int Function(int dwPointerID, int eShowContact)>('DwmShowContact');
