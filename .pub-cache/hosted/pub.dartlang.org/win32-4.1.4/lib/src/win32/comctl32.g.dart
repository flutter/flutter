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

final _comctl32 = DynamicLibrary.open('comctl32.dll');

/// Calls the next handler in a window's subclass chain. The last handler in
/// the subclass chain calls the original window procedure for the window.
///
/// ```c
/// LRESULT DefSubclassProc(
///   HWND   hWnd,
///   UINT   uMsg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category comctl32}
int DefSubclassProc(int hWnd, int uMsg, int wParam, int lParam) =>
    _DefSubclassProc(hWnd, uMsg, wParam, lParam);

final _DefSubclassProc = _comctl32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam),
    int Function(
        int hWnd, int uMsg, int wParam, int lParam)>('DefSubclassProc');

/// The DrawStatusText function draws the specified text in the style of a
/// status window with borders.
///
/// ```c
/// void DrawStatusTextW(
///   HDC     hDC,
///   LPCRECT lprc,
///   LPCWSTR pszText,
///   UINT    uFlags
/// );
/// ```
/// {@category comctl32}
void DrawStatusText(
        int hDC, Pointer<RECT> lprc, Pointer<Utf16> pszText, int uFlags) =>
    _DrawStatusText(hDC, lprc, pszText, uFlags);

final _DrawStatusText = _comctl32.lookupFunction<
    Void Function(
        IntPtr hDC, Pointer<RECT> lprc, Pointer<Utf16> pszText, Uint32 uFlags),
    void Function(int hDC, Pointer<RECT> lprc, Pointer<Utf16> pszText,
        int uFlags)>('DrawStatusTextW');

/// Ensures that the common control DLL (Comctl32.dll) is loaded, and
/// registers specific common control classes from the DLL. An application
/// must call this function before creating a common control.
///
/// ```c
/// BOOL InitCommonControlsEx(
///   const INITCOMMONCONTROLSEX *picce
/// );
/// ```
/// {@category comctl32}
int InitCommonControlsEx(Pointer<INITCOMMONCONTROLSEX> picce) =>
    _InitCommonControlsEx(picce);

final _InitCommonControlsEx = _comctl32.lookupFunction<
    Int32 Function(Pointer<INITCOMMONCONTROLSEX> picce),
    int Function(Pointer<INITCOMMONCONTROLSEX> picce)>('InitCommonControlsEx');

/// Removes a subclass callback from a window.
///
/// ```c
/// BOOL RemoveWindowSubclass(
///   HWND         hWnd,
///   SUBCLASSPROC pfnSubclass,
///   UINT_PTR     uIdSubclass
/// );
/// ```
/// {@category comctl32}
int RemoveWindowSubclass(int hWnd,
        Pointer<NativeFunction<SubclassProc>> pfnSubclass, int uIdSubclass) =>
    _RemoveWindowSubclass(hWnd, pfnSubclass, uIdSubclass);

final _RemoveWindowSubclass = _comctl32.lookupFunction<
    Int32 Function(IntPtr hWnd,
        Pointer<NativeFunction<SubclassProc>> pfnSubclass, IntPtr uIdSubclass),
    int Function(int hWnd, Pointer<NativeFunction<SubclassProc>> pfnSubclass,
        int uIdSubclass)>('RemoveWindowSubclass');

/// Installs or updates a window subclass callback.
///
/// ```c
/// BOOL SetWindowSubclass(
///   HWND         hWnd,
///   SUBCLASSPROC pfnSubclass,
///   UINT_PTR     uIdSubclass,
///   DWORD_PTR    dwRefData
/// );
/// ```
/// {@category comctl32}
int SetWindowSubclass(
        int hWnd,
        Pointer<NativeFunction<SubclassProc>> pfnSubclass,
        int uIdSubclass,
        int dwRefData) =>
    _SetWindowSubclass(hWnd, pfnSubclass, uIdSubclass, dwRefData);

