// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

// Native callback functions that can get called by the Win32 API

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'structs.g.dart';
import 'types.dart';

/// An application-defined or library-defined callback function used with the
/// SetWindowsHookEx function. The system calls this function before calling the
/// window procedure to process a message sent to the thread.
typedef CallWndProc = LRESULT Function(
    Int32 nCode, WPARAM wParam, LPARAM lParam);

/// Application-defined callback function used with the ChooseColor function.
/// Receives messages or notifications intended for the default dialog box
/// procedure of the Color dialog box.
typedef CCHookProc = UINT_PTR Function(HWND, UINT, WPARAM, LPARAM);

/// Application-defined callback function used with the ChooseFont function.
/// Receives messages or notifications intended for the default dialog box
/// procedure of the Font dialog box.
typedef CFHookProc = UINT_PTR Function(HWND, UINT, WPARAM, LPARAM);

/// Application-defined callback function used with the CreateDialog and
/// DialogBox families of functions. It processes messages sent to a modal or
/// modeless dialog box.
typedef DlgProc = INT_PTR Function(HWND, UINT, WPARAM, LPARAM);

/// Application-defined callback function used with the DrawThemeTextEx
/// function. This function is used instead of DrawText.
typedef DrawTextCallback = Int32 Function(HDC hdc, LPWSTR pszText,
    Int32 cchText, Pointer<RECT> prc, UINT dwFlags, LPARAM lparam);

/// Application-defined callback function that renders a complex image for the
/// DrawState function.
typedef DrawStateProc = Int32 Function(
    IntPtr hdc, IntPtr lData, IntPtr wData, Int32 cx, Int32 cy);

/// Application-defined callback function used with the EnumChildWindows
/// function. It receives the child window handles.
typedef EnumWindowsProc = BOOL Function(HWND hwnd, LPARAM lParam);

/// Application defined callback function used with the EnumFontFamiliesEx
/// function. It is used to process the fonts.
typedef EnumFontFamExProc = Int32 Function(Pointer<LOGFONT> lpelfe,
    Pointer<TEXTMETRIC> lpntme, DWORD FontType, LPARAM lParam);

/// Application-defined callback function used with the EnumResourceNames and
/// EnumResourceNamesEx functions. It receives the type and name of a resource.
typedef EnumResNameProc = BOOL Function(HMODULE hModule, Pointer<Utf16> lpType,
    Pointer<Utf16> lpName, LONG_PTR lParam);

/// Application-defined callback function used with the EnumResourceTypes and
/// EnumResourceTypesEx functions. It receives resource types.
typedef EnumResTypeProc = BOOL Function(
    HMODULE hModule, Pointer<Utf16> lpszType, LONG_PTR lParam);

/// Application-defined callback function used with the IDispatch::Invoke
/// function to defer filling in bstrDescription, bstrHelpFile, and
/// dwHelpContext fields until they are needed.
typedef ExcepInfoProc = IntPtr Function(Pointer<EXCEPINFO>);

/// Application-defined callback function used with the FindText or ReplaceText
/// function. Receives messages or notifications intended for the default dialog
/// box procedure of the Find or Replace dialog box.
typedef FRHookProc = UINT_PTR Function(HWND, UINT, WPARAM, LPARAM);

/// Application-defined callback function used with the SetConsoleCtrlHandler
/// function. A console process uses this function to handle control signals
/// received by the process. When the signal is received, the system creates a
/// new thread in the process to execute the function.
typedef HandlerRoutine = BOOL Function(DWORD dwCtrlType);

/// Application-defined callback function used with the ReadFileEx and
/// WriteFileEx functions. It is called when the asynchronous input and output
/// (I/O) operation is completed or canceled and the calling thread is in an
/// alertable state (by using the SleepEx, MsgWaitForMultipleObjectsEx,
/// WaitForSingleObjectEx, or WaitForMultipleObjectsEx function with the
/// fAlertable parameter set to TRUE).
typedef LpoverlappedCompletionRoutine = Void Function(DWORD dwErrorCode,
    DWORD dwNumberOfBytesTransfered, OVERLAPPED lpOverlapped);

/// Application-defined callback function implements a custom transform for
/// image scaling.
typedef MagImageScalingCallback = BOOL Function(
    HWND hwnd,
    Pointer srcdata,
    MAGIMAGEHEADER srcheader,
    Pointer destdata,
    MAGIMAGEHEADER destheader,
    RECT unclipped,
    RECT clipped,
    HRGN dirty);

