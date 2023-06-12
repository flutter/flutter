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

final _user32 = DynamicLibrary.open('user32.dll');

/// Sets the input locale identifier (formerly called the keyboard layout
/// handle) for the calling thread or the current process. The input locale
/// identifier specifies a locale as well as the physical layout of the
/// keyboard.
///
/// ```c
/// HKL ActivateKeyboardLayout(
///   HKL  hkl,
///   UINT Flags
/// );
/// ```
/// {@category user32}
int ActivateKeyboardLayout(int hkl, int Flags) =>
    _ActivateKeyboardLayout(hkl, Flags);

final _ActivateKeyboardLayout = _user32.lookupFunction<
    IntPtr Function(IntPtr hkl, Uint32 Flags),
    int Function(int hkl, int Flags)>('ActivateKeyboardLayout');

/// Places the given window in the system-maintained clipboard format
/// listener list.
///
/// ```c
/// BOOL AddClipboardFormatListener(
///   HWND hwnd
/// );
/// ```
/// {@category user32}
int AddClipboardFormatListener(int hwnd) => _AddClipboardFormatListener(hwnd);

final _AddClipboardFormatListener =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'AddClipboardFormatListener');

/// Calculates the required size of the window rectangle, based on the
/// desired client-rectangle size. The window rectangle can then be passed
/// to the CreateWindow function to create a window whose client area is the
/// desired size.
///
/// ```c
/// BOOL AdjustWindowRect(
///   LPRECT lpRect,
///   DWORD  dwStyle,
///   BOOL   bMenu
/// );
/// ```
/// {@category user32}
int AdjustWindowRect(Pointer<RECT> lpRect, int dwStyle, int bMenu) =>
    _AdjustWindowRect(lpRect, dwStyle, bMenu);

final _AdjustWindowRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu),
    int Function(
        Pointer<RECT> lpRect, int dwStyle, int bMenu)>('AdjustWindowRect');

/// Calculates the required size of the window rectangle, based on the
/// desired size of the client rectangle. The window rectangle can then be
/// passed to the CreateWindowEx function to create a window whose client
/// area is the desired size.
///
/// ```c
/// BOOL AdjustWindowRectEx(
///   LPRECT lpRect,
///   DWORD  dwStyle,
///   BOOL   bMenu,
///   DWORD  dwExStyle
/// );
/// ```
/// {@category user32}
int AdjustWindowRectEx(
        Pointer<RECT> lpRect, int dwStyle, int bMenu, int dwExStyle) =>
    _AdjustWindowRectEx(lpRect, dwStyle, bMenu, dwExStyle);

final _AdjustWindowRectEx = _user32.lookupFunction<
    Int32 Function(
        Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu, Uint32 dwExStyle),
    int Function(Pointer<RECT> lpRect, int dwStyle, int bMenu,
        int dwExStyle)>('AdjustWindowRectEx');

/// Calculates the required size of the window rectangle, based on the
/// desired size of the client rectangle and the provided DPI. This window
/// rectangle can then be passed to the CreateWindowEx function to create a
/// window with a client area of the desired size.
///
/// ```c
/// BOOL AdjustWindowRectExForDpi(
///   LPRECT lpRect,
///   DWORD  dwStyle,
///   BOOL   bMenu,
///   DWORD  dwExStyle,
///   UINT   dpi
/// );
/// ```
/// {@category user32}
int AdjustWindowRectExForDpi(
        Pointer<RECT> lpRect, int dwStyle, int bMenu, int dwExStyle, int dpi) =>
    _AdjustWindowRectExForDpi(lpRect, dwStyle, bMenu, dwExStyle, dpi);

final _AdjustWindowRectExForDpi = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lpRect, Uint32 dwStyle, Int32 bMenu,
        Uint32 dwExStyle, Uint32 dpi),
    int Function(Pointer<RECT> lpRect, int dwStyle, int bMenu, int dwExStyle,
        int dpi)>('AdjustWindowRectExForDpi');

/// Enables the specified process to set the foreground window using the
/// SetForegroundWindow function. The calling process must already be able
/// to set the foreground window.
///
/// ```c
/// BOOL AllowSetForegroundWindow(
///   DWORD dwProcessId
/// );
/// ```
/// {@category user32}
int AllowSetForegroundWindow(int dwProcessId) =>
    _AllowSetForegroundWindow(dwProcessId);

final _AllowSetForegroundWindow = _user32.lookupFunction<
    Int32 Function(Uint32 dwProcessId),
    int Function(int dwProcessId)>('AllowSetForegroundWindow');

/// Enables you to produce special effects when showing or hiding windows.
/// There are four types of animation: roll, slide, collapse or expand, and
/// alpha-blended fade.
///
/// ```c
/// BOOL AnimateWindow(
///   HWND  hWnd,
///   DWORD dwTime,
///   DWORD dwFlags
/// );
/// ```
/// {@category user32}
int AnimateWindow(int hWnd, int dwTime, int dwFlags) =>
    _AnimateWindow(hWnd, dwTime, dwFlags);

final _AnimateWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 dwTime, Uint32 dwFlags),
    int Function(int hWnd, int dwTime, int dwFlags)>('AnimateWindow');

/// Indicates whether an owned, visible, top-level pop-up, or overlapped
/// window exists on the screen. The function searches the entire screen,
/// not just the calling application's client area.
///
/// ```c
/// BOOL AnyPopup();
/// ```
/// {@category user32}
int AnyPopup() => _AnyPopup();

final _AnyPopup =
    _user32.lookupFunction<Int32 Function(), int Function()>('AnyPopup');

/// Appends a new item to the end of the specified menu bar, drop-down menu,
/// submenu, or shortcut menu. You can use this function to specify the
/// content, appearance, and behavior of the menu item.
///
/// ```c
/// BOOL AppendMenuW(
///   HMENU    hMenu,
///   UINT     uFlags,
///   UINT_PTR uIDNewItem,
///   LPCWSTR  lpNewItem
/// );
/// ```
/// {@category user32}
int AppendMenu(
        int hMenu, int uFlags, int uIDNewItem, Pointer<Utf16> lpNewItem) =>
    _AppendMenu(hMenu, uFlags, uIDNewItem, lpNewItem);

final _AppendMenu = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uFlags, IntPtr uIDNewItem,
        Pointer<Utf16> lpNewItem),
    int Function(int hMenu, int uFlags, int uIDNewItem,
        Pointer<Utf16> lpNewItem)>('AppendMenuW');

/// Determines whether two DPI_AWARENESS_CONTEXT values are identical.
///
/// ```c
/// BOOL AreDpiAwarenessContextsEqual(
///   DPI_AWARENESS_CONTEXT dpiContextA,
///   DPI_AWARENESS_CONTEXT dpiContextB
/// );
/// ```
/// {@category user32}
int AreDpiAwarenessContextsEqual(int dpiContextA, int dpiContextB) =>
    _AreDpiAwarenessContextsEqual(dpiContextA, dpiContextB);

final _AreDpiAwarenessContextsEqual = _user32.lookupFunction<
    Int32 Function(IntPtr dpiContextA, IntPtr dpiContextB),
    int Function(
        int dpiContextA, int dpiContextB)>('AreDpiAwarenessContextsEqual');

/// Arranges all the minimized (iconic) child windows of the specified
/// parent window.
///
/// ```c
/// UINT ArrangeIconicWindows(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int ArrangeIconicWindows(int hWnd) => _ArrangeIconicWindows(hWnd);

final _ArrangeIconicWindows = _user32.lookupFunction<
    Uint32 Function(IntPtr hWnd),
    int Function(int hWnd)>('ArrangeIconicWindows');

/// Attaches or detaches the input processing mechanism of one thread to
/// that of another thread.
///
/// ```c
/// BOOL AttachThreadInput(
///   DWORD idAttach,
///   DWORD idAttachTo,
///   BOOL  fAttach
/// );
/// ```
/// {@category user32}
int AttachThreadInput(int idAttach, int idAttachTo, int fAttach) =>
    _AttachThreadInput(idAttach, idAttachTo, fAttach);

final _AttachThreadInput = _user32.lookupFunction<
    Int32 Function(Uint32 idAttach, Uint32 idAttachTo, Int32 fAttach),
    int Function(
        int idAttach, int idAttachTo, int fAttach)>('AttachThreadInput');

/// Allocates memory for a multiple-window- position structure and returns
/// the handle to the structure.
///
/// ```c
/// HDWP BeginDeferWindowPos(
///   int nNumWindows
/// );
/// ```
/// {@category user32}
int BeginDeferWindowPos(int nNumWindows) => _BeginDeferWindowPos(nNumWindows);

final _BeginDeferWindowPos = _user32.lookupFunction<
    IntPtr Function(Int32 nNumWindows),
    int Function(int nNumWindows)>('BeginDeferWindowPos');

/// The BeginPaint function prepares the specified window for painting and
/// fills a PAINTSTRUCT structure with information about the painting.
///
/// ```c
/// HDC BeginPaint(
///   HWND          hWnd,
///   LPPAINTSTRUCT lpPaint
/// );
/// ```
/// {@category user32}
int BeginPaint(int hWnd, Pointer<PAINTSTRUCT> lpPaint) =>
    _BeginPaint(hWnd, lpPaint);

final _BeginPaint = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Pointer<PAINTSTRUCT> lpPaint),
    int Function(int hWnd, Pointer<PAINTSTRUCT> lpPaint)>('BeginPaint');

/// Blocks keyboard and mouse input events from reaching applications.
///
/// ```c
/// BOOL BlockInput(
///   BOOL fBlockIt);
/// ```
/// {@category user32}
int BlockInput(int fBlockIt) => _BlockInput(fBlockIt);

final _BlockInput = _user32.lookupFunction<Int32 Function(Int32 fBlockIt),
    int Function(int fBlockIt)>('BlockInput');

/// Brings the specified window to the top of the Z order. If the window is
/// a top-level window, it is activated. If the window is a child window,
/// the top-level parent window associated with the child window is
/// activated.
///
/// ```c
/// BOOL BringWindowToTop(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int BringWindowToTop(int hWnd) => _BringWindowToTop(hWnd);

final _BringWindowToTop =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'BringWindowToTop');

/// Sends a message to the specified recipients. The recipients can be
/// applications, installable drivers, network drivers, system-level device
/// drivers, or any combination of these system components.
///
/// ```c
/// long BroadcastSystemMessageW(
///   DWORD   flags,
///   LPDWORD lpInfo,
///   UINT    Msg,
///   WPARAM  wParam,
///   LPARAM  lParam
/// );
/// ```
/// {@category user32}
int BroadcastSystemMessage(
        int flags, Pointer<Uint32> lpInfo, int Msg, int wParam, int lParam) =>
    _BroadcastSystemMessage(flags, lpInfo, Msg, wParam, lParam);

final _BroadcastSystemMessage = _user32.lookupFunction<
    Int32 Function(Uint32 flags, Pointer<Uint32> lpInfo, Uint32 Msg,
        IntPtr wParam, IntPtr lParam),
    int Function(int flags, Pointer<Uint32> lpInfo, int Msg, int wParam,
        int lParam)>('BroadcastSystemMessageW');

/// Sends a message to the specified recipients. The recipients can be
/// applications, installable drivers, network drivers, system-level device
/// drivers, or any combination of these system components.
///
/// ```c
/// long BroadcastSystemMessageExW(
///   DWORD    flags,
///   LPDWORD  lpInfo,
///   UINT     Msg,
///   WPARAM   wParam,
///   LPARAM   lParam,
///   PBSMINFO pbsmInfo
/// );
/// ```
/// {@category user32}
int BroadcastSystemMessageEx(int flags, Pointer<Uint32> lpInfo, int Msg,
        int wParam, int lParam, Pointer<BSMINFO> pbsmInfo) =>
    _BroadcastSystemMessageEx(flags, lpInfo, Msg, wParam, lParam, pbsmInfo);

final _BroadcastSystemMessageEx = _user32.lookupFunction<
    Int32 Function(Uint32 flags, Pointer<Uint32> lpInfo, Uint32 Msg,
        IntPtr wParam, IntPtr lParam, Pointer<BSMINFO> pbsmInfo),
    int Function(int flags, Pointer<Uint32> lpInfo, int Msg, int wParam,
        int lParam, Pointer<BSMINFO> pbsmInfo)>('BroadcastSystemMessageExW');

/// Calculates an appropriate pop-up window position using the specified
/// anchor point, pop-up window size, flags, and the optional exclude
/// rectangle. When the specified pop-up window size is smaller than the
/// desktop window size, use the CalculatePopupWindowPosition function to
/// ensure that the pop-up window is fully visible on the desktop window,
/// regardless of the specified anchor point.
///
/// ```c
/// BOOL CalculatePopupWindowPosition(
///   const POINT *anchorPoint,
///   const SIZE  *windowSize,
///   UINT        flags,
///   RECT        *excludeRect,
///   RECT        *popupWindowPosition
/// );
/// ```
/// {@category user32}
int CalculatePopupWindowPosition(
        Pointer<POINT> anchorPoint,
        Pointer<SIZE> windowSize,
        int flags,
        Pointer<RECT> excludeRect,
        Pointer<RECT> popupWindowPosition) =>
    _CalculatePopupWindowPosition(
        anchorPoint, windowSize, flags, excludeRect, popupWindowPosition);

final _CalculatePopupWindowPosition = _user32.lookupFunction<
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
        Pointer<RECT> popupWindowPosition)>('CalculatePopupWindowPosition');

/// Passes the specified message and hook code to the hook procedures
/// associated with the WH_SYSMSGFILTER and WH_MSGFILTER hooks. A
/// WH_SYSMSGFILTER or WH_MSGFILTER hook procedure is an application-defined
/// callback function that examines and, optionally, modifies messages for a
/// dialog box, message box, menu, or scroll bar.
///
/// ```c
/// BOOL CallMsgFilterW(
///   LPMSG lpMsg,
///   int   nCode
/// );
/// ```
/// {@category user32}
int CallMsgFilter(Pointer<MSG> lpMsg, int nCode) =>
    _CallMsgFilter(lpMsg, nCode);

final _CallMsgFilter = _user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg, Int32 nCode),
    int Function(Pointer<MSG> lpMsg, int nCode)>('CallMsgFilterW');

/// Passes the hook information to the next hook procedure in the current
/// hook chain. A hook procedure can call this function either before or
/// after processing the hook information.
///
/// ```c
/// LRESULT CallNextHookEx(
///   HHOOK  hhk,
///   int    nCode,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int CallNextHookEx(int hhk, int nCode, int wParam, int lParam) =>
    _CallNextHookEx(hhk, nCode, wParam, lParam);

final _CallNextHookEx = _user32.lookupFunction<
    IntPtr Function(IntPtr hhk, Int32 nCode, IntPtr wParam, IntPtr lParam),
    int Function(int hhk, int nCode, int wParam, int lParam)>('CallNextHookEx');

/// Passes message information to the specified window procedure.
///
/// ```c
/// LRESULT CallWindowProcW(
///   WNDPROC lpPrevWndFunc,
///   HWND    hWnd,
///   UINT    Msg,
///   WPARAM  wParam,
///   LPARAM  lParam
/// );
/// ```
/// {@category user32}
int CallWindowProc(Pointer<NativeFunction<WindowProc>> lpPrevWndFunc, int hWnd,
        int Msg, int wParam, int lParam) =>
    _CallWindowProc(lpPrevWndFunc, hWnd, Msg, wParam, lParam);

final _CallWindowProc = _user32.lookupFunction<
    IntPtr Function(Pointer<NativeFunction<WindowProc>> lpPrevWndFunc,
        IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(Pointer<NativeFunction<WindowProc>> lpPrevWndFunc, int hWnd,
        int Msg, int wParam, int lParam)>('CallWindowProcW');

/// Cascades the specified child windows of the specified parent window.
///
/// ```c
/// WORD CascadeWindows(
///   HWND       hwndParent,
///   UINT       wHow,
///   const RECT *lpRect,
///   UINT       cKids,
///   const HWND *lpKids
/// );
/// ```
/// {@category user32}
int CascadeWindows(int hwndParent, int wHow, Pointer<RECT> lpRect, int cKids,
        Pointer<IntPtr> lpKids) =>
    _CascadeWindows(hwndParent, wHow, lpRect, cKids, lpKids);

final _CascadeWindows = _user32.lookupFunction<
    Uint16 Function(IntPtr hwndParent, Uint32 wHow, Pointer<RECT> lpRect,
        Uint32 cKids, Pointer<IntPtr> lpKids),
    int Function(int hwndParent, int wHow, Pointer<RECT> lpRect, int cKids,
        Pointer<IntPtr> lpKids)>('CascadeWindows');

/// Removes a specified window from the chain of clipboard viewers.
///
/// ```c
/// BOOL ChangeClipboardChain(
///   HWND hWndRemove,
///   HWND hWndNewNext
/// );
/// ```
/// {@category user32}
int ChangeClipboardChain(int hWndRemove, int hWndNewNext) =>
    _ChangeClipboardChain(hWndRemove, hWndNewNext);

final _ChangeClipboardChain = _user32.lookupFunction<
    Int32 Function(IntPtr hWndRemove, IntPtr hWndNewNext),
    int Function(int hWndRemove, int hWndNewNext)>('ChangeClipboardChain');

/// The ChangeDisplaySettings function changes the settings of the default
/// display device to the specified graphics mode.
///
/// ```c
/// LONG ChangeDisplaySettingsW(
///   DEVMODEW *lpDevMode,
///   DWORD    dwFlags
/// );
/// ```
/// {@category user32}
int ChangeDisplaySettings(Pointer<DEVMODE> lpDevMode, int dwFlags) =>
    _ChangeDisplaySettings(lpDevMode, dwFlags);

final _ChangeDisplaySettings = _user32.lookupFunction<
    Int32 Function(Pointer<DEVMODE> lpDevMode, Uint32 dwFlags),
    int Function(
        Pointer<DEVMODE> lpDevMode, int dwFlags)>('ChangeDisplaySettingsW');

/// The ChangeDisplaySettingsEx function changes the settings of the
/// specified display device to the specified graphics mode.
///
/// ```c
/// LONG ChangeDisplaySettingsExW(
///   LPCWSTR  lpszDeviceName,
///   DEVMODEW *lpDevMode,
///   HWND     hwnd,
///   DWORD    dwflags,
///   LPVOID   lParam
/// );
/// ```
/// {@category user32}
int ChangeDisplaySettingsEx(Pointer<Utf16> lpszDeviceName,
        Pointer<DEVMODE> lpDevMode, int hwnd, int dwflags, Pointer lParam) =>
    _ChangeDisplaySettingsEx(lpszDeviceName, lpDevMode, hwnd, dwflags, lParam);

final _ChangeDisplaySettingsEx = _user32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpszDeviceName, Pointer<DEVMODE> lpDevMode,
        IntPtr hwnd, Uint32 dwflags, Pointer lParam),
    int Function(Pointer<Utf16> lpszDeviceName, Pointer<DEVMODE> lpDevMode,
        int hwnd, int dwflags, Pointer lParam)>('ChangeDisplaySettingsExW');

/// Adds or removes a message from the User Interface Privilege Isolation
/// (UIPI) message filter.
///
/// ```c
/// BOOL ChangeWindowMessageFilter(
///   UINT  message,
///   DWORD dwFlag
/// );
/// ```
/// {@category user32}
int ChangeWindowMessageFilter(int message, int dwFlag) =>
    _ChangeWindowMessageFilter(message, dwFlag);

final _ChangeWindowMessageFilter = _user32.lookupFunction<
    Int32 Function(Uint32 message, Uint32 dwFlag),
    int Function(int message, int dwFlag)>('ChangeWindowMessageFilter');

/// Modifies the User Interface Privilege Isolation (UIPI) message filter
/// for a specified window.
///
/// ```c
/// BOOL ChangeWindowMessageFilterEx(
///   HWND                hwnd,
///   UINT                message,
///   DWORD               action,
///   PCHANGEFILTERSTRUCT pChangeFilterStruct
/// );
/// ```
/// {@category user32}
int ChangeWindowMessageFilterEx(int hwnd, int message, int action,
        Pointer<CHANGEFILTERSTRUCT> pChangeFilterStruct) =>
    _ChangeWindowMessageFilterEx(hwnd, message, action, pChangeFilterStruct);

final _ChangeWindowMessageFilterEx = _user32.lookupFunction<
        Int32 Function(IntPtr hwnd, Uint32 message, Uint32 action,
            Pointer<CHANGEFILTERSTRUCT> pChangeFilterStruct),
        int Function(int hwnd, int message, int action,
            Pointer<CHANGEFILTERSTRUCT> pChangeFilterStruct)>(
    'ChangeWindowMessageFilterEx');

/// Changes the check state of a button control.
///
/// ```c
/// BOOL CheckDlgButton(
///   HWND hDlg,
///   int  nIDButton,
///   UINT uCheck
/// );
/// ```
/// {@category user32}
int CheckDlgButton(int hDlg, int nIDButton, int uCheck) =>
    _CheckDlgButton(hDlg, nIDButton, uCheck);

final _CheckDlgButton = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Int32 nIDButton, Uint32 uCheck),
    int Function(int hDlg, int nIDButton, int uCheck)>('CheckDlgButton');

/// Adds a check mark to (checks) a specified radio button in a group and
/// removes a check mark from (clears) all other radio buttons in the group.
///
/// ```c
/// BOOL CheckRadioButton(
///   HWND hDlg,
///   int  nIDFirstButton,
///   int  nIDLastButton,
///   int  nIDCheckButton
/// );
/// ```
/// {@category user32}
int CheckRadioButton(
        int hDlg, int nIDFirstButton, int nIDLastButton, int nIDCheckButton) =>
    _CheckRadioButton(hDlg, nIDFirstButton, nIDLastButton, nIDCheckButton);

final _CheckRadioButton = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Int32 nIDFirstButton, Int32 nIDLastButton,
        Int32 nIDCheckButton),
    int Function(int hDlg, int nIDFirstButton, int nIDLastButton,
        int nIDCheckButton)>('CheckRadioButton');

/// Determines which, if any, of the child windows belonging to a parent
/// window contains the specified point. The search is restricted to
/// immediate child windows. Grandchildren, and deeper descendant windows
/// are not searched.
///
/// ```c
/// HWND ChildWindowFromPoint(
///   HWND  hWndParent,
///   POINT Point
/// );
/// ```
/// {@category user32}
int ChildWindowFromPoint(int hWndParent, POINT Point) =>
    _ChildWindowFromPoint(hWndParent, Point);

final _ChildWindowFromPoint = _user32.lookupFunction<
    IntPtr Function(IntPtr hWndParent, POINT Point),
    int Function(int hWndParent, POINT Point)>('ChildWindowFromPoint');

/// Determines which, if any, of the child windows belonging to the
/// specified parent window contains the specified point. The function can
/// ignore invisible, disabled, and transparent child windows. Grandchildren
/// and deeper descendants are not searched.
///
/// ```c
/// HWND ChildWindowFromPointEx(
///   HWND  hwnd,
///   POINT pt,
///   UINT  flags
/// );
/// ```
/// {@category user32}
int ChildWindowFromPointEx(int hwnd, POINT pt, int flags) =>
    _ChildWindowFromPointEx(hwnd, pt, flags);

final _ChildWindowFromPointEx = _user32.lookupFunction<
    IntPtr Function(IntPtr hwnd, POINT pt, Uint32 flags),
    int Function(int hwnd, POINT pt, int flags)>('ChildWindowFromPointEx');

/// The ClientToScreen function converts the client-area coordinates of a
/// specified point to screen coordinates.
///
/// ```c
/// BOOL ClientToScreen(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int ClientToScreen(int hWnd, Pointer<POINT> lpPoint) =>
    _ClientToScreen(hWnd, lpPoint);

final _ClientToScreen = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd, Pointer<POINT> lpPoint)>('ClientToScreen');

/// Confines the cursor to a rectangular area on the screen. If a subsequent
/// cursor position (set by the SetCursorPos function or the mouse) lies
/// outside the rectangle, the system automatically adjusts the position to
/// keep the cursor inside the rectangular area.
///
/// ```c
/// BOOL ClipCursor(
///   const RECT *lpRect
/// );
/// ```
/// {@category user32}
int ClipCursor(Pointer<RECT> lpRect) => _ClipCursor(lpRect);

final _ClipCursor = _user32.lookupFunction<Int32 Function(Pointer<RECT> lpRect),
    int Function(Pointer<RECT> lpRect)>('ClipCursor');

/// Closes the clipboard.
///
/// ```c
/// BOOL CloseClipboard();
/// ```
/// {@category user32}
int CloseClipboard() => _CloseClipboard();

final _CloseClipboard =
    _user32.lookupFunction<Int32 Function(), int Function()>('CloseClipboard');

/// Closes resources associated with a gesture information handle.
///
/// ```c
/// BOOL CloseGestureInfoHandle(
///   HGESTUREINFO hGestureInfo
/// );
/// ```
/// {@category user32}
int CloseGestureInfoHandle(int hGestureInfo) =>
    _CloseGestureInfoHandle(hGestureInfo);

final _CloseGestureInfoHandle = _user32.lookupFunction<
    Int32 Function(IntPtr hGestureInfo),
    int Function(int hGestureInfo)>('CloseGestureInfoHandle');

/// Closes a touch input handle, frees process memory associated with it,
/// and invalidates the handle.
///
/// ```c
/// BOOL CloseTouchInputHandle(
///   HTOUCHINPUT hTouchInput
/// );
/// ```
/// {@category user32}
int CloseTouchInputHandle(int hTouchInput) =>
    _CloseTouchInputHandle(hTouchInput);

final _CloseTouchInputHandle = _user32.lookupFunction<
    Int32 Function(IntPtr hTouchInput),
    int Function(int hTouchInput)>('CloseTouchInputHandle');

/// Minimizes (but does not destroy) the specified window.
///
/// ```c
/// BOOL CloseWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int CloseWindow(int hWnd) => _CloseWindow(hWnd);

final _CloseWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'CloseWindow');

/// Copies the specified accelerator table. This function is used to obtain
/// the accelerator-table data that corresponds to an accelerator-table
/// handle, or to determine the size of the accelerator-table data.
///
/// ```c
/// int CopyAcceleratorTableW(
///   HACCEL  hAccelSrc,
///   LPACCEL lpAccelDst,
///   int     cAccelEntries
/// );
/// ```
/// {@category user32}
int CopyAcceleratorTable(
        int hAccelSrc, Pointer<ACCEL> lpAccelDst, int cAccelEntries) =>
    _CopyAcceleratorTable(hAccelSrc, lpAccelDst, cAccelEntries);

final _CopyAcceleratorTable = _user32.lookupFunction<
    Int32 Function(
        IntPtr hAccelSrc, Pointer<ACCEL> lpAccelDst, Int32 cAccelEntries),
    int Function(int hAccelSrc, Pointer<ACCEL> lpAccelDst,
        int cAccelEntries)>('CopyAcceleratorTableW');

/// Copies the specified icon from another module to the current module.
///
/// ```c
/// HICON CopyIcon(
///   HICON hIcon
/// );
/// ```
/// {@category user32}
int CopyIcon(int hIcon) => _CopyIcon(hIcon);

final _CopyIcon = _user32.lookupFunction<IntPtr Function(IntPtr hIcon),
    int Function(int hIcon)>('CopyIcon');

/// Creates a new image (icon, cursor, or bitmap) and copies the attributes
/// of the specified image to the new one. If necessary, the function
/// stretches the bits to fit the desired size of the new image.
///
/// ```c
/// HANDLE CopyImage(
///   HANDLE h,
///   UINT   type,
///   int    cx,
///   int    cy,
///   UINT   flags
/// );
/// ```
/// {@category user32}
int CopyImage(int h, int type, int cx, int cy, int flags) =>
    _CopyImage(h, type, cx, cy, flags);

final _CopyImage = _user32.lookupFunction<
    IntPtr Function(IntPtr h, Uint32 type, Int32 cx, Int32 cy, Uint32 flags),
    int Function(int h, int type, int cx, int cy, int flags)>('CopyImage');

/// The CopyRect function copies the coordinates of one rectangle to
/// another.
///
/// ```c
/// BOOL CopyRect(
///   LPRECT     lprcDst,
///   const RECT *lprcSrc
/// );
/// ```
/// {@category user32}
int CopyRect(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc) =>
    _CopyRect(lprcDst, lprcSrc);

final _CopyRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc),
    int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc)>('CopyRect');

/// Retrieves the number of different data formats currently on the
/// clipboard.
///
/// ```c
/// int CountClipboardFormats();
/// ```
/// {@category user32}
int CountClipboardFormats() => _CountClipboardFormats();

final _CountClipboardFormats = _user32
    .lookupFunction<Int32 Function(), int Function()>('CountClipboardFormats');

/// Creates an accelerator table.
///
/// ```c
/// HACCEL CreateAcceleratorTableW(
///   LPACCEL paccel,
///   int     cAccel
/// );
/// ```
/// {@category user32}
int CreateAcceleratorTable(Pointer<ACCEL> paccel, int cAccel) =>
    _CreateAcceleratorTable(paccel, cAccel);

final _CreateAcceleratorTable = _user32.lookupFunction<
    IntPtr Function(Pointer<ACCEL> paccel, Int32 cAccel),
    int Function(Pointer<ACCEL> paccel, int cAccel)>('CreateAcceleratorTableW');

/// Creates a new desktop, associates it with the current window station of
/// the calling process, and assigns it to the calling thread. The calling
/// process must have an associated window station, either assigned by the
/// system at process creation time or set by the SetProcessWindowStation
/// function.
///
/// ```c
/// HDESK CreateDesktopW(
///   LPCWSTR               lpszDesktop,
///   LPCWSTR               lpszDevice,
///   DEVMODEW              *pDevmode,
///   DWORD                 dwFlags,
///   ACCESS_MASK           dwDesiredAccess,
///   LPSECURITY_ATTRIBUTES lpsa
/// );
/// ```
/// {@category user32}
int CreateDesktop(
        Pointer<Utf16> lpszDesktop,
        Pointer<Utf16> lpszDevice,
        Pointer<DEVMODE> pDevmode,
        int dwFlags,
        int dwDesiredAccess,
        Pointer<SECURITY_ATTRIBUTES> lpsa) =>
    _CreateDesktop(
        lpszDesktop, lpszDevice, pDevmode, dwFlags, dwDesiredAccess, lpsa);

final _CreateDesktop = _user32.lookupFunction<
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

/// Creates a new desktop with the specified heap, associates it with the
/// current window station of the calling process, and assigns it to the
/// calling thread. The calling process must have an associated window
/// station, either assigned by the system at process creation time or set
/// by the SetProcessWindowStation function.
///
/// ```c
/// HDESK CreateDesktopExW(
///   LPCWSTR               lpszDesktop,
///   LPCWSTR               lpszDevice,
///   DEVMODEW              *pDevmode,
///   DWORD                 dwFlags,
///   ACCESS_MASK           dwDesiredAccess,
///   LPSECURITY_ATTRIBUTES lpsa,
///   ULONG                 ulHeapSize,
///   PVOID                 pvoid
/// );
/// ```
/// {@category user32}
int CreateDesktopEx(
        Pointer<Utf16> lpszDesktop,
        Pointer<Utf16> lpszDevice,
        Pointer<DEVMODE> pDevmode,
        int dwFlags,
        int dwDesiredAccess,
        Pointer<SECURITY_ATTRIBUTES> lpsa,
        int ulHeapSize,
        Pointer pvoid) =>
    _CreateDesktopEx(lpszDesktop, lpszDevice, pDevmode, dwFlags,
        dwDesiredAccess, lpsa, ulHeapSize, pvoid);

final _CreateDesktopEx = _user32.lookupFunction<
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

/// Creates a modeless dialog box from a dialog box template in memory.
/// Before displaying the dialog box, the function passes an
/// application-defined value to the dialog box procedure as the lParam
/// parameter of the WM_INITDIALOG message. An application can use this
/// value to initialize dialog box controls.
///
/// ```c
/// HWND CreateDialogIndirectParamW(
///   HINSTANCE       hInstance,
///   LPCDLGTEMPLATEW lpTemplate,
///   HWND            hWndParent,
///   DLGPROC         lpDialogFunc,
///   LPARAM          dwInitParam
/// );
/// ```
/// {@category user32}
int CreateDialogIndirectParam(
        int hInstance,
        Pointer<DLGTEMPLATE> lpTemplate,
        int hWndParent,
        Pointer<NativeFunction<DlgProc>> lpDialogFunc,
        int dwInitParam) =>
    _CreateDialogIndirectParam(
        hInstance, lpTemplate, hWndParent, lpDialogFunc, dwInitParam);

final _CreateDialogIndirectParam = _user32.lookupFunction<
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

