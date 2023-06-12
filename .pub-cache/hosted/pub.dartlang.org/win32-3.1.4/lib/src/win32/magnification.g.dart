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

final _magnification = DynamicLibrary.open('magnification.dll');

/// Gets the color transformation matrix for a magnifier control.
///
/// ```c
/// BOOL MagGetColorEffect(
///   HWND            hwnd,
///   PMAGCOLOREFFECT pEffect
/// );
/// ```
/// {@category magnification}
int MagGetColorEffect(int hwnd, Pointer<MAGCOLOREFFECT> pEffect) =>
    _MagGetColorEffect(hwnd, pEffect);

final _MagGetColorEffect = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<MAGCOLOREFFECT> pEffect),
    int Function(
        int hwnd, Pointer<MAGCOLOREFFECT> pEffect)>('MagGetColorEffect');

/// Retrieves the color transformation matrix associated with the
/// full-screen magnifier.
///
/// ```c
/// BOOL MagGetFullscreenColorEffect(
///   PMAGCOLOREFFECT pEffect
/// );
/// ```
/// {@category magnification}
int MagGetFullscreenColorEffect(Pointer<MAGCOLOREFFECT> pEffect) =>
    _MagGetFullscreenColorEffect(pEffect);

final _MagGetFullscreenColorEffect = _magnification.lookupFunction<
    Int32 Function(Pointer<MAGCOLOREFFECT> pEffect),
    int Function(
        Pointer<MAGCOLOREFFECT> pEffect)>('MagGetFullscreenColorEffect');

/// Retrieves the magnification settings for the full-screen magnifier.
///
/// ```c
/// BOOL MagGetFullscreenTransform(
///   float *pMagLevel,
///   int   *pxOffset,
///   int   *pyOffset
/// );
/// ```
/// {@category magnification}
int MagGetFullscreenTransform(Pointer<Float> pMagLevel, Pointer<Int32> pxOffset,
        Pointer<Int32> pyOffset) =>
    _MagGetFullscreenTransform(pMagLevel, pxOffset, pyOffset);

final _MagGetFullscreenTransform = _magnification.lookupFunction<
    Int32 Function(Pointer<Float> pMagLevel, Pointer<Int32> pxOffset,
        Pointer<Int32> pyOffset),
    int Function(Pointer<Float> pMagLevel, Pointer<Int32> pxOffset,
        Pointer<Int32> pyOffset)>('MagGetFullscreenTransform');

/// Retrieves the registered callback function that implements a custom
/// transform for image scaling.
///
/// ```c
/// MagImageScalingCallback MagGetImageScalingCallback(
///   HWND hwnd
/// );
/// ```
/// {@category magnification}
Pointer<NativeFunction<MagImageScalingCallback>> MagGetImageScalingCallback(
        int hwnd) =>
    _MagGetImageScalingCallback(hwnd);

final _MagGetImageScalingCallback = _magnification.lookupFunction<
    Pointer<NativeFunction<MagImageScalingCallback>> Function(IntPtr hwnd),
    Pointer<NativeFunction<MagImageScalingCallback>> Function(
        int hwnd)>('MagGetImageScalingCallback');

/// Retrieves the current input transformation for pen and touch input,
/// represented as a source rectangle and a destination rectangle.
///
/// ```c
/// BOOL MagGetInputTransform(
///   BOOL   *pfEnabled,
///   LPRECT pRectSource,
///   LPRECT pRectDest
/// );
/// ```
/// {@category magnification}
int MagGetInputTransform(Pointer<Int32> pfEnabled, Pointer<RECT> pRectSource,
        Pointer<RECT> pRectDest) =>
    _MagGetInputTransform(pfEnabled, pRectSource, pRectDest);

final _MagGetInputTransform = _magnification.lookupFunction<
    Int32 Function(Pointer<Int32> pfEnabled, Pointer<RECT> pRectSource,
        Pointer<RECT> pRectDest),
    int Function(Pointer<Int32> pfEnabled, Pointer<RECT> pRectSource,
        Pointer<RECT> pRectDest)>('MagGetInputTransform');