/// Application-defined callback function for handling incoming MIDI messages.
/// MidiInProc is a placeholder for the application-supplied function name. The
/// address of this function can be specified in the callback-address parameter
/// of the midiInOpen function.
typedef MidiInProc = Void Function(HMIDIIN hMidiIn, UINT wMsg,
    DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2);

/// Application-defined callback function for handling outgoing MIDI messages.
/// MidiOutProc is a placeholder for the application-supplied function name. The
/// address of the function can be specified in the callback-address parameter
/// of the midiOutOpen function.
typedef MidiOutProc = Void Function(IntPtr hmo, Uint32 wMsg, IntPtr dwInstance,
    IntPtr dwParam1, IntPtr dwParam2);

/// Application-defined callback function used with the EnumDisplayMonitors
/// function. It receives display monitors in the calculated enumeration set.
typedef MonitorEnumProc = Int32 Function(
    IntPtr hMonitor, IntPtr hDC, Pointer lpRect, IntPtr lParam);

/// Application-defined callback function used with the Explorer-style Open and
/// Save As dialog boxes. Receives notification messages sent from the dialog
/// box. The function also receives messages for any additional controls that
/// you defined by specifying a child dialog template.
typedef OFNHookProc = UINT_PTR Function(HWND, UINT, WPARAM, LPARAM);

/// Application-defined callback function used with the GrayString function. It
/// is used to draw a string.
typedef OutputProc = Int32 Function(IntPtr Arg1, IntPtr Arg2, Int32 Arg3);

/// Application-defined callback function used with the
/// BluetoothRegisterForAuthenticationEx function.
typedef PfnAuthenticationCallbackEx = Int32 Function(Pointer pvParam,
    Pointer<BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS> pAuthCallbackParams);

/// Application-defined callback function used with profile drivers to implement
/// a Bluetooth GATT event callback to be called whenever the value of a
/// specific characteristic changes.
typedef PfnbluetoothGattEventCallback = Void Function(
    Int32 EventType, Pointer EventOutParameter, Pointer Context);

/// Application-defined callback function used with the SendMessageCallback
/// function. The system passes the message to the callback function after
/// passing the message to the destination window procedure. The SENDASYNCPROC
/// type defines a pointer to this callback function. SendAsyncProc is a
/// placeholder for the application-defined function name.
typedef SendAsyncProc = Void Function(IntPtr, Uint32, IntPtr, IntPtr);

// Application-defined callback function used with SAPI clients to receive
// notifications.
typedef SpNotifyCallback = Void Function(WPARAM wParam, LPARAM lParam);

/// Application-defined callback function used with the RemoveWindowSubclass
/// and SetWindowSubclass functions.
typedef SubclassProc = LRESULT Function(HWND hWnd, UINT uMsg, WPARAM wParam,
    LPARAM lParam, UINT_PTR uIdSubclass, DWORD_PTR dwRefData);

/// Application-defined callback function used with the SymEnumSymbols,
/// SymEnumTypes, and SymEnumTypesByName functions.
typedef SymEnumSymbolsProc = Int32 Function(
    Pointer<SYMBOL_INFO> pSymInfo, Uint32 SymbolSize, Pointer UserContext);

/// Application-defined callback function used with the TaskDialogIndirect
/// function. It receives messages from the task dialog when various events
/// occur.
typedef TaskDialogCallbackProc = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam, IntPtr lpRefData);

/// Application-defined callback function that serves as the starting address
/// for a thread. Specify this address when calling the CreateThread,
/// CreateRemoteThread, or CreateRemoteThreadEx function.
typedef ThreadProc = DWORD Function(Pointer lpParameter);

/// Application-defined callback function that processes WM_TIMER messages.
typedef TimerProc = Void Function(IntPtr, Uint32, Pointer<Uint32>, Int32);

/// Application-defined callback function that processes messages sent to a
/// window.
typedef WindowProc = LRESULT Function(
    HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

/// Application-defined callback function that is used by an application to
/// register and unregister notifications on all wireless interfaces.
typedef WlanNotificationCallback = Void Function(
    Pointer<L2_NOTIFICATION_DATA>, Pointer);

/// Application-defined callback function that provides special verification
/// for smart card searches.
typedef OpenCardCheckProc = Int32 Function(IntPtr, IntPtr, Pointer);

/// Application-defined callback function that allows callers to perform
/// additional processing to connect to the smart card.
typedef OpenCardConnProc = IntPtr Function(
    IntPtr, Pointer<Utf16>, Pointer<Utf16>, Pointer);

/// Application-defined callback function that can be used for disconnecting
/// smart cards.
typedef OpenCardDisconnProc = Void Function(IntPtr, IntPtr, Pointer);