/// Creates an icon that has the specified size, colors, and bit patterns.
///
/// ```c
/// HICON CreateIcon(
///   HINSTANCE  hInstance,
///   int        nWidth,
///   int        nHeight,
///   BYTE       cPlanes,
///   BYTE       cBitsPixel,
///   const BYTE *lpbANDbits,
///   const BYTE *lpbXORbits
/// );
/// ```
/// {@category user32}
int CreateIcon(int hInstance, int nWidth, int nHeight, int cPlanes,
        int cBitsPixel, Pointer<Uint8> lpbANDbits, Pointer<Uint8> lpbXORbits) =>
    _CreateIcon(hInstance, nWidth, nHeight, cPlanes, cBitsPixel, lpbANDbits,
        lpbXORbits);

final _CreateIcon = _user32.lookupFunction<
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

/// Creates a multiple-document interface (MDI) child window.
///
/// ```c
/// HWND CreateMDIWindowW(
///   LPCWSTR   lpClassName,
///   LPCWSTR   lpWindowName,
///   DWORD     dwStyle,
///   int       X,
///   int       Y,
///   int       nWidth,
///   int       nHeight,
///   HWND      hWndParent,
///   HINSTANCE hInstance,
///   LPARAM    lParam
/// );
/// ```
/// {@category user32}
int CreateMDIWindow(
        Pointer<Utf16> lpClassName,
        Pointer<Utf16> lpWindowName,
        int dwStyle,
        int X,
        int Y,
        int nWidth,
        int nHeight,
        int hWndParent,
        int hInstance,
        int lParam) =>
    _CreateMDIWindow(lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight,
        hWndParent, hInstance, lParam);

final _CreateMDIWindow = _user32.lookupFunction<
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

/// Creates a menu. The menu is initially empty, but it can be filled with
/// menu items by using the InsertMenuItem, AppendMenu, and InsertMenu
/// functions.
///
/// ```c
/// HMENU CreateMenu();
/// ```
/// {@category user32}
int CreateMenu() => _CreateMenu();

final _CreateMenu =
    _user32.lookupFunction<IntPtr Function(), int Function()>('CreateMenu');

/// Creates an overlapped, pop-up, or child window. It specifies the window
/// class, window title, window style, and (optionally) the initial position
/// and size of the window. The function also specifies the window's parent
/// or owner, if any, and the window's menu.
///
/// ```c
/// HWND CreateWindowExW(
///   DWORD     dwExStyle,
///   LPCWSTR   lpClassName,
///   LPCWSTR   lpWindowName,
///   DWORD     dwStyle,
///   int       X,
///   int       Y,
///   int       nWidth,
///   int       nHeight,
///   HWND      hWndParent,
///   HMENU     hMenu,
///   HINSTANCE hInstance,
///   LPVOID    lpParam
/// );
/// ```
/// {@category user32}
int CreateWindowEx(
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
        Pointer lpParam) =>
    _CreateWindowEx(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth,
        nHeight, hWndParent, hMenu, hInstance, lpParam);

final _CreateWindowEx = _user32.lookupFunction<
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

/// Creates a window station object, associates it with the calling process,
/// and assigns it to the current session.
///
/// ```c
/// HWINSTA CreateWindowStationW(
///   LPCWSTR               lpwinsta,
///   DWORD                 dwFlags,
///   ACCESS_MASK           dwDesiredAccess,
///   LPSECURITY_ATTRIBUTES lpsa
/// );
/// ```
/// {@category user32}
int CreateWindowStation(Pointer<Utf16> lpwinsta, int dwFlags,
        int dwDesiredAccess, Pointer<SECURITY_ATTRIBUTES> lpsa) =>
    _CreateWindowStation(lpwinsta, dwFlags, dwDesiredAccess, lpsa);

final _CreateWindowStation = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpwinsta, Uint32 dwFlags,
        Uint32 dwDesiredAccess, Pointer<SECURITY_ATTRIBUTES> lpsa),
    int Function(Pointer<Utf16> lpwinsta, int dwFlags, int dwDesiredAccess,
        Pointer<SECURITY_ATTRIBUTES> lpsa)>('CreateWindowStationW');

/// Updates the specified multiple-window – position structure for the
/// specified window. The function then returns a handle to the updated
/// structure. The EndDeferWindowPos function uses the information in this
/// structure to change the position and size of a number of windows
/// simultaneously. The BeginDeferWindowPos function creates the structure.
///
/// ```c
/// HDWP DeferWindowPos(
///   HDWP hWinPosInfo,
///   HWND hWnd,
///   HWND hWndInsertAfter,
///   int  x,
///   int  y,
///   int  cx,
///   int  cy,
///   UINT uFlags
/// );
/// ```
/// {@category user32}
int DeferWindowPos(int hWinPosInfo, int hWnd, int hWndInsertAfter, int x, int y,
        int cx, int cy, int uFlags) =>
    _DeferWindowPos(hWinPosInfo, hWnd, hWndInsertAfter, x, y, cx, cy, uFlags);

final _DeferWindowPos = _user32.lookupFunction<
    IntPtr Function(IntPtr hWinPosInfo, IntPtr hWnd, IntPtr hWndInsertAfter,
        Int32 x, Int32 y, Int32 cx, Int32 cy, Uint32 uFlags),
    int Function(int hWinPosInfo, int hWnd, int hWndInsertAfter, int x, int y,
        int cx, int cy, int uFlags)>('DeferWindowPos');

/// Provides default processing for any window message that the window
/// procedure of a multiple-document interface (MDI) child window does not
/// process. A window message not processed by the window procedure must be
/// passed to the DefMDIChildProc function, not to the DefWindowProc
/// function.
///
/// ```c
/// LRESULT DefMDIChildProcW(
///   HWND   hWnd,
///   UINT   uMsg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int DefMDIChildProc(int hWnd, int uMsg, int wParam, int lParam) =>
    _DefMDIChildProc(hWnd, uMsg, wParam, lParam);

final _DefMDIChildProc = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam),
    int Function(
        int hWnd, int uMsg, int wParam, int lParam)>('DefMDIChildProcW');

/// Unlike DefWindowProcA and DefWindowProcW, this function doesn't do any
/// processing. DefRawInputProc only checks whether cbSizeHeader's value
/// corresponds to the expected size of RAWINPUTHEADER.
///
/// ```c
/// LRESULT DefRawInputProc(
///   PRAWINPUT *paRawInput,
///   INT       nInput,
///   UINT      cbSizeHeader
/// );
/// ```
/// {@category user32}
int DefRawInputProc(
        Pointer<Pointer<RAWINPUT>> paRawInput, int nInput, int cbSizeHeader) =>
    _DefRawInputProc(paRawInput, nInput, cbSizeHeader);

final _DefRawInputProc = _user32.lookupFunction<
    IntPtr Function(Pointer<Pointer<RAWINPUT>> paRawInput, Int32 nInput,
        Uint32 cbSizeHeader),
    int Function(Pointer<Pointer<RAWINPUT>> paRawInput, int nInput,
        int cbSizeHeader)>('DefRawInputProc');

/// Calls the default window procedure to provide default processing for any
/// window messages that an application does not process. This function
/// ensures that every message is processed. DefWindowProc is called with
/// the same parameters received by the window procedure.
///
/// ```c
/// LRESULT DefWindowProcW(
///   HWND   hWnd,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int DefWindowProc(int hWnd, int Msg, int wParam, int lParam) =>
    _DefWindowProc(hWnd, Msg, wParam, lParam);

final _DefWindowProc = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(int hWnd, int Msg, int wParam, int lParam)>('DefWindowProcW');

/// Deletes an item from the specified menu. If the menu item opens a menu
/// or submenu, this function destroys the handle to the menu or submenu and
/// frees the memory used by the menu or submenu.
///
/// ```c
/// BOOL DeleteMenu(
///   HMENU hMenu,
///   UINT  uPosition,
///   UINT  uFlags
/// );
/// ```
/// {@category user32}
int DeleteMenu(int hMenu, int uPosition, int uFlags) =>
    _DeleteMenu(hMenu, uPosition, uFlags);

final _DeleteMenu = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags),
    int Function(int hMenu, int uPosition, int uFlags)>('DeleteMenu');

/// Destroys a cursor and frees any memory the cursor occupied. Do not use
/// this function to destroy a shared cursor.
///
/// ```c
/// BOOL DestroyCursor(
///   HCURSOR hCursor
/// );
/// ```
/// {@category user32}
int DestroyCursor(int hCursor) => _DestroyCursor(hCursor);

final _DestroyCursor = _user32.lookupFunction<Int32 Function(IntPtr hCursor),
    int Function(int hCursor)>('DestroyCursor');

/// Destroys an icon and frees any memory the icon occupied.
///
/// ```c
/// BOOL DestroyIcon(
///   HICON hIcon
/// );
/// ```
/// {@category user32}
int DestroyIcon(int hIcon) => _DestroyIcon(hIcon);

final _DestroyIcon = _user32.lookupFunction<Int32 Function(IntPtr hIcon),
    int Function(int hIcon)>('DestroyIcon');

/// Destroys the specified menu and frees any memory that the menu occupies.
///
/// ```c
/// BOOL DestroyMenu(
///   HMENU hMenu
/// );
/// ```
/// {@category user32}
int DestroyMenu(int hMenu) => _DestroyMenu(hMenu);

final _DestroyMenu = _user32.lookupFunction<Int32 Function(IntPtr hMenu),
    int Function(int hMenu)>('DestroyMenu');

/// Destroys the specified window. The function sends WM_DESTROY and
/// WM_NCDESTROY messages to the window to deactivate it and remove the
/// keyboard focus from it. The function also destroys the window's menu,
/// flushes the thread message queue, destroys timers, removes clipboard
/// ownership, and breaks the clipboard viewer chain (if the window is at
/// the top of the viewer chain).
///
/// ```c
/// BOOL DestroyWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int DestroyWindow(int hWnd) => _DestroyWindow(hWnd);

final _DestroyWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'DestroyWindow');

/// Creates a modal dialog box from a dialog box template in memory. Before
/// displaying the dialog box, the function passes an application-defined
/// value to the dialog box procedure as the lParam parameter of the
/// WM_INITDIALOG message. An application can use this value to initialize
/// dialog box controls.
///
/// ```c
/// INT_PTR DialogBoxIndirectParamW(
///   HINSTANCE       hInstance,
///   LPCDLGTEMPLATEW hDialogTemplate,
///   HWND            hWndParent,
///   DLGPROC         lpDialogFunc,
///   LPARAM          dwInitParam
/// );
/// ```
/// {@category user32}
int DialogBoxIndirectParam(
        int hInstance,
        Pointer<DLGTEMPLATE> hDialogTemplate,
        int hWndParent,
        Pointer<NativeFunction<DlgProc>> lpDialogFunc,
        int dwInitParam) =>
    _DialogBoxIndirectParam(
        hInstance, hDialogTemplate, hWndParent, lpDialogFunc, dwInitParam);

final _DialogBoxIndirectParam = _user32.lookupFunction<
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

/// Disables the window ghosting feature for the calling GUI process. Window
/// ghosting is a Windows Manager feature that lets the user minimize, move,
/// or close the main window of an application that is not responding.
///
/// ```c
/// void DisableProcessWindowsGhosting();
/// ```
/// {@category user32}
void DisableProcessWindowsGhosting() => _DisableProcessWindowsGhosting();

final _DisableProcessWindowsGhosting =
    _user32.lookupFunction<Void Function(), void Function()>(
        'DisableProcessWindowsGhosting');

/// Dispatches a message to a window procedure. It is typically used to
/// dispatch a message retrieved by the GetMessage function.
///
/// ```c
/// LRESULT DispatchMessageW(
///   const MSG *lpMsg
/// );
/// ```
/// {@category user32}
int DispatchMessage(Pointer<MSG> lpMsg) => _DispatchMessage(lpMsg);

final _DispatchMessage = _user32.lookupFunction<
    IntPtr Function(Pointer<MSG> lpMsg),
    int Function(Pointer<MSG> lpMsg)>('DispatchMessageW');

/// Captures the mouse and tracks its movement until the user releases the
/// left button, presses the ESC key, or moves the mouse outside the drag
/// rectangle around the specified point.
///
/// ```c
/// BOOL DragDetect(
///   HWND  hwnd,
///   POINT pt);
/// ```
/// {@category user32}
int DragDetect(int hwnd, POINT pt) => _DragDetect(hwnd, pt);

final _DragDetect = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, POINT pt),
    int Function(int hwnd, POINT pt)>('DragDetect');

/// Animates the caption of a window to indicate the opening of an icon or
/// the minimizing or maximizing of a window.
///
/// ```c
/// BOOL DrawAnimatedRects(
///   HWND       hwnd,
///   int        idAni,
///   const RECT *lprcFrom,
///   const RECT *lprcTo);
/// ```
/// {@category user32}
int DrawAnimatedRects(
        int hwnd, int idAni, Pointer<RECT> lprcFrom, Pointer<RECT> lprcTo) =>
    _DrawAnimatedRects(hwnd, idAni, lprcFrom, lprcTo);

final _DrawAnimatedRects = _user32.lookupFunction<
    Int32 Function(
        IntPtr hwnd, Int32 idAni, Pointer<RECT> lprcFrom, Pointer<RECT> lprcTo),
    int Function(int hwnd, int idAni, Pointer<RECT> lprcFrom,
        Pointer<RECT> lprcTo)>('DrawAnimatedRects');

/// The DrawCaption function draws a window caption.
///
/// ```c
/// BOOL DrawCaption(
///   HWND       hwnd,
///   HDC        hdc,
///   const RECT *lprect,
///   UINT       flags
/// );
/// ```
/// {@category user32}
int DrawCaption(int hwnd, int hdc, Pointer<RECT> lprect, int flags) =>
    _DrawCaption(hwnd, hdc, lprect, flags);

final _DrawCaption = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, IntPtr hdc, Pointer<RECT> lprect, Uint32 flags),
    int Function(
        int hwnd, int hdc, Pointer<RECT> lprect, int flags)>('DrawCaption');

/// The DrawEdge function draws one or more edges of rectangle.
///
/// ```c
/// BOOL DrawEdge(
///   HDC    hdc,
///   LPRECT qrc,
///   UINT   edge,
///   UINT   grfFlags);
/// ```
/// {@category user32}
int DrawEdge(int hdc, Pointer<RECT> qrc, int edge, int grfFlags) =>
    _DrawEdge(hdc, qrc, edge, grfFlags);

final _DrawEdge = _user32.lookupFunction<
    Int32 Function(IntPtr hdc, Pointer<RECT> qrc, Uint32 edge, Uint32 grfFlags),
    int Function(
        int hdc, Pointer<RECT> qrc, int edge, int grfFlags)>('DrawEdge');

/// The DrawFocusRect function draws a rectangle in the style used to
/// indicate that the rectangle has the focus.
///
/// ```c
/// BOOL DrawFocusRect(
///   HDC        hDC,
///   const RECT *lprc);
/// ```
/// {@category user32}
int DrawFocusRect(int hDC, Pointer<RECT> lprc) => _DrawFocusRect(hDC, lprc);

final _DrawFocusRect = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<RECT> lprc),
    int Function(int hDC, Pointer<RECT> lprc)>('DrawFocusRect');

/// The DrawFrameControl function draws a frame control of the specified
/// type and style.
///
/// ```c
/// BOOL DrawFrameControl(
///   HDC    ,
///   LPRECT ,
///   UINT   ,
///   UINT);
/// ```
/// {@category user32}
int DrawFrameControl(
        int param0, Pointer<RECT> param1, int param2, int param3) =>
    _DrawFrameControl(param0, param1, param2, param3);

final _DrawFrameControl = _user32.lookupFunction<
    Int32 Function(
        IntPtr param0, Pointer<RECT> param1, Uint32 param2, Uint32 param3),
    int Function(int param0, Pointer<RECT> param1, int param2,
        int param3)>('DrawFrameControl');

/// Draws an icon or cursor into the specified device context.
///
/// ```c
/// BOOL DrawIcon(
///   HDC   hDC,
///   int   X,
///   int   Y,
///   HICON hIcon
/// );
/// ```
/// {@category user32}
int DrawIcon(int hDC, int X, int Y, int hIcon) => _DrawIcon(hDC, X, Y, hIcon);

final _DrawIcon = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Int32 X, Int32 Y, IntPtr hIcon),
    int Function(int hDC, int X, int Y, int hIcon)>('DrawIcon');

/// The DrawState function displays an image and applies a visual effect to
/// indicate a state, such as a disabled or default state.
///
/// ```c
/// BOOL DrawStateW(
///   HDC           hdc,
///   HBRUSH        hbrFore,
///   DRAWSTATEPROC qfnCallBack,
///   LPARAM        lData,
///   WPARAM        wData,
///   int           x,
///   int           y,
///   int           cx,
///   int           cy,
///   UINT          uFlags);
/// ```
/// {@category user32}
int DrawState(
        int hdc,
        int hbrFore,
        Pointer<NativeFunction<DrawStateProc>> qfnCallBack,
        int lData,
        int wData,
        int x,
        int y,
        int cx,
        int cy,
        int uFlags) =>
    _DrawState(hdc, hbrFore, qfnCallBack, lData, wData, x, y, cx, cy, uFlags);

final _DrawState = _user32.lookupFunction<
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

/// The DrawText function draws formatted text in the specified rectangle.
/// It formats the text according to the specified method (expanding tabs,
/// justifying characters, breaking lines, and so forth).
///
/// ```c
/// int DrawTextW(
///   HDC     hdc,
///   LPCWSTR lpchText,
///   int     cchText,
///   LPRECT  lprc,
///   UINT    format
/// );
/// ```
/// {@category user32}
int DrawText(int hdc, Pointer<Utf16> lpchText, int cchText, Pointer<RECT> lprc,
        int format) =>
    _DrawText(hdc, lpchText, cchText, lprc, format);

final _DrawText = _user32.lookupFunction<
    Int32 Function(IntPtr hdc, Pointer<Utf16> lpchText, Int32 cchText,
        Pointer<RECT> lprc, Uint32 format),
    int Function(int hdc, Pointer<Utf16> lpchText, int cchText,
        Pointer<RECT> lprc, int format)>('DrawTextW');

/// The DrawTextEx function draws formatted text in the specified rectangle.
///
/// ```c
/// int DrawTextExW(
///   HDC              hdc,
///   LPWSTR           lpchText,
///   int              cchText,
///   LPRECT           lprc,
///   UINT             format,
///   LPDRAWTEXTPARAMS lpdtp
/// );
/// ```
/// {@category user32}
int DrawTextEx(int hdc, Pointer<Utf16> lpchText, int cchText,
        Pointer<RECT> lprc, int format, Pointer<DRAWTEXTPARAMS> lpdtp) =>
    _DrawTextEx(hdc, lpchText, cchText, lprc, format, lpdtp);

final _DrawTextEx = _user32.lookupFunction<
    Int32 Function(IntPtr hdc, Pointer<Utf16> lpchText, Int32 cchText,
        Pointer<RECT> lprc, Uint32 format, Pointer<DRAWTEXTPARAMS> lpdtp),
    int Function(
        int hdc,
        Pointer<Utf16> lpchText,
        int cchText,
        Pointer<RECT> lprc,
        int format,
        Pointer<DRAWTEXTPARAMS> lpdtp)>('DrawTextExW');

/// Empties the clipboard and frees handles to data in the clipboard. The
/// function then assigns ownership of the clipboard to the window that
/// currently has the clipboard open.
///
/// ```c
/// BOOL EmptyClipboard();
/// ```
/// {@category user32}
int EmptyClipboard() => _EmptyClipboard();

final _EmptyClipboard =
    _user32.lookupFunction<Int32 Function(), int Function()>('EmptyClipboard');

/// Enables, disables, or grays the specified menu item.
///
/// ```c
/// BOOL EnableMenuItem(
///   HMENU hMenu,
///   UINT  uIDEnableItem,
///   UINT  uEnable
/// );
/// ```
/// {@category user32}
int EnableMenuItem(int hMenu, int uIDEnableItem, int uEnable) =>
    _EnableMenuItem(hMenu, uIDEnableItem, uEnable);

final _EnableMenuItem = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uIDEnableItem, Uint32 uEnable),
    int Function(int hMenu, int uIDEnableItem, int uEnable)>('EnableMenuItem');

/// Enables the mouse to act as a pointer input device and send WM_POINTER
/// messages.
///
/// ```c
/// BOOL EnableMouseInPointer(
///   [in] BOOL fEnable
/// );
/// ```
/// {@category user32}
int EnableMouseInPointer(int fEnable) => _EnableMouseInPointer(fEnable);

final _EnableMouseInPointer = _user32.lookupFunction<
    Int32 Function(Int32 fEnable),
    int Function(int fEnable)>('EnableMouseInPointer');

/// In high-DPI displays, enables automatic display scaling of the
/// non-client area portions of the specified top-level window. Must be
/// called during the initialization of that window.
///
/// ```c
/// BOOL EnableNonClientDpiScaling(
///   HWND hwnd
/// );
/// ```
/// {@category user32}
int EnableNonClientDpiScaling(int hwnd) => _EnableNonClientDpiScaling(hwnd);

final _EnableNonClientDpiScaling =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'EnableNonClientDpiScaling');

/// The EnableScrollBar function enables or disables one or both scroll bar
/// arrows.
///
/// ```c
/// BOOL EnableScrollBar(
///   HWND hWnd,
///   UINT wSBflags,
///   UINT wArrows
/// );
/// ```
/// {@category user32}
int EnableScrollBar(int hWnd, int wSBflags, int wArrows) =>
    _EnableScrollBar(hWnd, wSBflags, wArrows);

final _EnableScrollBar = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 wSBflags, Uint32 wArrows),
    int Function(int hWnd, int wSBflags, int wArrows)>('EnableScrollBar');

/// Enables or disables mouse and keyboard input to the specified window or
/// control. When input is disabled, the window does not receive input such
/// as mouse clicks and key presses. When input is enabled, the window
/// receives all input.
///
/// ```c
/// BOOL EnableWindow(
///   HWND hWnd,
///   BOOL bEnable
/// );
/// ```
/// {@category user32}
int EnableWindow(int hWnd, int bEnable) => _EnableWindow(hWnd, bEnable);

final _EnableWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 bEnable),
    int Function(int hWnd, int bEnable)>('EnableWindow');

/// Simultaneously updates the position and size of one or more windows in a
/// single screen-refreshing cycle.
///
/// ```c
/// BOOL EndDeferWindowPos(
///   HDWP hWinPosInfo
/// );
/// ```
/// {@category user32}
int EndDeferWindowPos(int hWinPosInfo) => _EndDeferWindowPos(hWinPosInfo);

final _EndDeferWindowPos = _user32.lookupFunction<
    Int32 Function(IntPtr hWinPosInfo),
    int Function(int hWinPosInfo)>('EndDeferWindowPos');

/// Destroys a modal dialog box, causing the system to end any processing
/// for the dialog box.
///
/// ```c
/// BOOL EndDialog(
///   HWND    hDlg,
///   INT_PTR nResult
/// );
/// ```
/// {@category user32}
int EndDialog(int hDlg, int nResult) => _EndDialog(hDlg, nResult);

final _EndDialog = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, IntPtr nResult),
    int Function(int hDlg, int nResult)>('EndDialog');

/// Ends the calling thread's active menu.
///
/// ```c
/// BOOL EndMenu();
/// ```
/// {@category user32}
int EndMenu() => _EndMenu();

final _EndMenu =
    _user32.lookupFunction<Int32 Function(), int Function()>('EndMenu');

/// The EndPaint function marks the end of painting in the specified window.
/// This function is required for each call to the BeginPaint function, but
/// only after painting is complete.
///
/// ```c
/// BOOL EndPaint(
///   HWND              hWnd,
///   const PAINTSTRUCT *lpPaint
/// );
/// ```
/// {@category user32}
int EndPaint(int hWnd, Pointer<PAINTSTRUCT> lpPaint) =>
    _EndPaint(hWnd, lpPaint);

final _EndPaint = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<PAINTSTRUCT> lpPaint),
    int Function(int hWnd, Pointer<PAINTSTRUCT> lpPaint)>('EndPaint');

/// Enumerates the child windows that belong to the specified parent window
/// by passing the handle to each child window, in turn, to an
/// application-defined callback function. EnumChildWindows continues until
/// the last child window is enumerated or the callback function returns
/// FALSE.
///
/// ```c
/// BOOL EnumChildWindows(
///   HWND        hWndParent,
///   WNDENUMPROC lpEnumFunc,
///   LPARAM      lParam
/// );
/// ```
/// {@category user32}
int EnumChildWindows(int hWndParent,
        Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc, int lParam) =>
    _EnumChildWindows(hWndParent, lpEnumFunc, lParam);

final _EnumChildWindows = _user32.lookupFunction<
    Int32 Function(IntPtr hWndParent,
        Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc, IntPtr lParam),
    int Function(
        int hWndParent,
        Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
        int lParam)>('EnumChildWindows');

/// Enumerates the data formats currently available on the clipboard.
///
/// ```c
/// UINT EnumClipboardFormats(
///   UINT format
/// );
/// ```
/// {@category user32}
int EnumClipboardFormats(int format) => _EnumClipboardFormats(format);

final _EnumClipboardFormats = _user32.lookupFunction<
    Uint32 Function(Uint32 format),
    int Function(int format)>('EnumClipboardFormats');

/// Enumerates all top-level windows associated with the specified desktop.
/// It passes the handle to each window, in turn, to an application-defined
/// callback function.
///
/// ```c
/// BOOL EnumDesktopWindows(
///   HDESK       hDesktop,
///   WNDENUMPROC lpfn,
///   LPARAM      lParam
/// );
/// ```
/// {@category user32}
int EnumDesktopWindows(int hDesktop,
        Pointer<NativeFunction<EnumWindowsProc>> lpfn, int lParam) =>
    _EnumDesktopWindows(hDesktop, lpfn, lParam);

final _EnumDesktopWindows = _user32.lookupFunction<
    Int32 Function(IntPtr hDesktop,
        Pointer<NativeFunction<EnumWindowsProc>> lpfn, IntPtr lParam),
    int Function(int hDesktop, Pointer<NativeFunction<EnumWindowsProc>> lpfn,
        int lParam)>('EnumDesktopWindows');

/// The EnumDisplayMonitors function enumerates display monitors (including
/// invisible pseudo-monitors associated with the mirroring drivers) that
/// intersect a region formed by the intersection of a specified clipping
/// rectangle and the visible region of a device context.
/// EnumDisplayMonitors calls an application-defined MonitorEnumProc
/// callback function once for each monitor that is enumerated. Note that
/// GetSystemMetrics (SM_CMONITORS) counts only the display monitors.
///
/// ```c
/// BOOL EnumDisplayMonitors(
///   HDC             hdc,
///   LPCRECT         lprcClip,
///   MONITORENUMPROC lpfnEnum,
///   LPARAM          dwData
/// );
/// ```
/// {@category user32}
int EnumDisplayMonitors(int hdc, Pointer<RECT> lprcClip,
        Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum, int dwData) =>
    _EnumDisplayMonitors(hdc, lprcClip, lpfnEnum, dwData);

final _EnumDisplayMonitors = _user32.lookupFunction<
    Int32 Function(IntPtr hdc, Pointer<RECT> lprcClip,
        Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum, IntPtr dwData),
    int Function(
        int hdc,
        Pointer<RECT> lprcClip,
        Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum,
        int dwData)>('EnumDisplayMonitors');

/// Enumerates all nonchild windows associated with a thread by passing the
/// handle to each window, in turn, to an application-defined callback
/// function. EnumThreadWindows continues until the last window is
/// enumerated or the callback function returns FALSE.
///
/// ```c
/// BOOL EnumThreadWindows(
///   DWORD       dwThreadId,
///   WNDENUMPROC lpfn,
///   LPARAM      lParam
/// );
/// ```
/// {@category user32}
int EnumThreadWindows(int dwThreadId,
        Pointer<NativeFunction<EnumWindowsProc>> lpfn, int lParam) =>
    _EnumThreadWindows(dwThreadId, lpfn, lParam);

final _EnumThreadWindows = _user32.lookupFunction<
    Int32 Function(Uint32 dwThreadId,
        Pointer<NativeFunction<EnumWindowsProc>> lpfn, IntPtr lParam),
    int Function(int dwThreadId, Pointer<NativeFunction<EnumWindowsProc>> lpfn,
        int lParam)>('EnumThreadWindows');

/// Enumerates all top-level windows on the screen by passing the handle to
/// each window, in turn, to an application-defined callback function.
/// EnumWindows continues until the last top-level window is enumerated or
/// the callback function returns FALSE.
///
/// ```c
/// BOOL EnumWindows(
///   WNDENUMPROC lpEnumFunc,
///   LPARAM      lParam
/// );
/// ```
/// {@category user32}
int EnumWindows(
        Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc, int lParam) =>
    _EnumWindows(lpEnumFunc, lParam);

final _EnumWindows = _user32.lookupFunction<
    Int32 Function(
        Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc, IntPtr lParam),
    int Function(Pointer<NativeFunction<EnumWindowsProc>> lpEnumFunc,
        int lParam)>('EnumWindows');

/// The EqualRect function determines whether the two specified rectangles
/// are equal by comparing the coordinates of their upper-left and
/// lower-right corners.
///
/// ```c
/// BOOL EqualRect(
///   const RECT *lprc1,
///   const RECT *lprc2
/// );
/// ```
/// {@category user32}
int EqualRect(Pointer<RECT> lprc1, Pointer<RECT> lprc2) =>
    _EqualRect(lprc1, lprc2);

final _EqualRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprc1, Pointer<RECT> lprc2),
    int Function(Pointer<RECT> lprc1, Pointer<RECT> lprc2)>('EqualRect');

/// The ExcludeUpdateRgn function prevents drawing within invalid areas of a
/// window by excluding an updated region in the window from a clipping
/// region.
///
/// ```c
/// int ExcludeUpdateRgn(
///   HDC  hDC,
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int ExcludeUpdateRgn(int hDC, int hWnd) => _ExcludeUpdateRgn(hDC, hWnd);

final _ExcludeUpdateRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, IntPtr hWnd),
    int Function(int hDC, int hWnd)>('ExcludeUpdateRgn');

/// The FillRect function fills a rectangle by using the specified brush.
/// This function includes the left and top borders, but excludes the right
/// and bottom borders of the rectangle.
///
/// ```c
/// int FillRect(
///   HDC        hDC,
///   const RECT *lprc,
///   HBRUSH     hbr
/// );
/// ```
/// {@category user32}
int FillRect(int hDC, Pointer<RECT> lprc, int hbr) => _FillRect(hDC, lprc, hbr);

final _FillRect = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<RECT> lprc, IntPtr hbr),
    int Function(int hDC, Pointer<RECT> lprc, int hbr)>('FillRect');

/// Retrieves a handle to the top-level window whose class name and window
/// name match the specified strings. This function does not search child
/// windows. This function does not perform a case-sensitive search.
///
/// ```c
/// HWND FindWindowW(
///   LPCWSTR lpClassName,
///   LPCWSTR lpWindowName
/// );
/// ```
/// {@category user32}
int FindWindow(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName) =>
    _FindWindow(lpClassName, lpWindowName);

final _FindWindow = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName),
    int Function(Pointer<Utf16> lpClassName,
        Pointer<Utf16> lpWindowName)>('FindWindowW');

/// Retrieves a handle to a window whose class name and window name match
/// the specified strings. The function searches child windows, beginning
/// with the one following the specified child window. This function does
/// not perform a case-sensitive search.
///
/// ```c
/// HWND FindWindowExW(
///   HWND    hWndParent,
///   HWND    hWndChildAfter,
///   LPCWSTR lpszClass,
///   LPCWSTR lpszWindow
/// );
/// ```
/// {@category user32}
int FindWindowEx(int hWndParent, int hWndChildAfter, Pointer<Utf16> lpszClass,
        Pointer<Utf16> lpszWindow) =>
    _FindWindowEx(hWndParent, hWndChildAfter, lpszClass, lpszWindow);

final _FindWindowEx = _user32.lookupFunction<
    IntPtr Function(IntPtr hWndParent, IntPtr hWndChildAfter,
        Pointer<Utf16> lpszClass, Pointer<Utf16> lpszWindow),
    int Function(int hWndParent, int hWndChildAfter, Pointer<Utf16> lpszClass,
        Pointer<Utf16> lpszWindow)>('FindWindowExW');

/// The FrameRect function draws a border around the specified rectangle by
/// using the specified brush. The width and height of the border are always
/// one logical unit.
///
/// ```c
/// int FrameRect(
///   HDC        hDC,
///   const RECT *lprc,
///   HBRUSH     hbr
/// );
/// ```
/// {@category user32}
int FrameRect(int hDC, Pointer<RECT> lprc, int hbr) =>
    _FrameRect(hDC, lprc, hbr);

final _FrameRect = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<RECT> lprc, IntPtr hbr),
    int Function(int hDC, Pointer<RECT> lprc, int hbr)>('FrameRect');