/// Retrieves the list of windows that are magnified or excluded from
/// magnification.
///
/// ```c
/// int MagGetWindowFilterList(
///   HWND  hwnd,
///   DWORD *pdwFilterMode,
///   int   count,
///   HWND  *pHWND
/// );
/// ```
/// {@category magnification}
int MagGetWindowFilterList(int hwnd, Pointer<Uint32> pdwFilterMode, int count,
        Pointer<IntPtr> pHWND) =>
    _MagGetWindowFilterList(hwnd, pdwFilterMode, count, pHWND);

final _MagGetWindowFilterList = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<Uint32> pdwFilterMode, Int32 count,
        Pointer<IntPtr> pHWND),
    int Function(int hwnd, Pointer<Uint32> pdwFilterMode, int count,
        Pointer<IntPtr> pHWND)>('MagGetWindowFilterList');

/// Gets the rectangle of the area that is being magnified.
///
/// ```c
/// BOOL MagGetWindowSource(
///   HWND hwnd,
///   RECT *pRect
/// );
/// ```
/// {@category magnification}
int MagGetWindowSource(int hwnd, Pointer<RECT> pRect) =>
    _MagGetWindowSource(hwnd, pRect);

final _MagGetWindowSource = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<RECT> pRect),
    int Function(int hwnd, Pointer<RECT> pRect)>('MagGetWindowSource');

/// Retrieves the transformation matrix associated with a magnifier control.
///
/// ```c
/// BOOL MagGetWindowTransform(
///   HWND          hwnd,
///   PMAGTRANSFORM pTransform
/// );
/// ```
/// {@category magnification}
int MagGetWindowTransform(int hwnd, Pointer<MAGTRANSFORM> pTransform) =>
    _MagGetWindowTransform(hwnd, pTransform);

final _MagGetWindowTransform = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<MAGTRANSFORM> pTransform),
    int Function(
        int hwnd, Pointer<MAGTRANSFORM> pTransform)>('MagGetWindowTransform');

/// Creates and initializes the magnifier run-time objects.
///
/// ```c
/// BOOL MagInitialize();
/// ```
/// {@category magnification}
int MagInitialize() => _MagInitialize();

final _MagInitialize = _magnification
    .lookupFunction<Int32 Function(), int Function()>('MagInitialize');

/// Sets the color transformation matrix for a magnifier control.
///
/// ```c
/// BOOL MagSetColorEffect(
///   HWND            hwnd,
///   PMAGCOLOREFFECT pEffect
/// );
/// ```
/// {@category magnification}
int MagSetColorEffect(int hwnd, Pointer<MAGCOLOREFFECT> pEffect) =>
    _MagSetColorEffect(hwnd, pEffect);

final _MagSetColorEffect = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<MAGCOLOREFFECT> pEffect),
    int Function(
        int hwnd, Pointer<MAGCOLOREFFECT> pEffect)>('MagSetColorEffect');

/// Changes the color transformation matrix associated with the full-screen
/// magnifier.
///
/// ```c
/// BOOL MagSetFullscreenColorEffect(
///   PMAGCOLOREFFECT pEffect
/// );
/// ```
/// {@category magnification}
int MagSetFullscreenColorEffect(Pointer<MAGCOLOREFFECT> pEffect) =>
    _MagSetFullscreenColorEffect(pEffect);

final _MagSetFullscreenColorEffect = _magnification.lookupFunction<
    Int32 Function(Pointer<MAGCOLOREFFECT> pEffect),
    int Function(
        Pointer<MAGCOLOREFFECT> pEffect)>('MagSetFullscreenColorEffect');

/// Changes the magnification settings for the full-screen magnifier.
///
/// ```c
/// BOOL MagSetFullscreenTransform(
///   float magLevel,
///   int   xOffset,
///   int   yOffset
/// );
/// ```
/// {@category magnification}
int MagSetFullscreenTransform(double magLevel, int xOffset, int yOffset) =>
    _MagSetFullscreenTransform(magLevel, xOffset, yOffset);

final _MagSetFullscreenTransform = _magnification.lookupFunction<
    Int32 Function(Float magLevel, Int32 xOffset, Int32 yOffset),
    int Function(double magLevel, int xOffset,
        int yOffset)>('MagSetFullscreenTransform');

