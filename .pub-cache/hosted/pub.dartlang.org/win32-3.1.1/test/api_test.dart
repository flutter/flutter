// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Win32 API prototypes can be successfully loaded (i.e. that
// lookupFunction works for all the APIs generated)

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: non_constant_identifier_names

@TestOn('windows')

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:win32/win32.dart';
import 'package:win32/winsock2.dart';

import 'helpers.dart';

void main() {
  final windowsBuildNumber = getWindowsBuildNumber();
  group('Test gdi32 functions', () {
    test('Can instantiate AbortPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final AbortPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('AbortPath');
      expect(AbortPath, isA<Function>());
    });
    test('Can instantiate AddFontResource', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final AddFontResource = gdi32.lookupFunction<
          Int32 Function(Pointer<Utf16> param0),
          int Function(Pointer<Utf16> param0)>('AddFontResourceW');
      expect(AddFontResource, isA<Function>());
    });
    test('Can instantiate AddFontResourceEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final AddFontResourceEx = gdi32.lookupFunction<
          Int32 Function(Pointer<Utf16> name, Uint32 fl, Pointer res),
          int Function(
              Pointer<Utf16> name, int fl, Pointer res)>('AddFontResourceExW');
      expect(AddFontResourceEx, isA<Function>());
    });
    test('Can instantiate AngleArc', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final AngleArc = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Uint32 r,
              Float StartAngle, Float SweepAngle),
          int Function(int hdc, int x, int y, int r, double StartAngle,
              double SweepAngle)>('AngleArc');
      expect(AngleArc, isA<Function>());
    });
    test('Can instantiate AnimatePalette', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final AnimatePalette = gdi32.lookupFunction<
          Int32 Function(IntPtr hPal, Uint32 iStartIndex, Uint32 cEntries,
              Pointer<PALETTEENTRY> ppe),
          int Function(int hPal, int iStartIndex, int cEntries,
              Pointer<PALETTEENTRY> ppe)>('AnimatePalette');
      expect(AnimatePalette, isA<Function>());
    });
    test('Can instantiate Arc', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Arc = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x1, Int32 y1, Int32 x2, Int32 y2,
              Int32 x3, Int32 y3, Int32 x4, Int32 y4),
          int Function(int hdc, int x1, int y1, int x2, int y2, int x3, int y3,
              int x4, int y4)>('Arc');
      expect(Arc, isA<Function>());
    });
    test('Can instantiate ArcTo', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final ArcTo = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 left, Int32 top, Int32 right,
              Int32 bottom, Int32 xr1, Int32 yr1, Int32 xr2, Int32 yr2),
          int Function(int hdc, int left, int top, int right, int bottom,
              int xr1, int yr1, int xr2, int yr2)>('ArcTo');
      expect(ArcTo, isA<Function>());
    });
    test('Can instantiate BeginPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final BeginPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('BeginPath');
      expect(BeginPath, isA<Function>());
    });
    test('Can instantiate BitBlt', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final BitBlt = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Int32 cx, Int32 cy,
              IntPtr hdcSrc, Int32 x1, Int32 y1, Uint32 rop),
          int Function(int hdc, int x, int y, int cx, int cy, int hdcSrc,
              int x1, int y1, int rop)>('BitBlt');
      expect(BitBlt, isA<Function>());
    });
    test('Can instantiate CancelDC', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CancelDC = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('CancelDC');
      expect(CancelDC, isA<Function>());
    });
    test('Can instantiate Chord', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Chord = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x1, Int32 y1, Int32 x2, Int32 y2,
              Int32 x3, Int32 y3, Int32 x4, Int32 y4),
          int Function(int hdc, int x1, int y1, int x2, int y2, int x3, int y3,
              int x4, int y4)>('Chord');
      expect(Chord, isA<Function>());
    });
    test('Can instantiate CloseFigure', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CloseFigure = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('CloseFigure');
      expect(CloseFigure, isA<Function>());
    });
    test('Can instantiate CreateCompatibleBitmap', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateCompatibleBitmap = gdi32.lookupFunction<
          IntPtr Function(IntPtr hdc, Int32 cx, Int32 cy),
          int Function(int hdc, int cx, int cy)>('CreateCompatibleBitmap');
      expect(CreateCompatibleBitmap, isA<Function>());
    });
    test('Can instantiate CreateCompatibleDC', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateCompatibleDC = gdi32.lookupFunction<
          IntPtr Function(IntPtr hdc),
          int Function(int hdc)>('CreateCompatibleDC');
      expect(CreateCompatibleDC, isA<Function>());
    });
    test('Can instantiate CreateDC', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateDC = gdi32.lookupFunction<
          IntPtr Function(Pointer<Utf16> pwszDriver, Pointer<Utf16> pwszDevice,
              Pointer<Utf16> pszPort, Pointer<DEVMODE> pdm),
          int Function(Pointer<Utf16> pwszDriver, Pointer<Utf16> pwszDevice,
              Pointer<Utf16> pszPort, Pointer<DEVMODE> pdm)>('CreateDCW');
      expect(CreateDC, isA<Function>());
    });
    test('Can instantiate CreateDIBitmap', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateDIBitmap = gdi32.lookupFunction<
          IntPtr Function(
              IntPtr hdc,
              Pointer<BITMAPINFOHEADER> pbmih,
              Uint32 flInit,
              Pointer pjBits,
              Pointer<BITMAPINFO> pbmi,
              Uint32 iUsage),
          int Function(
              int hdc,
              Pointer<BITMAPINFOHEADER> pbmih,
              int flInit,
              Pointer pjBits,
              Pointer<BITMAPINFO> pbmi,
              int iUsage)>('CreateDIBitmap');
      expect(CreateDIBitmap, isA<Function>());
    });
    test('Can instantiate CreateDIBPatternBrushPt', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateDIBPatternBrushPt = gdi32.lookupFunction<
          IntPtr Function(Pointer lpPackedDIB, Uint32 iUsage),
          int Function(
              Pointer lpPackedDIB, int iUsage)>('CreateDIBPatternBrushPt');
      expect(CreateDIBPatternBrushPt, isA<Function>());
    });
    test('Can instantiate CreateDIBSection', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateDIBSection = gdi32.lookupFunction<
          IntPtr Function(IntPtr hdc, Pointer<BITMAPINFO> pbmi, Uint32 usage,
              Pointer<Pointer> ppvBits, IntPtr hSection, Uint32 offset),
          int Function(
              int hdc,
              Pointer<BITMAPINFO> pbmi,
              int usage,
              Pointer<Pointer> ppvBits,
              int hSection,
              int offset)>('CreateDIBSection');
      expect(CreateDIBSection, isA<Function>());
    });
    test('Can instantiate CreateEllipticRgn', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateEllipticRgn = gdi32.lookupFunction<
          IntPtr Function(Int32 x1, Int32 y1, Int32 x2, Int32 y2),
          int Function(int x1, int y1, int x2, int y2)>('CreateEllipticRgn');
      expect(CreateEllipticRgn, isA<Function>());
    });
    test('Can instantiate CreateFontIndirect', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateFontIndirect = gdi32.lookupFunction<
          IntPtr Function(Pointer<LOGFONT> lplf),
          int Function(Pointer<LOGFONT> lplf)>('CreateFontIndirectW');
      expect(CreateFontIndirect, isA<Function>());
    });
    test('Can instantiate CreateHalftonePalette', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateHalftonePalette = gdi32.lookupFunction<
          IntPtr Function(IntPtr hdc),
          int Function(int hdc)>('CreateHalftonePalette');
      expect(CreateHalftonePalette, isA<Function>());
    });
    test('Can instantiate CreateHatchBrush', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateHatchBrush = gdi32.lookupFunction<
          IntPtr Function(Uint32 iHatch, Uint32 color),
          int Function(int iHatch, int color)>('CreateHatchBrush');
      expect(CreateHatchBrush, isA<Function>());
    });
    test('Can instantiate CreatePen', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreatePen = gdi32.lookupFunction<
          IntPtr Function(Uint32 iStyle, Int32 cWidth, Uint32 color),
          int Function(int iStyle, int cWidth, int color)>('CreatePen');
      expect(CreatePen, isA<Function>());
    });
    test('Can instantiate CreateSolidBrush', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final CreateSolidBrush = gdi32.lookupFunction<
          IntPtr Function(Uint32 color),
          int Function(int color)>('CreateSolidBrush');
      expect(CreateSolidBrush, isA<Function>());
    });
    test('Can instantiate DeleteDC', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final DeleteDC = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('DeleteDC');
      expect(DeleteDC, isA<Function>());
    });
    test('Can instantiate DeleteObject', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final DeleteObject =
          gdi32.lookupFunction<Int32 Function(IntPtr ho), int Function(int ho)>(
              'DeleteObject');
      expect(DeleteObject, isA<Function>());
    });
    test('Can instantiate DrawEscape', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final DrawEscape = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Int32 iEscape, Int32 cjIn, Pointer<Utf8> lpIn),
          int Function(int hdc, int iEscape, int cjIn,
              Pointer<Utf8> lpIn)>('DrawEscape');
      expect(DrawEscape, isA<Function>());
    });
    test('Can instantiate Ellipse', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Ellipse = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Int32 left, Int32 top, Int32 right, Int32 bottom),
          int Function(
              int hdc, int left, int top, int right, int bottom)>('Ellipse');
      expect(Ellipse, isA<Function>());
    });
    test('Can instantiate EndPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final EndPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('EndPath');
      expect(EndPath, isA<Function>());
    });
    test('Can instantiate EnumFontFamiliesEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final EnumFontFamiliesEx = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc,
              Pointer<LOGFONT> lpLogfont,
              Pointer<NativeFunction<EnumFontFamExProc>> lpProc,
              IntPtr lParam,
              Uint32 dwFlags),
          int Function(
              int hdc,
              Pointer<LOGFONT> lpLogfont,
              Pointer<NativeFunction<EnumFontFamExProc>> lpProc,
              int lParam,
              int dwFlags)>('EnumFontFamiliesExW');
      expect(EnumFontFamiliesEx, isA<Function>());
    });
    test('Can instantiate ExtCreatePen', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final ExtCreatePen = gdi32.lookupFunction<
          IntPtr Function(Uint32 iPenStyle, Uint32 cWidth,
              Pointer<LOGBRUSH> plbrush, Uint32 cStyle, Pointer<Uint32> pstyle),
          int Function(int iPenStyle, int cWidth, Pointer<LOGBRUSH> plbrush,
              int cStyle, Pointer<Uint32> pstyle)>('ExtCreatePen');
      expect(ExtCreatePen, isA<Function>());
    });
    test('Can instantiate ExtTextOut', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final ExtTextOut = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc,
              Int32 x,
              Int32 y,
              Uint32 options,
              Pointer<RECT> lprect,
              Pointer<Utf16> lpString,
              Uint32 c,
              Pointer<Int32> lpDx),
          int Function(
              int hdc,
              int x,
              int y,
              int options,
              Pointer<RECT> lprect,
              Pointer<Utf16> lpString,
              int c,
              Pointer<Int32> lpDx)>('ExtTextOutW');
      expect(ExtTextOut, isA<Function>());
    });
    test('Can instantiate FillPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final FillPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('FillPath');
      expect(FillPath, isA<Function>());
    });
    test('Can instantiate FlattenPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final FlattenPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('FlattenPath');
      expect(FlattenPath, isA<Function>());
    });
    test('Can instantiate GetDeviceCaps', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetDeviceCaps = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Uint32 index),
          int Function(int hdc, int index)>('GetDeviceCaps');
      expect(GetDeviceCaps, isA<Function>());
    });
    test('Can instantiate GetDIBits', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetDIBits = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, IntPtr hbm, Uint32 start, Uint32 cLines,
              Pointer lpvBits, Pointer<BITMAPINFO> lpbmi, Uint32 usage),
          int Function(int hdc, int hbm, int start, int cLines, Pointer lpvBits,
              Pointer<BITMAPINFO> lpbmi, int usage)>('GetDIBits');
      expect(GetDIBits, isA<Function>());
    });
    test('Can instantiate GetNearestColor', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetNearestColor = gdi32.lookupFunction<
          Uint32 Function(IntPtr hdc, Uint32 color),
          int Function(int hdc, int color)>('GetNearestColor');
      expect(GetNearestColor, isA<Function>());
    });
    test('Can instantiate GetObject', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetObject = gdi32.lookupFunction<
          Int32 Function(IntPtr h, Int32 c, Pointer pv),
          int Function(int h, int c, Pointer pv)>('GetObjectW');
      expect(GetObject, isA<Function>());
    });
    test('Can instantiate GetPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetPath = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Pointer<POINT> apt, Pointer<Uint8> aj, Int32 cpt),
          int Function(int hdc, Pointer<POINT> apt, Pointer<Uint8> aj,
              int cpt)>('GetPath');
      expect(GetPath, isA<Function>());
    });
    test('Can instantiate GetPixel', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetPixel = gdi32.lookupFunction<
          Uint32 Function(IntPtr hdc, Int32 x, Int32 y),
          int Function(int hdc, int x, int y)>('GetPixel');
      expect(GetPixel, isA<Function>());
    });
    test('Can instantiate GetStockObject', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetStockObject =
          gdi32.lookupFunction<IntPtr Function(Uint32 i), int Function(int i)>(
              'GetStockObject');
      expect(GetStockObject, isA<Function>());
    });
    test('Can instantiate GetTextMetrics', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetTextMetrics = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<TEXTMETRIC> lptm),
          int Function(int hdc, Pointer<TEXTMETRIC> lptm)>('GetTextMetricsW');
      expect(GetTextMetrics, isA<Function>());
    });
    test('Can instantiate GetWindowExtEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetWindowExtEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<SIZE> lpsize),
          int Function(int hdc, Pointer<SIZE> lpsize)>('GetWindowExtEx');
      expect(GetWindowExtEx, isA<Function>());
    });
    test('Can instantiate GetWindowOrgEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final GetWindowOrgEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> lppoint),
          int Function(int hdc, Pointer<POINT> lppoint)>('GetWindowOrgEx');
      expect(GetWindowOrgEx, isA<Function>());
    });
    test('Can instantiate LineTo', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final LineTo = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y),
          int Function(int hdc, int x, int y)>('LineTo');
      expect(LineTo, isA<Function>());
    });
    test('Can instantiate MoveToEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final MoveToEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Pointer<POINT> lppt),
          int Function(int hdc, int x, int y, Pointer<POINT> lppt)>('MoveToEx');
      expect(MoveToEx, isA<Function>());
    });
    test('Can instantiate Pie', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Pie = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 left, Int32 top, Int32 right,
              Int32 bottom, Int32 xr1, Int32 yr1, Int32 xr2, Int32 yr2),
          int Function(int hdc, int left, int top, int right, int bottom,
              int xr1, int yr1, int xr2, int yr2)>('Pie');
      expect(Pie, isA<Function>());
    });
    test('Can instantiate PolyBezier', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolyBezier = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> apt, Uint32 cpt),
          int Function(int hdc, Pointer<POINT> apt, int cpt)>('PolyBezier');
      expect(PolyBezier, isA<Function>());
    });
    test('Can instantiate PolyBezierTo', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolyBezierTo = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> apt, Uint32 cpt),
          int Function(int hdc, Pointer<POINT> apt, int cpt)>('PolyBezierTo');
      expect(PolyBezierTo, isA<Function>());
    });
    test('Can instantiate PolyDraw', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolyDraw = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Pointer<POINT> apt, Pointer<Uint8> aj, Int32 cpt),
          int Function(int hdc, Pointer<POINT> apt, Pointer<Uint8> aj,
              int cpt)>('PolyDraw');
      expect(PolyDraw, isA<Function>());
    });
    test('Can instantiate Polygon', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Polygon = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> apt, Int32 cpt),
          int Function(int hdc, Pointer<POINT> apt, int cpt)>('Polygon');
      expect(Polygon, isA<Function>());
    });
    test('Can instantiate Polyline', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Polyline = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> apt, Int32 cpt),
          int Function(int hdc, Pointer<POINT> apt, int cpt)>('Polyline');
      expect(Polyline, isA<Function>());
    });
    test('Can instantiate PolylineTo', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolylineTo = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<POINT> apt, Uint32 cpt),
          int Function(int hdc, Pointer<POINT> apt, int cpt)>('PolylineTo');
      expect(PolylineTo, isA<Function>());
    });
    test('Can instantiate PolyPolygon', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolyPolygon = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Pointer<POINT> apt, Pointer<Int32> asz, Int32 csz),
          int Function(int hdc, Pointer<POINT> apt, Pointer<Int32> asz,
              int csz)>('PolyPolygon');
      expect(PolyPolygon, isA<Function>());
    });
    test('Can instantiate PolyPolyline', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PolyPolyline = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Pointer<POINT> apt, Pointer<Uint32> asz, Uint32 csz),
          int Function(int hdc, Pointer<POINT> apt, Pointer<Uint32> asz,
              int csz)>('PolyPolyline');
      expect(PolyPolyline, isA<Function>());
    });
    test('Can instantiate PtInRegion', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final PtInRegion = gdi32.lookupFunction<
          Int32 Function(IntPtr hrgn, Int32 x, Int32 y),
          int Function(int hrgn, int x, int y)>('PtInRegion');
      expect(PtInRegion, isA<Function>());
    });
    test('Can instantiate Rectangle', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final Rectangle = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Int32 left, Int32 top, Int32 right, Int32 bottom),
          int Function(
              int hdc, int left, int top, int right, int bottom)>('Rectangle');
      expect(Rectangle, isA<Function>());
    });
    test('Can instantiate RectInRegion', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final RectInRegion = gdi32.lookupFunction<
          Int32 Function(IntPtr hrgn, Pointer<RECT> lprect),
          int Function(int hrgn, Pointer<RECT> lprect)>('RectInRegion');
      expect(RectInRegion, isA<Function>());
    });
    test('Can instantiate RoundRect', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final RoundRect = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 left, Int32 top, Int32 right,
              Int32 bottom, Int32 width, Int32 height),
          int Function(int hdc, int left, int top, int right, int bottom,
              int width, int height)>('RoundRect');
      expect(RoundRect, isA<Function>());
    });
    test('Can instantiate SaveDC', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SaveDC = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('SaveDC');
      expect(SaveDC, isA<Function>());
    });
    test('Can instantiate SelectClipPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SelectClipPath = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 mode),
          int Function(int hdc, int mode)>('SelectClipPath');
      expect(SelectClipPath, isA<Function>());
    });
    test('Can instantiate SelectObject', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SelectObject = gdi32.lookupFunction<
          IntPtr Function(IntPtr hdc, IntPtr h),
          int Function(int hdc, int h)>('SelectObject');
      expect(SelectObject, isA<Function>());
    });
    test('Can instantiate SetBkColor', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetBkColor = gdi32.lookupFunction<
          Uint32 Function(IntPtr hdc, Uint32 color),
          int Function(int hdc, int color)>('SetBkColor');
      expect(SetBkColor, isA<Function>());
    });
    test('Can instantiate SetBkMode', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetBkMode = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Uint32 mode),
          int Function(int hdc, int mode)>('SetBkMode');
      expect(SetBkMode, isA<Function>());
    });
    test('Can instantiate SetMapMode', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetMapMode = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Uint32 iMode),
          int Function(int hdc, int iMode)>('SetMapMode');
      expect(SetMapMode, isA<Function>());
    });
    test('Can instantiate SetPixel', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetPixel = gdi32.lookupFunction<
          Uint32 Function(IntPtr hdc, Int32 x, Int32 y, Uint32 color),
          int Function(int hdc, int x, int y, int color)>('SetPixel');
      expect(SetPixel, isA<Function>());
    });
    test('Can instantiate SetStretchBltMode', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetStretchBltMode = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Uint32 mode),
          int Function(int hdc, int mode)>('SetStretchBltMode');
      expect(SetStretchBltMode, isA<Function>());
    });
    test('Can instantiate SetTextColor', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetTextColor = gdi32.lookupFunction<
          Uint32 Function(IntPtr hdc, Uint32 color),
          int Function(int hdc, int color)>('SetTextColor');
      expect(SetTextColor, isA<Function>());
    });
    test('Can instantiate SetViewportExtEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetViewportExtEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Pointer<SIZE> lpsz),
          int Function(
              int hdc, int x, int y, Pointer<SIZE> lpsz)>('SetViewportExtEx');
      expect(SetViewportExtEx, isA<Function>());
    });
    test('Can instantiate SetViewportOrgEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetViewportOrgEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Pointer<POINT> lppt),
          int Function(
              int hdc, int x, int y, Pointer<POINT> lppt)>('SetViewportOrgEx');
      expect(SetViewportOrgEx, isA<Function>());
    });
    test('Can instantiate SetWindowExtEx', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final SetWindowExtEx = gdi32.lookupFunction<
          Int32 Function(IntPtr hdc, Int32 x, Int32 y, Pointer<SIZE> lpsz),
          int Function(
              int hdc, int x, int y, Pointer<SIZE> lpsz)>('SetWindowExtEx');
      expect(SetWindowExtEx, isA<Function>());
    });
    test('Can instantiate StretchBlt', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final StretchBlt = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdcDest,
              Int32 xDest,
              Int32 yDest,
              Int32 wDest,
              Int32 hDest,
              IntPtr hdcSrc,
              Int32 xSrc,
              Int32 ySrc,
              Int32 wSrc,
              Int32 hSrc,
              Uint32 rop),
          int Function(
              int hdcDest,
              int xDest,
              int yDest,
              int wDest,
              int hDest,
              int hdcSrc,
              int xSrc,
              int ySrc,
              int wSrc,
              int hSrc,
              int rop)>('StretchBlt');
      expect(StretchBlt, isA<Function>());
    });
    test('Can instantiate StretchDIBits', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final StretchDIBits = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc,
              Int32 xDest,
              Int32 yDest,
              Int32 DestWidth,
              Int32 DestHeight,
              Int32 xSrc,
              Int32 ySrc,
              Int32 SrcWidth,
              Int32 SrcHeight,
              Pointer lpBits,
              Pointer<BITMAPINFO> lpbmi,
              Uint32 iUsage,
              Uint32 rop),
          int Function(
              int hdc,
              int xDest,
              int yDest,
              int DestWidth,
              int DestHeight,
              int xSrc,
              int ySrc,
              int SrcWidth,
              int SrcHeight,
              Pointer lpBits,
              Pointer<BITMAPINFO> lpbmi,
              int iUsage,
              int rop)>('StretchDIBits');
      expect(StretchDIBits, isA<Function>());
    });
    test('Can instantiate StrokeAndFillPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final StrokeAndFillPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('StrokeAndFillPath');
      expect(StrokeAndFillPath, isA<Function>());
    });
    test('Can instantiate StrokePath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final StrokePath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('StrokePath');
      expect(StrokePath, isA<Function>());
    });
    test('Can instantiate TextOut', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final TextOut = gdi32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Int32 x, Int32 y, Pointer<Utf16> lpString, Int32 c),
          int Function(int hdc, int x, int y, Pointer<Utf16> lpString,
              int c)>('TextOutW');
      expect(TextOut, isA<Function>());
    });
    test('Can instantiate WidenPath', () {
      final gdi32 = DynamicLibrary.open('gdi32.dll');
      final WidenPath = gdi32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('WidenPath');
      expect(WidenPath, isA<Function>());
    });
  });

  group('Test winspool functions', () {
    test('Can instantiate AbortPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AbortPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('AbortPrinter');
      expect(AbortPrinter, isA<Function>());
    });
    test('Can instantiate AddForm', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AddForm = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 Level, Pointer<Uint8> pForm),
          int Function(
              int hPrinter, int Level, Pointer<Uint8> pForm)>('AddFormW');
      expect(AddForm, isA<Function>());
    });
    test('Can instantiate AddJob', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AddJob = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 Level, Pointer<Uint8> pData,
              Uint32 cbBuf, Pointer<Uint32> pcbNeeded),
          int Function(int hPrinter, int Level, Pointer<Uint8> pData, int cbBuf,
              Pointer<Uint32> pcbNeeded)>('AddJobW');
      expect(AddJob, isA<Function>());
    });
    test('Can instantiate AddPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AddPrinter = winspool.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> pName, Uint32 Level, Pointer<Uint8> pPrinter),
          int Function(Pointer<Utf16> pName, int Level,
              Pointer<Uint8> pPrinter)>('AddPrinterW');
      expect(AddPrinter, isA<Function>());
    });
    test('Can instantiate AddPrinterConnection', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AddPrinterConnection = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pName),
          int Function(Pointer<Utf16> pName)>('AddPrinterConnectionW');
      expect(AddPrinterConnection, isA<Function>());
    });
    test('Can instantiate AddPrinterConnection2', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AddPrinterConnection2 = winspool.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> pszName, Uint32 dwLevel,
              Pointer pConnectionInfo),
          int Function(int hWnd, Pointer<Utf16> pszName, int dwLevel,
              Pointer pConnectionInfo)>('AddPrinterConnection2W');
      expect(AddPrinterConnection2, isA<Function>());
    });
    test('Can instantiate AdvancedDocumentProperties', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final AdvancedDocumentProperties = winspool.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              IntPtr hPrinter,
              Pointer<Utf16> pDeviceName,
              Pointer<DEVMODE> pDevModeOutput,
              Pointer<DEVMODE> pDevModeInput),
          int Function(
              int hWnd,
              int hPrinter,
              Pointer<Utf16> pDeviceName,
              Pointer<DEVMODE> pDevModeOutput,
              Pointer<DEVMODE> pDevModeInput)>('AdvancedDocumentPropertiesW');
      expect(AdvancedDocumentProperties, isA<Function>());
    });
    test('Can instantiate ClosePrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ClosePrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('ClosePrinter');
      expect(ClosePrinter, isA<Function>());
    });
    test('Can instantiate CloseSpoolFileHandle', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final CloseSpoolFileHandle = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, IntPtr hSpoolFile),
          int Function(int hPrinter, int hSpoolFile)>('CloseSpoolFileHandle');
      expect(CloseSpoolFileHandle, isA<Function>());
    });
    test('Can instantiate CommitSpoolData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final CommitSpoolData = winspool.lookupFunction<
          IntPtr Function(IntPtr hPrinter, IntPtr hSpoolFile, Uint32 cbCommit),
          int Function(
              int hPrinter, int hSpoolFile, int cbCommit)>('CommitSpoolData');
      expect(CommitSpoolData, isA<Function>());
    });
    test('Can instantiate ConfigurePort', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ConfigurePort = winspool.lookupFunction<
          Int32 Function(
              Pointer<Utf16> pName, IntPtr hWnd, Pointer<Utf16> pPortName),
          int Function(Pointer<Utf16> pName, int hWnd,
              Pointer<Utf16> pPortName)>('ConfigurePortW');
      expect(ConfigurePort, isA<Function>());
    });
    test('Can instantiate ConnectToPrinterDlg', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ConnectToPrinterDlg = winspool.lookupFunction<
          IntPtr Function(IntPtr hwnd, Uint32 Flags),
          int Function(int hwnd, int Flags)>('ConnectToPrinterDlg');
      expect(ConnectToPrinterDlg, isA<Function>());
    });
    test('Can instantiate DeleteForm', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeleteForm = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer<Utf16> pFormName),
          int Function(int hPrinter, Pointer<Utf16> pFormName)>('DeleteFormW');
      expect(DeleteForm, isA<Function>());
    });
    test('Can instantiate DeletePrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeletePrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('DeletePrinter');
      expect(DeletePrinter, isA<Function>());
    });
    test('Can instantiate DeletePrinterConnection', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeletePrinterConnection = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pName),
          int Function(Pointer<Utf16> pName)>('DeletePrinterConnectionW');
      expect(DeletePrinterConnection, isA<Function>());
    });
    test('Can instantiate DeletePrinterData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeletePrinterData = winspool.lookupFunction<
          Uint32 Function(IntPtr hPrinter, Pointer<Utf16> pValueName),
          int Function(
              int hPrinter, Pointer<Utf16> pValueName)>('DeletePrinterDataW');
      expect(DeletePrinterData, isA<Function>());
    });
    test('Can instantiate DeletePrinterDataEx', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeletePrinterDataEx = winspool.lookupFunction<
          Uint32 Function(IntPtr hPrinter, Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName),
          int Function(int hPrinter, Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName)>('DeletePrinterDataExW');
      expect(DeletePrinterDataEx, isA<Function>());
    });
    test('Can instantiate DeletePrinterKey', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DeletePrinterKey = winspool.lookupFunction<
          Uint32 Function(IntPtr hPrinter, Pointer<Utf16> pKeyName),
          int Function(
              int hPrinter, Pointer<Utf16> pKeyName)>('DeletePrinterKeyW');
      expect(DeletePrinterKey, isA<Function>());
    });
    test('Can instantiate DocumentProperties', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final DocumentProperties = winspool.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              IntPtr hPrinter,
              Pointer<Utf16> pDeviceName,
              Pointer<DEVMODE> pDevModeOutput,
              Pointer<DEVMODE> pDevModeInput,
              Uint32 fMode),
          int Function(
              int hWnd,
              int hPrinter,
              Pointer<Utf16> pDeviceName,
              Pointer<DEVMODE> pDevModeOutput,
              Pointer<DEVMODE> pDevModeInput,
              int fMode)>('DocumentPropertiesW');
      expect(DocumentProperties, isA<Function>());
    });
    test('Can instantiate EndDocPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EndDocPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('EndDocPrinter');
      expect(EndDocPrinter, isA<Function>());
    });
    test('Can instantiate EndPagePrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EndPagePrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('EndPagePrinter');
      expect(EndPagePrinter, isA<Function>());
    });
    test('Can instantiate EnumForms', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumForms = winspool.lookupFunction<
          Int32 Function(
              IntPtr hPrinter,
              Uint32 Level,
              Pointer<Uint8> pForm,
              Uint32 cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned),
          int Function(
              int hPrinter,
              int Level,
              Pointer<Uint8> pForm,
              int cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned)>('EnumFormsW');
      expect(EnumForms, isA<Function>());
    });
    test('Can instantiate EnumJobs', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumJobs = winspool.lookupFunction<
          Int32 Function(
              IntPtr hPrinter,
              Uint32 FirstJob,
              Uint32 NoJobs,
              Uint32 Level,
              Pointer<Uint8> pJob,
              Uint32 cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned),
          int Function(
              int hPrinter,
              int FirstJob,
              int NoJobs,
              int Level,
              Pointer<Uint8> pJob,
              int cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned)>('EnumJobsW');
      expect(EnumJobs, isA<Function>());
    });
    test('Can instantiate EnumPrinterData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumPrinterData = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Uint32 dwIndex,
              Pointer<Utf16> pValueName,
              Uint32 cbValueName,
              Pointer<Uint32> pcbValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              Uint32 cbData,
              Pointer<Uint32> pcbData),
          int Function(
              int hPrinter,
              int dwIndex,
              Pointer<Utf16> pValueName,
              int cbValueName,
              Pointer<Uint32> pcbValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              int cbData,
              Pointer<Uint32> pcbData)>('EnumPrinterDataW');
      expect(EnumPrinterData, isA<Function>());
    });
    test('Can instantiate EnumPrinterDataEx', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumPrinterDataEx = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Uint8> pEnumValues,
              Uint32 cbEnumValues,
              Pointer<Uint32> pcbEnumValues,
              Pointer<Uint32> pnEnumValues),
          int Function(
              int hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Uint8> pEnumValues,
              int cbEnumValues,
              Pointer<Uint32> pcbEnumValues,
              Pointer<Uint32> pnEnumValues)>('EnumPrinterDataExW');
      expect(EnumPrinterDataEx, isA<Function>());
    });
    test('Can instantiate EnumPrinterKey', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumPrinterKey = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pSubkey,
              Uint32 cbSubkey,
              Pointer<Uint32> pcbSubkey),
          int Function(
              int hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pSubkey,
              int cbSubkey,
              Pointer<Uint32> pcbSubkey)>('EnumPrinterKeyW');
      expect(EnumPrinterKey, isA<Function>());
    });
    test('Can instantiate EnumPrinters', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final EnumPrinters = winspool.lookupFunction<
          Int32 Function(
              Uint32 Flags,
              Pointer<Utf16> Name,
              Uint32 Level,
              Pointer<Uint8> pPrinterEnum,
              Uint32 cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned),
          int Function(
              int Flags,
              Pointer<Utf16> Name,
              int Level,
              Pointer<Uint8> pPrinterEnum,
              int cbBuf,
              Pointer<Uint32> pcbNeeded,
              Pointer<Uint32> pcReturned)>('EnumPrintersW');
      expect(EnumPrinters, isA<Function>());
    });
    test('Can instantiate FindClosePrinterChangeNotification', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final FindClosePrinterChangeNotification = winspool.lookupFunction<
          Int32 Function(IntPtr hChange),
          int Function(int hChange)>('FindClosePrinterChangeNotification');
      expect(FindClosePrinterChangeNotification, isA<Function>());
    });
    test('Can instantiate FindFirstPrinterChangeNotification', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final FindFirstPrinterChangeNotification = winspool.lookupFunction<
          IntPtr Function(IntPtr hPrinter, Uint32 fdwFilter, Uint32 fdwOptions,
              Pointer pPrinterNotifyOptions),
          int Function(
              int hPrinter,
              int fdwFilter,
              int fdwOptions,
              Pointer
                  pPrinterNotifyOptions)>('FindFirstPrinterChangeNotification');
      expect(FindFirstPrinterChangeNotification, isA<Function>());
    });
    test('Can instantiate FindNextPrinterChangeNotification', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final FindNextPrinterChangeNotification = winspool.lookupFunction<
              Int32 Function(IntPtr hChange, Pointer<Uint32> pdwChange,
                  Pointer pvReserved, Pointer<Pointer> ppPrinterNotifyInfo),
              int Function(int hChange, Pointer<Uint32> pdwChange,
                  Pointer pvReserved, Pointer<Pointer> ppPrinterNotifyInfo)>(
          'FindNextPrinterChangeNotification');
      expect(FindNextPrinterChangeNotification, isA<Function>());
    });
    test('Can instantiate FlushPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final FlushPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer pBuf, Uint32 cbBuf,
              Pointer<Uint32> pcWritten, Uint32 cSleep),
          int Function(int hPrinter, Pointer pBuf, int cbBuf,
              Pointer<Uint32> pcWritten, int cSleep)>('FlushPrinter');
      expect(FlushPrinter, isA<Function>());
    });
    test('Can instantiate FreePrinterNotifyInfo', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final FreePrinterNotifyInfo = winspool.lookupFunction<
              Int32 Function(Pointer<PRINTER_NOTIFY_INFO> pPrinterNotifyInfo),
              int Function(Pointer<PRINTER_NOTIFY_INFO> pPrinterNotifyInfo)>(
          'FreePrinterNotifyInfo');
      expect(FreePrinterNotifyInfo, isA<Function>());
    });
    test('Can instantiate GetDefaultPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetDefaultPrinter = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pszBuffer, Pointer<Uint32> pcchBuffer),
          int Function(Pointer<Utf16> pszBuffer,
              Pointer<Uint32> pcchBuffer)>('GetDefaultPrinterW');
      expect(GetDefaultPrinter, isA<Function>());
    });
    test('Can instantiate GetForm', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetForm = winspool.lookupFunction<
          Int32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pFormName,
              Uint32 Level,
              Pointer<Uint8> pForm,
              Uint32 cbBuf,
              Pointer<Uint32> pcbNeeded),
          int Function(
              int hPrinter,
              Pointer<Utf16> pFormName,
              int Level,
              Pointer<Uint8> pForm,
              int cbBuf,
              Pointer<Uint32> pcbNeeded)>('GetFormW');
      expect(GetForm, isA<Function>());
    });
    test('Can instantiate GetJob', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetJob = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 JobId, Uint32 Level,
              Pointer<Uint8> pJob, Uint32 cbBuf, Pointer<Uint32> pcbNeeded),
          int Function(int hPrinter, int JobId, int Level, Pointer<Uint8> pJob,
              int cbBuf, Pointer<Uint32> pcbNeeded)>('GetJobW');
      expect(GetJob, isA<Function>());
    });
    test('Can instantiate GetPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 Level, Pointer<Uint8> pPrinter,
              Uint32 cbBuf, Pointer<Uint32> pcbNeeded),
          int Function(int hPrinter, int Level, Pointer<Uint8> pPrinter,
              int cbBuf, Pointer<Uint32> pcbNeeded)>('GetPrinterW');
      expect(GetPrinter, isA<Function>());
    });
    test('Can instantiate GetPrinterData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetPrinterData = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              Uint32 nSize,
              Pointer<Uint32> pcbNeeded),
          int Function(
              int hPrinter,
              Pointer<Utf16> pValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              int nSize,
              Pointer<Uint32> pcbNeeded)>('GetPrinterDataW');
      expect(GetPrinterData, isA<Function>());
    });
    test('Can instantiate GetPrinterDataEx', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetPrinterDataEx = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              Uint32 nSize,
              Pointer<Uint32> pcbNeeded),
          int Function(
              int hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName,
              Pointer<Uint32> pType,
              Pointer<Uint8> pData,
              int nSize,
              Pointer<Uint32> pcbNeeded)>('GetPrinterDataExW');
      expect(GetPrinterDataEx, isA<Function>());
    });
    test('Can instantiate GetPrintExecutionData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetPrintExecutionData = winspool.lookupFunction<
          Int32 Function(Pointer<PRINT_EXECUTION_DATA> pData),
          int Function(
              Pointer<PRINT_EXECUTION_DATA> pData)>('GetPrintExecutionData');
      expect(GetPrintExecutionData, isA<Function>());
    });
    test('Can instantiate GetSpoolFileHandle', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final GetSpoolFileHandle = winspool.lookupFunction<
          IntPtr Function(IntPtr hPrinter),
          int Function(int hPrinter)>('GetSpoolFileHandle');
      expect(GetSpoolFileHandle, isA<Function>());
    });
    test('Can instantiate IsValidDevmode', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final IsValidDevmode = winspool.lookupFunction<
          Int32 Function(Pointer<DEVMODE> pDevmode, IntPtr DevmodeSize),
          int Function(
              Pointer<DEVMODE> pDevmode, int DevmodeSize)>('IsValidDevmodeW');
      expect(IsValidDevmode, isA<Function>());
    });
    test('Can instantiate OpenPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final OpenPrinter = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pPrinterName, Pointer<IntPtr> phPrinter,
              Pointer<PRINTER_DEFAULTS> pDefault),
          int Function(Pointer<Utf16> pPrinterName, Pointer<IntPtr> phPrinter,
              Pointer<PRINTER_DEFAULTS> pDefault)>('OpenPrinterW');
      expect(OpenPrinter, isA<Function>());
    });
    test('Can instantiate OpenPrinter2', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final OpenPrinter2 = winspool.lookupFunction<
          Int32 Function(
              Pointer<Utf16> pPrinterName,
              Pointer<IntPtr> phPrinter,
              Pointer<PRINTER_DEFAULTS> pDefault,
              Pointer<PRINTER_OPTIONS> pOptions),
          int Function(
              Pointer<Utf16> pPrinterName,
              Pointer<IntPtr> phPrinter,
              Pointer<PRINTER_DEFAULTS> pDefault,
              Pointer<PRINTER_OPTIONS> pOptions)>('OpenPrinter2W');
      expect(OpenPrinter2, isA<Function>());
    });
    test('Can instantiate PrinterProperties', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final PrinterProperties = winspool.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hPrinter),
          int Function(int hWnd, int hPrinter)>('PrinterProperties');
      expect(PrinterProperties, isA<Function>());
    });
    test('Can instantiate ReadPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ReadPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer pBuf, Uint32 cbBuf,
              Pointer<Uint32> pNoBytesRead),
          int Function(int hPrinter, Pointer pBuf, int cbBuf,
              Pointer<Uint32> pNoBytesRead)>('ReadPrinter');
      expect(ReadPrinter, isA<Function>());
    });
    test('Can instantiate ReportJobProcessingProgress', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ReportJobProcessingProgress = winspool.lookupFunction<
          Int32 Function(IntPtr printerHandle, Uint32 jobId, Int32 jobOperation,
              Int32 jobProgress),
          int Function(int printerHandle, int jobId, int jobOperation,
              int jobProgress)>('ReportJobProcessingProgress');
      expect(ReportJobProcessingProgress, isA<Function>());
    });
    test('Can instantiate ResetPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ResetPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer<PRINTER_DEFAULTS> pDefault),
          int Function(int hPrinter,
              Pointer<PRINTER_DEFAULTS> pDefault)>('ResetPrinterW');
      expect(ResetPrinter, isA<Function>());
    });
    test('Can instantiate ScheduleJob', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final ScheduleJob = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 JobId),
          int Function(int hPrinter, int JobId)>('ScheduleJob');
      expect(ScheduleJob, isA<Function>());
    });
    test('Can instantiate SetDefaultPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetDefaultPrinter = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pszPrinter),
          int Function(Pointer<Utf16> pszPrinter)>('SetDefaultPrinterW');
      expect(SetDefaultPrinter, isA<Function>());
    });
    test('Can instantiate SetForm', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetForm = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer<Utf16> pFormName,
              Uint32 Level, Pointer<Uint8> pForm),
          int Function(int hPrinter, Pointer<Utf16> pFormName, int Level,
              Pointer<Uint8> pForm)>('SetFormW');
      expect(SetForm, isA<Function>());
    });
    test('Can instantiate SetJob', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetJob = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 JobId, Uint32 Level,
              Pointer<Uint8> pJob, Uint32 Command),
          int Function(int hPrinter, int JobId, int Level, Pointer<Uint8> pJob,
              int Command)>('SetJobW');
      expect(SetJob, isA<Function>());
    });
    test('Can instantiate SetPort', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetPort = winspool.lookupFunction<
          Int32 Function(Pointer<Utf16> pName, Pointer<Utf16> pPortName,
              Uint32 dwLevel, Pointer<Uint8> pPortInfo),
          int Function(Pointer<Utf16> pName, Pointer<Utf16> pPortName,
              int dwLevel, Pointer<Uint8> pPortInfo)>('SetPortW');
      expect(SetPort, isA<Function>());
    });
    test('Can instantiate SetPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetPrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Uint32 Level, Pointer<Uint8> pPrinter,
              Uint32 Command),
          int Function(int hPrinter, int Level, Pointer<Uint8> pPrinter,
              int Command)>('SetPrinterW');
      expect(SetPrinter, isA<Function>());
    });
    test('Can instantiate SetPrinterData', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetPrinterData = winspool.lookupFunction<
          Uint32 Function(IntPtr hPrinter, Pointer<Utf16> pValueName,
              Uint32 Type, Pointer<Uint8> pData, Uint32 cbData),
          int Function(int hPrinter, Pointer<Utf16> pValueName, int Type,
              Pointer<Uint8> pData, int cbData)>('SetPrinterDataW');
      expect(SetPrinterData, isA<Function>());
    });
    test('Can instantiate SetPrinterDataEx', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final SetPrinterDataEx = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName,
              Uint32 Type,
              Pointer<Uint8> pData,
              Uint32 cbData),
          int Function(
              int hPrinter,
              Pointer<Utf16> pKeyName,
              Pointer<Utf16> pValueName,
              int Type,
              Pointer<Uint8> pData,
              int cbData)>('SetPrinterDataExW');
      expect(SetPrinterDataEx, isA<Function>());
    });
    test('Can instantiate StartDocPrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final StartDocPrinter = winspool.lookupFunction<
          Uint32 Function(
              IntPtr hPrinter, Uint32 Level, Pointer<DOC_INFO_1> pDocInfo),
          int Function(int hPrinter, int Level,
              Pointer<DOC_INFO_1> pDocInfo)>('StartDocPrinterW');
      expect(StartDocPrinter, isA<Function>());
    });
    test('Can instantiate StartPagePrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final StartPagePrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter),
          int Function(int hPrinter)>('StartPagePrinter');
      expect(StartPagePrinter, isA<Function>());
    });
    test('Can instantiate WritePrinter', () {
      final winspool = DynamicLibrary.open('winspool.drv');
      final WritePrinter = winspool.lookupFunction<
          Int32 Function(IntPtr hPrinter, Pointer pBuf, Uint32 cbBuf,
              Pointer<Uint32> pcWritten),
          int Function(int hPrinter, Pointer pBuf, int cbBuf,
              Pointer<Uint32> pcWritten)>('WritePrinter');
      expect(WritePrinter, isA<Function>());
    });
  });

  group('Test ws2_32 functions', () {
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate accept', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final accept = ws2_32.lookupFunction<
            IntPtr Function(
                IntPtr s, Pointer<SOCKADDR> addr, Pointer<Int32> addrlen),
            int Function(int s, Pointer<SOCKADDR> addr,
                Pointer<Int32> addrlen)>('accept');
        expect(accept, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate bind', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final bind = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Int32 namelen),
            int Function(int s, Pointer<SOCKADDR> name, int namelen)>('bind');
        expect(bind, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate closesocket', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final closesocket = ws2_32.lookupFunction<Int32 Function(IntPtr s),
            int Function(int s)>('closesocket');
        expect(closesocket, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate connect', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final connect = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Int32 namelen),
            int Function(
                int s, Pointer<SOCKADDR> name, int namelen)>('connect');
        expect(connect, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate GetAddrInfo', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final GetAddrInfo = ws2_32.lookupFunction<
            Int32 Function(
                Pointer<Utf16> pNodeName,
                Pointer<Utf16> pServiceName,
                Pointer<ADDRINFO> pHints,
                Pointer<Pointer<ADDRINFO>> ppResult),
            int Function(
                Pointer<Utf16> pNodeName,
                Pointer<Utf16> pServiceName,
                Pointer<ADDRINFO> pHints,
                Pointer<Pointer<ADDRINFO>> ppResult)>('GetAddrInfoW');
        expect(GetAddrInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate gethostbyaddr', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final gethostbyaddr = ws2_32.lookupFunction<
            Pointer<HOSTENT> Function(
                Pointer<Utf8> addr, Int32 len, Int32 type),
            Pointer<HOSTENT> Function(
                Pointer<Utf8> addr, int len, int type)>('gethostbyaddr');
        expect(gethostbyaddr, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate gethostbyname', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final gethostbyname = ws2_32.lookupFunction<
            Pointer<HOSTENT> Function(Pointer<Utf8> name),
            Pointer<HOSTENT> Function(Pointer<Utf8> name)>('gethostbyname');
        expect(gethostbyname, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate gethostname', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final gethostname = ws2_32.lookupFunction<
            Int32 Function(Pointer<Utf8> name, Int32 namelen),
            int Function(Pointer<Utf8> name, int namelen)>('gethostname');
        expect(gethostname, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getnameinfo', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getnameinfo = ws2_32.lookupFunction<
            Int32 Function(
                Pointer<SOCKADDR> pSockaddr,
                Int32 SockaddrLength,
                Pointer<Utf8> pNodeBuffer,
                Uint32 NodeBufferSize,
                Pointer<Utf8> pServiceBuffer,
                Uint32 ServiceBufferSize,
                Int32 Flags),
            int Function(
                Pointer<SOCKADDR> pSockaddr,
                int SockaddrLength,
                Pointer<Utf8> pNodeBuffer,
                int NodeBufferSize,
                Pointer<Utf8> pServiceBuffer,
                int ServiceBufferSize,
                int Flags)>('getnameinfo');
        expect(getnameinfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getpeername', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getpeername = ws2_32.lookupFunction<
            Int32 Function(
                IntPtr s, Pointer<SOCKADDR> name, Pointer<Int32> namelen),
            int Function(int s, Pointer<SOCKADDR> name,
                Pointer<Int32> namelen)>('getpeername');
        expect(getpeername, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getprotobyname', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getprotobyname = ws2_32.lookupFunction<
            Pointer<PROTOENT> Function(Pointer<Utf8> name),
            Pointer<PROTOENT> Function(Pointer<Utf8> name)>('getprotobyname');
        expect(getprotobyname, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getprotobynumber', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getprotobynumber = ws2_32.lookupFunction<
            Pointer<PROTOENT> Function(Int32 number),
            Pointer<PROTOENT> Function(int number)>('getprotobynumber');
        expect(getprotobynumber, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getservbyname', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getservbyname = ws2_32.lookupFunction<
            Pointer<SERVENT> Function(Pointer<Utf8> name, Pointer<Utf8> proto),
            Pointer<SERVENT> Function(
                Pointer<Utf8> name, Pointer<Utf8> proto)>('getservbyname');
        expect(getservbyname, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getservbyport', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getservbyport = ws2_32.lookupFunction<
            Pointer<SERVENT> Function(Int32 port, Pointer<Utf8> proto),
            Pointer<SERVENT> Function(
                int port, Pointer<Utf8> proto)>('getservbyport');
        expect(getservbyport, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getsockname', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getsockname = ws2_32.lookupFunction<
            Int32 Function(
                IntPtr s, Pointer<SOCKADDR> name, Pointer<Int32> namelen),
            int Function(int s, Pointer<SOCKADDR> name,
                Pointer<Int32> namelen)>('getsockname');
        expect(getsockname, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate getsockopt', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final getsockopt = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Int32 level, Int32 optname,
                Pointer<Utf8> optval, Pointer<Int32> optlen),
            int Function(int s, int level, int optname, Pointer<Utf8> optval,
                Pointer<Int32> optlen)>('getsockopt');
        expect(getsockopt, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate htonl', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final htonl = ws2_32.lookupFunction<Uint32 Function(Uint32 hostlong),
            int Function(int hostlong)>('htonl');
        expect(htonl, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate htons', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final htons = ws2_32.lookupFunction<Uint16 Function(Uint16 hostshort),
            int Function(int hostshort)>('htons');
        expect(htons, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate inet_addr', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final inet_addr = ws2_32.lookupFunction<
            Uint32 Function(Pointer<Utf8> cp),
            int Function(Pointer<Utf8> cp)>('inet_addr');
        expect(inet_addr, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate inet_ntoa', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final inet_ntoa = ws2_32.lookupFunction<
            Pointer<Utf8> Function(IN_ADDR in_),
            Pointer<Utf8> Function(IN_ADDR in_)>('inet_ntoa');
        expect(inet_ntoa, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate ioctlsocket', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final ioctlsocket = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Int32 cmd, Pointer<Uint32> argp),
            int Function(int s, int cmd, Pointer<Uint32> argp)>('ioctlsocket');
        expect(ioctlsocket, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate listen', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final listen = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Int32 backlog),
            int Function(int s, int backlog)>('listen');
        expect(listen, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate ntohl', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final ntohl = ws2_32.lookupFunction<Uint32 Function(Uint32 netlong),
            int Function(int netlong)>('ntohl');
        expect(ntohl, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate ntohs', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final ntohs = ws2_32.lookupFunction<Uint16 Function(Uint16 netshort),
            int Function(int netshort)>('ntohs');
        expect(ntohs, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate recv', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final recv = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags),
            int Function(int s, Pointer<Utf8> buf, int len, int flags)>('recv');
        expect(recv, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate recvfrom', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final recvfrom = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags,
                Pointer<SOCKADDR> from, Pointer<Int32> fromlen),
            int Function(int s, Pointer<Utf8> buf, int len, int flags,
                Pointer<SOCKADDR> from, Pointer<Int32> fromlen)>('recvfrom');
        expect(recvfrom, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate select', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final select = ws2_32.lookupFunction<
            Int32 Function(
                Int32 nfds,
                Pointer<FD_SET> readfds,
                Pointer<FD_SET> writefds,
                Pointer<FD_SET> exceptfds,
                Pointer<TIMEVAL> timeout),
            int Function(
                int nfds,
                Pointer<FD_SET> readfds,
                Pointer<FD_SET> writefds,
                Pointer<FD_SET> exceptfds,
                Pointer<TIMEVAL> timeout)>('select');
        expect(select, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate send', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final send = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags),
            int Function(int s, Pointer<Utf8> buf, int len, int flags)>('send');
        expect(send, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate sendto', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final sendto = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags,
                Pointer<SOCKADDR> to, Int32 tolen),
            int Function(int s, Pointer<Utf8> buf, int len, int flags,
                Pointer<SOCKADDR> to, int tolen)>('sendto');
        expect(sendto, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate shutdown', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final shutdown = ws2_32.lookupFunction<
            Int32 Function(IntPtr s, Int32 how),
            int Function(int s, int how)>('shutdown');
        expect(shutdown, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate socket', () {
        final ws2_32 = DynamicLibrary.open('ws2_32.dll');
        final socket = ws2_32.lookupFunction<
            IntPtr Function(Int32 af, Int32 type, Int32 protocol),
            int Function(int af, int type, int protocol)>('socket');
        expect(socket, isA<Function>());
      });
    }
  });

  group('Test kernel32 functions', () {
    test('Can instantiate ActivateActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ActivateActCtx = kernel32.lookupFunction<
          Int32 Function(IntPtr hActCtx, Pointer<IntPtr> lpCookie),
          int Function(
              int hActCtx, Pointer<IntPtr> lpCookie)>('ActivateActCtx');
      expect(ActivateActCtx, isA<Function>());
    });
    test('Can instantiate AddDllDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final AddDllDirectory = kernel32.lookupFunction<
          Pointer Function(Pointer<Utf16> NewDirectory),
          Pointer Function(Pointer<Utf16> NewDirectory)>('AddDllDirectory');
      expect(AddDllDirectory, isA<Function>());
    });
    test('Can instantiate AddRefActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final AddRefActCtx = kernel32.lookupFunction<
          Void Function(IntPtr hActCtx),
          void Function(int hActCtx)>('AddRefActCtx');
      expect(AddRefActCtx, isA<Function>());
    });
    test('Can instantiate AllocConsole', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final AllocConsole = kernel32
          .lookupFunction<Int32 Function(), int Function()>('AllocConsole');
      expect(AllocConsole, isA<Function>());
    });
    test('Can instantiate AreFileApisANSI', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final AreFileApisANSI = kernel32
          .lookupFunction<Int32 Function(), int Function()>('AreFileApisANSI');
      expect(AreFileApisANSI, isA<Function>());
    });
    test('Can instantiate AttachConsole', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final AttachConsole = kernel32.lookupFunction<
          Int32 Function(Uint32 dwProcessId),
          int Function(int dwProcessId)>('AttachConsole');
      expect(AttachConsole, isA<Function>());
    });
    test('Can instantiate Beep', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final Beep = kernel32.lookupFunction<
          Int32 Function(Uint32 dwFreq, Uint32 dwDuration),
          int Function(int dwFreq, int dwDuration)>('Beep');
      expect(Beep, isA<Function>());
    });
    test('Can instantiate BeginUpdateResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final BeginUpdateResource = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> pFileName, Int32 bDeleteExistingResources),
          int Function(Pointer<Utf16> pFileName,
              int bDeleteExistingResources)>('BeginUpdateResourceW');
      expect(BeginUpdateResource, isA<Function>());
    });
    test('Can instantiate BuildCommDCB', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final BuildCommDCB = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB),
          int Function(
              Pointer<Utf16> lpDef, Pointer<DCB> lpDCB)>('BuildCommDCBW');
      expect(BuildCommDCB, isA<Function>());
    });
    test('Can instantiate BuildCommDCBAndTimeouts', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final BuildCommDCBAndTimeouts = kernel32.lookupFunction<
              Int32 Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB,
                  Pointer<COMMTIMEOUTS> lpCommTimeouts),
              int Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB,
                  Pointer<COMMTIMEOUTS> lpCommTimeouts)>(
          'BuildCommDCBAndTimeoutsW');
      expect(BuildCommDCBAndTimeouts, isA<Function>());
    });
    test('Can instantiate CallNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CallNamedPipe = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpNamedPipeName,
              Pointer lpInBuffer,
              Uint32 nInBufferSize,
              Pointer lpOutBuffer,
              Uint32 nOutBufferSize,
              Pointer<Uint32> lpBytesRead,
              Uint32 nTimeOut),
          int Function(
              Pointer<Utf16> lpNamedPipeName,
              Pointer lpInBuffer,
              int nInBufferSize,
              Pointer lpOutBuffer,
              int nOutBufferSize,
              Pointer<Uint32> lpBytesRead,
              int nTimeOut)>('CallNamedPipeW');
      expect(CallNamedPipe, isA<Function>());
    });
    test('Can instantiate CancelIo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CancelIo = kernel32.lookupFunction<Int32 Function(IntPtr hFile),
          int Function(int hFile)>('CancelIo');
      expect(CancelIo, isA<Function>());
    });
    test('Can instantiate CancelIoEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CancelIoEx = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile, Pointer<OVERLAPPED> lpOverlapped)>('CancelIoEx');
      expect(CancelIoEx, isA<Function>());
    });
    test('Can instantiate CancelSynchronousIo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CancelSynchronousIo = kernel32.lookupFunction<
          Int32 Function(IntPtr hThread),
          int Function(int hThread)>('CancelSynchronousIo');
      expect(CancelSynchronousIo, isA<Function>());
    });
    test('Can instantiate CheckRemoteDebuggerPresent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CheckRemoteDebuggerPresent = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<Int32> pbDebuggerPresent),
          int Function(int hProcess,
              Pointer<Int32> pbDebuggerPresent)>('CheckRemoteDebuggerPresent');
      expect(CheckRemoteDebuggerPresent, isA<Function>());
    });
    test('Can instantiate ClearCommBreak', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ClearCommBreak = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile),
          int Function(int hFile)>('ClearCommBreak');
      expect(ClearCommBreak, isA<Function>());
    });
    test('Can instantiate ClearCommError', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ClearCommError = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile, Pointer<Uint32> lpErrors, Pointer<COMSTAT> lpStat),
          int Function(int hFile, Pointer<Uint32> lpErrors,
              Pointer<COMSTAT> lpStat)>('ClearCommError');
      expect(ClearCommError, isA<Function>());
    });
    test('Can instantiate CloseHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CloseHandle = kernel32.lookupFunction<
          Int32 Function(IntPtr hObject),
          int Function(int hObject)>('CloseHandle');
      expect(CloseHandle, isA<Function>());
    });
    if (windowsBuildNumber >= 17763) {
      test('Can instantiate ClosePseudoConsole', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final ClosePseudoConsole = kernel32.lookupFunction<
            Void Function(IntPtr hPC),
            void Function(int hPC)>('ClosePseudoConsole');
        expect(ClosePseudoConsole, isA<Function>());
      });
    }
    test('Can instantiate CommConfigDialog', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CommConfigDialog = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpszName, IntPtr hWnd, Pointer<COMMCONFIG> lpCC),
          int Function(Pointer<Utf16> lpszName, int hWnd,
              Pointer<COMMCONFIG> lpCC)>('CommConfigDialogW');
      expect(CommConfigDialog, isA<Function>());
    });
    test('Can instantiate ConnectNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ConnectNamedPipe = kernel32.lookupFunction<
          Int32 Function(IntPtr hNamedPipe, Pointer<OVERLAPPED> lpOverlapped),
          int Function(int hNamedPipe,
              Pointer<OVERLAPPED> lpOverlapped)>('ConnectNamedPipe');
      expect(ConnectNamedPipe, isA<Function>());
    });
    test('Can instantiate ContinueDebugEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ContinueDebugEvent = kernel32.lookupFunction<
          Int32 Function(
              Uint32 dwProcessId, Uint32 dwThreadId, Uint32 dwContinueStatus),
          int Function(int dwProcessId, int dwThreadId,
              int dwContinueStatus)>('ContinueDebugEvent');
      expect(ContinueDebugEvent, isA<Function>());
    });
    test('Can instantiate CreateActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateActCtx = kernel32.lookupFunction<
          IntPtr Function(Pointer<ACTCTX> pActCtx),
          int Function(Pointer<ACTCTX> pActCtx)>('CreateActCtxW');
      expect(CreateActCtx, isA<Function>());
    });
    test('Can instantiate CreateConsoleScreenBuffer', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateConsoleScreenBuffer = kernel32.lookupFunction<
          IntPtr Function(
              Uint32 dwDesiredAccess,
              Uint32 dwShareMode,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Uint32 dwFlags,
              Pointer lpScreenBufferData),
          int Function(
              int dwDesiredAccess,
              int dwShareMode,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              int dwFlags,
              Pointer lpScreenBufferData)>('CreateConsoleScreenBuffer');
      expect(CreateConsoleScreenBuffer, isA<Function>());
    });
    test('Can instantiate CreateDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateDirectory = kernel32.lookupFunction<
              Int32 Function(Pointer<Utf16> lpPathName,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
              int Function(Pointer<Utf16> lpPathName,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>(
          'CreateDirectoryW');
      expect(CreateDirectory, isA<Function>());
    });
    test('Can instantiate CreateEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateEvent = kernel32.lookupFunction<
          IntPtr Function(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
              Int32 bManualReset, Int32 bInitialState, Pointer<Utf16> lpName),
          int Function(
              Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
              int bManualReset,
              int bInitialState,
              Pointer<Utf16> lpName)>('CreateEventW');
      expect(CreateEvent, isA<Function>());
    });
    test('Can instantiate CreateEventEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateEventEx = kernel32.lookupFunction<
          IntPtr Function(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
              Pointer<Utf16> lpName, Uint32 dwFlags, Uint32 dwDesiredAccess),
          int Function(
              Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
              Pointer<Utf16> lpName,
              int dwFlags,
              int dwDesiredAccess)>('CreateEventExW');
      expect(CreateEventEx, isA<Function>());
    });
    test('Can instantiate CreateFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateFile = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpFileName,
              Uint32 dwDesiredAccess,
              Uint32 dwShareMode,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Uint32 dwCreationDisposition,
              Uint32 dwFlagsAndAttributes,
              IntPtr hTemplateFile),
          int Function(
              Pointer<Utf16> lpFileName,
              int dwDesiredAccess,
              int dwShareMode,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              int dwCreationDisposition,
              int dwFlagsAndAttributes,
              int hTemplateFile)>('CreateFileW');
      expect(CreateFile, isA<Function>());
    });
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate CreateFile2', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final CreateFile2 = kernel32.lookupFunction<
                IntPtr Function(
                    Pointer<Utf16> lpFileName,
                    Uint32 dwDesiredAccess,
                    Uint32 dwShareMode,
                    Uint32 dwCreationDisposition,
                    Pointer<CREATEFILE2_EXTENDED_PARAMETERS> pCreateExParams),
                int Function(
                    Pointer<Utf16> lpFileName,
                    int dwDesiredAccess,
                    int dwShareMode,
                    int dwCreationDisposition,
                    Pointer<CREATEFILE2_EXTENDED_PARAMETERS> pCreateExParams)>(
            'CreateFile2');
        expect(CreateFile2, isA<Function>());
      });
    }
    test('Can instantiate CreateIoCompletionPort', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateIoCompletionPort = kernel32.lookupFunction<
          IntPtr Function(IntPtr FileHandle, IntPtr ExistingCompletionPort,
              IntPtr CompletionKey, Uint32 NumberOfConcurrentThreads),
          int Function(
              int FileHandle,
              int ExistingCompletionPort,
              int CompletionKey,
              int NumberOfConcurrentThreads)>('CreateIoCompletionPort');
      expect(CreateIoCompletionPort, isA<Function>());
    });
    test('Can instantiate CreateNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateNamedPipe = kernel32.lookupFunction<
              IntPtr Function(
                  Pointer<Utf16> lpName,
                  Uint32 dwOpenMode,
                  Uint32 dwPipeMode,
                  Uint32 nMaxInstances,
                  Uint32 nOutBufferSize,
                  Uint32 nInBufferSize,
                  Uint32 nDefaultTimeOut,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
              int Function(
                  Pointer<Utf16> lpName,
                  int dwOpenMode,
                  int dwPipeMode,
                  int nMaxInstances,
                  int nOutBufferSize,
                  int nInBufferSize,
                  int nDefaultTimeOut,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>(
          'CreateNamedPipeW');
      expect(CreateNamedPipe, isA<Function>());
    });
    test('Can instantiate CreatePipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreatePipe = kernel32.lookupFunction<
          Int32 Function(Pointer<IntPtr> hReadPipe, Pointer<IntPtr> hWritePipe,
              Pointer<SECURITY_ATTRIBUTES> lpPipeAttributes, Uint32 nSize),
          int Function(
              Pointer<IntPtr> hReadPipe,
              Pointer<IntPtr> hWritePipe,
              Pointer<SECURITY_ATTRIBUTES> lpPipeAttributes,
              int nSize)>('CreatePipe');
      expect(CreatePipe, isA<Function>());
    });
    test('Can instantiate CreateProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateProcess = kernel32.lookupFunction<
              Int32 Function(
                  Pointer<Utf16> lpApplicationName,
                  Pointer<Utf16> lpCommandLine,
                  Pointer<SECURITY_ATTRIBUTES> lpProcessAttributes,
                  Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
                  Int32 bInheritHandles,
                  Uint32 dwCreationFlags,
                  Pointer lpEnvironment,
                  Pointer<Utf16> lpCurrentDirectory,
                  Pointer<STARTUPINFO> lpStartupInfo,
                  Pointer<PROCESS_INFORMATION> lpProcessInformation),
              int Function(
                  Pointer<Utf16> lpApplicationName,
                  Pointer<Utf16> lpCommandLine,
                  Pointer<SECURITY_ATTRIBUTES> lpProcessAttributes,
                  Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
                  int bInheritHandles,
                  int dwCreationFlags,
                  Pointer lpEnvironment,
                  Pointer<Utf16> lpCurrentDirectory,
                  Pointer<STARTUPINFO> lpStartupInfo,
                  Pointer<PROCESS_INFORMATION> lpProcessInformation)>(
          'CreateProcessW');
      expect(CreateProcess, isA<Function>());
    });
    if (windowsBuildNumber >= 17763) {
      test('Can instantiate CreatePseudoConsole', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final CreatePseudoConsole = kernel32.lookupFunction<
            Int32 Function(COORD size, IntPtr hInput, IntPtr hOutput,
                Uint32 dwFlags, Pointer<IntPtr> phPC),
            int Function(COORD size, int hInput, int hOutput, int dwFlags,
                Pointer<IntPtr> phPC)>('CreatePseudoConsole');
        expect(CreatePseudoConsole, isA<Function>());
      });
    }
    test('Can instantiate CreateRemoteThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateRemoteThread = kernel32.lookupFunction<
          IntPtr Function(
              IntPtr hProcess,
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              IntPtr dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              Uint32 dwCreationFlags,
              Pointer<Uint32> lpThreadId),
          int Function(
              int hProcess,
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              int dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              int dwCreationFlags,
              Pointer<Uint32> lpThreadId)>('CreateRemoteThread');
      expect(CreateRemoteThread, isA<Function>());
    });
    test('Can instantiate CreateRemoteThreadEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateRemoteThreadEx = kernel32.lookupFunction<
          IntPtr Function(
              IntPtr hProcess,
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              IntPtr dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              Uint32 dwCreationFlags,
              Pointer lpAttributeList,
              Pointer<Uint32> lpThreadId),
          int Function(
              int hProcess,
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              int dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              int dwCreationFlags,
              Pointer lpAttributeList,
              Pointer<Uint32> lpThreadId)>('CreateRemoteThreadEx');
      expect(CreateRemoteThreadEx, isA<Function>());
    });
    test('Can instantiate CreateThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final CreateThread = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              IntPtr dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              Uint32 dwCreationFlags,
              Pointer<Uint32> lpThreadId),
          int Function(
              Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
              int dwStackSize,
              Pointer<NativeFunction<ThreadProc>> lpStartAddress,
              Pointer lpParameter,
              int dwCreationFlags,
              Pointer<Uint32> lpThreadId)>('CreateThread');
      expect(CreateThread, isA<Function>());
    });
    test('Can instantiate DeactivateActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DeactivateActCtx = kernel32.lookupFunction<
          Int32 Function(Uint32 dwFlags, IntPtr ulCookie),
          int Function(int dwFlags, int ulCookie)>('DeactivateActCtx');
      expect(DeactivateActCtx, isA<Function>());
    });
    test('Can instantiate DebugBreak', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DebugBreak = kernel32
          .lookupFunction<Void Function(), void Function()>('DebugBreak');
      expect(DebugBreak, isA<Function>());
    });
    test('Can instantiate DebugBreakProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DebugBreakProcess = kernel32.lookupFunction<
          Int32 Function(IntPtr Process),
          int Function(int Process)>('DebugBreakProcess');
      expect(DebugBreakProcess, isA<Function>());
    });
    test('Can instantiate DebugSetProcessKillOnExit', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DebugSetProcessKillOnExit = kernel32.lookupFunction<
          Int32 Function(Int32 KillOnExit),
          int Function(int KillOnExit)>('DebugSetProcessKillOnExit');
      expect(DebugSetProcessKillOnExit, isA<Function>());
    });
    test('Can instantiate DefineDosDevice', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DefineDosDevice = kernel32.lookupFunction<
          Int32 Function(Uint32 dwFlags, Pointer<Utf16> lpDeviceName,
              Pointer<Utf16> lpTargetPath),
          int Function(int dwFlags, Pointer<Utf16> lpDeviceName,
              Pointer<Utf16> lpTargetPath)>('DefineDosDeviceW');
      expect(DefineDosDevice, isA<Function>());
    });
    test('Can instantiate DeleteFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DeleteFile = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName),
          int Function(Pointer<Utf16> lpFileName)>('DeleteFileW');
      expect(DeleteFile, isA<Function>());
    });
    test('Can instantiate DeleteVolumeMountPoint', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DeleteVolumeMountPoint = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszVolumeMountPoint),
          int Function(
              Pointer<Utf16> lpszVolumeMountPoint)>('DeleteVolumeMountPointW');
      expect(DeleteVolumeMountPoint, isA<Function>());
    });
    test('Can instantiate DeviceIoControl', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DeviceIoControl = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hDevice,
              Uint32 dwIoControlCode,
              Pointer lpInBuffer,
              Uint32 nInBufferSize,
              Pointer lpOutBuffer,
              Uint32 nOutBufferSize,
              Pointer<Uint32> lpBytesReturned,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hDevice,
              int dwIoControlCode,
              Pointer lpInBuffer,
              int nInBufferSize,
              Pointer lpOutBuffer,
              int nOutBufferSize,
              Pointer<Uint32> lpBytesReturned,
              Pointer<OVERLAPPED> lpOverlapped)>('DeviceIoControl');
      expect(DeviceIoControl, isA<Function>());
    });
    test('Can instantiate DisableThreadLibraryCalls', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DisableThreadLibraryCalls = kernel32.lookupFunction<
          Int32 Function(IntPtr hLibModule),
          int Function(int hLibModule)>('DisableThreadLibraryCalls');
      expect(DisableThreadLibraryCalls, isA<Function>());
    });
    test('Can instantiate DisconnectNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DisconnectNamedPipe = kernel32.lookupFunction<
          Int32 Function(IntPtr hNamedPipe),
          int Function(int hNamedPipe)>('DisconnectNamedPipe');
      expect(DisconnectNamedPipe, isA<Function>());
    });
    test('Can instantiate DnsHostnameToComputerName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DnsHostnameToComputerName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> Hostname, Pointer<Utf16> ComputerName,
              Pointer<Uint32> nSize),
          int Function(Pointer<Utf16> Hostname, Pointer<Utf16> ComputerName,
              Pointer<Uint32> nSize)>('DnsHostnameToComputerNameW');
      expect(DnsHostnameToComputerName, isA<Function>());
    });
    test('Can instantiate DosDateTimeToFileTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DosDateTimeToFileTime = kernel32.lookupFunction<
          Int32 Function(
              Uint16 wFatDate, Uint16 wFatTime, Pointer<FILETIME> lpFileTime),
          int Function(int wFatDate, int wFatTime,
              Pointer<FILETIME> lpFileTime)>('DosDateTimeToFileTime');
      expect(DosDateTimeToFileTime, isA<Function>());
    });
    test('Can instantiate DuplicateHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final DuplicateHandle = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hSourceProcessHandle,
              IntPtr hSourceHandle,
              IntPtr hTargetProcessHandle,
              Pointer<IntPtr> lpTargetHandle,
              Uint32 dwDesiredAccess,
              Int32 bInheritHandle,
              Uint32 dwOptions),
          int Function(
              int hSourceProcessHandle,
              int hSourceHandle,
              int hTargetProcessHandle,
              Pointer<IntPtr> lpTargetHandle,
              int dwDesiredAccess,
              int bInheritHandle,
              int dwOptions)>('DuplicateHandle');
      expect(DuplicateHandle, isA<Function>());
    });
    test('Can instantiate EndUpdateResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final EndUpdateResource = kernel32.lookupFunction<
          Int32 Function(IntPtr hUpdate, Int32 fDiscard),
          int Function(int hUpdate, int fDiscard)>('EndUpdateResourceW');
      expect(EndUpdateResource, isA<Function>());
    });
    test('Can instantiate K32EnumProcesses', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final K32EnumProcesses = kernel32.lookupFunction<
          Int32 Function(Pointer<Uint32> lpidProcess, Uint32 cb,
              Pointer<Uint32> lpcbNeeded),
          int Function(Pointer<Uint32> lpidProcess, int cb,
              Pointer<Uint32> lpcbNeeded)>('K32EnumProcesses');
      expect(K32EnumProcesses, isA<Function>());
    });
    test('Can instantiate K32EnumProcessModules', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final K32EnumProcessModules = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<IntPtr> lphModule, Uint32 cb,
              Pointer<Uint32> lpcbNeeded),
          int Function(int hProcess, Pointer<IntPtr> lphModule, int cb,
              Pointer<Uint32> lpcbNeeded)>('K32EnumProcessModules');
      expect(K32EnumProcessModules, isA<Function>());
    });
    test('Can instantiate K32EnumProcessModulesEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final K32EnumProcessModulesEx = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<IntPtr> lphModule, Uint32 cb,
              Pointer<Uint32> lpcbNeeded, Uint32 dwFilterFlag),
          int Function(
              int hProcess,
              Pointer<IntPtr> lphModule,
              int cb,
              Pointer<Uint32> lpcbNeeded,
              int dwFilterFlag)>('K32EnumProcessModulesEx');
      expect(K32EnumProcessModulesEx, isA<Function>());
    });
    test('Can instantiate EnumResourceNames', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final EnumResourceNames = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hModule,
              Pointer<Utf16> lpType,
              Pointer<NativeFunction<EnumResNameProc>> lpEnumFunc,
              IntPtr lParam),
          int Function(
              int hModule,
              Pointer<Utf16> lpType,
              Pointer<NativeFunction<EnumResNameProc>> lpEnumFunc,
              int lParam)>('EnumResourceNamesW');
      expect(EnumResourceNames, isA<Function>());
    });
    test('Can instantiate EnumResourceTypes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final EnumResourceTypes = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hModule,
              Pointer<NativeFunction<EnumResTypeProc>> lpEnumFunc,
              IntPtr lParam),
          int Function(
              int hModule,
              Pointer<NativeFunction<EnumResTypeProc>> lpEnumFunc,
              int lParam)>('EnumResourceTypesW');
      expect(EnumResourceTypes, isA<Function>());
    });
    test('Can instantiate EscapeCommFunction', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final EscapeCommFunction = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Uint32 dwFunc),
          int Function(int hFile, int dwFunc)>('EscapeCommFunction');
      expect(EscapeCommFunction, isA<Function>());
    });
    test('Can instantiate ExitProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ExitProcess = kernel32.lookupFunction<
          Void Function(Uint32 uExitCode),
          void Function(int uExitCode)>('ExitProcess');
      expect(ExitProcess, isA<Function>());
    });
    test('Can instantiate ExitThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ExitThread = kernel32.lookupFunction<
          Void Function(Uint32 dwExitCode),
          void Function(int dwExitCode)>('ExitThread');
      expect(ExitThread, isA<Function>());
    });
    test('Can instantiate FileTimeToDosDateTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FileTimeToDosDateTime = kernel32.lookupFunction<
          Int32 Function(Pointer<FILETIME> lpFileTime,
              Pointer<Uint16> lpFatDate, Pointer<Uint16> lpFatTime),
          int Function(Pointer<FILETIME> lpFileTime, Pointer<Uint16> lpFatDate,
              Pointer<Uint16> lpFatTime)>('FileTimeToDosDateTime');
      expect(FileTimeToDosDateTime, isA<Function>());
    });
    test('Can instantiate FileTimeToSystemTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FileTimeToSystemTime = kernel32.lookupFunction<
          Int32 Function(
              Pointer<FILETIME> lpFileTime, Pointer<SYSTEMTIME> lpSystemTime),
          int Function(Pointer<FILETIME> lpFileTime,
              Pointer<SYSTEMTIME> lpSystemTime)>('FileTimeToSystemTime');
      expect(FileTimeToSystemTime, isA<Function>());
    });
    test('Can instantiate FillConsoleOutputAttribute', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FillConsoleOutputAttribute = kernel32.lookupFunction<
              Int32 Function(
                  IntPtr hConsoleOutput,
                  Uint16 wAttribute,
                  Uint32 nLength,
                  COORD dwWriteCoord,
                  Pointer<Uint32> lpNumberOfAttrsWritten),
              int Function(int hConsoleOutput, int wAttribute, int nLength,
                  COORD dwWriteCoord, Pointer<Uint32> lpNumberOfAttrsWritten)>(
          'FillConsoleOutputAttribute');
      expect(FillConsoleOutputAttribute, isA<Function>());
    });
    test('Can instantiate FillConsoleOutputCharacter', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FillConsoleOutputCharacter = kernel32.lookupFunction<
              Int32 Function(
                  IntPtr hConsoleOutput,
                  Uint16 cCharacter,
                  Uint32 nLength,
                  COORD dwWriteCoord,
                  Pointer<Uint32> lpNumberOfCharsWritten),
              int Function(int hConsoleOutput, int cCharacter, int nLength,
                  COORD dwWriteCoord, Pointer<Uint32> lpNumberOfCharsWritten)>(
          'FillConsoleOutputCharacterW');
      expect(FillConsoleOutputCharacter, isA<Function>());
    });
    test('Can instantiate FindClose', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindClose = kernel32.lookupFunction<
          Int32 Function(IntPtr hFindFile),
          int Function(int hFindFile)>('FindClose');
      expect(FindClose, isA<Function>());
    });
    test('Can instantiate FindCloseChangeNotification', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindCloseChangeNotification = kernel32.lookupFunction<
          Int32 Function(IntPtr hChangeHandle),
          int Function(int hChangeHandle)>('FindCloseChangeNotification');
      expect(FindCloseChangeNotification, isA<Function>());
    });
    test('Can instantiate FindFirstChangeNotification', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstChangeNotification = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpPathName, Int32 bWatchSubtree,
              Uint32 dwNotifyFilter),
          int Function(Pointer<Utf16> lpPathName, int bWatchSubtree,
              int dwNotifyFilter)>('FindFirstChangeNotificationW');
      expect(FindFirstChangeNotification, isA<Function>());
    });
    test('Can instantiate FindFirstFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstFile = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpFileName,
              Pointer<WIN32_FIND_DATA> lpFindFileData),
          int Function(Pointer<Utf16> lpFileName,
              Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindFirstFileW');
      expect(FindFirstFile, isA<Function>());
    });
    test('Can instantiate FindFirstFileEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstFileEx = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpFileName,
              Int32 fInfoLevelId,
              Pointer lpFindFileData,
              Int32 fSearchOp,
              Pointer lpSearchFilter,
              Uint32 dwAdditionalFlags),
          int Function(
              Pointer<Utf16> lpFileName,
              int fInfoLevelId,
              Pointer lpFindFileData,
              int fSearchOp,
              Pointer lpSearchFilter,
              int dwAdditionalFlags)>('FindFirstFileExW');
      expect(FindFirstFileEx, isA<Function>());
    });
    test('Can instantiate FindFirstFileName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstFileName = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpFileName, Uint32 dwFlags,
              Pointer<Uint32> StringLength, Pointer<Utf16> LinkName),
          int Function(
              Pointer<Utf16> lpFileName,
              int dwFlags,
              Pointer<Uint32> StringLength,
              Pointer<Utf16> LinkName)>('FindFirstFileNameW');
      expect(FindFirstFileName, isA<Function>());
    });
    test('Can instantiate FindFirstStream', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstStream = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpFileName, Int32 InfoLevel,
              Pointer lpFindStreamData, Uint32 dwFlags),
          int Function(Pointer<Utf16> lpFileName, int InfoLevel,
              Pointer lpFindStreamData, int dwFlags)>('FindFirstStreamW');
      expect(FindFirstStream, isA<Function>());
    });
    test('Can instantiate FindFirstVolume', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindFirstVolume = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpszVolumeName, Uint32 cchBufferLength),
          int Function(Pointer<Utf16> lpszVolumeName,
              int cchBufferLength)>('FindFirstVolumeW');
      expect(FindFirstVolume, isA<Function>());
    });
    test('Can instantiate FindNextChangeNotification', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindNextChangeNotification = kernel32.lookupFunction<
          Int32 Function(IntPtr hChangeHandle),
          int Function(int hChangeHandle)>('FindNextChangeNotification');
      expect(FindNextChangeNotification, isA<Function>());
    });
    test('Can instantiate FindNextFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindNextFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData),
          int Function(int hFindFile,
              Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindNextFileW');
      expect(FindNextFile, isA<Function>());
    });
    test('Can instantiate FindNextFileName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindNextFileName = kernel32.lookupFunction<
          Int32 Function(IntPtr hFindStream, Pointer<Uint32> StringLength,
              Pointer<Utf16> LinkName),
          int Function(int hFindStream, Pointer<Uint32> StringLength,
              Pointer<Utf16> LinkName)>('FindNextFileNameW');
      expect(FindNextFileName, isA<Function>());
    });
    test('Can instantiate FindNextStream', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindNextStream = kernel32.lookupFunction<
          Int32 Function(IntPtr hFindStream, Pointer lpFindStreamData),
          int Function(
              int hFindStream, Pointer lpFindStreamData)>('FindNextStreamW');
      expect(FindNextStream, isA<Function>());
    });
    test('Can instantiate FindNextVolume', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindNextVolume = kernel32.lookupFunction<
          Int32 Function(IntPtr hFindVolume, Pointer<Utf16> lpszVolumeName,
              Uint32 cchBufferLength),
          int Function(int hFindVolume, Pointer<Utf16> lpszVolumeName,
              int cchBufferLength)>('FindNextVolumeW');
      expect(FindNextVolume, isA<Function>());
    });
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate FindPackagesByPackageFamily', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final FindPackagesByPackageFamily = kernel32.lookupFunction<
                Uint32 Function(
                    Pointer<Utf16> packageFamilyName,
                    Uint32 packageFilters,
                    Pointer<Uint32> count,
                    Pointer<Pointer<Utf16>> packageFullNames,
                    Pointer<Uint32> bufferLength,
                    Pointer<Utf16> buffer,
                    Pointer<Uint32> packageProperties),
                int Function(
                    Pointer<Utf16> packageFamilyName,
                    int packageFilters,
                    Pointer<Uint32> count,
                    Pointer<Pointer<Utf16>> packageFullNames,
                    Pointer<Uint32> bufferLength,
                    Pointer<Utf16> buffer,
                    Pointer<Uint32> packageProperties)>(
            'FindPackagesByPackageFamily');
        expect(FindPackagesByPackageFamily, isA<Function>());
      });
    }
    test('Can instantiate FindResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindResource = kernel32.lookupFunction<
          IntPtr Function(
              IntPtr hModule, Pointer<Utf16> lpName, Pointer<Utf16> lpType),
          int Function(int hModule, Pointer<Utf16> lpName,
              Pointer<Utf16> lpType)>('FindResourceW');
      expect(FindResource, isA<Function>());
    });
    test('Can instantiate FindResourceEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindResourceEx = kernel32.lookupFunction<
          IntPtr Function(IntPtr hModule, Pointer<Utf16> lpType,
              Pointer<Utf16> lpName, Uint16 wLanguage),
          int Function(int hModule, Pointer<Utf16> lpType,
              Pointer<Utf16> lpName, int wLanguage)>('FindResourceExW');
      expect(FindResourceEx, isA<Function>());
    });
    test('Can instantiate FindStringOrdinal', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindStringOrdinal = kernel32.lookupFunction<
          Int32 Function(
              Uint32 dwFindStringOrdinalFlags,
              Pointer<Utf16> lpStringSource,
              Int32 cchSource,
              Pointer<Utf16> lpStringValue,
              Int32 cchValue,
              Int32 bIgnoreCase),
          int Function(
              int dwFindStringOrdinalFlags,
              Pointer<Utf16> lpStringSource,
              int cchSource,
              Pointer<Utf16> lpStringValue,
              int cchValue,
              int bIgnoreCase)>('FindStringOrdinal');
      expect(FindStringOrdinal, isA<Function>());
    });
    test('Can instantiate FindVolumeClose', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FindVolumeClose = kernel32.lookupFunction<
          Int32 Function(IntPtr hFindVolume),
          int Function(int hFindVolume)>('FindVolumeClose');
      expect(FindVolumeClose, isA<Function>());
    });
    test('Can instantiate FlushConsoleInputBuffer', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FlushConsoleInputBuffer = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleInput),
          int Function(int hConsoleInput)>('FlushConsoleInputBuffer');
      expect(FlushConsoleInputBuffer, isA<Function>());
    });
    test('Can instantiate FormatMessage', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FormatMessage = kernel32.lookupFunction<
          Uint32 Function(
              Uint32 dwFlags,
              Pointer lpSource,
              Uint32 dwMessageId,
              Uint32 dwLanguageId,
              Pointer<Utf16> lpBuffer,
              Uint32 nSize,
              Pointer<Pointer<Int8>> Arguments),
          int Function(
              int dwFlags,
              Pointer lpSource,
              int dwMessageId,
              int dwLanguageId,
              Pointer<Utf16> lpBuffer,
              int nSize,
              Pointer<Pointer<Int8>> Arguments)>('FormatMessageW');
      expect(FormatMessage, isA<Function>());
    });
    test('Can instantiate FreeConsole', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FreeConsole = kernel32
          .lookupFunction<Int32 Function(), int Function()>('FreeConsole');
      expect(FreeConsole, isA<Function>());
    });
    test('Can instantiate FreeLibrary', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FreeLibrary = kernel32.lookupFunction<
          Int32 Function(IntPtr hLibModule),
          int Function(int hLibModule)>('FreeLibrary');
      expect(FreeLibrary, isA<Function>());
    });
    test('Can instantiate FreeLibraryAndExitThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final FreeLibraryAndExitThread = kernel32.lookupFunction<
          Void Function(IntPtr hLibModule, Uint32 dwExitCode),
          void Function(
              int hLibModule, int dwExitCode)>('FreeLibraryAndExitThread');
      expect(FreeLibraryAndExitThread, isA<Function>());
    });
    test('Can instantiate GetActiveProcessorCount', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetActiveProcessorCount = kernel32.lookupFunction<
          Uint32 Function(Uint16 GroupNumber),
          int Function(int GroupNumber)>('GetActiveProcessorCount');
      expect(GetActiveProcessorCount, isA<Function>());
    });
    test('Can instantiate GetActiveProcessorGroupCount', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetActiveProcessorGroupCount =
          kernel32.lookupFunction<Uint16 Function(), int Function()>(
              'GetActiveProcessorGroupCount');
      expect(GetActiveProcessorGroupCount, isA<Function>());
    });
    test('Can instantiate GetBinaryType', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetBinaryType = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpApplicationName, Pointer<Uint32> lpBinaryType),
          int Function(Pointer<Utf16> lpApplicationName,
              Pointer<Uint32> lpBinaryType)>('GetBinaryTypeW');
      expect(GetBinaryType, isA<Function>());
    });
    test('Can instantiate GetCommandLine', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommandLine = kernel32.lookupFunction<Pointer<Utf16> Function(),
          Pointer<Utf16> Function()>('GetCommandLineW');
      expect(GetCommandLine, isA<Function>());
    });
    test('Can instantiate GetCommConfig', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommConfig = kernel32.lookupFunction<
          Int32 Function(IntPtr hCommDev, Pointer<COMMCONFIG> lpCC,
              Pointer<Uint32> lpdwSize),
          int Function(int hCommDev, Pointer<COMMCONFIG> lpCC,
              Pointer<Uint32> lpdwSize)>('GetCommConfig');
      expect(GetCommConfig, isA<Function>());
    });
    test('Can instantiate GetCommMask', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommMask = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<Uint32> lpEvtMask),
          int Function(int hFile, Pointer<Uint32> lpEvtMask)>('GetCommMask');
      expect(GetCommMask, isA<Function>());
    });
    test('Can instantiate GetCommModemStatus', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommModemStatus = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<Uint32> lpModemStat),
          int Function(
              int hFile, Pointer<Uint32> lpModemStat)>('GetCommModemStatus');
      expect(GetCommModemStatus, isA<Function>());
    });
    test('Can instantiate GetCommProperties', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommProperties = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<COMMPROP> lpCommProp),
          int Function(
              int hFile, Pointer<COMMPROP> lpCommProp)>('GetCommProperties');
      expect(GetCommProperties, isA<Function>());
    });
    test('Can instantiate GetCommState', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommState = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB),
          int Function(int hFile, Pointer<DCB> lpDCB)>('GetCommState');
      expect(GetCommState, isA<Function>());
    });
    test('Can instantiate GetCommTimeouts', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCommTimeouts = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts),
          int Function(int hFile,
              Pointer<COMMTIMEOUTS> lpCommTimeouts)>('GetCommTimeouts');
      expect(GetCommTimeouts, isA<Function>());
    });
    test('Can instantiate GetCompressedFileSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCompressedFileSize = kernel32.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lpFileName, Pointer<Uint32> lpFileSizeHigh),
          int Function(Pointer<Utf16> lpFileName,
              Pointer<Uint32> lpFileSizeHigh)>('GetCompressedFileSizeW');
      expect(GetCompressedFileSize, isA<Function>());
    });
    test('Can instantiate GetComputerName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetComputerName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize),
          int Function(Pointer<Utf16> lpBuffer,
              Pointer<Uint32> nSize)>('GetComputerNameW');
      expect(GetComputerName, isA<Function>());
    });
    test('Can instantiate GetComputerNameEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetComputerNameEx = kernel32.lookupFunction<
          Int32 Function(
              Int32 NameType, Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize),
          int Function(int NameType, Pointer<Utf16> lpBuffer,
              Pointer<Uint32> nSize)>('GetComputerNameExW');
      expect(GetComputerNameEx, isA<Function>());
    });
    test('Can instantiate GetConsoleCP', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleCP = kernel32
          .lookupFunction<Uint32 Function(), int Function()>('GetConsoleCP');
      expect(GetConsoleCP, isA<Function>());
    });
    test('Can instantiate GetConsoleCursorInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleCursorInfo = kernel32.lookupFunction<
              Int32 Function(IntPtr hConsoleOutput,
                  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo),
              int Function(int hConsoleOutput,
                  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo)>(
          'GetConsoleCursorInfo');
      expect(GetConsoleCursorInfo, isA<Function>());
    });
    test('Can instantiate GetConsoleMode', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleMode = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleHandle, Pointer<Uint32> lpMode),
          int Function(
              int hConsoleHandle, Pointer<Uint32> lpMode)>('GetConsoleMode');
      expect(GetConsoleMode, isA<Function>());
    });
    test('Can instantiate GetConsoleOutputCP', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleOutputCP =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetConsoleOutputCP');
      expect(GetConsoleOutputCP, isA<Function>());
    });
    test('Can instantiate GetConsoleScreenBufferInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleScreenBufferInfo = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleOutput,
              Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo),
          int Function(
              int hConsoleOutput,
              Pointer<CONSOLE_SCREEN_BUFFER_INFO>
                  lpConsoleScreenBufferInfo)>('GetConsoleScreenBufferInfo');
      expect(GetConsoleScreenBufferInfo, isA<Function>());
    });
    test('Can instantiate GetConsoleSelectionInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleSelectionInfo = kernel32.lookupFunction<
              Int32 Function(
                  Pointer<CONSOLE_SELECTION_INFO> lpConsoleSelectionInfo),
              int Function(
                  Pointer<CONSOLE_SELECTION_INFO> lpConsoleSelectionInfo)>(
          'GetConsoleSelectionInfo');
      expect(GetConsoleSelectionInfo, isA<Function>());
    });
    test('Can instantiate GetConsoleTitle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleTitle = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpConsoleTitle, Uint32 nSize),
          int Function(
              Pointer<Utf16> lpConsoleTitle, int nSize)>('GetConsoleTitleW');
      expect(GetConsoleTitle, isA<Function>());
    });
    test('Can instantiate GetConsoleWindow', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetConsoleWindow =
          kernel32.lookupFunction<IntPtr Function(), int Function()>(
              'GetConsoleWindow');
      expect(GetConsoleWindow, isA<Function>());
    });
    test('Can instantiate GetCurrentActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentActCtx = kernel32.lookupFunction<
          Int32 Function(Pointer<IntPtr> lphActCtx),
          int Function(Pointer<IntPtr> lphActCtx)>('GetCurrentActCtx');
      expect(GetCurrentActCtx, isA<Function>());
    });
    test('Can instantiate GetCurrentProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentProcess =
          kernel32.lookupFunction<IntPtr Function(), int Function()>(
              'GetCurrentProcess');
      expect(GetCurrentProcess, isA<Function>());
    });
    test('Can instantiate GetCurrentProcessId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentProcessId =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetCurrentProcessId');
      expect(GetCurrentProcessId, isA<Function>());
    });
    test('Can instantiate GetCurrentProcessorNumber', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentProcessorNumber =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetCurrentProcessorNumber');
      expect(GetCurrentProcessorNumber, isA<Function>());
    });
    test('Can instantiate GetCurrentThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentThread =
          kernel32.lookupFunction<IntPtr Function(), int Function()>(
              'GetCurrentThread');
      expect(GetCurrentThread, isA<Function>());
    });
    test('Can instantiate GetCurrentThreadId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetCurrentThreadId =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetCurrentThreadId');
      expect(GetCurrentThreadId, isA<Function>());
    });
    test('Can instantiate GetDefaultCommConfig', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetDefaultCommConfig = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
              Pointer<Uint32> lpdwSize),
          int Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
              Pointer<Uint32> lpdwSize)>('GetDefaultCommConfigW');
      expect(GetDefaultCommConfig, isA<Function>());
    });
    test('Can instantiate GetDiskFreeSpace', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetDiskFreeSpace = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpRootPathName,
              Pointer<Uint32> lpSectorsPerCluster,
              Pointer<Uint32> lpBytesPerSector,
              Pointer<Uint32> lpNumberOfFreeClusters,
              Pointer<Uint32> lpTotalNumberOfClusters),
          int Function(
              Pointer<Utf16> lpRootPathName,
              Pointer<Uint32> lpSectorsPerCluster,
              Pointer<Uint32> lpBytesPerSector,
              Pointer<Uint32> lpNumberOfFreeClusters,
              Pointer<Uint32> lpTotalNumberOfClusters)>('GetDiskFreeSpaceW');
      expect(GetDiskFreeSpace, isA<Function>());
    });
    test('Can instantiate GetDiskFreeSpaceEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetDiskFreeSpaceEx = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpDirectoryName,
              Pointer<Uint64> lpFreeBytesAvailableToCaller,
              Pointer<Uint64> lpTotalNumberOfBytes,
              Pointer<Uint64> lpTotalNumberOfFreeBytes),
          int Function(
              Pointer<Utf16> lpDirectoryName,
              Pointer<Uint64> lpFreeBytesAvailableToCaller,
              Pointer<Uint64> lpTotalNumberOfBytes,
              Pointer<Uint64> lpTotalNumberOfFreeBytes)>('GetDiskFreeSpaceExW');
      expect(GetDiskFreeSpaceEx, isA<Function>());
    });
    test('Can instantiate GetDllDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetDllDirectory = kernel32.lookupFunction<
          Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
          int Function(
              int nBufferLength, Pointer<Utf16> lpBuffer)>('GetDllDirectoryW');
      expect(GetDllDirectory, isA<Function>());
    });
    test('Can instantiate GetDriveType', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetDriveType = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpRootPathName),
          int Function(Pointer<Utf16> lpRootPathName)>('GetDriveTypeW');
      expect(GetDriveType, isA<Function>());
    });
    test('Can instantiate GetEnvironmentVariable', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetEnvironmentVariable = kernel32.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lpName, Pointer<Utf16> lpBuffer, Uint32 nSize),
          int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpBuffer,
              int nSize)>('GetEnvironmentVariableW');
      expect(GetEnvironmentVariable, isA<Function>());
    });
    test('Can instantiate GetExitCodeProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetExitCodeProcess = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<Uint32> lpExitCode),
          int Function(
              int hProcess, Pointer<Uint32> lpExitCode)>('GetExitCodeProcess');
      expect(GetExitCodeProcess, isA<Function>());
    });
    test('Can instantiate GetFileAttributes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileAttributes = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpFileName),
          int Function(Pointer<Utf16> lpFileName)>('GetFileAttributesW');
      expect(GetFileAttributes, isA<Function>());
    });
    test('Can instantiate GetFileAttributesEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileAttributesEx = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName, Int32 fInfoLevelId,
              Pointer lpFileInformation),
          int Function(Pointer<Utf16> lpFileName, int fInfoLevelId,
              Pointer lpFileInformation)>('GetFileAttributesExW');
      expect(GetFileAttributesEx, isA<Function>());
    });
    test('Can instantiate GetFileInformationByHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileInformationByHandle = kernel32.lookupFunction<
              Int32 Function(IntPtr hFile,
                  Pointer<BY_HANDLE_FILE_INFORMATION> lpFileInformation),
              int Function(int hFile,
                  Pointer<BY_HANDLE_FILE_INFORMATION> lpFileInformation)>(
          'GetFileInformationByHandle');
      expect(GetFileInformationByHandle, isA<Function>());
    });
    test('Can instantiate GetFileSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileSize = kernel32.lookupFunction<
          Uint32 Function(IntPtr hFile, Pointer<Uint32> lpFileSizeHigh),
          int Function(
              int hFile, Pointer<Uint32> lpFileSizeHigh)>('GetFileSize');
      expect(GetFileSize, isA<Function>());
    });
    test('Can instantiate GetFileSizeEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileSizeEx = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<Int64> lpFileSize),
          int Function(int hFile, Pointer<Int64> lpFileSize)>('GetFileSizeEx');
      expect(GetFileSizeEx, isA<Function>());
    });
    test('Can instantiate GetFileType', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFileType = kernel32.lookupFunction<Uint32 Function(IntPtr hFile),
          int Function(int hFile)>('GetFileType');
      expect(GetFileType, isA<Function>());
    });
    test('Can instantiate GetFinalPathNameByHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFinalPathNameByHandle = kernel32.lookupFunction<
          Uint32 Function(IntPtr hFile, Pointer<Utf16> lpszFilePath,
              Uint32 cchFilePath, Uint32 dwFlags),
          int Function(int hFile, Pointer<Utf16> lpszFilePath, int cchFilePath,
              int dwFlags)>('GetFinalPathNameByHandleW');
      expect(GetFinalPathNameByHandle, isA<Function>());
    });
    test('Can instantiate GetFullPathName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetFullPathName = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpFileName, Uint32 nBufferLength,
              Pointer<Utf16> lpBuffer, Pointer<Pointer<Utf16>> lpFilePart),
          int Function(
              Pointer<Utf16> lpFileName,
              int nBufferLength,
              Pointer<Utf16> lpBuffer,
              Pointer<Pointer<Utf16>> lpFilePart)>('GetFullPathNameW');
      expect(GetFullPathName, isA<Function>());
    });
    test('Can instantiate GetHandleInformation', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetHandleInformation = kernel32.lookupFunction<
          Int32 Function(IntPtr hObject, Pointer<Uint32> lpdwFlags),
          int Function(
              int hObject, Pointer<Uint32> lpdwFlags)>('GetHandleInformation');
      expect(GetHandleInformation, isA<Function>());
    });
    test('Can instantiate GetLargestConsoleWindowSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLargestConsoleWindowSize = kernel32.lookupFunction<
          COORD Function(IntPtr hConsoleOutput),
          COORD Function(int hConsoleOutput)>('GetLargestConsoleWindowSize');
      expect(GetLargestConsoleWindowSize, isA<Function>());
    });
    test('Can instantiate GetLastError', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLastError = kernel32
          .lookupFunction<Uint32 Function(), int Function()>('GetLastError');
      expect(GetLastError, isA<Function>());
    });
    test('Can instantiate GetLocaleInfoEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLocaleInfoEx = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpLocaleName, Uint32 LCType,
              Pointer<Utf16> lpLCData, Int32 cchData),
          int Function(Pointer<Utf16> lpLocaleName, int LCType,
              Pointer<Utf16> lpLCData, int cchData)>('GetLocaleInfoEx');
      expect(GetLocaleInfoEx, isA<Function>());
    });
    test('Can instantiate GetLocalTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLocalTime = kernel32.lookupFunction<
          Void Function(Pointer<SYSTEMTIME> lpSystemTime),
          void Function(Pointer<SYSTEMTIME> lpSystemTime)>('GetLocalTime');
      expect(GetLocalTime, isA<Function>());
    });
    test('Can instantiate GetLogicalDrives', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLogicalDrives =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetLogicalDrives');
      expect(GetLogicalDrives, isA<Function>());
    });
    test('Can instantiate GetLogicalDriveStrings', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLogicalDriveStrings = kernel32.lookupFunction<
          Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
          int Function(int nBufferLength,
              Pointer<Utf16> lpBuffer)>('GetLogicalDriveStringsW');
      expect(GetLogicalDriveStrings, isA<Function>());
    });
    test('Can instantiate GetLongPathName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetLongPathName = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpszShortPath,
              Pointer<Utf16> lpszLongPath, Uint32 cchBuffer),
          int Function(Pointer<Utf16> lpszShortPath,
              Pointer<Utf16> lpszLongPath, int cchBuffer)>('GetLongPathNameW');
      expect(GetLongPathName, isA<Function>());
    });
    if (windowsBuildNumber >= 22000) {
      test('Can instantiate GetMachineTypeAttributes', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final GetMachineTypeAttributes = kernel32.lookupFunction<
                Int32 Function(
                    Uint16 Machine, Pointer<Uint32> MachineTypeAttributes),
                int Function(
                    int Machine, Pointer<Uint32> MachineTypeAttributes)>(
            'GetMachineTypeAttributes');
        expect(GetMachineTypeAttributes, isA<Function>());
      });
    }
    test('Can instantiate GetMaximumProcessorCount', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetMaximumProcessorCount = kernel32.lookupFunction<
          Uint32 Function(Uint16 GroupNumber),
          int Function(int GroupNumber)>('GetMaximumProcessorCount');
      expect(GetMaximumProcessorCount, isA<Function>());
    });
    test('Can instantiate GetMaximumProcessorGroupCount', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetMaximumProcessorGroupCount =
          kernel32.lookupFunction<Uint16 Function(), int Function()>(
              'GetMaximumProcessorGroupCount');
      expect(GetMaximumProcessorGroupCount, isA<Function>());
    });
    test('Can instantiate K32GetModuleBaseName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final K32GetModuleBaseName = kernel32.lookupFunction<
          Uint32 Function(IntPtr hProcess, IntPtr hModule,
              Pointer<Utf16> lpBaseName, Uint32 nSize),
          int Function(int hProcess, int hModule, Pointer<Utf16> lpBaseName,
              int nSize)>('K32GetModuleBaseNameW');
      expect(K32GetModuleBaseName, isA<Function>());
    });
    test('Can instantiate GetModuleFileName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetModuleFileName = kernel32.lookupFunction<
          Uint32 Function(
              IntPtr hModule, Pointer<Utf16> lpFilename, Uint32 nSize),
          int Function(int hModule, Pointer<Utf16> lpFilename,
              int nSize)>('GetModuleFileNameW');
      expect(GetModuleFileName, isA<Function>());
    });
    test('Can instantiate K32GetModuleFileNameEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final K32GetModuleFileNameEx = kernel32.lookupFunction<
          Uint32 Function(IntPtr hProcess, IntPtr hModule,
              Pointer<Utf16> lpFilename, Uint32 nSize),
          int Function(int hProcess, int hModule, Pointer<Utf16> lpFilename,
              int nSize)>('K32GetModuleFileNameExW');
      expect(K32GetModuleFileNameEx, isA<Function>());
    });
    test('Can instantiate GetModuleHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetModuleHandle = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpModuleName),
          int Function(Pointer<Utf16> lpModuleName)>('GetModuleHandleW');
      expect(GetModuleHandle, isA<Function>());
    });
    test('Can instantiate GetModuleHandleEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetModuleHandleEx = kernel32.lookupFunction<
          Int32 Function(Uint32 dwFlags, Pointer<Utf16> lpModuleName,
              Pointer<IntPtr> phModule),
          int Function(int dwFlags, Pointer<Utf16> lpModuleName,
              Pointer<IntPtr> phModule)>('GetModuleHandleExW');
      expect(GetModuleHandleEx, isA<Function>());
    });
    test('Can instantiate GetNamedPipeClientComputerName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNamedPipeClientComputerName = kernel32.lookupFunction<
          Int32 Function(IntPtr Pipe, Pointer<Utf16> ClientComputerName,
              Uint32 ClientComputerNameLength),
          int Function(int Pipe, Pointer<Utf16> ClientComputerName,
              int ClientComputerNameLength)>('GetNamedPipeClientComputerNameW');
      expect(GetNamedPipeClientComputerName, isA<Function>());
    });
    test('Can instantiate GetNamedPipeClientProcessId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNamedPipeClientProcessId = kernel32.lookupFunction<
          Int32 Function(IntPtr Pipe, Pointer<Uint32> ClientProcessId),
          int Function(int Pipe,
              Pointer<Uint32> ClientProcessId)>('GetNamedPipeClientProcessId');
      expect(GetNamedPipeClientProcessId, isA<Function>());
    });
    test('Can instantiate GetNamedPipeClientSessionId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNamedPipeClientSessionId = kernel32.lookupFunction<
          Int32 Function(IntPtr Pipe, Pointer<Uint32> ClientSessionId),
          int Function(int Pipe,
              Pointer<Uint32> ClientSessionId)>('GetNamedPipeClientSessionId');
      expect(GetNamedPipeClientSessionId, isA<Function>());
    });
    test('Can instantiate GetNamedPipeHandleState', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNamedPipeHandleState = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hNamedPipe,
              Pointer<Uint32> lpState,
              Pointer<Uint32> lpCurInstances,
              Pointer<Uint32> lpMaxCollectionCount,
              Pointer<Uint32> lpCollectDataTimeout,
              Pointer<Utf16> lpUserName,
              Uint32 nMaxUserNameSize),
          int Function(
              int hNamedPipe,
              Pointer<Uint32> lpState,
              Pointer<Uint32> lpCurInstances,
              Pointer<Uint32> lpMaxCollectionCount,
              Pointer<Uint32> lpCollectDataTimeout,
              Pointer<Utf16> lpUserName,
              int nMaxUserNameSize)>('GetNamedPipeHandleStateW');
      expect(GetNamedPipeHandleState, isA<Function>());
    });
    test('Can instantiate GetNamedPipeInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNamedPipeInfo = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hNamedPipe,
              Pointer<Uint32> lpFlags,
              Pointer<Uint32> lpOutBufferSize,
              Pointer<Uint32> lpInBufferSize,
              Pointer<Uint32> lpMaxInstances),
          int Function(
              int hNamedPipe,
              Pointer<Uint32> lpFlags,
              Pointer<Uint32> lpOutBufferSize,
              Pointer<Uint32> lpInBufferSize,
              Pointer<Uint32> lpMaxInstances)>('GetNamedPipeInfo');
      expect(GetNamedPipeInfo, isA<Function>());
    });
    test('Can instantiate GetNativeSystemInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNativeSystemInfo = kernel32.lookupFunction<
          Void Function(Pointer<SYSTEM_INFO> lpSystemInfo),
          void Function(
              Pointer<SYSTEM_INFO> lpSystemInfo)>('GetNativeSystemInfo');
      expect(GetNativeSystemInfo, isA<Function>());
    });
    test('Can instantiate GetNumberOfConsoleInputEvents', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetNumberOfConsoleInputEvents = kernel32.lookupFunction<
              Int32 Function(
                  IntPtr hConsoleInput, Pointer<Uint32> lpNumberOfEvents),
              int Function(
                  int hConsoleInput, Pointer<Uint32> lpNumberOfEvents)>(
          'GetNumberOfConsoleInputEvents');
      expect(GetNumberOfConsoleInputEvents, isA<Function>());
    });
    test('Can instantiate GetOverlappedResult', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetOverlappedResult = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<OVERLAPPED> lpOverlapped,
              Pointer<Uint32> lpNumberOfBytesTransferred, Int32 bWait),
          int Function(
              int hFile,
              Pointer<OVERLAPPED> lpOverlapped,
              Pointer<Uint32> lpNumberOfBytesTransferred,
              int bWait)>('GetOverlappedResult');
      expect(GetOverlappedResult, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetOverlappedResultEx', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final GetOverlappedResultEx = kernel32.lookupFunction<
            Int32 Function(
                IntPtr hFile,
                Pointer<OVERLAPPED> lpOverlapped,
                Pointer<Uint32> lpNumberOfBytesTransferred,
                Uint32 dwMilliseconds,
                Int32 bAlertable),
            int Function(
                int hFile,
                Pointer<OVERLAPPED> lpOverlapped,
                Pointer<Uint32> lpNumberOfBytesTransferred,
                int dwMilliseconds,
                int bAlertable)>('GetOverlappedResultEx');
        expect(GetOverlappedResultEx, isA<Function>());
      });
    }
    test('Can instantiate GetPhysicallyInstalledSystemMemory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetPhysicallyInstalledSystemMemory = kernel32.lookupFunction<
              Int32 Function(Pointer<Uint64> TotalMemoryInKilobytes),
              int Function(Pointer<Uint64> TotalMemoryInKilobytes)>(
          'GetPhysicallyInstalledSystemMemory');
      expect(GetPhysicallyInstalledSystemMemory, isA<Function>());
    });
    test('Can instantiate GetProcAddress', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcAddress = kernel32.lookupFunction<
          Pointer Function(IntPtr hModule, Pointer<Utf8> lpProcName),
          Pointer Function(
              int hModule, Pointer<Utf8> lpProcName)>('GetProcAddress');
      expect(GetProcAddress, isA<Function>());
    });
    test('Can instantiate GetProcessHeap', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessHeap = kernel32
          .lookupFunction<IntPtr Function(), int Function()>('GetProcessHeap');
      expect(GetProcessHeap, isA<Function>());
    });
    test('Can instantiate GetProcessHeaps', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessHeaps = kernel32.lookupFunction<
          Uint32 Function(Uint32 NumberOfHeaps, Pointer<IntPtr> ProcessHeaps),
          int Function(int NumberOfHeaps,
              Pointer<IntPtr> ProcessHeaps)>('GetProcessHeaps');
      expect(GetProcessHeaps, isA<Function>());
    });
    test('Can instantiate GetProcessId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessId = kernel32.lookupFunction<
          Uint32 Function(IntPtr Process),
          int Function(int Process)>('GetProcessId');
      expect(GetProcessId, isA<Function>());
    });
    test('Can instantiate GetProcessShutdownParameters', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessShutdownParameters = kernel32.lookupFunction<
          Int32 Function(Pointer<Uint32> lpdwLevel, Pointer<Uint32> lpdwFlags),
          int Function(Pointer<Uint32> lpdwLevel,
              Pointer<Uint32> lpdwFlags)>('GetProcessShutdownParameters');
      expect(GetProcessShutdownParameters, isA<Function>());
    });
    test('Can instantiate GetProcessTimes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessTimes = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hProcess,
              Pointer<FILETIME> lpCreationTime,
              Pointer<FILETIME> lpExitTime,
              Pointer<FILETIME> lpKernelTime,
              Pointer<FILETIME> lpUserTime),
          int Function(
              int hProcess,
              Pointer<FILETIME> lpCreationTime,
              Pointer<FILETIME> lpExitTime,
              Pointer<FILETIME> lpKernelTime,
              Pointer<FILETIME> lpUserTime)>('GetProcessTimes');
      expect(GetProcessTimes, isA<Function>());
    });
    test('Can instantiate GetProcessVersion', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessVersion = kernel32.lookupFunction<
          Uint32 Function(Uint32 ProcessId),
          int Function(int ProcessId)>('GetProcessVersion');
      expect(GetProcessVersion, isA<Function>());
    });
    test('Can instantiate GetProcessWorkingSetSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProcessWorkingSetSize = kernel32.lookupFunction<
              Int32 Function(
                  IntPtr hProcess,
                  Pointer<IntPtr> lpMinimumWorkingSetSize,
                  Pointer<IntPtr> lpMaximumWorkingSetSize),
              int Function(
                  int hProcess,
                  Pointer<IntPtr> lpMinimumWorkingSetSize,
                  Pointer<IntPtr> lpMaximumWorkingSetSize)>(
          'GetProcessWorkingSetSize');
      expect(GetProcessWorkingSetSize, isA<Function>());
    });
    test('Can instantiate GetProductInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetProductInfo = kernel32.lookupFunction<
          Int32 Function(
              Uint32 dwOSMajorVersion,
              Uint32 dwOSMinorVersion,
              Uint32 dwSpMajorVersion,
              Uint32 dwSpMinorVersion,
              Pointer<Uint32> pdwReturnedProductType),
          int Function(
              int dwOSMajorVersion,
              int dwOSMinorVersion,
              int dwSpMajorVersion,
              int dwSpMinorVersion,
              Pointer<Uint32> pdwReturnedProductType)>('GetProductInfo');
      expect(GetProductInfo, isA<Function>());
    });
    test('Can instantiate GetQueuedCompletionStatus', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetQueuedCompletionStatus = kernel32.lookupFunction<
          Int32 Function(
              IntPtr CompletionPort,
              Pointer<Uint32> lpNumberOfBytesTransferred,
              Pointer<IntPtr> lpCompletionKey,
              Pointer<Pointer<OVERLAPPED>> lpOverlapped,
              Uint32 dwMilliseconds),
          int Function(
              int CompletionPort,
              Pointer<Uint32> lpNumberOfBytesTransferred,
              Pointer<IntPtr> lpCompletionKey,
              Pointer<Pointer<OVERLAPPED>> lpOverlapped,
              int dwMilliseconds)>('GetQueuedCompletionStatus');
      expect(GetQueuedCompletionStatus, isA<Function>());
    });
    test('Can instantiate GetQueuedCompletionStatusEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetQueuedCompletionStatusEx = kernel32.lookupFunction<
          Int32 Function(
              IntPtr CompletionPort,
              Pointer<OVERLAPPED_ENTRY> lpCompletionPortEntries,
              Uint32 ulCount,
              Pointer<Uint32> ulNumEntriesRemoved,
              Uint32 dwMilliseconds,
              Int32 fAlertable),
          int Function(
              int CompletionPort,
              Pointer<OVERLAPPED_ENTRY> lpCompletionPortEntries,
              int ulCount,
              Pointer<Uint32> ulNumEntriesRemoved,
              int dwMilliseconds,
              int fAlertable)>('GetQueuedCompletionStatusEx');
      expect(GetQueuedCompletionStatusEx, isA<Function>());
    });
    test('Can instantiate GetShortPathName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetShortPathName = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpszLongPath,
              Pointer<Utf16> lpszShortPath, Uint32 cchBuffer),
          int Function(
              Pointer<Utf16> lpszLongPath,
              Pointer<Utf16> lpszShortPath,
              int cchBuffer)>('GetShortPathNameW');
      expect(GetShortPathName, isA<Function>());
    });
    test('Can instantiate GetStartupInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetStartupInfo = kernel32.lookupFunction<
          Void Function(Pointer<STARTUPINFO> lpStartupInfo),
          void Function(Pointer<STARTUPINFO> lpStartupInfo)>('GetStartupInfoW');
      expect(GetStartupInfo, isA<Function>());
    });
    test('Can instantiate GetStdHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetStdHandle = kernel32.lookupFunction<
          IntPtr Function(Uint32 nStdHandle),
          int Function(int nStdHandle)>('GetStdHandle');
      expect(GetStdHandle, isA<Function>());
    });
    test('Can instantiate GetSystemDefaultLangID', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemDefaultLangID =
          kernel32.lookupFunction<Uint16 Function(), int Function()>(
              'GetSystemDefaultLangID');
      expect(GetSystemDefaultLangID, isA<Function>());
    });
    test('Can instantiate GetSystemDefaultLocaleName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemDefaultLocaleName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpLocaleName, Int32 cchLocaleName),
          int Function(Pointer<Utf16> lpLocaleName,
              int cchLocaleName)>('GetSystemDefaultLocaleName');
      expect(GetSystemDefaultLocaleName, isA<Function>());
    });
    test('Can instantiate GetSystemDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemDirectory = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpBuffer, Uint32 uSize),
          int Function(
              Pointer<Utf16> lpBuffer, int uSize)>('GetSystemDirectoryW');
      expect(GetSystemDirectory, isA<Function>());
    });
    test('Can instantiate GetSystemInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemInfo = kernel32.lookupFunction<
          Void Function(Pointer<SYSTEM_INFO> lpSystemInfo),
          void Function(Pointer<SYSTEM_INFO> lpSystemInfo)>('GetSystemInfo');
      expect(GetSystemInfo, isA<Function>());
    });
    test('Can instantiate GetSystemPowerStatus', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemPowerStatus = kernel32.lookupFunction<
              Int32 Function(Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus),
              int Function(Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus)>(
          'GetSystemPowerStatus');
      expect(GetSystemPowerStatus, isA<Function>());
    });
    test('Can instantiate GetSystemTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemTime = kernel32.lookupFunction<
          Void Function(Pointer<SYSTEMTIME> lpSystemTime),
          void Function(Pointer<SYSTEMTIME> lpSystemTime)>('GetSystemTime');
      expect(GetSystemTime, isA<Function>());
    });
    test('Can instantiate GetSystemTimes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetSystemTimes = kernel32.lookupFunction<
          Int32 Function(Pointer<FILETIME> lpIdleTime,
              Pointer<FILETIME> lpKernelTime, Pointer<FILETIME> lpUserTime),
          int Function(
              Pointer<FILETIME> lpIdleTime,
              Pointer<FILETIME> lpKernelTime,
              Pointer<FILETIME> lpUserTime)>('GetSystemTimes');
      expect(GetSystemTimes, isA<Function>());
    });
    test('Can instantiate GetTempFileName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetTempFileName = kernel32.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lpPathName,
              Pointer<Utf16> lpPrefixString,
              Uint32 uUnique,
              Pointer<Utf16> lpTempFileName),
          int Function(Pointer<Utf16> lpPathName, Pointer<Utf16> lpPrefixString,
              int uUnique, Pointer<Utf16> lpTempFileName)>('GetTempFileNameW');
      expect(GetTempFileName, isA<Function>());
    });
    test('Can instantiate GetTempPath', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetTempPath = kernel32.lookupFunction<
          Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
          int Function(
              int nBufferLength, Pointer<Utf16> lpBuffer)>('GetTempPathW');
      expect(GetTempPath, isA<Function>());
    });
    if (windowsBuildNumber >= 20348) {
      test('Can instantiate GetTempPath2', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final GetTempPath2 = kernel32.lookupFunction<
            Uint32 Function(Uint32 BufferLength, Pointer<Utf16> Buffer),
            int Function(
                int BufferLength, Pointer<Utf16> Buffer)>('GetTempPath2W');
        expect(GetTempPath2, isA<Function>());
      });
    }
    test('Can instantiate GetThreadId', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetThreadId = kernel32.lookupFunction<
          Uint32 Function(IntPtr Thread),
          int Function(int Thread)>('GetThreadId');
      expect(GetThreadId, isA<Function>());
    });
    test('Can instantiate GetThreadLocale', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetThreadLocale = kernel32
          .lookupFunction<Uint32 Function(), int Function()>('GetThreadLocale');
      expect(GetThreadLocale, isA<Function>());
    });
    test('Can instantiate GetThreadTimes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetThreadTimes = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hThread,
              Pointer<FILETIME> lpCreationTime,
              Pointer<FILETIME> lpExitTime,
              Pointer<FILETIME> lpKernelTime,
              Pointer<FILETIME> lpUserTime),
          int Function(
              int hThread,
              Pointer<FILETIME> lpCreationTime,
              Pointer<FILETIME> lpExitTime,
              Pointer<FILETIME> lpKernelTime,
              Pointer<FILETIME> lpUserTime)>('GetThreadTimes');
      expect(GetThreadTimes, isA<Function>());
    });
    test('Can instantiate GetThreadUILanguage', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetThreadUILanguage =
          kernel32.lookupFunction<Uint16 Function(), int Function()>(
              'GetThreadUILanguage');
      expect(GetThreadUILanguage, isA<Function>());
    });
    test('Can instantiate GetUserDefaultLangID', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetUserDefaultLangID =
          kernel32.lookupFunction<Uint16 Function(), int Function()>(
              'GetUserDefaultLangID');
      expect(GetUserDefaultLangID, isA<Function>());
    });
    test('Can instantiate GetUserDefaultLCID', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetUserDefaultLCID =
          kernel32.lookupFunction<Uint32 Function(), int Function()>(
              'GetUserDefaultLCID');
      expect(GetUserDefaultLCID, isA<Function>());
    });
    test('Can instantiate GetUserDefaultLocaleName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetUserDefaultLocaleName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpLocaleName, Int32 cchLocaleName),
          int Function(Pointer<Utf16> lpLocaleName,
              int cchLocaleName)>('GetUserDefaultLocaleName');
      expect(GetUserDefaultLocaleName, isA<Function>());
    });
    test('Can instantiate GetVersionEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVersionEx = kernel32.lookupFunction<
          Int32 Function(Pointer<OSVERSIONINFO> lpVersionInformation),
          int Function(
              Pointer<OSVERSIONINFO> lpVersionInformation)>('GetVersionExW');
      expect(GetVersionEx, isA<Function>());
    });
    test('Can instantiate GetVolumeInformation', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVolumeInformation = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpRootPathName,
              Pointer<Utf16> lpVolumeNameBuffer,
              Uint32 nVolumeNameSize,
              Pointer<Uint32> lpVolumeSerialNumber,
              Pointer<Uint32> lpMaximumComponentLength,
              Pointer<Uint32> lpFileSystemFlags,
              Pointer<Utf16> lpFileSystemNameBuffer,
              Uint32 nFileSystemNameSize),
          int Function(
              Pointer<Utf16> lpRootPathName,
              Pointer<Utf16> lpVolumeNameBuffer,
              int nVolumeNameSize,
              Pointer<Uint32> lpVolumeSerialNumber,
              Pointer<Uint32> lpMaximumComponentLength,
              Pointer<Uint32> lpFileSystemFlags,
              Pointer<Utf16> lpFileSystemNameBuffer,
              int nFileSystemNameSize)>('GetVolumeInformationW');
      expect(GetVolumeInformation, isA<Function>());
    });
    test('Can instantiate GetVolumeInformationByHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVolumeInformationByHandle = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer<Utf16> lpVolumeNameBuffer,
              Uint32 nVolumeNameSize,
              Pointer<Uint32> lpVolumeSerialNumber,
              Pointer<Uint32> lpMaximumComponentLength,
              Pointer<Uint32> lpFileSystemFlags,
              Pointer<Utf16> lpFileSystemNameBuffer,
              Uint32 nFileSystemNameSize),
          int Function(
              int hFile,
              Pointer<Utf16> lpVolumeNameBuffer,
              int nVolumeNameSize,
              Pointer<Uint32> lpVolumeSerialNumber,
              Pointer<Uint32> lpMaximumComponentLength,
              Pointer<Uint32> lpFileSystemFlags,
              Pointer<Utf16> lpFileSystemNameBuffer,
              int nFileSystemNameSize)>('GetVolumeInformationByHandleW');
      expect(GetVolumeInformationByHandle, isA<Function>());
    });
    test('Can instantiate GetVolumeNameForVolumeMountPoint', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVolumeNameForVolumeMountPoint = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszVolumeMountPoint,
              Pointer<Utf16> lpszVolumeName, Uint32 cchBufferLength),
          int Function(
              Pointer<Utf16> lpszVolumeMountPoint,
              Pointer<Utf16> lpszVolumeName,
              int cchBufferLength)>('GetVolumeNameForVolumeMountPointW');
      expect(GetVolumeNameForVolumeMountPoint, isA<Function>());
    });
    test('Can instantiate GetVolumePathName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVolumePathName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszFileName,
              Pointer<Utf16> lpszVolumePathName, Uint32 cchBufferLength),
          int Function(
              Pointer<Utf16> lpszFileName,
              Pointer<Utf16> lpszVolumePathName,
              int cchBufferLength)>('GetVolumePathNameW');
      expect(GetVolumePathName, isA<Function>());
    });
    test('Can instantiate GetVolumePathNamesForVolumeName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GetVolumePathNamesForVolumeName = kernel32.lookupFunction<
              Int32 Function(
                  Pointer<Utf16> lpszVolumeName,
                  Pointer<Utf16> lpszVolumePathNames,
                  Uint32 cchBufferLength,
                  Pointer<Uint32> lpcchReturnLength),
              int Function(
                  Pointer<Utf16> lpszVolumeName,
                  Pointer<Utf16> lpszVolumePathNames,
                  int cchBufferLength,
                  Pointer<Uint32> lpcchReturnLength)>(
          'GetVolumePathNamesForVolumeNameW');
      expect(GetVolumePathNamesForVolumeName, isA<Function>());
    });
    test('Can instantiate GlobalAlloc', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GlobalAlloc = kernel32.lookupFunction<
          IntPtr Function(Uint32 uFlags, IntPtr dwBytes),
          int Function(int uFlags, int dwBytes)>('GlobalAlloc');
      expect(GlobalAlloc, isA<Function>());
    });
    test('Can instantiate GlobalFree', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GlobalFree = kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
          int Function(int hMem)>('GlobalFree');
      expect(GlobalFree, isA<Function>());
    });
    test('Can instantiate GlobalLock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GlobalLock = kernel32.lookupFunction<Pointer Function(IntPtr hMem),
          Pointer Function(int hMem)>('GlobalLock');
      expect(GlobalLock, isA<Function>());
    });
    test('Can instantiate GlobalSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GlobalSize = kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
          int Function(int hMem)>('GlobalSize');
      expect(GlobalSize, isA<Function>());
    });
    test('Can instantiate GlobalUnlock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final GlobalUnlock = kernel32.lookupFunction<Int32 Function(IntPtr hMem),
          int Function(int hMem)>('GlobalUnlock');
      expect(GlobalUnlock, isA<Function>());
    });
    test('Can instantiate HeapAlloc', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapAlloc = kernel32.lookupFunction<
          Pointer Function(IntPtr hHeap, Uint32 dwFlags, IntPtr dwBytes),
          Pointer Function(int hHeap, int dwFlags, int dwBytes)>('HeapAlloc');
      expect(HeapAlloc, isA<Function>());
    });
    test('Can instantiate HeapCompact', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapCompact = kernel32.lookupFunction<
          IntPtr Function(IntPtr hHeap, Uint32 dwFlags),
          int Function(int hHeap, int dwFlags)>('HeapCompact');
      expect(HeapCompact, isA<Function>());
    });
    test('Can instantiate HeapCreate', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapCreate = kernel32.lookupFunction<
          IntPtr Function(
              Uint32 flOptions, IntPtr dwInitialSize, IntPtr dwMaximumSize),
          int Function(int flOptions, int dwInitialSize,
              int dwMaximumSize)>('HeapCreate');
      expect(HeapCreate, isA<Function>());
    });
    test('Can instantiate HeapDestroy', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapDestroy = kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
          int Function(int hHeap)>('HeapDestroy');
      expect(HeapDestroy, isA<Function>());
    });
    test('Can instantiate HeapFree', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapFree = kernel32.lookupFunction<
          Int32 Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
          int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapFree');
      expect(HeapFree, isA<Function>());
    });
    test('Can instantiate HeapLock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapLock = kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
          int Function(int hHeap)>('HeapLock');
      expect(HeapLock, isA<Function>());
    });
    test('Can instantiate HeapQueryInformation', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapQueryInformation = kernel32.lookupFunction<
          Int32 Function(
              IntPtr HeapHandle,
              Int32 HeapInformationClass,
              Pointer HeapInformation,
              IntPtr HeapInformationLength,
              Pointer<IntPtr> ReturnLength),
          int Function(
              int HeapHandle,
              int HeapInformationClass,
              Pointer HeapInformation,
              int HeapInformationLength,
              Pointer<IntPtr> ReturnLength)>('HeapQueryInformation');
      expect(HeapQueryInformation, isA<Function>());
    });
    test('Can instantiate HeapReAlloc', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapReAlloc = kernel32.lookupFunction<
          Pointer Function(
              IntPtr hHeap, Uint32 dwFlags, Pointer lpMem, IntPtr dwBytes),
          Pointer Function(int hHeap, int dwFlags, Pointer lpMem,
              int dwBytes)>('HeapReAlloc');
      expect(HeapReAlloc, isA<Function>());
    });
    test('Can instantiate HeapSetInformation', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapSetInformation = kernel32.lookupFunction<
          Int32 Function(IntPtr HeapHandle, Int32 HeapInformationClass,
              Pointer HeapInformation, IntPtr HeapInformationLength),
          int Function(
              int HeapHandle,
              int HeapInformationClass,
              Pointer HeapInformation,
              int HeapInformationLength)>('HeapSetInformation');
      expect(HeapSetInformation, isA<Function>());
    });
    test('Can instantiate HeapSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapSize = kernel32.lookupFunction<
          IntPtr Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
          int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapSize');
      expect(HeapSize, isA<Function>());
    });
    test('Can instantiate HeapUnlock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapUnlock = kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
          int Function(int hHeap)>('HeapUnlock');
      expect(HeapUnlock, isA<Function>());
    });
    test('Can instantiate HeapValidate', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapValidate = kernel32.lookupFunction<
          Int32 Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
          int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapValidate');
      expect(HeapValidate, isA<Function>());
    });
    test('Can instantiate HeapWalk', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final HeapWalk = kernel32.lookupFunction<
          Int32 Function(IntPtr hHeap, Pointer<PROCESS_HEAP_ENTRY> lpEntry),
          int Function(
              int hHeap, Pointer<PROCESS_HEAP_ENTRY> lpEntry)>('HeapWalk');
      expect(HeapWalk, isA<Function>());
    });
    test('Can instantiate InitializeProcThreadAttributeList', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final InitializeProcThreadAttributeList = kernel32.lookupFunction<
          Int32 Function(Pointer lpAttributeList, Uint32 dwAttributeCount,
              Uint32 dwFlags, Pointer<IntPtr> lpSize),
          int Function(
              Pointer lpAttributeList,
              int dwAttributeCount,
              int dwFlags,
              Pointer<IntPtr> lpSize)>('InitializeProcThreadAttributeList');
      expect(InitializeProcThreadAttributeList, isA<Function>());
    });
    test('Can instantiate IsDebuggerPresent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final IsDebuggerPresent =
          kernel32.lookupFunction<Int32 Function(), int Function()>(
              'IsDebuggerPresent');
      expect(IsDebuggerPresent, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate IsNativeVhdBoot', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final IsNativeVhdBoot = kernel32.lookupFunction<
            Int32 Function(Pointer<Int32> NativeVhdBoot),
            int Function(Pointer<Int32> NativeVhdBoot)>('IsNativeVhdBoot');
        expect(IsNativeVhdBoot, isA<Function>());
      });
    }
    test('Can instantiate IsSystemResumeAutomatic', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final IsSystemResumeAutomatic =
          kernel32.lookupFunction<Int32 Function(), int Function()>(
              'IsSystemResumeAutomatic');
      expect(IsSystemResumeAutomatic, isA<Function>());
    });
    test('Can instantiate IsValidLocaleName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final IsValidLocaleName = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpLocaleName),
          int Function(Pointer<Utf16> lpLocaleName)>('IsValidLocaleName');
      expect(IsValidLocaleName, isA<Function>());
    });
    if (windowsBuildNumber >= 16299) {
      test('Can instantiate IsWow64Process2', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final IsWow64Process2 = kernel32.lookupFunction<
            Int32 Function(IntPtr hProcess, Pointer<Uint16> pProcessMachine,
                Pointer<Uint16> pNativeMachine),
            int Function(int hProcess, Pointer<Uint16> pProcessMachine,
                Pointer<Uint16> pNativeMachine)>('IsWow64Process2');
        expect(IsWow64Process2, isA<Function>());
      });
    }
    test('Can instantiate LoadLibrary', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LoadLibrary = kernel32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpLibFileName),
          int Function(Pointer<Utf16> lpLibFileName)>('LoadLibraryW');
      expect(LoadLibrary, isA<Function>());
    });
    test('Can instantiate LoadLibraryEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LoadLibraryEx = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpLibFileName, IntPtr hFile, Uint32 dwFlags),
          int Function(Pointer<Utf16> lpLibFileName, int hFile,
              int dwFlags)>('LoadLibraryExW');
      expect(LoadLibraryEx, isA<Function>());
    });
    test('Can instantiate LoadResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LoadResource = kernel32.lookupFunction<
          IntPtr Function(IntPtr hModule, IntPtr hResInfo),
          int Function(int hModule, int hResInfo)>('LoadResource');
      expect(LoadResource, isA<Function>());
    });
    test('Can instantiate LocalFree', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LocalFree = kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
          int Function(int hMem)>('LocalFree');
      expect(LocalFree, isA<Function>());
    });
    test('Can instantiate LockFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LockFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Uint32 dwFileOffsetLow,
              Uint32 dwFileOffsetHigh,
              Uint32 nNumberOfBytesToLockLow,
              Uint32 nNumberOfBytesToLockHigh),
          int Function(
              int hFile,
              int dwFileOffsetLow,
              int dwFileOffsetHigh,
              int nNumberOfBytesToLockLow,
              int nNumberOfBytesToLockHigh)>('LockFile');
      expect(LockFile, isA<Function>());
    });
    test('Can instantiate LockFileEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LockFileEx = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Uint32 dwFlags,
              Uint32 dwReserved,
              Uint32 nNumberOfBytesToLockLow,
              Uint32 nNumberOfBytesToLockHigh,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              int dwFlags,
              int dwReserved,
              int nNumberOfBytesToLockLow,
              int nNumberOfBytesToLockHigh,
              Pointer<OVERLAPPED> lpOverlapped)>('LockFileEx');
      expect(LockFileEx, isA<Function>());
    });
    test('Can instantiate LockResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final LockResource = kernel32.lookupFunction<
          Pointer Function(IntPtr hResData),
          Pointer Function(int hResData)>('LockResource');
      expect(LockResource, isA<Function>());
    });
    test('Can instantiate MoveFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final MoveFile = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpExistingFileName, Pointer<Utf16> lpNewFileName),
          int Function(Pointer<Utf16> lpExistingFileName,
              Pointer<Utf16> lpNewFileName)>('MoveFileW');
      expect(MoveFile, isA<Function>());
    });
    test('Can instantiate OpenEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final OpenEvent = kernel32.lookupFunction<
          IntPtr Function(Uint32 dwDesiredAccess, Int32 bInheritHandle,
              Pointer<Utf16> lpName),
          int Function(int dwDesiredAccess, int bInheritHandle,
              Pointer<Utf16> lpName)>('OpenEventW');
      expect(OpenEvent, isA<Function>());
    });
    test('Can instantiate OpenProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final OpenProcess = kernel32.lookupFunction<
          IntPtr Function(
              Uint32 dwDesiredAccess, Int32 bInheritHandle, Uint32 dwProcessId),
          int Function(int dwDesiredAccess, int bInheritHandle,
              int dwProcessId)>('OpenProcess');
      expect(OpenProcess, isA<Function>());
    });
    test('Can instantiate OutputDebugString', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final OutputDebugString = kernel32.lookupFunction<
          Void Function(Pointer<Utf16> lpOutputString),
          void Function(Pointer<Utf16> lpOutputString)>('OutputDebugStringW');
      expect(OutputDebugString, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate PackageFamilyNameFromFullName', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final PackageFamilyNameFromFullName = kernel32.lookupFunction<
                Uint32 Function(
                    Pointer<Utf16> packageFullName,
                    Pointer<Uint32> packageFamilyNameLength,
                    Pointer<Utf16> packageFamilyName),
                int Function(
                    Pointer<Utf16> packageFullName,
                    Pointer<Uint32> packageFamilyNameLength,
                    Pointer<Utf16> packageFamilyName)>(
            'PackageFamilyNameFromFullName');
        expect(PackageFamilyNameFromFullName, isA<Function>());
      });
    }
    test('Can instantiate PeekConsoleInput', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final PeekConsoleInput = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
              Uint32 nLength, Pointer<Uint32> lpNumberOfEventsRead),
          int Function(
              int hConsoleInput,
              Pointer<INPUT_RECORD> lpBuffer,
              int nLength,
              Pointer<Uint32> lpNumberOfEventsRead)>('PeekConsoleInputW');
      expect(PeekConsoleInput, isA<Function>());
    });
    test('Can instantiate PeekNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final PeekNamedPipe = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hNamedPipe,
              Pointer lpBuffer,
              Uint32 nBufferSize,
              Pointer<Uint32> lpBytesRead,
              Pointer<Uint32> lpTotalBytesAvail,
              Pointer<Uint32> lpBytesLeftThisMessage),
          int Function(
              int hNamedPipe,
              Pointer lpBuffer,
              int nBufferSize,
              Pointer<Uint32> lpBytesRead,
              Pointer<Uint32> lpTotalBytesAvail,
              Pointer<Uint32> lpBytesLeftThisMessage)>('PeekNamedPipe');
      expect(PeekNamedPipe, isA<Function>());
    });
    test('Can instantiate PostQueuedCompletionStatus', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final PostQueuedCompletionStatus = kernel32.lookupFunction<
          Int32 Function(
              IntPtr CompletionPort,
              Uint32 dwNumberOfBytesTransferred,
              IntPtr dwCompletionKey,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int CompletionPort,
              int dwNumberOfBytesTransferred,
              int dwCompletionKey,
              Pointer<OVERLAPPED> lpOverlapped)>('PostQueuedCompletionStatus');
      expect(PostQueuedCompletionStatus, isA<Function>());
    });
    test('Can instantiate PurgeComm', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final PurgeComm = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Uint32 dwFlags),
          int Function(int hFile, int dwFlags)>('PurgeComm');
      expect(PurgeComm, isA<Function>());
    });
    test('Can instantiate QueryDosDevice', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final QueryDosDevice = kernel32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpDeviceName,
              Pointer<Utf16> lpTargetPath, Uint32 ucchMax),
          int Function(Pointer<Utf16> lpDeviceName, Pointer<Utf16> lpTargetPath,
              int ucchMax)>('QueryDosDeviceW');
      expect(QueryDosDevice, isA<Function>());
    });
    test('Can instantiate QueryPerformanceCounter', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final QueryPerformanceCounter = kernel32.lookupFunction<
          Int32 Function(Pointer<Int64> lpPerformanceCount),
          int Function(
              Pointer<Int64> lpPerformanceCount)>('QueryPerformanceCounter');
      expect(QueryPerformanceCounter, isA<Function>());
    });
    test('Can instantiate QueryPerformanceFrequency', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final QueryPerformanceFrequency = kernel32.lookupFunction<
          Int32 Function(Pointer<Int64> lpFrequency),
          int Function(
              Pointer<Int64> lpFrequency)>('QueryPerformanceFrequency');
      expect(QueryPerformanceFrequency, isA<Function>());
    });
    test('Can instantiate ReadConsole', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadConsole = kernel32.lookupFunction<
              Int32 Function(
                  IntPtr hConsoleInput,
                  Pointer lpBuffer,
                  Uint32 nNumberOfCharsToRead,
                  Pointer<Uint32> lpNumberOfCharsRead,
                  Pointer<CONSOLE_READCONSOLE_CONTROL> pInputControl),
              int Function(
                  int hConsoleInput,
                  Pointer lpBuffer,
                  int nNumberOfCharsToRead,
                  Pointer<Uint32> lpNumberOfCharsRead,
                  Pointer<CONSOLE_READCONSOLE_CONTROL> pInputControl)>(
          'ReadConsoleW');
      expect(ReadConsole, isA<Function>());
    });
    test('Can instantiate ReadConsoleInput', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadConsoleInput = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
              Uint32 nLength, Pointer<Uint32> lpNumberOfEventsRead),
          int Function(
              int hConsoleInput,
              Pointer<INPUT_RECORD> lpBuffer,
              int nLength,
              Pointer<Uint32> lpNumberOfEventsRead)>('ReadConsoleInputW');
      expect(ReadConsoleInput, isA<Function>());
    });
    test('Can instantiate ReadFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer lpBuffer,
              Uint32 nNumberOfBytesToRead,
              Pointer<Uint32> lpNumberOfBytesRead,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              Pointer lpBuffer,
              int nNumberOfBytesToRead,
              Pointer<Uint32> lpNumberOfBytesRead,
              Pointer<OVERLAPPED> lpOverlapped)>('ReadFile');
      expect(ReadFile, isA<Function>());
    });
    test('Can instantiate ReadFileEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadFileEx = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer lpBuffer,
              Uint32 nNumberOfBytesToRead,
              Pointer<OVERLAPPED> lpOverlapped,
              Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
                  lpCompletionRoutine),
          int Function(
              int hFile,
              Pointer lpBuffer,
              int nNumberOfBytesToRead,
              Pointer<OVERLAPPED> lpOverlapped,
              Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
                  lpCompletionRoutine)>('ReadFileEx');
      expect(ReadFileEx, isA<Function>());
    });
    test('Can instantiate ReadFileScatter', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadFileScatter = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
              Uint32 nNumberOfBytesToRead,
              Pointer<Uint32> lpReserved,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
              int nNumberOfBytesToRead,
              Pointer<Uint32> lpReserved,
              Pointer<OVERLAPPED> lpOverlapped)>('ReadFileScatter');
      expect(ReadFileScatter, isA<Function>());
    });
    test('Can instantiate ReadProcessMemory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReadProcessMemory = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hProcess,
              Pointer lpBaseAddress,
              Pointer lpBuffer,
              IntPtr nSize,
              Pointer<IntPtr> lpNumberOfBytesRead),
          int Function(
              int hProcess,
              Pointer lpBaseAddress,
              Pointer lpBuffer,
              int nSize,
              Pointer<IntPtr> lpNumberOfBytesRead)>('ReadProcessMemory');
      expect(ReadProcessMemory, isA<Function>());
    });
    test('Can instantiate ReleaseActCtx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReleaseActCtx = kernel32.lookupFunction<
          Void Function(IntPtr hActCtx),
          void Function(int hActCtx)>('ReleaseActCtx');
      expect(ReleaseActCtx, isA<Function>());
    });
    test('Can instantiate RemoveDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final RemoveDirectory = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpPathName),
          int Function(Pointer<Utf16> lpPathName)>('RemoveDirectoryW');
      expect(RemoveDirectory, isA<Function>());
    });
    test('Can instantiate RemoveDllDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final RemoveDllDirectory = kernel32.lookupFunction<
          Int32 Function(Pointer Cookie),
          int Function(Pointer Cookie)>('RemoveDllDirectory');
      expect(RemoveDllDirectory, isA<Function>());
    });
    test('Can instantiate ReOpenFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ReOpenFile = kernel32.lookupFunction<
          IntPtr Function(IntPtr hOriginalFile, Uint32 dwDesiredAccess,
              Uint32 dwShareMode, Uint32 dwFlagsAndAttributes),
          int Function(int hOriginalFile, int dwDesiredAccess, int dwShareMode,
              int dwFlagsAndAttributes)>('ReOpenFile');
      expect(ReOpenFile, isA<Function>());
    });
    test('Can instantiate ResetEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ResetEvent = kernel32.lookupFunction<Int32 Function(IntPtr hEvent),
          int Function(int hEvent)>('ResetEvent');
      expect(ResetEvent, isA<Function>());
    });
    if (windowsBuildNumber >= 17763) {
      test('Can instantiate ResizePseudoConsole', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final ResizePseudoConsole = kernel32.lookupFunction<
            Int32 Function(IntPtr hPC, COORD size),
            int Function(int hPC, COORD size)>('ResizePseudoConsole');
        expect(ResizePseudoConsole, isA<Function>());
      });
    }
    test('Can instantiate ScrollConsoleScreenBuffer', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final ScrollConsoleScreenBuffer = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hConsoleOutput,
              Pointer<SMALL_RECT> lpScrollRectangle,
              Pointer<SMALL_RECT> lpClipRectangle,
              COORD dwDestinationOrigin,
              Pointer<CHAR_INFO> lpFill),
          int Function(
              int hConsoleOutput,
              Pointer<SMALL_RECT> lpScrollRectangle,
              Pointer<SMALL_RECT> lpClipRectangle,
              COORD dwDestinationOrigin,
              Pointer<CHAR_INFO> lpFill)>('ScrollConsoleScreenBufferW');
      expect(ScrollConsoleScreenBuffer, isA<Function>());
    });
    test('Can instantiate SetCommBreak', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCommBreak = kernel32.lookupFunction<Int32 Function(IntPtr hFile),
          int Function(int hFile)>('SetCommBreak');
      expect(SetCommBreak, isA<Function>());
    });
    test('Can instantiate SetCommConfig', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCommConfig = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hCommDev, Pointer<COMMCONFIG> lpCC, Uint32 dwSize),
          int Function(int hCommDev, Pointer<COMMCONFIG> lpCC,
              int dwSize)>('SetCommConfig');
      expect(SetCommConfig, isA<Function>());
    });
    test('Can instantiate SetCommMask', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCommMask = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Uint32 dwEvtMask),
          int Function(int hFile, int dwEvtMask)>('SetCommMask');
      expect(SetCommMask, isA<Function>());
    });
    test('Can instantiate SetCommState', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCommState = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB),
          int Function(int hFile, Pointer<DCB> lpDCB)>('SetCommState');
      expect(SetCommState, isA<Function>());
    });
    test('Can instantiate SetCommTimeouts', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCommTimeouts = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts),
          int Function(int hFile,
              Pointer<COMMTIMEOUTS> lpCommTimeouts)>('SetCommTimeouts');
      expect(SetCommTimeouts, isA<Function>());
    });
    test('Can instantiate SetConsoleCtrlHandler', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleCtrlHandler = kernel32.lookupFunction<
          Int32 Function(Pointer<NativeFunction<HandlerRoutine>> HandlerRoutine,
              Int32 Add),
          int Function(Pointer<NativeFunction<HandlerRoutine>> HandlerRoutine,
              int Add)>('SetConsoleCtrlHandler');
      expect(SetConsoleCtrlHandler, isA<Function>());
    });
    test('Can instantiate SetConsoleCursorInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleCursorInfo = kernel32.lookupFunction<
              Int32 Function(IntPtr hConsoleOutput,
                  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo),
              int Function(int hConsoleOutput,
                  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo)>(
          'SetConsoleCursorInfo');
      expect(SetConsoleCursorInfo, isA<Function>());
    });
    test('Can instantiate SetConsoleCursorPosition', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleCursorPosition = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleOutput, COORD dwCursorPosition),
          int Function(int hConsoleOutput,
              COORD dwCursorPosition)>('SetConsoleCursorPosition');
      expect(SetConsoleCursorPosition, isA<Function>());
    });
    test('Can instantiate SetConsoleDisplayMode', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleDisplayMode = kernel32.lookupFunction<
              Int32 Function(IntPtr hConsoleOutput, Uint32 dwFlags,
                  Pointer<COORD> lpNewScreenBufferDimensions),
              int Function(int hConsoleOutput, int dwFlags,
                  Pointer<COORD> lpNewScreenBufferDimensions)>(
          'SetConsoleDisplayMode');
      expect(SetConsoleDisplayMode, isA<Function>());
    });
    test('Can instantiate SetConsoleMode', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleMode = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleHandle, Uint32 dwMode),
          int Function(int hConsoleHandle, int dwMode)>('SetConsoleMode');
      expect(SetConsoleMode, isA<Function>());
    });
    test('Can instantiate SetConsoleTextAttribute', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleTextAttribute = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleOutput, Uint16 wAttributes),
          int Function(
              int hConsoleOutput, int wAttributes)>('SetConsoleTextAttribute');
      expect(SetConsoleTextAttribute, isA<Function>());
    });
    test('Can instantiate SetConsoleWindowInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetConsoleWindowInfo = kernel32.lookupFunction<
          Int32 Function(IntPtr hConsoleOutput, Int32 bAbsolute,
              Pointer<SMALL_RECT> lpConsoleWindow),
          int Function(int hConsoleOutput, int bAbsolute,
              Pointer<SMALL_RECT> lpConsoleWindow)>('SetConsoleWindowInfo');
      expect(SetConsoleWindowInfo, isA<Function>());
    });
    test('Can instantiate SetCurrentDirectory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetCurrentDirectory = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpPathName),
          int Function(Pointer<Utf16> lpPathName)>('SetCurrentDirectoryW');
      expect(SetCurrentDirectory, isA<Function>());
    });
    test('Can instantiate SetDefaultCommConfig', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetDefaultCommConfig = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC, Uint32 dwSize),
          int Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
              int dwSize)>('SetDefaultCommConfigW');
      expect(SetDefaultCommConfig, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SetDefaultDllDirectories', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final SetDefaultDllDirectories = kernel32.lookupFunction<
            Int32 Function(Uint32 DirectoryFlags),
            int Function(int DirectoryFlags)>('SetDefaultDllDirectories');
        expect(SetDefaultDllDirectories, isA<Function>());
      });
    }
    test('Can instantiate SetEndOfFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetEndOfFile = kernel32.lookupFunction<Int32 Function(IntPtr hFile),
          int Function(int hFile)>('SetEndOfFile');
      expect(SetEndOfFile, isA<Function>());
    });
    test('Can instantiate SetEnvironmentVariable', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetEnvironmentVariable = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue),
          int Function(Pointer<Utf16> lpName,
              Pointer<Utf16> lpValue)>('SetEnvironmentVariableW');
      expect(SetEnvironmentVariable, isA<Function>());
    });
    test('Can instantiate SetErrorMode', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetErrorMode = kernel32.lookupFunction<
          Uint32 Function(Uint32 uMode),
          int Function(int uMode)>('SetErrorMode');
      expect(SetErrorMode, isA<Function>());
    });
    test('Can instantiate SetEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetEvent = kernel32.lookupFunction<Int32 Function(IntPtr hEvent),
          int Function(int hEvent)>('SetEvent');
      expect(SetEvent, isA<Function>());
    });
    test('Can instantiate SetFileApisToANSI', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileApisToANSI =
          kernel32.lookupFunction<Void Function(), void Function()>(
              'SetFileApisToANSI');
      expect(SetFileApisToANSI, isA<Function>());
    });
    test('Can instantiate SetFileApisToOEM', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileApisToOEM = kernel32
          .lookupFunction<Void Function(), void Function()>('SetFileApisToOEM');
      expect(SetFileApisToOEM, isA<Function>());
    });
    test('Can instantiate SetFileAttributes', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileAttributes = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName, Uint32 dwFileAttributes),
          int Function(Pointer<Utf16> lpFileName,
              int dwFileAttributes)>('SetFileAttributesW');
      expect(SetFileAttributes, isA<Function>());
    });
    test('Can instantiate SetFileInformationByHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileInformationByHandle = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Int32 FileInformationClass,
              Pointer lpFileInformation, Uint32 dwBufferSize),
          int Function(
              int hFile,
              int FileInformationClass,
              Pointer lpFileInformation,
              int dwBufferSize)>('SetFileInformationByHandle');
      expect(SetFileInformationByHandle, isA<Function>());
    });
    test('Can instantiate SetFileIoOverlappedRange', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileIoOverlappedRange = kernel32.lookupFunction<
          Int32 Function(IntPtr FileHandle, Pointer<Uint8> OverlappedRangeStart,
              Uint32 Length),
          int Function(int FileHandle, Pointer<Uint8> OverlappedRangeStart,
              int Length)>('SetFileIoOverlappedRange');
      expect(SetFileIoOverlappedRange, isA<Function>());
    });
    test('Can instantiate SetFilePointer', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFilePointer = kernel32.lookupFunction<
          Uint32 Function(IntPtr hFile, Int32 lDistanceToMove,
              Pointer<Int32> lpDistanceToMoveHigh, Uint32 dwMoveMethod),
          int Function(
              int hFile,
              int lDistanceToMove,
              Pointer<Int32> lpDistanceToMoveHigh,
              int dwMoveMethod)>('SetFilePointer');
      expect(SetFilePointer, isA<Function>());
    });
    test('Can instantiate SetFilePointerEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFilePointerEx = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Int64 liDistanceToMove,
              Pointer<Int64> lpNewFilePointer, Uint32 dwMoveMethod),
          int Function(
              int hFile,
              int liDistanceToMove,
              Pointer<Int64> lpNewFilePointer,
              int dwMoveMethod)>('SetFilePointerEx');
      expect(SetFilePointerEx, isA<Function>());
    });
    test('Can instantiate SetFileShortName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileShortName = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<Utf16> lpShortName),
          int Function(
              int hFile, Pointer<Utf16> lpShortName)>('SetFileShortNameW');
      expect(SetFileShortName, isA<Function>());
    });
    test('Can instantiate SetFileValidData', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFileValidData = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Int64 ValidDataLength),
          int Function(int hFile, int ValidDataLength)>('SetFileValidData');
      expect(SetFileValidData, isA<Function>());
    });
    test('Can instantiate SetFirmwareEnvironmentVariable', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetFirmwareEnvironmentVariable = kernel32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid,
              Pointer pValue, Uint32 nSize),
          int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid,
              Pointer pValue, int nSize)>('SetFirmwareEnvironmentVariableW');
      expect(SetFirmwareEnvironmentVariable, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SetFirmwareEnvironmentVariableEx', () {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final SetFirmwareEnvironmentVariableEx = kernel32.lookupFunction<
            Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid,
                Pointer pValue, Uint32 nSize, Uint32 dwAttributes),
            int Function(
                Pointer<Utf16> lpName,
                Pointer<Utf16> lpGuid,
                Pointer pValue,
                int nSize,
                int dwAttributes)>('SetFirmwareEnvironmentVariableExW');
        expect(SetFirmwareEnvironmentVariableEx, isA<Function>());
      });
    }
    test('Can instantiate SetHandleInformation', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetHandleInformation = kernel32.lookupFunction<
          Int32 Function(IntPtr hObject, Uint32 dwMask, Uint32 dwFlags),
          int Function(
              int hObject, int dwMask, int dwFlags)>('SetHandleInformation');
      expect(SetHandleInformation, isA<Function>());
    });
    test('Can instantiate SetNamedPipeHandleState', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetNamedPipeHandleState = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hNamedPipe,
              Pointer<Uint32> lpMode,
              Pointer<Uint32> lpMaxCollectionCount,
              Pointer<Uint32> lpCollectDataTimeout),
          int Function(
              int hNamedPipe,
              Pointer<Uint32> lpMode,
              Pointer<Uint32> lpMaxCollectionCount,
              Pointer<Uint32> lpCollectDataTimeout)>('SetNamedPipeHandleState');
      expect(SetNamedPipeHandleState, isA<Function>());
    });
    test('Can instantiate SetProcessAffinityMask', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetProcessAffinityMask = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, IntPtr dwProcessAffinityMask),
          int Function(int hProcess,
              int dwProcessAffinityMask)>('SetProcessAffinityMask');
      expect(SetProcessAffinityMask, isA<Function>());
    });
    test('Can instantiate SetProcessPriorityBoost', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetProcessPriorityBoost = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Int32 bDisablePriorityBoost),
          int Function(int hProcess,
              int bDisablePriorityBoost)>('SetProcessPriorityBoost');
      expect(SetProcessPriorityBoost, isA<Function>());
    });
    test('Can instantiate SetProcessWorkingSetSize', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetProcessWorkingSetSize = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize,
              IntPtr dwMaximumWorkingSetSize),
          int Function(int hProcess, int dwMinimumWorkingSetSize,
              int dwMaximumWorkingSetSize)>('SetProcessWorkingSetSize');
      expect(SetProcessWorkingSetSize, isA<Function>());
    });
    test('Can instantiate SetStdHandle', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetStdHandle = kernel32.lookupFunction<
          Int32 Function(Uint32 nStdHandle, IntPtr hHandle),
          int Function(int nStdHandle, int hHandle)>('SetStdHandle');
      expect(SetStdHandle, isA<Function>());
    });
    test('Can instantiate SetThreadAffinityMask', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetThreadAffinityMask = kernel32.lookupFunction<
          IntPtr Function(IntPtr hThread, IntPtr dwThreadAffinityMask),
          int Function(
              int hThread, int dwThreadAffinityMask)>('SetThreadAffinityMask');
      expect(SetThreadAffinityMask, isA<Function>());
    });
    test('Can instantiate SetThreadErrorMode', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetThreadErrorMode = kernel32.lookupFunction<
          Int32 Function(Uint32 dwNewMode, Pointer<Uint32> lpOldMode),
          int Function(
              int dwNewMode, Pointer<Uint32> lpOldMode)>('SetThreadErrorMode');
      expect(SetThreadErrorMode, isA<Function>());
    });
    test('Can instantiate SetThreadExecutionState', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetThreadExecutionState = kernel32.lookupFunction<
          Uint32 Function(Uint32 esFlags),
          int Function(int esFlags)>('SetThreadExecutionState');
      expect(SetThreadExecutionState, isA<Function>());
    });
    test('Can instantiate SetThreadUILanguage', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetThreadUILanguage = kernel32.lookupFunction<
          Uint16 Function(Uint16 LangId),
          int Function(int LangId)>('SetThreadUILanguage');
      expect(SetThreadUILanguage, isA<Function>());
    });
    test('Can instantiate SetupComm', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetupComm = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Uint32 dwInQueue, Uint32 dwOutQueue),
          int Function(int hFile, int dwInQueue, int dwOutQueue)>('SetupComm');
      expect(SetupComm, isA<Function>());
    });
    test('Can instantiate SetVolumeLabel', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SetVolumeLabel = kernel32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpRootPathName, Pointer<Utf16> lpVolumeName),
          int Function(Pointer<Utf16> lpRootPathName,
              Pointer<Utf16> lpVolumeName)>('SetVolumeLabelW');
      expect(SetVolumeLabel, isA<Function>());
    });
    test('Can instantiate SizeofResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SizeofResource = kernel32.lookupFunction<
          Uint32 Function(IntPtr hModule, IntPtr hResInfo),
          int Function(int hModule, int hResInfo)>('SizeofResource');
      expect(SizeofResource, isA<Function>());
    });
    test('Can instantiate Sleep', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final Sleep = kernel32.lookupFunction<
          Void Function(Uint32 dwMilliseconds),
          void Function(int dwMilliseconds)>('Sleep');
      expect(Sleep, isA<Function>());
    });
    test('Can instantiate SleepEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SleepEx = kernel32.lookupFunction<
          Uint32 Function(Uint32 dwMilliseconds, Int32 bAlertable),
          int Function(int dwMilliseconds, int bAlertable)>('SleepEx');
      expect(SleepEx, isA<Function>());
    });
    test('Can instantiate SystemTimeToFileTime', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final SystemTimeToFileTime = kernel32.lookupFunction<
          Int32 Function(
              Pointer<SYSTEMTIME> lpSystemTime, Pointer<FILETIME> lpFileTime),
          int Function(Pointer<SYSTEMTIME> lpSystemTime,
              Pointer<FILETIME> lpFileTime)>('SystemTimeToFileTime');
      expect(SystemTimeToFileTime, isA<Function>());
    });
    test('Can instantiate TerminateProcess', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final TerminateProcess = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint32 uExitCode),
          int Function(int hProcess, int uExitCode)>('TerminateProcess');
      expect(TerminateProcess, isA<Function>());
    });
    test('Can instantiate TerminateThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final TerminateThread = kernel32.lookupFunction<
          Int32 Function(IntPtr hThread, Uint32 dwExitCode),
          int Function(int hThread, int dwExitCode)>('TerminateThread');
      expect(TerminateThread, isA<Function>());
    });
    test('Can instantiate TransactNamedPipe', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final TransactNamedPipe = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hNamedPipe,
              Pointer lpInBuffer,
              Uint32 nInBufferSize,
              Pointer lpOutBuffer,
              Uint32 nOutBufferSize,
              Pointer<Uint32> lpBytesRead,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hNamedPipe,
              Pointer lpInBuffer,
              int nInBufferSize,
              Pointer lpOutBuffer,
              int nOutBufferSize,
              Pointer<Uint32> lpBytesRead,
              Pointer<OVERLAPPED> lpOverlapped)>('TransactNamedPipe');
      expect(TransactNamedPipe, isA<Function>());
    });
    test('Can instantiate TransmitCommChar', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final TransmitCommChar = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Uint8 cChar),
          int Function(int hFile, int cChar)>('TransmitCommChar');
      expect(TransmitCommChar, isA<Function>());
    });
    test('Can instantiate UnlockFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final UnlockFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Uint32 dwFileOffsetLow,
              Uint32 dwFileOffsetHigh,
              Uint32 nNumberOfBytesToUnlockLow,
              Uint32 nNumberOfBytesToUnlockHigh),
          int Function(
              int hFile,
              int dwFileOffsetLow,
              int dwFileOffsetHigh,
              int nNumberOfBytesToUnlockLow,
              int nNumberOfBytesToUnlockHigh)>('UnlockFile');
      expect(UnlockFile, isA<Function>());
    });
    test('Can instantiate UnlockFileEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final UnlockFileEx = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Uint32 dwReserved,
              Uint32 nNumberOfBytesToUnlockLow,
              Uint32 nNumberOfBytesToUnlockHigh,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              int dwReserved,
              int nNumberOfBytesToUnlockLow,
              int nNumberOfBytesToUnlockHigh,
              Pointer<OVERLAPPED> lpOverlapped)>('UnlockFileEx');
      expect(UnlockFileEx, isA<Function>());
    });
    test('Can instantiate UpdateProcThreadAttribute', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final UpdateProcThreadAttribute = kernel32.lookupFunction<
          Int32 Function(
              Pointer lpAttributeList,
              Uint32 dwFlags,
              IntPtr Attribute,
              Pointer lpValue,
              IntPtr cbSize,
              Pointer lpPreviousValue,
              Pointer<IntPtr> lpReturnSize),
          int Function(
              Pointer lpAttributeList,
              int dwFlags,
              int Attribute,
              Pointer lpValue,
              int cbSize,
              Pointer lpPreviousValue,
              Pointer<IntPtr> lpReturnSize)>('UpdateProcThreadAttribute');
      expect(UpdateProcThreadAttribute, isA<Function>());
    });
    test('Can instantiate UpdateResource', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final UpdateResource = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hUpdate,
              Pointer<Utf16> lpType,
              Pointer<Utf16> lpName,
              Uint16 wLanguage,
              Pointer lpData,
              Uint32 cb),
          int Function(
              int hUpdate,
              Pointer<Utf16> lpType,
              Pointer<Utf16> lpName,
              int wLanguage,
              Pointer lpData,
              int cb)>('UpdateResourceW');
      expect(UpdateResource, isA<Function>());
    });
    test('Can instantiate VerifyVersionInfo', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VerifyVersionInfo = kernel32.lookupFunction<
          Int32 Function(Pointer<OSVERSIONINFOEX> lpVersionInformation,
              Uint32 dwTypeMask, Uint64 dwlConditionMask),
          int Function(Pointer<OSVERSIONINFOEX> lpVersionInformation,
              int dwTypeMask, int dwlConditionMask)>('VerifyVersionInfoW');
      expect(VerifyVersionInfo, isA<Function>());
    });
    test('Can instantiate VerLanguageName', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VerLanguageName = kernel32.lookupFunction<
          Uint32 Function(Uint32 wLang, Pointer<Utf16> szLang, Uint32 cchLang),
          int Function(int wLang, Pointer<Utf16> szLang,
              int cchLang)>('VerLanguageNameW');
      expect(VerLanguageName, isA<Function>());
    });
    test('Can instantiate VerSetConditionMask', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VerSetConditionMask = kernel32.lookupFunction<
          Uint64 Function(
              Uint64 ConditionMask, Uint32 TypeMask, Uint8 Condition),
          int Function(int ConditionMask, int TypeMask,
              int Condition)>('VerSetConditionMask');
      expect(VerSetConditionMask, isA<Function>());
    });
    test('Can instantiate VirtualAlloc', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualAlloc = kernel32.lookupFunction<
          Pointer Function(Pointer lpAddress, IntPtr dwSize,
              Uint32 flAllocationType, Uint32 flProtect),
          Pointer Function(Pointer lpAddress, int dwSize, int flAllocationType,
              int flProtect)>('VirtualAlloc');
      expect(VirtualAlloc, isA<Function>());
    });
    test('Can instantiate VirtualAllocEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualAllocEx = kernel32.lookupFunction<
          Pointer Function(IntPtr hProcess, Pointer lpAddress, IntPtr dwSize,
              Uint32 flAllocationType, Uint32 flProtect),
          Pointer Function(int hProcess, Pointer lpAddress, int dwSize,
              int flAllocationType, int flProtect)>('VirtualAllocEx');
      expect(VirtualAllocEx, isA<Function>());
    });
    test('Can instantiate VirtualFree', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualFree = kernel32.lookupFunction<
          Int32 Function(Pointer lpAddress, IntPtr dwSize, Uint32 dwFreeType),
          int Function(
              Pointer lpAddress, int dwSize, int dwFreeType)>('VirtualFree');
      expect(VirtualFree, isA<Function>());
    });
    test('Can instantiate VirtualFreeEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualFreeEx = kernel32.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer lpAddress, IntPtr dwSize,
              Uint32 dwFreeType),
          int Function(int hProcess, Pointer lpAddress, int dwSize,
              int dwFreeType)>('VirtualFreeEx');
      expect(VirtualFreeEx, isA<Function>());
    });
    test('Can instantiate VirtualLock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualLock = kernel32.lookupFunction<
          Int32 Function(Pointer lpAddress, IntPtr dwSize),
          int Function(Pointer lpAddress, int dwSize)>('VirtualLock');
      expect(VirtualLock, isA<Function>());
    });
    test('Can instantiate VirtualUnlock', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final VirtualUnlock = kernel32.lookupFunction<
          Int32 Function(Pointer lpAddress, IntPtr dwSize),
          int Function(Pointer lpAddress, int dwSize)>('VirtualUnlock');
      expect(VirtualUnlock, isA<Function>());
    });
    test('Can instantiate WaitCommEvent', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WaitCommEvent = kernel32.lookupFunction<
          Int32 Function(IntPtr hFile, Pointer<Uint32> lpEvtMask,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(int hFile, Pointer<Uint32> lpEvtMask,
              Pointer<OVERLAPPED> lpOverlapped)>('WaitCommEvent');
      expect(WaitCommEvent, isA<Function>());
    });
    test('Can instantiate WaitForSingleObject', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WaitForSingleObject = kernel32.lookupFunction<
          Uint32 Function(IntPtr hHandle, Uint32 dwMilliseconds),
          int Function(int hHandle, int dwMilliseconds)>('WaitForSingleObject');
      expect(WaitForSingleObject, isA<Function>());
    });
    test('Can instantiate WideCharToMultiByte', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WideCharToMultiByte = kernel32.lookupFunction<
          Int32 Function(
              Uint32 CodePage,
              Uint32 dwFlags,
              Pointer<Utf16> lpWideCharStr,
              Int32 cchWideChar,
              Pointer<Utf8> lpMultiByteStr,
              Int32 cbMultiByte,
              Pointer<Utf8> lpDefaultChar,
              Pointer<Int32> lpUsedDefaultChar),
          int Function(
              int CodePage,
              int dwFlags,
              Pointer<Utf16> lpWideCharStr,
              int cchWideChar,
              Pointer<Utf8> lpMultiByteStr,
              int cbMultiByte,
              Pointer<Utf8> lpDefaultChar,
              Pointer<Int32> lpUsedDefaultChar)>('WideCharToMultiByte');
      expect(WideCharToMultiByte, isA<Function>());
    });
    test('Can instantiate Wow64SuspendThread', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final Wow64SuspendThread = kernel32.lookupFunction<
          Uint32 Function(IntPtr hThread),
          int Function(int hThread)>('Wow64SuspendThread');
      expect(Wow64SuspendThread, isA<Function>());
    });
    test('Can instantiate WriteConsole', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WriteConsole = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hConsoleOutput,
              Pointer lpBuffer,
              Uint32 nNumberOfCharsToWrite,
              Pointer<Uint32> lpNumberOfCharsWritten,
              Pointer lpReserved),
          int Function(
              int hConsoleOutput,
              Pointer lpBuffer,
              int nNumberOfCharsToWrite,
              Pointer<Uint32> lpNumberOfCharsWritten,
              Pointer lpReserved)>('WriteConsoleW');
      expect(WriteConsole, isA<Function>());
    });
    test('Can instantiate WriteFile', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WriteFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer lpBuffer,
              Uint32 nNumberOfBytesToWrite,
              Pointer<Uint32> lpNumberOfBytesWritten,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              Pointer lpBuffer,
              int nNumberOfBytesToWrite,
              Pointer<Uint32> lpNumberOfBytesWritten,
              Pointer<OVERLAPPED> lpOverlapped)>('WriteFile');
      expect(WriteFile, isA<Function>());
    });
    test('Can instantiate WriteFileEx', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WriteFileEx = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer lpBuffer,
              Uint32 nNumberOfBytesToWrite,
              Pointer<OVERLAPPED> lpOverlapped,
              Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
                  lpCompletionRoutine),
          int Function(
              int hFile,
              Pointer lpBuffer,
              int nNumberOfBytesToWrite,
              Pointer<OVERLAPPED> lpOverlapped,
              Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
                  lpCompletionRoutine)>('WriteFileEx');
      expect(WriteFileEx, isA<Function>());
    });
    test('Can instantiate WriteFileGather', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WriteFileGather = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hFile,
              Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
              Uint32 nNumberOfBytesToWrite,
              Pointer<Uint32> lpReserved,
              Pointer<OVERLAPPED> lpOverlapped),
          int Function(
              int hFile,
              Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
              int nNumberOfBytesToWrite,
              Pointer<Uint32> lpReserved,
              Pointer<OVERLAPPED> lpOverlapped)>('WriteFileGather');
      expect(WriteFileGather, isA<Function>());
    });
    test('Can instantiate WriteProcessMemory', () {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final WriteProcessMemory = kernel32.lookupFunction<
          Int32 Function(
              IntPtr hProcess,
              Pointer lpBaseAddress,
              Pointer lpBuffer,
              IntPtr nSize,
              Pointer<IntPtr> lpNumberOfBytesWritten),
          int Function(
              int hProcess,
              Pointer lpBaseAddress,
              Pointer lpBuffer,
              int nSize,
              Pointer<IntPtr> lpNumberOfBytesWritten)>('WriteProcessMemory');
      expect(WriteProcessMemory, isA<Function>());
    });
  });

  group('Test user32 functions', () {
    test('Can instantiate ActivateKeyboardLayout', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ActivateKeyboardLayout = user32.lookupFunction<
          IntPtr Function(IntPtr hkl, Uint32 Flags),
          int Function(int hkl, int Flags)>('ActivateKeyboardLayout');
      expect(ActivateKeyboardLayout, isA<Function>());
    });
    test('Can instantiate AddClipboardFormatListener', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AddClipboardFormatListener = user32.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('AddClipboardFormatListener');
      expect(AddClipboardFormatListener, isA<Function>());
    });
    test('Can instantiate AdjustWindowRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AdjustWindowRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu),
          int Function(Pointer<RECT> lpRect, int dwStyle,
              int bMenu)>('AdjustWindowRect');
      expect(AdjustWindowRect, isA<Function>());
    });
    test('Can instantiate AdjustWindowRectEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AdjustWindowRectEx = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu,
              Uint32 dwExStyle),
          int Function(Pointer<RECT> lpRect, int dwStyle, int bMenu,
              int dwExStyle)>('AdjustWindowRectEx');
      expect(AdjustWindowRectEx, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate AdjustWindowRectExForDpi', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final AdjustWindowRectExForDpi = user32.lookupFunction<
            Int32 Function(Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu,
                Uint32 dwExStyle, Uint32 dpi),
            int Function(Pointer<RECT> lpRect, int dwStyle, int bMenu,
                int dwExStyle, int dpi)>('AdjustWindowRectExForDpi');
        expect(AdjustWindowRectExForDpi, isA<Function>());
      });
    }
    test('Can instantiate AllowSetForegroundWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AllowSetForegroundWindow = user32.lookupFunction<
          Int32 Function(Uint32 dwProcessId),
          int Function(int dwProcessId)>('AllowSetForegroundWindow');
      expect(AllowSetForegroundWindow, isA<Function>());
    });
    test('Can instantiate AnimateWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AnimateWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 dwTime, Uint32 dwFlags),
          int Function(int hWnd, int dwTime, int dwFlags)>('AnimateWindow');
      expect(AnimateWindow, isA<Function>());
    });
    test('Can instantiate AnyPopup', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AnyPopup =
          user32.lookupFunction<Int32 Function(), int Function()>('AnyPopup');
      expect(AnyPopup, isA<Function>());
    });
    test('Can instantiate AppendMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AppendMenu = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uFlags, IntPtr uIDNewItem,
              Pointer<Utf16> lpNewItem),
          int Function(int hMenu, int uFlags, int uIDNewItem,
              Pointer<Utf16> lpNewItem)>('AppendMenuW');
      expect(AppendMenu, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate AreDpiAwarenessContextsEqual', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final AreDpiAwarenessContextsEqual = user32.lookupFunction<
            Int32 Function(IntPtr dpiContextA, IntPtr dpiContextB),
            int Function(int dpiContextA,
                int dpiContextB)>('AreDpiAwarenessContextsEqual');
        expect(AreDpiAwarenessContextsEqual, isA<Function>());
      });
    }
    test('Can instantiate ArrangeIconicWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ArrangeIconicWindows = user32.lookupFunction<
          Uint32 Function(IntPtr hWnd),
          int Function(int hWnd)>('ArrangeIconicWindows');
      expect(ArrangeIconicWindows, isA<Function>());
    });
    test('Can instantiate AttachThreadInput', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final AttachThreadInput = user32.lookupFunction<
          Int32 Function(Uint32 idAttach, Uint32 idAttachTo, Int32 fAttach),
          int Function(
              int idAttach, int idAttachTo, int fAttach)>('AttachThreadInput');
      expect(AttachThreadInput, isA<Function>());
    });
    test('Can instantiate BeginDeferWindowPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BeginDeferWindowPos = user32.lookupFunction<
          IntPtr Function(Int32 nNumWindows),
          int Function(int nNumWindows)>('BeginDeferWindowPos');
      expect(BeginDeferWindowPos, isA<Function>());
    });
    test('Can instantiate BeginPaint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BeginPaint = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Pointer<PAINTSTRUCT> lpPaint),
          int Function(int hWnd, Pointer<PAINTSTRUCT> lpPaint)>('BeginPaint');
      expect(BeginPaint, isA<Function>());
    });
    test('Can instantiate BlockInput', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BlockInput = user32.lookupFunction<Int32 Function(Int32 fBlockIt),
          int Function(int fBlockIt)>('BlockInput');
      expect(BlockInput, isA<Function>());
    });
    test('Can instantiate BringWindowToTop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BringWindowToTop = user32.lookupFunction<
          Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('BringWindowToTop');
      expect(BringWindowToTop, isA<Function>());
    });
    test('Can instantiate BroadcastSystemMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BroadcastSystemMessage = user32.lookupFunction<
          Int32 Function(Uint32 flags, Pointer<Uint32> lpInfo, Uint32 Msg,
              IntPtr wParam, IntPtr lParam),
          int Function(int flags, Pointer<Uint32> lpInfo, int Msg, int wParam,
              int lParam)>('BroadcastSystemMessageW');
      expect(BroadcastSystemMessage, isA<Function>());
    });
    test('Can instantiate BroadcastSystemMessageEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final BroadcastSystemMessageEx = user32.lookupFunction<
          Int32 Function(Uint32 flags, Pointer<Uint32> lpInfo, Uint32 Msg,
              IntPtr wParam, IntPtr lParam, Pointer<BSMINFO> pbsmInfo),
          int Function(
              int flags,
              Pointer<Uint32> lpInfo,
              int Msg,
              int wParam,
              int lParam,
              Pointer<BSMINFO> pbsmInfo)>('BroadcastSystemMessageExW');
      expect(BroadcastSystemMessageEx, isA<Function>());
    });
    test('Can instantiate CalculatePopupWindowPosition', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CalculatePopupWindowPosition = user32.lookupFunction<
              Int32 Function(
                  Pointer<POINT> anchorPoint,
                  Pointer<SIZE> windowSize,
                  Uint32 flags,
                  Pointer<RECT> excludeRect,
                  Pointer<RECT> popupWindowPosition),
              int Function(
                  Pointer<POINT> anchorPoint,
                  Pointer<SIZE> windowSize,
                  int flags,
                  Pointer<RECT> excludeRect,
                  Pointer<RECT> popupWindowPosition)>(
          'CalculatePopupWindowPosition');
      expect(CalculatePopupWindowPosition, isA<Function>());
    });
    test('Can instantiate CallMsgFilter', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CallMsgFilter = user32.lookupFunction<
          Int32 Function(Pointer<MSG> lpMsg, Int32 nCode),
          int Function(Pointer<MSG> lpMsg, int nCode)>('CallMsgFilterW');
      expect(CallMsgFilter, isA<Function>());
    });
    test('Can instantiate CallNextHookEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CallNextHookEx = user32.lookupFunction<
          IntPtr Function(
              IntPtr hhk, Int32 nCode, IntPtr wParam, IntPtr lParam),
          int Function(
              int hhk, int nCode, int wParam, int lParam)>('CallNextHookEx');
      expect(CallNextHookEx, isA<Function>());
    });
    test('Can instantiate CallWindowProc', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CallWindowProc = user32.lookupFunction<
          IntPtr Function(Pointer<NativeFunction<WindowProc>> lpPrevWndFunc,
              IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(Pointer<NativeFunction<WindowProc>> lpPrevWndFunc,
              int hWnd, int Msg, int wParam, int lParam)>('CallWindowProcW');
      expect(CallWindowProc, isA<Function>());
    });
    test('Can instantiate CascadeWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CascadeWindows = user32.lookupFunction<
          Uint16 Function(IntPtr hwndParent, Uint32 wHow, Pointer<RECT> lpRect,
              Uint32 cKids, Pointer<IntPtr> lpKids),
          int Function(int hwndParent, int wHow, Pointer<RECT> lpRect,
              int cKids, Pointer<IntPtr> lpKids)>('CascadeWindows');
      expect(CascadeWindows, isA<Function>());
    });
    test('Can instantiate ChangeClipboardChain', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChangeClipboardChain = user32.lookupFunction<
          Int32 Function(IntPtr hWndRemove, IntPtr hWndNewNext),
          int Function(
              int hWndRemove, int hWndNewNext)>('ChangeClipboardChain');
      expect(ChangeClipboardChain, isA<Function>());
    });
    test('Can instantiate ChangeDisplaySettings', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChangeDisplaySettings = user32.lookupFunction<
          Int32 Function(Pointer<DEVMODE> lpDevMode, Uint32 dwFlags),
          int Function(Pointer<DEVMODE> lpDevMode,
              int dwFlags)>('ChangeDisplaySettingsW');
      expect(ChangeDisplaySettings, isA<Function>());
    });
    test('Can instantiate ChangeDisplaySettingsEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChangeDisplaySettingsEx = user32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> lpszDeviceName,
              Pointer<DEVMODE> lpDevMode,
              IntPtr hwnd,
              Uint32 dwflags,
              Pointer lParam),
          int Function(
              Pointer<Utf16> lpszDeviceName,
              Pointer<DEVMODE> lpDevMode,
              int hwnd,
              int dwflags,
              Pointer lParam)>('ChangeDisplaySettingsExW');
      expect(ChangeDisplaySettingsEx, isA<Function>());
    });
    test('Can instantiate ChangeWindowMessageFilter', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChangeWindowMessageFilter = user32.lookupFunction<
          Int32 Function(Uint32 message, Uint32 dwFlag),
          int Function(int message, int dwFlag)>('ChangeWindowMessageFilter');
      expect(ChangeWindowMessageFilter, isA<Function>());
    });
    test('Can instantiate ChangeWindowMessageFilterEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChangeWindowMessageFilterEx = user32.lookupFunction<
              Int32 Function(IntPtr hwnd, Uint32 message, Uint32 action,
                  Pointer<CHANGEFILTERSTRUCT> pChangeFilterStruct),
              int Function(int hwnd, int message, int action,
                  Pointer<CHANGEFILTERSTRUCT> pChangeFilterStruct)>(
          'ChangeWindowMessageFilterEx');
      expect(ChangeWindowMessageFilterEx, isA<Function>());
    });
    test('Can instantiate CheckDlgButton', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CheckDlgButton = user32.lookupFunction<
          Int32 Function(IntPtr hDlg, Int32 nIDButton, Uint32 uCheck),
          int Function(int hDlg, int nIDButton, int uCheck)>('CheckDlgButton');
      expect(CheckDlgButton, isA<Function>());
    });
    test('Can instantiate CheckRadioButton', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CheckRadioButton = user32.lookupFunction<
          Int32 Function(IntPtr hDlg, Int32 nIDFirstButton, Int32 nIDLastButton,
              Int32 nIDCheckButton),
          int Function(int hDlg, int nIDFirstButton, int nIDLastButton,
              int nIDCheckButton)>('CheckRadioButton');
      expect(CheckRadioButton, isA<Function>());
    });
    test('Can instantiate ChildWindowFromPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChildWindowFromPoint = user32.lookupFunction<
          IntPtr Function(IntPtr hWndParent, POINT Point),
          int Function(int hWndParent, POINT Point)>('ChildWindowFromPoint');
      expect(ChildWindowFromPoint, isA<Function>());
    });
    test('Can instantiate ChildWindowFromPointEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ChildWindowFromPointEx = user32.lookupFunction<
          IntPtr Function(IntPtr hwnd, POINT pt, Uint32 flags),
          int Function(
              int hwnd, POINT pt, int flags)>('ChildWindowFromPointEx');
      expect(ChildWindowFromPointEx, isA<Function>());
    });
    test('Can instantiate ClientToScreen', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ClientToScreen = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
          int Function(int hWnd, Pointer<POINT> lpPoint)>('ClientToScreen');
      expect(ClientToScreen, isA<Function>());
    });
    test('Can instantiate ClipCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ClipCursor = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lpRect),
          int Function(Pointer<RECT> lpRect)>('ClipCursor');
      expect(ClipCursor, isA<Function>());
    });
    test('Can instantiate CloseClipboard', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CloseClipboard = user32
          .lookupFunction<Int32 Function(), int Function()>('CloseClipboard');
      expect(CloseClipboard, isA<Function>());
    });
    test('Can instantiate CloseGestureInfoHandle', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CloseGestureInfoHandle = user32.lookupFunction<
          Int32 Function(IntPtr hGestureInfo),
          int Function(int hGestureInfo)>('CloseGestureInfoHandle');
      expect(CloseGestureInfoHandle, isA<Function>());
    });
    test('Can instantiate CloseTouchInputHandle', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CloseTouchInputHandle = user32.lookupFunction<
          Int32 Function(IntPtr hTouchInput),
          int Function(int hTouchInput)>('CloseTouchInputHandle');
      expect(CloseTouchInputHandle, isA<Function>());
    });
    test('Can instantiate CloseWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CloseWindow = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('CloseWindow');
      expect(CloseWindow, isA<Function>());
    });
    test('Can instantiate CopyAcceleratorTable', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CopyAcceleratorTable = user32.lookupFunction<
          Int32 Function(
              IntPtr hAccelSrc, Pointer<ACCEL> lpAccelDst, Int32 cAccelEntries),
          int Function(int hAccelSrc, Pointer<ACCEL> lpAccelDst,
              int cAccelEntries)>('CopyAcceleratorTableW');
      expect(CopyAcceleratorTable, isA<Function>());
    });
    test('Can instantiate CopyIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CopyIcon = user32.lookupFunction<IntPtr Function(IntPtr hIcon),
          int Function(int hIcon)>('CopyIcon');
      expect(CopyIcon, isA<Function>());
    });
    test('Can instantiate CopyImage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CopyImage = user32.lookupFunction<
          IntPtr Function(
              IntPtr h, Uint32 type, Int32 cx, Int32 cy, Uint32 flags),
          int Function(
              int h, int type, int cx, int cy, int flags)>('CopyImage');
      expect(CopyImage, isA<Function>());
    });
    test('Can instantiate CopyRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CopyRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc),
          int Function(
              Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc)>('CopyRect');
      expect(CopyRect, isA<Function>());
    });
    test('Can instantiate CountClipboardFormats', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CountClipboardFormats =
          user32.lookupFunction<Int32 Function(), int Function()>(
              'CountClipboardFormats');
      expect(CountClipboardFormats, isA<Function>());
    });
    test('Can instantiate CreateAcceleratorTable', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateAcceleratorTable = user32.lookupFunction<
          IntPtr Function(Pointer<ACCEL> paccel, Int32 cAccel),
          int Function(
              Pointer<ACCEL> paccel, int cAccel)>('CreateAcceleratorTableW');
      expect(CreateAcceleratorTable, isA<Function>());
    });
    test('Can instantiate CreateDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateDesktop = user32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpszDesktop,
              Pointer<Utf16> lpszDevice,
              Pointer<DEVMODE> pDevmode,
              Uint32 dwFlags,
              Uint32 dwDesiredAccess,
              Pointer<SECURITY_ATTRIBUTES> lpsa),
          int Function(
              Pointer<Utf16> lpszDesktop,
              Pointer<Utf16> lpszDevice,
              Pointer<DEVMODE> pDevmode,
              int dwFlags,
              int dwDesiredAccess,
              Pointer<SECURITY_ATTRIBUTES> lpsa)>('CreateDesktopW');
      expect(CreateDesktop, isA<Function>());
    });
    test('Can instantiate CreateDesktopEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateDesktopEx = user32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpszDesktop,
              Pointer<Utf16> lpszDevice,
              Pointer<DEVMODE> pDevmode,
              Uint32 dwFlags,
              Uint32 dwDesiredAccess,
              Pointer<SECURITY_ATTRIBUTES> lpsa,
              Uint32 ulHeapSize,
              Pointer pvoid),
          int Function(
              Pointer<Utf16> lpszDesktop,
              Pointer<Utf16> lpszDevice,
              Pointer<DEVMODE> pDevmode,
              int dwFlags,
              int dwDesiredAccess,
              Pointer<SECURITY_ATTRIBUTES> lpsa,
              int ulHeapSize,
              Pointer pvoid)>('CreateDesktopExW');
      expect(CreateDesktopEx, isA<Function>());
    });
    test('Can instantiate CreateDialogIndirectParam', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateDialogIndirectParam = user32.lookupFunction<
          IntPtr Function(
              IntPtr hInstance,
              Pointer<DLGTEMPLATE> lpTemplate,
              IntPtr hWndParent,
              Pointer<NativeFunction<DlgProc>> lpDialogFunc,
              IntPtr dwInitParam),
          int Function(
              int hInstance,
              Pointer<DLGTEMPLATE> lpTemplate,
              int hWndParent,
              Pointer<NativeFunction<DlgProc>> lpDialogFunc,
              int dwInitParam)>('CreateDialogIndirectParamW');
      expect(CreateDialogIndirectParam, isA<Function>());
    });
    test('Can instantiate CreateIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateIcon = user32.lookupFunction<
          IntPtr Function(
              IntPtr hInstance,
              Int32 nWidth,
              Int32 nHeight,
              Uint8 cPlanes,
              Uint8 cBitsPixel,
              Pointer<Uint8> lpbANDbits,
              Pointer<Uint8> lpbXORbits),
          int Function(
              int hInstance,
              int nWidth,
              int nHeight,
              int cPlanes,
              int cBitsPixel,
              Pointer<Uint8> lpbANDbits,
              Pointer<Uint8> lpbXORbits)>('CreateIcon');
      expect(CreateIcon, isA<Function>());
    });
    test('Can instantiate CreateMDIWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateMDIWindow = user32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpClassName,
              Pointer<Utf16> lpWindowName,
              Uint32 dwStyle,
              Int32 X,
              Int32 Y,
              Int32 nWidth,
              Int32 nHeight,
              IntPtr hWndParent,
              IntPtr hInstance,
              IntPtr lParam),
          int Function(
              Pointer<Utf16> lpClassName,
              Pointer<Utf16> lpWindowName,
              int dwStyle,
              int X,
              int Y,
              int nWidth,
              int nHeight,
              int hWndParent,
              int hInstance,
              int lParam)>('CreateMDIWindowW');
      expect(CreateMDIWindow, isA<Function>());
    });
    test('Can instantiate CreateMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateMenu = user32
          .lookupFunction<IntPtr Function(), int Function()>('CreateMenu');
      expect(CreateMenu, isA<Function>());
    });
    test('Can instantiate CreateWindowEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateWindowEx = user32.lookupFunction<
          IntPtr Function(
              Uint32 dwExStyle,
              Pointer<Utf16> lpClassName,
              Pointer<Utf16> lpWindowName,
              Uint32 dwStyle,
              Int32 X,
              Int32 Y,
              Int32 nWidth,
              Int32 nHeight,
              IntPtr hWndParent,
              IntPtr hMenu,
              IntPtr hInstance,
              Pointer lpParam),
          int Function(
              int dwExStyle,
              Pointer<Utf16> lpClassName,
              Pointer<Utf16> lpWindowName,
              int dwStyle,
              int X,
              int Y,
              int nWidth,
              int nHeight,
              int hWndParent,
              int hMenu,
              int hInstance,
              Pointer lpParam)>('CreateWindowExW');
      expect(CreateWindowEx, isA<Function>());
    });
    test('Can instantiate CreateWindowStation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final CreateWindowStation = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpwinsta, Uint32 dwFlags,
              Uint32 dwDesiredAccess, Pointer<SECURITY_ATTRIBUTES> lpsa),
          int Function(
              Pointer<Utf16> lpwinsta,
              int dwFlags,
              int dwDesiredAccess,
              Pointer<SECURITY_ATTRIBUTES> lpsa)>('CreateWindowStationW');
      expect(CreateWindowStation, isA<Function>());
    });
    test('Can instantiate DeferWindowPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DeferWindowPos = user32.lookupFunction<
          IntPtr Function(
              IntPtr hWinPosInfo,
              IntPtr hWnd,
              IntPtr hWndInsertAfter,
              Int32 x,
              Int32 y,
              Int32 cx,
              Int32 cy,
              Uint32 uFlags),
          int Function(int hWinPosInfo, int hWnd, int hWndInsertAfter, int x,
              int y, int cx, int cy, int uFlags)>('DeferWindowPos');
      expect(DeferWindowPos, isA<Function>());
    });
    test('Can instantiate DefMDIChildProc', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DefMDIChildProc = user32.lookupFunction<
          IntPtr Function(
              IntPtr hWnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int uMsg, int wParam, int lParam)>('DefMDIChildProcW');
      expect(DefMDIChildProc, isA<Function>());
    });
    test('Can instantiate DefRawInputProc', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DefRawInputProc = user32.lookupFunction<
          IntPtr Function(Pointer<Pointer<RAWINPUT>> paRawInput, Int32 nInput,
              Uint32 cbSizeHeader),
          int Function(Pointer<Pointer<RAWINPUT>> paRawInput, int nInput,
              int cbSizeHeader)>('DefRawInputProc');
      expect(DefRawInputProc, isA<Function>());
    });
    test('Can instantiate DefWindowProc', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DefWindowProc = user32.lookupFunction<
          IntPtr Function(
              IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int Msg, int wParam, int lParam)>('DefWindowProcW');
      expect(DefWindowProc, isA<Function>());
    });
    test('Can instantiate DeleteMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DeleteMenu = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags),
          int Function(int hMenu, int uPosition, int uFlags)>('DeleteMenu');
      expect(DeleteMenu, isA<Function>());
    });
    test('Can instantiate DestroyCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DestroyCursor = user32.lookupFunction<
          Int32 Function(IntPtr hCursor),
          int Function(int hCursor)>('DestroyCursor');
      expect(DestroyCursor, isA<Function>());
    });
    test('Can instantiate DestroyIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DestroyIcon = user32.lookupFunction<Int32 Function(IntPtr hIcon),
          int Function(int hIcon)>('DestroyIcon');
      expect(DestroyIcon, isA<Function>());
    });
    test('Can instantiate DestroyMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DestroyMenu = user32.lookupFunction<Int32 Function(IntPtr hMenu),
          int Function(int hMenu)>('DestroyMenu');
      expect(DestroyMenu, isA<Function>());
    });
    test('Can instantiate DestroyWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DestroyWindow = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('DestroyWindow');
      expect(DestroyWindow, isA<Function>());
    });
    test('Can instantiate DialogBoxIndirectParam', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DialogBoxIndirectParam = user32.lookupFunction<
          IntPtr Function(
              IntPtr hInstance,
              Pointer<DLGTEMPLATE> hDialogTemplate,
              IntPtr hWndParent,
              Pointer<NativeFunction<DlgProc>> lpDialogFunc,
              IntPtr dwInitParam),
          int Function(
              int hInstance,
              Pointer<DLGTEMPLATE> hDialogTemplate,
              int hWndParent,
              Pointer<NativeFunction<DlgProc>> lpDialogFunc,
              int dwInitParam)>('DialogBoxIndirectParamW');
      expect(DialogBoxIndirectParam, isA<Function>());
    });
    test('Can instantiate DisableProcessWindowsGhosting', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DisableProcessWindowsGhosting =
          user32.lookupFunction<Void Function(), void Function()>(
              'DisableProcessWindowsGhosting');
      expect(DisableProcessWindowsGhosting, isA<Function>());
    });
    test('Can instantiate DispatchMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DispatchMessage = user32.lookupFunction<
          IntPtr Function(Pointer<MSG> lpMsg),
          int Function(Pointer<MSG> lpMsg)>('DispatchMessageW');
      expect(DispatchMessage, isA<Function>());
    });
    test('Can instantiate DragDetect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DragDetect = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, POINT pt),
          int Function(int hwnd, POINT pt)>('DragDetect');
      expect(DragDetect, isA<Function>());
    });
    test('Can instantiate DrawAnimatedRects', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawAnimatedRects = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 idAni, Pointer<RECT> lprcFrom,
              Pointer<RECT> lprcTo),
          int Function(int hwnd, int idAni, Pointer<RECT> lprcFrom,
              Pointer<RECT> lprcTo)>('DrawAnimatedRects');
      expect(DrawAnimatedRects, isA<Function>());
    });
    test('Can instantiate DrawCaption', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawCaption = user32.lookupFunction<
          Int32 Function(
              IntPtr hwnd, IntPtr hdc, Pointer<RECT> lprect, Uint32 flags),
          int Function(int hwnd, int hdc, Pointer<RECT> lprect,
              int flags)>('DrawCaption');
      expect(DrawCaption, isA<Function>());
    });
    test('Can instantiate DrawEdge', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawEdge = user32.lookupFunction<
          Int32 Function(
              IntPtr hdc, Pointer<RECT> qrc, Uint32 edge, Uint32 grfFlags),
          int Function(
              int hdc, Pointer<RECT> qrc, int edge, int grfFlags)>('DrawEdge');
      expect(DrawEdge, isA<Function>());
    });
    test('Can instantiate DrawFocusRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawFocusRect = user32.lookupFunction<
          Int32 Function(IntPtr hDC, Pointer<RECT> lprc),
          int Function(int hDC, Pointer<RECT> lprc)>('DrawFocusRect');
      expect(DrawFocusRect, isA<Function>());
    });
    test('Can instantiate DrawFrameControl', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawFrameControl = user32.lookupFunction<
          Int32 Function(IntPtr param0, Pointer<RECT> param1, Uint32 param2,
              Uint32 param3),
          int Function(int param0, Pointer<RECT> param1, int param2,
              int param3)>('DrawFrameControl');
      expect(DrawFrameControl, isA<Function>());
    });
    test('Can instantiate DrawIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawIcon = user32.lookupFunction<
          Int32 Function(IntPtr hDC, Int32 X, Int32 Y, IntPtr hIcon),
          int Function(int hDC, int X, int Y, int hIcon)>('DrawIcon');
      expect(DrawIcon, isA<Function>());
    });
    test('Can instantiate DrawState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawState = user32.lookupFunction<
          Int32 Function(
              IntPtr hdc,
              IntPtr hbrFore,
              Pointer<NativeFunction<DrawStateProc>> qfnCallBack,
              IntPtr lData,
              IntPtr wData,
              Int32 x,
              Int32 y,
              Int32 cx,
              Int32 cy,
              Uint32 uFlags),
          int Function(
              int hdc,
              int hbrFore,
              Pointer<NativeFunction<DrawStateProc>> qfnCallBack,
              int lData,
              int wData,
              int x,
              int y,
              int cx,
              int cy,
              int uFlags)>('DrawStateW');
      expect(DrawState, isA<Function>());
    });
    test('Can instantiate DrawText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawText = user32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<Utf16> lpchText, Int32 cchText,
              Pointer<RECT> lprc, Uint32 format),
          int Function(int hdc, Pointer<Utf16> lpchText, int cchText,
              Pointer<RECT> lprc, int format)>('DrawTextW');
      expect(DrawText, isA<Function>());
    });
    test('Can instantiate DrawTextEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final DrawTextEx = user32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<Utf16> lpchText, Int32 cchText,
              Pointer<RECT> lprc, Uint32 format, Pointer<DRAWTEXTPARAMS> lpdtp),
          int Function(
              int hdc,
              Pointer<Utf16> lpchText,
              int cchText,
              Pointer<RECT> lprc,
              int format,
              Pointer<DRAWTEXTPARAMS> lpdtp)>('DrawTextExW');
      expect(DrawTextEx, isA<Function>());
    });
    test('Can instantiate EmptyClipboard', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EmptyClipboard = user32
          .lookupFunction<Int32 Function(), int Function()>('EmptyClipboard');
      expect(EmptyClipboard, isA<Function>());
    });
    test('Can instantiate EnableMenuItem', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnableMenuItem = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uIDEnableItem, Uint32 uEnable),
          int Function(
              int hMenu, int uIDEnableItem, int uEnable)>('EnableMenuItem');
      expect(EnableMenuItem, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate EnableMouseInPointer', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final EnableMouseInPointer = user32.lookupFunction<
            Int32 Function(Int32 fEnable),
            int Function(int fEnable)>('EnableMouseInPointer');
        expect(EnableMouseInPointer, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate EnableNonClientDpiScaling', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final EnableNonClientDpiScaling = user32.lookupFunction<
            Int32 Function(IntPtr hwnd),
            int Function(int hwnd)>('EnableNonClientDpiScaling');
        expect(EnableNonClientDpiScaling, isA<Function>());
      });
    }
    test('Can instantiate EnableScrollBar', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnableScrollBar = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 wSBflags, Uint32 wArrows),
          int Function(int hWnd, int wSBflags, int wArrows)>('EnableScrollBar');
      expect(EnableScrollBar, isA<Function>());
    });
    test('Can instantiate EnableWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnableWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 bEnable),
          int Function(int hWnd, int bEnable)>('EnableWindow');
      expect(EnableWindow, isA<Function>());
    });
    test('Can instantiate EndDeferWindowPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EndDeferWindowPos = user32.lookupFunction<
          Int32 Function(IntPtr hWinPosInfo),
          int Function(int hWinPosInfo)>('EndDeferWindowPos');
      expect(EndDeferWindowPos, isA<Function>());
    });
    test('Can instantiate EndDialog', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EndDialog = user32.lookupFunction<
          Int32 Function(IntPtr hDlg, IntPtr nResult),
          int Function(int hDlg, int nResult)>('EndDialog');
      expect(EndDialog, isA<Function>());
    });
    test('Can instantiate EndMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EndMenu =
          user32.lookupFunction<Int32 Function(), int Function()>('EndMenu');
      expect(EndMenu, isA<Function>());
    });
    test('Can instantiate EndPaint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EndPaint = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<PAINTSTRUCT> lpPaint),
          int Function(int hWnd, Pointer<PAINTSTRUCT> lpPaint)>('EndPaint');
      expect(EndPaint, isA<Function>());
    });
    test('Can instantiate EnumChildWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumChildWindows = user32.lookupFunction<
          Int32 Function(
              IntPtr hWndParent,
              Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
              IntPtr lParam),
          int Function(
              int hWndParent,
              Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
              int lParam)>('EnumChildWindows');
      expect(EnumChildWindows, isA<Function>());
    });
    test('Can instantiate EnumClipboardFormats', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumClipboardFormats = user32.lookupFunction<
          Uint32 Function(Uint32 format),
          int Function(int format)>('EnumClipboardFormats');
      expect(EnumClipboardFormats, isA<Function>());
    });
    test('Can instantiate EnumDesktopWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumDesktopWindows = user32.lookupFunction<
          Int32 Function(IntPtr hDesktop,
              Pointer<NativeFunction<EnumWindowsProc>> lpfn, IntPtr lParam),
          int Function(
              int hDesktop,
              Pointer<NativeFunction<EnumWindowsProc>> lpfn,
              int lParam)>('EnumDesktopWindows');
      expect(EnumDesktopWindows, isA<Function>());
    });
    test('Can instantiate EnumDisplayMonitors', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumDisplayMonitors = user32.lookupFunction<
          Int32 Function(IntPtr hdc, Pointer<RECT> lprcClip,
              Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum, IntPtr dwData),
          int Function(
              int hdc,
              Pointer<RECT> lprcClip,
              Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum,
              int dwData)>('EnumDisplayMonitors');
      expect(EnumDisplayMonitors, isA<Function>());
    });
    test('Can instantiate EnumThreadWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumThreadWindows = user32.lookupFunction<
          Int32 Function(Uint32 dwThreadId,
              Pointer<NativeFunction<EnumWindowsProc>> lpfn, IntPtr lParam),
          int Function(
              int dwThreadId,
              Pointer<NativeFunction<EnumWindowsProc>> lpfn,
              int lParam)>('EnumThreadWindows');
      expect(EnumThreadWindows, isA<Function>());
    });
    test('Can instantiate EnumWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EnumWindows = user32.lookupFunction<
          Int32 Function(Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
              IntPtr lParam),
          int Function(Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
              int lParam)>('EnumWindows');
      expect(EnumWindows, isA<Function>());
    });
    test('Can instantiate EqualRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final EqualRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc1, Pointer<RECT> lprc2),
          int Function(Pointer<RECT> lprc1, Pointer<RECT> lprc2)>('EqualRect');
      expect(EqualRect, isA<Function>());
    });
    test('Can instantiate ExcludeUpdateRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ExcludeUpdateRgn = user32.lookupFunction<
          Int32 Function(IntPtr hDC, IntPtr hWnd),
          int Function(int hDC, int hWnd)>('ExcludeUpdateRgn');
      expect(ExcludeUpdateRgn, isA<Function>());
    });
    test('Can instantiate FillRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final FillRect = user32.lookupFunction<
          Int32 Function(IntPtr hDC, Pointer<RECT> lprc, IntPtr hbr),
          int Function(int hDC, Pointer<RECT> lprc, int hbr)>('FillRect');
      expect(FillRect, isA<Function>());
    });
    test('Can instantiate FindWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final FindWindow = user32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName),
          int Function(Pointer<Utf16> lpClassName,
              Pointer<Utf16> lpWindowName)>('FindWindowW');
      expect(FindWindow, isA<Function>());
    });
    test('Can instantiate FindWindowEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final FindWindowEx = user32.lookupFunction<
          IntPtr Function(IntPtr hWndParent, IntPtr hWndChildAfter,
              Pointer<Utf16> lpszClass, Pointer<Utf16> lpszWindow),
          int Function(
              int hWndParent,
              int hWndChildAfter,
              Pointer<Utf16> lpszClass,
              Pointer<Utf16> lpszWindow)>('FindWindowExW');
      expect(FindWindowEx, isA<Function>());
    });
    test('Can instantiate FrameRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final FrameRect = user32.lookupFunction<
          Int32 Function(IntPtr hDC, Pointer<RECT> lprc, IntPtr hbr),
          int Function(int hDC, Pointer<RECT> lprc, int hbr)>('FrameRect');
      expect(FrameRect, isA<Function>());
    });
    test('Can instantiate GetActiveWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetActiveWindow = user32
          .lookupFunction<IntPtr Function(), int Function()>('GetActiveWindow');
      expect(GetActiveWindow, isA<Function>());
    });
    test('Can instantiate GetAltTabInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetAltTabInfo = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 iItem, Pointer<ALTTABINFO> pati,
              Pointer<Utf16> pszItemText, Uint32 cchItemText),
          int Function(int hwnd, int iItem, Pointer<ALTTABINFO> pati,
              Pointer<Utf16> pszItemText, int cchItemText)>('GetAltTabInfoW');
      expect(GetAltTabInfo, isA<Function>());
    });
    test('Can instantiate GetAncestor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetAncestor = user32.lookupFunction<
          IntPtr Function(IntPtr hwnd, Uint32 gaFlags),
          int Function(int hwnd, int gaFlags)>('GetAncestor');
      expect(GetAncestor, isA<Function>());
    });
    test('Can instantiate GetAsyncKeyState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetAsyncKeyState = user32.lookupFunction<Int16 Function(Int32 vKey),
          int Function(int vKey)>('GetAsyncKeyState');
      expect(GetAsyncKeyState, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetAwarenessFromDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetAwarenessFromDpiAwarenessContext = user32.lookupFunction<
            Int32 Function(IntPtr value),
            int Function(int value)>('GetAwarenessFromDpiAwarenessContext');
        expect(GetAwarenessFromDpiAwarenessContext, isA<Function>());
      });
    }
    test('Can instantiate GetCapture', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCapture = user32
          .lookupFunction<IntPtr Function(), int Function()>('GetCapture');
      expect(GetCapture, isA<Function>());
    });
    test('Can instantiate GetCaretBlinkTime', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCaretBlinkTime =
          user32.lookupFunction<Uint32 Function(), int Function()>(
              'GetCaretBlinkTime');
      expect(GetCaretBlinkTime, isA<Function>());
    });
    test('Can instantiate GetCaretPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCaretPos = user32.lookupFunction<
          Int32 Function(Pointer<POINT> lpPoint),
          int Function(Pointer<POINT> lpPoint)>('GetCaretPos');
      expect(GetCaretPos, isA<Function>());
    });
    test('Can instantiate GetClassInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClassInfo = user32.lookupFunction<
          Int32 Function(IntPtr hInstance, Pointer<Utf16> lpClassName,
              Pointer<WNDCLASS> lpWndClass),
          int Function(int hInstance, Pointer<Utf16> lpClassName,
              Pointer<WNDCLASS> lpWndClass)>('GetClassInfoW');
      expect(GetClassInfo, isA<Function>());
    });
    test('Can instantiate GetClassInfoEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClassInfoEx = user32.lookupFunction<
          Int32 Function(IntPtr hInstance, Pointer<Utf16> lpszClass,
              Pointer<WNDCLASSEX> lpwcx),
          int Function(int hInstance, Pointer<Utf16> lpszClass,
              Pointer<WNDCLASSEX> lpwcx)>('GetClassInfoExW');
      expect(GetClassInfoEx, isA<Function>());
    });
    test('Can instantiate GetClassLongPtr', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClassLongPtr = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Int32 nIndex),
          int Function(int hWnd, int nIndex)>('GetClassLongPtrW');
      expect(GetClassLongPtr, isA<Function>());
    });
    test('Can instantiate GetClassName', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClassName = user32.lookupFunction<
          Int32 Function(
              IntPtr hWnd, Pointer<Utf16> lpClassName, Int32 nMaxCount),
          int Function(int hWnd, Pointer<Utf16> lpClassName,
              int nMaxCount)>('GetClassNameW');
      expect(GetClassName, isA<Function>());
    });
    test('Can instantiate GetClientRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClientRect = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
          int Function(int hWnd, Pointer<RECT> lpRect)>('GetClientRect');
      expect(GetClientRect, isA<Function>());
    });
    test('Can instantiate GetClipboardData', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipboardData = user32.lookupFunction<
          IntPtr Function(Uint32 uFormat),
          int Function(int uFormat)>('GetClipboardData');
      expect(GetClipboardData, isA<Function>());
    });
    test('Can instantiate GetClipboardFormatName', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipboardFormatName = user32.lookupFunction<
          Int32 Function(
              Uint32 format, Pointer<Utf16> lpszFormatName, Int32 cchMaxCount),
          int Function(int format, Pointer<Utf16> lpszFormatName,
              int cchMaxCount)>('GetClipboardFormatNameW');
      expect(GetClipboardFormatName, isA<Function>());
    });
    test('Can instantiate GetClipboardOwner', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipboardOwner =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetClipboardOwner');
      expect(GetClipboardOwner, isA<Function>());
    });
    test('Can instantiate GetClipboardSequenceNumber', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipboardSequenceNumber =
          user32.lookupFunction<Uint32 Function(), int Function()>(
              'GetClipboardSequenceNumber');
      expect(GetClipboardSequenceNumber, isA<Function>());
    });
    test('Can instantiate GetClipboardViewer', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipboardViewer =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetClipboardViewer');
      expect(GetClipboardViewer, isA<Function>());
    });
    test('Can instantiate GetClipCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetClipCursor = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lpRect),
          int Function(Pointer<RECT> lpRect)>('GetClipCursor');
      expect(GetClipCursor, isA<Function>());
    });
    test('Can instantiate GetCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCursor =
          user32.lookupFunction<IntPtr Function(), int Function()>('GetCursor');
      expect(GetCursor, isA<Function>());
    });
    test('Can instantiate GetCursorInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCursorInfo = user32.lookupFunction<
          Int32 Function(Pointer<CURSORINFO> pci),
          int Function(Pointer<CURSORINFO> pci)>('GetCursorInfo');
      expect(GetCursorInfo, isA<Function>());
    });
    test('Can instantiate GetCursorPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetCursorPos = user32.lookupFunction<
          Int32 Function(Pointer<POINT> lpPoint),
          int Function(Pointer<POINT> lpPoint)>('GetCursorPos');
      expect(GetCursorPos, isA<Function>());
    });
    test('Can instantiate GetDC', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDC = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('GetDC');
      expect(GetDC, isA<Function>());
    });
    test('Can instantiate GetDCEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDCEx = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, IntPtr hrgnClip, Uint32 flags),
          int Function(int hWnd, int hrgnClip, int flags)>('GetDCEx');
      expect(GetDCEx, isA<Function>());
    });
    test('Can instantiate GetDesktopWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDesktopWindow =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetDesktopWindow');
      expect(GetDesktopWindow, isA<Function>());
    });
    test('Can instantiate GetDialogBaseUnits', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDialogBaseUnits =
          user32.lookupFunction<Int32 Function(), int Function()>(
              'GetDialogBaseUnits');
      expect(GetDialogBaseUnits, isA<Function>());
    });
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate GetDialogControlDpiChangeBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDialogControlDpiChangeBehavior = user32.lookupFunction<
            Uint32 Function(IntPtr hWnd),
            int Function(int hWnd)>('GetDialogControlDpiChangeBehavior');
        expect(GetDialogControlDpiChangeBehavior, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate GetDialogDpiChangeBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDialogDpiChangeBehavior = user32.lookupFunction<
            Uint32 Function(IntPtr hDlg),
            int Function(int hDlg)>('GetDialogDpiChangeBehavior');
        expect(GetDialogDpiChangeBehavior, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetDisplayAutoRotationPreferences', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDisplayAutoRotationPreferences = user32.lookupFunction<
                Int32 Function(Pointer<Int32> pOrientation),
                int Function(Pointer<Int32> pOrientation)>(
            'GetDisplayAutoRotationPreferences');
        expect(GetDisplayAutoRotationPreferences, isA<Function>());
      });
    }
    test('Can instantiate GetDlgItem', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDlgItem = user32.lookupFunction<
          IntPtr Function(IntPtr hDlg, Int32 nIDDlgItem),
          int Function(int hDlg, int nIDDlgItem)>('GetDlgItem');
      expect(GetDlgItem, isA<Function>());
    });
    test('Can instantiate GetDlgItemInt', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDlgItemInt = user32.lookupFunction<
          Uint32 Function(IntPtr hDlg, Int32 nIDDlgItem,
              Pointer<Int32> lpTranslated, Int32 bSigned),
          int Function(int hDlg, int nIDDlgItem, Pointer<Int32> lpTranslated,
              int bSigned)>('GetDlgItemInt');
      expect(GetDlgItemInt, isA<Function>());
    });
    test('Can instantiate GetDlgItemText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDlgItemText = user32.lookupFunction<
          Uint32 Function(IntPtr hDlg, Int32 nIDDlgItem,
              Pointer<Utf16> lpString, Int32 cchMax),
          int Function(int hDlg, int nIDDlgItem, Pointer<Utf16> lpString,
              int cchMax)>('GetDlgItemTextW');
      expect(GetDlgItemText, isA<Function>());
    });
    test('Can instantiate GetDoubleClickTime', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetDoubleClickTime =
          user32.lookupFunction<Uint32 Function(), int Function()>(
              'GetDoubleClickTime');
      expect(GetDoubleClickTime, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetDpiForSystem', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDpiForSystem =
            user32.lookupFunction<Uint32 Function(), int Function()>(
                'GetDpiForSystem');
        expect(GetDpiForSystem, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetDpiForWindow', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDpiForWindow = user32.lookupFunction<
            Uint32 Function(IntPtr hwnd),
            int Function(int hwnd)>('GetDpiForWindow');
        expect(GetDpiForWindow, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate GetDpiFromDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetDpiFromDpiAwarenessContext = user32.lookupFunction<
            Uint32 Function(IntPtr value),
            int Function(int value)>('GetDpiFromDpiAwarenessContext');
        expect(GetDpiFromDpiAwarenessContext, isA<Function>());
      });
    }
    test('Can instantiate GetFocus', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetFocus =
          user32.lookupFunction<IntPtr Function(), int Function()>('GetFocus');
      expect(GetFocus, isA<Function>());
    });
    test('Can instantiate GetForegroundWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetForegroundWindow =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetForegroundWindow');
      expect(GetForegroundWindow, isA<Function>());
    });
    test('Can instantiate GetGestureConfig', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetGestureConfig = user32.lookupFunction<
          Int32 Function(
              IntPtr hwnd,
              Uint32 dwReserved,
              Uint32 dwFlags,
              Pointer<Uint32> pcIDs,
              Pointer<GESTURECONFIG> pGestureConfig,
              Uint32 cbSize),
          int Function(
              int hwnd,
              int dwReserved,
              int dwFlags,
              Pointer<Uint32> pcIDs,
              Pointer<GESTURECONFIG> pGestureConfig,
              int cbSize)>('GetGestureConfig');
      expect(GetGestureConfig, isA<Function>());
    });
    test('Can instantiate GetGestureExtraArgs', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetGestureExtraArgs = user32.lookupFunction<
          Int32 Function(IntPtr hGestureInfo, Uint32 cbExtraArgs,
              Pointer<Uint8> pExtraArgs),
          int Function(int hGestureInfo, int cbExtraArgs,
              Pointer<Uint8> pExtraArgs)>('GetGestureExtraArgs');
      expect(GetGestureExtraArgs, isA<Function>());
    });
    test('Can instantiate GetGestureInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetGestureInfo = user32.lookupFunction<
          Int32 Function(
              IntPtr hGestureInfo, Pointer<GESTUREINFO> pGestureInfo),
          int Function(int hGestureInfo,
              Pointer<GESTUREINFO> pGestureInfo)>('GetGestureInfo');
      expect(GetGestureInfo, isA<Function>());
    });
    test('Can instantiate GetGUIThreadInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetGUIThreadInfo = user32.lookupFunction<
          Int32 Function(Uint32 idThread, Pointer<GUITHREADINFO> pgui),
          int Function(
              int idThread, Pointer<GUITHREADINFO> pgui)>('GetGUIThreadInfo');
      expect(GetGUIThreadInfo, isA<Function>());
    });
    test('Can instantiate GetIconInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetIconInfo = user32.lookupFunction<
          Int32 Function(IntPtr hIcon, Pointer<ICONINFO> piconinfo),
          int Function(int hIcon, Pointer<ICONINFO> piconinfo)>('GetIconInfo');
      expect(GetIconInfo, isA<Function>());
    });
    test('Can instantiate GetIconInfoEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetIconInfoEx = user32.lookupFunction<
          Int32 Function(IntPtr hicon, Pointer<ICONINFOEX> piconinfo),
          int Function(
              int hicon, Pointer<ICONINFOEX> piconinfo)>('GetIconInfoExW');
      expect(GetIconInfoEx, isA<Function>());
    });
    test('Can instantiate GetInputState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetInputState = user32
          .lookupFunction<Int32 Function(), int Function()>('GetInputState');
      expect(GetInputState, isA<Function>());
    });
    test('Can instantiate GetKeyboardLayout', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyboardLayout = user32.lookupFunction<
          IntPtr Function(Uint32 idThread),
          int Function(int idThread)>('GetKeyboardLayout');
      expect(GetKeyboardLayout, isA<Function>());
    });
    test('Can instantiate GetKeyboardLayoutList', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyboardLayoutList = user32.lookupFunction<
          Int32 Function(Int32 nBuff, Pointer<IntPtr> lpList),
          int Function(
              int nBuff, Pointer<IntPtr> lpList)>('GetKeyboardLayoutList');
      expect(GetKeyboardLayoutList, isA<Function>());
    });
    test('Can instantiate GetKeyboardLayoutName', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyboardLayoutName = user32.lookupFunction<
          Int32 Function(Pointer<Utf16> pwszKLID),
          int Function(Pointer<Utf16> pwszKLID)>('GetKeyboardLayoutNameW');
      expect(GetKeyboardLayoutName, isA<Function>());
    });
    test('Can instantiate GetKeyboardState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyboardState = user32.lookupFunction<
          Int32 Function(Pointer<Uint8> lpKeyState),
          int Function(Pointer<Uint8> lpKeyState)>('GetKeyboardState');
      expect(GetKeyboardState, isA<Function>());
    });
    test('Can instantiate GetKeyboardType', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyboardType = user32.lookupFunction<
          Int32 Function(Int32 nTypeFlag),
          int Function(int nTypeFlag)>('GetKeyboardType');
      expect(GetKeyboardType, isA<Function>());
    });
    test('Can instantiate GetKeyNameText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyNameText = user32.lookupFunction<
          Int32 Function(Int32 lParam, Pointer<Utf16> lpString, Int32 cchSize),
          int Function(int lParam, Pointer<Utf16> lpString,
              int cchSize)>('GetKeyNameTextW');
      expect(GetKeyNameText, isA<Function>());
    });
    test('Can instantiate GetKeyState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetKeyState = user32.lookupFunction<Int16 Function(Int32 nVirtKey),
          int Function(int nVirtKey)>('GetKeyState');
      expect(GetKeyState, isA<Function>());
    });
    test('Can instantiate GetLastInputInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetLastInputInfo = user32.lookupFunction<
          Int32 Function(Pointer<LASTINPUTINFO> plii),
          int Function(Pointer<LASTINPUTINFO> plii)>('GetLastInputInfo');
      expect(GetLastInputInfo, isA<Function>());
    });
    test('Can instantiate GetLayeredWindowAttributes', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetLayeredWindowAttributes = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<Uint32> pcrKey,
              Pointer<Uint8> pbAlpha, Pointer<Uint32> pdwFlags),
          int Function(int hwnd, Pointer<Uint32> pcrKey, Pointer<Uint8> pbAlpha,
              Pointer<Uint32> pdwFlags)>('GetLayeredWindowAttributes');
      expect(GetLayeredWindowAttributes, isA<Function>());
    });
    test('Can instantiate GetMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenu = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('GetMenu');
      expect(GetMenu, isA<Function>());
    });
    test('Can instantiate GetMenuInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuInfo = user32.lookupFunction<
          Int32 Function(IntPtr param0, Pointer<MENUINFO> param1),
          int Function(int param0, Pointer<MENUINFO> param1)>('GetMenuInfo');
      expect(GetMenuInfo, isA<Function>());
    });
    test('Can instantiate GetMenuItemCount', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuItemCount = user32.lookupFunction<
          Int32 Function(IntPtr hMenu),
          int Function(int hMenu)>('GetMenuItemCount');
      expect(GetMenuItemCount, isA<Function>());
    });
    test('Can instantiate GetMenuItemInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuItemInfo = user32.lookupFunction<
          Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPosition,
              Pointer<MENUITEMINFO> lpmii),
          int Function(int hmenu, int item, int fByPosition,
              Pointer<MENUITEMINFO> lpmii)>('GetMenuItemInfoW');
      expect(GetMenuItemInfo, isA<Function>());
    });
    test('Can instantiate GetMenuItemRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuItemRect = user32.lookupFunction<
          Int32 Function(
              IntPtr hWnd, IntPtr hMenu, Uint32 uItem, Pointer<RECT> lprcItem),
          int Function(int hWnd, int hMenu, int uItem,
              Pointer<RECT> lprcItem)>('GetMenuItemRect');
      expect(GetMenuItemRect, isA<Function>());
    });
    test('Can instantiate GetMenuState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuState = user32.lookupFunction<
          Uint32 Function(IntPtr hMenu, Uint32 uId, Uint32 uFlags),
          int Function(int hMenu, int uId, int uFlags)>('GetMenuState');
      expect(GetMenuState, isA<Function>());
    });
    test('Can instantiate GetMenuString', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMenuString = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uIDItem, Pointer<Utf16> lpString,
              Int32 cchMax, Uint32 flags),
          int Function(int hMenu, int uIDItem, Pointer<Utf16> lpString,
              int cchMax, int flags)>('GetMenuStringW');
      expect(GetMenuString, isA<Function>());
    });
    test('Can instantiate GetMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMessage = user32.lookupFunction<
          Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
              Uint32 wMsgFilterMax),
          int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
              int wMsgFilterMax)>('GetMessageW');
      expect(GetMessage, isA<Function>());
    });
    test('Can instantiate GetMessageExtraInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMessageExtraInfo =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetMessageExtraInfo');
      expect(GetMessageExtraInfo, isA<Function>());
    });
    test('Can instantiate GetMessagePos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMessagePos = user32
          .lookupFunction<Uint32 Function(), int Function()>('GetMessagePos');
      expect(GetMessagePos, isA<Function>());
    });
    test('Can instantiate GetMessageTime', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMessageTime = user32
          .lookupFunction<Int32 Function(), int Function()>('GetMessageTime');
      expect(GetMessageTime, isA<Function>());
    });
    test('Can instantiate GetMonitorInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMonitorInfo = user32.lookupFunction<
          Int32 Function(IntPtr hMonitor, Pointer<MONITORINFO> lpmi),
          int Function(
              int hMonitor, Pointer<MONITORINFO> lpmi)>('GetMonitorInfoW');
      expect(GetMonitorInfo, isA<Function>());
    });
    test('Can instantiate GetMouseMovePointsEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetMouseMovePointsEx = user32.lookupFunction<
          Int32 Function(
              Uint32 cbSize,
              Pointer<MOUSEMOVEPOINT> lppt,
              Pointer<MOUSEMOVEPOINT> lpptBuf,
              Int32 nBufPoints,
              Uint32 resolution),
          int Function(
              int cbSize,
              Pointer<MOUSEMOVEPOINT> lppt,
              Pointer<MOUSEMOVEPOINT> lpptBuf,
              int nBufPoints,
              int resolution)>('GetMouseMovePointsEx');
      expect(GetMouseMovePointsEx, isA<Function>());
    });
    test('Can instantiate GetNextDlgGroupItem', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetNextDlgGroupItem = user32.lookupFunction<
          IntPtr Function(IntPtr hDlg, IntPtr hCtl, Int32 bPrevious),
          int Function(
              int hDlg, int hCtl, int bPrevious)>('GetNextDlgGroupItem');
      expect(GetNextDlgGroupItem, isA<Function>());
    });
    test('Can instantiate GetNextDlgTabItem', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetNextDlgTabItem = user32.lookupFunction<
          IntPtr Function(IntPtr hDlg, IntPtr hCtl, Int32 bPrevious),
          int Function(int hDlg, int hCtl, int bPrevious)>('GetNextDlgTabItem');
      expect(GetNextDlgTabItem, isA<Function>());
    });
    test('Can instantiate GetOpenClipboardWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetOpenClipboardWindow =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetOpenClipboardWindow');
      expect(GetOpenClipboardWindow, isA<Function>());
    });
    test('Can instantiate GetParent', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetParent = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('GetParent');
      expect(GetParent, isA<Function>());
    });
    test('Can instantiate GetPhysicalCursorPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetPhysicalCursorPos = user32.lookupFunction<
          Int32 Function(Pointer<POINT> lpPoint),
          int Function(Pointer<POINT> lpPoint)>('GetPhysicalCursorPos');
      expect(GetPhysicalCursorPos, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerCursorId', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerCursorId = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Uint32> cursorId),
            int Function(
                int pointerId, Pointer<Uint32> cursorId)>('GetPointerCursorId');
        expect(GetPointerCursorId, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFrameInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFrameInfo = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
                Pointer<POINTER_INFO> pointerInfo),
            int Function(int pointerId, Pointer<Uint32> pointerCount,
                Pointer<POINTER_INFO> pointerInfo)>('GetPointerFrameInfo');
        expect(GetPointerFrameInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFrameInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFrameInfoHistory = user32.lookupFunction<
                Int32 Function(
                    Uint32 pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_INFO> pointerInfo),
                int Function(
                    int pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_INFO> pointerInfo)>(
            'GetPointerFrameInfoHistory');
        expect(GetPointerFrameInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFramePenInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFramePenInfo = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
                Pointer<POINTER_PEN_INFO> penInfo),
            int Function(int pointerId, Pointer<Uint32> pointerCount,
                Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerFramePenInfo');
        expect(GetPointerFramePenInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFramePenInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFramePenInfoHistory = user32.lookupFunction<
                Int32 Function(
                    Uint32 pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_PEN_INFO> penInfo),
                int Function(
                    int pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_PEN_INFO> penInfo)>(
            'GetPointerFramePenInfoHistory');
        expect(GetPointerFramePenInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFrameTouchInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFrameTouchInfo = user32.lookupFunction<
                Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo),
                int Function(int pointerId, Pointer<Uint32> pointerCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo)>(
            'GetPointerFrameTouchInfo');
        expect(GetPointerFrameTouchInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerFrameTouchInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerFrameTouchInfoHistory = user32.lookupFunction<
                Int32 Function(
                    Uint32 pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo),
                int Function(
                    int pointerId,
                    Pointer<Uint32> entriesCount,
                    Pointer<Uint32> pointerCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo)>(
            'GetPointerFrameTouchInfoHistory');
        expect(GetPointerFrameTouchInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerInfo = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<POINTER_INFO> pointerInfo),
            int Function(int pointerId,
                Pointer<POINTER_INFO> pointerInfo)>('GetPointerInfo');
        expect(GetPointerInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerInfoHistory = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
                Pointer<POINTER_INFO> pointerInfo),
            int Function(int pointerId, Pointer<Uint32> entriesCount,
                Pointer<POINTER_INFO> pointerInfo)>('GetPointerInfoHistory');
        expect(GetPointerInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerInputTransform', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerInputTransform = user32.lookupFunction<
                Int32 Function(Uint32 pointerId, Uint32 historyCount,
                    Pointer<INPUT_TRANSFORM> inputTransform),
                int Function(int pointerId, int historyCount,
                    Pointer<INPUT_TRANSFORM> inputTransform)>(
            'GetPointerInputTransform');
        expect(GetPointerInputTransform, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerPenInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerPenInfo = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<POINTER_PEN_INFO> penInfo),
            int Function(int pointerId,
                Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerPenInfo');
        expect(GetPointerPenInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerPenInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerPenInfoHistory = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
                Pointer<POINTER_PEN_INFO> penInfo),
            int Function(int pointerId, Pointer<Uint32> entriesCount,
                Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerPenInfoHistory');
        expect(GetPointerPenInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerTouchInfo', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerTouchInfo = user32.lookupFunction<
            Int32 Function(
                Uint32 pointerId, Pointer<POINTER_TOUCH_INFO> touchInfo),
            int Function(int pointerId,
                Pointer<POINTER_TOUCH_INFO> touchInfo)>('GetPointerTouchInfo');
        expect(GetPointerTouchInfo, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerTouchInfoHistory', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerTouchInfoHistory = user32.lookupFunction<
                Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo),
                int Function(int pointerId, Pointer<Uint32> entriesCount,
                    Pointer<POINTER_TOUCH_INFO> touchInfo)>(
            'GetPointerTouchInfoHistory');
        expect(GetPointerTouchInfoHistory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetPointerType', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetPointerType = user32.lookupFunction<
            Int32 Function(Uint32 pointerId, Pointer<Int32> pointerType),
            int Function(
                int pointerId, Pointer<Int32> pointerType)>('GetPointerType');
        expect(GetPointerType, isA<Function>());
      });
    }
    test('Can instantiate GetPriorityClipboardFormat', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetPriorityClipboardFormat = user32.lookupFunction<
          Int32 Function(Pointer<Uint32> paFormatPriorityList, Int32 cFormats),
          int Function(Pointer<Uint32> paFormatPriorityList,
              int cFormats)>('GetPriorityClipboardFormat');
      expect(GetPriorityClipboardFormat, isA<Function>());
    });
    test('Can instantiate GetProcessWindowStation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetProcessWindowStation =
          user32.lookupFunction<IntPtr Function(), int Function()>(
              'GetProcessWindowStation');
      expect(GetProcessWindowStation, isA<Function>());
    });
    test('Can instantiate GetProp', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetProp = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Pointer<Utf16> lpString),
          int Function(int hWnd, Pointer<Utf16> lpString)>('GetPropW');
      expect(GetProp, isA<Function>());
    });
    test('Can instantiate GetRawInputBuffer', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetRawInputBuffer = user32.lookupFunction<
          Uint32 Function(Pointer<RAWINPUT> pData, Pointer<Uint32> pcbSize,
              Uint32 cbSizeHeader),
          int Function(Pointer<RAWINPUT> pData, Pointer<Uint32> pcbSize,
              int cbSizeHeader)>('GetRawInputBuffer');
      expect(GetRawInputBuffer, isA<Function>());
    });
    test('Can instantiate GetRawInputData', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetRawInputData = user32.lookupFunction<
          Uint32 Function(IntPtr hRawInput, Uint32 uiCommand, Pointer pData,
              Pointer<Uint32> pcbSize, Uint32 cbSizeHeader),
          int Function(int hRawInput, int uiCommand, Pointer pData,
              Pointer<Uint32> pcbSize, int cbSizeHeader)>('GetRawInputData');
      expect(GetRawInputData, isA<Function>());
    });
    test('Can instantiate GetRawInputDeviceInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetRawInputDeviceInfo = user32.lookupFunction<
          Uint32 Function(IntPtr hDevice, Uint32 uiCommand, Pointer pData,
              Pointer<Uint32> pcbSize),
          int Function(int hDevice, int uiCommand, Pointer pData,
              Pointer<Uint32> pcbSize)>('GetRawInputDeviceInfoW');
      expect(GetRawInputDeviceInfo, isA<Function>());
    });
    test('Can instantiate GetRawInputDeviceList', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetRawInputDeviceList = user32.lookupFunction<
          Uint32 Function(Pointer<RAWINPUTDEVICELIST> pRawInputDeviceList,
              Pointer<Uint32> puiNumDevices, Uint32 cbSize),
          int Function(
              Pointer<RAWINPUTDEVICELIST> pRawInputDeviceList,
              Pointer<Uint32> puiNumDevices,
              int cbSize)>('GetRawInputDeviceList');
      expect(GetRawInputDeviceList, isA<Function>());
    });
    test('Can instantiate GetRegisteredRawInputDevices', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetRegisteredRawInputDevices = user32.lookupFunction<
          Uint32 Function(Pointer<RAWINPUTDEVICE> pRawInputDevices,
              Pointer<Uint32> puiNumDevices, Uint32 cbSize),
          int Function(
              Pointer<RAWINPUTDEVICE> pRawInputDevices,
              Pointer<Uint32> puiNumDevices,
              int cbSize)>('GetRegisteredRawInputDevices');
      expect(GetRegisteredRawInputDevices, isA<Function>());
    });
    test('Can instantiate GetScrollBarInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetScrollBarInfo = user32.lookupFunction<
          Int32 Function(
              IntPtr hwnd, Int32 idObject, Pointer<SCROLLBARINFO> psbi),
          int Function(int hwnd, int idObject,
              Pointer<SCROLLBARINFO> psbi)>('GetScrollBarInfo');
      expect(GetScrollBarInfo, isA<Function>());
    });
    test('Can instantiate GetScrollInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetScrollInfo = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Uint32 nBar, Pointer<SCROLLINFO> lpsi),
          int Function(
              int hwnd, int nBar, Pointer<SCROLLINFO> lpsi)>('GetScrollInfo');
      expect(GetScrollInfo, isA<Function>());
    });
    test('Can instantiate GetShellWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetShellWindow = user32
          .lookupFunction<IntPtr Function(), int Function()>('GetShellWindow');
      expect(GetShellWindow, isA<Function>());
    });
    test('Can instantiate GetSubMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetSubMenu = user32.lookupFunction<
          IntPtr Function(IntPtr hMenu, Int32 nPos),
          int Function(int hMenu, int nPos)>('GetSubMenu');
      expect(GetSubMenu, isA<Function>());
    });
    test('Can instantiate GetSysColor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetSysColor = user32.lookupFunction<Uint32 Function(Int32 nIndex),
          int Function(int nIndex)>('GetSysColor');
      expect(GetSysColor, isA<Function>());
    });
    test('Can instantiate GetSysColorBrush', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetSysColorBrush = user32.lookupFunction<
          IntPtr Function(Int32 nIndex),
          int Function(int nIndex)>('GetSysColorBrush');
      expect(GetSysColorBrush, isA<Function>());
    });
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate GetSystemDpiForProcess', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetSystemDpiForProcess = user32.lookupFunction<
            Uint32 Function(IntPtr hProcess),
            int Function(int hProcess)>('GetSystemDpiForProcess');
        expect(GetSystemDpiForProcess, isA<Function>());
      });
    }
    test('Can instantiate GetSystemMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetSystemMenu = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Int32 bRevert),
          int Function(int hWnd, int bRevert)>('GetSystemMenu');
      expect(GetSystemMenu, isA<Function>());
    });
    test('Can instantiate GetSystemMetrics', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetSystemMetrics = user32.lookupFunction<
          Int32 Function(Uint32 nIndex),
          int Function(int nIndex)>('GetSystemMetrics');
      expect(GetSystemMetrics, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetSystemMetricsForDpi', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetSystemMetricsForDpi = user32.lookupFunction<
            Int32 Function(Uint32 nIndex, Uint32 dpi),
            int Function(int nIndex, int dpi)>('GetSystemMetricsForDpi');
        expect(GetSystemMetricsForDpi, isA<Function>());
      });
    }
    test('Can instantiate GetTabbedTextExtent', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetTabbedTextExtent = user32.lookupFunction<
          Uint32 Function(IntPtr hdc, Pointer<Utf16> lpString, Int32 chCount,
              Int32 nTabPositions, Pointer<Int32> lpnTabStopPositions),
          int Function(
              int hdc,
              Pointer<Utf16> lpString,
              int chCount,
              int nTabPositions,
              Pointer<Int32> lpnTabStopPositions)>('GetTabbedTextExtentW');
      expect(GetTabbedTextExtent, isA<Function>());
    });
    test('Can instantiate GetThreadDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetThreadDesktop = user32.lookupFunction<
          IntPtr Function(Uint32 dwThreadId),
          int Function(int dwThreadId)>('GetThreadDesktop');
      expect(GetThreadDesktop, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetThreadDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetThreadDpiAwarenessContext =
            user32.lookupFunction<IntPtr Function(), int Function()>(
                'GetThreadDpiAwarenessContext');
        expect(GetThreadDpiAwarenessContext, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate GetThreadDpiHostingBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetThreadDpiHostingBehavior =
            user32.lookupFunction<Int32 Function(), int Function()>(
                'GetThreadDpiHostingBehavior');
        expect(GetThreadDpiHostingBehavior, isA<Function>());
      });
    }
    test('Can instantiate GetTitleBarInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetTitleBarInfo = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<TITLEBARINFO> pti),
          int Function(int hwnd, Pointer<TITLEBARINFO> pti)>('GetTitleBarInfo');
      expect(GetTitleBarInfo, isA<Function>());
    });
    test('Can instantiate GetTopWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetTopWindow = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('GetTopWindow');
      expect(GetTopWindow, isA<Function>());
    });
    test('Can instantiate GetTouchInputInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetTouchInputInfo = user32.lookupFunction<
          Int32 Function(IntPtr hTouchInput, Uint32 cInputs,
              Pointer<TOUCHINPUT> pInputs, Int32 cbSize),
          int Function(int hTouchInput, int cInputs,
              Pointer<TOUCHINPUT> pInputs, int cbSize)>('GetTouchInputInfo');
      expect(GetTouchInputInfo, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate GetUnpredictedMessagePos', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetUnpredictedMessagePos =
            user32.lookupFunction<Uint32 Function(), int Function()>(
                'GetUnpredictedMessagePos');
        expect(GetUnpredictedMessagePos, isA<Function>());
      });
    }
    test('Can instantiate GetUpdatedClipboardFormats', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetUpdatedClipboardFormats = user32.lookupFunction<
          Int32 Function(Pointer<Uint32> lpuiFormats, Uint32 cFormats,
              Pointer<Uint32> pcFormatsOut),
          int Function(Pointer<Uint32> lpuiFormats, int cFormats,
              Pointer<Uint32> pcFormatsOut)>('GetUpdatedClipboardFormats');
      expect(GetUpdatedClipboardFormats, isA<Function>());
    });
    test('Can instantiate GetUpdateRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetUpdateRect = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect, Int32 bErase),
          int Function(
              int hWnd, Pointer<RECT> lpRect, int bErase)>('GetUpdateRect');
      expect(GetUpdateRect, isA<Function>());
    });
    test('Can instantiate GetUpdateRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetUpdateRgn = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bErase),
          int Function(int hWnd, int hRgn, int bErase)>('GetUpdateRgn');
      expect(GetUpdateRgn, isA<Function>());
    });
    test('Can instantiate GetUserObjectInformation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetUserObjectInformation = user32.lookupFunction<
          Int32 Function(IntPtr hObj, Uint32 nIndex, Pointer pvInfo,
              Uint32 nLength, Pointer<Uint32> lpnLengthNeeded),
          int Function(int hObj, int nIndex, Pointer pvInfo, int nLength,
              Pointer<Uint32> lpnLengthNeeded)>('GetUserObjectInformationW');
      expect(GetUserObjectInformation, isA<Function>());
    });
    test('Can instantiate GetWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindow = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Uint32 uCmd),
          int Function(int hWnd, int uCmd)>('GetWindow');
      expect(GetWindow, isA<Function>());
    });
    test('Can instantiate GetWindowDC', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowDC = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('GetWindowDC');
      expect(GetWindowDC, isA<Function>());
    });
    test('Can instantiate GetWindowDisplayAffinity', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowDisplayAffinity = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Uint32> pdwAffinity),
          int Function(int hWnd,
              Pointer<Uint32> pdwAffinity)>('GetWindowDisplayAffinity');
      expect(GetWindowDisplayAffinity, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate GetWindowDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetWindowDpiAwarenessContext = user32.lookupFunction<
            IntPtr Function(IntPtr hwnd),
            int Function(int hwnd)>('GetWindowDpiAwarenessContext');
        expect(GetWindowDpiAwarenessContext, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate GetWindowDpiHostingBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final GetWindowDpiHostingBehavior = user32.lookupFunction<
            Int32 Function(IntPtr hwnd),
            int Function(int hwnd)>('GetWindowDpiHostingBehavior');
        expect(GetWindowDpiHostingBehavior, isA<Function>());
      });
    }
    test('Can instantiate GetWindowInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowInfo = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<WINDOWINFO> pwi),
          int Function(int hwnd, Pointer<WINDOWINFO> pwi)>('GetWindowInfo');
      expect(GetWindowInfo, isA<Function>());
    });
    test('Can instantiate GetWindowLongPtr', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowLongPtr = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Int32 nIndex),
          int Function(int hWnd, int nIndex)>('GetWindowLongPtrW');
      expect(GetWindowLongPtr, isA<Function>());
    });
    test('Can instantiate GetWindowModuleFileName', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowModuleFileName = user32.lookupFunction<
          Uint32 Function(
              IntPtr hwnd, Pointer<Utf16> pszFileName, Uint32 cchFileNameMax),
          int Function(int hwnd, Pointer<Utf16> pszFileName,
              int cchFileNameMax)>('GetWindowModuleFileNameW');
      expect(GetWindowModuleFileName, isA<Function>());
    });
    test('Can instantiate GetWindowPlacement', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowPlacement = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<WINDOWPLACEMENT> lpwndpl),
          int Function(int hWnd,
              Pointer<WINDOWPLACEMENT> lpwndpl)>('GetWindowPlacement');
      expect(GetWindowPlacement, isA<Function>());
    });
    test('Can instantiate GetWindowRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowRect = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
          int Function(int hWnd, Pointer<RECT> lpRect)>('GetWindowRect');
      expect(GetWindowRect, isA<Function>());
    });
    test('Can instantiate GetWindowRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowRgn = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hRgn),
          int Function(int hWnd, int hRgn)>('GetWindowRgn');
      expect(GetWindowRgn, isA<Function>());
    });
    test('Can instantiate GetWindowRgnBox', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowRgnBox = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lprc),
          int Function(int hWnd, Pointer<RECT> lprc)>('GetWindowRgnBox');
      expect(GetWindowRgnBox, isA<Function>());
    });
    test('Can instantiate GetWindowText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowText = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString, Int32 nMaxCount),
          int Function(int hWnd, Pointer<Utf16> lpString,
              int nMaxCount)>('GetWindowTextW');
      expect(GetWindowText, isA<Function>());
    });
    test('Can instantiate GetWindowTextLength', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowTextLength = user32.lookupFunction<
          Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('GetWindowTextLengthW');
      expect(GetWindowTextLength, isA<Function>());
    });
    test('Can instantiate GetWindowThreadProcessId', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GetWindowThreadProcessId = user32.lookupFunction<
          Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId),
          int Function(int hWnd,
              Pointer<Uint32> lpdwProcessId)>('GetWindowThreadProcessId');
      expect(GetWindowThreadProcessId, isA<Function>());
    });
    test('Can instantiate GrayString', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final GrayString = user32.lookupFunction<
          Int32 Function(
              IntPtr hDC,
              IntPtr hBrush,
              Pointer<NativeFunction<OutputProc>> lpOutputFunc,
              IntPtr lpData,
              Int32 nCount,
              Int32 X,
              Int32 Y,
              Int32 nWidth,
              Int32 nHeight),
          int Function(
              int hDC,
              int hBrush,
              Pointer<NativeFunction<OutputProc>> lpOutputFunc,
              int lpData,
              int nCount,
              int X,
              int Y,
              int nWidth,
              int nHeight)>('GrayStringW');
      expect(GrayString, isA<Function>());
    });
    test('Can instantiate HideCaret', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final HideCaret = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('HideCaret');
      expect(HideCaret, isA<Function>());
    });
    test('Can instantiate InflateRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InflateRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc, Int32 dx, Int32 dy),
          int Function(Pointer<RECT> lprc, int dx, int dy)>('InflateRect');
      expect(InflateRect, isA<Function>());
    });
    test('Can instantiate InSendMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InSendMessage = user32
          .lookupFunction<Int32 Function(), int Function()>('InSendMessage');
      expect(InSendMessage, isA<Function>());
    });
    test('Can instantiate InSendMessageEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InSendMessageEx = user32.lookupFunction<
          Uint32 Function(Pointer lpReserved),
          int Function(Pointer lpReserved)>('InSendMessageEx');
      expect(InSendMessageEx, isA<Function>());
    });
    test('Can instantiate InsertMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InsertMenu = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags,
              IntPtr uIDNewItem, Pointer<Utf16> lpNewItem),
          int Function(int hMenu, int uPosition, int uFlags, int uIDNewItem,
              Pointer<Utf16> lpNewItem)>('InsertMenuW');
      expect(InsertMenu, isA<Function>());
    });
    test('Can instantiate InsertMenuItem', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InsertMenuItem = user32.lookupFunction<
          Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPosition,
              Pointer<MENUITEMINFO> lpmi),
          int Function(int hmenu, int item, int fByPosition,
              Pointer<MENUITEMINFO> lpmi)>('InsertMenuItemW');
      expect(InsertMenuItem, isA<Function>());
    });
    test('Can instantiate IntersectRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IntersectRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2),
          int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2)>('IntersectRect');
      expect(IntersectRect, isA<Function>());
    });
    test('Can instantiate InvalidateRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InvalidateRect = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect, Int32 bErase),
          int Function(
              int hWnd, Pointer<RECT> lpRect, int bErase)>('InvalidateRect');
      expect(InvalidateRect, isA<Function>());
    });
    test('Can instantiate InvalidateRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InvalidateRgn = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bErase),
          int Function(int hWnd, int hRgn, int bErase)>('InvalidateRgn');
      expect(InvalidateRgn, isA<Function>());
    });
    test('Can instantiate InvertRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final InvertRect = user32.lookupFunction<
          Int32 Function(IntPtr hDC, Pointer<RECT> lprc),
          int Function(int hDC, Pointer<RECT> lprc)>('InvertRect');
      expect(InvertRect, isA<Function>());
    });
    test('Can instantiate IsChild', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsChild = user32.lookupFunction<
          Int32 Function(IntPtr hWndParent, IntPtr hWnd),
          int Function(int hWndParent, int hWnd)>('IsChild');
      expect(IsChild, isA<Function>());
    });
    test('Can instantiate IsClipboardFormatAvailable', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsClipboardFormatAvailable = user32.lookupFunction<
          Int32 Function(Uint32 format),
          int Function(int format)>('IsClipboardFormatAvailable');
      expect(IsClipboardFormatAvailable, isA<Function>());
    });
    test('Can instantiate IsDialogMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsDialogMessage = user32.lookupFunction<
          Int32 Function(IntPtr hDlg, Pointer<MSG> lpMsg),
          int Function(int hDlg, Pointer<MSG> lpMsg)>('IsDialogMessageW');
      expect(IsDialogMessage, isA<Function>());
    });
    test('Can instantiate IsDlgButtonChecked', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsDlgButtonChecked = user32.lookupFunction<
          Uint32 Function(IntPtr hDlg, Int32 nIDButton),
          int Function(int hDlg, int nIDButton)>('IsDlgButtonChecked');
      expect(IsDlgButtonChecked, isA<Function>());
    });
    test('Can instantiate IsGUIThread', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsGUIThread = user32.lookupFunction<Int32 Function(Int32 bConvert),
          int Function(int bConvert)>('IsGUIThread');
      expect(IsGUIThread, isA<Function>());
    });
    test('Can instantiate IsHungAppWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsHungAppWindow = user32.lookupFunction<Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('IsHungAppWindow');
      expect(IsHungAppWindow, isA<Function>());
    });
    test('Can instantiate IsIconic', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsIconic = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsIconic');
      expect(IsIconic, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate IsImmersiveProcess', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final IsImmersiveProcess = user32.lookupFunction<
            Int32 Function(IntPtr hProcess),
            int Function(int hProcess)>('IsImmersiveProcess');
        expect(IsImmersiveProcess, isA<Function>());
      });
    }
    test('Can instantiate IsMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsMenu = user32.lookupFunction<Int32 Function(IntPtr hMenu),
          int Function(int hMenu)>('IsMenu');
      expect(IsMenu, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate IsMouseInPointerEnabled', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final IsMouseInPointerEnabled =
            user32.lookupFunction<Int32 Function(), int Function()>(
                'IsMouseInPointerEnabled');
        expect(IsMouseInPointerEnabled, isA<Function>());
      });
    }
    test('Can instantiate IsProcessDPIAware', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsProcessDPIAware =
          user32.lookupFunction<Int32 Function(), int Function()>(
              'IsProcessDPIAware');
      expect(IsProcessDPIAware, isA<Function>());
    });
    test('Can instantiate IsRectEmpty', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsRectEmpty = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc),
          int Function(Pointer<RECT> lprc)>('IsRectEmpty');
      expect(IsRectEmpty, isA<Function>());
    });
    test('Can instantiate IsTouchWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsTouchWindow = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<Uint32> pulFlags),
          int Function(int hwnd, Pointer<Uint32> pulFlags)>('IsTouchWindow');
      expect(IsTouchWindow, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate IsValidDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final IsValidDpiAwarenessContext = user32.lookupFunction<
            Int32 Function(IntPtr value),
            int Function(int value)>('IsValidDpiAwarenessContext');
        expect(IsValidDpiAwarenessContext, isA<Function>());
      });
    }
    test('Can instantiate IsWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsWindow = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsWindow');
      expect(IsWindow, isA<Function>());
    });
    test('Can instantiate IsWindowEnabled', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsWindowEnabled = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsWindowEnabled');
      expect(IsWindowEnabled, isA<Function>());
    });
    test('Can instantiate IsWindowUnicode', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsWindowUnicode = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsWindowUnicode');
      expect(IsWindowUnicode, isA<Function>());
    });
    test('Can instantiate IsWindowVisible', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsWindowVisible = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsWindowVisible');
      expect(IsWindowVisible, isA<Function>());
    });
    test('Can instantiate IsWow64Message', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsWow64Message = user32
          .lookupFunction<Int32 Function(), int Function()>('IsWow64Message');
      expect(IsWow64Message, isA<Function>());
    });
    test('Can instantiate IsZoomed', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final IsZoomed = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('IsZoomed');
      expect(IsZoomed, isA<Function>());
    });
    test('Can instantiate KillTimer', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final KillTimer = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr uIDEvent),
          int Function(int hWnd, int uIDEvent)>('KillTimer');
      expect(KillTimer, isA<Function>());
    });
    test('Can instantiate LoadAccelerators', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadAccelerators = user32.lookupFunction<
          IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpTableName),
          int Function(
              int hInstance, Pointer<Utf16> lpTableName)>('LoadAcceleratorsW');
      expect(LoadAccelerators, isA<Function>());
    });
    test('Can instantiate LoadCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadCursor = user32.lookupFunction<
          IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpCursorName),
          int Function(
              int hInstance, Pointer<Utf16> lpCursorName)>('LoadCursorW');
      expect(LoadCursor, isA<Function>());
    });
    test('Can instantiate LoadCursorFromFile', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadCursorFromFile = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpFileName),
          int Function(Pointer<Utf16> lpFileName)>('LoadCursorFromFileW');
      expect(LoadCursorFromFile, isA<Function>());
    });
    test('Can instantiate LoadIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadIcon = user32.lookupFunction<
          IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpIconName),
          int Function(int hInstance, Pointer<Utf16> lpIconName)>('LoadIconW');
      expect(LoadIcon, isA<Function>());
    });
    test('Can instantiate LoadImage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadImage = user32.lookupFunction<
          IntPtr Function(IntPtr hInst, Pointer<Utf16> name, Uint32 type,
              Int32 cx, Int32 cy, Uint32 fuLoad),
          int Function(int hInst, Pointer<Utf16> name, int type, int cx, int cy,
              int fuLoad)>('LoadImageW');
      expect(LoadImage, isA<Function>());
    });
    test('Can instantiate LoadKeyboardLayout', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadKeyboardLayout = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16> pwszKLID, Uint32 Flags),
          int Function(
              Pointer<Utf16> pwszKLID, int Flags)>('LoadKeyboardLayoutW');
      expect(LoadKeyboardLayout, isA<Function>());
    });
    test('Can instantiate LoadMenuIndirect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadMenuIndirect = user32.lookupFunction<
          IntPtr Function(Pointer lpMenuTemplate),
          int Function(Pointer lpMenuTemplate)>('LoadMenuIndirectW');
      expect(LoadMenuIndirect, isA<Function>());
    });
    test('Can instantiate LoadString', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LoadString = user32.lookupFunction<
          Int32 Function(IntPtr hInstance, Uint32 uID, Pointer<Utf16> lpBuffer,
              Int32 cchBufferMax),
          int Function(int hInstance, int uID, Pointer<Utf16> lpBuffer,
              int cchBufferMax)>('LoadStringW');
      expect(LoadString, isA<Function>());
    });
    test('Can instantiate LockSetForegroundWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LockSetForegroundWindow = user32.lookupFunction<
          Int32 Function(Uint32 uLockCode),
          int Function(int uLockCode)>('LockSetForegroundWindow');
      expect(LockSetForegroundWindow, isA<Function>());
    });
    test('Can instantiate LockWindowUpdate', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LockWindowUpdate = user32.lookupFunction<
          Int32 Function(IntPtr hWndLock),
          int Function(int hWndLock)>('LockWindowUpdate');
      expect(LockWindowUpdate, isA<Function>());
    });
    test('Can instantiate LockWorkStation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LockWorkStation = user32
          .lookupFunction<Int32 Function(), int Function()>('LockWorkStation');
      expect(LockWorkStation, isA<Function>());
    });
    test('Can instantiate LogicalToPhysicalPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LogicalToPhysicalPoint = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
          int Function(
              int hWnd, Pointer<POINT> lpPoint)>('LogicalToPhysicalPoint');
      expect(LogicalToPhysicalPoint, isA<Function>());
    });
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate LogicalToPhysicalPointForPerMonitorDPI', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final LogicalToPhysicalPointForPerMonitorDPI = user32.lookupFunction<
                Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
                int Function(int hWnd, Pointer<POINT> lpPoint)>(
            'LogicalToPhysicalPointForPerMonitorDPI');
        expect(LogicalToPhysicalPointForPerMonitorDPI, isA<Function>());
      });
    }
    test('Can instantiate LookupIconIdFromDirectory', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LookupIconIdFromDirectory = user32.lookupFunction<
          Int32 Function(Pointer<Uint8> presbits, Int32 fIcon),
          int Function(
              Pointer<Uint8> presbits, int fIcon)>('LookupIconIdFromDirectory');
      expect(LookupIconIdFromDirectory, isA<Function>());
    });
    test('Can instantiate LookupIconIdFromDirectoryEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final LookupIconIdFromDirectoryEx = user32.lookupFunction<
          Int32 Function(Pointer<Uint8> presbits, Int32 fIcon, Int32 cxDesired,
              Int32 cyDesired, Uint32 Flags),
          int Function(Pointer<Uint8> presbits, int fIcon, int cxDesired,
              int cyDesired, int Flags)>('LookupIconIdFromDirectoryEx');
      expect(LookupIconIdFromDirectoryEx, isA<Function>());
    });
    test('Can instantiate MapDialogRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MapDialogRect = user32.lookupFunction<
          Int32 Function(IntPtr hDlg, Pointer<RECT> lpRect),
          int Function(int hDlg, Pointer<RECT> lpRect)>('MapDialogRect');
      expect(MapDialogRect, isA<Function>());
    });
    test('Can instantiate MapVirtualKey', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MapVirtualKey = user32.lookupFunction<
          Uint32 Function(Uint32 uCode, Uint32 uMapType),
          int Function(int uCode, int uMapType)>('MapVirtualKeyW');
      expect(MapVirtualKey, isA<Function>());
    });
    test('Can instantiate MapVirtualKeyEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MapVirtualKeyEx = user32.lookupFunction<
          Uint32 Function(Uint32 uCode, Uint32 uMapType, IntPtr dwhkl),
          int Function(int uCode, int uMapType, int dwhkl)>('MapVirtualKeyExW');
      expect(MapVirtualKeyEx, isA<Function>());
    });
    test('Can instantiate MapWindowPoints', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MapWindowPoints = user32.lookupFunction<
          Int32 Function(IntPtr hWndFrom, IntPtr hWndTo,
              Pointer<POINT> lpPoints, Uint32 cPoints),
          int Function(int hWndFrom, int hWndTo, Pointer<POINT> lpPoints,
              int cPoints)>('MapWindowPoints');
      expect(MapWindowPoints, isA<Function>());
    });
    test('Can instantiate MenuItemFromPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MenuItemFromPoint = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hMenu, POINT ptScreen),
          int Function(
              int hWnd, int hMenu, POINT ptScreen)>('MenuItemFromPoint');
      expect(MenuItemFromPoint, isA<Function>());
    });
    test('Can instantiate MessageBox', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MessageBox = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText,
              Pointer<Utf16> lpCaption, Uint32 uType),
          int Function(int hWnd, Pointer<Utf16> lpText,
              Pointer<Utf16> lpCaption, int uType)>('MessageBoxW');
      expect(MessageBox, isA<Function>());
    });
    test('Can instantiate MessageBoxEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MessageBoxEx = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText,
              Pointer<Utf16> lpCaption, Uint32 uType, Uint16 wLanguageId),
          int Function(
              int hWnd,
              Pointer<Utf16> lpText,
              Pointer<Utf16> lpCaption,
              int uType,
              int wLanguageId)>('MessageBoxExW');
      expect(MessageBoxEx, isA<Function>());
    });
    test('Can instantiate ModifyMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ModifyMenu = user32.lookupFunction<
          Int32 Function(IntPtr hMnu, Uint32 uPosition, Uint32 uFlags,
              IntPtr uIDNewItem, Pointer<Utf16> lpNewItem),
          int Function(int hMnu, int uPosition, int uFlags, int uIDNewItem,
              Pointer<Utf16> lpNewItem)>('ModifyMenuW');
      expect(ModifyMenu, isA<Function>());
    });
    test('Can instantiate MonitorFromPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MonitorFromPoint = user32.lookupFunction<
          IntPtr Function(POINT pt, Uint32 dwFlags),
          int Function(POINT pt, int dwFlags)>('MonitorFromPoint');
      expect(MonitorFromPoint, isA<Function>());
    });
    test('Can instantiate MonitorFromRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MonitorFromRect = user32.lookupFunction<
          IntPtr Function(Pointer<RECT> lprc, Uint32 dwFlags),
          int Function(Pointer<RECT> lprc, int dwFlags)>('MonitorFromRect');
      expect(MonitorFromRect, isA<Function>());
    });
    test('Can instantiate MonitorFromWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MonitorFromWindow = user32.lookupFunction<
          IntPtr Function(IntPtr hwnd, Uint32 dwFlags),
          int Function(int hwnd, int dwFlags)>('MonitorFromWindow');
      expect(MonitorFromWindow, isA<Function>());
    });
    test('Can instantiate MoveWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MoveWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 X, Int32 Y, Int32 nWidth,
              Int32 nHeight, Int32 bRepaint),
          int Function(int hWnd, int X, int Y, int nWidth, int nHeight,
              int bRepaint)>('MoveWindow');
      expect(MoveWindow, isA<Function>());
    });
    test('Can instantiate MsgWaitForMultipleObjects', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MsgWaitForMultipleObjects = user32.lookupFunction<
          Uint32 Function(Uint32 nCount, Pointer<IntPtr> pHandles,
              Int32 fWaitAll, Uint32 dwMilliseconds, Uint32 dwWakeMask),
          int Function(int nCount, Pointer<IntPtr> pHandles, int fWaitAll,
              int dwMilliseconds, int dwWakeMask)>('MsgWaitForMultipleObjects');
      expect(MsgWaitForMultipleObjects, isA<Function>());
    });
    test('Can instantiate MsgWaitForMultipleObjectsEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final MsgWaitForMultipleObjectsEx = user32.lookupFunction<
          Uint32 Function(Uint32 nCount, Pointer<IntPtr> pHandles,
              Uint32 dwMilliseconds, Uint32 dwWakeMask, Uint32 dwFlags),
          int Function(int nCount, Pointer<IntPtr> pHandles, int dwMilliseconds,
              int dwWakeMask, int dwFlags)>('MsgWaitForMultipleObjectsEx');
      expect(MsgWaitForMultipleObjectsEx, isA<Function>());
    });
    test('Can instantiate NotifyWinEvent', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final NotifyWinEvent = user32.lookupFunction<
          Void Function(
              Uint32 event, IntPtr hwnd, Int32 idObject, Int32 idChild),
          void Function(int event, int hwnd, int idObject,
              int idChild)>('NotifyWinEvent');
      expect(NotifyWinEvent, isA<Function>());
    });
    test('Can instantiate OemKeyScan', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OemKeyScan = user32.lookupFunction<Uint32 Function(Uint16 wOemChar),
          int Function(int wOemChar)>('OemKeyScan');
      expect(OemKeyScan, isA<Function>());
    });
    test('Can instantiate OffsetRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OffsetRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc, Int32 dx, Int32 dy),
          int Function(Pointer<RECT> lprc, int dx, int dy)>('OffsetRect');
      expect(OffsetRect, isA<Function>());
    });
    test('Can instantiate OpenClipboard', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OpenClipboard = user32.lookupFunction<
          Int32 Function(IntPtr hWndNewOwner),
          int Function(int hWndNewOwner)>('OpenClipboard');
      expect(OpenClipboard, isA<Function>());
    });
    test('Can instantiate OpenDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OpenDesktop = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpszDesktop, Uint32 dwFlags,
              Int32 fInherit, Uint32 dwDesiredAccess),
          int Function(Pointer<Utf16> lpszDesktop, int dwFlags, int fInherit,
              int dwDesiredAccess)>('OpenDesktopW');
      expect(OpenDesktop, isA<Function>());
    });
    test('Can instantiate OpenIcon', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OpenIcon = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('OpenIcon');
      expect(OpenIcon, isA<Function>());
    });
    test('Can instantiate OpenInputDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OpenInputDesktop = user32.lookupFunction<
          IntPtr Function(
              Uint32 dwFlags, Int32 fInherit, Uint32 dwDesiredAccess),
          int Function(int dwFlags, int fInherit,
              int dwDesiredAccess)>('OpenInputDesktop');
      expect(OpenInputDesktop, isA<Function>());
    });
    test('Can instantiate OpenWindowStation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final OpenWindowStation = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpszWinSta, Int32 fInherit,
              Uint32 dwDesiredAccess),
          int Function(Pointer<Utf16> lpszWinSta, int fInherit,
              int dwDesiredAccess)>('OpenWindowStationW');
      expect(OpenWindowStation, isA<Function>());
    });
    test('Can instantiate PaintDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PaintDesktop = user32.lookupFunction<Int32 Function(IntPtr hdc),
          int Function(int hdc)>('PaintDesktop');
      expect(PaintDesktop, isA<Function>());
    });
    test('Can instantiate PeekMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PeekMessage = user32.lookupFunction<
          Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
              Uint32 wMsgFilterMax, Uint32 wRemoveMsg),
          int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
              int wMsgFilterMax, int wRemoveMsg)>('PeekMessageW');
      expect(PeekMessage, isA<Function>());
    });
    test('Can instantiate PhysicalToLogicalPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PhysicalToLogicalPoint = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
          int Function(
              int hWnd, Pointer<POINT> lpPoint)>('PhysicalToLogicalPoint');
      expect(PhysicalToLogicalPoint, isA<Function>());
    });
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate PhysicalToLogicalPointForPerMonitorDPI', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final PhysicalToLogicalPointForPerMonitorDPI = user32.lookupFunction<
                Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
                int Function(int hWnd, Pointer<POINT> lpPoint)>(
            'PhysicalToLogicalPointForPerMonitorDPI');
        expect(PhysicalToLogicalPointForPerMonitorDPI, isA<Function>());
      });
    }
    test('Can instantiate PostMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PostMessage = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int Msg, int wParam, int lParam)>('PostMessageW');
      expect(PostMessage, isA<Function>());
    });
    test('Can instantiate PostQuitMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PostQuitMessage = user32.lookupFunction<
          Void Function(Int32 nExitCode),
          void Function(int nExitCode)>('PostQuitMessage');
      expect(PostQuitMessage, isA<Function>());
    });
    test('Can instantiate PostThreadMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PostThreadMessage = user32.lookupFunction<
          Int32 Function(
              Uint32 idThread, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(int idThread, int Msg, int wParam,
              int lParam)>('PostThreadMessageW');
      expect(PostThreadMessage, isA<Function>());
    });
    test('Can instantiate PrintWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PrintWindow = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, IntPtr hdcBlt, Uint32 nFlags),
          int Function(int hwnd, int hdcBlt, int nFlags)>('PrintWindow');
      expect(PrintWindow, isA<Function>());
    });
    test('Can instantiate PtInRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final PtInRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc, POINT pt),
          int Function(Pointer<RECT> lprc, POINT pt)>('PtInRect');
      expect(PtInRect, isA<Function>());
    });
    test('Can instantiate RedrawWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RedrawWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lprcUpdate,
              IntPtr hrgnUpdate, Uint32 flags),
          int Function(int hWnd, Pointer<RECT> lprcUpdate, int hrgnUpdate,
              int flags)>('RedrawWindow');
      expect(RedrawWindow, isA<Function>());
    });
    test('Can instantiate RegisterClass', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterClass = user32.lookupFunction<
          Uint16 Function(Pointer<WNDCLASS> lpWndClass),
          int Function(Pointer<WNDCLASS> lpWndClass)>('RegisterClassW');
      expect(RegisterClass, isA<Function>());
    });
    test('Can instantiate RegisterClassEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterClassEx = user32.lookupFunction<
          Uint16 Function(Pointer<WNDCLASSEX> param0),
          int Function(Pointer<WNDCLASSEX> param0)>('RegisterClassExW');
      expect(RegisterClassEx, isA<Function>());
    });
    test('Can instantiate RegisterClipboardFormat', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterClipboardFormat = user32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpszFormat),
          int Function(Pointer<Utf16> lpszFormat)>('RegisterClipboardFormatW');
      expect(RegisterClipboardFormat, isA<Function>());
    });
    test('Can instantiate RegisterHotKey', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterHotKey = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 id, Uint32 fsModifiers, Uint32 vk),
          int Function(
              int hWnd, int id, int fsModifiers, int vk)>('RegisterHotKey');
      expect(RegisterHotKey, isA<Function>());
    });
    test('Can instantiate RegisterPowerSettingNotification', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterPowerSettingNotification = user32.lookupFunction<
          IntPtr Function(
              IntPtr hRecipient, Pointer<GUID> PowerSettingGuid, Uint32 Flags),
          int Function(int hRecipient, Pointer<GUID> PowerSettingGuid,
              int Flags)>('RegisterPowerSettingNotification');
      expect(RegisterPowerSettingNotification, isA<Function>());
    });
    test('Can instantiate RegisterRawInputDevices', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterRawInputDevices = user32.lookupFunction<
          Int32 Function(Pointer<RAWINPUTDEVICE> pRawInputDevices,
              Uint32 uiNumDevices, Uint32 cbSize),
          int Function(Pointer<RAWINPUTDEVICE> pRawInputDevices,
              int uiNumDevices, int cbSize)>('RegisterRawInputDevices');
      expect(RegisterRawInputDevices, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RegisterTouchHitTestingWindow', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final RegisterTouchHitTestingWindow = user32.lookupFunction<
            Int32 Function(IntPtr hwnd, Uint32 value),
            int Function(int hwnd, int value)>('RegisterTouchHitTestingWindow');
        expect(RegisterTouchHitTestingWindow, isA<Function>());
      });
    }
    test('Can instantiate RegisterTouchWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterTouchWindow = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Uint32 ulFlags),
          int Function(int hwnd, int ulFlags)>('RegisterTouchWindow');
      expect(RegisterTouchWindow, isA<Function>());
    });
    test('Can instantiate RegisterWindowMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RegisterWindowMessage = user32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpString),
          int Function(Pointer<Utf16> lpString)>('RegisterWindowMessageW');
      expect(RegisterWindowMessage, isA<Function>());
    });
    test('Can instantiate ReleaseCapture', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ReleaseCapture = user32
          .lookupFunction<Int32 Function(), int Function()>('ReleaseCapture');
      expect(ReleaseCapture, isA<Function>());
    });
    test('Can instantiate ReleaseDC', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ReleaseDC = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hDC),
          int Function(int hWnd, int hDC)>('ReleaseDC');
      expect(ReleaseDC, isA<Function>());
    });
    test('Can instantiate RemoveClipboardFormatListener', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RemoveClipboardFormatListener = user32.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('RemoveClipboardFormatListener');
      expect(RemoveClipboardFormatListener, isA<Function>());
    });
    test('Can instantiate RemoveMenu', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RemoveMenu = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags),
          int Function(int hMenu, int uPosition, int uFlags)>('RemoveMenu');
      expect(RemoveMenu, isA<Function>());
    });
    test('Can instantiate RemoveProp', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final RemoveProp = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Pointer<Utf16> lpString),
          int Function(int hWnd, Pointer<Utf16> lpString)>('RemovePropW');
      expect(RemoveProp, isA<Function>());
    });
    test('Can instantiate ReplyMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ReplyMessage = user32.lookupFunction<Int32 Function(IntPtr lResult),
          int Function(int lResult)>('ReplyMessage');
      expect(ReplyMessage, isA<Function>());
    });
    test('Can instantiate ScreenToClient', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ScreenToClient = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
          int Function(int hWnd, Pointer<POINT> lpPoint)>('ScreenToClient');
      expect(ScreenToClient, isA<Function>());
    });
    test('Can instantiate ScrollDC', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ScrollDC = user32.lookupFunction<
          Int32 Function(
              IntPtr hDC,
              Int32 dx,
              Int32 dy,
              Pointer<RECT> lprcScroll,
              Pointer<RECT> lprcClip,
              IntPtr hrgnUpdate,
              Pointer<RECT> lprcUpdate),
          int Function(
              int hDC,
              int dx,
              int dy,
              Pointer<RECT> lprcScroll,
              Pointer<RECT> lprcClip,
              int hrgnUpdate,
              Pointer<RECT> lprcUpdate)>('ScrollDC');
      expect(ScrollDC, isA<Function>());
    });
    test('Can instantiate ScrollWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ScrollWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 XAmount, Int32 YAmount,
              Pointer<RECT> lpRect, Pointer<RECT> lpClipRect),
          int Function(int hWnd, int XAmount, int YAmount, Pointer<RECT> lpRect,
              Pointer<RECT> lpClipRect)>('ScrollWindow');
      expect(ScrollWindow, isA<Function>());
    });
    test('Can instantiate ScrollWindowEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ScrollWindowEx = user32.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              Int32 dx,
              Int32 dy,
              Pointer<RECT> prcScroll,
              Pointer<RECT> prcClip,
              IntPtr hrgnUpdate,
              Pointer<RECT> prcUpdate,
              Uint32 flags),
          int Function(
              int hWnd,
              int dx,
              int dy,
              Pointer<RECT> prcScroll,
              Pointer<RECT> prcClip,
              int hrgnUpdate,
              Pointer<RECT> prcUpdate,
              int flags)>('ScrollWindowEx');
      expect(ScrollWindowEx, isA<Function>());
    });
    test('Can instantiate SendDlgItemMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendDlgItemMessage = user32.lookupFunction<
          IntPtr Function(IntPtr hDlg, Int32 nIDDlgItem, Uint32 Msg,
              IntPtr wParam, IntPtr lParam),
          int Function(int hDlg, int nIDDlgItem, int Msg, int wParam,
              int lParam)>('SendDlgItemMessageW');
      expect(SendDlgItemMessage, isA<Function>());
    });
    test('Can instantiate SendInput', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendInput = user32.lookupFunction<
          Uint32 Function(Uint32 cInputs, Pointer<INPUT> pInputs, Int32 cbSize),
          int Function(
              int cInputs, Pointer<INPUT> pInputs, int cbSize)>('SendInput');
      expect(SendInput, isA<Function>());
    });
    test('Can instantiate SendMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendMessage = user32.lookupFunction<
          IntPtr Function(
              IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int Msg, int wParam, int lParam)>('SendMessageW');
      expect(SendMessage, isA<Function>());
    });
    test('Can instantiate SendMessageCallback', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendMessageCallback = user32.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              Uint32 Msg,
              IntPtr wParam,
              IntPtr lParam,
              Pointer<NativeFunction<SendAsyncProc>> lpResultCallBack,
              IntPtr dwData),
          int Function(
              int hWnd,
              int Msg,
              int wParam,
              int lParam,
              Pointer<NativeFunction<SendAsyncProc>> lpResultCallBack,
              int dwData)>('SendMessageCallbackW');
      expect(SendMessageCallback, isA<Function>());
    });
    test('Can instantiate SendMessageTimeout', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendMessageTimeout = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam,
              Uint32 fuFlags, Uint32 uTimeout, Pointer<IntPtr> lpdwResult),
          int Function(int hWnd, int Msg, int wParam, int lParam, int fuFlags,
              int uTimeout, Pointer<IntPtr> lpdwResult)>('SendMessageTimeoutW');
      expect(SendMessageTimeout, isA<Function>());
    });
    test('Can instantiate SendNotifyMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SendNotifyMessage = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int Msg, int wParam, int lParam)>('SendNotifyMessageW');
      expect(SendNotifyMessage, isA<Function>());
    });
    test('Can instantiate SetActiveWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetActiveWindow = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('SetActiveWindow');
      expect(SetActiveWindow, isA<Function>());
    });
    test('Can instantiate SetCapture', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetCapture = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('SetCapture');
      expect(SetCapture, isA<Function>());
    });
    test('Can instantiate SetCaretBlinkTime', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetCaretBlinkTime = user32.lookupFunction<
          Int32 Function(Uint32 uMSeconds),
          int Function(int uMSeconds)>('SetCaretBlinkTime');
      expect(SetCaretBlinkTime, isA<Function>());
    });
    test('Can instantiate SetCaretPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetCaretPos = user32.lookupFunction<
          Int32 Function(Int32 X, Int32 Y),
          int Function(int X, int Y)>('SetCaretPos');
      expect(SetCaretPos, isA<Function>());
    });
    test('Can instantiate SetClipboardData', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetClipboardData = user32.lookupFunction<
          IntPtr Function(Uint32 uFormat, IntPtr hMem),
          int Function(int uFormat, int hMem)>('SetClipboardData');
      expect(SetClipboardData, isA<Function>());
    });
    test('Can instantiate SetClipboardViewer', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetClipboardViewer = user32.lookupFunction<
          IntPtr Function(IntPtr hWndNewViewer),
          int Function(int hWndNewViewer)>('SetClipboardViewer');
      expect(SetClipboardViewer, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SetCoalescableTimer', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetCoalescableTimer = user32.lookupFunction<
            IntPtr Function(
                IntPtr hWnd,
                IntPtr nIDEvent,
                Uint32 uElapse,
                Pointer<NativeFunction<TimerProc>> lpTimerFunc,
                Uint32 uToleranceDelay),
            int Function(
                int hWnd,
                int nIDEvent,
                int uElapse,
                Pointer<NativeFunction<TimerProc>> lpTimerFunc,
                int uToleranceDelay)>('SetCoalescableTimer');
        expect(SetCoalescableTimer, isA<Function>());
      });
    }
    test('Can instantiate SetCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetCursor = user32.lookupFunction<IntPtr Function(IntPtr hCursor),
          int Function(int hCursor)>('SetCursor');
      expect(SetCursor, isA<Function>());
    });
    test('Can instantiate SetCursorPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetCursorPos = user32.lookupFunction<
          Int32 Function(Int32 X, Int32 Y),
          int Function(int X, int Y)>('SetCursorPos');
      expect(SetCursorPos, isA<Function>());
    });
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate SetDialogControlDpiChangeBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetDialogControlDpiChangeBehavior = user32.lookupFunction<
            Int32 Function(IntPtr hWnd, Uint32 mask, Uint32 values),
            int Function(int hWnd, int mask,
                int values)>('SetDialogControlDpiChangeBehavior');
        expect(SetDialogControlDpiChangeBehavior, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate SetDialogDpiChangeBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetDialogDpiChangeBehavior = user32.lookupFunction<
            Int32 Function(IntPtr hDlg, Uint32 mask, Uint32 values),
            int Function(
                int hDlg, int mask, int values)>('SetDialogDpiChangeBehavior');
        expect(SetDialogDpiChangeBehavior, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SetDisplayAutoRotationPreferences', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetDisplayAutoRotationPreferences = user32.lookupFunction<
            Int32 Function(Int32 orientation),
            int Function(int orientation)>('SetDisplayAutoRotationPreferences');
        expect(SetDisplayAutoRotationPreferences, isA<Function>());
      });
    }
    test('Can instantiate SetDlgItemInt', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetDlgItemInt = user32.lookupFunction<
          Int32 Function(
              IntPtr hDlg, Int32 nIDDlgItem, Uint32 uValue, Int32 bSigned),
          int Function(int hDlg, int nIDDlgItem, int uValue,
              int bSigned)>('SetDlgItemInt');
      expect(SetDlgItemInt, isA<Function>());
    });
    test('Can instantiate SetDlgItemText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetDlgItemText = user32.lookupFunction<
          Int32 Function(
              IntPtr hDlg, Int32 nIDDlgItem, Pointer<Utf16> lpString),
          int Function(int hDlg, int nIDDlgItem,
              Pointer<Utf16> lpString)>('SetDlgItemTextW');
      expect(SetDlgItemText, isA<Function>());
    });
    test('Can instantiate SetDoubleClickTime', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetDoubleClickTime = user32.lookupFunction<
          Int32 Function(Uint32 param0),
          int Function(int param0)>('SetDoubleClickTime');
      expect(SetDoubleClickTime, isA<Function>());
    });
    test('Can instantiate SetFocus', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetFocus = user32.lookupFunction<IntPtr Function(IntPtr hWnd),
          int Function(int hWnd)>('SetFocus');
      expect(SetFocus, isA<Function>());
    });
    test('Can instantiate SetForegroundWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetForegroundWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('SetForegroundWindow');
      expect(SetForegroundWindow, isA<Function>());
    });
    test('Can instantiate SetGestureConfig', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetGestureConfig = user32.lookupFunction<
          Int32 Function(IntPtr hwnd, Uint32 dwReserved, Uint32 cIDs,
              Pointer<GESTURECONFIG> pGestureConfig, Uint32 cbSize),
          int Function(
              int hwnd,
              int dwReserved,
              int cIDs,
              Pointer<GESTURECONFIG> pGestureConfig,
              int cbSize)>('SetGestureConfig');
      expect(SetGestureConfig, isA<Function>());
    });
    test('Can instantiate SetKeyboardState', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetKeyboardState = user32.lookupFunction<
          Int32 Function(Pointer<Uint8> lpKeyState),
          int Function(Pointer<Uint8> lpKeyState)>('SetKeyboardState');
      expect(SetKeyboardState, isA<Function>());
    });
    test('Can instantiate SetLayeredWindowAttributes', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetLayeredWindowAttributes = user32.lookupFunction<
          Int32 Function(
              IntPtr hwnd, Uint32 crKey, Uint8 bAlpha, Uint32 dwFlags),
          int Function(int hwnd, int crKey, int bAlpha,
              int dwFlags)>('SetLayeredWindowAttributes');
      expect(SetLayeredWindowAttributes, isA<Function>());
    });
    test('Can instantiate SetMenuInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetMenuInfo = user32.lookupFunction<
          Int32 Function(IntPtr param0, Pointer<MENUINFO> param1),
          int Function(int param0, Pointer<MENUINFO> param1)>('SetMenuInfo');
      expect(SetMenuInfo, isA<Function>());
    });
    test('Can instantiate SetMenuItemBitmaps', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetMenuItemBitmaps = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags,
              IntPtr hBitmapUnchecked, IntPtr hBitmapChecked),
          int Function(int hMenu, int uPosition, int uFlags,
              int hBitmapUnchecked, int hBitmapChecked)>('SetMenuItemBitmaps');
      expect(SetMenuItemBitmaps, isA<Function>());
    });
    test('Can instantiate SetMenuItemInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetMenuItemInfo = user32.lookupFunction<
          Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPositon,
              Pointer<MENUITEMINFO> lpmii),
          int Function(int hmenu, int item, int fByPositon,
              Pointer<MENUITEMINFO> lpmii)>('SetMenuItemInfoW');
      expect(SetMenuItemInfo, isA<Function>());
    });
    test('Can instantiate SetMessageExtraInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetMessageExtraInfo = user32.lookupFunction<
          IntPtr Function(IntPtr lParam),
          int Function(int lParam)>('SetMessageExtraInfo');
      expect(SetMessageExtraInfo, isA<Function>());
    });
    test('Can instantiate SetParent', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetParent = user32.lookupFunction<
          IntPtr Function(IntPtr hWndChild, IntPtr hWndNewParent),
          int Function(int hWndChild, int hWndNewParent)>('SetParent');
      expect(SetParent, isA<Function>());
    });
    test('Can instantiate SetProcessDPIAware', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetProcessDPIAware =
          user32.lookupFunction<Int32 Function(), int Function()>(
              'SetProcessDPIAware');
      expect(SetProcessDPIAware, isA<Function>());
    });
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate SetProcessDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetProcessDpiAwarenessContext = user32.lookupFunction<
            Int32 Function(IntPtr value),
            int Function(int value)>('SetProcessDpiAwarenessContext');
        expect(SetProcessDpiAwarenessContext, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate SetProp', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetProp = user32.lookupFunction<
            Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString, IntPtr hData),
            int Function(
                int hWnd, Pointer<Utf16> lpString, int hData)>('SetPropW');
        expect(SetProp, isA<Function>());
      });
    }
    test('Can instantiate SetRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc, Int32 xLeft, Int32 yTop,
              Int32 xRight, Int32 yBottom),
          int Function(Pointer<RECT> lprc, int xLeft, int yTop, int xRight,
              int yBottom)>('SetRect');
      expect(SetRect, isA<Function>());
    });
    test('Can instantiate SetRectEmpty', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetRectEmpty = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprc),
          int Function(Pointer<RECT> lprc)>('SetRectEmpty');
      expect(SetRectEmpty, isA<Function>());
    });
    test('Can instantiate SetScrollInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetScrollInfo = user32.lookupFunction<
          Int32 Function(
              IntPtr hwnd, Uint32 nBar, Pointer<SCROLLINFO> lpsi, Int32 redraw),
          int Function(int hwnd, int nBar, Pointer<SCROLLINFO> lpsi,
              int redraw)>('SetScrollInfo');
      expect(SetScrollInfo, isA<Function>());
    });
    test('Can instantiate SetSysColors', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetSysColors = user32.lookupFunction<
          Int32 Function(Int32 cElements, Pointer<Int32> lpaElements,
              Pointer<Uint32> lpaRgbValues),
          int Function(int cElements, Pointer<Int32> lpaElements,
              Pointer<Uint32> lpaRgbValues)>('SetSysColors');
      expect(SetSysColors, isA<Function>());
    });
    test('Can instantiate SetSystemCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetSystemCursor = user32.lookupFunction<
          Int32 Function(IntPtr hcur, Uint32 id),
          int Function(int hcur, int id)>('SetSystemCursor');
      expect(SetSystemCursor, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate SetThreadDpiAwarenessContext', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetThreadDpiAwarenessContext = user32.lookupFunction<
            IntPtr Function(IntPtr dpiContext),
            int Function(int dpiContext)>('SetThreadDpiAwarenessContext');
        expect(SetThreadDpiAwarenessContext, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate SetThreadDpiHostingBehavior', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SetThreadDpiHostingBehavior = user32.lookupFunction<
            Int32 Function(Int32 value),
            int Function(int value)>('SetThreadDpiHostingBehavior');
        expect(SetThreadDpiHostingBehavior, isA<Function>());
      });
    }
    test('Can instantiate SetTimer', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetTimer = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, IntPtr nIDEvent, Uint32 uElapse,
              Pointer<NativeFunction<TimerProc>> lpTimerFunc),
          int Function(int hWnd, int nIDEvent, int uElapse,
              Pointer<NativeFunction<TimerProc>> lpTimerFunc)>('SetTimer');
      expect(SetTimer, isA<Function>());
    });
    test('Can instantiate SetUserObjectInformation', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetUserObjectInformation = user32.lookupFunction<
          Int32 Function(
              IntPtr hObj, Int32 nIndex, Pointer pvInfo, Uint32 nLength),
          int Function(int hObj, int nIndex, Pointer pvInfo,
              int nLength)>('SetUserObjectInformationW');
      expect(SetUserObjectInformation, isA<Function>());
    });
    test('Can instantiate SetWindowDisplayAffinity', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowDisplayAffinity = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 dwAffinity),
          int Function(int hWnd, int dwAffinity)>('SetWindowDisplayAffinity');
      expect(SetWindowDisplayAffinity, isA<Function>());
    });
    test('Can instantiate SetWindowLongPtr', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowLongPtr = user32.lookupFunction<
          IntPtr Function(IntPtr hWnd, Int32 nIndex, IntPtr dwNewLong),
          int Function(
              int hWnd, int nIndex, int dwNewLong)>('SetWindowLongPtrW');
      expect(SetWindowLongPtr, isA<Function>());
    });
    test('Can instantiate SetWindowPlacement', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowPlacement = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<WINDOWPLACEMENT> lpwndpl),
          int Function(int hWnd,
              Pointer<WINDOWPLACEMENT> lpwndpl)>('SetWindowPlacement');
      expect(SetWindowPlacement, isA<Function>());
    });
    test('Can instantiate SetWindowPos', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowPos = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 X, Int32 Y,
              Int32 cx, Int32 cy, Uint32 uFlags),
          int Function(int hWnd, int hWndInsertAfter, int X, int Y, int cx,
              int cy, int uFlags)>('SetWindowPos');
      expect(SetWindowPos, isA<Function>());
    });
    test('Can instantiate SetWindowRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowRgn = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bRedraw),
          int Function(int hWnd, int hRgn, int bRedraw)>('SetWindowRgn');
      expect(SetWindowRgn, isA<Function>());
    });
    test('Can instantiate SetWindowsHookEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowsHookEx = user32.lookupFunction<
          IntPtr Function(
              Int32 idHook,
              Pointer<NativeFunction<CallWndProc>> lpfn,
              IntPtr hmod,
              Uint32 dwThreadId),
          int Function(int idHook, Pointer<NativeFunction<CallWndProc>> lpfn,
              int hmod, int dwThreadId)>('SetWindowsHookExW');
      expect(SetWindowsHookEx, isA<Function>());
    });
    test('Can instantiate SetWindowText', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SetWindowText = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString),
          int Function(int hWnd, Pointer<Utf16> lpString)>('SetWindowTextW');
      expect(SetWindowText, isA<Function>());
    });
    test('Can instantiate ShowCaret', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ShowCaret = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('ShowCaret');
      expect(ShowCaret, isA<Function>());
    });
    test('Can instantiate ShowCursor', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ShowCursor = user32.lookupFunction<Int32 Function(Int32 bShow),
          int Function(int bShow)>('ShowCursor');
      expect(ShowCursor, isA<Function>());
    });
    test('Can instantiate ShowOwnedPopups', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ShowOwnedPopups = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 fShow),
          int Function(int hWnd, int fShow)>('ShowOwnedPopups');
      expect(ShowOwnedPopups, isA<Function>());
    });
    test('Can instantiate ShowWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ShowWindow = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 nCmdShow),
          int Function(int hWnd, int nCmdShow)>('ShowWindow');
      expect(ShowWindow, isA<Function>());
    });
    test('Can instantiate ShowWindowAsync', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ShowWindowAsync = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Uint32 nCmdShow),
          int Function(int hWnd, int nCmdShow)>('ShowWindowAsync');
      expect(ShowWindowAsync, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SkipPointerFrameMessages', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SkipPointerFrameMessages = user32.lookupFunction<
            Int32 Function(Uint32 pointerId),
            int Function(int pointerId)>('SkipPointerFrameMessages');
        expect(SkipPointerFrameMessages, isA<Function>());
      });
    }
    test('Can instantiate SoundSentry', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SoundSentry = user32
          .lookupFunction<Int32 Function(), int Function()>('SoundSentry');
      expect(SoundSentry, isA<Function>());
    });
    test('Can instantiate SubtractRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SubtractRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2),
          int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2)>('SubtractRect');
      expect(SubtractRect, isA<Function>());
    });
    test('Can instantiate SwapMouseButton', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SwapMouseButton = user32.lookupFunction<Int32 Function(Int32 fSwap),
          int Function(int fSwap)>('SwapMouseButton');
      expect(SwapMouseButton, isA<Function>());
    });
    test('Can instantiate SwitchDesktop', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SwitchDesktop = user32.lookupFunction<
          Int32 Function(IntPtr hDesktop),
          int Function(int hDesktop)>('SwitchDesktop');
      expect(SwitchDesktop, isA<Function>());
    });
    test('Can instantiate SwitchToThisWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SwitchToThisWindow = user32.lookupFunction<
          Void Function(IntPtr hwnd, Int32 fUnknown),
          void Function(int hwnd, int fUnknown)>('SwitchToThisWindow');
      expect(SwitchToThisWindow, isA<Function>());
    });
    test('Can instantiate SystemParametersInfo', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final SystemParametersInfo = user32.lookupFunction<
          Int32 Function(
              Uint32 uiAction, Uint32 uiParam, Pointer pvParam, Uint32 fWinIni),
          int Function(int uiAction, int uiParam, Pointer pvParam,
              int fWinIni)>('SystemParametersInfoW');
      expect(SystemParametersInfo, isA<Function>());
    });
    if (windowsBuildNumber >= 14393) {
      test('Can instantiate SystemParametersInfoForDpi', () {
        final user32 = DynamicLibrary.open('user32.dll');
        final SystemParametersInfoForDpi = user32.lookupFunction<
            Int32 Function(Uint32 uiAction, Uint32 uiParam, Pointer pvParam,
                Uint32 fWinIni, Uint32 dpi),
            int Function(int uiAction, int uiParam, Pointer pvParam,
                int fWinIni, int dpi)>('SystemParametersInfoForDpi');
        expect(SystemParametersInfoForDpi, isA<Function>());
      });
    }
    test('Can instantiate TabbedTextOut', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TabbedTextOut = user32.lookupFunction<
          Int32 Function(
              IntPtr hdc,
              Int32 x,
              Int32 y,
              Pointer<Utf16> lpString,
              Int32 chCount,
              Int32 nTabPositions,
              Pointer<Int32> lpnTabStopPositions,
              Int32 nTabOrigin),
          int Function(
              int hdc,
              int x,
              int y,
              Pointer<Utf16> lpString,
              int chCount,
              int nTabPositions,
              Pointer<Int32> lpnTabStopPositions,
              int nTabOrigin)>('TabbedTextOutW');
      expect(TabbedTextOut, isA<Function>());
    });
    test('Can instantiate TileWindows', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TileWindows = user32.lookupFunction<
          Uint16 Function(IntPtr hwndParent, Uint32 wHow, Pointer<RECT> lpRect,
              Uint32 cKids, Pointer<IntPtr> lpKids),
          int Function(int hwndParent, int wHow, Pointer<RECT> lpRect,
              int cKids, Pointer<IntPtr> lpKids)>('TileWindows');
      expect(TileWindows, isA<Function>());
    });
    test('Can instantiate ToAscii', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ToAscii = user32.lookupFunction<
          Int32 Function(Uint32 uVirtKey, Uint32 uScanCode,
              Pointer<Uint8> lpKeyState, Pointer<Uint16> lpChar, Uint32 uFlags),
          int Function(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
              Pointer<Uint16> lpChar, int uFlags)>('ToAscii');
      expect(ToAscii, isA<Function>());
    });
    test('Can instantiate ToAsciiEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ToAsciiEx = user32.lookupFunction<
          Int32 Function(
              Uint32 uVirtKey,
              Uint32 uScanCode,
              Pointer<Uint8> lpKeyState,
              Pointer<Uint16> lpChar,
              Uint32 uFlags,
              IntPtr dwhkl),
          int Function(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
              Pointer<Uint16> lpChar, int uFlags, int dwhkl)>('ToAsciiEx');
      expect(ToAsciiEx, isA<Function>());
    });
    test('Can instantiate ToUnicode', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ToUnicode = user32.lookupFunction<
          Int32 Function(
              Uint32 wVirtKey,
              Uint32 wScanCode,
              Pointer<Uint8> lpKeyState,
              Pointer<Utf16> pwszBuff,
              Int32 cchBuff,
              Uint32 wFlags),
          int Function(int wVirtKey, int wScanCode, Pointer<Uint8> lpKeyState,
              Pointer<Utf16> pwszBuff, int cchBuff, int wFlags)>('ToUnicode');
      expect(ToUnicode, isA<Function>());
    });
    test('Can instantiate ToUnicodeEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ToUnicodeEx = user32.lookupFunction<
          Int32 Function(
              Uint32 wVirtKey,
              Uint32 wScanCode,
              Pointer<Uint8> lpKeyState,
              Pointer<Utf16> pwszBuff,
              Int32 cchBuff,
              Uint32 wFlags,
              IntPtr dwhkl),
          int Function(
              int wVirtKey,
              int wScanCode,
              Pointer<Uint8> lpKeyState,
              Pointer<Utf16> pwszBuff,
              int cchBuff,
              int wFlags,
              int dwhkl)>('ToUnicodeEx');
      expect(ToUnicodeEx, isA<Function>());
    });
    test('Can instantiate TrackPopupMenuEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TrackPopupMenuEx = user32.lookupFunction<
          Int32 Function(IntPtr hMenu, Uint32 uFlags, Int32 x, Int32 y,
              IntPtr hwnd, Pointer<TPMPARAMS> lptpm),
          int Function(int hMenu, int uFlags, int x, int y, int hwnd,
              Pointer<TPMPARAMS> lptpm)>('TrackPopupMenuEx');
      expect(TrackPopupMenuEx, isA<Function>());
    });
    test('Can instantiate TranslateAccelerator', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TranslateAccelerator = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hAccTable, Pointer<MSG> lpMsg),
          int Function(int hWnd, int hAccTable,
              Pointer<MSG> lpMsg)>('TranslateAcceleratorW');
      expect(TranslateAccelerator, isA<Function>());
    });
    test('Can instantiate TranslateMDISysAccel', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TranslateMDISysAccel = user32.lookupFunction<
          Int32 Function(IntPtr hWndClient, Pointer<MSG> lpMsg),
          int Function(
              int hWndClient, Pointer<MSG> lpMsg)>('TranslateMDISysAccel');
      expect(TranslateMDISysAccel, isA<Function>());
    });
    test('Can instantiate TranslateMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final TranslateMessage = user32.lookupFunction<
          Int32 Function(Pointer<MSG> lpMsg),
          int Function(Pointer<MSG> lpMsg)>('TranslateMessage');
      expect(TranslateMessage, isA<Function>());
    });
    test('Can instantiate UnhookWindowsHookEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnhookWindowsHookEx = user32.lookupFunction<
          Int32 Function(IntPtr hhk),
          int Function(int hhk)>('UnhookWindowsHookEx');
      expect(UnhookWindowsHookEx, isA<Function>());
    });
    test('Can instantiate UnionRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnionRect = user32.lookupFunction<
          Int32 Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2),
          int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
              Pointer<RECT> lprcSrc2)>('UnionRect');
      expect(UnionRect, isA<Function>());
    });
    test('Can instantiate UnloadKeyboardLayout', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnloadKeyboardLayout = user32.lookupFunction<
          Int32 Function(IntPtr hkl),
          int Function(int hkl)>('UnloadKeyboardLayout');
      expect(UnloadKeyboardLayout, isA<Function>());
    });
    test('Can instantiate UnregisterClass', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnregisterClass = user32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpClassName, IntPtr hInstance),
          int Function(
              Pointer<Utf16> lpClassName, int hInstance)>('UnregisterClassW');
      expect(UnregisterClass, isA<Function>());
    });
    test('Can instantiate UnregisterHotKey', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnregisterHotKey = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Int32 id),
          int Function(int hWnd, int id)>('UnregisterHotKey');
      expect(UnregisterHotKey, isA<Function>());
    });
    test('Can instantiate UnregisterPowerSettingNotification', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnregisterPowerSettingNotification = user32.lookupFunction<
          Int32 Function(IntPtr Handle),
          int Function(int Handle)>('UnregisterPowerSettingNotification');
      expect(UnregisterPowerSettingNotification, isA<Function>());
    });
    test('Can instantiate UnregisterTouchWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UnregisterTouchWindow = user32.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('UnregisterTouchWindow');
      expect(UnregisterTouchWindow, isA<Function>());
    });
    test('Can instantiate UpdateLayeredWindowIndirect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UpdateLayeredWindowIndirect = user32.lookupFunction<
              Int32 Function(
                  IntPtr hWnd, Pointer<UPDATELAYEREDWINDOWINFO> pULWInfo),
              int Function(
                  int hWnd, Pointer<UPDATELAYEREDWINDOWINFO> pULWInfo)>(
          'UpdateLayeredWindowIndirect');
      expect(UpdateLayeredWindowIndirect, isA<Function>());
    });
    test('Can instantiate UpdateWindow', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final UpdateWindow = user32.lookupFunction<Int32 Function(IntPtr hWnd),
          int Function(int hWnd)>('UpdateWindow');
      expect(UpdateWindow, isA<Function>());
    });
    test('Can instantiate ValidateRect', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ValidateRect = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
          int Function(int hWnd, Pointer<RECT> lpRect)>('ValidateRect');
      expect(ValidateRect, isA<Function>());
    });
    test('Can instantiate ValidateRgn', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final ValidateRgn = user32.lookupFunction<
          Int32 Function(IntPtr hWnd, IntPtr hRgn),
          int Function(int hWnd, int hRgn)>('ValidateRgn');
      expect(ValidateRgn, isA<Function>());
    });
    test('Can instantiate VkKeyScan', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final VkKeyScan = user32.lookupFunction<Int16 Function(Uint16 ch),
          int Function(int ch)>('VkKeyScanW');
      expect(VkKeyScan, isA<Function>());
    });
    test('Can instantiate VkKeyScanEx', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final VkKeyScanEx = user32.lookupFunction<
          Int16 Function(Uint16 ch, IntPtr dwhkl),
          int Function(int ch, int dwhkl)>('VkKeyScanExW');
      expect(VkKeyScanEx, isA<Function>());
    });
    test('Can instantiate WaitForInputIdle', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final WaitForInputIdle = user32.lookupFunction<
          Uint32 Function(IntPtr hProcess, Uint32 dwMilliseconds),
          int Function(int hProcess, int dwMilliseconds)>('WaitForInputIdle');
      expect(WaitForInputIdle, isA<Function>());
    });
    test('Can instantiate WaitMessage', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final WaitMessage = user32
          .lookupFunction<Int32 Function(), int Function()>('WaitMessage');
      expect(WaitMessage, isA<Function>());
    });
    test('Can instantiate WindowFromDC', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final WindowFromDC = user32.lookupFunction<IntPtr Function(IntPtr hDC),
          int Function(int hDC)>('WindowFromDC');
      expect(WindowFromDC, isA<Function>());
    });
    test('Can instantiate WindowFromPhysicalPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final WindowFromPhysicalPoint = user32.lookupFunction<
          IntPtr Function(POINT Point),
          int Function(POINT Point)>('WindowFromPhysicalPoint');
      expect(WindowFromPhysicalPoint, isA<Function>());
    });
    test('Can instantiate WindowFromPoint', () {
      final user32 = DynamicLibrary.open('user32.dll');
      final WindowFromPoint = user32.lookupFunction<
          IntPtr Function(POINT Point),
          int Function(POINT Point)>('WindowFromPoint');
      expect(WindowFromPoint, isA<Function>());
    });
  });

  group('Test iphlpapi functions', () {
    test('Can instantiate AddIPAddress', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final AddIPAddress = iphlpapi.lookupFunction<
          Uint32 Function(Uint32 Address, Uint32 IpMask, Uint32 IfIndex,
              Pointer<Uint32> NTEContext, Pointer<Uint32> NTEInstance),
          int Function(
              int Address,
              int IpMask,
              int IfIndex,
              Pointer<Uint32> NTEContext,
              Pointer<Uint32> NTEInstance)>('AddIPAddress');
      expect(AddIPAddress, isA<Function>());
    });
    test('Can instantiate DeleteIPAddress', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final DeleteIPAddress = iphlpapi.lookupFunction<
          Uint32 Function(Uint32 NTEContext),
          int Function(int NTEContext)>('DeleteIPAddress');
      expect(DeleteIPAddress, isA<Function>());
    });
    test('Can instantiate GetAdapterIndex', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final GetAdapterIndex = iphlpapi.lookupFunction<
          Uint32 Function(Pointer<Utf16> AdapterName, Pointer<Uint32> IfIndex),
          int Function(Pointer<Utf16> AdapterName,
              Pointer<Uint32> IfIndex)>('GetAdapterIndex');
      expect(GetAdapterIndex, isA<Function>());
    });
    test('Can instantiate GetAdaptersAddresses', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final GetAdaptersAddresses = iphlpapi.lookupFunction<
          Uint32 Function(
              Uint32 Family,
              Uint32 Flags,
              Pointer Reserved,
              Pointer<IP_ADAPTER_ADDRESSES_LH> AdapterAddresses,
              Pointer<Uint32> SizePointer),
          int Function(
              int Family,
              int Flags,
              Pointer Reserved,
              Pointer<IP_ADAPTER_ADDRESSES_LH> AdapterAddresses,
              Pointer<Uint32> SizePointer)>('GetAdaptersAddresses');
      expect(GetAdaptersAddresses, isA<Function>());
    });
    test('Can instantiate GetInterfaceInfo', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final GetInterfaceInfo = iphlpapi.lookupFunction<
          Uint32 Function(
              Pointer<IP_INTERFACE_INFO> pIfTable, Pointer<Uint32> dwOutBufLen),
          int Function(Pointer<IP_INTERFACE_INFO> pIfTable,
              Pointer<Uint32> dwOutBufLen)>('GetInterfaceInfo');
      expect(GetInterfaceInfo, isA<Function>());
    });
    test('Can instantiate GetPerAdapterInfo', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final GetPerAdapterInfo = iphlpapi.lookupFunction<
          Uint32 Function(
              Uint32 IfIndex,
              Pointer<IP_PER_ADAPTER_INFO_W2KSP1> pPerAdapterInfo,
              Pointer<Uint32> pOutBufLen),
          int Function(
              int IfIndex,
              Pointer<IP_PER_ADAPTER_INFO_W2KSP1> pPerAdapterInfo,
              Pointer<Uint32> pOutBufLen)>('GetPerAdapterInfo');
      expect(GetPerAdapterInfo, isA<Function>());
    });
    test('Can instantiate IpReleaseAddress', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final IpReleaseAddress = iphlpapi.lookupFunction<
          Uint32 Function(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo),
          int Function(
              Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo)>('IpReleaseAddress');
      expect(IpReleaseAddress, isA<Function>());
    });
    test('Can instantiate IpRenewAddress', () {
      final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
      final IpRenewAddress = iphlpapi.lookupFunction<
          Uint32 Function(Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo),
          int Function(
              Pointer<IP_ADAPTER_INDEX_MAP> AdapterInfo)>('IpRenewAddress');
      expect(IpRenewAddress, isA<Function>());
    });
  });

  group('Test bthprops functions', () {
    test('Can instantiate BluetoothAuthenticateDeviceEx', () {
      final bthprops = DynamicLibrary.open('bthprops.cpl');
      final BluetoothAuthenticateDeviceEx = bthprops.lookupFunction<
          Uint32 Function(
              IntPtr hwndParentIn,
              IntPtr hRadioIn,
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdiInout,
              Pointer<BLUETOOTH_OOB_DATA_INFO> pbtOobData,
              Int32 authenticationRequirement),
          int Function(
              int hwndParentIn,
              int hRadioIn,
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdiInout,
              Pointer<BLUETOOTH_OOB_DATA_INFO> pbtOobData,
              int authenticationRequirement)>('BluetoothAuthenticateDeviceEx');
      expect(BluetoothAuthenticateDeviceEx, isA<Function>());
    });
    test('Can instantiate BluetoothDisplayDeviceProperties', () {
      final bthprops = DynamicLibrary.open('bthprops.cpl');
      final BluetoothDisplayDeviceProperties = bthprops.lookupFunction<
              Int32 Function(
                  IntPtr hwndParent, Pointer<BLUETOOTH_DEVICE_INFO> pbtdi),
              int Function(
                  int hwndParent, Pointer<BLUETOOTH_DEVICE_INFO> pbtdi)>(
          'BluetoothDisplayDeviceProperties');
      expect(BluetoothDisplayDeviceProperties, isA<Function>());
    });
  });

  group('Test bluetoothapis functions', () {
    test('Can instantiate BluetoothEnableDiscovery', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothEnableDiscovery = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hRadio, Int32 fEnabled),
          int Function(int hRadio, int fEnabled)>('BluetoothEnableDiscovery');
      expect(BluetoothEnableDiscovery, isA<Function>());
    });
    test('Can instantiate BluetoothEnableIncomingConnections', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothEnableIncomingConnections = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hRadio, Int32 fEnabled),
          int Function(
              int hRadio, int fEnabled)>('BluetoothEnableIncomingConnections');
      expect(BluetoothEnableIncomingConnections, isA<Function>());
    });
    test('Can instantiate BluetoothEnumerateInstalledServices', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothEnumerateInstalledServices = bluetoothapis.lookupFunction<
          Uint32 Function(IntPtr hRadio, Pointer<BLUETOOTH_DEVICE_INFO> pbtdi,
              Pointer<Uint32> pcServiceInout, Pointer<GUID> pGuidServices),
          int Function(
              int hRadio,
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdi,
              Pointer<Uint32> pcServiceInout,
              Pointer<GUID>
                  pGuidServices)>('BluetoothEnumerateInstalledServices');
      expect(BluetoothEnumerateInstalledServices, isA<Function>());
    });
    test('Can instantiate BluetoothFindDeviceClose', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindDeviceClose = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hFind),
          int Function(int hFind)>('BluetoothFindDeviceClose');
      expect(BluetoothFindDeviceClose, isA<Function>());
    });
    test('Can instantiate BluetoothFindFirstDevice', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindFirstDevice = bluetoothapis.lookupFunction<
              IntPtr Function(Pointer<BLUETOOTH_DEVICE_SEARCH_PARAMS> pbtsp,
                  Pointer<BLUETOOTH_DEVICE_INFO> pbtdi),
              int Function(Pointer<BLUETOOTH_DEVICE_SEARCH_PARAMS> pbtsp,
                  Pointer<BLUETOOTH_DEVICE_INFO> pbtdi)>(
          'BluetoothFindFirstDevice');
      expect(BluetoothFindFirstDevice, isA<Function>());
    });
    test('Can instantiate BluetoothFindFirstRadio', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindFirstRadio = bluetoothapis.lookupFunction<
          IntPtr Function(Pointer<BLUETOOTH_FIND_RADIO_PARAMS> pbtfrp,
              Pointer<IntPtr> phRadio),
          int Function(Pointer<BLUETOOTH_FIND_RADIO_PARAMS> pbtfrp,
              Pointer<IntPtr> phRadio)>('BluetoothFindFirstRadio');
      expect(BluetoothFindFirstRadio, isA<Function>());
    });
    test('Can instantiate BluetoothFindNextDevice', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindNextDevice = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hFind, Pointer<BLUETOOTH_DEVICE_INFO> pbtdi),
          int Function(int hFind,
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdi)>('BluetoothFindNextDevice');
      expect(BluetoothFindNextDevice, isA<Function>());
    });
    test('Can instantiate BluetoothFindNextRadio', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindNextRadio = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hFind, Pointer<IntPtr> phRadio),
          int Function(
              int hFind, Pointer<IntPtr> phRadio)>('BluetoothFindNextRadio');
      expect(BluetoothFindNextRadio, isA<Function>());
    });
    test('Can instantiate BluetoothFindRadioClose', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothFindRadioClose = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hFind),
          int Function(int hFind)>('BluetoothFindRadioClose');
      expect(BluetoothFindRadioClose, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTAbortReliableWrite', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTAbortReliableWrite = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice, Uint64 ReliableWriteContext, Uint32 Flags),
            int Function(int hDevice, int ReliableWriteContext,
                int Flags)>('BluetoothGATTAbortReliableWrite');
        expect(BluetoothGATTAbortReliableWrite, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTBeginReliableWrite', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTBeginReliableWrite = bluetoothapis.lookupFunction<
            Int32 Function(IntPtr hDevice, Pointer<Uint64> ReliableWriteContext,
                Uint32 Flags),
            int Function(int hDevice, Pointer<Uint64> ReliableWriteContext,
                int Flags)>('BluetoothGATTBeginReliableWrite');
        expect(BluetoothGATTBeginReliableWrite, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTEndReliableWrite', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTEndReliableWrite = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice, Uint64 ReliableWriteContext, Uint32 Flags),
            int Function(int hDevice, int ReliableWriteContext,
                int Flags)>('BluetoothGATTEndReliableWrite');
        expect(BluetoothGATTEndReliableWrite, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetCharacteristics', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetCharacteristics = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Pointer<BTH_LE_GATT_SERVICE> Service,
                Uint16 CharacteristicsBufferCount,
                Pointer<BTH_LE_GATT_CHARACTERISTIC> CharacteristicsBuffer,
                Pointer<Uint16> CharacteristicsBufferActual,
                Uint32 Flags),
            int Function(
                int hDevice,
                Pointer<BTH_LE_GATT_SERVICE> Service,
                int CharacteristicsBufferCount,
                Pointer<BTH_LE_GATT_CHARACTERISTIC> CharacteristicsBuffer,
                Pointer<Uint16> CharacteristicsBufferActual,
                int Flags)>('BluetoothGATTGetCharacteristics');
        expect(BluetoothGATTGetCharacteristics, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetCharacteristicValue', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetCharacteristicValue =
            bluetoothapis.lookupFunction<
                Int32 Function(
                    IntPtr hDevice,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                    Uint32 CharacteristicValueDataSize,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE>
                        CharacteristicValue,
                    Pointer<Uint16> CharacteristicValueSizeRequired,
                    Uint32 Flags),
                int Function(
                    int hDevice,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                    int CharacteristicValueDataSize,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE>
                        CharacteristicValue,
                    Pointer<Uint16> CharacteristicValueSizeRequired,
                    int Flags)>('BluetoothGATTGetCharacteristicValue');
        expect(BluetoothGATTGetCharacteristicValue, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetDescriptors', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetDescriptors = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                Uint16 DescriptorsBufferCount,
                Pointer<BTH_LE_GATT_DESCRIPTOR> DescriptorsBuffer,
                Pointer<Uint16> DescriptorsBufferActual,
                Uint32 Flags),
            int Function(
                int hDevice,
                Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                int DescriptorsBufferCount,
                Pointer<BTH_LE_GATT_DESCRIPTOR> DescriptorsBuffer,
                Pointer<Uint16> DescriptorsBufferActual,
                int Flags)>('BluetoothGATTGetDescriptors');
        expect(BluetoothGATTGetDescriptors, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetDescriptorValue', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetDescriptorValue = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
                Uint32 DescriptorValueDataSize,
                Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
                Pointer<Uint16> DescriptorValueSizeRequired,
                Uint32 Flags),
            int Function(
                int hDevice,
                Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
                int DescriptorValueDataSize,
                Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
                Pointer<Uint16> DescriptorValueSizeRequired,
                int Flags)>('BluetoothGATTGetDescriptorValue');
        expect(BluetoothGATTGetDescriptorValue, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetIncludedServices', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetIncludedServices = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Pointer<BTH_LE_GATT_SERVICE> ParentService,
                Uint16 IncludedServicesBufferCount,
                Pointer<BTH_LE_GATT_SERVICE> IncludedServicesBuffer,
                Pointer<Uint16> IncludedServicesBufferActual,
                Uint32 Flags),
            int Function(
                int hDevice,
                Pointer<BTH_LE_GATT_SERVICE> ParentService,
                int IncludedServicesBufferCount,
                Pointer<BTH_LE_GATT_SERVICE> IncludedServicesBuffer,
                Pointer<Uint16> IncludedServicesBufferActual,
                int Flags)>('BluetoothGATTGetIncludedServices');
        expect(BluetoothGATTGetIncludedServices, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTGetServices', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTGetServices = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Uint16 ServicesBufferCount,
                Pointer<BTH_LE_GATT_SERVICE> ServicesBuffer,
                Pointer<Uint16> ServicesBufferActual,
                Uint32 Flags),
            int Function(
                int hDevice,
                int ServicesBufferCount,
                Pointer<BTH_LE_GATT_SERVICE> ServicesBuffer,
                Pointer<Uint16> ServicesBufferActual,
                int Flags)>('BluetoothGATTGetServices');
        expect(BluetoothGATTGetServices, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTRegisterEvent', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTRegisterEvent = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hService,
                Int32 EventType,
                Pointer EventParameterIn,
                Pointer<NativeFunction<PfnbluetoothGattEventCallback>> Callback,
                Pointer CallbackContext,
                Pointer<IntPtr> pEventHandle,
                Uint32 Flags),
            int Function(
                int hService,
                int EventType,
                Pointer EventParameterIn,
                Pointer<NativeFunction<PfnbluetoothGattEventCallback>> Callback,
                Pointer CallbackContext,
                Pointer<IntPtr> pEventHandle,
                int Flags)>('BluetoothGATTRegisterEvent');
        expect(BluetoothGATTRegisterEvent, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTSetCharacteristicValue', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTSetCharacteristicValue =
            bluetoothapis.lookupFunction<
                Int32 Function(
                    IntPtr hDevice,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE>
                        CharacteristicValue,
                    Uint64 ReliableWriteContext,
                    Uint32 Flags),
                int Function(
                    int hDevice,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC> Characteristic,
                    Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE>
                        CharacteristicValue,
                    int ReliableWriteContext,
                    int Flags)>('BluetoothGATTSetCharacteristicValue');
        expect(BluetoothGATTSetCharacteristicValue, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTSetDescriptorValue', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTSetDescriptorValue = bluetoothapis.lookupFunction<
            Int32 Function(
                IntPtr hDevice,
                Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
                Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
                Uint32 Flags),
            int Function(
                int hDevice,
                Pointer<BTH_LE_GATT_DESCRIPTOR> Descriptor,
                Pointer<BTH_LE_GATT_DESCRIPTOR_VALUE> DescriptorValue,
                int Flags)>('BluetoothGATTSetDescriptorValue');
        expect(BluetoothGATTSetDescriptorValue, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate BluetoothGATTUnregisterEvent', () {
        final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
        final BluetoothGATTUnregisterEvent = bluetoothapis.lookupFunction<
            Int32 Function(IntPtr EventHandle, Uint32 Flags),
            int Function(
                int EventHandle, int Flags)>('BluetoothGATTUnregisterEvent');
        expect(BluetoothGATTUnregisterEvent, isA<Function>());
      });
    }
    test('Can instantiate BluetoothGetRadioInfo', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothGetRadioInfo = bluetoothapis.lookupFunction<
              Uint32 Function(
                  IntPtr hRadio, Pointer<BLUETOOTH_RADIO_INFO> pRadioInfo),
              int Function(
                  int hRadio, Pointer<BLUETOOTH_RADIO_INFO> pRadioInfo)>(
          'BluetoothGetRadioInfo');
      expect(BluetoothGetRadioInfo, isA<Function>());
    });
    test('Can instantiate BluetoothIsConnectable', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothIsConnectable = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hRadio),
          int Function(int hRadio)>('BluetoothIsConnectable');
      expect(BluetoothIsConnectable, isA<Function>());
    });
    test('Can instantiate BluetoothIsDiscoverable', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothIsDiscoverable = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hRadio),
          int Function(int hRadio)>('BluetoothIsDiscoverable');
      expect(BluetoothIsDiscoverable, isA<Function>());
    });
    test('Can instantiate BluetoothIsVersionAvailable', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothIsVersionAvailable = bluetoothapis.lookupFunction<
          Int32 Function(Uint8 MajorVersion, Uint8 MinorVersion),
          int Function(int MajorVersion,
              int MinorVersion)>('BluetoothIsVersionAvailable');
      expect(BluetoothIsVersionAvailable, isA<Function>());
    });
    test('Can instantiate BluetoothRegisterForAuthenticationEx', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothRegisterForAuthenticationEx = bluetoothapis.lookupFunction<
          Uint32 Function(
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdiIn,
              Pointer<IntPtr> phRegHandleOut,
              Pointer<NativeFunction<PfnAuthenticationCallbackEx>>
                  pfnCallbackIn,
              Pointer pvParam),
          int Function(
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdiIn,
              Pointer<IntPtr> phRegHandleOut,
              Pointer<NativeFunction<PfnAuthenticationCallbackEx>>
                  pfnCallbackIn,
              Pointer pvParam)>('BluetoothRegisterForAuthenticationEx');
      expect(BluetoothRegisterForAuthenticationEx, isA<Function>());
    });
    test('Can instantiate BluetoothRemoveDevice', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothRemoveDevice = bluetoothapis.lookupFunction<
          Uint32 Function(Pointer<BLUETOOTH_ADDRESS> pAddress),
          int Function(
              Pointer<BLUETOOTH_ADDRESS> pAddress)>('BluetoothRemoveDevice');
      expect(BluetoothRemoveDevice, isA<Function>());
    });
    test('Can instantiate BluetoothSetServiceState', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothSetServiceState = bluetoothapis.lookupFunction<
          Uint32 Function(IntPtr hRadio, Pointer<BLUETOOTH_DEVICE_INFO> pbtdi,
              Pointer<GUID> pGuidService, Uint32 dwServiceFlags),
          int Function(
              int hRadio,
              Pointer<BLUETOOTH_DEVICE_INFO> pbtdi,
              Pointer<GUID> pGuidService,
              int dwServiceFlags)>('BluetoothSetServiceState');
      expect(BluetoothSetServiceState, isA<Function>());
    });
    test('Can instantiate BluetoothUnregisterAuthentication', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothUnregisterAuthentication = bluetoothapis.lookupFunction<
          Int32 Function(IntPtr hRegHandle),
          int Function(int hRegHandle)>('BluetoothUnregisterAuthentication');
      expect(BluetoothUnregisterAuthentication, isA<Function>());
    });
    test('Can instantiate BluetoothUpdateDeviceRecord', () {
      final bluetoothapis = DynamicLibrary.open('bluetoothapis.dll');
      final BluetoothUpdateDeviceRecord = bluetoothapis.lookupFunction<
              Uint32 Function(Pointer<BLUETOOTH_DEVICE_INFO> pbtdi),
              int Function(Pointer<BLUETOOTH_DEVICE_INFO> pbtdi)>(
          'BluetoothUpdateDeviceRecord');
      expect(BluetoothUpdateDeviceRecord, isA<Function>());
    });
  });

  group('Test powrprof functions', () {
    test('Can instantiate CallNtPowerInformation', () {
      final powrprof = DynamicLibrary.open('powrprof.dll');
      final CallNtPowerInformation = powrprof.lookupFunction<
          Int32 Function(
              Int32 InformationLevel,
              Pointer InputBuffer,
              Uint32 InputBufferLength,
              Pointer OutputBuffer,
              Uint32 OutputBufferLength),
          int Function(
              int InformationLevel,
              Pointer InputBuffer,
              int InputBufferLength,
              Pointer OutputBuffer,
              int OutputBufferLength)>('CallNtPowerInformation');
      expect(CallNtPowerInformation, isA<Function>());
    });
  });

  group('Test comdlg32 functions', () {
    test('Can instantiate ChooseColor', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final ChooseColor = comdlg32.lookupFunction<
          Int32 Function(Pointer<CHOOSECOLOR> param0),
          int Function(Pointer<CHOOSECOLOR> param0)>('ChooseColorW');
      expect(ChooseColor, isA<Function>());
    });
    test('Can instantiate ChooseFont', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final ChooseFont = comdlg32.lookupFunction<
          Int32 Function(Pointer<CHOOSEFONT> param0),
          int Function(Pointer<CHOOSEFONT> param0)>('ChooseFontW');
      expect(ChooseFont, isA<Function>());
    });
    test('Can instantiate FindText', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final FindText = comdlg32.lookupFunction<
          IntPtr Function(Pointer<FINDREPLACE> param0),
          int Function(Pointer<FINDREPLACE> param0)>('FindTextW');
      expect(FindText, isA<Function>());
    });
    test('Can instantiate GetOpenFileName', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final GetOpenFileName = comdlg32.lookupFunction<
          Int32 Function(Pointer<OPENFILENAME> param0),
          int Function(Pointer<OPENFILENAME> param0)>('GetOpenFileNameW');
      expect(GetOpenFileName, isA<Function>());
    });
    test('Can instantiate GetSaveFileName', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final GetSaveFileName = comdlg32.lookupFunction<
          Int32 Function(Pointer<OPENFILENAME> param0),
          int Function(Pointer<OPENFILENAME> param0)>('GetSaveFileNameW');
      expect(GetSaveFileName, isA<Function>());
    });
    test('Can instantiate ReplaceText', () {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final ReplaceText = comdlg32.lookupFunction<
          IntPtr Function(Pointer<FINDREPLACE> param0),
          int Function(Pointer<FINDREPLACE> param0)>('ReplaceTextW');
      expect(ReplaceText, isA<Function>());
    });
  });

  group('Test uxtheme functions', () {
    test('Can instantiate CloseThemeData', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final CloseThemeData = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme),
          int Function(int hTheme)>('CloseThemeData');
      expect(CloseThemeData, isA<Function>());
    });
    test('Can instantiate DrawThemeBackground', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeBackground = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, IntPtr hdc, Int32 iPartId,
              Int32 iStateId, Pointer<RECT> pRect, Pointer<RECT> pClipRect),
          int Function(
              int hTheme,
              int hdc,
              int iPartId,
              int iStateId,
              Pointer<RECT> pRect,
              Pointer<RECT> pClipRect)>('DrawThemeBackground');
      expect(DrawThemeBackground, isA<Function>());
    });
    test('Can instantiate DrawThemeEdge', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeEdge = uxtheme.lookupFunction<
          Int32 Function(
              IntPtr hTheme,
              IntPtr hdc,
              Int32 iPartId,
              Int32 iStateId,
              Pointer<RECT> pDestRect,
              Uint32 uEdge,
              Uint32 uFlags,
              Pointer<RECT> pContentRect),
          int Function(
              int hTheme,
              int hdc,
              int iPartId,
              int iStateId,
              Pointer<RECT> pDestRect,
              int uEdge,
              int uFlags,
              Pointer<RECT> pContentRect)>('DrawThemeEdge');
      expect(DrawThemeEdge, isA<Function>());
    });
    test('Can instantiate DrawThemeIcon', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeIcon = uxtheme.lookupFunction<
          Int32 Function(
              IntPtr hTheme,
              IntPtr hdc,
              Int32 iPartId,
              Int32 iStateId,
              Pointer<RECT> pRect,
              IntPtr himl,
              Int32 iImageIndex),
          int Function(int hTheme, int hdc, int iPartId, int iStateId,
              Pointer<RECT> pRect, int himl, int iImageIndex)>('DrawThemeIcon');
      expect(DrawThemeIcon, isA<Function>());
    });
    test('Can instantiate DrawThemeParentBackground', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeParentBackground = uxtheme.lookupFunction<
          Int32 Function(IntPtr hwnd, IntPtr hdc, Pointer<RECT> prc),
          int Function(int hwnd, int hdc,
              Pointer<RECT> prc)>('DrawThemeParentBackground');
      expect(DrawThemeParentBackground, isA<Function>());
    });
    test('Can instantiate DrawThemeParentBackgroundEx', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeParentBackgroundEx = uxtheme.lookupFunction<
          Int32 Function(
              IntPtr hwnd, IntPtr hdc, Uint32 dwFlags, Pointer<RECT> prc),
          int Function(int hwnd, int hdc, int dwFlags,
              Pointer<RECT> prc)>('DrawThemeParentBackgroundEx');
      expect(DrawThemeParentBackgroundEx, isA<Function>());
    });
    test('Can instantiate DrawThemeTextEx', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final DrawThemeTextEx = uxtheme.lookupFunction<
          Int32 Function(
              IntPtr hTheme,
              IntPtr hdc,
              Int32 iPartId,
              Int32 iStateId,
              Pointer<Utf16> pszText,
              Int32 cchText,
              Uint32 dwTextFlags,
              Pointer<RECT> pRect,
              Pointer<DTTOPTS> pOptions),
          int Function(
              int hTheme,
              int hdc,
              int iPartId,
              int iStateId,
              Pointer<Utf16> pszText,
              int cchText,
              int dwTextFlags,
              Pointer<RECT> pRect,
              Pointer<DTTOPTS> pOptions)>('DrawThemeTextEx');
      expect(DrawThemeTextEx, isA<Function>());
    });
    test('Can instantiate EnableThemeDialogTexture', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final EnableThemeDialogTexture = uxtheme.lookupFunction<
          Int32 Function(IntPtr hwnd, Uint32 dwFlags),
          int Function(int hwnd, int dwFlags)>('EnableThemeDialogTexture');
      expect(EnableThemeDialogTexture, isA<Function>());
    });
    test('Can instantiate GetCurrentThemeName', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetCurrentThemeName = uxtheme.lookupFunction<
          Int32 Function(
              Pointer<Utf16> pszThemeFileName,
              Int32 cchMaxNameChars,
              Pointer<Utf16> pszColorBuff,
              Int32 cchMaxColorChars,
              Pointer<Utf16> pszSizeBuff,
              Int32 cchMaxSizeChars),
          int Function(
              Pointer<Utf16> pszThemeFileName,
              int cchMaxNameChars,
              Pointer<Utf16> pszColorBuff,
              int cchMaxColorChars,
              Pointer<Utf16> pszSizeBuff,
              int cchMaxSizeChars)>('GetCurrentThemeName');
      expect(GetCurrentThemeName, isA<Function>());
    });
    test('Can instantiate GetThemeMetric', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeMetric = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, IntPtr hdc, Int32 iPartId,
              Int32 iStateId, Uint32 iPropId, Pointer<Int32> piVal),
          int Function(int hTheme, int hdc, int iPartId, int iStateId,
              int iPropId, Pointer<Int32> piVal)>('GetThemeMetric');
      expect(GetThemeMetric, isA<Function>());
    });
    test('Can instantiate GetThemePartSize', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemePartSize = uxtheme.lookupFunction<
          Int32 Function(
              IntPtr hTheme,
              IntPtr hdc,
              Int32 iPartId,
              Int32 iStateId,
              Pointer<RECT> prc,
              Int32 eSize,
              Pointer<SIZE> psz),
          int Function(
              int hTheme,
              int hdc,
              int iPartId,
              int iStateId,
              Pointer<RECT> prc,
              int eSize,
              Pointer<SIZE> psz)>('GetThemePartSize');
      expect(GetThemePartSize, isA<Function>());
    });
    test('Can instantiate GetThemeRect', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeRect = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, Int32 iPartId, Int32 iStateId,
              Int32 iPropId, Pointer<RECT> pRect),
          int Function(int hTheme, int iPartId, int iStateId, int iPropId,
              Pointer<RECT> pRect)>('GetThemeRect');
      expect(GetThemeRect, isA<Function>());
    });
    test('Can instantiate GetThemeSysColor', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeSysColor = uxtheme.lookupFunction<
          Uint32 Function(IntPtr hTheme, Int32 iColorId),
          int Function(int hTheme, int iColorId)>('GetThemeSysColor');
      expect(GetThemeSysColor, isA<Function>());
    });
    test('Can instantiate GetThemeSysColorBrush', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeSysColorBrush = uxtheme.lookupFunction<
          IntPtr Function(IntPtr hTheme, Uint32 iColorId),
          int Function(int hTheme, int iColorId)>('GetThemeSysColorBrush');
      expect(GetThemeSysColorBrush, isA<Function>());
    });
    test('Can instantiate GetThemeSysFont', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeSysFont = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, Uint32 iFontId, Pointer<LOGFONT> plf),
          int Function(int hTheme, int iFontId,
              Pointer<LOGFONT> plf)>('GetThemeSysFont');
      expect(GetThemeSysFont, isA<Function>());
    });
    test('Can instantiate GetThemeSysSize', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetThemeSysSize = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, Int32 iSizeId),
          int Function(int hTheme, int iSizeId)>('GetThemeSysSize');
      expect(GetThemeSysSize, isA<Function>());
    });
    test('Can instantiate GetWindowTheme', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final GetWindowTheme = uxtheme.lookupFunction<
          IntPtr Function(IntPtr hwnd),
          int Function(int hwnd)>('GetWindowTheme');
      expect(GetWindowTheme, isA<Function>());
    });
    test('Can instantiate IsAppThemed', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsAppThemed = uxtheme
          .lookupFunction<Int32 Function(), int Function()>('IsAppThemed');
      expect(IsAppThemed, isA<Function>());
    });
    test('Can instantiate IsCompositionActive', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsCompositionActive =
          uxtheme.lookupFunction<Int32 Function(), int Function()>(
              'IsCompositionActive');
      expect(IsCompositionActive, isA<Function>());
    });
    test('Can instantiate IsThemeActive', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsThemeActive = uxtheme
          .lookupFunction<Int32 Function(), int Function()>('IsThemeActive');
      expect(IsThemeActive, isA<Function>());
    });
    test('Can instantiate IsThemeBackgroundPartiallyTransparent', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsThemeBackgroundPartiallyTransparent = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, Int32 iPartId, Int32 iStateId),
          int Function(int hTheme, int iPartId,
              int iStateId)>('IsThemeBackgroundPartiallyTransparent');
      expect(IsThemeBackgroundPartiallyTransparent, isA<Function>());
    });
    test('Can instantiate IsThemeDialogTextureEnabled', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsThemeDialogTextureEnabled = uxtheme.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('IsThemeDialogTextureEnabled');
      expect(IsThemeDialogTextureEnabled, isA<Function>());
    });
    test('Can instantiate IsThemePartDefined', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final IsThemePartDefined = uxtheme.lookupFunction<
          Int32 Function(IntPtr hTheme, Int32 iPartId, Int32 iStateId),
          int Function(
              int hTheme, int iPartId, int iStateId)>('IsThemePartDefined');
      expect(IsThemePartDefined, isA<Function>());
    });
    test('Can instantiate OpenThemeData', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final OpenThemeData = uxtheme.lookupFunction<
          IntPtr Function(IntPtr hwnd, Pointer<Utf16> pszClassList),
          int Function(int hwnd, Pointer<Utf16> pszClassList)>('OpenThemeData');
      expect(OpenThemeData, isA<Function>());
    });
    test('Can instantiate OpenThemeDataEx', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final OpenThemeDataEx = uxtheme.lookupFunction<
          IntPtr Function(
              IntPtr hwnd, Pointer<Utf16> pszClassList, Uint32 dwFlags),
          int Function(int hwnd, Pointer<Utf16> pszClassList,
              int dwFlags)>('OpenThemeDataEx');
      expect(OpenThemeDataEx, isA<Function>());
    });
    if (windowsBuildNumber >= 15063) {
      test('Can instantiate OpenThemeDataForDpi', () {
        final uxtheme = DynamicLibrary.open('uxtheme.dll');
        final OpenThemeDataForDpi = uxtheme.lookupFunction<
            IntPtr Function(
                IntPtr hwnd, Pointer<Utf16> pszClassList, Uint32 dpi),
            int Function(int hwnd, Pointer<Utf16> pszClassList,
                int dpi)>('OpenThemeDataForDpi');
        expect(OpenThemeDataForDpi, isA<Function>());
      });
    }
    test('Can instantiate SetThemeAppProperties', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final SetThemeAppProperties = uxtheme.lookupFunction<
          Void Function(Uint32 dwFlags),
          void Function(int dwFlags)>('SetThemeAppProperties');
      expect(SetThemeAppProperties, isA<Function>());
    });
    test('Can instantiate SetWindowTheme', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final SetWindowTheme = uxtheme.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<Utf16> pszSubAppName,
              Pointer<Utf16> pszSubIdList),
          int Function(int hwnd, Pointer<Utf16> pszSubAppName,
              Pointer<Utf16> pszSubIdList)>('SetWindowTheme');
      expect(SetWindowTheme, isA<Function>());
    });
    test('Can instantiate SetWindowThemeAttribute', () {
      final uxtheme = DynamicLibrary.open('uxtheme.dll');
      final SetWindowThemeAttribute = uxtheme.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 eAttribute, Pointer pvAttribute,
              Uint32 cbAttribute),
          int Function(int hwnd, int eAttribute, Pointer pvAttribute,
              int cbAttribute)>('SetWindowThemeAttribute');
      expect(SetWindowThemeAttribute, isA<Function>());
    });
  });

  group('Test ole32 functions', () {
    test('Can instantiate CLSIDFromProgID', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CLSIDFromProgID = ole32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszProgID, Pointer<GUID> lpclsid),
          int Function(Pointer<Utf16> lpszProgID,
              Pointer<GUID> lpclsid)>('CLSIDFromProgID');
      expect(CLSIDFromProgID, isA<Function>());
    });
    test('Can instantiate CLSIDFromProgIDEx', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CLSIDFromProgIDEx = ole32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpszProgID, Pointer<GUID> lpclsid),
          int Function(Pointer<Utf16> lpszProgID,
              Pointer<GUID> lpclsid)>('CLSIDFromProgIDEx');
      expect(CLSIDFromProgIDEx, isA<Function>());
    });
    test('Can instantiate CLSIDFromString', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CLSIDFromString = ole32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpsz, Pointer<GUID> pclsid),
          int Function(
              Pointer<Utf16> lpsz, Pointer<GUID> pclsid)>('CLSIDFromString');
      expect(CLSIDFromString, isA<Function>());
    });
    test('Can instantiate CoAddRefServerProcess', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoAddRefServerProcess =
          ole32.lookupFunction<Uint32 Function(), int Function()>(
              'CoAddRefServerProcess');
      expect(CoAddRefServerProcess, isA<Function>());
    });
    test('Can instantiate CoCreateGuid', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoCreateGuid = ole32.lookupFunction<
          Int32 Function(Pointer<GUID> pguid),
          int Function(Pointer<GUID> pguid)>('CoCreateGuid');
      expect(CoCreateGuid, isA<Function>());
    });
    test('Can instantiate CoCreateInstance', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoCreateInstance = ole32.lookupFunction<
          Int32 Function(Pointer<GUID> rclsid, Pointer<COMObject> pUnkOuter,
              Uint32 dwClsContext, Pointer<GUID> riid, Pointer<Pointer> ppv),
          int Function(
              Pointer<GUID> rclsid,
              Pointer<COMObject> pUnkOuter,
              int dwClsContext,
              Pointer<GUID> riid,
              Pointer<Pointer> ppv)>('CoCreateInstance');
      expect(CoCreateInstance, isA<Function>());
    });
    test('Can instantiate CoGetClassObject', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoGetClassObject = ole32.lookupFunction<
          Int32 Function(Pointer<GUID> rclsid, Uint32 dwClsContext,
              Pointer pvReserved, Pointer<GUID> riid, Pointer<Pointer> ppv),
          int Function(
              Pointer<GUID> rclsid,
              int dwClsContext,
              Pointer pvReserved,
              Pointer<GUID> riid,
              Pointer<Pointer> ppv)>('CoGetClassObject');
      expect(CoGetClassObject, isA<Function>());
    });
    test('Can instantiate CoGetCurrentProcess', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoGetCurrentProcess =
          ole32.lookupFunction<Uint32 Function(), int Function()>(
              'CoGetCurrentProcess');
      expect(CoGetCurrentProcess, isA<Function>());
    });
    test('Can instantiate CoInitializeEx', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoInitializeEx = ole32.lookupFunction<
          Int32 Function(Pointer pvReserved, Uint32 dwCoInit),
          int Function(Pointer pvReserved, int dwCoInit)>('CoInitializeEx');
      expect(CoInitializeEx, isA<Function>());
    });
    test('Can instantiate CoInitializeSecurity', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoInitializeSecurity = ole32.lookupFunction<
          Int32 Function(
              Pointer pSecDesc,
              Int32 cAuthSvc,
              Pointer<SOLE_AUTHENTICATION_SERVICE> asAuthSvc,
              Pointer pReserved1,
              Uint32 dwAuthnLevel,
              Uint32 dwImpLevel,
              Pointer pAuthList,
              Int32 dwCapabilities,
              Pointer pReserved3),
          int Function(
              Pointer pSecDesc,
              int cAuthSvc,
              Pointer<SOLE_AUTHENTICATION_SERVICE> asAuthSvc,
              Pointer pReserved1,
              int dwAuthnLevel,
              int dwImpLevel,
              Pointer pAuthList,
              int dwCapabilities,
              Pointer pReserved3)>('CoInitializeSecurity');
      expect(CoInitializeSecurity, isA<Function>());
    });
    test('Can instantiate CoSetProxyBlanket', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoSetProxyBlanket = ole32.lookupFunction<
          Int32 Function(
              Pointer<COMObject> pProxy,
              Uint32 dwAuthnSvc,
              Uint32 dwAuthzSvc,
              Pointer<Utf16> pServerPrincName,
              Uint32 dwAuthnLevel,
              Uint32 dwImpLevel,
              Pointer pAuthInfo,
              Int32 dwCapabilities),
          int Function(
              Pointer<COMObject> pProxy,
              int dwAuthnSvc,
              int dwAuthzSvc,
              Pointer<Utf16> pServerPrincName,
              int dwAuthnLevel,
              int dwImpLevel,
              Pointer pAuthInfo,
              int dwCapabilities)>('CoSetProxyBlanket');
      expect(CoSetProxyBlanket, isA<Function>());
    });
    test('Can instantiate CoTaskMemAlloc', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoTaskMemAlloc = ole32.lookupFunction<Pointer Function(IntPtr cb),
          Pointer Function(int cb)>('CoTaskMemAlloc');
      expect(CoTaskMemAlloc, isA<Function>());
    });
    test('Can instantiate CoTaskMemFree', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoTaskMemFree = ole32.lookupFunction<Void Function(Pointer pv),
          void Function(Pointer pv)>('CoTaskMemFree');
      expect(CoTaskMemFree, isA<Function>());
    });
    test('Can instantiate CoTaskMemRealloc', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoTaskMemRealloc = ole32.lookupFunction<
          Pointer Function(Pointer pv, IntPtr cb),
          Pointer Function(Pointer pv, int cb)>('CoTaskMemRealloc');
      expect(CoTaskMemRealloc, isA<Function>());
    });
    test('Can instantiate CoUninitialize', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoUninitialize = ole32
          .lookupFunction<Void Function(), void Function()>('CoUninitialize');
      expect(CoUninitialize, isA<Function>());
    });
    test('Can instantiate CoWaitForMultipleHandles', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CoWaitForMultipleHandles = ole32.lookupFunction<
          Int32 Function(Uint32 dwFlags, Uint32 dwTimeout, Uint32 cHandles,
              Pointer<IntPtr> pHandles, Pointer<Uint32> lpdwindex),
          int Function(
              int dwFlags,
              int dwTimeout,
              int cHandles,
              Pointer<IntPtr> pHandles,
              Pointer<Uint32> lpdwindex)>('CoWaitForMultipleHandles');
      expect(CoWaitForMultipleHandles, isA<Function>());
    });
    if (windowsBuildNumber >= 10586) {
      test('Can instantiate CoWaitForMultipleObjects', () {
        final ole32 = DynamicLibrary.open('ole32.dll');
        final CoWaitForMultipleObjects = ole32.lookupFunction<
            Int32 Function(Uint32 dwFlags, Uint32 dwTimeout, Uint32 cHandles,
                Pointer<IntPtr> pHandles, Pointer<Uint32> lpdwindex),
            int Function(
                int dwFlags,
                int dwTimeout,
                int cHandles,
                Pointer<IntPtr> pHandles,
                Pointer<Uint32> lpdwindex)>('CoWaitForMultipleObjects');
        expect(CoWaitForMultipleObjects, isA<Function>());
      });
    }
    test('Can instantiate CreateStreamOnHGlobal', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final CreateStreamOnHGlobal = ole32.lookupFunction<
          Int32 Function(IntPtr hGlobal, Int32 fDeleteOnRelease,
              Pointer<Pointer<COMObject>> ppstm),
          int Function(int hGlobal, int fDeleteOnRelease,
              Pointer<Pointer<COMObject>> ppstm)>('CreateStreamOnHGlobal');
      expect(CreateStreamOnHGlobal, isA<Function>());
    });
    test('Can instantiate GetClassFile', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final GetClassFile = ole32.lookupFunction<
          Int32 Function(Pointer<Utf16> szFilename, Pointer<GUID> pclsid),
          int Function(
              Pointer<Utf16> szFilename, Pointer<GUID> pclsid)>('GetClassFile');
      expect(GetClassFile, isA<Function>());
    });
    test('Can instantiate GetHGlobalFromStream', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final GetHGlobalFromStream = ole32.lookupFunction<
          Int32 Function(Pointer<COMObject> pstm, Pointer<IntPtr> phglobal),
          int Function(Pointer<COMObject> pstm,
              Pointer<IntPtr> phglobal)>('GetHGlobalFromStream');
      expect(GetHGlobalFromStream, isA<Function>());
    });
    test('Can instantiate IIDFromString', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final IIDFromString = ole32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpsz, Pointer<GUID> lpiid),
          int Function(
              Pointer<Utf16> lpsz, Pointer<GUID> lpiid)>('IIDFromString');
      expect(IIDFromString, isA<Function>());
    });
    test('Can instantiate OleInitialize', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final OleInitialize = ole32.lookupFunction<
          Int32 Function(Pointer pvReserved),
          int Function(Pointer pvReserved)>('OleInitialize');
      expect(OleInitialize, isA<Function>());
    });
    test('Can instantiate OleUninitialize', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final OleUninitialize = ole32
          .lookupFunction<Void Function(), void Function()>('OleUninitialize');
      expect(OleUninitialize, isA<Function>());
    });
    test('Can instantiate ProgIDFromCLSID', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final ProgIDFromCLSID = ole32.lookupFunction<
          Int32 Function(
              Pointer<GUID> clsid, Pointer<Pointer<Utf16>> lplpszProgID),
          int Function(Pointer<GUID> clsid,
              Pointer<Pointer<Utf16>> lplpszProgID)>('ProgIDFromCLSID');
      expect(ProgIDFromCLSID, isA<Function>());
    });
    test('Can instantiate StringFromCLSID', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final StringFromCLSID = ole32.lookupFunction<
          Int32 Function(Pointer<GUID> rclsid, Pointer<Pointer<Utf16>> lplpsz),
          int Function(Pointer<GUID> rclsid,
              Pointer<Pointer<Utf16>> lplpsz)>('StringFromCLSID');
      expect(StringFromCLSID, isA<Function>());
    });
    test('Can instantiate StringFromGUID2', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final StringFromGUID2 = ole32.lookupFunction<
          Int32 Function(
              Pointer<GUID> rguid, Pointer<Utf16> lpsz, Int32 cchMax),
          int Function(Pointer<GUID> rguid, Pointer<Utf16> lpsz,
              int cchMax)>('StringFromGUID2');
      expect(StringFromGUID2, isA<Function>());
    });
    test('Can instantiate StringFromIID', () {
      final ole32 = DynamicLibrary.open('ole32.dll');
      final StringFromIID = ole32.lookupFunction<
          Int32 Function(Pointer<GUID> rclsid, Pointer<Pointer<Utf16>> lplpsz),
          int Function(Pointer<GUID> rclsid,
              Pointer<Pointer<Utf16>> lplpsz)>('StringFromIID');
      expect(StringFromIID, isA<Function>());
    });
  });

  group('Test shell32 functions', () {
    test('Can instantiate CommandLineToArgv', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final CommandLineToArgv = shell32.lookupFunction<
          Pointer<Pointer<Utf16>> Function(
              Pointer<Utf16> lpCmdLine, Pointer<Int32> pNumArgs),
          Pointer<Pointer<Utf16>> Function(Pointer<Utf16> lpCmdLine,
              Pointer<Int32> pNumArgs)>('CommandLineToArgvW');
      expect(CommandLineToArgv, isA<Function>());
    });
    test('Can instantiate ExtractAssociatedIcon', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final ExtractAssociatedIcon = shell32.lookupFunction<
          IntPtr Function(
              IntPtr hInst, Pointer<Utf16> pszIconPath, Pointer<Uint16> piIcon),
          int Function(int hInst, Pointer<Utf16> pszIconPath,
              Pointer<Uint16> piIcon)>('ExtractAssociatedIconW');
      expect(ExtractAssociatedIcon, isA<Function>());
    });
    test('Can instantiate FindExecutable', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final FindExecutable = shell32.lookupFunction<
          IntPtr Function(Pointer<Utf16> lpFile, Pointer<Utf16> lpDirectory,
              Pointer<Utf16> lpResult),
          int Function(Pointer<Utf16> lpFile, Pointer<Utf16> lpDirectory,
              Pointer<Utf16> lpResult)>('FindExecutableW');
      expect(FindExecutable, isA<Function>());
    });
    test('Can instantiate SHCreateItemFromParsingName', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHCreateItemFromParsingName = shell32.lookupFunction<
          Int32 Function(Pointer<Utf16> pszPath, Pointer<COMObject> pbc,
              Pointer<GUID> riid, Pointer<Pointer> ppv),
          int Function(
              Pointer<Utf16> pszPath,
              Pointer<COMObject> pbc,
              Pointer<GUID> riid,
              Pointer<Pointer> ppv)>('SHCreateItemFromParsingName');
      expect(SHCreateItemFromParsingName, isA<Function>());
    });
    test('Can instantiate Shell_NotifyIcon', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final Shell_NotifyIcon = shell32.lookupFunction<
          Int32 Function(Uint32 dwMessage, Pointer<NOTIFYICONDATA> lpData),
          int Function(int dwMessage,
              Pointer<NOTIFYICONDATA> lpData)>('Shell_NotifyIconW');
      expect(Shell_NotifyIcon, isA<Function>());
    });
    test('Can instantiate ShellAbout', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final ShellAbout = shell32.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<Utf16> szApp,
              Pointer<Utf16> szOtherStuff, IntPtr hIcon),
          int Function(int hWnd, Pointer<Utf16> szApp,
              Pointer<Utf16> szOtherStuff, int hIcon)>('ShellAboutW');
      expect(ShellAbout, isA<Function>());
    });
    test('Can instantiate ShellExecute', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final ShellExecute = shell32.lookupFunction<
          IntPtr Function(
              IntPtr hwnd,
              Pointer<Utf16> lpOperation,
              Pointer<Utf16> lpFile,
              Pointer<Utf16> lpParameters,
              Pointer<Utf16> lpDirectory,
              Uint32 nShowCmd),
          int Function(
              int hwnd,
              Pointer<Utf16> lpOperation,
              Pointer<Utf16> lpFile,
              Pointer<Utf16> lpParameters,
              Pointer<Utf16> lpDirectory,
              int nShowCmd)>('ShellExecuteW');
      expect(ShellExecute, isA<Function>());
    });
    test('Can instantiate ShellExecuteEx', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final ShellExecuteEx = shell32.lookupFunction<
          Int32 Function(Pointer<SHELLEXECUTEINFO> pExecInfo),
          int Function(Pointer<SHELLEXECUTEINFO> pExecInfo)>('ShellExecuteExW');
      expect(ShellExecuteEx, isA<Function>());
    });
    test('Can instantiate SHEmptyRecycleBin', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHEmptyRecycleBin = shell32.lookupFunction<
          Int32 Function(
              IntPtr hwnd, Pointer<Utf16> pszRootPath, Uint32 dwFlags),
          int Function(int hwnd, Pointer<Utf16> pszRootPath,
              int dwFlags)>('SHEmptyRecycleBinW');
      expect(SHEmptyRecycleBin, isA<Function>());
    });
    test('Can instantiate SHGetDesktopFolder', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHGetDesktopFolder = shell32.lookupFunction<
          Int32 Function(Pointer<Pointer<COMObject>> ppshf),
          int Function(
              Pointer<Pointer<COMObject>> ppshf)>('SHGetDesktopFolder');
      expect(SHGetDesktopFolder, isA<Function>());
    });
    test('Can instantiate SHGetDiskFreeSpaceEx', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHGetDiskFreeSpaceEx = shell32.lookupFunction<
              Int32 Function(
                  Pointer<Utf16> pszDirectoryName,
                  Pointer<Uint64> pulFreeBytesAvailableToCaller,
                  Pointer<Uint64> pulTotalNumberOfBytes,
                  Pointer<Uint64> pulTotalNumberOfFreeBytes),
              int Function(
                  Pointer<Utf16> pszDirectoryName,
                  Pointer<Uint64> pulFreeBytesAvailableToCaller,
                  Pointer<Uint64> pulTotalNumberOfBytes,
                  Pointer<Uint64> pulTotalNumberOfFreeBytes)>(
          'SHGetDiskFreeSpaceExW');
      expect(SHGetDiskFreeSpaceEx, isA<Function>());
    });
    test('Can instantiate SHGetDriveMedia', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHGetDriveMedia = shell32.lookupFunction<
          Int32 Function(
              Pointer<Utf16> pszDrive, Pointer<Uint32> pdwMediaContent),
          int Function(Pointer<Utf16> pszDrive,
              Pointer<Uint32> pdwMediaContent)>('SHGetDriveMedia');
      expect(SHGetDriveMedia, isA<Function>());
    });
    test('Can instantiate SHGetFolderPath', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHGetFolderPath = shell32.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 csidl, IntPtr hToken,
              Uint32 dwFlags, Pointer<Utf16> pszPath),
          int Function(int hwnd, int csidl, int hToken, int dwFlags,
              Pointer<Utf16> pszPath)>('SHGetFolderPathW');
      expect(SHGetFolderPath, isA<Function>());
    });
    test('Can instantiate SHGetKnownFolderPath', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHGetKnownFolderPath = shell32.lookupFunction<
          Int32 Function(Pointer<GUID> rfid, Int32 dwFlags, IntPtr hToken,
              Pointer<Pointer<Utf16>> ppszPath),
          int Function(Pointer<GUID> rfid, int dwFlags, int hToken,
              Pointer<Pointer<Utf16>> ppszPath)>('SHGetKnownFolderPath');
      expect(SHGetKnownFolderPath, isA<Function>());
    });
    test('Can instantiate SHQueryRecycleBin', () {
      final shell32 = DynamicLibrary.open('shell32.dll');
      final SHQueryRecycleBin = shell32.lookupFunction<
          Int32 Function(Pointer<Utf16> pszRootPath,
              Pointer<SHQUERYRBINFO> pSHQueryRBInfo),
          int Function(Pointer<Utf16> pszRootPath,
              Pointer<SHQUERYRBINFO> pSHQueryRBInfo)>('SHQueryRecycleBinW');
      expect(SHQueryRecycleBin, isA<Function>());
    });
  });

  group('Test api-ms-win-core-handle-l1-1-0 functions', () {
    if (windowsBuildNumber >= 10240) {
      test('Can instantiate CompareObjectHandles', () {
        final api_ms_win_core_handle_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-handle-l1-1-0.dll');
        final CompareObjectHandles =
            api_ms_win_core_handle_l1_1_0.lookupFunction<
                Int32 Function(
                    IntPtr hFirstObjectHandle, IntPtr hSecondObjectHandle),
                int Function(int hFirstObjectHandle,
                    int hSecondObjectHandle)>('CompareObjectHandles');
        expect(CompareObjectHandles, isA<Function>());
      });
    }
  });

  group('Test advapi32 functions', () {
    test('Can instantiate CredDelete', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final CredDelete = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> TargetName, Uint32 Type, Uint32 Flags),
          int Function(
              Pointer<Utf16> TargetName, int Type, int Flags)>('CredDeleteW');
      expect(CredDelete, isA<Function>());
    });
    test('Can instantiate CredFree', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final CredFree = advapi32.lookupFunction<Void Function(Pointer Buffer),
          void Function(Pointer Buffer)>('CredFree');
      expect(CredFree, isA<Function>());
    });
    test('Can instantiate CredRead', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final CredRead = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> TargetName, Uint32 Type, Uint32 Flags,
              Pointer<Pointer<CREDENTIAL>> Credential),
          int Function(Pointer<Utf16> TargetName, int Type, int Flags,
              Pointer<Pointer<CREDENTIAL>> Credential)>('CredReadW');
      expect(CredRead, isA<Function>());
    });
    test('Can instantiate CredWrite', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final CredWrite = advapi32.lookupFunction<
          Int32 Function(Pointer<CREDENTIAL> Credential, Uint32 Flags),
          int Function(
              Pointer<CREDENTIAL> Credential, int Flags)>('CredWriteW');
      expect(CredWrite, isA<Function>());
    });
    test('Can instantiate DecryptFile', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final DecryptFile = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName, Uint32 dwReserved),
          int Function(
              Pointer<Utf16> lpFileName, int dwReserved)>('DecryptFileW');
      expect(DecryptFile, isA<Function>());
    });
    test('Can instantiate EncryptFile', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final EncryptFile = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName),
          int Function(Pointer<Utf16> lpFileName)>('EncryptFileW');
      expect(EncryptFile, isA<Function>());
    });
    test('Can instantiate FileEncryptionStatus', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final FileEncryptionStatus = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpFileName, Pointer<Uint32> lpStatus),
          int Function(Pointer<Utf16> lpFileName,
              Pointer<Uint32> lpStatus)>('FileEncryptionStatusW');
      expect(FileEncryptionStatus, isA<Function>());
    });
    test('Can instantiate GetTokenInformation', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final GetTokenInformation = advapi32.lookupFunction<
          Int32 Function(
              IntPtr TokenHandle,
              Int32 TokenInformationClass,
              Pointer TokenInformation,
              Uint32 TokenInformationLength,
              Pointer<Uint32> ReturnLength),
          int Function(
              int TokenHandle,
              int TokenInformationClass,
              Pointer TokenInformation,
              int TokenInformationLength,
              Pointer<Uint32> ReturnLength)>('GetTokenInformation');
      expect(GetTokenInformation, isA<Function>());
    });
    test('Can instantiate GetUserName', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final GetUserName = advapi32.lookupFunction<
          Int32 Function(Pointer<Utf16> lpBuffer, Pointer<Uint32> pcbBuffer),
          int Function(Pointer<Utf16> lpBuffer,
              Pointer<Uint32> pcbBuffer)>('GetUserNameW');
      expect(GetUserName, isA<Function>());
    });
    test('Can instantiate InitiateShutdown', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final InitiateShutdown = advapi32.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lpMachineName,
              Pointer<Utf16> lpMessage,
              Uint32 dwGracePeriod,
              Uint32 dwShutdownFlags,
              Uint32 dwReason),
          int Function(
              Pointer<Utf16> lpMachineName,
              Pointer<Utf16> lpMessage,
              int dwGracePeriod,
              int dwShutdownFlags,
              int dwReason)>('InitiateShutdownW');
      expect(InitiateShutdown, isA<Function>());
    });
    test('Can instantiate OpenProcessToken', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final OpenProcessToken = advapi32.lookupFunction<
          Int32 Function(IntPtr ProcessHandle, Uint32 DesiredAccess,
              Pointer<IntPtr> TokenHandle),
          int Function(int ProcessHandle, int DesiredAccess,
              Pointer<IntPtr> TokenHandle)>('OpenProcessToken');
      expect(OpenProcessToken, isA<Function>());
    });
    test('Can instantiate OpenThreadToken', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final OpenThreadToken = advapi32.lookupFunction<
          Int32 Function(IntPtr ThreadHandle, Uint32 DesiredAccess,
              Int32 OpenAsSelf, Pointer<IntPtr> TokenHandle),
          int Function(int ThreadHandle, int DesiredAccess, int OpenAsSelf,
              Pointer<IntPtr> TokenHandle)>('OpenThreadToken');
      expect(OpenThreadToken, isA<Function>());
    });
    test('Can instantiate RegCloseKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegCloseKey = advapi32.lookupFunction<Uint32 Function(IntPtr hKey),
          int Function(int hKey)>('RegCloseKey');
      expect(RegCloseKey, isA<Function>());
    });
    test('Can instantiate RegConnectRegistry', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegConnectRegistry = advapi32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpMachineName, IntPtr hKey,
              Pointer<IntPtr> phkResult),
          int Function(Pointer<Utf16> lpMachineName, int hKey,
              Pointer<IntPtr> phkResult)>('RegConnectRegistryW');
      expect(RegConnectRegistry, isA<Function>());
    });
    test('Can instantiate RegCopyTree', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegCopyTree = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKeySrc, Pointer<Utf16> lpSubKey, IntPtr hKeyDest),
          int Function(int hKeySrc, Pointer<Utf16> lpSubKey,
              int hKeyDest)>('RegCopyTreeW');
      expect(RegCopyTree, isA<Function>());
    });
    test('Can instantiate RegCreateKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegCreateKey = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult),
          int Function(int hKey, Pointer<Utf16> lpSubKey,
              Pointer<IntPtr> phkResult)>('RegCreateKeyW');
      expect(RegCreateKey, isA<Function>());
    });
    test('Can instantiate RegCreateKeyEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegCreateKeyEx = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpSubKey,
              Uint32 Reserved,
              Pointer<Utf16> lpClass,
              Uint32 dwOptions,
              Uint32 samDesired,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Pointer<IntPtr> phkResult,
              Pointer<Uint32> lpdwDisposition),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              int Reserved,
              Pointer<Utf16> lpClass,
              int dwOptions,
              int samDesired,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Pointer<IntPtr> phkResult,
              Pointer<Uint32> lpdwDisposition)>('RegCreateKeyExW');
      expect(RegCreateKeyEx, isA<Function>());
    });
    test('Can instantiate RegCreateKeyTransacted', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegCreateKeyTransacted = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpSubKey,
              Uint32 Reserved,
              Pointer<Utf16> lpClass,
              Uint32 dwOptions,
              Uint32 samDesired,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Pointer<IntPtr> phkResult,
              Pointer<Uint32> lpdwDisposition,
              IntPtr hTransaction,
              Pointer pExtendedParemeter),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              int Reserved,
              Pointer<Utf16> lpClass,
              int dwOptions,
              int samDesired,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              Pointer<IntPtr> phkResult,
              Pointer<Uint32> lpdwDisposition,
              int hTransaction,
              Pointer pExtendedParemeter)>('RegCreateKeyTransactedW');
      expect(RegCreateKeyTransacted, isA<Function>());
    });
    test('Can instantiate RegDeleteKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
          int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegDeleteKeyW');
      expect(RegDeleteKey, isA<Function>());
    });
    test('Can instantiate RegDeleteKeyEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteKeyEx = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey,
              Uint32 samDesired, Uint32 Reserved),
          int Function(int hKey, Pointer<Utf16> lpSubKey, int samDesired,
              int Reserved)>('RegDeleteKeyExW');
      expect(RegDeleteKeyEx, isA<Function>());
    });
    test('Can instantiate RegDeleteKeyTransacted', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteKeyTransacted = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpSubKey,
              Uint32 samDesired,
              Uint32 Reserved,
              IntPtr hTransaction,
              Pointer pExtendedParameter),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              int samDesired,
              int Reserved,
              int hTransaction,
              Pointer pExtendedParameter)>('RegDeleteKeyTransactedW');
      expect(RegDeleteKeyTransacted, isA<Function>());
    });
    test('Can instantiate RegDeleteKeyValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteKeyValue = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpValueName),
          int Function(int hKey, Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpValueName)>('RegDeleteKeyValueW');
      expect(RegDeleteKeyValue, isA<Function>());
    });
    test('Can instantiate RegDeleteTree', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteTree = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
          int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegDeleteTreeW');
      expect(RegDeleteTree, isA<Function>());
    });
    test('Can instantiate RegDeleteValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDeleteValue = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpValueName),
          int Function(
              int hKey, Pointer<Utf16> lpValueName)>('RegDeleteValueW');
      expect(RegDeleteValue, isA<Function>());
    });
    test('Can instantiate RegDisablePredefinedCache', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDisablePredefinedCache =
          advapi32.lookupFunction<Uint32 Function(), int Function()>(
              'RegDisablePredefinedCache');
      expect(RegDisablePredefinedCache, isA<Function>());
    });
    test('Can instantiate RegDisablePredefinedCacheEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDisablePredefinedCacheEx =
          advapi32.lookupFunction<Uint32 Function(), int Function()>(
              'RegDisablePredefinedCacheEx');
      expect(RegDisablePredefinedCacheEx, isA<Function>());
    });
    test('Can instantiate RegDisableReflectionKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegDisableReflectionKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hBase),
          int Function(int hBase)>('RegDisableReflectionKey');
      expect(RegDisableReflectionKey, isA<Function>());
    });
    test('Can instantiate RegEnableReflectionKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegEnableReflectionKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hBase),
          int Function(int hBase)>('RegEnableReflectionKey');
      expect(RegEnableReflectionKey, isA<Function>());
    });
    test('Can instantiate RegEnumKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegEnumKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Uint32 dwIndex, Pointer<Utf16> lpName,
              Uint32 cchName),
          int Function(int hKey, int dwIndex, Pointer<Utf16> lpName,
              int cchName)>('RegEnumKeyW');
      expect(RegEnumKey, isA<Function>());
    });
    test('Can instantiate RegEnumKeyEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegEnumKeyEx = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Uint32 dwIndex,
              Pointer<Utf16> lpName,
              Pointer<Uint32> lpcchName,
              Pointer<Uint32> lpReserved,
              Pointer<Utf16> lpClass,
              Pointer<Uint32> lpcchClass,
              Pointer<FILETIME> lpftLastWriteTime),
          int Function(
              int hKey,
              int dwIndex,
              Pointer<Utf16> lpName,
              Pointer<Uint32> lpcchName,
              Pointer<Uint32> lpReserved,
              Pointer<Utf16> lpClass,
              Pointer<Uint32> lpcchClass,
              Pointer<FILETIME> lpftLastWriteTime)>('RegEnumKeyExW');
      expect(RegEnumKeyEx, isA<Function>());
    });
    test('Can instantiate RegEnumValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegEnumValue = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Uint32 dwIndex,
              Pointer<Utf16> lpValueName,
              Pointer<Uint32> lpcchValueName,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpType,
              Pointer<Uint8> lpData,
              Pointer<Uint32> lpcbData),
          int Function(
              int hKey,
              int dwIndex,
              Pointer<Utf16> lpValueName,
              Pointer<Uint32> lpcchValueName,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpType,
              Pointer<Uint8> lpData,
              Pointer<Uint32> lpcbData)>('RegEnumValueW');
      expect(RegEnumValue, isA<Function>());
    });
    test('Can instantiate RegFlushKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegFlushKey = advapi32.lookupFunction<Uint32 Function(IntPtr hKey),
          int Function(int hKey)>('RegFlushKey');
      expect(RegFlushKey, isA<Function>());
    });
    test('Can instantiate RegGetValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegGetValue = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hkey,
              Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpValue,
              Uint32 dwFlags,
              Pointer<Uint32> pdwType,
              Pointer pvData,
              Pointer<Uint32> pcbData),
          int Function(
              int hkey,
              Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpValue,
              int dwFlags,
              Pointer<Uint32> pdwType,
              Pointer pvData,
              Pointer<Uint32> pcbData)>('RegGetValueW');
      expect(RegGetValue, isA<Function>());
    });
    test('Can instantiate RegLoadAppKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegLoadAppKey = advapi32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpFile, Pointer<IntPtr> phkResult,
              Uint32 samDesired, Uint32 dwOptions, Uint32 Reserved),
          int Function(Pointer<Utf16> lpFile, Pointer<IntPtr> phkResult,
              int samDesired, int dwOptions, int Reserved)>('RegLoadAppKeyW');
      expect(RegLoadAppKey, isA<Function>());
    });
    test('Can instantiate RegLoadKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegLoadKey = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpFile),
          int Function(int hKey, Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpFile)>('RegLoadKeyW');
      expect(RegLoadKey, isA<Function>());
    });
    test('Can instantiate RegLoadMUIString', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegLoadMUIString = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> pszValue,
              Pointer<Utf16> pszOutBuf,
              Uint32 cbOutBuf,
              Pointer<Uint32> pcbData,
              Uint32 Flags,
              Pointer<Utf16> pszDirectory),
          int Function(
              int hKey,
              Pointer<Utf16> pszValue,
              Pointer<Utf16> pszOutBuf,
              int cbOutBuf,
              Pointer<Uint32> pcbData,
              int Flags,
              Pointer<Utf16> pszDirectory)>('RegLoadMUIStringW');
      expect(RegLoadMUIString, isA<Function>());
    });
    test('Can instantiate RegNotifyChangeKeyValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegNotifyChangeKeyValue = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Int32 bWatchSubtree,
              Uint32 dwNotifyFilter, IntPtr hEvent, Int32 fAsynchronous),
          int Function(int hKey, int bWatchSubtree, int dwNotifyFilter,
              int hEvent, int fAsynchronous)>('RegNotifyChangeKeyValue');
      expect(RegNotifyChangeKeyValue, isA<Function>());
    });
    test('Can instantiate RegOpenCurrentUser', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOpenCurrentUser = advapi32.lookupFunction<
          Uint32 Function(Uint32 samDesired, Pointer<IntPtr> phkResult),
          int Function(
              int samDesired, Pointer<IntPtr> phkResult)>('RegOpenCurrentUser');
      expect(RegOpenCurrentUser, isA<Function>());
    });
    test('Can instantiate RegOpenKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOpenKey = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult),
          int Function(int hKey, Pointer<Utf16> lpSubKey,
              Pointer<IntPtr> phkResult)>('RegOpenKeyW');
      expect(RegOpenKey, isA<Function>());
    });
    test('Can instantiate RegOpenKeyEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOpenKeyEx = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey,
              Uint32 ulOptions, Uint32 samDesired, Pointer<IntPtr> phkResult),
          int Function(int hKey, Pointer<Utf16> lpSubKey, int ulOptions,
              int samDesired, Pointer<IntPtr> phkResult)>('RegOpenKeyExW');
      expect(RegOpenKeyEx, isA<Function>());
    });
    test('Can instantiate RegOpenKeyTransacted', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOpenKeyTransacted = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpSubKey,
              Uint32 ulOptions,
              Uint32 samDesired,
              Pointer<IntPtr> phkResult,
              IntPtr hTransaction,
              Pointer pExtendedParemeter),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              int ulOptions,
              int samDesired,
              Pointer<IntPtr> phkResult,
              int hTransaction,
              Pointer pExtendedParemeter)>('RegOpenKeyTransactedW');
      expect(RegOpenKeyTransacted, isA<Function>());
    });
    test('Can instantiate RegOpenUserClassesRoot', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOpenUserClassesRoot = advapi32.lookupFunction<
          Uint32 Function(IntPtr hToken, Uint32 dwOptions, Uint32 samDesired,
              Pointer<IntPtr> phkResult),
          int Function(int hToken, int dwOptions, int samDesired,
              Pointer<IntPtr> phkResult)>('RegOpenUserClassesRoot');
      expect(RegOpenUserClassesRoot, isA<Function>());
    });
    test('Can instantiate RegOverridePredefKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegOverridePredefKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, IntPtr hNewHKey),
          int Function(int hKey, int hNewHKey)>('RegOverridePredefKey');
      expect(RegOverridePredefKey, isA<Function>());
    });
    test('Can instantiate RegQueryInfoKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegQueryInfoKey = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpClass,
              Pointer<Uint32> lpcchClass,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpcSubKeys,
              Pointer<Uint32> lpcbMaxSubKeyLen,
              Pointer<Uint32> lpcbMaxClassLen,
              Pointer<Uint32> lpcValues,
              Pointer<Uint32> lpcbMaxValueNameLen,
              Pointer<Uint32> lpcbMaxValueLen,
              Pointer<Uint32> lpcbSecurityDescriptor,
              Pointer<FILETIME> lpftLastWriteTime),
          int Function(
              int hKey,
              Pointer<Utf16> lpClass,
              Pointer<Uint32> lpcchClass,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpcSubKeys,
              Pointer<Uint32> lpcbMaxSubKeyLen,
              Pointer<Uint32> lpcbMaxClassLen,
              Pointer<Uint32> lpcValues,
              Pointer<Uint32> lpcbMaxValueNameLen,
              Pointer<Uint32> lpcbMaxValueLen,
              Pointer<Uint32> lpcbSecurityDescriptor,
              Pointer<FILETIME> lpftLastWriteTime)>('RegQueryInfoKeyW');
      expect(RegQueryInfoKey, isA<Function>());
    });
    test('Can instantiate RegQueryMultipleValues', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegQueryMultipleValues = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<VALENT> val_list,
              Uint32 num_vals,
              Pointer<Utf16> lpValueBuf,
              Pointer<Uint32> ldwTotsize),
          int Function(
              int hKey,
              Pointer<VALENT> val_list,
              int num_vals,
              Pointer<Utf16> lpValueBuf,
              Pointer<Uint32> ldwTotsize)>('RegQueryMultipleValuesW');
      expect(RegQueryMultipleValues, isA<Function>());
    });
    test('Can instantiate RegQueryReflectionKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegQueryReflectionKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hBase, Pointer<Int32> bIsReflectionDisabled),
          int Function(int hBase,
              Pointer<Int32> bIsReflectionDisabled)>('RegQueryReflectionKey');
      expect(RegQueryReflectionKey, isA<Function>());
    });
    test('Can instantiate RegQueryValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegQueryValue = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpData, Pointer<Int32> lpcbData),
          int Function(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpData,
              Pointer<Int32> lpcbData)>('RegQueryValueW');
      expect(RegQueryValue, isA<Function>());
    });
    test('Can instantiate RegQueryValueEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegQueryValueEx = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpValueName,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpType,
              Pointer<Uint8> lpData,
              Pointer<Uint32> lpcbData),
          int Function(
              int hKey,
              Pointer<Utf16> lpValueName,
              Pointer<Uint32> lpReserved,
              Pointer<Uint32> lpType,
              Pointer<Uint8> lpData,
              Pointer<Uint32> lpcbData)>('RegQueryValueExW');
      expect(RegQueryValueEx, isA<Function>());
    });
    test('Can instantiate RegRenameKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegRenameKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKeyName,
              Pointer<Utf16> lpNewKeyName),
          int Function(int hKey, Pointer<Utf16> lpSubKeyName,
              Pointer<Utf16> lpNewKeyName)>('RegRenameKey');
      expect(RegRenameKey, isA<Function>());
    });
    test('Can instantiate RegReplaceKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegReplaceKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpNewFile, Pointer<Utf16> lpOldFile),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpNewFile,
              Pointer<Utf16> lpOldFile)>('RegReplaceKeyW');
      expect(RegReplaceKey, isA<Function>());
    });
    test('Can instantiate RegRestoreKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegRestoreKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile, Int32 dwFlags),
          int Function(
              int hKey, Pointer<Utf16> lpFile, int dwFlags)>('RegRestoreKeyW');
      expect(RegRestoreKey, isA<Function>());
    });
    test('Can instantiate RegSaveKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegSaveKey = advapi32.lookupFunction<
              Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
              int Function(int hKey, Pointer<Utf16> lpFile,
                  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>(
          'RegSaveKeyW');
      expect(RegSaveKey, isA<Function>());
    });
    test('Can instantiate RegSaveKeyEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegSaveKeyEx = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes, Uint32 Flags),
          int Function(
              int hKey,
              Pointer<Utf16> lpFile,
              Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
              int Flags)>('RegSaveKeyExW');
      expect(RegSaveKeyEx, isA<Function>());
    });
    test('Can instantiate RegSetKeyValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegSetKeyValue = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpValueName,
              Uint32 dwType,
              Pointer lpData,
              Uint32 cbData),
          int Function(
              int hKey,
              Pointer<Utf16> lpSubKey,
              Pointer<Utf16> lpValueName,
              int dwType,
              Pointer lpData,
              int cbData)>('RegSetKeyValueW');
      expect(RegSetKeyValue, isA<Function>());
    });
    test('Can instantiate RegSetValue', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegSetValue = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Uint32 dwType,
              Pointer<Utf16> lpData, Uint32 cbData),
          int Function(int hKey, Pointer<Utf16> lpSubKey, int dwType,
              Pointer<Utf16> lpData, int cbData)>('RegSetValueW');
      expect(RegSetValue, isA<Function>());
    });
    test('Can instantiate RegSetValueEx', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegSetValueEx = advapi32.lookupFunction<
          Uint32 Function(
              IntPtr hKey,
              Pointer<Utf16> lpValueName,
              Uint32 Reserved,
              Uint32 dwType,
              Pointer<Uint8> lpData,
              Uint32 cbData),
          int Function(int hKey, Pointer<Utf16> lpValueName, int Reserved,
              int dwType, Pointer<Uint8> lpData, int cbData)>('RegSetValueExW');
      expect(RegSetValueEx, isA<Function>());
    });
    test('Can instantiate RegUnLoadKey', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final RegUnLoadKey = advapi32.lookupFunction<
          Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
          int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegUnLoadKeyW');
      expect(RegUnLoadKey, isA<Function>());
    });
    test('Can instantiate SetThreadToken', () {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final SetThreadToken = advapi32.lookupFunction<
          Int32 Function(Pointer<IntPtr> Thread, IntPtr Token),
          int Function(Pointer<IntPtr> Thread, int Token)>('SetThreadToken');
      expect(SetThreadToken, isA<Function>());
    });
  });

  group('Test crypt32 functions', () {
    test('Can instantiate CryptProtectData', () {
      final crypt32 = DynamicLibrary.open('crypt32.dll');
      final CryptProtectData = crypt32.lookupFunction<
          Int32 Function(
              Pointer<CRYPT_INTEGER_BLOB> pDataIn,
              Pointer<Utf16> szDataDescr,
              Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
              Pointer pvReserved,
              Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
              Uint32 dwFlags,
              Pointer<CRYPT_INTEGER_BLOB> pDataOut),
          int Function(
              Pointer<CRYPT_INTEGER_BLOB> pDataIn,
              Pointer<Utf16> szDataDescr,
              Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
              Pointer pvReserved,
              Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
              int dwFlags,
              Pointer<CRYPT_INTEGER_BLOB> pDataOut)>('CryptProtectData');
      expect(CryptProtectData, isA<Function>());
    });
    test('Can instantiate CryptProtectMemory', () {
      final crypt32 = DynamicLibrary.open('crypt32.dll');
      final CryptProtectMemory = crypt32.lookupFunction<
          Int32 Function(Pointer pDataIn, Uint32 cbDataIn, Uint32 dwFlags),
          int Function(Pointer pDataIn, int cbDataIn,
              int dwFlags)>('CryptProtectMemory');
      expect(CryptProtectMemory, isA<Function>());
    });
    test('Can instantiate CryptUnprotectData', () {
      final crypt32 = DynamicLibrary.open('crypt32.dll');
      final CryptUnprotectData = crypt32.lookupFunction<
          Int32 Function(
              Pointer<CRYPT_INTEGER_BLOB> pDataIn,
              Pointer<Pointer<Utf16>> ppszDataDescr,
              Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
              Pointer pvReserved,
              Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
              Uint32 dwFlags,
              Pointer<CRYPT_INTEGER_BLOB> pDataOut),
          int Function(
              Pointer<CRYPT_INTEGER_BLOB> pDataIn,
              Pointer<Pointer<Utf16>> ppszDataDescr,
              Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
              Pointer pvReserved,
              Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
              int dwFlags,
              Pointer<CRYPT_INTEGER_BLOB> pDataOut)>('CryptUnprotectData');
      expect(CryptUnprotectData, isA<Function>());
    });
    test('Can instantiate CryptUnprotectMemory', () {
      final crypt32 = DynamicLibrary.open('crypt32.dll');
      final CryptUnprotectMemory = crypt32.lookupFunction<
          Int32 Function(Pointer pDataIn, Uint32 cbDataIn, Uint32 dwFlags),
          int Function(Pointer pDataIn, int cbDataIn,
              int dwFlags)>('CryptUnprotectMemory');
      expect(CryptUnprotectMemory, isA<Function>());
    });
    test('Can instantiate CryptUpdateProtectedState', () {
      final crypt32 = DynamicLibrary.open('crypt32.dll');
      final CryptUpdateProtectedState = crypt32.lookupFunction<
          Int32 Function(
              Pointer pOldSid,
              Pointer<Utf16> pwszOldPassword,
              Uint32 dwFlags,
              Pointer<Uint32> pdwSuccessCount,
              Pointer<Uint32> pdwFailureCount),
          int Function(
              Pointer pOldSid,
              Pointer<Utf16> pwszOldPassword,
              int dwFlags,
              Pointer<Uint32> pdwSuccessCount,
              Pointer<Uint32> pdwFailureCount)>('CryptUpdateProtectedState');
      expect(CryptUpdateProtectedState, isA<Function>());
    });
  });

  group('Test comctl32 functions', () {
    test('Can instantiate DefSubclassProc', () {
      final comctl32 = DynamicLibrary.open('comctl32.dll');
      final DefSubclassProc = comctl32.lookupFunction<
          IntPtr Function(
              IntPtr hWnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam),
          int Function(
              int hWnd, int uMsg, int wParam, int lParam)>('DefSubclassProc');
      expect(DefSubclassProc, isA<Function>());
    });
    test('Can instantiate DrawStatusText', () {
      final comctl32 = DynamicLibrary.open('comctl32.dll');
      final DrawStatusText = comctl32.lookupFunction<
          Void Function(IntPtr hDC, Pointer<RECT> lprc, Pointer<Utf16> pszText,
              Uint32 uFlags),
          void Function(int hDC, Pointer<RECT> lprc, Pointer<Utf16> pszText,
              int uFlags)>('DrawStatusTextW');
      expect(DrawStatusText, isA<Function>());
    });
    test('Can instantiate InitCommonControlsEx', () {
      final comctl32 = DynamicLibrary.open('comctl32.dll');
      final InitCommonControlsEx = comctl32.lookupFunction<
          Int32 Function(Pointer<INITCOMMONCONTROLSEX> picce),
          int Function(
              Pointer<INITCOMMONCONTROLSEX> picce)>('InitCommonControlsEx');
      expect(InitCommonControlsEx, isA<Function>());
    });
    test('Can instantiate RemoveWindowSubclass', () {
      final comctl32 = DynamicLibrary.open('comctl32.dll');
      final RemoveWindowSubclass = comctl32.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              Pointer<NativeFunction<SubclassProc>> pfnSubclass,
              IntPtr uIdSubclass),
          int Function(
              int hWnd,
              Pointer<NativeFunction<SubclassProc>> pfnSubclass,
              int uIdSubclass)>('RemoveWindowSubclass');
      expect(RemoveWindowSubclass, isA<Function>());
    });
    test('Can instantiate SetWindowSubclass', () {
      final comctl32 = DynamicLibrary.open('comctl32.dll');
      final SetWindowSubclass = comctl32.lookupFunction<
          Int32 Function(
              IntPtr hWnd,
              Pointer<NativeFunction<SubclassProc>> pfnSubclass,
              IntPtr uIdSubclass,
              IntPtr dwRefData),
          int Function(
              int hWnd,
              Pointer<NativeFunction<SubclassProc>> pfnSubclass,
              int uIdSubclass,
              int dwRefData)>('SetWindowSubclass');
      expect(SetWindowSubclass, isA<Function>());
    });
  });

  group('Test dxva2 functions', () {
    test('Can instantiate DestroyPhysicalMonitor', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final DestroyPhysicalMonitor = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor),
          int Function(int hMonitor)>('DestroyPhysicalMonitor');
      expect(DestroyPhysicalMonitor, isA<Function>());
    });
    test('Can instantiate DestroyPhysicalMonitors', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final DestroyPhysicalMonitors = dxva2.lookupFunction<
              Int32 Function(Uint32 dwPhysicalMonitorArraySize,
                  Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray),
              int Function(int dwPhysicalMonitorArraySize,
                  Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray)>(
          'DestroyPhysicalMonitors');
      expect(DestroyPhysicalMonitors, isA<Function>());
    });
    test('Can instantiate GetMonitorBrightness', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorBrightness = dxva2.lookupFunction<
          Int32 Function(
              IntPtr hMonitor,
              Pointer<Uint32> pdwMinimumBrightness,
              Pointer<Uint32> pdwCurrentBrightness,
              Pointer<Uint32> pdwMaximumBrightness),
          int Function(
              int hMonitor,
              Pointer<Uint32> pdwMinimumBrightness,
              Pointer<Uint32> pdwCurrentBrightness,
              Pointer<Uint32> pdwMaximumBrightness)>('GetMonitorBrightness');
      expect(GetMonitorBrightness, isA<Function>());
    });
    test('Can instantiate GetMonitorCapabilities', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorCapabilities = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor,
                  Pointer<Uint32> pdwMonitorCapabilities,
                  Pointer<Uint32> pdwSupportedColorTemperatures),
              int Function(int hMonitor, Pointer<Uint32> pdwMonitorCapabilities,
                  Pointer<Uint32> pdwSupportedColorTemperatures)>(
          'GetMonitorCapabilities');
      expect(GetMonitorCapabilities, isA<Function>());
    });
    test('Can instantiate GetMonitorColorTemperature', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorColorTemperature = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor, Pointer<Int32> pctCurrentColorTemperature),
              int Function(
                  int hMonitor, Pointer<Int32> pctCurrentColorTemperature)>(
          'GetMonitorColorTemperature');
      expect(GetMonitorColorTemperature, isA<Function>());
    });
    test('Can instantiate GetMonitorContrast', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorContrast = dxva2.lookupFunction<
          Int32 Function(
              IntPtr hMonitor,
              Pointer<Uint32> pdwMinimumContrast,
              Pointer<Uint32> pdwCurrentContrast,
              Pointer<Uint32> pdwMaximumContrast),
          int Function(
              int hMonitor,
              Pointer<Uint32> pdwMinimumContrast,
              Pointer<Uint32> pdwCurrentContrast,
              Pointer<Uint32> pdwMaximumContrast)>('GetMonitorContrast');
      expect(GetMonitorContrast, isA<Function>());
    });
    test('Can instantiate GetMonitorDisplayAreaPosition', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorDisplayAreaPosition = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor,
                  Int32 ptPositionType,
                  Pointer<Uint32> pdwMinimumPosition,
                  Pointer<Uint32> pdwCurrentPosition,
                  Pointer<Uint32> pdwMaximumPosition),
              int Function(
                  int hMonitor,
                  int ptPositionType,
                  Pointer<Uint32> pdwMinimumPosition,
                  Pointer<Uint32> pdwCurrentPosition,
                  Pointer<Uint32> pdwMaximumPosition)>(
          'GetMonitorDisplayAreaPosition');
      expect(GetMonitorDisplayAreaPosition, isA<Function>());
    });
    test('Can instantiate GetMonitorDisplayAreaSize', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorDisplayAreaSize = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor,
                  Int32 stSizeType,
                  Pointer<Uint32> pdwMinimumWidthOrHeight,
                  Pointer<Uint32> pdwCurrentWidthOrHeight,
                  Pointer<Uint32> pdwMaximumWidthOrHeight),
              int Function(
                  int hMonitor,
                  int stSizeType,
                  Pointer<Uint32> pdwMinimumWidthOrHeight,
                  Pointer<Uint32> pdwCurrentWidthOrHeight,
                  Pointer<Uint32> pdwMaximumWidthOrHeight)>(
          'GetMonitorDisplayAreaSize');
      expect(GetMonitorDisplayAreaSize, isA<Function>());
    });
    test('Can instantiate GetMonitorRedGreenOrBlueDrive', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorRedGreenOrBlueDrive = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor,
                  Int32 dtDriveType,
                  Pointer<Uint32> pdwMinimumDrive,
                  Pointer<Uint32> pdwCurrentDrive,
                  Pointer<Uint32> pdwMaximumDrive),
              int Function(
                  int hMonitor,
                  int dtDriveType,
                  Pointer<Uint32> pdwMinimumDrive,
                  Pointer<Uint32> pdwCurrentDrive,
                  Pointer<Uint32> pdwMaximumDrive)>(
          'GetMonitorRedGreenOrBlueDrive');
      expect(GetMonitorRedGreenOrBlueDrive, isA<Function>());
    });
    test('Can instantiate GetMonitorRedGreenOrBlueGain', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorRedGreenOrBlueGain = dxva2.lookupFunction<
          Int32 Function(
              IntPtr hMonitor,
              Int32 gtGainType,
              Pointer<Uint32> pdwMinimumGain,
              Pointer<Uint32> pdwCurrentGain,
              Pointer<Uint32> pdwMaximumGain),
          int Function(
              int hMonitor,
              int gtGainType,
              Pointer<Uint32> pdwMinimumGain,
              Pointer<Uint32> pdwCurrentGain,
              Pointer<Uint32> pdwMaximumGain)>('GetMonitorRedGreenOrBlueGain');
      expect(GetMonitorRedGreenOrBlueGain, isA<Function>());
    });
    test('Can instantiate GetMonitorTechnologyType', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetMonitorTechnologyType = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor, Pointer<Int32> pdtyDisplayTechnologyType),
              int Function(
                  int hMonitor, Pointer<Int32> pdtyDisplayTechnologyType)>(
          'GetMonitorTechnologyType');
      expect(GetMonitorTechnologyType, isA<Function>());
    });
    test('Can instantiate GetNumberOfPhysicalMonitorsFromHMONITOR', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetNumberOfPhysicalMonitorsFromHMONITOR = dxva2.lookupFunction<
              Int32 Function(
                  IntPtr hMonitor, Pointer<Uint32> pdwNumberOfPhysicalMonitors),
              int Function(
                  int hMonitor, Pointer<Uint32> pdwNumberOfPhysicalMonitors)>(
          'GetNumberOfPhysicalMonitorsFromHMONITOR');
      expect(GetNumberOfPhysicalMonitorsFromHMONITOR, isA<Function>());
    });
    test('Can instantiate GetPhysicalMonitorsFromHMONITOR', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final GetPhysicalMonitorsFromHMONITOR = dxva2.lookupFunction<
              Int32 Function(IntPtr hMonitor, Uint32 dwPhysicalMonitorArraySize,
                  Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray),
              int Function(int hMonitor, int dwPhysicalMonitorArraySize,
                  Pointer<PHYSICAL_MONITOR> pPhysicalMonitorArray)>(
          'GetPhysicalMonitorsFromHMONITOR');
      expect(GetPhysicalMonitorsFromHMONITOR, isA<Function>());
    });
    test('Can instantiate SaveCurrentMonitorSettings', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SaveCurrentMonitorSettings = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor),
          int Function(int hMonitor)>('SaveCurrentMonitorSettings');
      expect(SaveCurrentMonitorSettings, isA<Function>());
    });
    test('Can instantiate SetMonitorBrightness', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorBrightness = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Uint32 dwNewBrightness),
          int Function(
              int hMonitor, int dwNewBrightness)>('SetMonitorBrightness');
      expect(SetMonitorBrightness, isA<Function>());
    });
    test('Can instantiate SetMonitorColorTemperature', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorColorTemperature = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Int32 ctCurrentColorTemperature),
          int Function(int hMonitor,
              int ctCurrentColorTemperature)>('SetMonitorColorTemperature');
      expect(SetMonitorColorTemperature, isA<Function>());
    });
    test('Can instantiate SetMonitorContrast', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorContrast = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Uint32 dwNewContrast),
          int Function(int hMonitor, int dwNewContrast)>('SetMonitorContrast');
      expect(SetMonitorContrast, isA<Function>());
    });
    test('Can instantiate SetMonitorDisplayAreaPosition', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorDisplayAreaPosition = dxva2.lookupFunction<
          Int32 Function(
              IntPtr hMonitor, Int32 ptPositionType, Uint32 dwNewPosition),
          int Function(int hMonitor, int ptPositionType,
              int dwNewPosition)>('SetMonitorDisplayAreaPosition');
      expect(SetMonitorDisplayAreaPosition, isA<Function>());
    });
    test('Can instantiate SetMonitorDisplayAreaSize', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorDisplayAreaSize = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Int32 stSizeType,
              Uint32 dwNewDisplayAreaWidthOrHeight),
          int Function(int hMonitor, int stSizeType,
              int dwNewDisplayAreaWidthOrHeight)>('SetMonitorDisplayAreaSize');
      expect(SetMonitorDisplayAreaSize, isA<Function>());
    });
    test('Can instantiate SetMonitorRedGreenOrBlueDrive', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorRedGreenOrBlueDrive = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Int32 dtDriveType, Uint32 dwNewDrive),
          int Function(int hMonitor, int dtDriveType,
              int dwNewDrive)>('SetMonitorRedGreenOrBlueDrive');
      expect(SetMonitorRedGreenOrBlueDrive, isA<Function>());
    });
    test('Can instantiate SetMonitorRedGreenOrBlueGain', () {
      final dxva2 = DynamicLibrary.open('dxva2.dll');
      final SetMonitorRedGreenOrBlueGain = dxva2.lookupFunction<
          Int32 Function(IntPtr hMonitor, Int32 gtGainType, Uint32 dwNewGain),
          int Function(int hMonitor, int gtGainType,
              int dwNewGain)>('SetMonitorRedGreenOrBlueGain');
      expect(SetMonitorRedGreenOrBlueGain, isA<Function>());
    });
  });

  group('Test oleaut32 functions', () {
    test('Can instantiate DosDateTimeToVariantTime', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final DosDateTimeToVariantTime = oleaut32.lookupFunction<
          Int32 Function(
              Uint16 wDosDate, Uint16 wDosTime, Pointer<Double> pvtime),
          int Function(int wDosDate, int wDosTime,
              Pointer<Double> pvtime)>('DosDateTimeToVariantTime');
      expect(DosDateTimeToVariantTime, isA<Function>());
    });
    test('Can instantiate GetActiveObject', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final GetActiveObject = oleaut32.lookupFunction<
          Int32 Function(Pointer<GUID> rclsid, Pointer pvReserved,
              Pointer<Pointer<COMObject>> ppunk),
          int Function(Pointer<GUID> rclsid, Pointer pvReserved,
              Pointer<Pointer<COMObject>> ppunk)>('GetActiveObject');
      expect(GetActiveObject, isA<Function>());
    });
    test('Can instantiate SysAllocString', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysAllocString = oleaut32.lookupFunction<
          Pointer<Utf16> Function(Pointer<Utf16> psz),
          Pointer<Utf16> Function(Pointer<Utf16> psz)>('SysAllocString');
      expect(SysAllocString, isA<Function>());
    });
    test('Can instantiate SysAllocStringByteLen', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysAllocStringByteLen = oleaut32.lookupFunction<
          Pointer<Utf16> Function(Pointer<Utf8> psz, Uint32 len),
          Pointer<Utf16> Function(
              Pointer<Utf8> psz, int len)>('SysAllocStringByteLen');
      expect(SysAllocStringByteLen, isA<Function>());
    });
    test('Can instantiate SysAllocStringLen', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysAllocStringLen = oleaut32.lookupFunction<
          Pointer<Utf16> Function(Pointer<Utf16> strIn, Uint32 ui),
          Pointer<Utf16> Function(
              Pointer<Utf16> strIn, int ui)>('SysAllocStringLen');
      expect(SysAllocStringLen, isA<Function>());
    });
    test('Can instantiate SysFreeString', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysFreeString = oleaut32.lookupFunction<
          Void Function(Pointer<Utf16> bstrString),
          void Function(Pointer<Utf16> bstrString)>('SysFreeString');
      expect(SysFreeString, isA<Function>());
    });
    test('Can instantiate SysReAllocString', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysReAllocString = oleaut32.lookupFunction<
          Int32 Function(Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz),
          int Function(Pointer<Pointer<Utf16>> pbstr,
              Pointer<Utf16> psz)>('SysReAllocString');
      expect(SysReAllocString, isA<Function>());
    });
    test('Can instantiate SysReAllocStringLen', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysReAllocStringLen = oleaut32.lookupFunction<
          Int32 Function(
              Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz, Uint32 len),
          int Function(Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz,
              int len)>('SysReAllocStringLen');
      expect(SysReAllocStringLen, isA<Function>());
    });
    test('Can instantiate SysReleaseString', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysReleaseString = oleaut32.lookupFunction<
          Void Function(Pointer<Utf16> bstrString),
          void Function(Pointer<Utf16> bstrString)>('SysReleaseString');
      expect(SysReleaseString, isA<Function>());
    });
    test('Can instantiate SysStringByteLen', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysStringByteLen = oleaut32.lookupFunction<
          Uint32 Function(Pointer<Utf16> bstr),
          int Function(Pointer<Utf16> bstr)>('SysStringByteLen');
      expect(SysStringByteLen, isA<Function>());
    });
    test('Can instantiate SysStringLen', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final SysStringLen = oleaut32.lookupFunction<
          Uint32 Function(Pointer<Utf16> pbstr),
          int Function(Pointer<Utf16> pbstr)>('SysStringLen');
      expect(SysStringLen, isA<Function>());
    });
    test('Can instantiate VarBstrCat', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VarBstrCat = oleaut32.lookupFunction<
          Int32 Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
              Pointer<Pointer<Uint16>> pbstrResult),
          int Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
              Pointer<Pointer<Uint16>> pbstrResult)>('VarBstrCat');
      expect(VarBstrCat, isA<Function>());
    });
    test('Can instantiate VarBstrCmp', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VarBstrCmp = oleaut32.lookupFunction<
          Int32 Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
              Uint32 lcid, Uint32 dwFlags),
          int Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
              int lcid, int dwFlags)>('VarBstrCmp');
      expect(VarBstrCmp, isA<Function>());
    });
    test('Can instantiate VariantChangeType', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantChangeType = oleaut32.lookupFunction<
          Int32 Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvarSrc,
              Uint16 wFlags, Uint16 vt),
          int Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvarSrc,
              int wFlags, int vt)>('VariantChangeType');
      expect(VariantChangeType, isA<Function>());
    });
    test('Can instantiate VariantClear', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantClear = oleaut32.lookupFunction<
          Int32 Function(Pointer<VARIANT> pvarg),
          int Function(Pointer<VARIANT> pvarg)>('VariantClear');
      expect(VariantClear, isA<Function>());
    });
    test('Can instantiate VariantCopy', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantCopy = oleaut32.lookupFunction<
          Int32 Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvargSrc),
          int Function(Pointer<VARIANT> pvargDest,
              Pointer<VARIANT> pvargSrc)>('VariantCopy');
      expect(VariantCopy, isA<Function>());
    });
    test('Can instantiate VariantInit', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantInit = oleaut32.lookupFunction<
          Void Function(Pointer<VARIANT> pvarg),
          void Function(Pointer<VARIANT> pvarg)>('VariantInit');
      expect(VariantInit, isA<Function>());
    });
    test('Can instantiate VariantTimeToDosDateTime', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantTimeToDosDateTime = oleaut32.lookupFunction<
          Int32 Function(Double vtime, Pointer<Uint16> pwDosDate,
              Pointer<Uint16> pwDosTime),
          int Function(double vtime, Pointer<Uint16> pwDosDate,
              Pointer<Uint16> pwDosTime)>('VariantTimeToDosDateTime');
      expect(VariantTimeToDosDateTime, isA<Function>());
    });
    test('Can instantiate VariantTimeToSystemTime', () {
      final oleaut32 = DynamicLibrary.open('oleaut32.dll');
      final VariantTimeToSystemTime = oleaut32.lookupFunction<
          Int32 Function(Double vtime, Pointer<SYSTEMTIME> lpSystemTime),
          int Function(double vtime,
              Pointer<SYSTEMTIME> lpSystemTime)>('VariantTimeToSystemTime');
      expect(VariantTimeToSystemTime, isA<Function>());
    });
  });

  group('Test dwmapi functions', () {
    test('Can instantiate DwmEnableBlurBehindWindow', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmEnableBlurBehindWindow = dwmapi.lookupFunction<
              Int32 Function(IntPtr hWnd, Pointer<DWM_BLURBEHIND> pBlurBehind),
              int Function(int hWnd, Pointer<DWM_BLURBEHIND> pBlurBehind)>(
          'DwmEnableBlurBehindWindow');
      expect(DwmEnableBlurBehindWindow, isA<Function>());
    });
    test('Can instantiate DwmEnableMMCSS', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmEnableMMCSS = dwmapi.lookupFunction<
          Int32 Function(Int32 fEnableMMCSS),
          int Function(int fEnableMMCSS)>('DwmEnableMMCSS');
      expect(DwmEnableMMCSS, isA<Function>());
    });
    test('Can instantiate DwmExtendFrameIntoClientArea', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmExtendFrameIntoClientArea = dwmapi.lookupFunction<
          Int32 Function(IntPtr hWnd, Pointer<MARGINS> pMarInset),
          int Function(int hWnd,
              Pointer<MARGINS> pMarInset)>('DwmExtendFrameIntoClientArea');
      expect(DwmExtendFrameIntoClientArea, isA<Function>());
    });
    test('Can instantiate DwmFlush', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmFlush =
          dwmapi.lookupFunction<Int32 Function(), int Function()>('DwmFlush');
      expect(DwmFlush, isA<Function>());
    });
    test('Can instantiate DwmGetColorizationColor', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmGetColorizationColor = dwmapi.lookupFunction<
          Int32 Function(
              Pointer<Uint32> pcrColorization, Pointer<Int32> pfOpaqueBlend),
          int Function(Pointer<Uint32> pcrColorization,
              Pointer<Int32> pfOpaqueBlend)>('DwmGetColorizationColor');
      expect(DwmGetColorizationColor, isA<Function>());
    });
    test('Can instantiate DwmGetTransportAttributes', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmGetTransportAttributes = dwmapi.lookupFunction<
          Int32 Function(Pointer<Int32> pfIsRemoting,
              Pointer<Int32> pfIsConnected, Pointer<Uint32> pDwGeneration),
          int Function(
              Pointer<Int32> pfIsRemoting,
              Pointer<Int32> pfIsConnected,
              Pointer<Uint32> pDwGeneration)>('DwmGetTransportAttributes');
      expect(DwmGetTransportAttributes, isA<Function>());
    });
    test('Can instantiate DwmGetWindowAttribute', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmGetWindowAttribute = dwmapi.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 dwAttribute, Pointer pvAttribute,
              Uint32 cbAttribute),
          int Function(int hwnd, int dwAttribute, Pointer pvAttribute,
              int cbAttribute)>('DwmGetWindowAttribute');
      expect(DwmGetWindowAttribute, isA<Function>());
    });
    test('Can instantiate DwmInvalidateIconicBitmaps', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmInvalidateIconicBitmaps = dwmapi.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('DwmInvalidateIconicBitmaps');
      expect(DwmInvalidateIconicBitmaps, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate DwmRenderGesture', () {
        final dwmapi = DynamicLibrary.open('dwmapi.dll');
        final DwmRenderGesture = dwmapi.lookupFunction<
            Int32 Function(Int32 gt, Uint32 cContacts,
                Pointer<Uint32> pdwPointerID, Pointer<POINT> pPoints),
            int Function(int gt, int cContacts, Pointer<Uint32> pdwPointerID,
                Pointer<POINT> pPoints)>('DwmRenderGesture');
        expect(DwmRenderGesture, isA<Function>());
      });
    }
    test('Can instantiate DwmSetWindowAttribute', () {
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final DwmSetWindowAttribute = dwmapi.lookupFunction<
          Int32 Function(IntPtr hwnd, Int32 dwAttribute, Pointer pvAttribute,
              Uint32 cbAttribute),
          int Function(int hwnd, int dwAttribute, Pointer pvAttribute,
              int cbAttribute)>('DwmSetWindowAttribute');
      expect(DwmSetWindowAttribute, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate DwmShowContact', () {
        final dwmapi = DynamicLibrary.open('dwmapi.dll');
        final DwmShowContact = dwmapi.lookupFunction<
            Int32 Function(Uint32 dwPointerID, Uint32 eShowContact),
            int Function(int dwPointerID, int eShowContact)>('DwmShowContact');
        expect(DwmShowContact, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-core-comm-l1-1-2 functions', () {
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate GetCommPorts', () {
        final api_ms_win_core_comm_l1_1_2 =
            DynamicLibrary.open('api-ms-win-core-comm-l1-1-2.dll');
        final GetCommPorts = api_ms_win_core_comm_l1_1_2.lookupFunction<
            Uint32 Function(Pointer<Uint32> lpPortNumbers,
                Uint32 uPortNumbersCount, Pointer<Uint32> puPortNumbersFound),
            int Function(Pointer<Uint32> lpPortNumbers, int uPortNumbersCount,
                Pointer<Uint32> puPortNumbersFound)>('GetCommPorts');
        expect(GetCommPorts, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-shcore-scaling-l1-1-1 functions', () {
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate GetDpiForMonitor', () {
        final api_ms_win_shcore_scaling_l1_1_1 =
            DynamicLibrary.open('api-ms-win-shcore-scaling-l1-1-1.dll');
        final GetDpiForMonitor =
            api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
                Int32 Function(IntPtr hmonitor, Int32 dpiType,
                    Pointer<Uint32> dpiX, Pointer<Uint32> dpiY),
                int Function(int hmonitor, int dpiType, Pointer<Uint32> dpiX,
                    Pointer<Uint32> dpiY)>('GetDpiForMonitor');
        expect(GetDpiForMonitor, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate GetProcessDpiAwareness', () {
        final api_ms_win_shcore_scaling_l1_1_1 =
            DynamicLibrary.open('api-ms-win-shcore-scaling-l1-1-1.dll');
        final GetProcessDpiAwareness =
            api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
                Int32 Function(IntPtr hprocess, Pointer<Int32> value),
                int Function(int hprocess,
                    Pointer<Int32> value)>('GetProcessDpiAwareness');
        expect(GetProcessDpiAwareness, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate GetScaleFactorForMonitor', () {
        final api_ms_win_shcore_scaling_l1_1_1 =
            DynamicLibrary.open('api-ms-win-shcore-scaling-l1-1-1.dll');
        final GetScaleFactorForMonitor =
            api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
                Int32 Function(IntPtr hMon, Pointer<Int32> pScale),
                int Function(int hMon,
                    Pointer<Int32> pScale)>('GetScaleFactorForMonitor');
        expect(GetScaleFactorForMonitor, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9600) {
      test('Can instantiate SetProcessDpiAwareness', () {
        final api_ms_win_shcore_scaling_l1_1_1 =
            DynamicLibrary.open('api-ms-win-shcore-scaling-l1-1-1.dll');
        final SetProcessDpiAwareness =
            api_ms_win_shcore_scaling_l1_1_1.lookupFunction<
                Int32 Function(Int32 value),
                int Function(int value)>('SetProcessDpiAwareness');
        expect(SetProcessDpiAwareness, isA<Function>());
      });
    }
  });

  group('Test version functions', () {
    test('Can instantiate GetFileVersionInfo', () {
      final version = DynamicLibrary.open('version.dll');
      final GetFileVersionInfo = version.lookupFunction<
          Int32 Function(Pointer<Utf16> lptstrFilename, Uint32 dwHandle,
              Uint32 dwLen, Pointer lpData),
          int Function(Pointer<Utf16> lptstrFilename, int dwHandle, int dwLen,
              Pointer lpData)>('GetFileVersionInfoW');
      expect(GetFileVersionInfo, isA<Function>());
    });
    test('Can instantiate GetFileVersionInfoEx', () {
      final version = DynamicLibrary.open('version.dll');
      final GetFileVersionInfoEx = version.lookupFunction<
          Int32 Function(Uint32 dwFlags, Pointer<Utf16> lpwstrFilename,
              Uint32 dwHandle, Uint32 dwLen, Pointer lpData),
          int Function(int dwFlags, Pointer<Utf16> lpwstrFilename, int dwHandle,
              int dwLen, Pointer lpData)>('GetFileVersionInfoExW');
      expect(GetFileVersionInfoEx, isA<Function>());
    });
    test('Can instantiate GetFileVersionInfoSize', () {
      final version = DynamicLibrary.open('version.dll');
      final GetFileVersionInfoSize = version.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lptstrFilename, Pointer<Uint32> lpdwHandle),
          int Function(Pointer<Utf16> lptstrFilename,
              Pointer<Uint32> lpdwHandle)>('GetFileVersionInfoSizeW');
      expect(GetFileVersionInfoSize, isA<Function>());
    });
    test('Can instantiate GetFileVersionInfoSizeEx', () {
      final version = DynamicLibrary.open('version.dll');
      final GetFileVersionInfoSizeEx = version.lookupFunction<
          Uint32 Function(Uint32 dwFlags, Pointer<Utf16> lpwstrFilename,
              Pointer<Uint32> lpdwHandle),
          int Function(int dwFlags, Pointer<Utf16> lpwstrFilename,
              Pointer<Uint32> lpdwHandle)>('GetFileVersionInfoSizeExW');
      expect(GetFileVersionInfoSizeEx, isA<Function>());
    });
    test('Can instantiate VerFindFile', () {
      final version = DynamicLibrary.open('version.dll');
      final VerFindFile = version.lookupFunction<
          Uint32 Function(
              Uint32 uFlags,
              Pointer<Utf16> szFileName,
              Pointer<Utf16> szWinDir,
              Pointer<Utf16> szAppDir,
              Pointer<Utf16> szCurDir,
              Pointer<Uint32> puCurDirLen,
              Pointer<Utf16> szDestDir,
              Pointer<Uint32> puDestDirLen),
          int Function(
              int uFlags,
              Pointer<Utf16> szFileName,
              Pointer<Utf16> szWinDir,
              Pointer<Utf16> szAppDir,
              Pointer<Utf16> szCurDir,
              Pointer<Uint32> puCurDirLen,
              Pointer<Utf16> szDestDir,
              Pointer<Uint32> puDestDirLen)>('VerFindFileW');
      expect(VerFindFile, isA<Function>());
    });
    test('Can instantiate VerInstallFile', () {
      final version = DynamicLibrary.open('version.dll');
      final VerInstallFile = version.lookupFunction<
          Uint32 Function(
              Uint32 uFlags,
              Pointer<Utf16> szSrcFileName,
              Pointer<Utf16> szDestFileName,
              Pointer<Utf16> szSrcDir,
              Pointer<Utf16> szDestDir,
              Pointer<Utf16> szCurDir,
              Pointer<Utf16> szTmpFile,
              Pointer<Uint32> puTmpFileLen),
          int Function(
              int uFlags,
              Pointer<Utf16> szSrcFileName,
              Pointer<Utf16> szDestFileName,
              Pointer<Utf16> szSrcDir,
              Pointer<Utf16> szDestDir,
              Pointer<Utf16> szCurDir,
              Pointer<Utf16> szTmpFile,
              Pointer<Uint32> puTmpFileLen)>('VerInstallFileW');
      expect(VerInstallFile, isA<Function>());
    });
    test('Can instantiate VerQueryValue', () {
      final version = DynamicLibrary.open('version.dll');
      final VerQueryValue = version.lookupFunction<
          Int32 Function(Pointer pBlock, Pointer<Utf16> lpSubBlock,
              Pointer<Pointer> lplpBuffer, Pointer<Uint32> puLen),
          int Function(
              Pointer pBlock,
              Pointer<Utf16> lpSubBlock,
              Pointer<Pointer> lplpBuffer,
              Pointer<Uint32> puLen)>('VerQueryValueW');
      expect(VerQueryValue, isA<Function>());
    });
  });

  group('Test api-ms-win-core-sysinfo-l1-2-3 functions', () {
    if (windowsBuildNumber >= 10240) {
      test('Can instantiate GetIntegratedDisplaySize', () {
        final api_ms_win_core_sysinfo_l1_2_3 =
            DynamicLibrary.open('api-ms-win-core-sysinfo-l1-2-3.dll');
        final GetIntegratedDisplaySize =
            api_ms_win_core_sysinfo_l1_2_3.lookupFunction<
                Int32 Function(Pointer<Double> sizeInInches),
                int Function(
                    Pointer<Double> sizeInInches)>('GetIntegratedDisplaySize');
        expect(GetIntegratedDisplaySize, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-core-apiquery-l2-1-0 functions', () {
    if (windowsBuildNumber >= 10240) {
      test('Can instantiate IsApiSetImplemented', () {
        final api_ms_win_core_apiquery_l2_1_0 =
            DynamicLibrary.open('api-ms-win-core-apiquery-l2-1-0.dll');
        final IsApiSetImplemented =
            api_ms_win_core_apiquery_l2_1_0.lookupFunction<
                Int32 Function(Pointer<Utf8> Contract),
                int Function(Pointer<Utf8> Contract)>('IsApiSetImplemented');
        expect(IsApiSetImplemented, isA<Function>());
      });
    }
  });

  group('Test magnification functions', () {
    test('Can instantiate MagGetColorEffect', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagGetColorEffect = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<MAGCOLOREFFECT> pEffect),
          int Function(
              int hwnd, Pointer<MAGCOLOREFFECT> pEffect)>('MagGetColorEffect');
      expect(MagGetColorEffect, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagGetFullscreenColorEffect', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagGetFullscreenColorEffect = magnification.lookupFunction<
                Int32 Function(Pointer<MAGCOLOREFFECT> pEffect),
                int Function(Pointer<MAGCOLOREFFECT> pEffect)>(
            'MagGetFullscreenColorEffect');
        expect(MagGetFullscreenColorEffect, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagGetFullscreenTransform', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagGetFullscreenTransform = magnification.lookupFunction<
            Int32 Function(Pointer<Float> pMagLevel, Pointer<Int32> pxOffset,
                Pointer<Int32> pyOffset),
            int Function(Pointer<Float> pMagLevel, Pointer<Int32> pxOffset,
                Pointer<Int32> pyOffset)>('MagGetFullscreenTransform');
        expect(MagGetFullscreenTransform, isA<Function>());
      });
    }
    test('Can instantiate MagGetImageScalingCallback', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagGetImageScalingCallback = magnification.lookupFunction<
          Pointer<NativeFunction<MagImageScalingCallback>> Function(
              IntPtr hwnd),
          Pointer<NativeFunction<MagImageScalingCallback>> Function(
              int hwnd)>('MagGetImageScalingCallback');
      expect(MagGetImageScalingCallback, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagGetInputTransform', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagGetInputTransform = magnification.lookupFunction<
            Int32 Function(Pointer<Int32> pfEnabled, Pointer<RECT> pRectSource,
                Pointer<RECT> pRectDest),
            int Function(Pointer<Int32> pfEnabled, Pointer<RECT> pRectSource,
                Pointer<RECT> pRectDest)>('MagGetInputTransform');
        expect(MagGetInputTransform, isA<Function>());
      });
    }
    test('Can instantiate MagGetWindowFilterList', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagGetWindowFilterList = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<Uint32> pdwFilterMode,
              Int32 count, Pointer<IntPtr> pHWND),
          int Function(int hwnd, Pointer<Uint32> pdwFilterMode, int count,
              Pointer<IntPtr> pHWND)>('MagGetWindowFilterList');
      expect(MagGetWindowFilterList, isA<Function>());
    });
    test('Can instantiate MagGetWindowSource', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagGetWindowSource = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<RECT> pRect),
          int Function(int hwnd, Pointer<RECT> pRect)>('MagGetWindowSource');
      expect(MagGetWindowSource, isA<Function>());
    });
    test('Can instantiate MagGetWindowTransform', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagGetWindowTransform = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<MAGTRANSFORM> pTransform),
          int Function(int hwnd,
              Pointer<MAGTRANSFORM> pTransform)>('MagGetWindowTransform');
      expect(MagGetWindowTransform, isA<Function>());
    });
    test('Can instantiate MagInitialize', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagInitialize = magnification
          .lookupFunction<Int32 Function(), int Function()>('MagInitialize');
      expect(MagInitialize, isA<Function>());
    });
    test('Can instantiate MagSetColorEffect', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagSetColorEffect = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<MAGCOLOREFFECT> pEffect),
          int Function(
              int hwnd, Pointer<MAGCOLOREFFECT> pEffect)>('MagSetColorEffect');
      expect(MagSetColorEffect, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagSetFullscreenColorEffect', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagSetFullscreenColorEffect = magnification.lookupFunction<
                Int32 Function(Pointer<MAGCOLOREFFECT> pEffect),
                int Function(Pointer<MAGCOLOREFFECT> pEffect)>(
            'MagSetFullscreenColorEffect');
        expect(MagSetFullscreenColorEffect, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagSetFullscreenTransform', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagSetFullscreenTransform = magnification.lookupFunction<
            Int32 Function(Float magLevel, Int32 xOffset, Int32 yOffset),
            int Function(double magLevel, int xOffset,
                int yOffset)>('MagSetFullscreenTransform');
        expect(MagSetFullscreenTransform, isA<Function>());
      });
    }
    test('Can instantiate MagSetImageScalingCallback', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagSetImageScalingCallback = magnification.lookupFunction<
              Int32 Function(IntPtr hwnd,
                  Pointer<NativeFunction<MagImageScalingCallback>> callback),
              int Function(int hwnd,
                  Pointer<NativeFunction<MagImageScalingCallback>> callback)>(
          'MagSetImageScalingCallback');
      expect(MagSetImageScalingCallback, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagSetInputTransform', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagSetInputTransform = magnification.lookupFunction<
            Int32 Function(Int32 fEnabled, Pointer<RECT> pRectSource,
                Pointer<RECT> pRectDest),
            int Function(int fEnabled, Pointer<RECT> pRectSource,
                Pointer<RECT> pRectDest)>('MagSetInputTransform');
        expect(MagSetInputTransform, isA<Function>());
      });
    }
    test('Can instantiate MagSetWindowFilterList', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagSetWindowFilterList = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Uint32 dwFilterMode, Int32 count,
              Pointer<IntPtr> pHWND),
          int Function(int hwnd, int dwFilterMode, int count,
              Pointer<IntPtr> pHWND)>('MagSetWindowFilterList');
      expect(MagSetWindowFilterList, isA<Function>());
    });
    test('Can instantiate MagSetWindowSource', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagSetWindowSource = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, RECT rect),
          int Function(int hwnd, RECT rect)>('MagSetWindowSource');
      expect(MagSetWindowSource, isA<Function>());
    });
    test('Can instantiate MagSetWindowTransform', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagSetWindowTransform = magnification.lookupFunction<
          Int32 Function(IntPtr hwnd, Pointer<MAGTRANSFORM> pTransform),
          int Function(int hwnd,
              Pointer<MAGTRANSFORM> pTransform)>('MagSetWindowTransform');
      expect(MagSetWindowTransform, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate MagShowSystemCursor', () {
        final magnification = DynamicLibrary.open('magnification.dll');
        final MagShowSystemCursor = magnification.lookupFunction<
            Int32 Function(Int32 fShowCursor),
            int Function(int fShowCursor)>('MagShowSystemCursor');
        expect(MagShowSystemCursor, isA<Function>());
      });
    }
    test('Can instantiate MagUninitialize', () {
      final magnification = DynamicLibrary.open('magnification.dll');
      final MagUninitialize = magnification
          .lookupFunction<Int32 Function(), int Function()>('MagUninitialize');
      expect(MagUninitialize, isA<Function>());
    });
  });

  group('Test winmm functions', () {
    test('Can instantiate mciGetDeviceID', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final mciGetDeviceID = winmm.lookupFunction<
          Uint32 Function(Pointer<Utf16> pszDevice),
          int Function(Pointer<Utf16> pszDevice)>('mciGetDeviceIDW');
      expect(mciGetDeviceID, isA<Function>());
    });
    test('Can instantiate mciGetDeviceIDFromElementID', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final mciGetDeviceIDFromElementID = winmm.lookupFunction<
          Uint32 Function(Uint32 dwElementID, Pointer<Utf16> lpstrType),
          int Function(int dwElementID,
              Pointer<Utf16> lpstrType)>('mciGetDeviceIDFromElementIDW');
      expect(mciGetDeviceIDFromElementID, isA<Function>());
    });
    test('Can instantiate mciGetErrorString', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final mciGetErrorString = winmm.lookupFunction<
          Int32 Function(Uint32 mcierr, Pointer<Utf16> pszText, Uint32 cchText),
          int Function(int mcierr, Pointer<Utf16> pszText,
              int cchText)>('mciGetErrorStringW');
      expect(mciGetErrorString, isA<Function>());
    });
    test('Can instantiate mciSendCommand', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final mciSendCommand = winmm.lookupFunction<
          Uint32 Function(
              Uint32 mciId, Uint32 uMsg, IntPtr dwParam1, IntPtr dwParam2),
          int Function(int mciId, int uMsg, int dwParam1,
              int dwParam2)>('mciSendCommandW');
      expect(mciSendCommand, isA<Function>());
    });
    test('Can instantiate mciSendString', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final mciSendString = winmm.lookupFunction<
          Uint32 Function(
              Pointer<Utf16> lpstrCommand,
              Pointer<Utf16> lpstrReturnString,
              Uint32 uReturnLength,
              IntPtr hwndCallback),
          int Function(
              Pointer<Utf16> lpstrCommand,
              Pointer<Utf16> lpstrReturnString,
              int uReturnLength,
              int hwndCallback)>('mciSendStringW');
      expect(mciSendString, isA<Function>());
    });
    test('Can instantiate midiConnect', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiConnect = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, IntPtr hmo, Pointer pReserved),
          int Function(int hmi, int hmo, Pointer pReserved)>('midiConnect');
      expect(midiConnect, isA<Function>());
    });
    test('Can instantiate midiDisconnect', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiDisconnect = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, IntPtr hmo, Pointer pReserved),
          int Function(int hmi, int hmo, Pointer pReserved)>('midiDisconnect');
      expect(midiDisconnect, isA<Function>());
    });
    test('Can instantiate midiInClose', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInClose = winmm.lookupFunction<Uint32 Function(IntPtr hmi),
          int Function(int hmi)>('midiInClose');
      expect(midiInClose, isA<Function>());
    });
    test('Can instantiate midiInGetDevCaps', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInGetDevCaps = winmm.lookupFunction<
          Uint32 Function(
              IntPtr uDeviceID, Pointer<MIDIINCAPS> pmic, Uint32 cbmic),
          int Function(int uDeviceID, Pointer<MIDIINCAPS> pmic,
              int cbmic)>('midiInGetDevCapsW');
      expect(midiInGetDevCaps, isA<Function>());
    });
    test('Can instantiate midiInGetErrorText', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInGetErrorText = winmm.lookupFunction<
          Uint32 Function(
              Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
          int Function(int mmrError, Pointer<Utf16> pszText,
              int cchText)>('midiInGetErrorTextW');
      expect(midiInGetErrorText, isA<Function>());
    });
    test('Can instantiate midiInGetID', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInGetID = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, Pointer<Uint32> puDeviceID),
          int Function(int hmi, Pointer<Uint32> puDeviceID)>('midiInGetID');
      expect(midiInGetID, isA<Function>());
    });
    test('Can instantiate midiInGetNumDevs', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInGetNumDevs =
          winmm.lookupFunction<Uint32 Function(), int Function()>(
              'midiInGetNumDevs');
      expect(midiInGetNumDevs, isA<Function>());
    });
    test('Can instantiate midiInMessage', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInMessage = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
          int Function(int hmi, int uMsg, int dw1, int dw2)>('midiInMessage');
      expect(midiInMessage, isA<Function>());
    });
    test('Can instantiate midiInOpen', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInOpen = winmm.lookupFunction<
          Uint32 Function(Pointer<IntPtr> phmi, Uint32 uDeviceID,
              IntPtr dwCallback, IntPtr dwInstance, Uint32 fdwOpen),
          int Function(Pointer<IntPtr> phmi, int uDeviceID, int dwCallback,
              int dwInstance, int fdwOpen)>('midiInOpen');
      expect(midiInOpen, isA<Function>());
    });
    test('Can instantiate midiInPrepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInPrepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, Pointer<MIDIHDR> pmh, Uint32 cbmh),
          int Function(
              int hmi, Pointer<MIDIHDR> pmh, int cbmh)>('midiInPrepareHeader');
      expect(midiInPrepareHeader, isA<Function>());
    });
    test('Can instantiate midiInReset', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInReset = winmm.lookupFunction<Uint32 Function(IntPtr hmi),
          int Function(int hmi)>('midiInReset');
      expect(midiInReset, isA<Function>());
    });
    test('Can instantiate midiInStart', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInStart = winmm.lookupFunction<Uint32 Function(IntPtr hmi),
          int Function(int hmi)>('midiInStart');
      expect(midiInStart, isA<Function>());
    });
    test('Can instantiate midiInStop', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInStop = winmm.lookupFunction<Uint32 Function(IntPtr hmi),
          int Function(int hmi)>('midiInStop');
      expect(midiInStop, isA<Function>());
    });
    test('Can instantiate midiInUnprepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiInUnprepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hmi, Pointer<MIDIHDR> pmh, Uint32 cbmh),
          int Function(int hmi, Pointer<MIDIHDR> pmh,
              int cbmh)>('midiInUnprepareHeader');
      expect(midiInUnprepareHeader, isA<Function>());
    });
    test('Can instantiate midiOutCacheDrumPatches', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutCacheDrumPatches = winmm.lookupFunction<
          Uint32 Function(
              IntPtr hmo, Uint32 uPatch, Pointer<Uint16> pwkya, Uint32 fuCache),
          int Function(int hmo, int uPatch, Pointer<Uint16> pwkya,
              int fuCache)>('midiOutCacheDrumPatches');
      expect(midiOutCacheDrumPatches, isA<Function>());
    });
    test('Can instantiate midiOutCachePatches', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutCachePatches = winmm.lookupFunction<
          Uint32 Function(
              IntPtr hmo, Uint32 uBank, Pointer<Uint16> pwpa, Uint32 fuCache),
          int Function(int hmo, int uBank, Pointer<Uint16> pwpa,
              int fuCache)>('midiOutCachePatches');
      expect(midiOutCachePatches, isA<Function>());
    });
    test('Can instantiate midiOutClose', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutClose = winmm.lookupFunction<Uint32 Function(IntPtr hmo),
          int Function(int hmo)>('midiOutClose');
      expect(midiOutClose, isA<Function>());
    });
    test('Can instantiate midiOutGetDevCaps', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutGetDevCaps = winmm.lookupFunction<
          Uint32 Function(
              IntPtr uDeviceID, Pointer<MIDIOUTCAPS> pmoc, Uint32 cbmoc),
          int Function(int uDeviceID, Pointer<MIDIOUTCAPS> pmoc,
              int cbmoc)>('midiOutGetDevCapsW');
      expect(midiOutGetDevCaps, isA<Function>());
    });
    test('Can instantiate midiOutGetErrorText', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutGetErrorText = winmm.lookupFunction<
          Uint32 Function(
              Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
          int Function(int mmrError, Pointer<Utf16> pszText,
              int cchText)>('midiOutGetErrorTextW');
      expect(midiOutGetErrorText, isA<Function>());
    });
    test('Can instantiate midiOutGetID', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutGetID = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Pointer<Uint32> puDeviceID),
          int Function(int hmo, Pointer<Uint32> puDeviceID)>('midiOutGetID');
      expect(midiOutGetID, isA<Function>());
    });
    test('Can instantiate midiOutGetNumDevs', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutGetNumDevs =
          winmm.lookupFunction<Uint32 Function(), int Function()>(
              'midiOutGetNumDevs');
      expect(midiOutGetNumDevs, isA<Function>());
    });
    test('Can instantiate midiOutGetVolume', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutGetVolume = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Pointer<Uint32> pdwVolume),
          int Function(int hmo, Pointer<Uint32> pdwVolume)>('midiOutGetVolume');
      expect(midiOutGetVolume, isA<Function>());
    });
    test('Can instantiate midiOutLongMsg', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutLongMsg = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
          int Function(
              int hmo, Pointer<MIDIHDR> pmh, int cbmh)>('midiOutLongMsg');
      expect(midiOutLongMsg, isA<Function>());
    });
    test('Can instantiate midiOutMessage', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutMessage = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
          int Function(int hmo, int uMsg, int dw1, int dw2)>('midiOutMessage');
      expect(midiOutMessage, isA<Function>());
    });
    test('Can instantiate midiOutOpen', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutOpen = winmm.lookupFunction<
          Uint32 Function(Pointer<IntPtr> phmo, Uint32 uDeviceID,
              IntPtr dwCallback, IntPtr dwInstance, Uint32 fdwOpen),
          int Function(Pointer<IntPtr> phmo, int uDeviceID, int dwCallback,
              int dwInstance, int fdwOpen)>('midiOutOpen');
      expect(midiOutOpen, isA<Function>());
    });
    test('Can instantiate midiOutPrepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutPrepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
          int Function(
              int hmo, Pointer<MIDIHDR> pmh, int cbmh)>('midiOutPrepareHeader');
      expect(midiOutPrepareHeader, isA<Function>());
    });
    test('Can instantiate midiOutReset', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutReset = winmm.lookupFunction<Uint32 Function(IntPtr hmo),
          int Function(int hmo)>('midiOutReset');
      expect(midiOutReset, isA<Function>());
    });
    test('Can instantiate midiOutSetVolume', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutSetVolume = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Uint32 dwVolume),
          int Function(int hmo, int dwVolume)>('midiOutSetVolume');
      expect(midiOutSetVolume, isA<Function>());
    });
    test('Can instantiate midiOutShortMsg', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutShortMsg = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Uint32 dwMsg),
          int Function(int hmo, int dwMsg)>('midiOutShortMsg');
      expect(midiOutShortMsg, isA<Function>());
    });
    test('Can instantiate midiOutUnprepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final midiOutUnprepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
          int Function(int hmo, Pointer<MIDIHDR> pmh,
              int cbmh)>('midiOutUnprepareHeader');
      expect(midiOutUnprepareHeader, isA<Function>());
    });
    test('Can instantiate PlaySound', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final PlaySound = winmm.lookupFunction<
          Int32 Function(Pointer<Utf16> pszSound, IntPtr hmod, Uint32 fdwSound),
          int Function(
              Pointer<Utf16> pszSound, int hmod, int fdwSound)>('PlaySoundW');
      expect(PlaySound, isA<Function>());
    });
    test('Can instantiate waveOutClose', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutClose = winmm.lookupFunction<Uint32 Function(IntPtr hwo),
          int Function(int hwo)>('waveOutClose');
      expect(waveOutClose, isA<Function>());
    });
    test('Can instantiate waveOutGetDevCaps', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetDevCaps = winmm.lookupFunction<
          Uint32 Function(
              IntPtr uDeviceID, Pointer<WAVEOUTCAPS> pwoc, Uint32 cbwoc),
          int Function(int uDeviceID, Pointer<WAVEOUTCAPS> pwoc,
              int cbwoc)>('waveOutGetDevCapsW');
      expect(waveOutGetDevCaps, isA<Function>());
    });
    test('Can instantiate waveOutGetErrorText', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetErrorText = winmm.lookupFunction<
          Uint32 Function(
              Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
          int Function(int mmrError, Pointer<Utf16> pszText,
              int cchText)>('waveOutGetErrorTextW');
      expect(waveOutGetErrorText, isA<Function>());
    });
    test('Can instantiate waveOutGetID', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetID = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<Uint32> puDeviceID),
          int Function(int hwo, Pointer<Uint32> puDeviceID)>('waveOutGetID');
      expect(waveOutGetID, isA<Function>());
    });
    test('Can instantiate waveOutGetNumDevs', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetNumDevs =
          winmm.lookupFunction<Uint32 Function(), int Function()>(
              'waveOutGetNumDevs');
      expect(waveOutGetNumDevs, isA<Function>());
    });
    test('Can instantiate waveOutGetPitch', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetPitch = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwPitch),
          int Function(int hwo, Pointer<Uint32> pdwPitch)>('waveOutGetPitch');
      expect(waveOutGetPitch, isA<Function>());
    });
    test('Can instantiate waveOutGetPlaybackRate', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetPlaybackRate = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwRate),
          int Function(
              int hwo, Pointer<Uint32> pdwRate)>('waveOutGetPlaybackRate');
      expect(waveOutGetPlaybackRate, isA<Function>());
    });
    test('Can instantiate waveOutGetPosition', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetPosition = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<MMTIME> pmmt, Uint32 cbmmt),
          int Function(
              int hwo, Pointer<MMTIME> pmmt, int cbmmt)>('waveOutGetPosition');
      expect(waveOutGetPosition, isA<Function>());
    });
    test('Can instantiate waveOutGetVolume', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutGetVolume = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwVolume),
          int Function(int hwo, Pointer<Uint32> pdwVolume)>('waveOutGetVolume');
      expect(waveOutGetVolume, isA<Function>());
    });
    test('Can instantiate waveOutMessage', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutMessage = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
          int Function(int hwo, int uMsg, int dw1, int dw2)>('waveOutMessage');
      expect(waveOutMessage, isA<Function>());
    });
    test('Can instantiate waveOutOpen', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutOpen = winmm.lookupFunction<
          Uint32 Function(
              Pointer<IntPtr> phwo,
              Uint32 uDeviceID,
              Pointer<WAVEFORMATEX> pwfx,
              IntPtr dwCallback,
              IntPtr dwInstance,
              Uint32 fdwOpen),
          int Function(
              Pointer<IntPtr> phwo,
              int uDeviceID,
              Pointer<WAVEFORMATEX> pwfx,
              int dwCallback,
              int dwInstance,
              int fdwOpen)>('waveOutOpen');
      expect(waveOutOpen, isA<Function>());
    });
    test('Can instantiate waveOutPause', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutPause = winmm.lookupFunction<Uint32 Function(IntPtr hwo),
          int Function(int hwo)>('waveOutPause');
      expect(waveOutPause, isA<Function>());
    });
    test('Can instantiate waveOutPrepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutPrepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
          int Function(
              int hwo, Pointer<WAVEHDR> pwh, int cbwh)>('waveOutPrepareHeader');
      expect(waveOutPrepareHeader, isA<Function>());
    });
    test('Can instantiate waveOutReset', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutReset = winmm.lookupFunction<Uint32 Function(IntPtr hwo),
          int Function(int hwo)>('waveOutReset');
      expect(waveOutReset, isA<Function>());
    });
    test('Can instantiate waveOutRestart', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutRestart = winmm.lookupFunction<Uint32 Function(IntPtr hwo),
          int Function(int hwo)>('waveOutRestart');
      expect(waveOutRestart, isA<Function>());
    });
    test('Can instantiate waveOutSetPitch', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutSetPitch = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Uint32 dwPitch),
          int Function(int hwo, int dwPitch)>('waveOutSetPitch');
      expect(waveOutSetPitch, isA<Function>());
    });
    test('Can instantiate waveOutSetPlaybackRate', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutSetPlaybackRate = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Uint32 dwRate),
          int Function(int hwo, int dwRate)>('waveOutSetPlaybackRate');
      expect(waveOutSetPlaybackRate, isA<Function>());
    });
    test('Can instantiate waveOutSetVolume', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutSetVolume = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Uint32 dwVolume),
          int Function(int hwo, int dwVolume)>('waveOutSetVolume');
      expect(waveOutSetVolume, isA<Function>());
    });
    test('Can instantiate waveOutUnprepareHeader', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutUnprepareHeader = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
          int Function(int hwo, Pointer<WAVEHDR> pwh,
              int cbwh)>('waveOutUnprepareHeader');
      expect(waveOutUnprepareHeader, isA<Function>());
    });
    test('Can instantiate waveOutWrite', () {
      final winmm = DynamicLibrary.open('winmm.dll');
      final waveOutWrite = winmm.lookupFunction<
          Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
          int Function(
              int hwo, Pointer<WAVEHDR> pwh, int cbwh)>('waveOutWrite');
      expect(waveOutWrite, isA<Function>());
    });
  });

  group('Test rometadata functions', () {
    if (windowsBuildNumber >= 10586) {
      test('Can instantiate MetaDataGetDispenser', () {
        final rometadata = DynamicLibrary.open('rometadata.dll');
        final MetaDataGetDispenser = rometadata.lookupFunction<
            Int32 Function(
                Pointer<GUID> rclsid, Pointer<GUID> riid, Pointer<Pointer> ppv),
            int Function(Pointer<GUID> rclsid, Pointer<GUID> riid,
                Pointer<Pointer> ppv)>('MetaDataGetDispenser');
        expect(MetaDataGetDispenser, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-core-comm-l1-1-1 functions', () {
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate OpenCommPort', () {
        final api_ms_win_core_comm_l1_1_1 =
            DynamicLibrary.open('api-ms-win-core-comm-l1-1-1.dll');
        final OpenCommPort = api_ms_win_core_comm_l1_1_1.lookupFunction<
            IntPtr Function(Uint32 uPortNumber, Uint32 dwDesiredAccess,
                Uint32 dwFlagsAndAttributes),
            int Function(int uPortNumber, int dwDesiredAccess,
                int dwFlagsAndAttributes)>('OpenCommPort');
        expect(OpenCommPort, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-core-winrt-l1-1-0 functions', () {
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RoActivateInstance', () {
        final api_ms_win_core_winrt_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
        final RoActivateInstance = api_ms_win_core_winrt_l1_1_0.lookupFunction<
            Int32 Function(IntPtr activatableClassId,
                Pointer<Pointer<COMObject>> instance),
            int Function(int activatableClassId,
                Pointer<Pointer<COMObject>> instance)>('RoActivateInstance');
        expect(RoActivateInstance, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RoGetActivationFactory', () {
        final api_ms_win_core_winrt_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
        final RoGetActivationFactory =
            api_ms_win_core_winrt_l1_1_0.lookupFunction<
                Int32 Function(IntPtr activatableClassId, Pointer<GUID> iid,
                    Pointer<Pointer> factory),
                int Function(int activatableClassId, Pointer<GUID> iid,
                    Pointer<Pointer> factory)>('RoGetActivationFactory');
        expect(RoGetActivationFactory, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RoGetApartmentIdentifier', () {
        final api_ms_win_core_winrt_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
        final RoGetApartmentIdentifier =
            api_ms_win_core_winrt_l1_1_0.lookupFunction<
                    Int32 Function(Pointer<Uint64> apartmentIdentifier),
                    int Function(Pointer<Uint64> apartmentIdentifier)>(
                'RoGetApartmentIdentifier');
        expect(RoGetApartmentIdentifier, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RoInitialize', () {
        final api_ms_win_core_winrt_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
        final RoInitialize = api_ms_win_core_winrt_l1_1_0.lookupFunction<
            Int32 Function(Int32 initType),
            int Function(int initType)>('RoInitialize');
        expect(RoInitialize, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate RoUninitialize', () {
        final api_ms_win_core_winrt_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
        final RoUninitialize = api_ms_win_core_winrt_l1_1_0
            .lookupFunction<Void Function(), void Function()>('RoUninitialize');
        expect(RoUninitialize, isA<Function>());
      });
    }
  });

  group('Test winscard functions', () {
    test('Can instantiate SCardAccessStartedEvent', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardAccessStartedEvent =
          winscard.lookupFunction<IntPtr Function(), int Function()>(
              'SCardAccessStartedEvent');
      expect(SCardAccessStartedEvent, isA<Function>());
    });
    test('Can instantiate SCardAddReaderToGroup', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardAddReaderToGroup = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szGroupName),
          int Function(int hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szGroupName)>('SCardAddReaderToGroupW');
      expect(SCardAddReaderToGroup, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SCardAudit', () {
        final winscard = DynamicLibrary.open('winscard.dll');
        final SCardAudit = winscard.lookupFunction<
            Int32 Function(IntPtr hContext, Uint32 dwEvent),
            int Function(int hContext, int dwEvent)>('SCardAudit');
        expect(SCardAudit, isA<Function>());
      });
    }
    test('Can instantiate SCardBeginTransaction', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardBeginTransaction = winscard.lookupFunction<
          Int32 Function(IntPtr hCard),
          int Function(int hCard)>('SCardBeginTransaction');
      expect(SCardBeginTransaction, isA<Function>());
    });
    test('Can instantiate SCardCancel', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardCancel = winscard.lookupFunction<
          Int32 Function(IntPtr hContext),
          int Function(int hContext)>('SCardCancel');
      expect(SCardCancel, isA<Function>());
    });
    test('Can instantiate SCardConnect', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardConnect = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<Utf16> szReader,
              Uint32 dwShareMode,
              Uint32 dwPreferredProtocols,
              Pointer<IntPtr> phCard,
              Pointer<Uint32> pdwActiveProtocol),
          int Function(
              int hContext,
              Pointer<Utf16> szReader,
              int dwShareMode,
              int dwPreferredProtocols,
              Pointer<IntPtr> phCard,
              Pointer<Uint32> pdwActiveProtocol)>('SCardConnectW');
      expect(SCardConnect, isA<Function>());
    });
    test('Can instantiate SCardControl', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardControl = winscard.lookupFunction<
          Int32 Function(
              IntPtr hCard,
              Uint32 dwControlCode,
              Pointer lpInBuffer,
              Uint32 cbInBufferSize,
              Pointer lpOutBuffer,
              Uint32 cbOutBufferSize,
              Pointer<Uint32> lpBytesReturned),
          int Function(
              int hCard,
              int dwControlCode,
              Pointer lpInBuffer,
              int cbInBufferSize,
              Pointer lpOutBuffer,
              int cbOutBufferSize,
              Pointer<Uint32> lpBytesReturned)>('SCardControl');
      expect(SCardControl, isA<Function>());
    });
    test('Can instantiate SCardDisconnect', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardDisconnect = winscard.lookupFunction<
          Int32 Function(IntPtr hCard, Uint32 dwDisposition),
          int Function(int hCard, int dwDisposition)>('SCardDisconnect');
      expect(SCardDisconnect, isA<Function>());
    });
    test('Can instantiate SCardEndTransaction', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardEndTransaction = winscard.lookupFunction<
          Int32 Function(IntPtr hCard, Uint32 dwDisposition),
          int Function(int hCard, int dwDisposition)>('SCardEndTransaction');
      expect(SCardEndTransaction, isA<Function>());
    });
    test('Can instantiate SCardEstablishContext', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardEstablishContext = winscard.lookupFunction<
          Int32 Function(Uint32 dwScope, Pointer pvReserved1,
              Pointer pvReserved2, Pointer<IntPtr> phContext),
          int Function(int dwScope, Pointer pvReserved1, Pointer pvReserved2,
              Pointer<IntPtr> phContext)>('SCardEstablishContext');
      expect(SCardEstablishContext, isA<Function>());
    });
    test('Can instantiate SCardForgetCardType', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardForgetCardType = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szCardName),
          int Function(
              int hContext, Pointer<Utf16> szCardName)>('SCardForgetCardTypeW');
      expect(SCardForgetCardType, isA<Function>());
    });
    test('Can instantiate SCardForgetReader', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardForgetReader = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName),
          int Function(
              int hContext, Pointer<Utf16> szReaderName)>('SCardForgetReaderW');
      expect(SCardForgetReader, isA<Function>());
    });
    test('Can instantiate SCardForgetReaderGroup', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardForgetReaderGroup = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szGroupName),
          int Function(int hContext,
              Pointer<Utf16> szGroupName)>('SCardForgetReaderGroupW');
      expect(SCardForgetReaderGroup, isA<Function>());
    });
    test('Can instantiate SCardFreeMemory', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardFreeMemory = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer pvMem),
          int Function(int hContext, Pointer pvMem)>('SCardFreeMemory');
      expect(SCardFreeMemory, isA<Function>());
    });
    test('Can instantiate SCardGetAttrib', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardGetAttrib = winscard.lookupFunction<
          Int32 Function(IntPtr hCard, Uint32 dwAttrId, Pointer<Uint8> pbAttr,
              Pointer<Uint32> pcbAttrLen),
          int Function(int hCard, int dwAttrId, Pointer<Uint8> pbAttr,
              Pointer<Uint32> pcbAttrLen)>('SCardGetAttrib');
      expect(SCardGetAttrib, isA<Function>());
    });
    test('Can instantiate SCardGetCardTypeProviderName', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardGetCardTypeProviderName = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<Utf16> szCardName,
              Uint32 dwProviderId,
              Pointer<Utf16> szProvider,
              Pointer<Uint32> pcchProvider),
          int Function(
              int hContext,
              Pointer<Utf16> szCardName,
              int dwProviderId,
              Pointer<Utf16> szProvider,
              Pointer<Uint32> pcchProvider)>('SCardGetCardTypeProviderNameW');
      expect(SCardGetCardTypeProviderName, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SCardGetDeviceTypeId', () {
        final winscard = DynamicLibrary.open('winscard.dll');
        final SCardGetDeviceTypeId = winscard.lookupFunction<
            Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName,
                Pointer<Uint32> pdwDeviceTypeId),
            int Function(int hContext, Pointer<Utf16> szReaderName,
                Pointer<Uint32> pdwDeviceTypeId)>('SCardGetDeviceTypeIdW');
        expect(SCardGetDeviceTypeId, isA<Function>());
      });
    }
    test('Can instantiate SCardGetProviderId', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardGetProviderId = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szCard,
              Pointer<GUID> pguidProviderId),
          int Function(int hContext, Pointer<Utf16> szCard,
              Pointer<GUID> pguidProviderId)>('SCardGetProviderIdW');
      expect(SCardGetProviderId, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SCardGetReaderDeviceInstanceId', () {
        final winscard = DynamicLibrary.open('winscard.dll');
        final SCardGetReaderDeviceInstanceId = winscard.lookupFunction<
                Int32 Function(
                    IntPtr hContext,
                    Pointer<Utf16> szReaderName,
                    Pointer<Utf16> szDeviceInstanceId,
                    Pointer<Uint32> pcchDeviceInstanceId),
                int Function(
                    int hContext,
                    Pointer<Utf16> szReaderName,
                    Pointer<Utf16> szDeviceInstanceId,
                    Pointer<Uint32> pcchDeviceInstanceId)>(
            'SCardGetReaderDeviceInstanceIdW');
        expect(SCardGetReaderDeviceInstanceId, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SCardGetReaderIcon', () {
        final winscard = DynamicLibrary.open('winscard.dll');
        final SCardGetReaderIcon = winscard.lookupFunction<
            Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName,
                Pointer<Uint8> pbIcon, Pointer<Uint32> pcbIcon),
            int Function(
                int hContext,
                Pointer<Utf16> szReaderName,
                Pointer<Uint8> pbIcon,
                Pointer<Uint32> pcbIcon)>('SCardGetReaderIconW');
        expect(SCardGetReaderIcon, isA<Function>());
      });
    }
    test('Can instantiate SCardGetStatusChange', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardGetStatusChange = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Uint32 dwTimeout,
              Pointer<SCARD_READERSTATE> rgReaderStates, Uint32 cReaders),
          int Function(
              int hContext,
              int dwTimeout,
              Pointer<SCARD_READERSTATE> rgReaderStates,
              int cReaders)>('SCardGetStatusChangeW');
      expect(SCardGetStatusChange, isA<Function>());
    });
    test('Can instantiate SCardGetTransmitCount', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardGetTransmitCount = winscard.lookupFunction<
          Int32 Function(IntPtr hCard, Pointer<Uint32> pcTransmitCount),
          int Function(int hCard,
              Pointer<Uint32> pcTransmitCount)>('SCardGetTransmitCount');
      expect(SCardGetTransmitCount, isA<Function>());
    });
    test('Can instantiate SCardIntroduceCardType', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardIntroduceCardType = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<Utf16> szCardName,
              Pointer<GUID> pguidPrimaryProvider,
              Pointer<GUID> rgguidInterfaces,
              Uint32 dwInterfaceCount,
              Pointer<Uint8> pbAtr,
              Pointer<Uint8> pbAtrMask,
              Uint32 cbAtrLen),
          int Function(
              int hContext,
              Pointer<Utf16> szCardName,
              Pointer<GUID> pguidPrimaryProvider,
              Pointer<GUID> rgguidInterfaces,
              int dwInterfaceCount,
              Pointer<Uint8> pbAtr,
              Pointer<Uint8> pbAtrMask,
              int cbAtrLen)>('SCardIntroduceCardTypeW');
      expect(SCardIntroduceCardType, isA<Function>());
    });
    test('Can instantiate SCardIntroduceReader', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardIntroduceReader = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szDeviceName),
          int Function(int hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szDeviceName)>('SCardIntroduceReaderW');
      expect(SCardIntroduceReader, isA<Function>());
    });
    test('Can instantiate SCardIntroduceReaderGroup', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardIntroduceReaderGroup = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szGroupName),
          int Function(int hContext,
              Pointer<Utf16> szGroupName)>('SCardIntroduceReaderGroupW');
      expect(SCardIntroduceReaderGroup, isA<Function>());
    });
    test('Can instantiate SCardIsValidContext', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardIsValidContext = winscard.lookupFunction<
          Int32 Function(IntPtr hContext),
          int Function(int hContext)>('SCardIsValidContext');
      expect(SCardIsValidContext, isA<Function>());
    });
    test('Can instantiate SCardListCards', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardListCards = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<Uint8> pbAtr,
              Pointer<GUID> rgquidInterfaces,
              Uint32 cguidInterfaceCount,
              Pointer<Utf16> mszCards,
              Pointer<Uint32> pcchCards),
          int Function(
              int hContext,
              Pointer<Uint8> pbAtr,
              Pointer<GUID> rgquidInterfaces,
              int cguidInterfaceCount,
              Pointer<Utf16> mszCards,
              Pointer<Uint32> pcchCards)>('SCardListCardsW');
      expect(SCardListCards, isA<Function>());
    });
    test('Can instantiate SCardListInterfaces', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardListInterfaces = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szCard,
              Pointer<GUID> pguidInterfaces, Pointer<Uint32> pcguidInterfaces),
          int Function(
              int hContext,
              Pointer<Utf16> szCard,
              Pointer<GUID> pguidInterfaces,
              Pointer<Uint32> pcguidInterfaces)>('SCardListInterfacesW');
      expect(SCardListInterfaces, isA<Function>());
    });
    test('Can instantiate SCardListReaderGroups', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardListReaderGroups = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> mszGroups,
              Pointer<Uint32> pcchGroups),
          int Function(int hContext, Pointer<Utf16> mszGroups,
              Pointer<Uint32> pcchGroups)>('SCardListReaderGroupsW');
      expect(SCardListReaderGroups, isA<Function>());
    });
    test('Can instantiate SCardListReaders', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardListReaders = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> mszGroups,
              Pointer<Utf16> mszReaders, Pointer<Uint32> pcchReaders),
          int Function(
              int hContext,
              Pointer<Utf16> mszGroups,
              Pointer<Utf16> mszReaders,
              Pointer<Uint32> pcchReaders)>('SCardListReadersW');
      expect(SCardListReaders, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SCardListReadersWithDeviceInstanceId', () {
        final winscard = DynamicLibrary.open('winscard.dll');
        final SCardListReadersWithDeviceInstanceId = winscard.lookupFunction<
            Int32 Function(IntPtr hContext, Pointer<Utf16> szDeviceInstanceId,
                Pointer<Utf16> mszReaders, Pointer<Uint32> pcchReaders),
            int Function(
                int hContext,
                Pointer<Utf16> szDeviceInstanceId,
                Pointer<Utf16> mszReaders,
                Pointer<Uint32>
                    pcchReaders)>('SCardListReadersWithDeviceInstanceIdW');
        expect(SCardListReadersWithDeviceInstanceId, isA<Function>());
      });
    }
    test('Can instantiate SCardLocateCards', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardLocateCards = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> mszCards,
              Pointer<SCARD_READERSTATE> rgReaderStates, Uint32 cReaders),
          int Function(
              int hContext,
              Pointer<Utf16> mszCards,
              Pointer<SCARD_READERSTATE> rgReaderStates,
              int cReaders)>('SCardLocateCardsW');
      expect(SCardLocateCards, isA<Function>());
    });
    test('Can instantiate SCardLocateCardsByATR', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardLocateCardsByATR = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<SCARD_ATRMASK> rgAtrMasks,
              Uint32 cAtrs,
              Pointer<SCARD_READERSTATE> rgReaderStates,
              Uint32 cReaders),
          int Function(
              int hContext,
              Pointer<SCARD_ATRMASK> rgAtrMasks,
              int cAtrs,
              Pointer<SCARD_READERSTATE> rgReaderStates,
              int cReaders)>('SCardLocateCardsByATRW');
      expect(SCardLocateCardsByATR, isA<Function>());
    });
    test('Can instantiate SCardReadCache', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardReadCache = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<GUID> CardIdentifier,
              Uint32 FreshnessCounter,
              Pointer<Utf16> LookupName,
              Pointer<Uint8> Data,
              Pointer<Uint32> DataLen),
          int Function(
              int hContext,
              Pointer<GUID> CardIdentifier,
              int FreshnessCounter,
              Pointer<Utf16> LookupName,
              Pointer<Uint8> Data,
              Pointer<Uint32> DataLen)>('SCardReadCacheW');
      expect(SCardReadCache, isA<Function>());
    });
    test('Can instantiate SCardReconnect', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardReconnect = winscard.lookupFunction<
          Int32 Function(
              IntPtr hCard,
              Uint32 dwShareMode,
              Uint32 dwPreferredProtocols,
              Uint32 dwInitialization,
              Pointer<Uint32> pdwActiveProtocol),
          int Function(
              int hCard,
              int dwShareMode,
              int dwPreferredProtocols,
              int dwInitialization,
              Pointer<Uint32> pdwActiveProtocol)>('SCardReconnect');
      expect(SCardReconnect, isA<Function>());
    });
    test('Can instantiate SCardReleaseContext', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardReleaseContext = winscard.lookupFunction<
          Int32 Function(IntPtr hContext),
          int Function(int hContext)>('SCardReleaseContext');
      expect(SCardReleaseContext, isA<Function>());
    });
    test('Can instantiate SCardReleaseStartedEvent', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardReleaseStartedEvent =
          winscard.lookupFunction<Void Function(), void Function()>(
              'SCardReleaseStartedEvent');
      expect(SCardReleaseStartedEvent, isA<Function>());
    });
    test('Can instantiate SCardRemoveReaderFromGroup', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardRemoveReaderFromGroup = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szGroupName),
          int Function(int hContext, Pointer<Utf16> szReaderName,
              Pointer<Utf16> szGroupName)>('SCardRemoveReaderFromGroupW');
      expect(SCardRemoveReaderFromGroup, isA<Function>());
    });
    test('Can instantiate SCardSetAttrib', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardSetAttrib = winscard.lookupFunction<
          Int32 Function(IntPtr hCard, Uint32 dwAttrId, Pointer<Uint8> pbAttr,
              Uint32 cbAttrLen),
          int Function(int hCard, int dwAttrId, Pointer<Uint8> pbAttr,
              int cbAttrLen)>('SCardSetAttrib');
      expect(SCardSetAttrib, isA<Function>());
    });
    test('Can instantiate SCardSetCardTypeProviderName', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardSetCardTypeProviderName = winscard.lookupFunction<
          Int32 Function(IntPtr hContext, Pointer<Utf16> szCardName,
              Uint32 dwProviderId, Pointer<Utf16> szProvider),
          int Function(
              int hContext,
              Pointer<Utf16> szCardName,
              int dwProviderId,
              Pointer<Utf16> szProvider)>('SCardSetCardTypeProviderNameW');
      expect(SCardSetCardTypeProviderName, isA<Function>());
    });
    test('Can instantiate SCardStatus', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardStatus = winscard.lookupFunction<
          Int32 Function(
              IntPtr hCard,
              Pointer<Utf16> mszReaderNames,
              Pointer<Uint32> pcchReaderLen,
              Pointer<Uint32> pdwState,
              Pointer<Uint32> pdwProtocol,
              Pointer<Uint8> pbAtr,
              Pointer<Uint32> pcbAtrLen),
          int Function(
              int hCard,
              Pointer<Utf16> mszReaderNames,
              Pointer<Uint32> pcchReaderLen,
              Pointer<Uint32> pdwState,
              Pointer<Uint32> pdwProtocol,
              Pointer<Uint8> pbAtr,
              Pointer<Uint32> pcbAtrLen)>('SCardStatusW');
      expect(SCardStatus, isA<Function>());
    });
    test('Can instantiate SCardTransmit', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardTransmit = winscard.lookupFunction<
          Int32 Function(
              IntPtr hCard,
              Pointer<SCARD_IO_REQUEST> pioSendPci,
              Pointer<Uint8> pbSendBuffer,
              Uint32 cbSendLength,
              Pointer<SCARD_IO_REQUEST> pioRecvPci,
              Pointer<Uint8> pbRecvBuffer,
              Pointer<Uint32> pcbRecvLength),
          int Function(
              int hCard,
              Pointer<SCARD_IO_REQUEST> pioSendPci,
              Pointer<Uint8> pbSendBuffer,
              int cbSendLength,
              Pointer<SCARD_IO_REQUEST> pioRecvPci,
              Pointer<Uint8> pbRecvBuffer,
              Pointer<Uint32> pcbRecvLength)>('SCardTransmit');
      expect(SCardTransmit, isA<Function>());
    });
    test('Can instantiate SCardWriteCache', () {
      final winscard = DynamicLibrary.open('winscard.dll');
      final SCardWriteCache = winscard.lookupFunction<
          Int32 Function(
              IntPtr hContext,
              Pointer<GUID> CardIdentifier,
              Uint32 FreshnessCounter,
              Pointer<Utf16> LookupName,
              Pointer<Uint8> Data,
              Uint32 DataLen),
          int Function(
              int hContext,
              Pointer<GUID> CardIdentifier,
              int FreshnessCounter,
              Pointer<Utf16> LookupName,
              Pointer<Uint8> Data,
              int DataLen)>('SCardWriteCacheW');
      expect(SCardWriteCache, isA<Function>());
    });
  });

  group('Test scarddlg functions', () {
    test('Can instantiate SCardUIDlgSelectCard', () {
      final scarddlg = DynamicLibrary.open('scarddlg.dll');
      final SCardUIDlgSelectCard = scarddlg.lookupFunction<
          Int32 Function(Pointer<OPENCARDNAME_EX> param0),
          int Function(
              Pointer<OPENCARDNAME_EX> param0)>('SCardUIDlgSelectCardW');
      expect(SCardUIDlgSelectCard, isA<Function>());
    });
  });

  group('Test setupapi functions', () {
    test('Can instantiate SetupDiDestroyDeviceInfoList', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiDestroyDeviceInfoList = setupapi.lookupFunction<
          Int32 Function(IntPtr DeviceInfoSet),
          int Function(int DeviceInfoSet)>('SetupDiDestroyDeviceInfoList');
      expect(SetupDiDestroyDeviceInfoList, isA<Function>());
    });
    test('Can instantiate SetupDiEnumDeviceInfo', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiEnumDeviceInfo = setupapi.lookupFunction<
              Int32 Function(IntPtr DeviceInfoSet, Uint32 MemberIndex,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData),
              int Function(int DeviceInfoSet, int MemberIndex,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData)>(
          'SetupDiEnumDeviceInfo');
      expect(SetupDiEnumDeviceInfo, isA<Function>());
    });
    test('Can instantiate SetupDiEnumDeviceInterfaces', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiEnumDeviceInterfaces = setupapi.lookupFunction<
              Int32 Function(
                  IntPtr DeviceInfoSet,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData,
                  Pointer<GUID> InterfaceClassGuid,
                  Uint32 MemberIndex,
                  Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData),
              int Function(
                  int DeviceInfoSet,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData,
                  Pointer<GUID> InterfaceClassGuid,
                  int MemberIndex,
                  Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData)>(
          'SetupDiEnumDeviceInterfaces');
      expect(SetupDiEnumDeviceInterfaces, isA<Function>());
    });
    test('Can instantiate SetupDiGetClassDevs', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiGetClassDevs = setupapi.lookupFunction<
          IntPtr Function(Pointer<GUID> ClassGuid, Pointer<Utf16> Enumerator,
              IntPtr hwndParent, Uint32 Flags),
          int Function(Pointer<GUID> ClassGuid, Pointer<Utf16> Enumerator,
              int hwndParent, int Flags)>('SetupDiGetClassDevsW');
      expect(SetupDiGetClassDevs, isA<Function>());
    });
    test('Can instantiate SetupDiGetDeviceInstanceId', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiGetDeviceInstanceId = setupapi.lookupFunction<
          Int32 Function(
              IntPtr DeviceInfoSet,
              Pointer<SP_DEVINFO_DATA> DeviceInfoData,
              Pointer<Utf16> DeviceInstanceId,
              Uint32 DeviceInstanceIdSize,
              Pointer<Uint32> RequiredSize),
          int Function(
              int DeviceInfoSet,
              Pointer<SP_DEVINFO_DATA> DeviceInfoData,
              Pointer<Utf16> DeviceInstanceId,
              int DeviceInstanceIdSize,
              Pointer<Uint32> RequiredSize)>('SetupDiGetDeviceInstanceIdW');
      expect(SetupDiGetDeviceInstanceId, isA<Function>());
    });
    test('Can instantiate SetupDiGetDeviceInterfaceDetail', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiGetDeviceInterfaceDetail = setupapi.lookupFunction<
              Int32 Function(
                  IntPtr DeviceInfoSet,
                  Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData,
                  Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_>
                      DeviceInterfaceDetailData,
                  Uint32 DeviceInterfaceDetailDataSize,
                  Pointer<Uint32> RequiredSize,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData),
              int Function(
                  int DeviceInfoSet,
                  Pointer<SP_DEVICE_INTERFACE_DATA> DeviceInterfaceData,
                  Pointer<SP_DEVICE_INTERFACE_DETAIL_DATA_>
                      DeviceInterfaceDetailData,
                  int DeviceInterfaceDetailDataSize,
                  Pointer<Uint32> RequiredSize,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData)>(
          'SetupDiGetDeviceInterfaceDetailW');
      expect(SetupDiGetDeviceInterfaceDetail, isA<Function>());
    });
    test('Can instantiate SetupDiGetDeviceRegistryProperty', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiGetDeviceRegistryProperty = setupapi.lookupFunction<
              Int32 Function(
                  IntPtr DeviceInfoSet,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData,
                  Uint32 Property,
                  Pointer<Uint32> PropertyRegDataType,
                  Pointer<Uint8> PropertyBuffer,
                  Uint32 PropertyBufferSize,
                  Pointer<Uint32> RequiredSize),
              int Function(
                  int DeviceInfoSet,
                  Pointer<SP_DEVINFO_DATA> DeviceInfoData,
                  int Property,
                  Pointer<Uint32> PropertyRegDataType,
                  Pointer<Uint8> PropertyBuffer,
                  int PropertyBufferSize,
                  Pointer<Uint32> RequiredSize)>(
          'SetupDiGetDeviceRegistryPropertyW');
      expect(SetupDiGetDeviceRegistryProperty, isA<Function>());
    });
    test('Can instantiate SetupDiOpenDevRegKey', () {
      final setupapi = DynamicLibrary.open('setupapi.dll');
      final SetupDiOpenDevRegKey = setupapi.lookupFunction<
          IntPtr Function(
              IntPtr DeviceInfoSet,
              Pointer<SP_DEVINFO_DATA> DeviceInfoData,
              Uint32 Scope,
              Uint32 HwProfile,
              Uint32 KeyType,
              Uint32 samDesired),
          int Function(
              int DeviceInfoSet,
              Pointer<SP_DEVINFO_DATA> DeviceInfoData,
              int Scope,
              int HwProfile,
              int KeyType,
              int samDesired)>('SetupDiOpenDevRegKey');
      expect(SetupDiOpenDevRegKey, isA<Function>());
    });
  });

  group('Test shlwapi functions', () {
    test('Can instantiate SHCreateMemStream', () {
      final shlwapi = DynamicLibrary.open('shlwapi.dll');
      final SHCreateMemStream = shlwapi.lookupFunction<
          Pointer<COMObject> Function(Pointer<Uint8> pInit, Uint32 cbInit),
          Pointer<COMObject> Function(
              Pointer<Uint8> pInit, int cbInit)>('SHCreateMemStream');
      expect(SHCreateMemStream, isA<Function>());
    });
  });

  group('Test dbghelp functions', () {
    test('Can instantiate SymCleanup', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymCleanup = dbghelp.lookupFunction<Int32 Function(IntPtr hProcess),
          int Function(int hProcess)>('SymCleanup');
      expect(SymCleanup, isA<Function>());
    });
    test('Can instantiate SymEnumSymbols', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymEnumSymbols = dbghelp.lookupFunction<
          Int32 Function(
              IntPtr hProcess,
              Uint64 BaseOfDll,
              Pointer<Utf16> Mask,
              Pointer<NativeFunction<SymEnumSymbolsProc>> EnumSymbolsCallback,
              Pointer UserContext),
          int Function(
              int hProcess,
              int BaseOfDll,
              Pointer<Utf16> Mask,
              Pointer<NativeFunction<SymEnumSymbolsProc>> EnumSymbolsCallback,
              Pointer UserContext)>('SymEnumSymbolsW');
      expect(SymEnumSymbols, isA<Function>());
    });
    test('Can instantiate SymFromAddr', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymFromAddr = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint64 Address,
              Pointer<Uint64> Displacement, Pointer<SYMBOL_INFO> Symbol),
          int Function(int hProcess, int Address, Pointer<Uint64> Displacement,
              Pointer<SYMBOL_INFO> Symbol)>('SymFromAddrW');
      expect(SymFromAddr, isA<Function>());
    });
    test('Can instantiate SymFromToken', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymFromToken = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint64 Base, Uint32 Token,
              Pointer<SYMBOL_INFO> Symbol),
          int Function(int hProcess, int Base, int Token,
              Pointer<SYMBOL_INFO> Symbol)>('SymFromTokenW');
      expect(SymFromToken, isA<Function>());
    });
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate SymGetExtendedOption', () {
        final dbghelp = DynamicLibrary.open('dbghelp.dll');
        final SymGetExtendedOption = dbghelp.lookupFunction<
            Int32 Function(Int32 option),
            int Function(int option)>('SymGetExtendedOption');
        expect(SymGetExtendedOption, isA<Function>());
      });
    }
    test('Can instantiate SymInitialize', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymInitialize = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<Utf16> UserSearchPath,
              Int32 fInvadeProcess),
          int Function(int hProcess, Pointer<Utf16> UserSearchPath,
              int fInvadeProcess)>('SymInitializeW');
      expect(SymInitialize, isA<Function>());
    });
    test('Can instantiate SymLoadModuleEx', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymLoadModuleEx = dbghelp.lookupFunction<
          Uint64 Function(
              IntPtr hProcess,
              IntPtr hFile,
              Pointer<Utf16> ImageName,
              Pointer<Utf16> ModuleName,
              Uint64 BaseOfDll,
              Uint32 DllSize,
              Pointer<MODLOAD_DATA> Data,
              Uint32 Flags),
          int Function(
              int hProcess,
              int hFile,
              Pointer<Utf16> ImageName,
              Pointer<Utf16> ModuleName,
              int BaseOfDll,
              int DllSize,
              Pointer<MODLOAD_DATA> Data,
              int Flags)>('SymLoadModuleExW');
      expect(SymLoadModuleEx, isA<Function>());
    });
    if (windowsBuildNumber >= 17134) {
      test('Can instantiate SymSetExtendedOption', () {
        final dbghelp = DynamicLibrary.open('dbghelp.dll');
        final SymSetExtendedOption = dbghelp.lookupFunction<
            Int32 Function(Int32 option, Int32 value),
            int Function(int option, int value)>('SymSetExtendedOption');
        expect(SymSetExtendedOption, isA<Function>());
      });
    }
    test('Can instantiate SymSetOptions', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymSetOptions = dbghelp.lookupFunction<
          Uint32 Function(Uint32 SymOptions),
          int Function(int SymOptions)>('SymSetOptions');
      expect(SymSetOptions, isA<Function>());
    });
    test('Can instantiate SymSetParentWindow', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymSetParentWindow = dbghelp.lookupFunction<
          Int32 Function(IntPtr hwnd),
          int Function(int hwnd)>('SymSetParentWindow');
      expect(SymSetParentWindow, isA<Function>());
    });
    test('Can instantiate SymSetScopeFromAddr', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymSetScopeFromAddr = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint64 Address),
          int Function(int hProcess, int Address)>('SymSetScopeFromAddr');
      expect(SymSetScopeFromAddr, isA<Function>());
    });
    test('Can instantiate SymSetScopeFromIndex', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymSetScopeFromIndex = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint64 BaseOfDll, Uint32 Index),
          int Function(
              int hProcess, int BaseOfDll, int Index)>('SymSetScopeFromIndex');
      expect(SymSetScopeFromIndex, isA<Function>());
    });
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate SymSetScopeFromInlineContext', () {
        final dbghelp = DynamicLibrary.open('dbghelp.dll');
        final SymSetScopeFromInlineContext = dbghelp.lookupFunction<
            Int32 Function(
                IntPtr hProcess, Uint64 Address, Uint32 InlineContext),
            int Function(int hProcess, int Address,
                int InlineContext)>('SymSetScopeFromInlineContext');
        expect(SymSetScopeFromInlineContext, isA<Function>());
      });
    }
    test('Can instantiate SymSetSearchPath', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymSetSearchPath = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Pointer<Utf16> SearchPathA),
          int Function(
              int hProcess, Pointer<Utf16> SearchPathA)>('SymSetSearchPathW');
      expect(SymSetSearchPath, isA<Function>());
    });
    test('Can instantiate SymUnloadModule', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymUnloadModule = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint32 BaseOfDll),
          int Function(int hProcess, int BaseOfDll)>('SymUnloadModule');
      expect(SymUnloadModule, isA<Function>());
    });
    test('Can instantiate SymUnloadModule64', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final SymUnloadModule64 = dbghelp.lookupFunction<
          Int32 Function(IntPtr hProcess, Uint64 BaseOfDll),
          int Function(int hProcess, int BaseOfDll)>('SymUnloadModule64');
      expect(SymUnloadModule64, isA<Function>());
    });
    test('Can instantiate UnDecorateSymbolName', () {
      final dbghelp = DynamicLibrary.open('dbghelp.dll');
      final UnDecorateSymbolName = dbghelp.lookupFunction<
          Uint32 Function(Pointer<Utf16> name, Pointer<Utf16> outputString,
              Uint32 maxStringLength, Uint32 flags),
          int Function(Pointer<Utf16> name, Pointer<Utf16> outputString,
              int maxStringLength, int flags)>('UnDecorateSymbolNameW');
      expect(UnDecorateSymbolName, isA<Function>());
    });
  });

  group('Test api-ms-win-core-winrt-string-l1-1-0 functions', () {
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsCompareStringOrdinal', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsCompareStringOrdinal =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(
                    IntPtr string1, IntPtr string2, Pointer<Int32> result),
                int Function(int string1, int string2,
                    Pointer<Int32> result)>('WindowsCompareStringOrdinal');
        expect(WindowsCompareStringOrdinal, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsConcatString', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsConcatString =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(
                    IntPtr string1, IntPtr string2, Pointer<IntPtr> newString),
                int Function(int string1, int string2,
                    Pointer<IntPtr> newString)>('WindowsConcatString');
        expect(WindowsConcatString, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsCreateString', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsCreateString =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(Pointer<Utf16> sourceString, Uint32 length,
                    Pointer<IntPtr> string),
                int Function(Pointer<Utf16> sourceString, int length,
                    Pointer<IntPtr> string)>('WindowsCreateString');
        expect(WindowsCreateString, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsDeleteString', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsDeleteString =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string),
                int Function(int string)>('WindowsDeleteString');
        expect(WindowsDeleteString, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsDeleteStringBuffer', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsDeleteStringBuffer =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr bufferHandle),
                int Function(int bufferHandle)>('WindowsDeleteStringBuffer');
        expect(WindowsDeleteStringBuffer, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsDuplicateString', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsDuplicateString =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, Pointer<IntPtr> newString),
                int Function(int string,
                    Pointer<IntPtr> newString)>('WindowsDuplicateString');
        expect(WindowsDuplicateString, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsGetStringLen', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsGetStringLen =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Uint32 Function(IntPtr string),
                int Function(int string)>('WindowsGetStringLen');
        expect(WindowsGetStringLen, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsGetStringRawBuffer', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsGetStringRawBuffer =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Pointer<Utf16> Function(IntPtr string, Pointer<Uint32> length),
                Pointer<Utf16> Function(int string,
                    Pointer<Uint32> length)>('WindowsGetStringRawBuffer');
        expect(WindowsGetStringRawBuffer, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsIsStringEmpty', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsIsStringEmpty =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string),
                int Function(int string)>('WindowsIsStringEmpty');
        expect(WindowsIsStringEmpty, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsPreallocateStringBuffer', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsPreallocateStringBuffer =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                    Int32 Function(
                        Uint32 length,
                        Pointer<Pointer<Uint16>> charBuffer,
                        Pointer<IntPtr> bufferHandle),
                    int Function(
                        int length,
                        Pointer<Pointer<Uint16>> charBuffer,
                        Pointer<IntPtr> bufferHandle)>(
                'WindowsPreallocateStringBuffer');
        expect(WindowsPreallocateStringBuffer, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsPromoteStringBuffer', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsPromoteStringBuffer =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr bufferHandle, Pointer<IntPtr> string),
                int Function(int bufferHandle,
                    Pointer<IntPtr> string)>('WindowsPromoteStringBuffer');
        expect(WindowsPromoteStringBuffer, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsReplaceString', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsReplaceString =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, IntPtr stringReplaced,
                    IntPtr stringReplaceWith, Pointer<IntPtr> newString),
                int Function(
                    int string,
                    int stringReplaced,
                    int stringReplaceWith,
                    Pointer<IntPtr> newString)>('WindowsReplaceString');
        expect(WindowsReplaceString, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsStringHasEmbeddedNull', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsStringHasEmbeddedNull =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                    Int32 Function(IntPtr string, Pointer<Int32> hasEmbedNull),
                    int Function(int string, Pointer<Int32> hasEmbedNull)>(
                'WindowsStringHasEmbeddedNull');
        expect(WindowsStringHasEmbeddedNull, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsSubstring', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsSubstring =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, Uint32 startIndex,
                    Pointer<IntPtr> newString),
                int Function(int string, int startIndex,
                    Pointer<IntPtr> newString)>('WindowsSubstring');
        expect(WindowsSubstring, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsSubstringWithSpecifiedLength', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsSubstringWithSpecifiedLength =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, Uint32 startIndex, Uint32 length,
                    Pointer<IntPtr> newString),
                int Function(
                    int string,
                    int startIndex,
                    int length,
                    Pointer<IntPtr>
                        newString)>('WindowsSubstringWithSpecifiedLength');
        expect(WindowsSubstringWithSpecifiedLength, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsTrimStringEnd', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsTrimStringEnd =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, IntPtr trimString,
                    Pointer<IntPtr> newString),
                int Function(int string, int trimString,
                    Pointer<IntPtr> newString)>('WindowsTrimStringEnd');
        expect(WindowsTrimStringEnd, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate WindowsTrimStringStart', () {
        final api_ms_win_core_winrt_string_l1_1_0 =
            DynamicLibrary.open('api-ms-win-core-winrt-string-l1-1-0.dll');
        final WindowsTrimStringStart =
            api_ms_win_core_winrt_string_l1_1_0.lookupFunction<
                Int32 Function(IntPtr string, IntPtr trimString,
                    Pointer<IntPtr> newString),
                int Function(int string, int trimString,
                    Pointer<IntPtr> newString)>('WindowsTrimStringStart');
        expect(WindowsTrimStringStart, isA<Function>());
      });
    }
  });

  group('Test api-ms-win-wsl-api-l1-1-0 functions', () {
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslConfigureDistribution', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslConfigureDistribution =
            api_ms_win_wsl_api_l1_1_0.lookupFunction<
                Int32 Function(Pointer<Utf16> distributionName,
                    Uint32 defaultUID, Uint32 wslDistributionFlags),
                int Function(Pointer<Utf16> distributionName, int defaultUID,
                    int wslDistributionFlags)>('WslConfigureDistribution');
        expect(WslConfigureDistribution, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslGetDistributionConfiguration', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslGetDistributionConfiguration =
            api_ms_win_wsl_api_l1_1_0
                .lookupFunction<
                        Int32 Function(
                            Pointer<Utf16> distributionName,
                            Pointer<Uint32> distributionVersion,
                            Pointer<Uint32> defaultUID,
                            Pointer<Uint32> wslDistributionFlags,
                            Pointer<Pointer<Pointer<Utf8>>>
                                defaultEnvironmentVariables,
                            Pointer<Uint32> defaultEnvironmentVariableCount),
                        int Function(
                            Pointer<Utf16> distributionName,
                            Pointer<Uint32> distributionVersion,
                            Pointer<Uint32> defaultUID,
                            Pointer<Uint32> wslDistributionFlags,
                            Pointer<Pointer<Pointer<Utf8>>>
                                defaultEnvironmentVariables,
                            Pointer<Uint32> defaultEnvironmentVariableCount)>(
                    'WslGetDistributionConfiguration');
        expect(WslGetDistributionConfiguration, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslIsDistributionRegistered', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslIsDistributionRegistered =
            api_ms_win_wsl_api_l1_1_0.lookupFunction<
                    Int32 Function(Pointer<Utf16> distributionName),
                    int Function(Pointer<Utf16> distributionName)>(
                'WslIsDistributionRegistered');
        expect(WslIsDistributionRegistered, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslLaunch', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslLaunch = api_ms_win_wsl_api_l1_1_0.lookupFunction<
            Int32 Function(
                Pointer<Utf16> distributionName,
                Pointer<Utf16> command,
                Int32 useCurrentWorkingDirectory,
                IntPtr stdIn,
                IntPtr stdOut,
                IntPtr stdErr,
                Pointer<IntPtr> process),
            int Function(
                Pointer<Utf16> distributionName,
                Pointer<Utf16> command,
                int useCurrentWorkingDirectory,
                int stdIn,
                int stdOut,
                int stdErr,
                Pointer<IntPtr> process)>('WslLaunch');
        expect(WslLaunch, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslLaunchInteractive', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslLaunchInteractive = api_ms_win_wsl_api_l1_1_0.lookupFunction<
            Int32 Function(
                Pointer<Utf16> distributionName,
                Pointer<Utf16> command,
                Int32 useCurrentWorkingDirectory,
                Pointer<Uint32> exitCode),
            int Function(
                Pointer<Utf16> distributionName,
                Pointer<Utf16> command,
                int useCurrentWorkingDirectory,
                Pointer<Uint32> exitCode)>('WslLaunchInteractive');
        expect(WslLaunchInteractive, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslRegisterDistribution', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslRegisterDistribution =
            api_ms_win_wsl_api_l1_1_0.lookupFunction<
                Int32 Function(Pointer<Utf16> distributionName,
                    Pointer<Utf16> tarGzFilename),
                int Function(Pointer<Utf16> distributionName,
                    Pointer<Utf16> tarGzFilename)>('WslRegisterDistribution');
        expect(WslRegisterDistribution, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 19041) {
      test('Can instantiate WslUnregisterDistribution', () {
        final api_ms_win_wsl_api_l1_1_0 =
            DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');
        final WslUnregisterDistribution =
            api_ms_win_wsl_api_l1_1_0.lookupFunction<
                    Int32 Function(Pointer<Utf16> distributionName),
                    int Function(Pointer<Utf16> distributionName)>(
                'WslUnregisterDistribution');
        expect(WslUnregisterDistribution, isA<Function>());
      });
    }
  });

  group('Test xinput1_4 functions', () {
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputEnable', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputEnable = xinput1_4.lookupFunction<
            Void Function(Int32 enable),
            void Function(int enable)>('XInputEnable');
        expect(XInputEnable, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputGetAudioDeviceIds', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputGetAudioDeviceIds = xinput1_4.lookupFunction<
            Uint32 Function(
                Uint32 dwUserIndex,
                Pointer<Utf16> pRenderDeviceId,
                Pointer<Uint32> pRenderCount,
                Pointer<Utf16> pCaptureDeviceId,
                Pointer<Uint32> pCaptureCount),
            int Function(
                int dwUserIndex,
                Pointer<Utf16> pRenderDeviceId,
                Pointer<Uint32> pRenderCount,
                Pointer<Utf16> pCaptureDeviceId,
                Pointer<Uint32> pCaptureCount)>('XInputGetAudioDeviceIds');
        expect(XInputGetAudioDeviceIds, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputGetBatteryInformation', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputGetBatteryInformation = xinput1_4.lookupFunction<
                Uint32 Function(Uint32 dwUserIndex, Uint8 devType,
                    Pointer<XINPUT_BATTERY_INFORMATION> pBatteryInformation),
                int Function(int dwUserIndex, int devType,
                    Pointer<XINPUT_BATTERY_INFORMATION> pBatteryInformation)>(
            'XInputGetBatteryInformation');
        expect(XInputGetBatteryInformation, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputGetCapabilities', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputGetCapabilities = xinput1_4.lookupFunction<
                Uint32 Function(Uint32 dwUserIndex, Uint32 dwFlags,
                    Pointer<XINPUT_CAPABILITIES> pCapabilities),
                int Function(int dwUserIndex, int dwFlags,
                    Pointer<XINPUT_CAPABILITIES> pCapabilities)>(
            'XInputGetCapabilities');
        expect(XInputGetCapabilities, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputGetKeystroke', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputGetKeystroke = xinput1_4.lookupFunction<
            Uint32 Function(Uint32 dwUserIndex, Uint32 dwReserved,
                Pointer<XINPUT_KEYSTROKE> pKeystroke),
            int Function(int dwUserIndex, int dwReserved,
                Pointer<XINPUT_KEYSTROKE> pKeystroke)>('XInputGetKeystroke');
        expect(XInputGetKeystroke, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputGetState', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputGetState = xinput1_4.lookupFunction<
            Uint32 Function(Uint32 dwUserIndex, Pointer<XINPUT_STATE> pState),
            int Function(int dwUserIndex,
                Pointer<XINPUT_STATE> pState)>('XInputGetState');
        expect(XInputGetState, isA<Function>());
      });
    }
    if (windowsBuildNumber >= 9200) {
      test('Can instantiate XInputSetState', () {
        final xinput1_4 = DynamicLibrary.open('xinput1_4.dll');
        final XInputSetState = xinput1_4.lookupFunction<
            Uint32 Function(
                Uint32 dwUserIndex, Pointer<XINPUT_VIBRATION> pVibration),
            int Function(int dwUserIndex,
                Pointer<XINPUT_VIBRATION> pVibration)>('XInputSetState');
        expect(XInputSetState, isA<Function>());
      });
    }
  });
}