/// Retrieves the window handle to the active window attached to the calling
/// thread's message queue.
///
/// ```c
/// HWND GetActiveWindow();
/// ```
/// {@category user32}
int GetActiveWindow() => _GetActiveWindow();

final _GetActiveWindow = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetActiveWindow');

/// Retrieves status information for the specified window if it is the
/// application-switching (ALT+TAB) window.
///
/// ```c
/// BOOL GetAltTabInfoW(
///   [in, optional]  HWND        hwnd,
///   [in]            int         iItem,
///   [in, out]       PALTTABINFO pati,
///   [out, optional] LPWSTR      pszItemText,
///   [in]            UINT        cchItemText
/// );
/// ```
/// {@category user32}
int GetAltTabInfo(int hwnd, int iItem, Pointer<ALTTABINFO> pati,
        Pointer<Utf16> pszItemText, int cchItemText) =>
    _GetAltTabInfo(hwnd, iItem, pati, pszItemText, cchItemText);

final _GetAltTabInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Int32 iItem, Pointer<ALTTABINFO> pati,
        Pointer<Utf16> pszItemText, Uint32 cchItemText),
    int Function(int hwnd, int iItem, Pointer<ALTTABINFO> pati,
        Pointer<Utf16> pszItemText, int cchItemText)>('GetAltTabInfoW');

/// Retrieves the handle to the ancestor of the specified window.
///
/// ```c
/// HWND GetAncestor(
///   HWND hwnd,
///   UINT gaFlags
/// );
/// ```
/// {@category user32}
int GetAncestor(int hwnd, int gaFlags) => _GetAncestor(hwnd, gaFlags);

final _GetAncestor = _user32.lookupFunction<
    IntPtr Function(IntPtr hwnd, Uint32 gaFlags),
    int Function(int hwnd, int gaFlags)>('GetAncestor');

/// Determines whether a key is up or down at the time the function is
/// called, and whether the key was pressed after a previous call to
/// GetAsyncKeyState.
///
/// ```c
/// SHORT GetAsyncKeyState(
///   int vKey
/// );
/// ```
/// {@category user32}
int GetAsyncKeyState(int vKey) => _GetAsyncKeyState(vKey);

final _GetAsyncKeyState =
    _user32.lookupFunction<Int16 Function(Int32 vKey), int Function(int vKey)>(
        'GetAsyncKeyState');

/// Retrieves the DPI_AWARENESS value from a DPI_AWARENESS_CONTEXT.
///
/// ```c
/// DPI_AWARENESS GetAwarenessFromDpiAwarenessContext(
///   DPI_AWARENESS_CONTEXT value
/// );
/// ```
/// {@category user32}
int GetAwarenessFromDpiAwarenessContext(int value) =>
    _GetAwarenessFromDpiAwarenessContext(value);

final _GetAwarenessFromDpiAwarenessContext = _user32.lookupFunction<
    Int32 Function(IntPtr value),
    int Function(int value)>('GetAwarenessFromDpiAwarenessContext');

/// Retrieves a handle to the window (if any) that has captured the mouse.
/// Only one window at a time can capture the mouse; this window receives
/// mouse input whether or not the cursor is within its borders.
///
/// ```c
/// HWND GetCapture();
/// ```
/// {@category user32}
int GetCapture() => _GetCapture();

final _GetCapture =
    _user32.lookupFunction<IntPtr Function(), int Function()>('GetCapture');

/// Retrieves the time required to invert the caret's pixels. The user can
/// set this value.
///
/// ```c
/// UINT GetCaretBlinkTime();
/// ```
/// {@category user32}
int GetCaretBlinkTime() => _GetCaretBlinkTime();

final _GetCaretBlinkTime = _user32
    .lookupFunction<Uint32 Function(), int Function()>('GetCaretBlinkTime');

/// Copies the caret's position to the specified POINT structure.
///
/// ```c
/// BOOL GetCaretPos(
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int GetCaretPos(Pointer<POINT> lpPoint) => _GetCaretPos(lpPoint);

final _GetCaretPos = _user32.lookupFunction<
    Int32 Function(Pointer<POINT> lpPoint),
    int Function(Pointer<POINT> lpPoint)>('GetCaretPos');

/// Retrieves information about a window class.
///
/// ```c
/// BOOL GetClassInfoW(
///   HINSTANCE   hInstance,
///   LPCWSTR     lpClassName,
///   LPWNDCLASSW lpWndClass
/// );
/// ```
/// {@category user32}
int GetClassInfo(int hInstance, Pointer<Utf16> lpClassName,
        Pointer<WNDCLASS> lpWndClass) =>
    _GetClassInfo(hInstance, lpClassName, lpWndClass);

final _GetClassInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hInstance, Pointer<Utf16> lpClassName,
        Pointer<WNDCLASS> lpWndClass),
    int Function(int hInstance, Pointer<Utf16> lpClassName,
        Pointer<WNDCLASS> lpWndClass)>('GetClassInfoW');

/// Retrieves information about a window class, including a handle to the
/// small icon associated with the window class. The GetClassInfo function
/// does not retrieve a handle to the small icon.
///
/// ```c
/// BOOL GetClassInfoExW(
///   HINSTANCE     hInstance,
///   LPCWSTR       lpszClass,
///   LPWNDCLASSEXW lpwcx
/// );
/// ```
/// {@category user32}
int GetClassInfoEx(
        int hInstance, Pointer<Utf16> lpszClass, Pointer<WNDCLASSEX> lpwcx) =>
    _GetClassInfoEx(hInstance, lpszClass, lpwcx);

final _GetClassInfoEx = _user32.lookupFunction<
    Int32 Function(
        IntPtr hInstance, Pointer<Utf16> lpszClass, Pointer<WNDCLASSEX> lpwcx),
    int Function(int hInstance, Pointer<Utf16> lpszClass,
        Pointer<WNDCLASSEX> lpwcx)>('GetClassInfoExW');

/// Retrieves the specified value from the WNDCLASSEX structure associated
/// with the specified window.
///
/// ```c
/// ULONG_PTR GetClassLongPtrW(
///   HWND hWnd,
///   int  nIndex
/// );
/// ```
/// {@category user32}
int GetClassLongPtr(int hWnd, int nIndex) => _GetClassLongPtr(hWnd, nIndex);

final _GetClassLongPtr = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Int32 nIndex),
    int Function(int hWnd, int nIndex)>('GetClassLongPtrW');

/// Retrieves the name of the class to which the specified window belongs.
///
/// ```c
/// int GetClassNameW(
///   [in]  HWND   hWnd,
///   [out] LPWSTR lpClassName,
///   [in]  int    nMaxCount
/// );
/// ```
/// {@category user32}
int GetClassName(int hWnd, Pointer<Utf16> lpClassName, int nMaxCount) =>
    _GetClassName(hWnd, lpClassName, nMaxCount);

final _GetClassName = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpClassName, Int32 nMaxCount),
    int Function(
        int hWnd, Pointer<Utf16> lpClassName, int nMaxCount)>('GetClassNameW');

/// Retrieves the coordinates of a window's client area. The client
/// coordinates specify the upper-left and lower-right corners of the client
/// area. Because client coordinates are relative to the upper-left corner
/// of a window's client area, the coordinates of the upper-left corner are
/// (0,0).
///
/// ```c
/// BOOL GetClientRect(
///   HWND   hWnd,
///   LPRECT lpRect
/// );
/// ```
/// {@category user32}
int GetClientRect(int hWnd, Pointer<RECT> lpRect) =>
    _GetClientRect(hWnd, lpRect);

final _GetClientRect = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
    int Function(int hWnd, Pointer<RECT> lpRect)>('GetClientRect');

/// Retrieves data from the clipboard in a specified format. The clipboard
/// must have been opened previously.
///
/// ```c
/// HANDLE GetClipboardData(
///   UINT uFormat
/// );
/// ```
/// {@category user32}
int GetClipboardData(int uFormat) => _GetClipboardData(uFormat);

final _GetClipboardData = _user32.lookupFunction<
    IntPtr Function(Uint32 uFormat),
    int Function(int uFormat)>('GetClipboardData');

/// Retrieves from the clipboard the name of the specified registered
/// format. The function copies the name to the specified buffer.
///
/// ```c
/// int GetClipboardFormatNameW(
///   UINT format,
///   LPWSTR lpszFormatName,
///   int cchMaxCount
/// );
/// ```
/// {@category user32}
int GetClipboardFormatName(
        int format, Pointer<Utf16> lpszFormatName, int cchMaxCount) =>
    _GetClipboardFormatName(format, lpszFormatName, cchMaxCount);

final _GetClipboardFormatName = _user32.lookupFunction<
    Int32 Function(
        Uint32 format, Pointer<Utf16> lpszFormatName, Int32 cchMaxCount),
    int Function(int format, Pointer<Utf16> lpszFormatName,
        int cchMaxCount)>('GetClipboardFormatNameW');

/// Retrieves the window handle of the current owner of the clipboard.
///
/// ```c
/// HWND GetClipboardOwner();
/// ```
/// {@category user32}
int GetClipboardOwner() => _GetClipboardOwner();

final _GetClipboardOwner = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetClipboardOwner');

/// Retrieves the clipboard sequence number for the current window station.
///
/// ```c
/// DWORD GetClipboardSequenceNumber();
/// ```
/// {@category user32}
int GetClipboardSequenceNumber() => _GetClipboardSequenceNumber();

final _GetClipboardSequenceNumber =
    _user32.lookupFunction<Uint32 Function(), int Function()>(
        'GetClipboardSequenceNumber');

/// Retrieves the handle to the first window in the clipboard viewer chain.
///
/// ```c
/// HWND GetClipboardViewer();
/// ```
/// {@category user32}
int GetClipboardViewer() => _GetClipboardViewer();

final _GetClipboardViewer = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetClipboardViewer');

/// Retrieves the screen coordinates of the rectangular area to which the
/// cursor is confined.
///
/// ```c
/// BOOL GetClipCursor(
///   LPRECT lpRect
/// );
/// ```
/// {@category user32}
int GetClipCursor(Pointer<RECT> lpRect) => _GetClipCursor(lpRect);

final _GetClipCursor = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lpRect),
    int Function(Pointer<RECT> lpRect)>('GetClipCursor');

/// Retrieves a handle to the current cursor.
///
/// ```c
/// HCURSOR GetCursor();
/// ```
/// {@category user32}
int GetCursor() => _GetCursor();

final _GetCursor =
    _user32.lookupFunction<IntPtr Function(), int Function()>('GetCursor');

/// Retrieves information about the global cursor.
///
/// ```c
/// BOOL GetCursorInfo(
///   PCURSORINFO pci
/// );
/// ```
/// {@category user32}
int GetCursorInfo(Pointer<CURSORINFO> pci) => _GetCursorInfo(pci);

final _GetCursorInfo = _user32.lookupFunction<
    Int32 Function(Pointer<CURSORINFO> pci),
    int Function(Pointer<CURSORINFO> pci)>('GetCursorInfo');

/// Retrieves the position of the mouse cursor, in screen coordinates.
///
/// ```c
/// BOOL GetCursorPos(
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int GetCursorPos(Pointer<POINT> lpPoint) => _GetCursorPos(lpPoint);

final _GetCursorPos = _user32.lookupFunction<
    Int32 Function(Pointer<POINT> lpPoint),
    int Function(Pointer<POINT> lpPoint)>('GetCursorPos');

/// The GetDC function retrieves a handle to a device context (DC) for the
/// client area of a specified window or for the entire screen. You can use
/// the returned handle in subsequent GDI functions to draw in the DC. The
/// device context is an opaque data structure, whose values are used
/// internally by GDI.
///
/// ```c
/// HDC GetDC(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetDC(int hWnd) => _GetDC(hWnd);

final _GetDC = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('GetDC');

/// The GetDCEx function retrieves a handle to a device context (DC) for the
/// client area of a specified window or for the entire screen. You can use
/// the returned handle in subsequent GDI functions to draw in the DC. The
/// device context is an opaque data structure, whose values are used
/// internally by GDI.
///
/// ```c
/// HDC GetDCEx(
///   HWND  hWnd,
///   HRGN  hrgnClip,
///   DWORD flags
/// );
/// ```
/// {@category user32}
int GetDCEx(int hWnd, int hrgnClip, int flags) =>
    _GetDCEx(hWnd, hrgnClip, flags);

final _GetDCEx = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, IntPtr hrgnClip, Uint32 flags),
    int Function(int hWnd, int hrgnClip, int flags)>('GetDCEx');

/// Retrieves a handle to the desktop window. The desktop window covers the
/// entire screen. The desktop window is the area on top of which other
/// windows are painted.
///
/// ```c
/// HWND GetDesktopWindow();
/// ```
/// {@category user32}
int GetDesktopWindow() => _GetDesktopWindow();

final _GetDesktopWindow = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetDesktopWindow');

/// Retrieves the system's dialog base units, which are the average width
/// and height of characters in the system font. For dialog boxes that use
/// the system font, you can use these values to convert between dialog
/// template units, as specified in dialog box templates, and pixels. For
/// dialog boxes that do not use the system font, the conversion from dialog
/// template units to pixels depends on the font used by the dialog box.
///
/// ```c
/// long GetDialogBaseUnits();
/// ```
/// {@category user32}
int GetDialogBaseUnits() => _GetDialogBaseUnits();

final _GetDialogBaseUnits = _user32
    .lookupFunction<Int32 Function(), int Function()>('GetDialogBaseUnits');

/// Retrieves and per-monitor DPI scaling behavior overrides of a child
/// window in a dialog.
///
/// ```c
/// DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS GetDialogControlDpiChangeBehavior(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetDialogControlDpiChangeBehavior(int hWnd) =>
    _GetDialogControlDpiChangeBehavior(hWnd);

final _GetDialogControlDpiChangeBehavior = _user32.lookupFunction<
    Uint32 Function(IntPtr hWnd),
    int Function(int hWnd)>('GetDialogControlDpiChangeBehavior');

/// Returns the flags that might have been set on a given dialog by an
/// earlier call to SetDialogDpiChangeBehavior. If that function was never
/// called on the dialog, the return value will be zero.
///
/// ```c
/// DIALOG_DPI_CHANGE_BEHAVIORS GetDialogDpiChangeBehavior(
///   HWND hDlg
/// );
/// ```
/// {@category user32}
int GetDialogDpiChangeBehavior(int hDlg) => _GetDialogDpiChangeBehavior(hDlg);

final _GetDialogDpiChangeBehavior = _user32.lookupFunction<
    Uint32 Function(IntPtr hDlg),
    int Function(int hDlg)>('GetDialogDpiChangeBehavior');

/// Retrieves the screen auto-rotation preferences for the current process.
///
/// ```c
/// BOOL GetDisplayAutoRotationPreferences(
///   ORIENTATION_PREFERENCE *pOrientation
/// );
/// ```
/// {@category user32}
int GetDisplayAutoRotationPreferences(Pointer<Int32> pOrientation) =>
    _GetDisplayAutoRotationPreferences(pOrientation);

final _GetDisplayAutoRotationPreferences = _user32.lookupFunction<
    Int32 Function(Pointer<Int32> pOrientation),
    int Function(
        Pointer<Int32> pOrientation)>('GetDisplayAutoRotationPreferences');

/// Retrieves a handle to a control in the specified dialog box.
///
/// ```c
/// HWND GetDlgItem(
///   HWND hDlg,
///   int  nIDDlgItem
/// );
/// ```
/// {@category user32}
int GetDlgItem(int hDlg, int nIDDlgItem) => _GetDlgItem(hDlg, nIDDlgItem);

final _GetDlgItem = _user32.lookupFunction<
    IntPtr Function(IntPtr hDlg, Int32 nIDDlgItem),
    int Function(int hDlg, int nIDDlgItem)>('GetDlgItem');

/// Translates the text of a specified control in a dialog box into an
/// integer value.
///
/// ```c
/// UINT GetDlgItemInt(
///   HWND hDlg,
///   int  nIDDlgItem,
///   BOOL *lpTranslated,
///   BOOL bSigned
/// );
/// ```
/// {@category user32}
int GetDlgItemInt(
        int hDlg, int nIDDlgItem, Pointer<Int32> lpTranslated, int bSigned) =>
    _GetDlgItemInt(hDlg, nIDDlgItem, lpTranslated, bSigned);

final _GetDlgItemInt = _user32.lookupFunction<
    Uint32 Function(IntPtr hDlg, Int32 nIDDlgItem, Pointer<Int32> lpTranslated,
        Int32 bSigned),
    int Function(int hDlg, int nIDDlgItem, Pointer<Int32> lpTranslated,
        int bSigned)>('GetDlgItemInt');

/// Retrieves the title or text associated with a control in a dialog box.
///
/// ```c
/// UINT GetDlgItemTextW(
///   HWND   hDlg,
///   int    nIDDlgItem,
///   LPWSTR lpString,
///   int    cchMax
/// );
/// ```
/// {@category user32}
int GetDlgItemText(
        int hDlg, int nIDDlgItem, Pointer<Utf16> lpString, int cchMax) =>
    _GetDlgItemText(hDlg, nIDDlgItem, lpString, cchMax);

final _GetDlgItemText = _user32.lookupFunction<
    Uint32 Function(
        IntPtr hDlg, Int32 nIDDlgItem, Pointer<Utf16> lpString, Int32 cchMax),
    int Function(int hDlg, int nIDDlgItem, Pointer<Utf16> lpString,
        int cchMax)>('GetDlgItemTextW');

/// Retrieves the current double-click time for the mouse. A double-click is
/// a series of two clicks of the mouse button, the second occurring within
/// a specified time after the first. The double-click time is the maximum
/// number of milliseconds that may occur between the first and second click
/// of a double-click. The maximum double-click time is 5000 milliseconds.
///
/// ```c
/// UINT GetDoubleClickTime();
/// ```
/// {@category user32}
int GetDoubleClickTime() => _GetDoubleClickTime();

final _GetDoubleClickTime = _user32
    .lookupFunction<Uint32 Function(), int Function()>('GetDoubleClickTime');

/// Returns the system DPI.
///
/// ```c
/// UINT GetDpiForSystem();
/// ```
/// {@category user32}
int GetDpiForSystem() => _GetDpiForSystem();

final _GetDpiForSystem = _user32
    .lookupFunction<Uint32 Function(), int Function()>('GetDpiForSystem');

/// Returns the dots per inch (dpi) value for the associated window.
///
/// ```c
/// UINT GetDpiForWindow(
///   HWND hwnd
/// );
/// ```
/// {@category user32}
int GetDpiForWindow(int hwnd) => _GetDpiForWindow(hwnd);

final _GetDpiForWindow = _user32.lookupFunction<Uint32 Function(IntPtr hwnd),
    int Function(int hwnd)>('GetDpiForWindow');

/// Retrieves the DPI from a given DPI_AWARENESS_CONTEXT handle. This
/// enables you to determine the DPI of a thread without needed to examine a
/// window created within that thread.
///
/// ```c
/// UINT GetDpiFromDpiAwarenessContext(
///   DPI_AWARENESS_CONTEXT value);
/// ```
/// {@category user32}
int GetDpiFromDpiAwarenessContext(int value) =>
    _GetDpiFromDpiAwarenessContext(value);

final _GetDpiFromDpiAwarenessContext = _user32.lookupFunction<
    Uint32 Function(IntPtr value),
    int Function(int value)>('GetDpiFromDpiAwarenessContext');

/// Retrieves the handle to the window that has the keyboard focus, if the
/// window is attached to the calling thread's message queue.
///
/// ```c
/// HWND GetFocus();
/// ```
/// {@category user32}
int GetFocus() => _GetFocus();

final _GetFocus =
    _user32.lookupFunction<IntPtr Function(), int Function()>('GetFocus');

/// Retrieves a handle to the foreground window (the window with which the
/// user is currently working). The system assigns a slightly higher
/// priority to the thread that creates the foreground window than it does
/// to other threads.
///
/// ```c
/// HWND GetForegroundWindow();
/// ```
/// {@category user32}
int GetForegroundWindow() => _GetForegroundWindow();

final _GetForegroundWindow = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetForegroundWindow');

/// Retrieves the configuration for which Windows Touch gesture messages are
/// sent from a window.
///
/// ```c
/// BOOL GetGestureConfig(
///   HWND           hwnd,
///   DWORD          dwReserved,
///   DWORD          dwFlags,
///   PUINT          pcIDs,
///   PGESTURECONFIG pGestureConfig,
///   UINT           cbSize
/// );
/// ```
/// {@category user32}
int GetGestureConfig(
        int hwnd,
        int dwReserved,
        int dwFlags,
        Pointer<Uint32> pcIDs,
        Pointer<GESTURECONFIG> pGestureConfig,
        int cbSize) =>
    _GetGestureConfig(hwnd, dwReserved, dwFlags, pcIDs, pGestureConfig, cbSize);

final _GetGestureConfig = _user32.lookupFunction<
    Int32 Function(
        IntPtr hwnd,
        Uint32 dwReserved,
        Uint32 dwFlags,
        Pointer<Uint32> pcIDs,
        Pointer<GESTURECONFIG> pGestureConfig,
        Uint32 cbSize),
    int Function(int hwnd, int dwReserved, int dwFlags, Pointer<Uint32> pcIDs,
        Pointer<GESTURECONFIG> pGestureConfig, int cbSize)>('GetGestureConfig');

/// Retrieves additional information about a gesture from its GESTUREINFO
/// handle.
///
/// ```c
/// BOOL GetGestureExtraArgs(
///   HGESTUREINFO hGestureInfo,
///   UINT         cbExtraArgs,
///   PBYTE        pExtraArgs
/// );
/// ```
/// {@category user32}
int GetGestureExtraArgs(
        int hGestureInfo, int cbExtraArgs, Pointer<Uint8> pExtraArgs) =>
    _GetGestureExtraArgs(hGestureInfo, cbExtraArgs, pExtraArgs);

final _GetGestureExtraArgs = _user32.lookupFunction<
    Int32 Function(
        IntPtr hGestureInfo, Uint32 cbExtraArgs, Pointer<Uint8> pExtraArgs),
    int Function(int hGestureInfo, int cbExtraArgs,
        Pointer<Uint8> pExtraArgs)>('GetGestureExtraArgs');

/// Retrieves a GESTUREINFO structure given a handle to the gesture
/// information.
///
/// ```c
/// BOOL GetGestureInfo(
///   HGESTUREINFO hGestureInfo,
///   PGESTUREINFO pGestureInfo
/// );
/// ```
/// {@category user32}
int GetGestureInfo(int hGestureInfo, Pointer<GESTUREINFO> pGestureInfo) =>
    _GetGestureInfo(hGestureInfo, pGestureInfo);

final _GetGestureInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hGestureInfo, Pointer<GESTUREINFO> pGestureInfo),
    int Function(
        int hGestureInfo, Pointer<GESTUREINFO> pGestureInfo)>('GetGestureInfo');

/// Retrieves information about the active window or a specified GUI thread.
///
/// ```c
/// BOOL GetGUIThreadInfo(
///   [in]      DWORD          idThread,
///   [in, out] PGUITHREADINFO pgui
/// );
/// ```
/// {@category user32}
int GetGUIThreadInfo(int idThread, Pointer<GUITHREADINFO> pgui) =>
    _GetGUIThreadInfo(idThread, pgui);

final _GetGUIThreadInfo = _user32.lookupFunction<
    Int32 Function(Uint32 idThread, Pointer<GUITHREADINFO> pgui),
    int Function(
        int idThread, Pointer<GUITHREADINFO> pgui)>('GetGUIThreadInfo');

/// Retrieves information about the specified icon or cursor.
///
/// ```c
/// BOOL GetIconInfo(
///   HICON     hIcon,
///   PICONINFO piconinfo
/// );
/// ```
/// {@category user32}
int GetIconInfo(int hIcon, Pointer<ICONINFO> piconinfo) =>
    _GetIconInfo(hIcon, piconinfo);

final _GetIconInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hIcon, Pointer<ICONINFO> piconinfo),
    int Function(int hIcon, Pointer<ICONINFO> piconinfo)>('GetIconInfo');

/// Retrieves the opacity and transparency color key of a layered window.
///
/// ```c
/// BOOL GetIconInfoExW(
///   HICON        hicon,
///   PICONINFOEXW piconinfo
/// );
/// ```
/// {@category user32}
int GetIconInfoEx(int hicon, Pointer<ICONINFOEX> piconinfo) =>
    _GetIconInfoEx(hicon, piconinfo);

final _GetIconInfoEx = _user32.lookupFunction<
    Int32 Function(IntPtr hicon, Pointer<ICONINFOEX> piconinfo),
    int Function(int hicon, Pointer<ICONINFOEX> piconinfo)>('GetIconInfoExW');

/// Determines whether there are mouse-button or keyboard messages in the
/// calling thread's message queue.
///
/// ```c
/// BOOL GetInputState();
/// ```
/// {@category user32}
int GetInputState() => _GetInputState();

final _GetInputState =
    _user32.lookupFunction<Int32 Function(), int Function()>('GetInputState');

/// Retrieves the active input locale identifier (formerly called the
/// keyboard layout).
///
/// ```c
/// HKL GetKeyboardLayout(
///   DWORD idThread
/// );
/// ```
/// {@category user32}
int GetKeyboardLayout(int idThread) => _GetKeyboardLayout(idThread);

final _GetKeyboardLayout = _user32.lookupFunction<
    IntPtr Function(Uint32 idThread),
    int Function(int idThread)>('GetKeyboardLayout');

/// Retrieves the input locale identifiers (formerly called keyboard layout
/// handles) corresponding to the current set of input locales in the
/// system. The function copies the identifiers to the specified buffer.
///
/// ```c
/// int GetKeyboardLayoutList(
///   int nBuff,
///   HKL *lpList
/// );
/// ```
/// {@category user32}
int GetKeyboardLayoutList(int nBuff, Pointer<IntPtr> lpList) =>
    _GetKeyboardLayoutList(nBuff, lpList);

final _GetKeyboardLayoutList = _user32.lookupFunction<
    Int32 Function(Int32 nBuff, Pointer<IntPtr> lpList),
    int Function(int nBuff, Pointer<IntPtr> lpList)>('GetKeyboardLayoutList');

/// Retrieves the name of the active input locale identifier (formerly
/// called the keyboard layout) for the system.
///
/// ```c
/// BOOL GetKeyboardLayoutNameW(
///   LPWSTR pwszKLID
/// );
/// ```
/// {@category user32}
int GetKeyboardLayoutName(Pointer<Utf16> pwszKLID) =>
    _GetKeyboardLayoutName(pwszKLID);

final _GetKeyboardLayoutName = _user32.lookupFunction<
    Int32 Function(Pointer<Utf16> pwszKLID),
    int Function(Pointer<Utf16> pwszKLID)>('GetKeyboardLayoutNameW');

/// Copies the status of the 256 virtual keys to the specified buffer.
///
/// ```c
/// BOOL GetKeyboardState(
///   PBYTE lpKeyState
/// );
/// ```
/// {@category user32}
int GetKeyboardState(Pointer<Uint8> lpKeyState) =>
    _GetKeyboardState(lpKeyState);

final _GetKeyboardState = _user32.lookupFunction<
    Int32 Function(Pointer<Uint8> lpKeyState),
    int Function(Pointer<Uint8> lpKeyState)>('GetKeyboardState');

/// Retrieves information about the current keyboard.
///
/// ```c
/// int GetKeyboardType(
///   int nTypeFlag
/// );
/// ```
/// {@category user32}
int GetKeyboardType(int nTypeFlag) => _GetKeyboardType(nTypeFlag);

final _GetKeyboardType = _user32.lookupFunction<Int32 Function(Int32 nTypeFlag),
    int Function(int nTypeFlag)>('GetKeyboardType');

/// Retrieves a string that represents the name of a key.
///
/// ```c
/// int GetKeyNameTextW(
///   LONG   lParam,
///   LPWSTR lpString,
///   int    cchSize
/// );
/// ```
/// {@category user32}
int GetKeyNameText(int lParam, Pointer<Utf16> lpString, int cchSize) =>
    _GetKeyNameText(lParam, lpString, cchSize);

final _GetKeyNameText = _user32.lookupFunction<
    Int32 Function(Int32 lParam, Pointer<Utf16> lpString, Int32 cchSize),
    int Function(
        int lParam, Pointer<Utf16> lpString, int cchSize)>('GetKeyNameTextW');

/// Retrieves the status of the specified virtual key. The status specifies
/// whether the key is up, down, or toggled (on, off—alternating each time
/// the key is pressed).
///
/// ```c
/// SHORT GetKeyState(
///   int nVirtKey
/// );
/// ```
/// {@category user32}
int GetKeyState(int nVirtKey) => _GetKeyState(nVirtKey);

final _GetKeyState = _user32.lookupFunction<Int16 Function(Int32 nVirtKey),
    int Function(int nVirtKey)>('GetKeyState');

/// Retrieves the time of the last input event.
///
/// ```c
/// BOOL GetLastInputInfo(
///   PLASTINPUTINFO plii
/// );
/// ```
/// {@category user32}
int GetLastInputInfo(Pointer<LASTINPUTINFO> plii) => _GetLastInputInfo(plii);

final _GetLastInputInfo = _user32.lookupFunction<
    Int32 Function(Pointer<LASTINPUTINFO> plii),
    int Function(Pointer<LASTINPUTINFO> plii)>('GetLastInputInfo');

/// Retrieves the opacity and transparency color key of a layered window.
///
/// ```c
/// BOOL GetLayeredWindowAttributes(
///   HWND     hwnd,
///   COLORREF *pcrKey,
///   BYTE     *pbAlpha,
///   DWORD    *pdwFlags
/// );
/// ```
/// {@category user32}
int GetLayeredWindowAttributes(int hwnd, Pointer<Uint32> pcrKey,
        Pointer<Uint8> pbAlpha, Pointer<Uint32> pdwFlags) =>
    _GetLayeredWindowAttributes(hwnd, pcrKey, pbAlpha, pdwFlags);

final _GetLayeredWindowAttributes = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<Uint32> pcrKey, Pointer<Uint8> pbAlpha,
        Pointer<Uint32> pdwFlags),
    int Function(int hwnd, Pointer<Uint32> pcrKey, Pointer<Uint8> pbAlpha,
        Pointer<Uint32> pdwFlags)>('GetLayeredWindowAttributes');

/// Retrieves a handle to the menu assigned to the specified window.
///
/// ```c
/// HMENU GetMenu(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetMenu(int hWnd) => _GetMenu(hWnd);

final _GetMenu = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('GetMenu');

/// Retrieves information about a specified menu.
///
/// ```c
/// HMENU GetMenuInfo(
///   HMENU hMenu,
///   LPMENUINFO lpMenuInfo
/// );
/// ```
/// {@category user32}
int GetMenuInfo(int param0, Pointer<MENUINFO> param1) =>
    _GetMenuInfo(param0, param1);

final _GetMenuInfo = _user32.lookupFunction<
    Int32 Function(IntPtr param0, Pointer<MENUINFO> param1),
    int Function(int param0, Pointer<MENUINFO> param1)>('GetMenuInfo');

/// Determines the number of items in the specified menu.
///
/// ```c
/// int GetMenuItemCount(
///   HMENU hMenu
/// );
/// ```
/// {@category user32}
int GetMenuItemCount(int hMenu) => _GetMenuItemCount(hMenu);

final _GetMenuItemCount = _user32.lookupFunction<Int32 Function(IntPtr hMenu),
    int Function(int hMenu)>('GetMenuItemCount');

/// Retrieves information about a menu item.
///
/// ```c
/// BOOL GetMenuItemInfoW(
///   HMENU           hmenu,
///   UINT            item,
///   BOOL            fByPosition,
///   LPMENUITEMINFOW lpmii
/// );
/// ```
/// {@category user32}
int GetMenuItemInfo(
        int hmenu, int item, int fByPosition, Pointer<MENUITEMINFO> lpmii) =>
    _GetMenuItemInfo(hmenu, item, fByPosition, lpmii);

final _GetMenuItemInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPosition,
        Pointer<MENUITEMINFO> lpmii),
    int Function(int hmenu, int item, int fByPosition,
        Pointer<MENUITEMINFO> lpmii)>('GetMenuItemInfoW');

/// Retrieves the bounding rectangle for the specified menu item.
///
/// ```c
/// BOOL GetMenuItemRect(
///   HWND   hWnd,
///   HMENU  hMenu,
///   UINT   uItem,
///   LPRECT lprcItem
/// );
/// ```
/// {@category user32}
int GetMenuItemRect(int hWnd, int hMenu, int uItem, Pointer<RECT> lprcItem) =>
    _GetMenuItemRect(hWnd, hMenu, uItem, lprcItem);