/// Sets the callback function for external image filtering and scaling.
///
/// ```c
/// BOOL MagSetImageScalingCallback(
///   HWND                    hwnd,
///   MagImageScalingCallback callback
/// );
/// ```
/// {@category magnification}
int MagSetImageScalingCallback(
        int hwnd, Pointer<NativeFunction<MagImageScalingCallback>> callback) =>
    _MagSetImageScalingCallback(hwnd, callback);

final _MagSetImageScalingCallback = _magnification.lookupFunction<
    Int32 Function(
        IntPtr hwnd, Pointer<NativeFunction<MagImageScalingCallback>> callback),
    int Function(
        int hwnd,
        Pointer<NativeFunction<MagImageScalingCallback>>
            callback)>('MagSetImageScalingCallback');

/// Sets the current active input transformation for pen and touch input,
/// represented as a source rectangle and a destination rectangle.
///
/// ```c
/// BOOL MagSetInputTransform(
///   BOOL         fEnabled,
///   const LPRECT pRectSource,
///   const LPRECT pRectDest
/// );
/// ```
/// {@category magnification}
int MagSetInputTransform(
        int fEnabled, Pointer<RECT> pRectSource, Pointer<RECT> pRectDest) =>
    _MagSetInputTransform(fEnabled, pRectSource, pRectDest);

final _MagSetInputTransform = _magnification.lookupFunction<
    Int32 Function(
        Int32 fEnabled, Pointer<RECT> pRectSource, Pointer<RECT> pRectDest),
    int Function(int fEnabled, Pointer<RECT> pRectSource,
        Pointer<RECT> pRectDest)>('MagSetInputTransform');

/// Sets the list of windows to be magnified or the list of windows to be
/// excluded from magnification.
///
/// ```c
/// BOOL MagSetWindowFilterList(
///   HWND  hwnd,
///   DWORD dwFilterMode,
///   int   count,
///   HWND  *pHWND
/// );
/// ```
/// {@category magnification}
int MagSetWindowFilterList(
        int hwnd, int dwFilterMode, int count, Pointer<IntPtr> pHWND) =>
    _MagSetWindowFilterList(hwnd, dwFilterMode, count, pHWND);

final _MagSetWindowFilterList = _magnification.lookupFunction<
    Int32 Function(
        IntPtr hwnd, Uint32 dwFilterMode, Int32 count, Pointer<IntPtr> pHWND),
    int Function(int hwnd, int dwFilterMode, int count,
        Pointer<IntPtr> pHWND)>('MagSetWindowFilterList');

/// Sets the source rectangle for the magnification window.
///
/// ```c
/// BOOL MagSetWindowSource(
///   HWND hwnd,
///   RECT rect
/// );
/// ```
/// {@category magnification}
int MagSetWindowSource(int hwnd, RECT rect) => _MagSetWindowSource(hwnd, rect);

final _MagSetWindowSource = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, RECT rect),
    int Function(int hwnd, RECT rect)>('MagSetWindowSource');

/// Sets the transformation matrix for a magnifier control.
///
/// ```c
/// BOOL MagSetWindowTransform(
///   HWND          hwnd,
///   PMAGTRANSFORM pTransform
/// );
/// ```
/// {@category magnification}
int MagSetWindowTransform(int hwnd, Pointer<MAGTRANSFORM> pTransform) =>
    _MagSetWindowTransform(hwnd, pTransform);

final _MagSetWindowTransform = _magnification.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<MAGTRANSFORM> pTransform),
    int Function(
        int hwnd, Pointer<MAGTRANSFORM> pTransform)>('MagSetWindowTransform');

/// Shows or hides the system cursor.
///
/// ```c
/// BOOL MagShowSystemCursor(
///   BOOL fShowCursor
/// );
/// ```
/// {@category magnification}
int MagShowSystemCursor(int fShowCursor) => _MagShowSystemCursor(fShowCursor);

final _MagShowSystemCursor = _magnification.lookupFunction<
    Int32 Function(Int32 fShowCursor),
    int Function(int fShowCursor)>('MagShowSystemCursor');

/// Destroys the magnifier run-time objects.
///
/// ```c
/// BOOL MagUninitialize();
/// ```
/// {@category magnification}
int MagUninitialize() => _MagUninitialize();

final _MagUninitialize = _magnification
    .lookupFunction<Int32 Function(), int Function()>('MagUninitialize');