final _SetWindowSubclass = _comctl32.lookupFunction<
    Int32 Function(
        IntPtr hWnd,
        Pointer<NativeFunction<SubclassProc>> pfnSubclass,
        IntPtr uIdSubclass,
        IntPtr dwRefData),
    int Function(int hWnd, Pointer<NativeFunction<SubclassProc>> pfnSubclass,
        int uIdSubclass, int dwRefData)>('SetWindowSubclass');

/// The TaskDialog function creates, displays, and operates a task dialog.
/// The task dialog contains application-defined message text and title,
/// icons, and any combination of predefined push buttons. This function
/// does not support the registration of a callback function to receive
/// notifications.
///
/// ```c
/// HRESULT TaskDialog(
///   HWND                           hwndOwner,
///   HINSTANCE                      hInstance,
///   PCWSTR                         pszWindowTitle,
///   PCWSTR                         pszMainInstruction,
///   PCWSTR                         pszContent,
///   TASKDIALOG_COMMON_BUTTON_FLAGS dwCommonButtons,
///   PCWSTR                         pszIcon,
///   int                            *pnButton
/// );
/// ```
/// {@category comctl32}
int TaskDialog(
        int hwndOwner,
        int hInstance,
        Pointer<Utf16> pszWindowTitle,
        Pointer<Utf16> pszMainInstruction,
        Pointer<Utf16> pszContent,
        int dwCommonButtons,
        Pointer<Utf16> pszIcon,
        Pointer<Int32> pnButton) =>
    _TaskDialog(hwndOwner, hInstance, pszWindowTitle, pszMainInstruction,
        pszContent, dwCommonButtons, pszIcon, pnButton);

final _TaskDialog = _comctl32.lookupFunction<
    Int32 Function(
        IntPtr hwndOwner,
        IntPtr hInstance,
        Pointer<Utf16> pszWindowTitle,
        Pointer<Utf16> pszMainInstruction,
        Pointer<Utf16> pszContent,
        Int32 dwCommonButtons,
        Pointer<Utf16> pszIcon,
        Pointer<Int32> pnButton),
    int Function(
        int hwndOwner,
        int hInstance,
        Pointer<Utf16> pszWindowTitle,
        Pointer<Utf16> pszMainInstruction,
        Pointer<Utf16> pszContent,
        int dwCommonButtons,
        Pointer<Utf16> pszIcon,
        Pointer<Int32> pnButton)>('TaskDialog');

/// The TaskDialogIndirect function creates, displays, and operates a task
/// dialog. The task dialog contains application-defined icons, messages,
/// title, verification check box, command links, push buttons, and radio
/// buttons. This function can register a callback function to receive
/// notification messages.
///
/// ```c
/// HRESULT TaskDialogIndirect(
///   const TASKDIALOGCONFIG *pTaskConfig,
///   int                    *pnButton,
///   int                    *pnRadioButton,
///   BOOL                   *pfVerificationFlagChecked
/// );
/// ```
/// {@category comctl32}
int TaskDialogIndirect(
        Pointer<TASKDIALOGCONFIG> pTaskConfig,
        Pointer<Int32> pnButton,
        Pointer<Int32> pnRadioButton,
        Pointer<Int32> pfVerificationFlagChecked) =>
    _TaskDialogIndirect(
        pTaskConfig, pnButton, pnRadioButton, pfVerificationFlagChecked);

final _TaskDialogIndirect = _comctl32.lookupFunction<
    Int32 Function(
        Pointer<TASKDIALOGCONFIG> pTaskConfig,
        Pointer<Int32> pnButton,
        Pointer<Int32> pnRadioButton,
        Pointer<Int32> pfVerificationFlagChecked),
    int Function(
        Pointer<TASKDIALOGCONFIG> pTaskConfig,
        Pointer<Int32> pnButton,
        Pointer<Int32> pnRadioButton,
        Pointer<Int32> pfVerificationFlagChecked)>('TaskDialogIndirect');