final _GetMenuItemRect = _user32.lookupFunction<
    Int32 Function(
        IntPtr hWnd, IntPtr hMenu, Uint32 uItem, Pointer<RECT> lprcItem),
    int Function(int hWnd, int hMenu, int uItem,
        Pointer<RECT> lprcItem)>('GetMenuItemRect');

/// Retrieves the menu flags associated with the specified menu item. If the
/// menu item opens a submenu, this function also returns the number of
/// items in the submenu.
///
/// ```c
/// UINT GetMenuState(
///   HMENU hMenu,
///   UINT  uId,
///   UINT  uFlags
/// );
/// ```
/// {@category user32}
int GetMenuState(int hMenu, int uId, int uFlags) =>
    _GetMenuState(hMenu, uId, uFlags);

final _GetMenuState = _user32.lookupFunction<
    Uint32 Function(IntPtr hMenu, Uint32 uId, Uint32 uFlags),
    int Function(int hMenu, int uId, int uFlags)>('GetMenuState');

/// Copies the text string of the specified menu item into the specified
/// buffer.
///
/// ```c
/// int GetMenuStringW(
///   HMENU  hMenu,
///   UINT   uIDItem,
///   LPWSTR lpString,
///   int    cchMax,
///   UINT   flags
/// );
/// ```
/// {@category user32}
int GetMenuString(int hMenu, int uIDItem, Pointer<Utf16> lpString, int cchMax,
        int flags) =>
    _GetMenuString(hMenu, uIDItem, lpString, cchMax, flags);

final _GetMenuString = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uIDItem, Pointer<Utf16> lpString,
        Int32 cchMax, Uint32 flags),
    int Function(int hMenu, int uIDItem, Pointer<Utf16> lpString, int cchMax,
        int flags)>('GetMenuStringW');

/// Retrieves a message from the calling thread's message queue. The
/// function dispatches incoming sent messages until a posted message is
/// available for retrieval.
///
/// ```c
/// BOOL GetMessageW(
///   LPMSG lpMsg,
///   HWND  hWnd,
///   UINT  wMsgFilterMin,
///   UINT  wMsgFilterMax
/// );
/// ```
/// {@category user32}
int GetMessage(
        Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin, int wMsgFilterMax) =>
    _GetMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax);

final _GetMessage = _user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
        Uint32 wMsgFilterMax),
    int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax)>('GetMessageW');

/// Retrieves the extra message information for the current thread. Extra
/// message information is an application- or driver-defined value
/// associated with the current thread's message queue.
///
/// ```c
/// LPARAM GetMessageExtraInfo();
/// ```
/// {@category user32}
int GetMessageExtraInfo() => _GetMessageExtraInfo();

final _GetMessageExtraInfo = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetMessageExtraInfo');

/// Retrieves the cursor position for the last message retrieved by the
/// GetMessage function.
///
/// ```c
/// DWORD GetMessagePos();
/// ```
/// {@category user32}
int GetMessagePos() => _GetMessagePos();

final _GetMessagePos =
    _user32.lookupFunction<Uint32 Function(), int Function()>('GetMessagePos');

/// Retrieves the message time for the last message retrieved by the
/// GetMessage function. The time is a long integer that specifies the
/// elapsed time, in milliseconds, from the time the system was started to
/// the time the message was created (that is, placed in the thread's
/// message queue).
///
/// ```c
/// LONG GetMessageTime();
/// ```
/// {@category user32}
int GetMessageTime() => _GetMessageTime();

final _GetMessageTime =
    _user32.lookupFunction<Int32 Function(), int Function()>('GetMessageTime');

/// The GetMonitorInfo function retrieves information about a display
/// monitor.
///
/// ```c
/// BOOL GetMonitorInfoW(
///   HMONITOR      hMonitor,
///   LPMONITORINFO lpmi
/// );
/// ```
/// {@category user32}
int GetMonitorInfo(int hMonitor, Pointer<MONITORINFO> lpmi) =>
    _GetMonitorInfo(hMonitor, lpmi);

final _GetMonitorInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hMonitor, Pointer<MONITORINFO> lpmi),
    int Function(int hMonitor, Pointer<MONITORINFO> lpmi)>('GetMonitorInfoW');

/// Retrieves a history of up to 64 previous coordinates of the mouse or
/// pen.
///
/// ```c
/// int GetMouseMovePointsEx(
///   UINT             cbSize,
///   LPMOUSEMOVEPOINT lppt,
///   LPMOUSEMOVEPOINT lpptBuf,
///   int              nBufPoints,
///   DWORD            resolution
/// );
/// ```
/// {@category user32}
int GetMouseMovePointsEx(int cbSize, Pointer<MOUSEMOVEPOINT> lppt,
        Pointer<MOUSEMOVEPOINT> lpptBuf, int nBufPoints, int resolution) =>
    _GetMouseMovePointsEx(cbSize, lppt, lpptBuf, nBufPoints, resolution);

final _GetMouseMovePointsEx = _user32.lookupFunction<
    Int32 Function(Uint32 cbSize, Pointer<MOUSEMOVEPOINT> lppt,
        Pointer<MOUSEMOVEPOINT> lpptBuf, Int32 nBufPoints, Uint32 resolution),
    int Function(
        int cbSize,
        Pointer<MOUSEMOVEPOINT> lppt,
        Pointer<MOUSEMOVEPOINT> lpptBuf,
        int nBufPoints,
        int resolution)>('GetMouseMovePointsEx');

/// Retrieves a handle to the first control in a group of controls that
/// precedes (or follows) the specified control in a dialog box.
///
/// ```c
/// HWND GetNextDlgGroupItem(
///   HWND hDlg,
///   HWND hCtl,
///   BOOL bPrevious
/// );
/// ```
/// {@category user32}
int GetNextDlgGroupItem(int hDlg, int hCtl, int bPrevious) =>
    _GetNextDlgGroupItem(hDlg, hCtl, bPrevious);

final _GetNextDlgGroupItem = _user32.lookupFunction<
    IntPtr Function(IntPtr hDlg, IntPtr hCtl, Int32 bPrevious),
    int Function(int hDlg, int hCtl, int bPrevious)>('GetNextDlgGroupItem');

/// Retrieves a handle to the first control that has the WS_TABSTOP style
/// that precedes (or follows) the specified control.
///
/// ```c
/// HWND GetNextDlgTabItem(
///   HWND hDlg,
///   HWND hCtl,
///   BOOL bPrevious
/// );
/// ```
/// {@category user32}
int GetNextDlgTabItem(int hDlg, int hCtl, int bPrevious) =>
    _GetNextDlgTabItem(hDlg, hCtl, bPrevious);

final _GetNextDlgTabItem = _user32.lookupFunction<
    IntPtr Function(IntPtr hDlg, IntPtr hCtl, Int32 bPrevious),
    int Function(int hDlg, int hCtl, int bPrevious)>('GetNextDlgTabItem');

/// Retrieves the handle to the window that currently has the clipboard
/// open.
///
/// ```c
/// HWND GetOpenClipboardWindow();
/// ```
/// {@category user32}
int GetOpenClipboardWindow() => _GetOpenClipboardWindow();

final _GetOpenClipboardWindow =
    _user32.lookupFunction<IntPtr Function(), int Function()>(
        'GetOpenClipboardWindow');

/// Retrieves a handle to the specified window's parent or owner.
///
/// ```c
/// HWND GetParent(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetParent(int hWnd) => _GetParent(hWnd);

final _GetParent = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('GetParent');

/// Retrieves the position of the cursor in physical coordinates.
///
/// ```c
/// BOOL GetPhysicalCursorPos(
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int GetPhysicalCursorPos(Pointer<POINT> lpPoint) =>
    _GetPhysicalCursorPos(lpPoint);

final _GetPhysicalCursorPos = _user32.lookupFunction<
    Int32 Function(Pointer<POINT> lpPoint),
    int Function(Pointer<POINT> lpPoint)>('GetPhysicalCursorPos');

/// Retrieves the cursor identifier associated with the specified pointer.
///
/// ```c
/// BOOL GetPointerCursorId(
///   [in]  UINT32 pointerId,
///   [out] UINT32 *cursorId
/// );
/// ```
/// {@category user32}
int GetPointerCursorId(int pointerId, Pointer<Uint32> cursorId) =>
    _GetPointerCursorId(pointerId, cursorId);

final _GetPointerCursorId = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> cursorId),
    int Function(
        int pointerId, Pointer<Uint32> cursorId)>('GetPointerCursorId');

/// Gets the entire frame of information for the specified pointers
/// associated with the current message.
///
/// ```c
/// BOOL GetPointerFrameInfo(
///   [in]      UINT32       pointerId,
///   [in, out] UINT32       *pointerCount,
///   [out]     POINTER_INFO *pointerInfo
/// );
/// ```
/// {@category user32}
int GetPointerFrameInfo(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_INFO> pointerInfo) =>
    _GetPointerFrameInfo(pointerId, pointerCount, pointerInfo);

final _GetPointerFrameInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_INFO> pointerInfo),
    int Function(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_INFO> pointerInfo)>('GetPointerFrameInfo');

/// Gets the entire frame of information (including coalesced input frames)
/// for the specified pointers associated with the current message.
///
/// ```c
/// BOOL GetPointerFrameInfoHistory(
///   [in]      UINT32       pointerId,
///   [in, out] UINT32       *entriesCount,
///   [in, out] UINT32       *pointerCount,
///   [out]     POINTER_INFO *pointerInfo
/// );
/// ```
/// {@category user32}
int GetPointerFrameInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_INFO> pointerInfo) =>
    _GetPointerFrameInfoHistory(
        pointerId, entriesCount, pointerCount, pointerInfo);

final _GetPointerFrameInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_INFO> pointerInfo),
    int Function(
        int pointerId,
        Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount,
        Pointer<POINTER_INFO> pointerInfo)>('GetPointerFrameInfoHistory');

/// Gets the entire frame of pen-based information for the specified
/// pointers (of type PT_PEN) associated with the current message.
///
/// ```c
/// BOOL GetPointerFramePenInfo(
///   [in]      UINT32           pointerId,
///   [in, out] UINT32           *pointerCount,
///   [out]     POINTER_PEN_INFO *penInfo
/// );
/// ```
/// {@category user32}
int GetPointerFramePenInfo(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_PEN_INFO> penInfo) =>
    _GetPointerFramePenInfo(pointerId, pointerCount, penInfo);

final _GetPointerFramePenInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_PEN_INFO> penInfo),
    int Function(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerFramePenInfo');

/// Gets the entire frame of pen-based information (including coalesced
/// input frames) for the specified pointers (of type PT_PEN) associated
/// with the current message.
///
/// ```c
/// BOOL GetPointerFramePenInfoHistory(
///   [in]            UINT32           pointerId,
///   [in, out]       UINT32           *entriesCount,
///   [in, out]       UINT32           *pointerCount,
///   [out, optional] POINTER_PEN_INFO *penInfo
/// );
/// ```
/// {@category user32}
int GetPointerFramePenInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_PEN_INFO> penInfo) =>
    _GetPointerFramePenInfoHistory(
        pointerId, entriesCount, pointerCount, penInfo);

final _GetPointerFramePenInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_PEN_INFO> penInfo),
    int Function(
        int pointerId,
        Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount,
        Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerFramePenInfoHistory');

/// Gets the entire frame of touch-based information for the specified
/// pointers (of type PT_TOUCH) associated with the current message.
///
/// ```c
/// BOOL GetPointerFrameTouchInfo(
///   [in]      UINT32             pointerId,
///   [in, out] UINT32             *pointerCount,
///   [out]     POINTER_TOUCH_INFO *touchInfo
/// );
/// ```
/// {@category user32}
int GetPointerFrameTouchInfo(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo) =>
    _GetPointerFrameTouchInfo(pointerId, pointerCount, touchInfo);

final _GetPointerFrameTouchInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo),
    int Function(int pointerId, Pointer<Uint32> pointerCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo)>('GetPointerFrameTouchInfo');

/// Gets the entire frame of touch-based information (including coalesced
/// input frames) for the specified pointers (of type PT_TOUCH) associated
/// with the current message.
///
/// ```c
/// BOOL GetPointerFrameTouchInfoHistory(
///   [in]      UINT32             pointerId,
///   [in, out] UINT32             *entriesCount,
///   [in, out] UINT32             *pointerCount,
///   [out]     POINTER_TOUCH_INFO *touchInfo
/// );
/// ```
/// {@category user32}
int GetPointerFrameTouchInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_TOUCH_INFO> touchInfo) =>
    _GetPointerFrameTouchInfoHistory(
        pointerId, entriesCount, pointerCount, touchInfo);

final _GetPointerFrameTouchInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount, Pointer<POINTER_TOUCH_INFO> touchInfo),
    int Function(
        int pointerId,
        Pointer<Uint32> entriesCount,
        Pointer<Uint32> pointerCount,
        Pointer<POINTER_TOUCH_INFO>
            touchInfo)>('GetPointerFrameTouchInfoHistory');

/// Gets the information for the specified pointer associated with the
/// current message.
///
/// ```c
/// BOOL GetPointerInfo(
///   [in]  UINT32       pointerId,
///   [out] POINTER_INFO *pointerInfo
/// );
/// ```
/// {@category user32}
int GetPointerInfo(int pointerId, Pointer<POINTER_INFO> pointerInfo) =>
    _GetPointerInfo(pointerId, pointerInfo);

final _GetPointerInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<POINTER_INFO> pointerInfo),
    int Function(
        int pointerId, Pointer<POINTER_INFO> pointerInfo)>('GetPointerInfo');

/// Gets the information associated with the individual inputs, if any, that
/// were coalesced into the current message for the specified pointer. The
/// most recent input is included in the returned history and is the same as
/// the most recent input returned by the GetPointerInfo function.
///
/// ```c
/// BOOL GetPointerInfoHistory(
///   [in]            UINT32       pointerId,
///   [in, out]       UINT32       *entriesCount,
///   [out, optional] POINTER_INFO *pointerInfo
/// );
/// ```
/// {@category user32}
int GetPointerInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_INFO> pointerInfo) =>
    _GetPointerInfoHistory(pointerId, entriesCount, pointerInfo);

final _GetPointerInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_INFO> pointerInfo),
    int Function(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_INFO> pointerInfo)>('GetPointerInfoHistory');

/// Gets one or more transforms for the pointer information coordinates
/// associated with the current message.
///
/// ```c
/// BOOL GetPointerInputTransform(
///   [in]  UINT32          pointerId,
///   [in]  UINT32          historyCount,
///   [out] INPUT_TRANSFORM *inputTransform
/// );
/// ```
/// {@category user32}
int GetPointerInputTransform(int pointerId, int historyCount,
        Pointer<INPUT_TRANSFORM> inputTransform) =>
    _GetPointerInputTransform(pointerId, historyCount, inputTransform);

final _GetPointerInputTransform = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Uint32 historyCount,
        Pointer<INPUT_TRANSFORM> inputTransform),
    int Function(int pointerId, int historyCount,
        Pointer<INPUT_TRANSFORM> inputTransform)>('GetPointerInputTransform');

/// Gets the pen-based information for the specified pointer (of type
/// PT_PEN) associated with the current message.
///
/// ```c
/// BOOL GetPointerPenInfo(
///   [in]  UINT32           pointerId,
///   [out] POINTER_PEN_INFO *penInfo
/// );
/// ```
/// {@category user32}
int GetPointerPenInfo(int pointerId, Pointer<POINTER_PEN_INFO> penInfo) =>
    _GetPointerPenInfo(pointerId, penInfo);

final _GetPointerPenInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<POINTER_PEN_INFO> penInfo),
    int Function(
        int pointerId, Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerPenInfo');

/// Gets the pen-based information associated with the individual inputs, if
/// any, that were coalesced into the current message for the specified
/// pointer (of type PT_PEN). The most recent input is included in the
/// returned history and is the same as the most recent input returned by
/// the GetPointerPenInfo function.
///
/// ```c
/// BOOL GetPointerPenInfoHistory(
///   [in]            UINT32           pointerId,
///   [in, out]       UINT32           *entriesCount,
///   [out, optional] POINTER_PEN_INFO *penInfo
/// );
/// ```
/// {@category user32}
int GetPointerPenInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_PEN_INFO> penInfo) =>
    _GetPointerPenInfoHistory(pointerId, entriesCount, penInfo);

final _GetPointerPenInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_PEN_INFO> penInfo),
    int Function(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_PEN_INFO> penInfo)>('GetPointerPenInfoHistory');

/// Gets the touch-based information for the specified pointer (of type
/// PT_TOUCH) associated with the current message.
///
/// ```c
/// BOOL GetPointerTouchInfo(
///   [in]  UINT32             pointerId,
///   [out] POINTER_TOUCH_INFO *touchInfo
/// );
/// ```
/// {@category user32}
int GetPointerTouchInfo(int pointerId, Pointer<POINTER_TOUCH_INFO> touchInfo) =>
    _GetPointerTouchInfo(pointerId, touchInfo);

final _GetPointerTouchInfo = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<POINTER_TOUCH_INFO> touchInfo),
    int Function(int pointerId,
        Pointer<POINTER_TOUCH_INFO> touchInfo)>('GetPointerTouchInfo');

/// Gets the touch-based information associated with the individual inputs,
/// if any, that were coalesced into the current message for the specified
/// pointer (of type PT_TOUCH). The most recent input is included in the
/// returned history and is the same as the most recent input returned by
/// the GetPointerTouchInfo function.
///
/// ```c
/// BOOL GetPointerTouchInfoHistory(
///   [in]            UINT32             pointerId,
///   [in, out]       UINT32             *entriesCount,
///   [out, optional] POINTER_TOUCH_INFO *touchInfo
/// );
/// ```
/// {@category user32}
int GetPointerTouchInfoHistory(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo) =>
    _GetPointerTouchInfoHistory(pointerId, entriesCount, touchInfo);

final _GetPointerTouchInfoHistory = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo),
    int Function(int pointerId, Pointer<Uint32> entriesCount,
        Pointer<POINTER_TOUCH_INFO> touchInfo)>('GetPointerTouchInfoHistory');

/// Retrieves the pointer type for a specified pointer.
///
/// ```c
/// BOOL GetPointerType(
///   [in]  UINT32             pointerId,
///   [out] POINTER_INPUT_TYPE *pointerType
/// );
/// ```
/// {@category user32}
int GetPointerType(int pointerId, Pointer<Int32> pointerType) =>
    _GetPointerType(pointerId, pointerType);

final _GetPointerType = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId, Pointer<Int32> pointerType),
    int Function(int pointerId, Pointer<Int32> pointerType)>('GetPointerType');

/// Retrieves the first available clipboard format in the specified list.
///
/// ```c
/// int GetPriorityClipboardFormat(
///   UINT *paFormatPriorityList,
///   int  cFormats
/// );
/// ```
/// {@category user32}
int GetPriorityClipboardFormat(
        Pointer<Uint32> paFormatPriorityList, int cFormats) =>
    _GetPriorityClipboardFormat(paFormatPriorityList, cFormats);

final _GetPriorityClipboardFormat = _user32.lookupFunction<
    Int32 Function(Pointer<Uint32> paFormatPriorityList, Int32 cFormats),
    int Function(Pointer<Uint32> paFormatPriorityList,
        int cFormats)>('GetPriorityClipboardFormat');

/// Retrieves a handle to the current window station for the calling
/// process.
///
/// ```c
/// HWINSTA GetProcessWindowStation();
/// ```
/// {@category user32}
int GetProcessWindowStation() => _GetProcessWindowStation();

final _GetProcessWindowStation =
    _user32.lookupFunction<IntPtr Function(), int Function()>(
        'GetProcessWindowStation');

/// Retrieves a data handle from the property list of the specified window.
/// The character string identifies the handle to be retrieved. The string
/// and handle must have been added to the property list by a previous call
/// to the SetProp function.
///
/// ```c
/// HANDLE GetPropW(
///   HWND    hWnd,
///   LPCWSTR lpString
/// );
/// ```
/// {@category user32}
int GetProp(int hWnd, Pointer<Utf16> lpString) => _GetProp(hWnd, lpString);

final _GetProp = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Pointer<Utf16> lpString),
    int Function(int hWnd, Pointer<Utf16> lpString)>('GetPropW');

/// Performs a buffered read of the raw input messages data found in the
/// calling thread's message queue.
///
/// ```c
/// UINT GetRawInputBuffer(
///   PRAWINPUT pData,
///   PUINT     pcbSize,
///   UINT      cbSizeHeader
/// );
/// ```
/// {@category user32}
int GetRawInputBuffer(
        Pointer<RAWINPUT> pData, Pointer<Uint32> pcbSize, int cbSizeHeader) =>
    _GetRawInputBuffer(pData, pcbSize, cbSizeHeader);

final _GetRawInputBuffer = _user32.lookupFunction<
    Uint32 Function(
        Pointer<RAWINPUT> pData, Pointer<Uint32> pcbSize, Uint32 cbSizeHeader),
    int Function(Pointer<RAWINPUT> pData, Pointer<Uint32> pcbSize,
        int cbSizeHeader)>('GetRawInputBuffer');

/// Retrieves the raw input from the specified device.
///
/// ```c
/// UINT GetRawInputData(
///   HRAWINPUT hRawInput,
///   UINT      uiCommand,
///   LPVOID    pData,
///   PUINT     pcbSize,
///   UINT      cbSizeHeader
/// );
/// ```
/// {@category user32}
int GetRawInputData(int hRawInput, int uiCommand, Pointer pData,
        Pointer<Uint32> pcbSize, int cbSizeHeader) =>
    _GetRawInputData(hRawInput, uiCommand, pData, pcbSize, cbSizeHeader);

final _GetRawInputData = _user32.lookupFunction<
    Uint32 Function(IntPtr hRawInput, Uint32 uiCommand, Pointer pData,
        Pointer<Uint32> pcbSize, Uint32 cbSizeHeader),
    int Function(int hRawInput, int uiCommand, Pointer pData,
        Pointer<Uint32> pcbSize, int cbSizeHeader)>('GetRawInputData');

/// Retrieves information about the raw input device.
///
/// ```c
/// UINT GetRawInputDeviceInfoW(
///   HANDLE hDevice,
///   UINT   uiCommand,
///   LPVOID pData,
///   PUINT  pcbSize
/// );
/// ```
/// {@category user32}
int GetRawInputDeviceInfo(
        int hDevice, int uiCommand, Pointer pData, Pointer<Uint32> pcbSize) =>
    _GetRawInputDeviceInfo(hDevice, uiCommand, pData, pcbSize);

final _GetRawInputDeviceInfo = _user32.lookupFunction<
    Uint32 Function(IntPtr hDevice, Uint32 uiCommand, Pointer pData,
        Pointer<Uint32> pcbSize),
    int Function(int hDevice, int uiCommand, Pointer pData,
        Pointer<Uint32> pcbSize)>('GetRawInputDeviceInfoW');

/// Enumerates the raw input devices attached to the system.
///
/// ```c
/// UINT GetRawInputDeviceList(
///   PRAWINPUTDEVICELIST pRawInputDeviceList,
///   PUINT               puiNumDevices,
///   UINT                cbSize
/// );
/// ```
/// {@category user32}
int GetRawInputDeviceList(Pointer<RAWINPUTDEVICELIST> pRawInputDeviceList,
        Pointer<Uint32> puiNumDevices, int cbSize) =>
    _GetRawInputDeviceList(pRawInputDeviceList, puiNumDevices, cbSize);

final _GetRawInputDeviceList = _user32.lookupFunction<
    Uint32 Function(Pointer<RAWINPUTDEVICELIST> pRawInputDeviceList,
        Pointer<Uint32> puiNumDevices, Uint32 cbSize),
    int Function(Pointer<RAWINPUTDEVICELIST> pRawInputDeviceList,
        Pointer<Uint32> puiNumDevices, int cbSize)>('GetRawInputDeviceList');

/// Retrieves the information about the raw input devices for the current
/// application.
///
/// ```c
/// UINT GetRegisteredRawInputDevices(
///   PRAWINPUTDEVICE pRawInputDevices,
///   PUINT           puiNumDevices,
///   UINT            cbSize
/// );
/// ```
/// {@category user32}
int GetRegisteredRawInputDevices(Pointer<RAWINPUTDEVICE> pRawInputDevices,
        Pointer<Uint32> puiNumDevices, int cbSize) =>
    _GetRegisteredRawInputDevices(pRawInputDevices, puiNumDevices, cbSize);

final _GetRegisteredRawInputDevices = _user32.lookupFunction<
    Uint32 Function(Pointer<RAWINPUTDEVICE> pRawInputDevices,
        Pointer<Uint32> puiNumDevices, Uint32 cbSize),
    int Function(
        Pointer<RAWINPUTDEVICE> pRawInputDevices,
        Pointer<Uint32> puiNumDevices,
        int cbSize)>('GetRegisteredRawInputDevices');

/// The GetScrollBarInfo function retrieves information about the specified
/// scroll bar.
///
/// ```c
/// BOOL GetScrollBarInfo(
///   HWND           hwnd,
///   LONG           idObject,
///   PSCROLLBARINFO psbi
/// );
/// ```
/// {@category user32}
int GetScrollBarInfo(int hwnd, int idObject, Pointer<SCROLLBARINFO> psbi) =>
    _GetScrollBarInfo(hwnd, idObject, psbi);

final _GetScrollBarInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Int32 idObject, Pointer<SCROLLBARINFO> psbi),
    int Function(int hwnd, int idObject,
        Pointer<SCROLLBARINFO> psbi)>('GetScrollBarInfo');

/// The GetScrollInfo function retrieves the parameters of a scroll bar,
/// including the minimum and maximum scrolling positions, the page size,
/// and the position of the scroll box (thumb).
///
/// ```c
/// BOOL GetScrollInfo(
///   HWND         hwnd,
///   int          nBar,
///   LPSCROLLINFO lpsi
/// );
/// ```
/// {@category user32}
int GetScrollInfo(int hwnd, int nBar, Pointer<SCROLLINFO> lpsi) =>
    _GetScrollInfo(hwnd, nBar, lpsi);

final _GetScrollInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Uint32 nBar, Pointer<SCROLLINFO> lpsi),
    int Function(
        int hwnd, int nBar, Pointer<SCROLLINFO> lpsi)>('GetScrollInfo');

/// Retrieves a handle to the Shell's desktop window.
///
/// ```c
/// HWND GetShellWindow();
/// ```
/// {@category user32}
int GetShellWindow() => _GetShellWindow();

final _GetShellWindow =
    _user32.lookupFunction<IntPtr Function(), int Function()>('GetShellWindow');

/// Retrieves a handle to the drop-down menu or submenu activated by the
/// specified menu item.
///
/// ```c
/// HMENU GetSubMenu(
///   HMENU hMenu,
///   int nPos
/// );
/// ```
/// {@category user32}
int GetSubMenu(int hMenu, int nPos) => _GetSubMenu(hMenu, nPos);

final _GetSubMenu = _user32.lookupFunction<
    IntPtr Function(IntPtr hMenu, Int32 nPos),
    int Function(int hMenu, int nPos)>('GetSubMenu');

/// Retrieves the current color of the specified display element. Display
/// elements are the parts of a window and the display that appear on the
/// system display screen.
///
/// ```c
/// DWORD GetSysColor(
///   int nIndex
/// );
/// ```
/// {@category user32}
int GetSysColor(int nIndex) => _GetSysColor(nIndex);

final _GetSysColor = _user32.lookupFunction<Uint32 Function(Int32 nIndex),
    int Function(int nIndex)>('GetSysColor');

/// The GetSysColorBrush function retrieves a handle identifying a logical
/// brush that corresponds to the specified color index.
///
/// ```c
/// HBRUSH GetSysColorBrush(
///   int nIndex
/// );
/// ```
/// {@category user32}
int GetSysColorBrush(int nIndex) => _GetSysColorBrush(nIndex);

final _GetSysColorBrush = _user32.lookupFunction<IntPtr Function(Int32 nIndex),
    int Function(int nIndex)>('GetSysColorBrush');

/// Retrieves the system DPI associated with a given process. This is useful
/// for avoiding compatibility issues that arise from sharing DPI-sensitive
/// information between multiple system-aware processes with different
/// system DPI values.
///
/// ```c
/// UINT GetSystemDpiForProcess(
///   HANDLE hProcess
/// );
/// ```
/// {@category user32}
int GetSystemDpiForProcess(int hProcess) => _GetSystemDpiForProcess(hProcess);

final _GetSystemDpiForProcess = _user32.lookupFunction<
    Uint32 Function(IntPtr hProcess),
    int Function(int hProcess)>('GetSystemDpiForProcess');

/// Enables the application to access the window menu (also known as the
/// system menu or the control menu) for copying and modifying.
///
/// ```c
/// HMENU GetSystemMenu(
///   HWND hWnd,
///   BOOL bRevert
/// );
/// ```
/// {@category user32}
int GetSystemMenu(int hWnd, int bRevert) => _GetSystemMenu(hWnd, bRevert);

final _GetSystemMenu = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Int32 bRevert),
    int Function(int hWnd, int bRevert)>('GetSystemMenu');

/// Retrieves the specified system metric or system configuration setting.
/// Note that all dimensions retrieved by GetSystemMetrics are in pixels.
///
/// ```c
/// int GetSystemMetrics(
///   int nIndex
/// );
/// ```
/// {@category user32}
int GetSystemMetrics(int nIndex) => _GetSystemMetrics(nIndex);

final _GetSystemMetrics = _user32.lookupFunction<Int32 Function(Uint32 nIndex),
    int Function(int nIndex)>('GetSystemMetrics');

/// Retrieves the specified system metric or system configuration setting
/// taking into account a provided DPI.
///
/// ```c
/// int GetSystemMetricsForDpi(
///   int  nIndex,
///   UINT dpi
/// );
/// ```
/// {@category user32}
int GetSystemMetricsForDpi(int nIndex, int dpi) =>
    _GetSystemMetricsForDpi(nIndex, dpi);

final _GetSystemMetricsForDpi = _user32.lookupFunction<
    Int32 Function(Uint32 nIndex, Uint32 dpi),
    int Function(int nIndex, int dpi)>('GetSystemMetricsForDpi');

/// The GetTabbedTextExtent function computes the width and height of a
/// character string. If the string contains one or more tab characters, the
/// width of the string is based upon the specified tab stops. The
/// GetTabbedTextExtent function uses the currently selected font to compute
/// the dimensions of the string.
///
/// ```c
/// DWORD GetTabbedTextExtentW(
///   HDC       hdc,
///   LPCWSTR   lpString,
///   int       chCount,
///   int       nTabPositions,
///   const INT *lpnTabStopPositions
/// );
/// ```
/// {@category user32}
int GetTabbedTextExtent(int hdc, Pointer<Utf16> lpString, int chCount,
        int nTabPositions, Pointer<Int32> lpnTabStopPositions) =>
    _GetTabbedTextExtent(
        hdc, lpString, chCount, nTabPositions, lpnTabStopPositions);

final _GetTabbedTextExtent = _user32.lookupFunction<
    Uint32 Function(IntPtr hdc, Pointer<Utf16> lpString, Int32 chCount,
        Int32 nTabPositions, Pointer<Int32> lpnTabStopPositions),
    int Function(
        int hdc,
        Pointer<Utf16> lpString,
        int chCount,
        int nTabPositions,
        Pointer<Int32> lpnTabStopPositions)>('GetTabbedTextExtentW');

/// Retrieves a handle to the desktop assigned to the specified thread.
///
/// ```c
/// HDESK GetThreadDesktop(
///   DWORD dwThreadId
/// );
/// ```
/// {@category user32}
int GetThreadDesktop(int dwThreadId) => _GetThreadDesktop(dwThreadId);

final _GetThreadDesktop = _user32.lookupFunction<
    IntPtr Function(Uint32 dwThreadId),
    int Function(int dwThreadId)>('GetThreadDesktop');

/// Gets the DPI_AWARENESS_CONTEXT for the current thread.
///
/// ```c
/// DPI_AWARENESS_CONTEXT GetThreadDpiAwarenessContext();
/// ```
/// {@category user32}
int GetThreadDpiAwarenessContext() => _GetThreadDpiAwarenessContext();

final _GetThreadDpiAwarenessContext =
    _user32.lookupFunction<IntPtr Function(), int Function()>(
        'GetThreadDpiAwarenessContext');

/// Retrieves the DPI_HOSTING_BEHAVIOR from the current thread.
///
/// ```c
/// DPI_HOSTING_BEHAVIOR GetThreadDpiHostingBehavior();
/// ```
/// {@category user32}
int GetThreadDpiHostingBehavior() => _GetThreadDpiHostingBehavior();

final _GetThreadDpiHostingBehavior =
    _user32.lookupFunction<Int32 Function(), int Function()>(
        'GetThreadDpiHostingBehavior');

/// Retrieves information about the specified title bar.
///
/// ```c
/// BOOL GetTitleBarInfo(
///   HWND          hwnd,
///   PTITLEBARINFO pti
/// );
/// ```
/// {@category user32}
int GetTitleBarInfo(int hwnd, Pointer<TITLEBARINFO> pti) =>
    _GetTitleBarInfo(hwnd, pti);

final _GetTitleBarInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<TITLEBARINFO> pti),
    int Function(int hwnd, Pointer<TITLEBARINFO> pti)>('GetTitleBarInfo');

/// Examines the Z order of the child windows associated with the specified
/// parent window and retrieves a handle to the child window at the top of
/// the Z order.
///
/// ```c
/// HWND GetTopWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetTopWindow(int hWnd) => _GetTopWindow(hWnd);

final _GetTopWindow = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('GetTopWindow');

/// Retrieves detailed information about touch inputs associated with a
/// particular touch input handle.
///
/// ```c
/// BOOL GetTouchInputInfo(
///   HTOUCHINPUT hTouchInput,
///   UINT        cInputs,
///   PTOUCHINPUT pInputs,
///   int         cbSize
/// );
/// ```
/// {@category user32}
int GetTouchInputInfo(int hTouchInput, int cInputs, Pointer<TOUCHINPUT> pInputs,
        int cbSize) =>
    _GetTouchInputInfo(hTouchInput, cInputs, pInputs, cbSize);

final _GetTouchInputInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hTouchInput, Uint32 cInputs,
        Pointer<TOUCHINPUT> pInputs, Int32 cbSize),
    int Function(int hTouchInput, int cInputs, Pointer<TOUCHINPUT> pInputs,
        int cbSize)>('GetTouchInputInfo');

/// Gets pointer data before it has gone through touch prediction
/// processing.
///
/// ```c
/// DWORD GetUnpredictedMessagePos();
/// ```
/// {@category user32}
int GetUnpredictedMessagePos() => _GetUnpredictedMessagePos();

final _GetUnpredictedMessagePos =
    _user32.lookupFunction<Uint32 Function(), int Function()>(
        'GetUnpredictedMessagePos');

/// Retrieves the currently supported clipboard formats.
///
/// ```c
/// BOOL GetUpdatedClipboardFormats(
///   PUINT lpuiFormats,
///   UINT  cFormats,
///   PUINT pcFormatsOut
/// );
/// ```
/// {@category user32}
int GetUpdatedClipboardFormats(Pointer<Uint32> lpuiFormats, int cFormats,
        Pointer<Uint32> pcFormatsOut) =>
    _GetUpdatedClipboardFormats(lpuiFormats, cFormats, pcFormatsOut);

final _GetUpdatedClipboardFormats = _user32.lookupFunction<
    Int32 Function(Pointer<Uint32> lpuiFormats, Uint32 cFormats,
        Pointer<Uint32> pcFormatsOut),
    int Function(Pointer<Uint32> lpuiFormats, int cFormats,
        Pointer<Uint32> pcFormatsOut)>('GetUpdatedClipboardFormats');

/// The GetUpdateRect function retrieves the coordinates of the smallest
/// rectangle that completely encloses the update region of the specified
/// window. GetUpdateRect retrieves the rectangle in logical coordinates. If
/// there is no update region, GetUpdateRect retrieves an empty rectangle
/// (sets all coordinates to zero).
///
/// ```c
/// BOOL GetUpdateRect(
///   HWND   hWnd,
///   LPRECT lpRect,
///   BOOL   bErase
/// );
/// ```
/// {@category user32}
int GetUpdateRect(int hWnd, Pointer<RECT> lpRect, int bErase) =>
    _GetUpdateRect(hWnd, lpRect, bErase);

final _GetUpdateRect = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect, Int32 bErase),
    int Function(int hWnd, Pointer<RECT> lpRect, int bErase)>('GetUpdateRect');

/// The GetUpdateRgn function retrieves the update region of a window by
/// copying it into the specified region. The coordinates of the update
/// region are relative to the upper-left corner of the window (that is,
/// they are client coordinates).
///
/// ```c
/// int GetUpdateRgn(
///   HWND hWnd,
///   HRGN hRgn,
///   BOOL bErase
/// );
/// ```
/// {@category user32}
int GetUpdateRgn(int hWnd, int hRgn, int bErase) =>
    _GetUpdateRgn(hWnd, hRgn, bErase);

final _GetUpdateRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bErase),
    int Function(int hWnd, int hRgn, int bErase)>('GetUpdateRgn');

/// Retrieves information about the specified window station or desktop
/// object.
///
/// ```c
/// BOOL GetUserObjectInformationW(
///   HANDLE  hObj,
///   int     nIndex,
///   PVOID   pvInfo,
///   DWORD   nLength,
///   LPDWORD lpnLengthNeeded
/// );
/// ```
/// {@category user32}
int GetUserObjectInformation(int hObj, int nIndex, Pointer pvInfo, int nLength,
        Pointer<Uint32> lpnLengthNeeded) =>
    _GetUserObjectInformation(hObj, nIndex, pvInfo, nLength, lpnLengthNeeded);

final _GetUserObjectInformation = _user32.lookupFunction<
    Int32 Function(IntPtr hObj, Uint32 nIndex, Pointer pvInfo, Uint32 nLength,
        Pointer<Uint32> lpnLengthNeeded),
    int Function(int hObj, int nIndex, Pointer pvInfo, int nLength,
        Pointer<Uint32> lpnLengthNeeded)>('GetUserObjectInformationW');

/// Retrieves a handle to a window that has the specified relationship
/// (Z-Order or owner) to the specified window.
///
/// ```c
/// HWND GetWindow(
///   HWND hWnd,
///   UINT uCmd
/// );
/// ```
/// {@category user32}
int GetWindow(int hWnd, int uCmd) => _GetWindow(hWnd, uCmd);

final _GetWindow = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 uCmd),
    int Function(int hWnd, int uCmd)>('GetWindow');

/// The GetWindowDC function retrieves the device context (DC) for the
/// entire window, including title bar, menus, and scroll bars. A window
/// device context permits painting anywhere in a window, because the origin
/// of the device context is the upper-left corner of the window instead of
/// the client area.
///
/// ```c
/// HDC GetWindowDC(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetWindowDC(int hWnd) => _GetWindowDC(hWnd);

final _GetWindowDC = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('GetWindowDC');

/// Retrieves the current display affinity setting, from any process, for a
/// given window.
///
/// ```c
/// BOOL GetWindowDisplayAffinity(
///   HWND  hWnd,
///   DWORD *pdwAffinity
/// );
/// ```
/// {@category user32}
int GetWindowDisplayAffinity(int hWnd, Pointer<Uint32> pdwAffinity) =>
    _GetWindowDisplayAffinity(hWnd, pdwAffinity);

final _GetWindowDisplayAffinity = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Uint32> pdwAffinity),
    int Function(
        int hWnd, Pointer<Uint32> pdwAffinity)>('GetWindowDisplayAffinity');

/// Returns the DPI_AWARENESS_CONTEXT associated with a window.
///
/// ```c
/// DPI_AWARENESS_CONTEXT GetWindowDpiAwarenessContext(
///   HWND hwnd);
/// ```
/// {@category user32}
int GetWindowDpiAwarenessContext(int hwnd) =>
    _GetWindowDpiAwarenessContext(hwnd);

final _GetWindowDpiAwarenessContext = _user32.lookupFunction<
    IntPtr Function(IntPtr hwnd),
    int Function(int hwnd)>('GetWindowDpiAwarenessContext');

/// Returns the DPI_HOSTING_BEHAVIOR of the specified window.
///
/// ```c
/// DPI_HOSTING_BEHAVIOR GetWindowDpiHostingBehavior(
///   HWND hwnd);
/// ```
/// {@category user32}
int GetWindowDpiHostingBehavior(int hwnd) => _GetWindowDpiHostingBehavior(hwnd);

final _GetWindowDpiHostingBehavior =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'GetWindowDpiHostingBehavior');

/// Retrieves information about the specified window.
///
/// ```c
/// BOOL GetWindowInfo(
///   HWND hwnd,
///   PWINDOWINFO pwi
/// );
/// ```
/// {@category user32}
int GetWindowInfo(int hwnd, Pointer<WINDOWINFO> pwi) =>
    _GetWindowInfo(hwnd, pwi);

final _GetWindowInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<WINDOWINFO> pwi),
    int Function(int hwnd, Pointer<WINDOWINFO> pwi)>('GetWindowInfo');

/// Retrieves information about the specified window. The function also
/// retrieves the value at a specified offset into the extra window memory.
///
/// ```c
/// LONG_PTR GetWindowLongPtrW(
///   HWND hWnd,
///   int  nIndex
/// );
/// ```
/// {@category user32}
int GetWindowLongPtr(int hWnd, int nIndex) => _GetWindowLongPtr(hWnd, nIndex);

final _GetWindowLongPtr = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Int32 nIndex),
    int Function(int hWnd, int nIndex)>('GetWindowLongPtrW');

/// Retrieves the full path and file name of the module associated with the
/// specified window handle.
///
/// ```c
/// UINT GetWindowModuleFileNameW(
///   HWND   hwnd,
///   LPWSTR pszFileName,
///   UINT   cchFileNameMax
/// );
/// ```
/// {@category user32}
int GetWindowModuleFileName(
        int hwnd, Pointer<Utf16> pszFileName, int cchFileNameMax) =>
    _GetWindowModuleFileName(hwnd, pszFileName, cchFileNameMax);

final _GetWindowModuleFileName = _user32.lookupFunction<
    Uint32 Function(
        IntPtr hwnd, Pointer<Utf16> pszFileName, Uint32 cchFileNameMax),
    int Function(int hwnd, Pointer<Utf16> pszFileName,
        int cchFileNameMax)>('GetWindowModuleFileNameW');

/// Retrieves the show state and the restored, minimized, and maximized
/// positions of the specified window.
///
/// ```c
/// BOOL GetWindowPlacement(
///   HWND            hWnd,
///   WINDOWPLACEMENT *lpwndpl);
/// ```
/// {@category user32}
int GetWindowPlacement(int hWnd, Pointer<WINDOWPLACEMENT> lpwndpl) =>
    _GetWindowPlacement(hWnd, lpwndpl);

final _GetWindowPlacement = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<WINDOWPLACEMENT> lpwndpl),
    int Function(
        int hWnd, Pointer<WINDOWPLACEMENT> lpwndpl)>('GetWindowPlacement');

/// Retrieves the dimensions of the bounding rectangle of the specified
/// window. The dimensions are given in screen coordinates that are relative
/// to the upper-left corner of the screen.
///
/// ```c
/// BOOL GetWindowRect(
///   HWND   hWnd,
///   LPRECT lpRect
/// );
/// ```
/// {@category user32}
int GetWindowRect(int hWnd, Pointer<RECT> lpRect) =>
    _GetWindowRect(hWnd, lpRect);

final _GetWindowRect = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
    int Function(int hWnd, Pointer<RECT> lpRect)>('GetWindowRect');

/// The GetWindowRgn function obtains a copy of the window region of a
/// window. The window region of a window is set by calling the SetWindowRgn
/// function. The window region determines the area within the window where
/// the system permits drawing. The system does not display any portion of a
/// window that lies outside of the window region.
///
/// ```c
/// int GetWindowRgn(
///   HWND hWnd,
///   HRGN hRgn
/// );
/// ```
/// {@category user32}
int GetWindowRgn(int hWnd, int hRgn) => _GetWindowRgn(hWnd, hRgn);

final _GetWindowRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hRgn),
    int Function(int hWnd, int hRgn)>('GetWindowRgn');

/// The GetWindowRgnBox function retrieves the dimensions of the tightest
/// bounding rectangle for the window region of a window.
///
/// ```c
/// int GetWindowRgnBox(
///   HWND   hWnd,
///   LPRECT lprc
/// );
/// ```
/// {@category user32}
int GetWindowRgnBox(int hWnd, Pointer<RECT> lprc) =>
    _GetWindowRgnBox(hWnd, lprc);

final _GetWindowRgnBox = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lprc),
    int Function(int hWnd, Pointer<RECT> lprc)>('GetWindowRgnBox');

/// Copies the text of the specified window's title bar (if it has one) into
/// a buffer. If the specified window is a control, the text of the control
/// is copied. However, GetWindowText cannot retrieve the text of a control
/// in another application.
///
/// ```c
/// int GetWindowTextW(
///   HWND   hWnd,
///   LPWSTR lpString,
///   int    nMaxCount
/// );
/// ```
/// {@category user32}
int GetWindowText(int hWnd, Pointer<Utf16> lpString, int nMaxCount) =>
    _GetWindowText(hWnd, lpString, nMaxCount);

final _GetWindowText = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString, Int32 nMaxCount),
    int Function(
        int hWnd, Pointer<Utf16> lpString, int nMaxCount)>('GetWindowTextW');

/// Retrieves the length, in characters, of the specified window's title bar
/// text (if the window has a title bar). If the specified window is a
/// control, the function retrieves the length of the text within the
/// control. However, GetWindowTextLength cannot retrieve the length of the
/// text of an edit control in another application.
///
/// ```c
/// int GetWindowTextLengthW(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int GetWindowTextLength(int hWnd) => _GetWindowTextLength(hWnd);

final _GetWindowTextLength =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'GetWindowTextLengthW');

/// Retrieves the identifier of the thread that created the specified window
/// and, optionally, the identifier of the process that created the window.
///
/// ```c
/// DWORD GetWindowThreadProcessId(
///   HWND    hWnd,
///   LPDWORD lpdwProcessId
/// );
/// ```
/// {@category user32}
int GetWindowThreadProcessId(int hWnd, Pointer<Uint32> lpdwProcessId) =>
    _GetWindowThreadProcessId(hWnd, lpdwProcessId);

final _GetWindowThreadProcessId = _user32.lookupFunction<
    Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId),
    int Function(
        int hWnd, Pointer<Uint32> lpdwProcessId)>('GetWindowThreadProcessId');

/// The GrayString function draws gray text at the specified location. The
/// function draws the text by copying it into a memory bitmap, graying the
/// bitmap, and then copying the bitmap to the screen. The function grays
/// the text regardless of the selected brush and background. GrayString
/// uses the font currently selected for the specified device context.
///
/// ```c
/// BOOL GrayStringW(
///   HDC            hDC,
///   HBRUSH         hBrush,
///   GRAYSTRINGPROC lpOutputFunc,
///   LPARAM         lpData,
///   int            nCount,
///   int            X,
///   int            Y,
///   int            nWidth,
///   int            nHeight
/// );
/// ```
/// {@category user32}
int GrayString(
        int hDC,
        int hBrush,
        Pointer<NativeFunction<OutputProc>> lpOutputFunc,
        int lpData,
        int nCount,
        int X,
        int Y,
        int nWidth,
        int nHeight) =>
    _GrayString(
        hDC, hBrush, lpOutputFunc, lpData, nCount, X, Y, nWidth, nHeight);

final _GrayString = _user32.lookupFunction<
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

/// Removes the caret from the screen. Hiding a caret does not destroy its
/// current shape or invalidate the insertion point.
///
/// ```c
/// BOOL HideCaret(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int HideCaret(int hWnd) => _HideCaret(hWnd);

final _HideCaret =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'HideCaret');

/// The InflateRect function increases or decreases the width and height of
/// the specified rectangle. The InflateRect function adds -dx units to the
/// left end and dx to the right end of the rectangle and -dy units to the
/// top and dy to the bottom. The dx and dy parameters are signed values;
/// positive values increase the width and height, and negative values
/// decrease them.
///
/// ```c
/// BOOL InflateRect(
///   LPRECT lprc,
///   int    dx,
///   int    dy
/// );
/// ```
/// {@category user32}
int InflateRect(Pointer<RECT> lprc, int dx, int dy) =>
    _InflateRect(lprc, dx, dy);

final _InflateRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprc, Int32 dx, Int32 dy),
    int Function(Pointer<RECT> lprc, int dx, int dy)>('InflateRect');

/// Determines whether the current window procedure is processing a message
/// that was sent from another thread (in the same process or a different
/// process) by a call to the SendMessage function.
///
/// ```c
/// BOOL InSendMessage();
/// ```
/// {@category user32}
int InSendMessage() => _InSendMessage();

final _InSendMessage =
    _user32.lookupFunction<Int32 Function(), int Function()>('InSendMessage');

/// Determines whether the current window procedure is processing a message
/// that was sent from another thread (in the same process or a different
/// process).
///
/// ```c
/// DWORD InSendMessageEx(
///   LPVOID lpReserved
/// );
/// ```
/// {@category user32}
int InSendMessageEx(Pointer lpReserved) => _InSendMessageEx(lpReserved);

final _InSendMessageEx = _user32.lookupFunction<
    Uint32 Function(Pointer lpReserved),
    int Function(Pointer lpReserved)>('InSendMessageEx');

/// Inserts a new menu item into a menu, moving other items down the menu.
///
/// ```c
/// BOOL InsertMenuW(
///   HMENU    hMenu,
///   UINT     uPosition,
///   UINT     uFlags,
///   UINT_PTR uIDNewItem,
///   LPCWSTR  lpNewItem
/// );
/// ```
/// {@category user32}
int InsertMenu(int hMenu, int uPosition, int uFlags, int uIDNewItem,
        Pointer<Utf16> lpNewItem) =>
    _InsertMenu(hMenu, uPosition, uFlags, uIDNewItem, lpNewItem);

final _InsertMenu = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags,
        IntPtr uIDNewItem, Pointer<Utf16> lpNewItem),
    int Function(int hMenu, int uPosition, int uFlags, int uIDNewItem,
        Pointer<Utf16> lpNewItem)>('InsertMenuW');

/// Inserts a new menu item at the specified position in a menu.
///
/// ```c
/// BOOL InsertMenuItemW(
///   HMENU            hmenu,
///   UINT             item,
///   BOOL             fByPosition,
///   LPCMENUITEMINFOW lpmi
/// );
/// ```
/// {@category user32}
int InsertMenuItem(
        int hmenu, int item, int fByPosition, Pointer<MENUITEMINFO> lpmi) =>
    _InsertMenuItem(hmenu, item, fByPosition, lpmi);

final _InsertMenuItem = _user32.lookupFunction<
    Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPosition,
        Pointer<MENUITEMINFO> lpmi),
    int Function(int hmenu, int item, int fByPosition,
        Pointer<MENUITEMINFO> lpmi)>('InsertMenuItemW');

/// The IntersectRect function calculates the intersection of two source
/// rectangles and places the coordinates of the intersection rectangle into
/// the destination rectangle. If the source rectangles do not intersect, an
/// empty rectangle (in which all coordinates are set to zero) is placed
/// into the destination rectangle.
///
/// ```c
/// BOOL IntersectRect(
///   LPRECT     lprcDst,
///   const RECT *lprcSrc1,
///   const RECT *lprcSrc2
/// );
/// ```
/// {@category user32}
int IntersectRect(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2) =>
    _IntersectRect(lprcDst, lprcSrc1, lprcSrc2);

final _IntersectRect = _user32.lookupFunction<
    Int32 Function(
        Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1, Pointer<RECT> lprcSrc2),
    int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2)>('IntersectRect');

/// The InvalidateRect function adds a rectangle to the specified window's
/// update region. The update region represents the portion of the window's
/// client area that must be redrawn.
///
/// ```c
/// BOOL InvalidateRect(
///   HWND       hWnd,
///   const RECT *lpRect,
///   BOOL       bErase
/// );
/// ```
/// {@category user32}
int InvalidateRect(int hWnd, Pointer<RECT> lpRect, int bErase) =>
    _InvalidateRect(hWnd, lpRect, bErase);

final _InvalidateRect = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect, Int32 bErase),
    int Function(int hWnd, Pointer<RECT> lpRect, int bErase)>('InvalidateRect');

/// The InvalidateRgn function invalidates the client area within the
/// specified region by adding it to the current update region of a window.
/// The invalidated region, along with all other areas in the update region,
/// is marked for painting when the next WM_PAINT message occurs.
///
/// ```c
/// BOOL InvalidateRgn(
///   HWND hWnd,
///   HRGN hRgn,
///   BOOL bErase
/// );
/// ```
/// {@category user32}
int InvalidateRgn(int hWnd, int hRgn, int bErase) =>
    _InvalidateRgn(hWnd, hRgn, bErase);

final _InvalidateRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bErase),
    int Function(int hWnd, int hRgn, int bErase)>('InvalidateRgn');

/// The InvertRect function inverts a rectangle in a window by performing a
/// logical NOT operation on the color values for each pixel in the
/// rectangle's interior.
///
/// ```c
/// BOOL InvertRect(
///   HDC        hDC,
///   const RECT *lprc
/// );
/// ```
/// {@category user32}
int InvertRect(int hDC, Pointer<RECT> lprc) => _InvertRect(hDC, lprc);

final _InvertRect = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<RECT> lprc),
    int Function(int hDC, Pointer<RECT> lprc)>('InvertRect');

/// Determines whether a window is a child window or descendant window of a
/// specified parent window. A child window is the direct descendant of a
/// specified parent window if that parent window is in the chain of parent
/// windows; the chain of parent windows leads from the original overlapped
/// or pop-up window to the child window.
///
/// ```c
/// BOOL IsChild(
///   HWND hWndParent,
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int IsChild(int hWndParent, int hWnd) => _IsChild(hWndParent, hWnd);

final _IsChild = _user32.lookupFunction<
    Int32 Function(IntPtr hWndParent, IntPtr hWnd),
    int Function(int hWndParent, int hWnd)>('IsChild');

/// Determines whether the clipboard contains data in the specified format.
///
/// ```c
/// BOOL IsClipboardFormatAvailable(
///   UINT format
/// );
/// ```
/// {@category user32}
int IsClipboardFormatAvailable(int format) =>
    _IsClipboardFormatAvailable(format);

final _IsClipboardFormatAvailable = _user32.lookupFunction<
    Int32 Function(Uint32 format),
    int Function(int format)>('IsClipboardFormatAvailable');

/// Determines whether a message is intended for the specified dialog box
/// and, if it is, processes the message.
///
/// ```c
/// BOOL IsDialogMessageW(
///   HWND  hDlg,
///   LPMSG lpMsg
/// );
/// ```
/// {@category user32}
int IsDialogMessage(int hDlg, Pointer<MSG> lpMsg) =>
    _IsDialogMessage(hDlg, lpMsg);

final _IsDialogMessage = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Pointer<MSG> lpMsg),
    int Function(int hDlg, Pointer<MSG> lpMsg)>('IsDialogMessageW');

/// The IsDlgButtonChecked function determines whether a button control is
/// checked or whether a three-state button control is checked, unchecked,
/// or indeterminate.
///
/// ```c
/// UINT IsDlgButtonChecked(
///   HWND hDlg,
///   int  nIDButton
/// );
/// ```
/// {@category user32}
int IsDlgButtonChecked(int hDlg, int nIDButton) =>
    _IsDlgButtonChecked(hDlg, nIDButton);

final _IsDlgButtonChecked = _user32.lookupFunction<
    Uint32 Function(IntPtr hDlg, Int32 nIDButton),
    int Function(int hDlg, int nIDButton)>('IsDlgButtonChecked');

/// Determines whether the calling thread is already a GUI thread. It can
/// also optionally convert the thread to a GUI thread.
///
/// ```c
/// BOOL IsGUIThread(
///   BOOL bConvert
/// );
/// ```
/// {@category user32}
int IsGUIThread(int bConvert) => _IsGUIThread(bConvert);

final _IsGUIThread = _user32.lookupFunction<Int32 Function(Int32 bConvert),
    int Function(int bConvert)>('IsGUIThread');

/// Determines whether the system considers that a specified application is
/// not responding. An application is considered to be not responding if it
/// is not waiting for input, is not in startup processing, and has not
/// called PeekMessage within the internal timeout period of 5 seconds.
///
/// ```c
/// BOOL IsHungAppWindow(
///   HWND hwnd
/// );
/// ```
/// {@category user32}
int IsHungAppWindow(int hwnd) => _IsHungAppWindow(hwnd);

final _IsHungAppWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'IsHungAppWindow');

/// Determines whether the specified window is minimized (iconic).
///
/// ```c
/// BOOL IsIconic(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int IsIconic(int hWnd) => _IsIconic(hWnd);

final _IsIconic =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsIconic');

/// Determines whether the process belongs to a Windows Store app.
///
/// ```c
/// BOOL IsImmersiveProcess(
///   HANDLE hProcess
/// );
/// ```
/// {@category user32}
int IsImmersiveProcess(int hProcess) => _IsImmersiveProcess(hProcess);

final _IsImmersiveProcess = _user32.lookupFunction<
    Int32 Function(IntPtr hProcess),
    int Function(int hProcess)>('IsImmersiveProcess');

/// Determines whether a handle is a menu handle.
///
/// ```c
/// BOOL IsMenu(
///   HMENU hMenu
/// );
/// ```
/// {@category user32}
int IsMenu(int hMenu) => _IsMenu(hMenu);

final _IsMenu = _user32.lookupFunction<Int32 Function(IntPtr hMenu),
    int Function(int hMenu)>('IsMenu');

/// Indicates whether EnableMouseInPointer is set for the mouse to act as a
/// pointer input device and send WM_POINTER messages.
///
/// ```c
/// BOOL IsMouseInPointerEnabled();
/// ```
/// {@category user32}
int IsMouseInPointerEnabled() => _IsMouseInPointerEnabled();

final _IsMouseInPointerEnabled =
    _user32.lookupFunction<Int32 Function(), int Function()>(
        'IsMouseInPointerEnabled');

/// Determines whether the current process is dots per inch (dpi) aware such
/// that it adjusts the sizes of UI elements to compensate for the dpi
/// setting.
///
/// ```c
/// BOOL IsProcessDPIAware();
/// ```
/// {@category user32}
int IsProcessDPIAware() => _IsProcessDPIAware();

final _IsProcessDPIAware = _user32
    .lookupFunction<Int32 Function(), int Function()>('IsProcessDPIAware');

/// The IsRectEmpty function determines whether the specified rectangle is
/// empty. An empty rectangle is one that has no area; that is, the
/// coordinate of the right side is less than or equal to the coordinate of
/// the left side, or the coordinate of the bottom side is less than or
/// equal to the coordinate of the top side.
///
/// ```c
/// BOOL IsRectEmpty(
///   const RECT *lprc
/// );
/// ```
/// {@category user32}
int IsRectEmpty(Pointer<RECT> lprc) => _IsRectEmpty(lprc);

final _IsRectEmpty = _user32.lookupFunction<Int32 Function(Pointer<RECT> lprc),
    int Function(Pointer<RECT> lprc)>('IsRectEmpty');

/// Checks whether a specified window is touch-capable and, optionally,
/// retrieves the modifier flags set for the window's touch capability.
///
/// ```c
/// BOOL IsTouchWindow(
///   HWND   hwnd,
///   PULONG pulFlags
/// );
/// ```
/// {@category user32}
int IsTouchWindow(int hwnd, Pointer<Uint32> pulFlags) =>
    _IsTouchWindow(hwnd, pulFlags);

final _IsTouchWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Pointer<Uint32> pulFlags),
    int Function(int hwnd, Pointer<Uint32> pulFlags)>('IsTouchWindow');

/// Determines if a specified DPI_AWARENESS_CONTEXT is valid and supported
/// by the current system.
///
/// ```c
/// BOOL IsValidDpiAwarenessContext(
///   DPI_AWARENESS_CONTEXT value);
/// ```
/// {@category user32}
int IsValidDpiAwarenessContext(int value) => _IsValidDpiAwarenessContext(value);

final _IsValidDpiAwarenessContext = _user32.lookupFunction<
    Int32 Function(IntPtr value),
    int Function(int value)>('IsValidDpiAwarenessContext');

/// Determines whether the specified window handle identifies an existing
/// window.
///
/// ```c
/// BOOL IsWindow(
///   HWND hWnd);
/// ```
/// {@category user32}
int IsWindow(int hWnd) => _IsWindow(hWnd);

final _IsWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsWindow');

/// Determines whether the specified window is enabled for mouse and
/// keyboard input.
///
/// ```c
/// BOOL IsWindowEnabled(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int IsWindowEnabled(int hWnd) => _IsWindowEnabled(hWnd);

final _IsWindowEnabled =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsWindowEnabled');

/// Determines whether the specified window is a native Unicode window.
///
/// ```c
/// BOOL IsWindowUnicode(
///   HWND hWnd);
/// ```
/// {@category user32}
int IsWindowUnicode(int hWnd) => _IsWindowUnicode(hWnd);

final _IsWindowUnicode =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsWindowUnicode');

/// Determines the visibility state of the specified window.
///
/// ```c
/// BOOL IsWindowVisible(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int IsWindowVisible(int hWnd) => _IsWindowVisible(hWnd);

final _IsWindowVisible =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsWindowVisible');

/// Determines whether the last message read from the current thread's queue
/// originated from a WOW64 process.
///
/// ```c
/// BOOL IsWow64Message();
/// ```
/// {@category user32}
int IsWow64Message() => _IsWow64Message();

final _IsWow64Message =
    _user32.lookupFunction<Int32 Function(), int Function()>('IsWow64Message');

/// Determines whether a window is maximized.
///
/// ```c
/// BOOL IsZoomed(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int IsZoomed(int hWnd) => _IsZoomed(hWnd);

final _IsZoomed =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'IsZoomed');

/// Destroys the specified timer.
///
/// ```c
/// BOOL KillTimer(
///   HWND     hWnd,
///   UINT_PTR uIDEvent
/// );
/// ```
/// {@category user32}
int KillTimer(int hWnd, int uIDEvent) => _KillTimer(hWnd, uIDEvent);

final _KillTimer = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr uIDEvent),
    int Function(int hWnd, int uIDEvent)>('KillTimer');

/// Loads the specified accelerator table.
///
/// ```c
/// HACCEL LoadAcceleratorsW(
///   HINSTANCE hInstance,
///   LPCWSTR   lpTableName
/// );
/// ```
/// {@category user32}
int LoadAccelerators(int hInstance, Pointer<Utf16> lpTableName) =>
    _LoadAccelerators(hInstance, lpTableName);

final _LoadAccelerators = _user32.lookupFunction<
    IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpTableName),
    int Function(
        int hInstance, Pointer<Utf16> lpTableName)>('LoadAcceleratorsW');

/// Loads the specified cursor resource from the executable (.EXE) file
/// associated with an application instance. Note: this function has been
/// superseded by the LoadImage function.
///
/// ```c
/// HCURSOR LoadCursorW(
///   HINSTANCE hInstance,
///   LPCWSTR   lpCursorName
/// );
/// ```
/// {@category user32}
int LoadCursor(int hInstance, Pointer<Utf16> lpCursorName) =>
    _LoadCursor(hInstance, lpCursorName);

final _LoadCursor = _user32.lookupFunction<
    IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpCursorName),
    int Function(int hInstance, Pointer<Utf16> lpCursorName)>('LoadCursorW');

/// Creates a cursor based on data contained in a file.
///
/// ```c
/// HCURSOR LoadCursorFromFileW(
///   LPCWSTR lpFileName
/// );
/// ```
/// {@category user32}
int LoadCursorFromFile(Pointer<Utf16> lpFileName) =>
    _LoadCursorFromFile(lpFileName);

final _LoadCursorFromFile = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpFileName),
    int Function(Pointer<Utf16> lpFileName)>('LoadCursorFromFileW');

/// Loads the specified icon resource from the executable (.exe) file
/// associated with an application instance.
///
/// ```c
/// HICON LoadIconW(
///   HINSTANCE hInstance,
///   LPCWSTR   lpIconName
/// );
/// ```
/// {@category user32}
int LoadIcon(int hInstance, Pointer<Utf16> lpIconName) =>
    _LoadIcon(hInstance, lpIconName);

final _LoadIcon = _user32.lookupFunction<
    IntPtr Function(IntPtr hInstance, Pointer<Utf16> lpIconName),
    int Function(int hInstance, Pointer<Utf16> lpIconName)>('LoadIconW');

/// Loads an icon, cursor, animated cursor, or bitmap.
///
/// ```c
/// HANDLE LoadImageW(
///   HINSTANCE hInst,
///   LPCWSTR   name,
///   UINT      type,
///   int       cx,
///   int       cy,
///   UINT      fuLoad
/// );
/// ```
/// {@category user32}
int LoadImage(
        int hInst, Pointer<Utf16> name, int type, int cx, int cy, int fuLoad) =>
    _LoadImage(hInst, name, type, cx, cy, fuLoad);

final _LoadImage = _user32.lookupFunction<
    IntPtr Function(IntPtr hInst, Pointer<Utf16> name, Uint32 type, Int32 cx,
        Int32 cy, Uint32 fuLoad),
    int Function(int hInst, Pointer<Utf16> name, int type, int cx, int cy,
        int fuLoad)>('LoadImageW');

/// Loads a new input locale identifier (formerly called the keyboard
/// layout) into the system.
///
/// ```c
/// HKL LoadKeyboardLayoutW(
///   LPCWSTR pwszKLID,
///   UINT    Flags
/// );
/// ```
/// {@category user32}
int LoadKeyboardLayout(Pointer<Utf16> pwszKLID, int Flags) =>
    _LoadKeyboardLayout(pwszKLID, Flags);

final _LoadKeyboardLayout = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> pwszKLID, Uint32 Flags),
    int Function(Pointer<Utf16> pwszKLID, int Flags)>('LoadKeyboardLayoutW');

/// Creates a cursor based on data contained in a file.
///
/// ```c
/// HMENU LoadMenuIndirectW(
///   const MENUTEMPLATEW *lpMenuTemplate
/// );
/// ```
/// {@category user32}
int LoadMenuIndirect(Pointer lpMenuTemplate) =>
    _LoadMenuIndirect(lpMenuTemplate);

final _LoadMenuIndirect = _user32.lookupFunction<
    IntPtr Function(Pointer lpMenuTemplate),
    int Function(Pointer lpMenuTemplate)>('LoadMenuIndirectW');

/// Loads a string resource from the executable file associated with a
/// specified module and either copies the string into a buffer with a
/// terminating null character or returns a read-only pointer to the string
/// resource itself.
///
/// ```c
/// int LoadStringW(
///   HINSTANCE hInstance,
///   UINT      uID,
///   LPWSTR    lpBuffer,
///   int       cchBufferMax
/// );
/// ```
/// {@category user32}
int LoadString(
        int hInstance, int uID, Pointer<Utf16> lpBuffer, int cchBufferMax) =>
    _LoadString(hInstance, uID, lpBuffer, cchBufferMax);

final _LoadString = _user32.lookupFunction<
    Int32 Function(IntPtr hInstance, Uint32 uID, Pointer<Utf16> lpBuffer,
        Int32 cchBufferMax),
    int Function(int hInstance, int uID, Pointer<Utf16> lpBuffer,
        int cchBufferMax)>('LoadStringW');

/// The foreground process can call the LockSetForegroundWindow function to
/// disable calls to the SetForegroundWindow function.
///
/// ```c
/// BOOL LockSetForegroundWindow(
///   UINT uLockCode
/// );
/// ```
/// {@category user32}
int LockSetForegroundWindow(int uLockCode) =>
    _LockSetForegroundWindow(uLockCode);

final _LockSetForegroundWindow = _user32.lookupFunction<
    Int32 Function(Uint32 uLockCode),
    int Function(int uLockCode)>('LockSetForegroundWindow');

/// The LockWindowUpdate function disables or enables drawing in the
/// specified window. Only one window can be locked at a time.
///
/// ```c
/// BOOL LockWindowUpdate(
///   HWND hWndLock
/// );
/// ```
/// {@category user32}
int LockWindowUpdate(int hWndLock) => _LockWindowUpdate(hWndLock);

final _LockWindowUpdate = _user32.lookupFunction<
    Int32 Function(IntPtr hWndLock),
    int Function(int hWndLock)>('LockWindowUpdate');

/// Locks the workstation's display. Locking a workstation protects it from
/// unauthorized use.
///
/// ```c
/// BOOL LockWorkStation();
/// ```
/// {@category user32}
int LockWorkStation() => _LockWorkStation();

final _LockWorkStation =
    _user32.lookupFunction<Int32 Function(), int Function()>('LockWorkStation');

/// Converts the logical coordinates of a point in a window to physical
/// coordinates.
///
/// ```c
/// BOOL LogicalToPhysicalPoint(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int LogicalToPhysicalPoint(int hWnd, Pointer<POINT> lpPoint) =>
    _LogicalToPhysicalPoint(hWnd, lpPoint);

final _LogicalToPhysicalPoint = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd, Pointer<POINT> lpPoint)>('LogicalToPhysicalPoint');

/// Converts a point in a window from logical coordinates into physical
/// coordinates, regardless of the dots per inch (dpi) awareness of the
/// caller.
///
/// ```c
/// BOOL LogicalToPhysicalPointForPerMonitorDPI(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int LogicalToPhysicalPointForPerMonitorDPI(int hWnd, Pointer<POINT> lpPoint) =>
    _LogicalToPhysicalPointForPerMonitorDPI(hWnd, lpPoint);

final _LogicalToPhysicalPointForPerMonitorDPI = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd,
        Pointer<POINT> lpPoint)>('LogicalToPhysicalPointForPerMonitorDPI');

/// Searches through icon or cursor data for the icon or cursor that best
/// fits the current display device.
///
/// ```c
/// int LookupIconIdFromDirectory(
///   PBYTE presbits,
///   BOOL  fIcon
/// );
/// ```
/// {@category user32}
int LookupIconIdFromDirectory(Pointer<Uint8> presbits, int fIcon) =>
    _LookupIconIdFromDirectory(presbits, fIcon);

final _LookupIconIdFromDirectory = _user32.lookupFunction<
    Int32 Function(Pointer<Uint8> presbits, Int32 fIcon),
    int Function(
        Pointer<Uint8> presbits, int fIcon)>('LookupIconIdFromDirectory');

/// Searches through icon or cursor data for the icon or cursor that best
/// fits the current display device.
///
/// ```c
/// int LookupIconIdFromDirectoryEx(
///   PBYTE presbits,
///   BOOL  fIcon,
///   int   cxDesired,
///   int   cyDesired,
///   UINT  Flags
/// );
/// ```
/// {@category user32}
int LookupIconIdFromDirectoryEx(Pointer<Uint8> presbits, int fIcon,
        int cxDesired, int cyDesired, int Flags) =>
    _LookupIconIdFromDirectoryEx(presbits, fIcon, cxDesired, cyDesired, Flags);

final _LookupIconIdFromDirectoryEx = _user32.lookupFunction<
    Int32 Function(Pointer<Uint8> presbits, Int32 fIcon, Int32 cxDesired,
        Int32 cyDesired, Uint32 Flags),
    int Function(Pointer<Uint8> presbits, int fIcon, int cxDesired,
        int cyDesired, int Flags)>('LookupIconIdFromDirectoryEx');

/// Converts the specified dialog box units to screen units (pixels). The
/// function replaces the coordinates in the specified RECT structure with
/// the converted coordinates, which allows the structure to be used to
/// create a dialog box or position a control within a dialog box.
///
/// ```c
/// BOOL MapDialogRect(
///   HWND   hDlg,
///   LPRECT lpRect
/// );
/// ```
/// {@category user32}
int MapDialogRect(int hDlg, Pointer<RECT> lpRect) =>
    _MapDialogRect(hDlg, lpRect);

final _MapDialogRect = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Pointer<RECT> lpRect),
    int Function(int hDlg, Pointer<RECT> lpRect)>('MapDialogRect');

/// Translates (maps) a virtual-key code into a scan code or character
/// value, or translates a scan code into a virtual-key code.
///
/// ```c
/// UINT MapVirtualKeyW(
///   UINT uCode,
///   UINT uMapType
/// );
/// ```
/// {@category user32}
int MapVirtualKey(int uCode, int uMapType) => _MapVirtualKey(uCode, uMapType);

final _MapVirtualKey = _user32.lookupFunction<
    Uint32 Function(Uint32 uCode, Uint32 uMapType),
    int Function(int uCode, int uMapType)>('MapVirtualKeyW');

/// Translates (maps) a virtual-key code into a scan code or character
/// value, or translates a scan code into a virtual-key code. The function
/// translates the codes using the input language and an input locale
/// identifier.
///
/// ```c
/// UINT MapVirtualKeyExW(
///   UINT uCode,
///   UINT uMapType,
///   HKL  dwhkl
/// );
/// ```
/// {@category user32}
int MapVirtualKeyEx(int uCode, int uMapType, int dwhkl) =>
    _MapVirtualKeyEx(uCode, uMapType, dwhkl);

final _MapVirtualKeyEx = _user32.lookupFunction<
    Uint32 Function(Uint32 uCode, Uint32 uMapType, IntPtr dwhkl),
    int Function(int uCode, int uMapType, int dwhkl)>('MapVirtualKeyExW');

/// The MapWindowPoints function converts (maps) a set of points from a
/// coordinate space relative to one window to a coordinate space relative
/// to another window.
///
/// ```c
/// int MapWindowPoints(
///   HWND    hWndFrom,
///   HWND    hWndTo,
///   LPPOINT lpPoints,
///   UINT    cPoints
/// );
/// ```
/// {@category user32}
int MapWindowPoints(
        int hWndFrom, int hWndTo, Pointer<POINT> lpPoints, int cPoints) =>
    _MapWindowPoints(hWndFrom, hWndTo, lpPoints, cPoints);

final _MapWindowPoints = _user32.lookupFunction<
    Int32 Function(IntPtr hWndFrom, IntPtr hWndTo, Pointer<POINT> lpPoints,
        Uint32 cPoints),
    int Function(int hWndFrom, int hWndTo, Pointer<POINT> lpPoints,
        int cPoints)>('MapWindowPoints');

/// Determines which menu item, if any, is at the specified location.
///
/// ```c
/// int MenuItemFromPoint(
///   HWND  hWnd,
///   HMENU hMenu,
///   POINT ptScreen
/// );
/// ```
/// {@category user32}
int MenuItemFromPoint(int hWnd, int hMenu, POINT ptScreen) =>
    _MenuItemFromPoint(hWnd, hMenu, ptScreen);

final _MenuItemFromPoint = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hMenu, POINT ptScreen),
    int Function(int hWnd, int hMenu, POINT ptScreen)>('MenuItemFromPoint');

/// Displays a modal dialog box that contains a system icon, a set of
/// buttons, and a brief application-specific message, such as status or
/// error information. The message box returns an integer value that
/// indicates which button the user clicked.
///
/// ```c
/// int MessageBoxW(
///   HWND    hWnd,
///   LPCWSTR lpText,
///   LPCWSTR lpCaption,
///   UINT    uType
/// );
/// ```
/// {@category user32}
int MessageBox(
        int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption, int uType) =>
    _MessageBox(hWnd, lpText, lpCaption, uType);

final _MessageBox = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption,
        Uint32 uType),
    int Function(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption,
        int uType)>('MessageBoxW');

/// Creates, displays, and operates a message box. The message box contains
/// an application-defined message and title, plus any combination of
/// predefined icons and push buttons. The buttons are in the language of
/// the system user interface.
///
/// ```c
/// int MessageBoxExW(
///   HWND    hWnd,
///   LPCWSTR lpText,
///   LPCWSTR lpCaption,
///   UINT    uType,
///   WORD    wLanguageId
/// );
/// ```
/// {@category user32}
int MessageBoxEx(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption,
        int uType, int wLanguageId) =>
    _MessageBoxEx(hWnd, lpText, lpCaption, uType, wLanguageId);

final _MessageBoxEx = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption,
        Uint32 uType, Uint16 wLanguageId),
    int Function(int hWnd, Pointer<Utf16> lpText, Pointer<Utf16> lpCaption,
        int uType, int wLanguageId)>('MessageBoxExW');

/// Changes an existing menu item. This function is used to specify the
/// content, appearance, and behavior of the menu item.
///
/// ```c
/// BOOL ModifyMenuW(
///   HMENU    hMnu,
///   UINT     uPosition,
///   UINT     uFlags,
///   UINT_PTR uIDNewItem,
///   LPCWSTR  lpNewItem
/// );
/// ```
/// {@category user32}
int ModifyMenu(int hMnu, int uPosition, int uFlags, int uIDNewItem,
        Pointer<Utf16> lpNewItem) =>
    _ModifyMenu(hMnu, uPosition, uFlags, uIDNewItem, lpNewItem);

final _ModifyMenu = _user32.lookupFunction<
    Int32 Function(IntPtr hMnu, Uint32 uPosition, Uint32 uFlags,
        IntPtr uIDNewItem, Pointer<Utf16> lpNewItem),
    int Function(int hMnu, int uPosition, int uFlags, int uIDNewItem,
        Pointer<Utf16> lpNewItem)>('ModifyMenuW');

/// The MonitorFromPoint function retrieves a handle to the display monitor
/// that contains a specified point.
///
/// ```c
/// HMONITOR MonitorFromPoint(
///   POINT pt,
///   DWORD dwFlags
/// );
/// ```
/// {@category user32}
int MonitorFromPoint(POINT pt, int dwFlags) => _MonitorFromPoint(pt, dwFlags);

final _MonitorFromPoint = _user32.lookupFunction<
    IntPtr Function(POINT pt, Uint32 dwFlags),
    int Function(POINT pt, int dwFlags)>('MonitorFromPoint');

/// The MonitorFromRect function retrieves a handle to the display monitor
/// that has the largest area of intersection with a specified rectangle.
///
/// ```c
/// HMONITOR MonitorFromRect(
///   LPCRECT lprc,
///   DWORD   dwFlags
/// );
/// ```
/// {@category user32}
int MonitorFromRect(Pointer<RECT> lprc, int dwFlags) =>
    _MonitorFromRect(lprc, dwFlags);

final _MonitorFromRect = _user32.lookupFunction<
    IntPtr Function(Pointer<RECT> lprc, Uint32 dwFlags),
    int Function(Pointer<RECT> lprc, int dwFlags)>('MonitorFromRect');

/// The MonitorFromWindow function retrieves a handle to the display monitor
/// that has the largest area of intersection with the bounding rectangle of
/// a specified window.
///
/// ```c
/// HMONITOR MonitorFromWindow(
///   HWND  hwnd,
///   DWORD dwFlags
/// );
/// ```
/// {@category user32}
int MonitorFromWindow(int hwnd, int dwFlags) =>
    _MonitorFromWindow(hwnd, dwFlags);

final _MonitorFromWindow = _user32.lookupFunction<
    IntPtr Function(IntPtr hwnd, Uint32 dwFlags),
    int Function(int hwnd, int dwFlags)>('MonitorFromWindow');

/// Changes the position and dimensions of the specified window. For a
/// top-level window, the position and dimensions are relative to the
/// upper-left corner of the screen. For a child window, they are relative
/// to the upper-left corner of the parent window's client area.
///
/// ```c
/// BOOL MoveWindow(
///   HWND hWnd,
///   int  X,
///   int  Y,
///   int  nWidth,
///   int  nHeight,
///   BOOL bRepaint
/// );
/// ```
/// {@category user32}
int MoveWindow(int hWnd, int X, int Y, int nWidth, int nHeight, int bRepaint) =>
    _MoveWindow(hWnd, X, Y, nWidth, nHeight, bRepaint);

final _MoveWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 X, Int32 Y, Int32 nWidth, Int32 nHeight,
        Int32 bRepaint),
    int Function(int hWnd, int X, int Y, int nWidth, int nHeight,
        int bRepaint)>('MoveWindow');

/// Waits until one or all of the specified objects are in the signaled
/// state or the time-out interval elapses. The objects can include input
/// event objects, which you specify using the dwWakeMask parameter.
///
/// ```c
/// DWORD MsgWaitForMultipleObjects(
///   DWORD        nCount,
///   const HANDLE *pHandles,
///   BOOL         fWaitAll,
///   DWORD        dwMilliseconds,
///   DWORD        dwWakeMask
/// );
/// ```
/// {@category user32}
int MsgWaitForMultipleObjects(int nCount, Pointer<IntPtr> pHandles,
        int fWaitAll, int dwMilliseconds, int dwWakeMask) =>
    _MsgWaitForMultipleObjects(
        nCount, pHandles, fWaitAll, dwMilliseconds, dwWakeMask);

final _MsgWaitForMultipleObjects = _user32.lookupFunction<
    Uint32 Function(Uint32 nCount, Pointer<IntPtr> pHandles, Int32 fWaitAll,
        Uint32 dwMilliseconds, Uint32 dwWakeMask),
    int Function(int nCount, Pointer<IntPtr> pHandles, int fWaitAll,
        int dwMilliseconds, int dwWakeMask)>('MsgWaitForMultipleObjects');

/// Waits until one or all of the specified objects are in the signaled
/// state, an I/O completion routine or asynchronous procedure call (APC) is
/// queued to the thread, or the time-out interval elapses. The array of
/// objects can include input event objects, which you specify using the
/// dwWakeMask parameter.
///
/// ```c
/// DWORD MsgWaitForMultipleObjectsEx(
///   DWORD        nCount,
///   const HANDLE *pHandles,
///   DWORD        dwMilliseconds,
///   DWORD        dwWakeMask,
///   DWORD        dwFlags
/// );
/// ```
/// {@category user32}
int MsgWaitForMultipleObjectsEx(int nCount, Pointer<IntPtr> pHandles,
        int dwMilliseconds, int dwWakeMask, int dwFlags) =>
    _MsgWaitForMultipleObjectsEx(
        nCount, pHandles, dwMilliseconds, dwWakeMask, dwFlags);

final _MsgWaitForMultipleObjectsEx = _user32.lookupFunction<
    Uint32 Function(Uint32 nCount, Pointer<IntPtr> pHandles,
        Uint32 dwMilliseconds, Uint32 dwWakeMask, Uint32 dwFlags),
    int Function(int nCount, Pointer<IntPtr> pHandles, int dwMilliseconds,
        int dwWakeMask, int dwFlags)>('MsgWaitForMultipleObjectsEx');

/// Signals the system that a predefined event occurred. If any client
/// applications have registered a hook function for the event, the system
/// calls the client's hook function.
///
/// ```c
/// void NotifyWinEvent(
///   DWORD event,
///   HWND  hwnd,
///   LONG  idObject,
///   LONG  idChild
/// );
/// ```
/// {@category user32}
void NotifyWinEvent(int event, int hwnd, int idObject, int idChild) =>
    _NotifyWinEvent(event, hwnd, idObject, idChild);

final _NotifyWinEvent = _user32.lookupFunction<
    Void Function(Uint32 event, IntPtr hwnd, Int32 idObject, Int32 idChild),
    void Function(
        int event, int hwnd, int idObject, int idChild)>('NotifyWinEvent');

/// Maps OEMASCII codes 0 through 0x0FF into the OEM scan codes and shift
/// states. The function provides information that allows a program to send
/// OEM text to another program by simulating keyboard input.
///
/// ```c
/// DWORD OemKeyScan(
///   WORD wOemChar
/// );
/// ```
/// {@category user32}
int OemKeyScan(int wOemChar) => _OemKeyScan(wOemChar);

final _OemKeyScan = _user32.lookupFunction<Uint32 Function(Uint16 wOemChar),
    int Function(int wOemChar)>('OemKeyScan');

/// The OffsetRect function moves the specified rectangle by the specified
/// offsets.
///
/// ```c
/// BOOL OffsetRect(
///   LPRECT lprc,
///   int    dx,
///   int    dy
/// );
/// ```
/// {@category user32}
int OffsetRect(Pointer<RECT> lprc, int dx, int dy) => _OffsetRect(lprc, dx, dy);

final _OffsetRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprc, Int32 dx, Int32 dy),
    int Function(Pointer<RECT> lprc, int dx, int dy)>('OffsetRect');

/// Opens the clipboard for examination and prevents other applications from
/// modifying the clipboard content.
///
/// ```c
/// BOOL OpenClipboard(
///   HWND hWndNewOwner
/// );
/// ```
/// {@category user32}
int OpenClipboard(int hWndNewOwner) => _OpenClipboard(hWndNewOwner);

final _OpenClipboard = _user32.lookupFunction<
    Int32 Function(IntPtr hWndNewOwner),
    int Function(int hWndNewOwner)>('OpenClipboard');

/// Opens the specified desktop object.
///
/// ```c
/// HDESK OpenDesktopW(
///   LPCWSTR     lpszDesktop,
///   DWORD       dwFlags,
///   BOOL        fInherit,
///   ACCESS_MASK dwDesiredAccess
/// );
/// ```
/// {@category user32}
int OpenDesktop(Pointer<Utf16> lpszDesktop, int dwFlags, int fInherit,
        int dwDesiredAccess) =>
    _OpenDesktop(lpszDesktop, dwFlags, fInherit, dwDesiredAccess);

final _OpenDesktop = _user32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpszDesktop, Uint32 dwFlags, Int32 fInherit,
        Uint32 dwDesiredAccess),
    int Function(Pointer<Utf16> lpszDesktop, int dwFlags, int fInherit,
        int dwDesiredAccess)>('OpenDesktopW');

/// Restores a minimized (iconic) window to its previous size and position;
/// it then activates the window.
///
/// ```c
/// BOOL OpenIcon(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int OpenIcon(int hWnd) => _OpenIcon(hWnd);

final _OpenIcon =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'OpenIcon');

/// Opens the desktop that receives user input.
///
/// ```c
/// HDESK OpenInputDesktop(
///   DWORD       dwFlags,
///   BOOL        fInherit,
///   ACCESS_MASK dwDesiredAccess
/// );
/// ```
/// {@category user32}
int OpenInputDesktop(int dwFlags, int fInherit, int dwDesiredAccess) =>
    _OpenInputDesktop(dwFlags, fInherit, dwDesiredAccess);

final _OpenInputDesktop = _user32.lookupFunction<
    IntPtr Function(Uint32 dwFlags, Int32 fInherit, Uint32 dwDesiredAccess),
    int Function(
        int dwFlags, int fInherit, int dwDesiredAccess)>('OpenInputDesktop');

/// Opens the specified window station.
///
/// ```c
/// HWINSTA OpenWindowStationW(
///   LPCWSTR     lpszWinSta,
///   BOOL        fInherit,
///   ACCESS_MASK dwDesiredAccess
/// );
/// ```
/// {@category user32}
int OpenWindowStation(
        Pointer<Utf16> lpszWinSta, int fInherit, int dwDesiredAccess) =>
    _OpenWindowStation(lpszWinSta, fInherit, dwDesiredAccess);

final _OpenWindowStation = _user32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpszWinSta, Int32 fInherit, Uint32 dwDesiredAccess),
    int Function(Pointer<Utf16> lpszWinSta, int fInherit,
        int dwDesiredAccess)>('OpenWindowStationW');

/// The PaintDesktop function fills the clipping region in the specified
/// device context with the desktop pattern or wallpaper. The function is
/// provided primarily for shell desktops.
///
/// ```c
/// BOOL PaintDesktop(
///   HDC hdc
/// );
/// ```
/// {@category user32}
int PaintDesktop(int hdc) => _PaintDesktop(hdc);

final _PaintDesktop =
    _user32.lookupFunction<Int32 Function(IntPtr hdc), int Function(int hdc)>(
        'PaintDesktop');

/// Dispatches incoming sent messages, checks the thread message queue for a
/// posted message, and retrieves the message (if any exist).
///
/// ```c
/// BOOL PeekMessageW(
///   LPMSG lpMsg,
///   HWND  hWnd,
///   UINT  wMsgFilterMin,
///   UINT  wMsgFilterMax,
///   UINT  wRemoveMsg
/// );
/// ```
/// {@category user32}
int PeekMessage(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax, int wRemoveMsg) =>
    _PeekMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);

final _PeekMessage = _user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
        Uint32 wMsgFilterMax, Uint32 wRemoveMsg),
    int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax, int wRemoveMsg)>('PeekMessageW');

/// Converts the physical coordinates of a point in a window to logical
/// coordinates.
///
/// ```c
/// BOOL PhysicalToLogicalPoint(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int PhysicalToLogicalPoint(int hWnd, Pointer<POINT> lpPoint) =>
    _PhysicalToLogicalPoint(hWnd, lpPoint);

final _PhysicalToLogicalPoint = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd, Pointer<POINT> lpPoint)>('PhysicalToLogicalPoint');

/// Converts a point in a window from physical coordinates into logical
/// coordinates, regardless of the dots per inch (dpi) awareness of the
/// caller.
///
/// ```c
/// BOOL PhysicalToLogicalPointForPerMonitorDPI(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int PhysicalToLogicalPointForPerMonitorDPI(int hWnd, Pointer<POINT> lpPoint) =>
    _PhysicalToLogicalPointForPerMonitorDPI(hWnd, lpPoint);

final _PhysicalToLogicalPointForPerMonitorDPI = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd,
        Pointer<POINT> lpPoint)>('PhysicalToLogicalPointForPerMonitorDPI');

/// Places (posts) a message in the message queue associated with the thread
/// that created the specified window and returns without waiting for the
/// thread to process the message.
///
/// ```c
/// BOOL PostMessageW(
///   HWND   hWnd,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int PostMessage(int hWnd, int Msg, int wParam, int lParam) =>
    _PostMessage(hWnd, Msg, wParam, lParam);

final _PostMessage = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(int hWnd, int Msg, int wParam, int lParam)>('PostMessageW');

/// Indicates to the system that a thread has made a request to terminate
/// (quit). It is typically used in response to a WM_DESTROY message.
///
/// ```c
/// void PostQuitMessage(
///   int nExitCode
/// );
/// ```
/// {@category user32}
void PostQuitMessage(int nExitCode) => _PostQuitMessage(nExitCode);

final _PostQuitMessage = _user32.lookupFunction<Void Function(Int32 nExitCode),
    void Function(int nExitCode)>('PostQuitMessage');

/// Posts a message to the message queue of the specified thread. It returns
/// without waiting for the thread to process the message.
///
/// ```c
/// BOOL PostThreadMessageW(
///   DWORD  idThread,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int PostThreadMessage(int idThread, int Msg, int wParam, int lParam) =>
    _PostThreadMessage(idThread, Msg, wParam, lParam);

final _PostThreadMessage = _user32.lookupFunction<
    Int32 Function(Uint32 idThread, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(
        int idThread, int Msg, int wParam, int lParam)>('PostThreadMessageW');

/// The PrintWindow function copies a visual window into the specified
/// device context (DC), typically a printer DC.
///
/// ```c
/// BOOL PrintWindow(
///   HWND hwnd,
///   HDC  hdcBlt,
///   UINT nFlags
/// );
/// ```
/// {@category user32}
int PrintWindow(int hwnd, int hdcBlt, int nFlags) =>
    _PrintWindow(hwnd, hdcBlt, nFlags);

final _PrintWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, IntPtr hdcBlt, Uint32 nFlags),
    int Function(int hwnd, int hdcBlt, int nFlags)>('PrintWindow');

/// The PtInRect function determines whether the specified point lies within
/// the specified rectangle. A point is within a rectangle if it lies on the
/// left or top side or is within all four sides. A point on the right or
/// bottom side is considered outside the rectangle.
///
/// ```c
/// BOOL PtInRect(
///   const RECT *lprc,
///   POINT      pt
/// );
/// ```
/// {@category user32}
int PtInRect(Pointer<RECT> lprc, POINT pt) => _PtInRect(lprc, pt);

final _PtInRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprc, POINT pt),
    int Function(Pointer<RECT> lprc, POINT pt)>('PtInRect');

/// The RedrawWindow function updates the specified rectangle or region in a
/// window's client area.
///
/// ```c
/// BOOL RedrawWindow(
///   HWND       hWnd,
///   const RECT *lprcUpdate,
///   HRGN       hrgnUpdate,
///   UINT       flags
/// );
/// ```
/// {@category user32}
int RedrawWindow(
        int hWnd, Pointer<RECT> lprcUpdate, int hrgnUpdate, int flags) =>
    _RedrawWindow(hWnd, lprcUpdate, hrgnUpdate, flags);

final _RedrawWindow = _user32.lookupFunction<
    Int32 Function(
        IntPtr hWnd, Pointer<RECT> lprcUpdate, IntPtr hrgnUpdate, Uint32 flags),
    int Function(int hWnd, Pointer<RECT> lprcUpdate, int hrgnUpdate,
        int flags)>('RedrawWindow');

/// Registers a window class for subsequent use in calls to the CreateWindow
/// or CreateWindowEx function.
///
/// ```c
/// ATOM RegisterClassW(
///   const WNDCLASSW *lpWndClass
/// );
/// ```
/// {@category user32}
int RegisterClass(Pointer<WNDCLASS> lpWndClass) => _RegisterClass(lpWndClass);

final _RegisterClass = _user32.lookupFunction<
    Uint16 Function(Pointer<WNDCLASS> lpWndClass),
    int Function(Pointer<WNDCLASS> lpWndClass)>('RegisterClassW');

/// Registers a window class for subsequent use in calls to the CreateWindow
/// or CreateWindowEx function.
///
/// ```c
/// ATOM RegisterClassExW(
///   const WNDCLASSEXW *unnamedParam1);
/// ```
/// {@category user32}
int RegisterClassEx(Pointer<WNDCLASSEX> param0) => _RegisterClassEx(param0);

final _RegisterClassEx = _user32.lookupFunction<
    Uint16 Function(Pointer<WNDCLASSEX> param0),
    int Function(Pointer<WNDCLASSEX> param0)>('RegisterClassExW');

/// Registers a new clipboard format. This format can then be used as a
/// valid clipboard format.
///
/// ```c
/// UINT RegisterClipboardFormatW(
///   LPCWSTR lpszFormat
/// );
/// ```
/// {@category user32}
int RegisterClipboardFormat(Pointer<Utf16> lpszFormat) =>
    _RegisterClipboardFormat(lpszFormat);

final _RegisterClipboardFormat = _user32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpszFormat),
    int Function(Pointer<Utf16> lpszFormat)>('RegisterClipboardFormatW');

/// Defines a system-wide hot key.
///
/// ```c
/// BOOL RegisterHotKey(
///   HWND hWnd,
///   int  id,
///   UINT fsModifiers,
///   UINT vk
/// );
/// ```
/// {@category user32}
int RegisterHotKey(int hWnd, int id, int fsModifiers, int vk) =>
    _RegisterHotKey(hWnd, id, fsModifiers, vk);

final _RegisterHotKey = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 id, Uint32 fsModifiers, Uint32 vk),
    int Function(int hWnd, int id, int fsModifiers, int vk)>('RegisterHotKey');

/// Registers the application to receive power setting notifications for the
/// specific power setting event.
///
/// ```c
/// HPOWERNOTIFY RegisterPowerSettingNotification(
///   HANDLE  hRecipient,
///   LPCGUID PowerSettingGuid,
///   DWORD   Flags
/// );
/// ```
/// {@category user32}
int RegisterPowerSettingNotification(
        int hRecipient, Pointer<GUID> PowerSettingGuid, int Flags) =>
    _RegisterPowerSettingNotification(hRecipient, PowerSettingGuid, Flags);

final _RegisterPowerSettingNotification = _user32.lookupFunction<
    IntPtr Function(
        IntPtr hRecipient, Pointer<GUID> PowerSettingGuid, Uint32 Flags),
    int Function(int hRecipient, Pointer<GUID> PowerSettingGuid,
        int Flags)>('RegisterPowerSettingNotification');

/// Registers the devices that supply the raw input data.
///
/// ```c
/// BOOL RegisterRawInputDevices(
///   PCRAWINPUTDEVICE pRawInputDevices,
///   UINT             uiNumDevices,
///   UINT             cbSize
/// );
/// ```
/// {@category user32}
int RegisterRawInputDevices(Pointer<RAWINPUTDEVICE> pRawInputDevices,
        int uiNumDevices, int cbSize) =>
    _RegisterRawInputDevices(pRawInputDevices, uiNumDevices, cbSize);

final _RegisterRawInputDevices = _user32.lookupFunction<
    Int32 Function(Pointer<RAWINPUTDEVICE> pRawInputDevices,
        Uint32 uiNumDevices, Uint32 cbSize),
    int Function(Pointer<RAWINPUTDEVICE> pRawInputDevices, int uiNumDevices,
        int cbSize)>('RegisterRawInputDevices');

/// Registers a window to process the WM_TOUCHHITTESTING notification.
///
/// ```c
/// BOOL RegisterTouchHitTestingWindow(
///   HWND  hwnd,
///   ULONG value
/// );
/// ```
/// {@category user32}
int RegisterTouchHitTestingWindow(int hwnd, int value) =>
    _RegisterTouchHitTestingWindow(hwnd, value);

final _RegisterTouchHitTestingWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Uint32 value),
    int Function(int hwnd, int value)>('RegisterTouchHitTestingWindow');

/// Registers a window as being touch-capable.
///
/// ```c
/// BOOL RegisterTouchWindow(
///   HWND  hwnd,
///   ULONG ulFlags
/// );
/// ```
/// {@category user32}
int RegisterTouchWindow(int hwnd, int ulFlags) =>
    _RegisterTouchWindow(hwnd, ulFlags);

final _RegisterTouchWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Uint32 ulFlags),
    int Function(int hwnd, int ulFlags)>('RegisterTouchWindow');

/// Defines a new window message that is guaranteed to be unique throughout
/// the system. The message value can be used when sending or posting
/// messages.
///
/// ```c
/// UINT RegisterWindowMessageW(
///   LPCWSTR lpString
/// );
/// ```
/// {@category user32}
int RegisterWindowMessage(Pointer<Utf16> lpString) =>
    _RegisterWindowMessage(lpString);

final _RegisterWindowMessage = _user32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpString),
    int Function(Pointer<Utf16> lpString)>('RegisterWindowMessageW');

/// Releases the mouse capture from a window in the current thread and
/// restores normal mouse input processing. A window that has captured the
/// mouse receives all mouse input, regardless of the position of the
/// cursor, except when a mouse button is clicked while the cursor hot spot
/// is in the window of another thread.
///
/// ```c
/// BOOL ReleaseCapture();
/// ```
/// {@category user32}
int ReleaseCapture() => _ReleaseCapture();

final _ReleaseCapture =
    _user32.lookupFunction<Int32 Function(), int Function()>('ReleaseCapture');

/// The ReleaseDC function releases a device context (DC), freeing it for
/// use by other applications. The effect of the ReleaseDC function depends
/// on the type of DC. It frees only common and window DCs. It has no effect
/// on class or private DCs.
///
/// ```c
/// int ReleaseDC(
///   HWND hWnd,
///   HDC  hDC
/// );
/// ```
/// {@category user32}
int ReleaseDC(int hWnd, int hDC) => _ReleaseDC(hWnd, hDC);

final _ReleaseDC = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hDC),
    int Function(int hWnd, int hDC)>('ReleaseDC');

/// Removes the given window from the system-maintained clipboard format
/// listener list.
///
/// ```c
/// BOOL RemoveClipboardFormatListener(
///   HWND hwnd
/// );
/// ```
/// {@category user32}
int RemoveClipboardFormatListener(int hwnd) =>
    _RemoveClipboardFormatListener(hwnd);

final _RemoveClipboardFormatListener =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'RemoveClipboardFormatListener');

/// Deletes a menu item or detaches a submenu from the specified menu. If
/// the menu item opens a drop-down menu or submenu, RemoveMenu does not
/// destroy the menu or its handle, allowing the menu to be reused. Before
/// this function is called, the GetSubMenu function should retrieve a
/// handle to the drop-down menu or submenu.
///
/// ```c
/// BOOL RemoveMenu(
///   HMENU hMenu,
///   UINT  uPosition,
///   UINT  uFlags
/// );
/// ```
/// {@category user32}
int RemoveMenu(int hMenu, int uPosition, int uFlags) =>
    _RemoveMenu(hMenu, uPosition, uFlags);

final _RemoveMenu = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags),
    int Function(int hMenu, int uPosition, int uFlags)>('RemoveMenu');

/// Removes an entry from the property list of the specified window. The
/// specified character string identifies the entry to be removed.
///
/// ```c
/// HANDLE RemovePropW(
///   HWND    hWnd,
///   LPCWSTR lpString
/// );
/// ```
/// {@category user32}
int RemoveProp(int hWnd, Pointer<Utf16> lpString) =>
    _RemoveProp(hWnd, lpString);

final _RemoveProp = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Pointer<Utf16> lpString),
    int Function(int hWnd, Pointer<Utf16> lpString)>('RemovePropW');

/// Replies to a message sent from another thread by the SendMessage
/// function.
///
/// ```c
/// BOOL ReplyMessage(
///   LRESULT lResult
/// );
/// ```
/// {@category user32}
int ReplyMessage(int lResult) => _ReplyMessage(lResult);

final _ReplyMessage = _user32.lookupFunction<Int32 Function(IntPtr lResult),
    int Function(int lResult)>('ReplyMessage');

/// The ScreenToClient function converts the screen coordinates of a
/// specified point on the screen to client-area coordinates.
///
/// ```c
/// BOOL ScreenToClient(
///   HWND    hWnd,
///   LPPOINT lpPoint
/// );
/// ```
/// {@category user32}
int ScreenToClient(int hWnd, Pointer<POINT> lpPoint) =>
    _ScreenToClient(hWnd, lpPoint);

final _ScreenToClient = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<POINT> lpPoint),
    int Function(int hWnd, Pointer<POINT> lpPoint)>('ScreenToClient');

/// The ScrollDC function scrolls a rectangle of bits horizontally and
/// vertically.
///
/// ```c
/// BOOL ScrollDC(
///   HDC        hDC,
///   int        dx,
///   int        dy,
///   const RECT *lprcScroll,
///   const RECT *lprcClip,
///   HRGN       hrgnUpdate,
///   LPRECT     lprcUpdate
/// );
/// ```
/// {@category user32}
int ScrollDC(int hDC, int dx, int dy, Pointer<RECT> lprcScroll,
        Pointer<RECT> lprcClip, int hrgnUpdate, Pointer<RECT> lprcUpdate) =>
    _ScrollDC(hDC, dx, dy, lprcScroll, lprcClip, hrgnUpdate, lprcUpdate);

final _ScrollDC = _user32.lookupFunction<
    Int32 Function(IntPtr hDC, Int32 dx, Int32 dy, Pointer<RECT> lprcScroll,
        Pointer<RECT> lprcClip, IntPtr hrgnUpdate, Pointer<RECT> lprcUpdate),
    int Function(
        int hDC,
        int dx,
        int dy,
        Pointer<RECT> lprcScroll,
        Pointer<RECT> lprcClip,
        int hrgnUpdate,
        Pointer<RECT> lprcUpdate)>('ScrollDC');

/// The ScrollWindow function scrolls the contents of the specified window's
/// client area.
///
/// ```c
/// BOOL ScrollWindow(
///   HWND       hWnd,
///   int        XAmount,
///   int        YAmount,
///   const RECT *lpRect,
///   const RECT *lpClipRect
/// );
/// ```
/// {@category user32}
int ScrollWindow(int hWnd, int XAmount, int YAmount, Pointer<RECT> lpRect,
        Pointer<RECT> lpClipRect) =>
    _ScrollWindow(hWnd, XAmount, YAmount, lpRect, lpClipRect);

final _ScrollWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 XAmount, Int32 YAmount,
        Pointer<RECT> lpRect, Pointer<RECT> lpClipRect),
    int Function(int hWnd, int XAmount, int YAmount, Pointer<RECT> lpRect,
        Pointer<RECT> lpClipRect)>('ScrollWindow');

/// The ScrollWindowEx function scrolls the contents of the specified
/// window's client area.
///
/// ```c
/// int ScrollWindowEx(
///   HWND       hWnd,
///   int        dx,
///   int        dy,
///   const RECT *prcScroll,
///   const RECT *prcClip,
///   HRGN       hrgnUpdate,
///   LPRECT     prcUpdate,
///   UINT       flags
/// );
/// ```
/// {@category user32}
int ScrollWindowEx(
        int hWnd,
        int dx,
        int dy,
        Pointer<RECT> prcScroll,
        Pointer<RECT> prcClip,
        int hrgnUpdate,
        Pointer<RECT> prcUpdate,
        int flags) =>
    _ScrollWindowEx(
        hWnd, dx, dy, prcScroll, prcClip, hrgnUpdate, prcUpdate, flags);

final _ScrollWindowEx = _user32.lookupFunction<
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

/// Sends a message to the specified control in a dialog box.
///
/// ```c
/// LRESULT SendDlgItemMessageW(
///   HWND   hDlg,
///   int    nIDDlgItem,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int SendDlgItemMessage(
        int hDlg, int nIDDlgItem, int Msg, int wParam, int lParam) =>
    _SendDlgItemMessage(hDlg, nIDDlgItem, Msg, wParam, lParam);

final _SendDlgItemMessage = _user32.lookupFunction<
    IntPtr Function(IntPtr hDlg, Int32 nIDDlgItem, Uint32 Msg, IntPtr wParam,
        IntPtr lParam),
    int Function(int hDlg, int nIDDlgItem, int Msg, int wParam,
        int lParam)>('SendDlgItemMessageW');

/// Synthesizes keystrokes, mouse motions, and button clicks.
///
/// ```c
/// UINT SendInput(
///   UINT    cInputs,
///   LPINPUT pInputs,
///   int     cbSize
/// );
/// ```
/// {@category user32}
int SendInput(int cInputs, Pointer<INPUT> pInputs, int cbSize) =>
    _SendInput(cInputs, pInputs, cbSize);

final _SendInput = _user32.lookupFunction<
    Uint32 Function(Uint32 cInputs, Pointer<INPUT> pInputs, Int32 cbSize),
    int Function(int cInputs, Pointer<INPUT> pInputs, int cbSize)>('SendInput');

/// Sends the specified message to a window or windows. The SendMessage
/// function calls the window procedure for the specified window and does
/// not return until the window procedure has processed the message.
///
/// ```c
/// LRESULT SendMessageW(
///   HWND   hWnd,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int SendMessage(int hWnd, int Msg, int wParam, int lParam) =>
    _SendMessage(hWnd, Msg, wParam, lParam);

final _SendMessage = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(int hWnd, int Msg, int wParam, int lParam)>('SendMessageW');

/// Sends the specified message to a window or windows. It calls the window
/// procedure for the specified window and returns immediately if the window
/// belongs to another thread. After the window procedure processes the
/// message, the system calls the specified callback function, passing the
/// result of the message processing and an application-defined value to the
/// callback function.
///
/// ```c
/// BOOL SendMessageCallbackW(
///   HWND          hWnd,
///   UINT          Msg,
///   WPARAM        wParam,
///   LPARAM        lParam,
///   SENDASYNCPROC lpResultCallBack,
///   ULONG_PTR     dwData
/// );
/// ```
/// {@category user32}
int SendMessageCallback(int hWnd, int Msg, int wParam, int lParam,
        Pointer<NativeFunction<SendAsyncProc>> lpResultCallBack, int dwData) =>
    _SendMessageCallback(hWnd, Msg, wParam, lParam, lpResultCallBack, dwData);

final _SendMessageCallback = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam,
        Pointer<NativeFunction<SendAsyncProc>> lpResultCallBack, IntPtr dwData),
    int Function(
        int hWnd,
        int Msg,
        int wParam,
        int lParam,
        Pointer<NativeFunction<SendAsyncProc>> lpResultCallBack,
        int dwData)>('SendMessageCallbackW');

/// Sends the specified message to one or more windows.
///
/// ```c
/// LRESULT SendMessageTimeoutW(
///   HWND       hWnd,
///   UINT       Msg,
///   WPARAM     wParam,
///   LPARAM     lParam,
///   UINT       fuFlags,
///   UINT       uTimeout,
///   PDWORD_PTR lpdwResult
/// );
/// ```
/// {@category user32}
int SendMessageTimeout(int hWnd, int Msg, int wParam, int lParam, int fuFlags,
        int uTimeout, Pointer<IntPtr> lpdwResult) =>
    _SendMessageTimeout(
        hWnd, Msg, wParam, lParam, fuFlags, uTimeout, lpdwResult);

final _SendMessageTimeout = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam,
        Uint32 fuFlags, Uint32 uTimeout, Pointer<IntPtr> lpdwResult),
    int Function(int hWnd, int Msg, int wParam, int lParam, int fuFlags,
        int uTimeout, Pointer<IntPtr> lpdwResult)>('SendMessageTimeoutW');

/// Sends the specified message to a window or windows. If the window was
/// created by the calling thread, SendNotifyMessage calls the window
/// procedure for the window and does not return until the window procedure
/// has processed the message. If the window was created by a different
/// thread, SendNotifyMessage passes the message to the window procedure and
/// returns immediately; it does not wait for the window procedure to finish
/// processing the message.
///
/// ```c
/// BOOL SendNotifyMessageW(
///   HWND   hWnd,
///   UINT   Msg,
///   WPARAM wParam,
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int SendNotifyMessage(int hWnd, int Msg, int wParam, int lParam) =>
    _SendNotifyMessage(hWnd, Msg, wParam, lParam);

final _SendNotifyMessage = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(
        int hWnd, int Msg, int wParam, int lParam)>('SendNotifyMessageW');

/// Activates a window. The window must be attached to the calling thread's
/// message queue.
///
/// ```c
/// HWND SetActiveWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int SetActiveWindow(int hWnd) => _SetActiveWindow(hWnd);

final _SetActiveWindow = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('SetActiveWindow');

/// Sets the mouse capture to the specified window belonging to the current
/// thread. SetCapture captures mouse input either when the mouse is over
/// the capturing window, or when the mouse button was pressed while the
/// mouse was over the capturing window and the button is still down. Only
/// one window at a time can capture the mouse.
///
/// ```c
/// HWND SetCapture(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int SetCapture(int hWnd) => _SetCapture(hWnd);

final _SetCapture = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('SetCapture');

/// Sets the caret blink time to the specified number of milliseconds. The
/// blink time is the elapsed time, in milliseconds, required to invert the
/// caret's pixels.
///
/// ```c
/// BOOL SetCaretBlinkTime(
///   UINT uMSeconds
/// );
/// ```
/// {@category user32}
int SetCaretBlinkTime(int uMSeconds) => _SetCaretBlinkTime(uMSeconds);

final _SetCaretBlinkTime = _user32.lookupFunction<
    Int32 Function(Uint32 uMSeconds),
    int Function(int uMSeconds)>('SetCaretBlinkTime');

/// Moves the caret to the specified coordinates. If the window that owns
/// the caret was created with the CS_OWNDC class style, then the specified
/// coordinates are subject to the mapping mode of the device context
/// associated with that window.
///
/// ```c
/// BOOL SetCaretPos(
///   int X,
///   int Y
/// );
/// ```
/// {@category user32}
int SetCaretPos(int X, int Y) => _SetCaretPos(X, Y);

final _SetCaretPos = _user32.lookupFunction<Int32 Function(Int32 X, Int32 Y),
    int Function(int X, int Y)>('SetCaretPos');

/// Places data on the clipboard in a specified clipboard format. The window
/// must be the current clipboard owner, and the application must have
/// called the OpenClipboard function.
///
/// ```c
/// HANDLE SetClipboardData(
///   UINT   uFormat,
///   HANDLE hMem
/// );
/// ```
/// {@category user32}
int SetClipboardData(int uFormat, int hMem) => _SetClipboardData(uFormat, hMem);

final _SetClipboardData = _user32.lookupFunction<
    IntPtr Function(Uint32 uFormat, IntPtr hMem),
    int Function(int uFormat, int hMem)>('SetClipboardData');

/// Adds the specified window to the chain of clipboard viewers.
///
/// ```c
/// HWND SetClipboardViewer(
///   HWND hWndNewViewer
/// );
/// ```
/// {@category user32}
int SetClipboardViewer(int hWndNewViewer) => _SetClipboardViewer(hWndNewViewer);

final _SetClipboardViewer = _user32.lookupFunction<
    IntPtr Function(IntPtr hWndNewViewer),
    int Function(int hWndNewViewer)>('SetClipboardViewer');

/// Creates a timer with the specified time-out value and coalescing
/// tolerance delay.
///
/// ```c
/// UINT_PTR SetCoalescableTimer(
///   HWND      hWnd,
///   UINT_PTR  nIDEvent,
///   UINT      uElapse,
///   TIMERPROC lpTimerFunc,
///   ULONG     uToleranceDelay
/// );
/// ```
/// {@category user32}
int SetCoalescableTimer(int hWnd, int nIDEvent, int uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc, int uToleranceDelay) =>
    _SetCoalescableTimer(hWnd, nIDEvent, uElapse, lpTimerFunc, uToleranceDelay);

final _SetCoalescableTimer = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, IntPtr nIDEvent, Uint32 uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc, Uint32 uToleranceDelay),
    int Function(
        int hWnd,
        int nIDEvent,
        int uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc,
        int uToleranceDelay)>('SetCoalescableTimer');

/// Sets the cursor shape.
///
/// ```c
/// HCURSOR SetCursor(
///   HCURSOR hCursor
/// );
/// ```
/// {@category user32}
int SetCursor(int hCursor) => _SetCursor(hCursor);

final _SetCursor = _user32.lookupFunction<IntPtr Function(IntPtr hCursor),
    int Function(int hCursor)>('SetCursor');

/// Moves the cursor to the specified screen coordinates. If the new
/// coordinates are not within the screen rectangle set by the most recent
/// ClipCursor function call, the system automatically adjusts the
/// coordinates so that the cursor stays within the rectangle.
///
/// ```c
/// BOOL SetCursorPos(
///   int X,
///   int Y
/// );
/// ```
/// {@category user32}
int SetCursorPos(int X, int Y) => _SetCursorPos(X, Y);

final _SetCursorPos = _user32.lookupFunction<Int32 Function(Int32 X, Int32 Y),
    int Function(int X, int Y)>('SetCursorPos');

/// Overrides the default per-monitor DPI scaling behavior of a child window
/// in a dialog.
///
/// ```c
/// BOOL SetDialogControlDpiChangeBehavior(
///   HWND                                hWnd,
///   DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS mask,
///   DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS values
/// );
/// ```
/// {@category user32}
int SetDialogControlDpiChangeBehavior(int hWnd, int mask, int values) =>
    _SetDialogControlDpiChangeBehavior(hWnd, mask, values);

final _SetDialogControlDpiChangeBehavior = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 mask, Uint32 values),
    int Function(
        int hWnd, int mask, int values)>('SetDialogControlDpiChangeBehavior');

/// Dialogs in Per-Monitor v2 contexts are automatically DPI scaled. This
/// method lets you customize their DPI change behavior. This function works
/// in conjunction with the DIALOG_DPI_CHANGE_BEHAVIORS enum in order to
/// override the default DPI scaling behavior for dialogs. This function is
/// called on a specified dialog, for which the specified flags are
/// individually saved.
///
/// ```c
/// BOOL SetDialogDpiChangeBehavior(
///   HWND                        hDlg,
///   DIALOG_DPI_CHANGE_BEHAVIORS mask,
///   DIALOG_DPI_CHANGE_BEHAVIORS values
/// );
/// ```
/// {@category user32}
int SetDialogDpiChangeBehavior(int hDlg, int mask, int values) =>
    _SetDialogDpiChangeBehavior(hDlg, mask, values);

final _SetDialogDpiChangeBehavior = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Uint32 mask, Uint32 values),
    int Function(int hDlg, int mask, int values)>('SetDialogDpiChangeBehavior');

/// Sets the screen auto-rotation preferences for the current process.
///
/// ```c
/// BOOL SetDisplayAutoRotationPreferences(
///   ORIENTATION_PREFERENCE orientation
/// );
/// ```
/// {@category user32}
int SetDisplayAutoRotationPreferences(int orientation) =>
    _SetDisplayAutoRotationPreferences(orientation);

final _SetDisplayAutoRotationPreferences = _user32.lookupFunction<
    Int32 Function(Int32 orientation),
    int Function(int orientation)>('SetDisplayAutoRotationPreferences');

/// Sets the text of a control in a dialog box to the string representation
/// of a specified integer value.
///
/// ```c
/// BOOL SetDlgItemInt(
///   HWND hDlg,
///   int  nIDDlgItem,
///   UINT uValue,
///   BOOL bSigned
/// );
/// ```
/// {@category user32}
int SetDlgItemInt(int hDlg, int nIDDlgItem, int uValue, int bSigned) =>
    _SetDlgItemInt(hDlg, nIDDlgItem, uValue, bSigned);

final _SetDlgItemInt = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Int32 nIDDlgItem, Uint32 uValue, Int32 bSigned),
    int Function(
        int hDlg, int nIDDlgItem, int uValue, int bSigned)>('SetDlgItemInt');

/// Sets the title or text of a control in a dialog box.
///
/// ```c
/// BOOL SetDlgItemTextW(
///   HWND    hDlg,
///   int     nIDDlgItem,
///   LPCWSTR lpString
/// );
/// ```
/// {@category user32}
int SetDlgItemText(int hDlg, int nIDDlgItem, Pointer<Utf16> lpString) =>
    _SetDlgItemText(hDlg, nIDDlgItem, lpString);

final _SetDlgItemText = _user32.lookupFunction<
    Int32 Function(IntPtr hDlg, Int32 nIDDlgItem, Pointer<Utf16> lpString),
    int Function(
        int hDlg, int nIDDlgItem, Pointer<Utf16> lpString)>('SetDlgItemTextW');

/// Sets the double-click time for the mouse. A double-click is a series of
/// two clicks of a mouse button, the second occurring within a specified
/// time after the first. The double-click time is the maximum number of
/// milliseconds that may occur between the first and second clicks of a
/// double-click.
///
/// ```c
/// BOOL SetDoubleClickTime(
///   UINT Arg1
/// );
/// ```
/// {@category user32}
int SetDoubleClickTime(int param0) => _SetDoubleClickTime(param0);

final _SetDoubleClickTime = _user32.lookupFunction<
    Int32 Function(Uint32 param0),
    int Function(int param0)>('SetDoubleClickTime');

/// Sets the keyboard focus to the specified window. The window must be
/// attached to the calling thread's message queue.
///
/// ```c
/// HWND SetFocus(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int SetFocus(int hWnd) => _SetFocus(hWnd);

final _SetFocus = _user32.lookupFunction<IntPtr Function(IntPtr hWnd),
    int Function(int hWnd)>('SetFocus');

/// Brings the thread that created the specified window into the foreground
/// and activates the window. Keyboard input is directed to the window, and
/// various visual cues are changed for the user. The system assigns a
/// slightly higher priority to the thread that created the foreground
/// window than it does to other threads.
///
/// ```c
/// BOOL SetForegroundWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int SetForegroundWindow(int hWnd) => _SetForegroundWindow(hWnd);

final _SetForegroundWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'SetForegroundWindow');

/// Configures the messages that are sent from a window for Windows Touch
/// gestures.
///
/// ```c
/// BOOL SetGestureConfig(
///   HWND           hwnd,
///   DWORD          dwReserved,
///   UINT           cIDs,
///   PGESTURECONFIG pGestureConfig,
///   UINT           cbSize
/// );
/// ```
/// {@category user32}
int SetGestureConfig(int hwnd, int dwReserved, int cIDs,
        Pointer<GESTURECONFIG> pGestureConfig, int cbSize) =>
    _SetGestureConfig(hwnd, dwReserved, cIDs, pGestureConfig, cbSize);

final _SetGestureConfig = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Uint32 dwReserved, Uint32 cIDs,
        Pointer<GESTURECONFIG> pGestureConfig, Uint32 cbSize),
    int Function(int hwnd, int dwReserved, int cIDs,
        Pointer<GESTURECONFIG> pGestureConfig, int cbSize)>('SetGestureConfig');

/// Copies an array of keyboard key states into the calling thread's
/// keyboard input-state table. This is the same table accessed by the
/// GetKeyboardState and GetKeyState functions. Changes made to this table
/// do not affect keyboard input to any other thread.
///
/// ```c
/// BOOL SetKeyboardState(
///   LPBYTE lpKeyState
/// );
/// ```
/// {@category user32}
int SetKeyboardState(Pointer<Uint8> lpKeyState) =>
    _SetKeyboardState(lpKeyState);

final _SetKeyboardState = _user32.lookupFunction<
    Int32 Function(Pointer<Uint8> lpKeyState),
    int Function(Pointer<Uint8> lpKeyState)>('SetKeyboardState');

/// Sets the opacity and transparency color key of a layered window.
///
/// ```c
/// BOOL SetLayeredWindowAttributes(
///   HWND     hwnd,
///   COLORREF crKey,
///   BYTE     bAlpha,
///   DWORD    dwFlags
/// );
/// ```
/// {@category user32}
int SetLayeredWindowAttributes(int hwnd, int crKey, int bAlpha, int dwFlags) =>
    _SetLayeredWindowAttributes(hwnd, crKey, bAlpha, dwFlags);

final _SetLayeredWindowAttributes = _user32.lookupFunction<
    Int32 Function(IntPtr hwnd, Uint32 crKey, Uint8 bAlpha, Uint32 dwFlags),
    int Function(int hwnd, int crKey, int bAlpha,
        int dwFlags)>('SetLayeredWindowAttributes');

/// Sets information for a specified menu.
///
/// ```c
/// BOOL SetMenuInfo(
///   HMENU       hmenu,
///   LPCMENUINFO lpmi
/// );
/// ```
/// {@category user32}
int SetMenuInfo(int param0, Pointer<MENUINFO> param1) =>
    _SetMenuInfo(param0, param1);

final _SetMenuInfo = _user32.lookupFunction<
    Int32 Function(IntPtr param0, Pointer<MENUINFO> param1),
    int Function(int param0, Pointer<MENUINFO> param1)>('SetMenuInfo');

/// Associates the specified bitmap with a menu item. Whether the menu item
/// is selected or clear, the system displays the appropriate bitmap next to
/// the menu item.
///
/// ```c
/// BOOL SetMenuItemBitmaps(
///   HMENU   hMenu,
///   UINT    uPosition,
///   UINT    uFlags,
///   HBITMAP hBitmapUnchecked,
///   HBITMAP hBitmapChecked
/// );
/// ```
/// {@category user32}
int SetMenuItemBitmaps(int hMenu, int uPosition, int uFlags,
        int hBitmapUnchecked, int hBitmapChecked) =>
    _SetMenuItemBitmaps(
        hMenu, uPosition, uFlags, hBitmapUnchecked, hBitmapChecked);

final _SetMenuItemBitmaps = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uPosition, Uint32 uFlags,
        IntPtr hBitmapUnchecked, IntPtr hBitmapChecked),
    int Function(int hMenu, int uPosition, int uFlags, int hBitmapUnchecked,
        int hBitmapChecked)>('SetMenuItemBitmaps');

/// Changes information about a menu item.
///
/// ```c
/// BOOL SetMenuItemInfoW(
///   HMENU            hmenu,
///   UINT             item,
///   BOOL             fByPositon,
///   LPCMENUITEMINFOW lpmii
/// );
/// ```
/// {@category user32}
int SetMenuItemInfo(
        int hmenu, int item, int fByPositon, Pointer<MENUITEMINFO> lpmii) =>
    _SetMenuItemInfo(hmenu, item, fByPositon, lpmii);

final _SetMenuItemInfo = _user32.lookupFunction<
    Int32 Function(IntPtr hmenu, Uint32 item, Int32 fByPositon,
        Pointer<MENUITEMINFO> lpmii),
    int Function(int hmenu, int item, int fByPositon,
        Pointer<MENUITEMINFO> lpmii)>('SetMenuItemInfoW');

/// Sets the extra message information for the current thread. Extra message
/// information is an application- or driver-defined value associated with
/// the current thread's message queue. An application can use the
/// GetMessageExtraInfo function to retrieve a thread's extra message
/// information.
///
/// ```c
/// LPARAM SetMessageExtraInfo(
///   LPARAM lParam
/// );
/// ```
/// {@category user32}
int SetMessageExtraInfo(int lParam) => _SetMessageExtraInfo(lParam);

final _SetMessageExtraInfo = _user32.lookupFunction<
    IntPtr Function(IntPtr lParam),
    int Function(int lParam)>('SetMessageExtraInfo');

/// Changes the parent window of the specified child window.
///
/// ```c
/// HWND SetParent(
///   HWND hWndChild,
///   HWND hWndNewParent
/// );
/// ```
/// {@category user32}
int SetParent(int hWndChild, int hWndNewParent) =>
    _SetParent(hWndChild, hWndNewParent);

final _SetParent = _user32.lookupFunction<
    IntPtr Function(IntPtr hWndChild, IntPtr hWndNewParent),
    int Function(int hWndChild, int hWndNewParent)>('SetParent');

/// Sets the process-default DPI awareness to system-DPI awareness.
///
/// ```c
/// BOOL SetProcessDPIAware();
/// ```
/// {@category user32}
int SetProcessDPIAware() => _SetProcessDPIAware();

final _SetProcessDPIAware = _user32
    .lookupFunction<Int32 Function(), int Function()>('SetProcessDPIAware');

/// It is recommended that you set the process-default DPI awareness via
/// application manifest. See Setting the default DPI awareness for a
/// process for more information. Setting the process-default DPI awareness
/// via API call can lead to unexpected application behavior. Sets the
/// current process to a specified dots per inch (dpi) awareness context.
/// The DPI awareness contexts are from the DPI_AWARENESS_CONTEXT value.
///
/// ```c
/// BOOL SetProcessDpiAwarenessContext(
///   DPI_AWARENESS_CONTEXT value
/// );
/// ```
/// {@category user32}
int SetProcessDpiAwarenessContext(int value) =>
    _SetProcessDpiAwarenessContext(value);

final _SetProcessDpiAwarenessContext = _user32.lookupFunction<
    Int32 Function(IntPtr value),
    int Function(int value)>('SetProcessDpiAwarenessContext');

/// Adds a new entry or changes an existing entry in the property list of
/// the specified window. The function adds a new entry to the list if the
/// specified character string does not exist already in the list. The new
/// entry contains the string and the handle. Otherwise, the function
/// replaces the string's current handle with the specified handle.
///
/// ```c
/// BOOL SetPropW(
///   HWND    hWnd,
///   LPCWSTR lpString,
///   HANDLE  hData
/// );
/// ```
/// {@category user32}
int SetProp(int hWnd, Pointer<Utf16> lpString, int hData) =>
    _SetProp(hWnd, lpString, hData);

final _SetProp = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString, IntPtr hData),
    int Function(int hWnd, Pointer<Utf16> lpString, int hData)>('SetPropW');

/// The SetRect function sets the coordinates of the specified rectangle.
/// This is equivalent to assigning the left, top, right, and bottom
/// arguments to the appropriate members of the RECT structure.
///
/// ```c
/// BOOL SetRect(
///   LPRECT lprc,
///   int    xLeft,
///   int    yTop,
///   int    xRight,
///   int    yBottom
/// );
/// ```
/// {@category user32}
int SetRect(Pointer<RECT> lprc, int xLeft, int yTop, int xRight, int yBottom) =>
    _SetRect(lprc, xLeft, yTop, xRight, yBottom);

final _SetRect = _user32.lookupFunction<
    Int32 Function(Pointer<RECT> lprc, Int32 xLeft, Int32 yTop, Int32 xRight,
        Int32 yBottom),
    int Function(Pointer<RECT> lprc, int xLeft, int yTop, int xRight,
        int yBottom)>('SetRect');

/// The SetRectEmpty function creates an empty rectangle in which all
/// coordinates are set to zero.
///
/// ```c
/// BOOL SetRectEmpty(
///   LPRECT lprc
/// );
/// ```
/// {@category user32}
int SetRectEmpty(Pointer<RECT> lprc) => _SetRectEmpty(lprc);

final _SetRectEmpty = _user32.lookupFunction<Int32 Function(Pointer<RECT> lprc),
    int Function(Pointer<RECT> lprc)>('SetRectEmpty');

/// The SetScrollInfo function sets the parameters of a scroll bar,
/// including the minimum and maximum scrolling positions, the page size,
/// and the position of the scroll box (thumb). The function also redraws
/// the scroll bar, if requested.
///
/// ```c
/// int SetScrollInfo(
///   HWND          hwnd,
///   int           nBar,
///   LPCSCROLLINFO lpsi,
///   BOOL          redraw
/// );
/// ```
/// {@category user32}
int SetScrollInfo(int hwnd, int nBar, Pointer<SCROLLINFO> lpsi, int redraw) =>
    _SetScrollInfo(hwnd, nBar, lpsi, redraw);

final _SetScrollInfo = _user32.lookupFunction<
    Int32 Function(
        IntPtr hwnd, Uint32 nBar, Pointer<SCROLLINFO> lpsi, Int32 redraw),
    int Function(int hwnd, int nBar, Pointer<SCROLLINFO> lpsi,
        int redraw)>('SetScrollInfo');

/// Sets the colors for the specified display elements. Display elements are
/// the various parts of a window and the display that appear on the system
/// display screen.
///
/// ```c
/// BOOL SetSysColors(
///   int            cElements,
///   const INT      *lpaElements,
///   const COLORREF *lpaRgbValues
/// );
/// ```
/// {@category user32}
int SetSysColors(int cElements, Pointer<Int32> lpaElements,
        Pointer<Uint32> lpaRgbValues) =>
    _SetSysColors(cElements, lpaElements, lpaRgbValues);

final _SetSysColors = _user32.lookupFunction<
    Int32 Function(Int32 cElements, Pointer<Int32> lpaElements,
        Pointer<Uint32> lpaRgbValues),
    int Function(int cElements, Pointer<Int32> lpaElements,
        Pointer<Uint32> lpaRgbValues)>('SetSysColors');

/// Enables an application to customize the system cursors. It replaces the
/// contents of the system cursor specified by the id parameter with the
/// contents of the cursor specified by the hcur parameter and then destroys
/// hcur.
///
/// ```c
/// BOOL SetSystemCursor(
///   HCURSOR hcur,
///   DWORD   id
/// );
/// ```
/// {@category user32}
int SetSystemCursor(int hcur, int id) => _SetSystemCursor(hcur, id);

final _SetSystemCursor = _user32.lookupFunction<
    Int32 Function(IntPtr hcur, Uint32 id),
    int Function(int hcur, int id)>('SetSystemCursor');

/// Set the DPI awareness for the current thread to the provided value.
///
/// ```c
/// DPI_AWARENESS_CONTEXT SetThreadDpiAwarenessContext(
///   DPI_AWARENESS_CONTEXT dpiContext
/// );
/// ```
/// {@category user32}
int SetThreadDpiAwarenessContext(int dpiContext) =>
    _SetThreadDpiAwarenessContext(dpiContext);

final _SetThreadDpiAwarenessContext = _user32.lookupFunction<
    IntPtr Function(IntPtr dpiContext),
    int Function(int dpiContext)>('SetThreadDpiAwarenessContext');

/// Sets the thread's DPI_HOSTING_BEHAVIOR. This behavior allows windows
/// created in the thread to host child windows with a different
/// DPI_AWARENESS_CONTEXT.
///
/// ```c
/// DPI_HOSTING_BEHAVIOR SetThreadDpiHostingBehavior(
///   DPI_HOSTING_BEHAVIOR value
/// );
/// ```
/// {@category user32}
int SetThreadDpiHostingBehavior(int value) =>
    _SetThreadDpiHostingBehavior(value);

final _SetThreadDpiHostingBehavior = _user32.lookupFunction<
    Int32 Function(Int32 value),
    int Function(int value)>('SetThreadDpiHostingBehavior');

/// Creates a timer with the specified time-out value.
///
/// ```c
/// UINT_PTR SetTimer(
///   HWND      hWnd,
///   UINT_PTR  nIDEvent,
///   UINT      uElapse,
///   TIMERPROC lpTimerFunc
/// );
/// ```
/// {@category user32}
int SetTimer(int hWnd, int nIDEvent, int uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc) =>
    _SetTimer(hWnd, nIDEvent, uElapse, lpTimerFunc);

final _SetTimer = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, IntPtr nIDEvent, Uint32 uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc),
    int Function(int hWnd, int nIDEvent, int uElapse,
        Pointer<NativeFunction<TimerProc>> lpTimerFunc)>('SetTimer');

/// Sets information about the specified window station or desktop object.
///
/// ```c
/// BOOL SetUserObjectInformationW(
///   HANDLE hObj,
///   int    nIndex,
///   PVOID  pvInfo,
///   DWORD  nLength
/// );
/// ```
/// {@category user32}
int SetUserObjectInformation(
        int hObj, int nIndex, Pointer pvInfo, int nLength) =>
    _SetUserObjectInformation(hObj, nIndex, pvInfo, nLength);

final _SetUserObjectInformation = _user32.lookupFunction<
    Int32 Function(IntPtr hObj, Int32 nIndex, Pointer pvInfo, Uint32 nLength),
    int Function(int hObj, int nIndex, Pointer pvInfo,
        int nLength)>('SetUserObjectInformationW');

/// Specifies where the content of the window can be displayed.
///
/// ```c
/// BOOL SetWindowDisplayAffinity(
///   HWND  hWnd,
///   DWORD dwAffinity
/// );
/// ```
/// {@category user32}
int SetWindowDisplayAffinity(int hWnd, int dwAffinity) =>
    _SetWindowDisplayAffinity(hWnd, dwAffinity);

final _SetWindowDisplayAffinity = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 dwAffinity),
    int Function(int hWnd, int dwAffinity)>('SetWindowDisplayAffinity');

/// Changes an attribute of the specified window. The function also sets a
/// value at the specified offset in the extra window memory.
///
/// ```c
/// LONG_PTR SetWindowLongPtrW(
///   HWND     hWnd,
///   int      nIndex,
///   LONG_PTR dwNewLong
/// );
/// ```
/// {@category user32}
int SetWindowLongPtr(int hWnd, int nIndex, int dwNewLong) =>
    _SetWindowLongPtr(hWnd, nIndex, dwNewLong);

final _SetWindowLongPtr = _user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Int32 nIndex, IntPtr dwNewLong),
    int Function(int hWnd, int nIndex, int dwNewLong)>('SetWindowLongPtrW');

/// Sets the show state and the restored, minimized, and maximized positions
/// of the specified window.
///
/// ```c
/// BOOL SetWindowPlacement(
///   HWND                  hWnd,
///   const WINDOWPLACEMENT *lpwndpl
/// );
/// ```
/// {@category user32}
int SetWindowPlacement(int hWnd, Pointer<WINDOWPLACEMENT> lpwndpl) =>
    _SetWindowPlacement(hWnd, lpwndpl);

final _SetWindowPlacement = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<WINDOWPLACEMENT> lpwndpl),
    int Function(
        int hWnd, Pointer<WINDOWPLACEMENT> lpwndpl)>('SetWindowPlacement');

/// Changes the size, position, and Z order of a child, pop-up, or top-level
/// window. These windows are ordered according to their appearance on the
/// screen. The topmost window receives the highest rank and is the first
/// window in the Z order.
///
/// ```c
/// BOOL SetWindowPos(
///   HWND hWnd,
///   HWND hWndInsertAfter,
///   int  X,
///   int  Y,
///   int  cx,
///   int  cy,
///   UINT uFlags
/// );
/// ```
/// {@category user32}
int SetWindowPos(int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy,
        int uFlags) =>
    _SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags);

final _SetWindowPos = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 X, Int32 Y,
        Int32 cx, Int32 cy, Uint32 uFlags),
    int Function(int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy,
        int uFlags)>('SetWindowPos');

/// The SetWindowRgn function sets the window region of a window. The window
/// region determines the area within the window where the system permits
/// drawing. The system does not display any portion of a window that lies
/// outside of the window region
///
/// ```c
/// int SetWindowRgn(
///   HWND hWnd,
///   HRGN hRgn,
///   BOOL bRedraw
/// );
/// ```
/// {@category user32}
int SetWindowRgn(int hWnd, int hRgn, int bRedraw) =>
    _SetWindowRgn(hWnd, hRgn, bRedraw);

final _SetWindowRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hRgn, Int32 bRedraw),
    int Function(int hWnd, int hRgn, int bRedraw)>('SetWindowRgn');

/// Installs an application-defined hook procedure into a hook chain. You
/// would install a hook procedure to monitor the system for certain types
/// of events. These events are associated either with a specific thread or
/// with all threads in the same desktop as the calling thread.
///
/// ```c
/// HHOOK SetWindowsHookExW(
///   int       idHook,
///   HOOKPROC  lpfn,
///   HINSTANCE hmod,
///   DWORD     dwThreadId
/// );
/// ```
/// {@category user32}
int SetWindowsHookEx(int idHook, Pointer<NativeFunction<CallWndProc>> lpfn,
        int hmod, int dwThreadId) =>
    _SetWindowsHookEx(idHook, lpfn, hmod, dwThreadId);

final _SetWindowsHookEx = _user32.lookupFunction<
    IntPtr Function(Int32 idHook, Pointer<NativeFunction<CallWndProc>> lpfn,
        IntPtr hmod, Uint32 dwThreadId),
    int Function(int idHook, Pointer<NativeFunction<CallWndProc>> lpfn,
        int hmod, int dwThreadId)>('SetWindowsHookExW');

/// Changes the text of the specified window's title bar (if it has one). If
/// the specified window is a control, the text of the control is changed.
/// However, SetWindowText cannot change the text of a control in another
/// application.
///
/// ```c
/// BOOL SetWindowTextW(
///   HWND    hWnd,
///   LPCWSTR lpString
/// );
/// ```
/// {@category user32}
int SetWindowText(int hWnd, Pointer<Utf16> lpString) =>
    _SetWindowText(hWnd, lpString);

final _SetWindowText = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString),
    int Function(int hWnd, Pointer<Utf16> lpString)>('SetWindowTextW');

/// Makes the caret visible on the screen at the caret's current position.
/// When the caret becomes visible, it begins flashing automatically.
///
/// ```c
/// BOOL ShowCaret(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int ShowCaret(int hWnd) => _ShowCaret(hWnd);

final _ShowCaret =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'ShowCaret');

/// Displays or hides the cursor.
///
/// ```c
/// int ShowCursor(
///   BOOL bShow
/// );
/// ```
/// {@category user32}
int ShowCursor(int bShow) => _ShowCursor(bShow);

final _ShowCursor = _user32.lookupFunction<Int32 Function(Int32 bShow),
    int Function(int bShow)>('ShowCursor');

/// Shows or hides all pop-up windows owned by the specified window.
///
/// ```c
/// BOOL ShowOwnedPopups(
///   HWND hWnd,
///   BOOL fShow
/// );
/// ```
/// {@category user32}
int ShowOwnedPopups(int hWnd, int fShow) => _ShowOwnedPopups(hWnd, fShow);

final _ShowOwnedPopups = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 fShow),
    int Function(int hWnd, int fShow)>('ShowOwnedPopups');

/// Sets the specified window's show state.
///
/// ```c
/// BOOL ShowWindow(
///   HWND hWnd,
///   int  nCmdShow
/// );
/// ```
/// {@category user32}
int ShowWindow(int hWnd, int nCmdShow) => _ShowWindow(hWnd, nCmdShow);

final _ShowWindow = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 nCmdShow),
    int Function(int hWnd, int nCmdShow)>('ShowWindow');

/// Sets the show state of a window without waiting for the operation to
/// complete.
///
/// ```c
/// BOOL ShowWindowAsync(
///   HWND hWnd,
///   int  nCmdShow
/// );
/// ```
/// {@category user32}
int ShowWindowAsync(int hWnd, int nCmdShow) => _ShowWindowAsync(hWnd, nCmdShow);

final _ShowWindowAsync = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Uint32 nCmdShow),
    int Function(int hWnd, int nCmdShow)>('ShowWindowAsync');

/// Determines which pointer input frame generated the most recently
/// retrieved message for the specified pointer and discards any queued
/// (unretrieved) pointer input messages generated from the same pointer
/// input frame. If an application has retrieved information for an entire
/// frame using the GetPointerFrameInfo function, the
/// GetPointerFrameInfoHistory function or one of their type-specific
/// variants, it can use this function to avoid retrieving and discarding
/// remaining messages from that frame one by one.
///
/// ```c
/// BOOL SkipPointerFrameMessages(
///   [in] UINT32 pointerId
/// );
/// ```
/// {@category user32}
int SkipPointerFrameMessages(int pointerId) =>
    _SkipPointerFrameMessages(pointerId);

final _SkipPointerFrameMessages = _user32.lookupFunction<
    Int32 Function(Uint32 pointerId),
    int Function(int pointerId)>('SkipPointerFrameMessages');

/// Triggers a visual signal to indicate that a sound is playing.
///
/// ```c
/// BOOL SoundSentry();
/// ```
/// {@category user32}
int SoundSentry() => _SoundSentry();

final _SoundSentry =
    _user32.lookupFunction<Int32 Function(), int Function()>('SoundSentry');

/// The SubtractRect function determines the coordinates of a rectangle
/// formed by subtracting one rectangle from another.
///
/// ```c
/// BOOL SubtractRect(
///   LPRECT     lprcDst,
///   const RECT *lprcSrc1,
///   const RECT *lprcSrc2
/// );
/// ```
/// {@category user32}
int SubtractRect(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2) =>
    _SubtractRect(lprcDst, lprcSrc1, lprcSrc2);

final _SubtractRect = _user32.lookupFunction<
    Int32 Function(
        Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1, Pointer<RECT> lprcSrc2),
    int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2)>('SubtractRect');

/// Reverses or restores the meaning of the left and right mouse buttons.
///
/// ```c
/// BOOL SwapMouseButton(
///   BOOL fSwap
/// );
/// ```
/// {@category user32}
int SwapMouseButton(int fSwap) => _SwapMouseButton(fSwap);

final _SwapMouseButton = _user32.lookupFunction<Int32 Function(Int32 fSwap),
    int Function(int fSwap)>('SwapMouseButton');

/// Makes the specified desktop visible and activates it. This enables the
/// desktop to receive input from the user. The calling process must have
/// DESKTOP_SWITCHDESKTOP access to the desktop for the SwitchDesktop
/// function to succeed.
///
/// ```c
/// BOOL SwitchDesktop(
///   HDESK hDesktop
/// );
/// ```
/// {@category user32}
int SwitchDesktop(int hDesktop) => _SwitchDesktop(hDesktop);

final _SwitchDesktop = _user32.lookupFunction<Int32 Function(IntPtr hDesktop),
    int Function(int hDesktop)>('SwitchDesktop');

/// Switches focus to the specified window and brings it to the foreground.
///
/// ```c
/// void SwitchToThisWindow(
///   HWND hwnd,
///   BOOL fUnknown
/// );
/// ```
/// {@category user32}
void SwitchToThisWindow(int hwnd, int fUnknown) =>
    _SwitchToThisWindow(hwnd, fUnknown);

final _SwitchToThisWindow = _user32.lookupFunction<
    Void Function(IntPtr hwnd, Int32 fUnknown),
    void Function(int hwnd, int fUnknown)>('SwitchToThisWindow');

/// Retrieves or sets the value of one of the system-wide parameters. This
/// function can also update the user profile while setting a parameter.
///
/// ```c
/// BOOL SystemParametersInfoW(
///   UINT  uiAction,
///   UINT  uiParam,
///   PVOID pvParam,
///   UINT  fWinIni
/// );
/// ```
/// {@category user32}
int SystemParametersInfo(
        int uiAction, int uiParam, Pointer pvParam, int fWinIni) =>
    _SystemParametersInfo(uiAction, uiParam, pvParam, fWinIni);

final _SystemParametersInfo = _user32.lookupFunction<
    Int32 Function(
        Uint32 uiAction, Uint32 uiParam, Pointer pvParam, Uint32 fWinIni),
    int Function(int uiAction, int uiParam, Pointer pvParam,
        int fWinIni)>('SystemParametersInfoW');

/// Retrieves the value of one of the system-wide parameters, taking into
/// account the provided DPI value.
///
/// ```c
/// BOOL SystemParametersInfoForDpi(
///   UINT  uiAction,
///   UINT  uiParam,
///   PVOID pvParam,
///   UINT  fWinIni,
///   UINT  dpi
/// );
/// ```
/// {@category user32}
int SystemParametersInfoForDpi(
        int uiAction, int uiParam, Pointer pvParam, int fWinIni, int dpi) =>
    _SystemParametersInfoForDpi(uiAction, uiParam, pvParam, fWinIni, dpi);

final _SystemParametersInfoForDpi = _user32.lookupFunction<
    Int32 Function(Uint32 uiAction, Uint32 uiParam, Pointer pvParam,
        Uint32 fWinIni, Uint32 dpi),
    int Function(int uiAction, int uiParam, Pointer pvParam, int fWinIni,
        int dpi)>('SystemParametersInfoForDpi');

/// The TabbedTextOut function writes a character string at a specified
/// location, expanding tabs to the values specified in an array of tab-stop
/// positions. Text is written in the currently selected font, background
/// color, and text color.
///
/// ```c
/// LONG TabbedTextOutW(
///   HDC       hdc,
///   int       x,
///   int       y,
///   LPCWSTR   lpString,
///   int       chCount,
///   int       nTabPositions,
///   const INT *lpnTabStopPositions,
///   int       nTabOrigin
/// );
/// ```
/// {@category user32}
int TabbedTextOut(
        int hdc,
        int x,
        int y,
        Pointer<Utf16> lpString,
        int chCount,
        int nTabPositions,
        Pointer<Int32> lpnTabStopPositions,
        int nTabOrigin) =>
    _TabbedTextOut(hdc, x, y, lpString, chCount, nTabPositions,
        lpnTabStopPositions, nTabOrigin);

final _TabbedTextOut = _user32.lookupFunction<
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

/// Tiles the specified child windows of the specified parent window.
///
/// ```c
/// WORD TileWindows(
///   HWND       hwndParent,
///   UINT       wHow,
///   const RECT *lpRect,
///   UINT       cKids,
///   const HWND *lpKids
/// );
/// ```
/// {@category user32}
int TileWindows(int hwndParent, int wHow, Pointer<RECT> lpRect, int cKids,
        Pointer<IntPtr> lpKids) =>
    _TileWindows(hwndParent, wHow, lpRect, cKids, lpKids);

final _TileWindows = _user32.lookupFunction<
    Uint16 Function(IntPtr hwndParent, Uint32 wHow, Pointer<RECT> lpRect,
        Uint32 cKids, Pointer<IntPtr> lpKids),
    int Function(int hwndParent, int wHow, Pointer<RECT> lpRect, int cKids,
        Pointer<IntPtr> lpKids)>('TileWindows');

/// Translates the specified virtual-key code and keyboard state to the
/// corresponding character or characters. The function translates the code
/// using the input language and physical keyboard layout identified by the
/// keyboard layout handle.
///
/// ```c
/// int ToAscii(
///   UINT       uVirtKey,
///   UINT       uScanCode,
///   const BYTE *lpKeyState,
///   LPWORD     lpChar,
///   UINT       uFlags
/// );
/// ```
/// {@category user32}
int ToAscii(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, int uFlags) =>
    _ToAscii(uVirtKey, uScanCode, lpKeyState, lpChar, uFlags);

final _ToAscii = _user32.lookupFunction<
    Int32 Function(Uint32 uVirtKey, Uint32 uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, Uint32 uFlags),
    int Function(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, int uFlags)>('ToAscii');

/// Translates the specified virtual-key code and keyboard state to the
/// corresponding character or characters. The function translates the code
/// using the input language and physical keyboard layout identified by the
/// input locale identifier.
///
/// ```c
/// int ToAsciiEx(
///   UINT       uVirtKey,
///   UINT       uScanCode,
///   const BYTE *lpKeyState,
///   LPWORD     lpChar,
///   UINT       uFlags,
///   HKL        dwhkl
/// );
/// ```
/// {@category user32}
int ToAsciiEx(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, int uFlags, int dwhkl) =>
    _ToAsciiEx(uVirtKey, uScanCode, lpKeyState, lpChar, uFlags, dwhkl);

final _ToAsciiEx = _user32.lookupFunction<
    Int32 Function(Uint32 uVirtKey, Uint32 uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, Uint32 uFlags, IntPtr dwhkl),
    int Function(int uVirtKey, int uScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Uint16> lpChar, int uFlags, int dwhkl)>('ToAsciiEx');

/// Translates the specified virtual-key code and keyboard state to the
/// corresponding Unicode character or characters.
///
/// ```c
/// int ToUnicode(
///   UINT       wVirtKey,
///   UINT       wScanCode,
///   const BYTE *lpKeyState,
///   LPWSTR     pwszBuff,
///   int        cchBuff,
///   UINT       wFlags
/// );
/// ```
/// {@category user32}
int ToUnicode(int wVirtKey, int wScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff, int cchBuff, int wFlags) =>
    _ToUnicode(wVirtKey, wScanCode, lpKeyState, pwszBuff, cchBuff, wFlags);

final _ToUnicode = _user32.lookupFunction<
    Int32 Function(Uint32 wVirtKey, Uint32 wScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff, Int32 cchBuff, Uint32 wFlags),
    int Function(int wVirtKey, int wScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff, int cchBuff, int wFlags)>('ToUnicode');

/// Translates the specified virtual-key code and keyboard state to the
/// corresponding Unicode character or characters.
///
/// ```c
/// int ToUnicodeEx(
///   UINT       wVirtKey,
///   UINT       wScanCode,
///   const BYTE *lpKeyState,
///   LPWSTR     pwszBuff,
///   int        cchBuff,
///   UINT       wFlags,
///   HKL        dwhkl
/// );
/// ```
/// {@category user32}
int ToUnicodeEx(int wVirtKey, int wScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff, int cchBuff, int wFlags, int dwhkl) =>
    _ToUnicodeEx(
        wVirtKey, wScanCode, lpKeyState, pwszBuff, cchBuff, wFlags, dwhkl);

final _ToUnicodeEx = _user32.lookupFunction<
    Int32 Function(Uint32 wVirtKey, Uint32 wScanCode, Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff, Int32 cchBuff, Uint32 wFlags, IntPtr dwhkl),
    int Function(
        int wVirtKey,
        int wScanCode,
        Pointer<Uint8> lpKeyState,
        Pointer<Utf16> pwszBuff,
        int cchBuff,
        int wFlags,
        int dwhkl)>('ToUnicodeEx');

/// Displays a shortcut menu at the specified location and tracks the
/// selection of items on the shortcut menu. The shortcut menu can appear
/// anywhere on the screen.
///
/// ```c
/// BOOL TrackPopupMenuEx(
///   HMENU hMenu,
///   UINT uFlags,
///   int x,
///   int y,
///   HWND hwnd,
///   TPMPARAMS *lptpm
/// );
/// ```
/// {@category user32}
int TrackPopupMenuEx(int hMenu, int uFlags, int x, int y, int hwnd,
        Pointer<TPMPARAMS> lptpm) =>
    _TrackPopupMenuEx(hMenu, uFlags, x, y, hwnd, lptpm);

final _TrackPopupMenuEx = _user32.lookupFunction<
    Int32 Function(IntPtr hMenu, Uint32 uFlags, Int32 x, Int32 y, IntPtr hwnd,
        Pointer<TPMPARAMS> lptpm),
    int Function(int hMenu, int uFlags, int x, int y, int hwnd,
        Pointer<TPMPARAMS> lptpm)>('TrackPopupMenuEx');

/// Processes accelerator keys for menu commands. The function translates a
/// WM_KEYDOWN or WM_SYSKEYDOWN message to a WM_COMMAND or WM_SYSCOMMAND
/// message (if there is an entry for the key in the specified accelerator
/// table) and then sends the WM_COMMAND or WM_SYSCOMMAND message directly
/// to the specified window procedure. TranslateAccelerator does not return
/// until the window procedure has processed the message.
///
/// ```c
/// int TranslateAcceleratorW(
///   HWND   hWnd,
///   HACCEL hAccTable,
///   LPMSG  lpMsg
/// );
/// ```
/// {@category user32}
int TranslateAccelerator(int hWnd, int hAccTable, Pointer<MSG> lpMsg) =>
    _TranslateAccelerator(hWnd, hAccTable, lpMsg);

final _TranslateAccelerator = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hAccTable, Pointer<MSG> lpMsg),
    int Function(
        int hWnd, int hAccTable, Pointer<MSG> lpMsg)>('TranslateAcceleratorW');

/// Processes accelerator keystrokes for window menu commands of the
/// multiple-document interface (MDI) child windows associated with the
/// specified MDI client window. The function translates WM_KEYUP and
/// WM_KEYDOWN messages to WM_SYSCOMMAND messages and sends them to the
/// appropriate MDI child windows.
///
/// ```c
/// BOOL TranslateMDISysAccel(
///   HWND  hWndClient,
///   LPMSG lpMsg
/// );
/// ```
/// {@category user32}
int TranslateMDISysAccel(int hWndClient, Pointer<MSG> lpMsg) =>
    _TranslateMDISysAccel(hWndClient, lpMsg);

final _TranslateMDISysAccel = _user32.lookupFunction<
    Int32 Function(IntPtr hWndClient, Pointer<MSG> lpMsg),
    int Function(int hWndClient, Pointer<MSG> lpMsg)>('TranslateMDISysAccel');

/// Translates virtual-key messages into character messages. The character
/// messages are posted to the calling thread's message queue, to be read
/// the next time the thread calls the GetMessage or PeekMessage function.
///
/// ```c
/// BOOL TranslateMessage(
///   const MSG *lpMsg
/// );
/// ```
/// {@category user32}
int TranslateMessage(Pointer<MSG> lpMsg) => _TranslateMessage(lpMsg);

final _TranslateMessage = _user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg),
    int Function(Pointer<MSG> lpMsg)>('TranslateMessage');

/// Removes a hook procedure installed in a hook chain by the
/// SetWindowsHookEx function.
///
/// ```c
/// BOOL UnhookWindowsHookEx(
///   HHOOK hhk
/// );
/// ```
/// {@category user32}
int UnhookWindowsHookEx(int hhk) => _UnhookWindowsHookEx(hhk);

final _UnhookWindowsHookEx =
    _user32.lookupFunction<Int32 Function(IntPtr hhk), int Function(int hhk)>(
        'UnhookWindowsHookEx');

/// The UnionRect function creates the union of two rectangles. The union is
/// the smallest rectangle that contains both source rectangles.
///
/// ```c
/// BOOL UnionRect(
///   LPRECT     lprcDst,
///   const RECT *lprcSrc1,
///   const RECT *lprcSrc2
/// );
/// ```
/// {@category user32}
int UnionRect(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2) =>
    _UnionRect(lprcDst, lprcSrc1, lprcSrc2);

final _UnionRect = _user32.lookupFunction<
    Int32 Function(
        Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1, Pointer<RECT> lprcSrc2),
    int Function(Pointer<RECT> lprcDst, Pointer<RECT> lprcSrc1,
        Pointer<RECT> lprcSrc2)>('UnionRect');

/// Unloads an input locale identifier (formerly called a keyboard layout).
///
/// ```c
/// BOOL UnloadKeyboardLayout(
///   HKL hkl
/// );
/// ```
/// {@category user32}
int UnloadKeyboardLayout(int hkl) => _UnloadKeyboardLayout(hkl);

final _UnloadKeyboardLayout =
    _user32.lookupFunction<Int32 Function(IntPtr hkl), int Function(int hkl)>(
        'UnloadKeyboardLayout');

/// Unregisters a window class, freeing the memory required for the class.
///
/// ```c
/// BOOL UnregisterClassW(
///   LPCWSTR   lpClassName,
///   HINSTANCE hInstance
/// );
/// ```
/// {@category user32}
int UnregisterClass(Pointer<Utf16> lpClassName, int hInstance) =>
    _UnregisterClass(lpClassName, hInstance);

final _UnregisterClass = _user32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpClassName, IntPtr hInstance),
    int Function(
        Pointer<Utf16> lpClassName, int hInstance)>('UnregisterClassW');

/// Frees a hot key previously registered by the calling thread.
///
/// ```c
/// BOOL UnregisterHotKey(
///   HWND hWnd,
///   int  id
/// );
/// ```
/// {@category user32}
int UnregisterHotKey(int hWnd, int id) => _UnregisterHotKey(hWnd, id);

final _UnregisterHotKey = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 id),
    int Function(int hWnd, int id)>('UnregisterHotKey');

/// Unregisters the power setting notification.
///
/// ```c
/// BOOL UnregisterPowerSettingNotification(
///   HPOWERNOTIFY Handle
/// );
/// ```
/// {@category user32}
int UnregisterPowerSettingNotification(int Handle) =>
    _UnregisterPowerSettingNotification(Handle);

final _UnregisterPowerSettingNotification = _user32.lookupFunction<
    Int32 Function(IntPtr Handle),
    int Function(int Handle)>('UnregisterPowerSettingNotification');

/// Registers a window as no longer being touch-capable.
///
/// ```c
/// BOOL UnregisterTouchWindow(
/// HWND hwnd
/// );
/// ```
/// {@category user32}
int UnregisterTouchWindow(int hwnd) => _UnregisterTouchWindow(hwnd);

final _UnregisterTouchWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hwnd), int Function(int hwnd)>(
        'UnregisterTouchWindow');

/// Updates the position, size, shape, content, and translucency of a
/// layered window.
///
/// ```c
/// BOOL UpdateLayeredWindowIndirect(
///   HWND hwnd,
///   const UPDATELAYEREDWINDOWINFO *pULWInfo
/// );
/// ```
/// {@category user32}
int UpdateLayeredWindowIndirect(
        int hWnd, Pointer<UPDATELAYEREDWINDOWINFO> pULWInfo) =>
    _UpdateLayeredWindowIndirect(hWnd, pULWInfo);

final _UpdateLayeredWindowIndirect = _user32.lookupFunction<
        Int32 Function(IntPtr hWnd, Pointer<UPDATELAYEREDWINDOWINFO> pULWInfo),
        int Function(int hWnd, Pointer<UPDATELAYEREDWINDOWINFO> pULWInfo)>(
    'UpdateLayeredWindowIndirect');

/// The UpdateWindow function updates the client area of the specified
/// window by sending a WM_PAINT message to the window if the window's
/// update region is not empty. The function sends a WM_PAINT message
/// directly to the window procedure of the specified window, bypassing the
/// application queue. If the update region is empty, no message is sent.
///
/// ```c
/// BOOL UpdateWindow(
///   HWND hWnd
/// );
/// ```
/// {@category user32}
int UpdateWindow(int hWnd) => _UpdateWindow(hWnd);

final _UpdateWindow =
    _user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'UpdateWindow');

/// The ValidateRect function validates the client area within a rectangle
/// by removing the rectangle from the update region of the specified
/// window.
///
/// ```c
/// BOOL ValidateRect(
///   HWND       hWnd,
///   const RECT *lpRect
/// );
/// ```
/// {@category user32}
int ValidateRect(int hWnd, Pointer<RECT> lpRect) => _ValidateRect(hWnd, lpRect);

final _ValidateRect = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect),
    int Function(int hWnd, Pointer<RECT> lpRect)>('ValidateRect');

/// The ValidateRgn function validates the client area within a region by
/// removing the region from the current update region of the specified
/// window.
///
/// ```c
/// BOOL ValidateRgn(
///   HWND hWnd,
///   HRGN hRgn
/// );
/// ```
/// {@category user32}
int ValidateRgn(int hWnd, int hRgn) => _ValidateRgn(hWnd, hRgn);

final _ValidateRgn = _user32.lookupFunction<
    Int32 Function(IntPtr hWnd, IntPtr hRgn),
    int Function(int hWnd, int hRgn)>('ValidateRgn');

/// Translates a character to the corresponding virtual-key code and shift
/// state for the current keyboard.
///
/// ```c
/// SHORT VkKeyScanW(
///   WCHAR ch
/// );
/// ```
/// {@category user32}
int VkKeyScan(int ch) => _VkKeyScan(ch);

final _VkKeyScan =
    _user32.lookupFunction<Int16 Function(Uint16 ch), int Function(int ch)>(
        'VkKeyScanW');

/// Translates a character to the corresponding virtual-key code and shift
/// state. The function translates the character using the input language
/// and physical keyboard layout identified by the input locale identifier.
///
/// ```c
/// SHORT VkKeyScanExW(
///   WCHAR ch,
///   HKL   dwhkl
/// );
/// ```
/// {@category user32}
int VkKeyScanEx(int ch, int dwhkl) => _VkKeyScanEx(ch, dwhkl);

final _VkKeyScanEx = _user32.lookupFunction<
    Int16 Function(Uint16 ch, IntPtr dwhkl),
    int Function(int ch, int dwhkl)>('VkKeyScanExW');

/// Waits until the specified process has finished processing its initial
/// input and is waiting for user input with no input pending, or until the
/// time-out interval has elapsed.
///
/// ```c
/// DWORD WaitForInputIdle(
///   HANDLE hProcess,
///   DWORD  dwMilliseconds
/// );
/// ```
/// {@category user32}
int WaitForInputIdle(int hProcess, int dwMilliseconds) =>
    _WaitForInputIdle(hProcess, dwMilliseconds);

final _WaitForInputIdle = _user32.lookupFunction<
    Uint32 Function(IntPtr hProcess, Uint32 dwMilliseconds),
    int Function(int hProcess, int dwMilliseconds)>('WaitForInputIdle');

/// Yields control to other threads when a thread has no other messages in
/// its message queue. The WaitMessage function suspends the thread and does
/// not return until a new message is placed in the thread's message queue.
///
/// ```c
/// BOOL WaitMessage();
/// ```
/// {@category user32}
int WaitMessage() => _WaitMessage();

final _WaitMessage =
    _user32.lookupFunction<Int32 Function(), int Function()>('WaitMessage');

/// The WindowFromDC function returns a handle to the window associated with
/// the specified display device context (DC). Output functions that use the
/// specified device context draw into this window.
///
/// ```c
/// HWND WindowFromDC(
///   HDC hDC
/// );
/// ```
/// {@category user32}
int WindowFromDC(int hDC) => _WindowFromDC(hDC);

final _WindowFromDC =
    _user32.lookupFunction<IntPtr Function(IntPtr hDC), int Function(int hDC)>(
        'WindowFromDC');

/// Retrieves a handle to the window that contains the specified physical
/// point.
///
/// ```c
/// HWND WindowFromPhysicalPoint(
///   POINT Point
/// );
/// ```
/// {@category user32}
int WindowFromPhysicalPoint(POINT Point) => _WindowFromPhysicalPoint(Point);

final _WindowFromPhysicalPoint = _user32.lookupFunction<
    IntPtr Function(POINT Point),
    int Function(POINT Point)>('WindowFromPhysicalPoint');

/// Retrieves a handle to the window that contains the specified point.
///
/// ```c
/// HWND WindowFromPoint(
///   POINT Point
/// );
/// ```
/// {@category user32}
int WindowFromPoint(POINT Point) => _WindowFromPoint(Point);

final _WindowFromPoint = _user32.lookupFunction<IntPtr Function(POINT Point),
    int Function(POINT Point)>('WindowFromPoint');
