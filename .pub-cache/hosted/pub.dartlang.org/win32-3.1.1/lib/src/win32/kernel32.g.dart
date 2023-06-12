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

final _kernel32 = DynamicLibrary.open('kernel32.dll');

/// The ActivateActCtx function activates the specified activation context.
/// It does this by pushing the specified activation context to the top of
/// the activation stack. The specified activation context is thus
/// associated with the current thread and any appropriate side-by-side API
/// functions.
///
/// ```c
/// BOOL ActivateActCtx(
///   HANDLE    hActCtx,
///   ULONG_PTR *lpCookie
/// );
/// ```
/// {@category kernel32}
int ActivateActCtx(int hActCtx, Pointer<IntPtr> lpCookie) =>
    _ActivateActCtx(hActCtx, lpCookie);

final _ActivateActCtx = _kernel32.lookupFunction<
    Int32 Function(IntPtr hActCtx, Pointer<IntPtr> lpCookie),
    int Function(int hActCtx, Pointer<IntPtr> lpCookie)>('ActivateActCtx');

/// Adds a directory to the process DLL search path.
///
/// ```c
/// DLL_DIRECTORY_COOKIE AddDllDirectory(
///   [in] PCWSTR NewDirectory
/// );
/// ```
/// {@category kernel32}
Pointer AddDllDirectory(Pointer<Utf16> NewDirectory) =>
    _AddDllDirectory(NewDirectory);

final _AddDllDirectory = _kernel32.lookupFunction<
    Pointer Function(Pointer<Utf16> NewDirectory),
    Pointer Function(Pointer<Utf16> NewDirectory)>('AddDllDirectory');

/// The AddRefActCtx function increments the reference count of the
/// specified activation context.
///
/// ```c
/// void AddRefActCtx(
///   HANDLE hActCtx
/// );
/// ```
/// {@category kernel32}
void AddRefActCtx(int hActCtx) => _AddRefActCtx(hActCtx);

final _AddRefActCtx = _kernel32.lookupFunction<Void Function(IntPtr hActCtx),
    void Function(int hActCtx)>('AddRefActCtx');

/// Allocates a new console for the calling process.
///
/// ```c
/// BOOL AllocConsole(void);
/// ```
/// {@category kernel32}
int AllocConsole() => _AllocConsole();

final _AllocConsole =
    _kernel32.lookupFunction<Int32 Function(), int Function()>('AllocConsole');

/// Determines whether the file I/O functions are using the ANSI or OEM
/// character set code page. This function is useful for 8-bit console input
/// and output operations.
///
/// ```c
/// BOOL AreFileApisANSI();
/// ```
/// {@category kernel32}
int AreFileApisANSI() => _AreFileApisANSI();

final _AreFileApisANSI = _kernel32
    .lookupFunction<Int32 Function(), int Function()>('AreFileApisANSI');

/// Attaches the calling process to the console of the specified process.
///
/// ```c
/// BOOL AttachConsole(
///   _In_ DWORD dwProcessId
/// );
/// ```
/// {@category kernel32}
int AttachConsole(int dwProcessId) => _AttachConsole(dwProcessId);

final _AttachConsole = _kernel32.lookupFunction<
    Int32 Function(Uint32 dwProcessId),
    int Function(int dwProcessId)>('AttachConsole');

/// Generates simple tones on the speaker. The function is synchronous; it
/// performs an alertable wait and does not return control to its caller
/// until the sound finishes.
///
/// ```c
/// BOOL Beep(
///   DWORD dwFreq,
///   DWORD dwDuration
/// );
/// ```
/// {@category kernel32}
int Beep(int dwFreq, int dwDuration) => _Beep(dwFreq, dwDuration);

final _Beep = _kernel32.lookupFunction<
    Int32 Function(Uint32 dwFreq, Uint32 dwDuration),
    int Function(int dwFreq, int dwDuration)>('Beep');

/// Retrieves a handle that can be used by the UpdateResource function to
/// add, delete, or replace resources in a binary module.
///
/// ```c
/// HANDLE BeginUpdateResourceW(
///   LPCWSTR pFileName,
///   BOOL    bDeleteExistingResources
/// );
/// ```
/// {@category kernel32}
int BeginUpdateResource(
        Pointer<Utf16> pFileName, int bDeleteExistingResources) =>
    _BeginUpdateResource(pFileName, bDeleteExistingResources);

final _BeginUpdateResource = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> pFileName, Int32 bDeleteExistingResources),
    int Function(Pointer<Utf16> pFileName,
        int bDeleteExistingResources)>('BeginUpdateResourceW');

/// Fills a specified DCB structure with values specified in a
/// device-control string. The device-control string uses the syntax of the
/// mode command.
///
/// ```c
/// BOOL BuildCommDCBW(
///   LPCWSTR lpDef,
///   LPDCB   lpDCB
/// );
/// ```
/// {@category kernel32}
int BuildCommDCB(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB) =>
    _BuildCommDCB(lpDef, lpDCB);

final _BuildCommDCB = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB),
    int Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB)>('BuildCommDCBW');

/// Translates a device-definition string into appropriate device-control
/// block codes and places them into a device control block. The function
/// can also set up time-out values, including the possibility of no
/// time-outs, for a device; the function's behavior in this regard depends
/// on the contents of the device-definition string.
///
/// ```c
/// BOOL BuildCommDCBAndTimeoutsW(
///   LPCWSTR        lpDef,
///   LPDCB          lpDCB,
///   LPCOMMTIMEOUTS lpCommTimeouts
/// );
/// ```
/// {@category kernel32}
int BuildCommDCBAndTimeouts(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB,
        Pointer<COMMTIMEOUTS> lpCommTimeouts) =>
    _BuildCommDCBAndTimeouts(lpDef, lpDCB, lpCommTimeouts);

final _BuildCommDCBAndTimeouts = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB,
        Pointer<COMMTIMEOUTS> lpCommTimeouts),
    int Function(Pointer<Utf16> lpDef, Pointer<DCB> lpDCB,
        Pointer<COMMTIMEOUTS> lpCommTimeouts)>('BuildCommDCBAndTimeoutsW');

/// Connects to a message-type pipe (and waits if an instance of the pipe is
/// not available), writes to and reads from the pipe, and then closes the
/// pipe.
///
/// ```c
/// BOOL CallNamedPipeW(
///   LPCWSTR lpNamedPipeName,
///   LPVOID  lpInBuffer,
///   DWORD   nInBufferSize,
///   LPVOID  lpOutBuffer,
///   DWORD   nOutBufferSize,
///   LPDWORD lpBytesRead,
///   DWORD   nTimeOut
/// );
/// ```
/// {@category kernel32}
int CallNamedPipe(
        Pointer<Utf16> lpNamedPipeName,
        Pointer lpInBuffer,
        int nInBufferSize,
        Pointer lpOutBuffer,
        int nOutBufferSize,
        Pointer<Uint32> lpBytesRead,
        int nTimeOut) =>
    _CallNamedPipe(lpNamedPipeName, lpInBuffer, nInBufferSize, lpOutBuffer,
        nOutBufferSize, lpBytesRead, nTimeOut);

final _CallNamedPipe = _kernel32.lookupFunction<
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

/// Cancels all pending input and output (I/O) operations that are issued by
/// the calling thread for the specified file. The function does not cancel
/// I/O operations that other threads issue for a file handle.
///
/// ```c
/// BOOL CancelIo(
///   HANDLE hFile
/// );
/// ```
/// {@category kernel32}
int CancelIo(int hFile) => _CancelIo(hFile);

final _CancelIo = _kernel32.lookupFunction<Int32 Function(IntPtr hFile),
    int Function(int hFile)>('CancelIo');

/// Marks any outstanding I/O operations for the specified file handle. The
/// function only cancels I/O operations in the current process, regardless
/// of which thread created the I/O operation.
///
/// ```c
/// BOOL CancelIoEx(
///   HANDLE       hFile,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int CancelIoEx(int hFile, Pointer<OVERLAPPED> lpOverlapped) =>
    _CancelIoEx(hFile, lpOverlapped);

final _CancelIoEx = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<OVERLAPPED> lpOverlapped),
    int Function(int hFile, Pointer<OVERLAPPED> lpOverlapped)>('CancelIoEx');

/// Marks pending synchronous I/O operations that are issued by the
/// specified thread as canceled.
///
/// ```c
/// BOOL CancelSynchronousIo(
/// HANDLE hThread
/// );
/// ```
/// {@category kernel32}
int CancelSynchronousIo(int hThread) => _CancelSynchronousIo(hThread);

final _CancelSynchronousIo = _kernel32.lookupFunction<
    Int32 Function(IntPtr hThread),
    int Function(int hThread)>('CancelSynchronousIo');

/// Determines whether the specified process is being debugged.
///
/// ```c
/// BOOL CheckRemoteDebuggerPresent(
///   HANDLE hProcess,
///   PBOOL  pbDebuggerPresent
///       );
/// ```
/// {@category kernel32}
int CheckRemoteDebuggerPresent(
        int hProcess, Pointer<Int32> pbDebuggerPresent) =>
    _CheckRemoteDebuggerPresent(hProcess, pbDebuggerPresent);

final _CheckRemoteDebuggerPresent = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<Int32> pbDebuggerPresent),
    int Function(int hProcess,
        Pointer<Int32> pbDebuggerPresent)>('CheckRemoteDebuggerPresent');

/// Restores character transmission for a specified communications device
/// and places the transmission line in a nonbreak state.
///
/// ```c
/// BOOL ClearCommBreak(
///   HANDLE hFile
/// );
/// ```
/// {@category kernel32}
int ClearCommBreak(int hFile) => _ClearCommBreak(hFile);

final _ClearCommBreak = _kernel32.lookupFunction<Int32 Function(IntPtr hFile),
    int Function(int hFile)>('ClearCommBreak');

/// Retrieves information about a communications error and reports the
/// current status of a communications device. The function is called when a
/// communications error occurs, and it clears the device's error flag to
/// enable additional input and output (I/O) operations.
///
/// ```c
/// BOOL ClearCommError(
///   HANDLE    hFile,
///   LPDWORD   lpErrors,
///   LPCOMSTAT lpStat
/// );
/// ```
/// {@category kernel32}
int ClearCommError(
        int hFile, Pointer<Uint32> lpErrors, Pointer<COMSTAT> lpStat) =>
    _ClearCommError(hFile, lpErrors, lpStat);

final _ClearCommError = _kernel32.lookupFunction<
    Int32 Function(
        IntPtr hFile, Pointer<Uint32> lpErrors, Pointer<COMSTAT> lpStat),
    int Function(int hFile, Pointer<Uint32> lpErrors,
        Pointer<COMSTAT> lpStat)>('ClearCommError');

/// Closes an open object handle.
///
/// ```c
/// BOOL CloseHandle(
///   HANDLE hObject
/// );
/// ```
/// {@category kernel32}
int CloseHandle(int hObject) => _CloseHandle(hObject);

final _CloseHandle = _kernel32.lookupFunction<Int32 Function(IntPtr hObject),
    int Function(int hObject)>('CloseHandle');

/// Closes a pseudoconsole from the given handle.
///
/// ```c
/// void ClosePseudoConsole(
///   _In_ HPCON hPC
/// );
/// ```
/// {@category kernel32}
void ClosePseudoConsole(int hPC) => _ClosePseudoConsole(hPC);

final _ClosePseudoConsole =
    _kernel32.lookupFunction<Void Function(IntPtr hPC), void Function(int hPC)>(
        'ClosePseudoConsole');

/// Displays a driver-supplied configuration dialog box.
///
/// ```c
/// BOOL CommConfigDialogW(
///   LPCWSTR      lpszName,
///   HWND         hWnd,
///   LPCOMMCONFIG lpCC
/// );
/// ```
/// {@category kernel32}
int CommConfigDialog(
        Pointer<Utf16> lpszName, int hWnd, Pointer<COMMCONFIG> lpCC) =>
    _CommConfigDialog(lpszName, hWnd, lpCC);

final _CommConfigDialog = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpszName, IntPtr hWnd, Pointer<COMMCONFIG> lpCC),
    int Function(Pointer<Utf16> lpszName, int hWnd,
        Pointer<COMMCONFIG> lpCC)>('CommConfigDialogW');

/// Enables a named pipe server process to wait for a client process to
/// connect to an instance of a named pipe. A client process connects by
/// calling either the CreateFile or CallNamedPipe function.
///
/// ```c
/// BOOL ConnectNamedPipe(
///   HANDLE       hNamedPipe,
///   LPOVERLAPPED lpOverlapped);
/// ```
/// {@category kernel32}
int ConnectNamedPipe(int hNamedPipe, Pointer<OVERLAPPED> lpOverlapped) =>
    _ConnectNamedPipe(hNamedPipe, lpOverlapped);

final _ConnectNamedPipe = _kernel32.lookupFunction<
    Int32 Function(IntPtr hNamedPipe, Pointer<OVERLAPPED> lpOverlapped),
    int Function(
        int hNamedPipe, Pointer<OVERLAPPED> lpOverlapped)>('ConnectNamedPipe');

/// Enables a debugger to continue a thread that previously reported a
/// debugging event.
///
/// ```c
/// BOOL ContinueDebugEvent(
///   DWORD dwProcessId,
///   DWORD dwThreadId,
///   DWORD dwContinueStatus
/// );
/// ```
/// {@category kernel32}
int ContinueDebugEvent(int dwProcessId, int dwThreadId, int dwContinueStatus) =>
    _ContinueDebugEvent(dwProcessId, dwThreadId, dwContinueStatus);

final _ContinueDebugEvent = _kernel32.lookupFunction<
    Int32 Function(
        Uint32 dwProcessId, Uint32 dwThreadId, Uint32 dwContinueStatus),
    int Function(int dwProcessId, int dwThreadId,
        int dwContinueStatus)>('ContinueDebugEvent');

/// The CreateActCtx function creates an activation context.
///
/// ```c
/// HANDLE CreateActCtxW(
///   PCACTCTXW pActCtx
/// );
/// ```
/// {@category kernel32}
int CreateActCtx(Pointer<ACTCTX> pActCtx) => _CreateActCtx(pActCtx);

final _CreateActCtx = _kernel32.lookupFunction<
    IntPtr Function(Pointer<ACTCTX> pActCtx),
    int Function(Pointer<ACTCTX> pActCtx)>('CreateActCtxW');

/// Creates a console screen buffer.
///
/// ```c
/// HANDLE CreateConsoleScreenBuffer(
///   _In_             DWORD               dwDesiredAccess,
///   _In_             DWORD               dwShareMode,
///   _In_opt_   const SECURITY_ATTRIBUTES *lpSecurityAttributes,
///   _In_             DWORD               dwFlags,
///   _Reserved_       LPVOID              lpScreenBufferData
/// );
/// ```
/// {@category kernel32}
int CreateConsoleScreenBuffer(
        int dwDesiredAccess,
        int dwShareMode,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        int dwFlags,
        Pointer lpScreenBufferData) =>
    _CreateConsoleScreenBuffer(dwDesiredAccess, dwShareMode,
        lpSecurityAttributes, dwFlags, lpScreenBufferData);

final _CreateConsoleScreenBuffer = _kernel32.lookupFunction<
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

/// Creates a new directory. If the underlying file system supports security
/// on files and directories, the function applies a specified security
/// descriptor to the new directory.
///
/// ```c
/// BOOL CreateDirectoryW(
///   LPCWSTR               lpPathName,
///   LPSECURITY_ATTRIBUTES lpSecurityAttributes
/// );
/// ```
/// {@category kernel32}
int CreateDirectory(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes) =>
    _CreateDirectory(lpPathName, lpSecurityAttributes);

final _CreateDirectory = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
    int Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>('CreateDirectoryW');

/// Creates or opens a named or unnamed event object.
///
/// ```c
/// HANDLE CreateEventW(
///   LPSECURITY_ATTRIBUTES lpEventAttributes,
///   BOOL bManualReset,
///   BOOL  bInitialState,
///   LPCWSTR lpName
/// );
/// ```
/// {@category kernel32}
int CreateEvent(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        int bManualReset, int bInitialState, Pointer<Utf16> lpName) =>
    _CreateEvent(lpEventAttributes, bManualReset, bInitialState, lpName);

final _CreateEvent = _kernel32.lookupFunction<
    IntPtr Function(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        Int32 bManualReset, Int32 bInitialState, Pointer<Utf16> lpName),
    int Function(
        Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        int bManualReset,
        int bInitialState,
        Pointer<Utf16> lpName)>('CreateEventW');

/// Creates or opens a named or unnamed event object and returns a handle to
/// the object.
///
/// ```c
/// HANDLE CreateEventExW(
///   LPSECURITY_ATTRIBUTES lpEventAttributes,
///   LPCWSTR               lpName,
///   DWORD                 dwFlags,
///   DWORD                 dwDesiredAccess
/// );
/// ```
/// {@category kernel32}
int CreateEventEx(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        Pointer<Utf16> lpName, int dwFlags, int dwDesiredAccess) =>
    _CreateEventEx(lpEventAttributes, lpName, dwFlags, dwDesiredAccess);

final _CreateEventEx = _kernel32.lookupFunction<
    IntPtr Function(Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        Pointer<Utf16> lpName, Uint32 dwFlags, Uint32 dwDesiredAccess),
    int Function(
        Pointer<SECURITY_ATTRIBUTES> lpEventAttributes,
        Pointer<Utf16> lpName,
        int dwFlags,
        int dwDesiredAccess)>('CreateEventExW');

/// Creates or opens a file or I/O device. The most commonly used I/O
/// devices are as follows: file, file stream, directory, physical disk,
/// volume, console buffer, tape drive, communications resource, mailslot,
/// and pipe. The function returns a handle that can be used to access the
/// file or device for various types of I/O depending on the file or device
/// and the flags and attributes specified.
///
/// ```c
/// HANDLE CreateFileW(
///   LPCWSTR               lpFileName,
///   DWORD                 dwDesiredAccess,
///   DWORD                 dwShareMode,
///   LPSECURITY_ATTRIBUTES lpSecurityAttributes,
///   DWORD                 dwCreationDisposition,
///   DWORD                 dwFlagsAndAttributes,
///   HANDLE                hTemplateFile
/// );
/// ```
/// {@category kernel32}
int CreateFile(
        Pointer<Utf16> lpFileName,
        int dwDesiredAccess,
        int dwShareMode,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        int dwCreationDisposition,
        int dwFlagsAndAttributes,
        int hTemplateFile) =>
    _CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes,
        dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);

final _CreateFile = _kernel32.lookupFunction<
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

/// Creates or opens a file or I/O device. The most commonly used I/O
/// devices are as follows: file, file stream, directory, physical disk,
/// volume, console buffer, tape drive, communications resource, mailslot,
/// and pipe. The function returns a handle that can be used to access the
/// file or device for various types of I/O depending on the file or device
/// and the flags and attributes specified.
///
/// ```c
/// HANDLE CreateFile2(
///   [in]           LPCWSTR                           lpFileName,
///   [in]           DWORD                             dwDesiredAccess,
///   [in]           DWORD                             dwShareMode,
///   [in]           DWORD                             dwCreationDisposition,
///   [in, optional] LPCREATEFILE2_EXTENDED_PARAMETERS pCreateExParams
/// );
/// ```
/// {@category kernel32}
int CreateFile2(
        Pointer<Utf16> lpFileName,
        int dwDesiredAccess,
        int dwShareMode,
        int dwCreationDisposition,
        Pointer<CREATEFILE2_EXTENDED_PARAMETERS> pCreateExParams) =>
    _CreateFile2(lpFileName, dwDesiredAccess, dwShareMode,
        dwCreationDisposition, pCreateExParams);

final _CreateFile2 = _kernel32.lookupFunction<
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

/// Creates an input/output (I/O) completion port and associates it with a
/// specified file handle, or creates an I/O completion port that is not yet
/// associated with a file handle, allowing association at a later time.
///
/// ```c
/// HANDLE CreateIoCompletionPort(
///   HANDLE    FileHandle,
///   HANDLE    ExistingCompletionPort,
///   ULONG_PTR CompletionKey,
///   DWORD     NumberOfConcurrentThreads
/// );
/// ```
/// {@category kernel32}
int CreateIoCompletionPort(int FileHandle, int ExistingCompletionPort,
        int CompletionKey, int NumberOfConcurrentThreads) =>
    _CreateIoCompletionPort(FileHandle, ExistingCompletionPort, CompletionKey,
        NumberOfConcurrentThreads);

final _CreateIoCompletionPort = _kernel32.lookupFunction<
    IntPtr Function(IntPtr FileHandle, IntPtr ExistingCompletionPort,
        IntPtr CompletionKey, Uint32 NumberOfConcurrentThreads),
    int Function(int FileHandle, int ExistingCompletionPort, int CompletionKey,
        int NumberOfConcurrentThreads)>('CreateIoCompletionPort');

/// Creates an instance of a named pipe and returns a handle for subsequent
/// pipe operations. A named pipe server process uses this function either
/// to create the first instance of a specific named pipe and establish its
/// basic attributes or to create a new instance of an existing named pipe.
///
/// ```c
/// HANDLE CreateNamedPipeW(
///   LPCWSTR                lpName,
///   DWORD                 dwOpenMode,
///   DWORD                 dwPipeMode,
///   DWORD                 nMaxInstances,
///   DWORD                 nOutBufferSize,
///   DWORD                 nInBufferSize,
///   DWORD                 nDefaultTimeOut,
///   LPSECURITY_ATTRIBUTES lpSecurityAttributes);
/// ```
/// {@category kernel32}
int CreateNamedPipe(
        Pointer<Utf16> lpName,
        int dwOpenMode,
        int dwPipeMode,
        int nMaxInstances,
        int nOutBufferSize,
        int nInBufferSize,
        int nDefaultTimeOut,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes) =>
    _CreateNamedPipe(lpName, dwOpenMode, dwPipeMode, nMaxInstances,
        nOutBufferSize, nInBufferSize, nDefaultTimeOut, lpSecurityAttributes);

final _CreateNamedPipe = _kernel32.lookupFunction<
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
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>('CreateNamedPipeW');

/// Creates an anonymous pipe, and returns handles to the read and write
/// ends of the pipe.
///
/// ```c
/// BOOL CreatePipe(
///   PHANDLE               hReadPipe,
///   PHANDLE               hWritePipe,
///   LPSECURITY_ATTRIBUTES lpPipeAttributes,
///   DWORD                 nSize
/// );
/// ```
/// {@category kernel32}
int CreatePipe(Pointer<IntPtr> hReadPipe, Pointer<IntPtr> hWritePipe,
        Pointer<SECURITY_ATTRIBUTES> lpPipeAttributes, int nSize) =>
    _CreatePipe(hReadPipe, hWritePipe, lpPipeAttributes, nSize);

final _CreatePipe = _kernel32.lookupFunction<
    Int32 Function(Pointer<IntPtr> hReadPipe, Pointer<IntPtr> hWritePipe,
        Pointer<SECURITY_ATTRIBUTES> lpPipeAttributes, Uint32 nSize),
    int Function(
        Pointer<IntPtr> hReadPipe,
        Pointer<IntPtr> hWritePipe,
        Pointer<SECURITY_ATTRIBUTES> lpPipeAttributes,
        int nSize)>('CreatePipe');

/// Creates a new process and its primary thread. The new process runs in
/// the security context of the calling process.
///
/// ```c
/// BOOL CreateProcessW(
///   LPCWSTR               lpApplicationName,
///   LPWSTR                lpCommandLine,
///   LPSECURITY_ATTRIBUTES lpProcessAttributes,
///   LPSECURITY_ATTRIBUTES lpThreadAttributes,
///   BOOL                  bInheritHandles,
///   DWORD                 dwCreationFlags,
///   LPVOID                lpEnvironment,
///   LPCWSTR               lpCurrentDirectory,
///   LPSTARTUPINFOW        lpStartupInfo,
///   LPPROCESS_INFORMATION lpProcessInformation
/// );
/// ```
/// {@category kernel32}
int CreateProcess(
        Pointer<Utf16> lpApplicationName,
        Pointer<Utf16> lpCommandLine,
        Pointer<SECURITY_ATTRIBUTES> lpProcessAttributes,
        Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
        int bInheritHandles,
        int dwCreationFlags,
        Pointer lpEnvironment,
        Pointer<Utf16> lpCurrentDirectory,
        Pointer<STARTUPINFO> lpStartupInfo,
        Pointer<PROCESS_INFORMATION> lpProcessInformation) =>
    _CreateProcess(
        lpApplicationName,
        lpCommandLine,
        lpProcessAttributes,
        lpThreadAttributes,
        bInheritHandles,
        dwCreationFlags,
        lpEnvironment,
        lpCurrentDirectory,
        lpStartupInfo,
        lpProcessInformation);

final _CreateProcess = _kernel32.lookupFunction<
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
        Pointer<PROCESS_INFORMATION> lpProcessInformation)>('CreateProcessW');

/// Creates a new pseudoconsole object for the calling process.
///
/// ```c
/// HRESULT CreatePseudoConsole(
///   _In_ COORD size,
///   _In_ HANDLE hInput,
///   _In_ HANDLE hOutput,
///   _In_ DWORD dwFlags,
///   _Out_ HPCON* phPC
/// );
/// ```
/// {@category kernel32}
int CreatePseudoConsole(COORD size, int hInput, int hOutput, int dwFlags,
        Pointer<IntPtr> phPC) =>
    _CreatePseudoConsole(size, hInput, hOutput, dwFlags, phPC);

final _CreatePseudoConsole = _kernel32.lookupFunction<
    Int32 Function(COORD size, IntPtr hInput, IntPtr hOutput, Uint32 dwFlags,
        Pointer<IntPtr> phPC),
    int Function(COORD size, int hInput, int hOutput, int dwFlags,
        Pointer<IntPtr> phPC)>('CreatePseudoConsole');

/// Creates a thread that runs in the virtual address space of another
/// process. Use the CreateRemoteThreadEx function to create a thread that
/// runs in the virtual address space of another process and optionally
/// specify extended attributes.
///
/// ```c
/// HANDLE CreateRemoteThread(
///   HANDLE hProcess,
///   LPSECURITY_ATTRIBUTES lpThreadAttributes,
///   SIZE_T dwStackSize,
///   LPTHREAD_START_ROUTINE lpStartAddress,
///   LPVOID lpParameter,
///   DWORD dwCreationFlags,
///   LPDWORD lpThreadId
/// );
/// ```
/// {@category kernel32}
int CreateRemoteThread(
        int hProcess,
        Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
        int dwStackSize,
        Pointer<NativeFunction<ThreadProc>> lpStartAddress,
        Pointer lpParameter,
        int dwCreationFlags,
        Pointer<Uint32> lpThreadId) =>
    _CreateRemoteThread(hProcess, lpThreadAttributes, dwStackSize,
        lpStartAddress, lpParameter, dwCreationFlags, lpThreadId);

final _CreateRemoteThread = _kernel32.lookupFunction<
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

/// Creates a thread that runs in the virtual address space of another
/// process and optionally specifies extended attributes such as processor
/// group affinity.
///
/// ```c
/// HANDLE CreateRemoteThreadEx(
///   HANDLE hProcess,
///   LPSECURITY_ATTRIBUTES lpThreadAttributes,
///   SIZE_T dwStackSize,
///   LPTHREAD_START_ROUTINE lpStartAddress,
///   LPVOID lpParameter,
///   DWORD dwCreationFlags,
///   LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList,
///   LPDWORD lpThreadId
/// );
/// ```
/// {@category kernel32}
int CreateRemoteThreadEx(
        int hProcess,
        Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
        int dwStackSize,
        Pointer<NativeFunction<ThreadProc>> lpStartAddress,
        Pointer lpParameter,
        int dwCreationFlags,
        Pointer lpAttributeList,
        Pointer<Uint32> lpThreadId) =>
    _CreateRemoteThreadEx(
        hProcess,
        lpThreadAttributes,
        dwStackSize,
        lpStartAddress,
        lpParameter,
        dwCreationFlags,
        lpAttributeList,
        lpThreadId);

final _CreateRemoteThreadEx = _kernel32.lookupFunction<
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

/// Creates a thread to execute within the virtual address space of the
/// calling process.
///
/// ```c
/// HANDLE CreateThread(
///   LPSECURITY_ATTRIBUTES lpThreadAttributes,
///   SIZE_T dwStackSize,
///   LPTHREAD_START_ROUTINE lpStartAddress,
///   LPVOID lpParameter,
///   DWORD dwCreationFlags,
///   LPDWORD lpThreadId
/// );
/// ```
/// {@category kernel32}
int CreateThread(
        Pointer<SECURITY_ATTRIBUTES> lpThreadAttributes,
        int dwStackSize,
        Pointer<NativeFunction<ThreadProc>> lpStartAddress,
        Pointer lpParameter,
        int dwCreationFlags,
        Pointer<Uint32> lpThreadId) =>
    _CreateThread(lpThreadAttributes, dwStackSize, lpStartAddress, lpParameter,
        dwCreationFlags, lpThreadId);

final _CreateThread = _kernel32.lookupFunction<
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

/// The DeactivateActCtx function deactivates the activation context
/// corresponding to the specified cookie.
///
/// ```c
/// BOOL DeactivateActCtx(
///   DWORD     dwFlags,
///   ULONG_PTR ulCookie
/// );
/// ```
/// {@category kernel32}
int DeactivateActCtx(int dwFlags, int ulCookie) =>
    _DeactivateActCtx(dwFlags, ulCookie);

final _DeactivateActCtx = _kernel32.lookupFunction<
    Int32 Function(Uint32 dwFlags, IntPtr ulCookie),
    int Function(int dwFlags, int ulCookie)>('DeactivateActCtx');

/// Causes a breakpoint exception to occur in the current process. This
/// allows the calling thread to signal the debugger to handle the
/// exception.
///
/// ```c
/// void DebugBreak();
/// ```
/// {@category kernel32}
void DebugBreak() => _DebugBreak();

final _DebugBreak =
    _kernel32.lookupFunction<Void Function(), void Function()>('DebugBreak');

/// Causes a breakpoint exception to occur in the specified process. This
/// allows the calling thread to signal the debugger to handle the
/// exception.
///
/// ```c
/// BOOL DebugBreakProcess(
///   HANDLE Process
/// );
/// ```
/// {@category kernel32}
int DebugBreakProcess(int Process) => _DebugBreakProcess(Process);

final _DebugBreakProcess = _kernel32.lookupFunction<
    Int32 Function(IntPtr Process),
    int Function(int Process)>('DebugBreakProcess');

/// Sets the action to be performed when the calling thread exits.
///
/// ```c
/// BOOL DebugSetProcessKillOnExit(
///   BOOL KillOnExit
/// );
/// ```
/// {@category kernel32}
int DebugSetProcessKillOnExit(int KillOnExit) =>
    _DebugSetProcessKillOnExit(KillOnExit);

final _DebugSetProcessKillOnExit = _kernel32.lookupFunction<
    Int32 Function(Int32 KillOnExit),
    int Function(int KillOnExit)>('DebugSetProcessKillOnExit');

/// Defines, redefines, or deletes MS-DOS device names.
///
/// ```c
/// BOOL DefineDosDeviceW(
///   [in]           DWORD   dwFlags,
///   [in]           LPCWSTR lpDeviceName,
///   [in, optional] LPCWSTR lpTargetPath
/// );
/// ```
/// {@category kernel32}
int DefineDosDevice(int dwFlags, Pointer<Utf16> lpDeviceName,
        Pointer<Utf16> lpTargetPath) =>
    _DefineDosDevice(dwFlags, lpDeviceName, lpTargetPath);

final _DefineDosDevice = _kernel32.lookupFunction<
    Int32 Function(Uint32 dwFlags, Pointer<Utf16> lpDeviceName,
        Pointer<Utf16> lpTargetPath),
    int Function(int dwFlags, Pointer<Utf16> lpDeviceName,
        Pointer<Utf16> lpTargetPath)>('DefineDosDeviceW');

/// Deletes an existing file.
///
/// ```c
/// BOOL DeleteFileW(
///   LPCWSTR lpFileName
/// );
/// ```
/// {@category kernel32}
int DeleteFile(Pointer<Utf16> lpFileName) => _DeleteFile(lpFileName);

final _DeleteFile = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName),
    int Function(Pointer<Utf16> lpFileName)>('DeleteFileW');

/// Deletes a drive letter or mounted folder.
///
/// ```c
/// BOOL DeleteVolumeMountPointW(
///   [in] LPCWSTR lpszVolumeMountPoint
/// );
/// ```
/// {@category kernel32}
int DeleteVolumeMountPoint(Pointer<Utf16> lpszVolumeMountPoint) =>
    _DeleteVolumeMountPoint(lpszVolumeMountPoint);

final _DeleteVolumeMountPoint = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpszVolumeMountPoint),
    int Function(
        Pointer<Utf16> lpszVolumeMountPoint)>('DeleteVolumeMountPointW');

/// Sends a control code directly to a specified device driver, causing the
/// corresponding device to perform the corresponding operation.
///
/// ```c
/// BOOL DeviceIoControl(
///   HANDLE       hDevice,
///   DWORD        dwIoControlCode,
///   LPVOID       lpInBuffer,
///   DWORD        nInBufferSize,
///   LPVOID       lpOutBuffer,
///   DWORD        nOutBufferSize,
///   LPDWORD      lpBytesReturned,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int DeviceIoControl(
        int hDevice,
        int dwIoControlCode,
        Pointer lpInBuffer,
        int nInBufferSize,
        Pointer lpOutBuffer,
        int nOutBufferSize,
        Pointer<Uint32> lpBytesReturned,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _DeviceIoControl(hDevice, dwIoControlCode, lpInBuffer, nInBufferSize,
        lpOutBuffer, nOutBufferSize, lpBytesReturned, lpOverlapped);

final _DeviceIoControl = _kernel32.lookupFunction<
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

/// Disables the DLL_THREAD_ATTACH and DLL_THREAD_DETACH notifications for
/// the specified dynamic-link library (DLL). This can reduce the size of
/// the working set for some applications.
///
/// ```c
/// BOOL DisableThreadLibraryCalls(
///   HMODULE hLibModule
/// );
/// ```
/// {@category kernel32}
int DisableThreadLibraryCalls(int hLibModule) =>
    _DisableThreadLibraryCalls(hLibModule);

final _DisableThreadLibraryCalls = _kernel32.lookupFunction<
    Int32 Function(IntPtr hLibModule),
    int Function(int hLibModule)>('DisableThreadLibraryCalls');

/// Disconnects the server end of a named pipe instance from a client
/// process.
///
/// ```c
/// BOOL DisconnectNamedPipe(
///   HANDLE hNamedPipe);
/// ```
/// {@category kernel32}
int DisconnectNamedPipe(int hNamedPipe) => _DisconnectNamedPipe(hNamedPipe);

final _DisconnectNamedPipe = _kernel32.lookupFunction<
    Int32 Function(IntPtr hNamedPipe),
    int Function(int hNamedPipe)>('DisconnectNamedPipe');

/// Converts a DNS-style host name to a NetBIOS-style computer name.
///
/// ```c
/// BOOL DnsHostnameToComputerNameW(
///   LPCWSTR Hostname,
///   LPWSTR  ComputerName,
///   LPDWORD nSize
/// );
/// ```
/// {@category kernel32}
int DnsHostnameToComputerName(Pointer<Utf16> Hostname,
        Pointer<Utf16> ComputerName, Pointer<Uint32> nSize) =>
    _DnsHostnameToComputerName(Hostname, ComputerName, nSize);

final _DnsHostnameToComputerName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> Hostname, Pointer<Utf16> ComputerName,
        Pointer<Uint32> nSize),
    int Function(Pointer<Utf16> Hostname, Pointer<Utf16> ComputerName,
        Pointer<Uint32> nSize)>('DnsHostnameToComputerNameW');

/// Converts MS-DOS date and time values to a file time.
///
/// ```c
/// BOOL DosDateTimeToFileTime(
///   WORD       wFatDate,
///   WORD       wFatTime,
///   LPFILETIME lpFileTime
/// );
/// ```
/// {@category kernel32}
int DosDateTimeToFileTime(
        int wFatDate, int wFatTime, Pointer<FILETIME> lpFileTime) =>
    _DosDateTimeToFileTime(wFatDate, wFatTime, lpFileTime);

final _DosDateTimeToFileTime = _kernel32.lookupFunction<
    Int32 Function(
        Uint16 wFatDate, Uint16 wFatTime, Pointer<FILETIME> lpFileTime),
    int Function(int wFatDate, int wFatTime,
        Pointer<FILETIME> lpFileTime)>('DosDateTimeToFileTime');

/// Duplicates an object handle.
///
/// ```c
/// BOOL DuplicateHandle(
///   HANDLE   hSourceProcessHandle,
///   HANDLE   hSourceHandle,
///   HANDLE   hTargetProcessHandle,
///   LPHANDLE lpTargetHandle,
///   DWORD    dwDesiredAccess,
///   BOOL     bInheritHandle,
///   DWORD    dwOptions
/// );
/// ```
/// {@category kernel32}
int DuplicateHandle(
        int hSourceProcessHandle,
        int hSourceHandle,
        int hTargetProcessHandle,
        Pointer<IntPtr> lpTargetHandle,
        int dwDesiredAccess,
        int bInheritHandle,
        int dwOptions) =>
    _DuplicateHandle(hSourceProcessHandle, hSourceHandle, hTargetProcessHandle,
        lpTargetHandle, dwDesiredAccess, bInheritHandle, dwOptions);

final _DuplicateHandle = _kernel32.lookupFunction<
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

/// Commits or discards changes made prior to a call to UpdateResource.
///
/// ```c
/// BOOL EndUpdateResourceW(
///   HANDLE hUpdate,
///   BOOL   fDiscard
/// );
/// ```
/// {@category kernel32}
int EndUpdateResource(int hUpdate, int fDiscard) =>
    _EndUpdateResource(hUpdate, fDiscard);

final _EndUpdateResource = _kernel32.lookupFunction<
    Int32 Function(IntPtr hUpdate, Int32 fDiscard),
    int Function(int hUpdate, int fDiscard)>('EndUpdateResourceW');

/// Retrieves the process identifier for each process object in the system.
///
/// ```c
/// BOOL K32EnumProcesses(
///   DWORD   *lpidProcess,
///   DWORD   cb,
///   LPDWORD lpcbNeeded
/// );
/// ```
/// {@category kernel32}
int EnumProcesses(
        Pointer<Uint32> lpidProcess, int cb, Pointer<Uint32> lpcbNeeded) =>
    _K32EnumProcesses(lpidProcess, cb, lpcbNeeded);

final _K32EnumProcesses = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Uint32> lpidProcess, Uint32 cb, Pointer<Uint32> lpcbNeeded),
    int Function(Pointer<Uint32> lpidProcess, int cb,
        Pointer<Uint32> lpcbNeeded)>('K32EnumProcesses');

/// Retrieves a handle for each module in the specified process.
///
/// ```c
/// BOOL K32EnumProcessModules(
///   HANDLE  hProcess,
///   HMODULE *lphModule,
///   DWORD   cb,
///   LPDWORD lpcbNeeded
/// );
/// ```
/// {@category kernel32}
int EnumProcessModules(int hProcess, Pointer<IntPtr> lphModule, int cb,
        Pointer<Uint32> lpcbNeeded) =>
    _K32EnumProcessModules(hProcess, lphModule, cb, lpcbNeeded);

final _K32EnumProcessModules = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<IntPtr> lphModule, Uint32 cb,
        Pointer<Uint32> lpcbNeeded),
    int Function(int hProcess, Pointer<IntPtr> lphModule, int cb,
        Pointer<Uint32> lpcbNeeded)>('K32EnumProcessModules');

/// Retrieves a handle for each module in the specified process that meets
/// the specified filter criteria.
///
/// ```c
/// BOOL K32EnumProcessModulesEx(
///   HANDLE  hProcess,
///   HMODULE *lphModule,
///   DWORD   cb,
///   LPDWORD lpcbNeeded,
///   DWORD   dwFilterFlag
/// );
/// ```
/// {@category kernel32}
int EnumProcessModulesEx(int hProcess, Pointer<IntPtr> lphModule, int cb,
        Pointer<Uint32> lpcbNeeded, int dwFilterFlag) =>
    _K32EnumProcessModulesEx(hProcess, lphModule, cb, lpcbNeeded, dwFilterFlag);

final _K32EnumProcessModulesEx = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<IntPtr> lphModule, Uint32 cb,
        Pointer<Uint32> lpcbNeeded, Uint32 dwFilterFlag),
    int Function(
        int hProcess,
        Pointer<IntPtr> lphModule,
        int cb,
        Pointer<Uint32> lpcbNeeded,
        int dwFilterFlag)>('K32EnumProcessModulesEx');

/// Enumerates resources of a specified type within a binary module. For
/// Windows Vista and later, this is typically a language-neutral Portable
/// Executable (LN file), and the enumeration will also include resources
/// from the corresponding language-specific resource files (.mui files)
/// that contain localizable language resources. It is also possible for
/// hModule to specify an .mui file, in which case only that file is
/// searched for resources.
///
/// ```c
/// BOOL EnumResourceNamesW(
///   HMODULE          hModule,
///   LPCWSTR          lpType,
///   ENUMRESNAMEPROCW lpEnumFunc,
///   LONG_PTR         lParam
/// );
/// ```
/// {@category kernel32}
int EnumResourceNames(int hModule, Pointer<Utf16> lpType,
        Pointer<NativeFunction<EnumResNameProc>> lpEnumFunc, int lParam) =>
    _EnumResourceNames(hModule, lpType, lpEnumFunc, lParam);

final _EnumResourceNames = _kernel32.lookupFunction<
    Int32 Function(IntPtr hModule, Pointer<Utf16> lpType,
        Pointer<NativeFunction<EnumResNameProc>> lpEnumFunc, IntPtr lParam),
    int Function(
        int hModule,
        Pointer<Utf16> lpType,
        Pointer<NativeFunction<EnumResNameProc>> lpEnumFunc,
        int lParam)>('EnumResourceNamesW');

/// Enumerates resource types within a binary module. Starting with Windows
/// Vista, this is typically a language-neutral Portable Executable (LN
/// file), and the enumeration also includes resources from one of the
/// corresponding language-specific resource files (.mui files)—if one
/// exists—that contain localizable language resources. It is also possible
/// to use hModule to specify a .mui file, in which case only that file is
/// searched for resource types.
///
/// ```c
/// BOOL EnumResourceTypesW(
///   HMODULE          hModule,
///   ENUMRESTYPEPROCW lpEnumFunc,
///   LONG_PTR         lParam
/// );
/// ```
/// {@category kernel32}
int EnumResourceTypes(int hModule,
        Pointer<NativeFunction<EnumResTypeProc>> lpEnumFunc, int lParam) =>
    _EnumResourceTypes(hModule, lpEnumFunc, lParam);

final _EnumResourceTypes = _kernel32.lookupFunction<
    Int32 Function(IntPtr hModule,
        Pointer<NativeFunction<EnumResTypeProc>> lpEnumFunc, IntPtr lParam),
    int Function(
        int hModule,
        Pointer<NativeFunction<EnumResTypeProc>> lpEnumFunc,
        int lParam)>('EnumResourceTypesW');

/// Directs the specified communications device to perform an extended
/// function.
///
/// ```c
/// BOOL EscapeCommFunction(
///   HANDLE hFile,
///   DWORD  dwFunc
/// );
/// ```
/// {@category kernel32}
int EscapeCommFunction(int hFile, int dwFunc) =>
    _EscapeCommFunction(hFile, dwFunc);

final _EscapeCommFunction = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Uint32 dwFunc),
    int Function(int hFile, int dwFunc)>('EscapeCommFunction');

/// Ends the calling process and all its threads.
///
/// ```c
/// void ExitProcess(
///   UINT uExitCode
/// );
/// ```
/// {@category kernel32}
void ExitProcess(int uExitCode) => _ExitProcess(uExitCode);

final _ExitProcess = _kernel32.lookupFunction<Void Function(Uint32 uExitCode),
    void Function(int uExitCode)>('ExitProcess');

/// Ends the calling thread.
///
/// ```c
/// void ExitThread(
///   DWORD dwExitCode
/// );
/// ```
/// {@category kernel32}
void ExitThread(int dwExitCode) => _ExitThread(dwExitCode);

final _ExitThread = _kernel32.lookupFunction<Void Function(Uint32 dwExitCode),
    void Function(int dwExitCode)>('ExitThread');

/// Converts a file time to MS-DOS date and time values.
///
/// ```c
/// BOOL FileTimeToDosDateTime(
///   const FILETIME *lpFileTime,
///   LPWORD         lpFatDate,
///   LPWORD         lpFatTime
/// );
/// ```
/// {@category kernel32}
int FileTimeToDosDateTime(Pointer<FILETIME> lpFileTime,
        Pointer<Uint16> lpFatDate, Pointer<Uint16> lpFatTime) =>
    _FileTimeToDosDateTime(lpFileTime, lpFatDate, lpFatTime);

final _FileTimeToDosDateTime = _kernel32.lookupFunction<
    Int32 Function(Pointer<FILETIME> lpFileTime, Pointer<Uint16> lpFatDate,
        Pointer<Uint16> lpFatTime),
    int Function(Pointer<FILETIME> lpFileTime, Pointer<Uint16> lpFatDate,
        Pointer<Uint16> lpFatTime)>('FileTimeToDosDateTime');

/// Converts a file time to system time format. System time is based on
/// Coordinated Universal Time (UTC).
///
/// ```c
/// BOOL FileTimeToSystemTime(
///   const FILETIME *lpFileTime,
///   LPSYSTEMTIME   lpSystemTime
/// );
/// ```
/// {@category kernel32}
int FileTimeToSystemTime(
        Pointer<FILETIME> lpFileTime, Pointer<SYSTEMTIME> lpSystemTime) =>
    _FileTimeToSystemTime(lpFileTime, lpSystemTime);

final _FileTimeToSystemTime = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<FILETIME> lpFileTime, Pointer<SYSTEMTIME> lpSystemTime),
    int Function(Pointer<FILETIME> lpFileTime,
        Pointer<SYSTEMTIME> lpSystemTime)>('FileTimeToSystemTime');

/// Sets the character attributes for a specified number of character cells,
/// beginning at the specified coordinates in a screen buffer.
///
/// ```c
/// BOOL FillConsoleOutputAttribute(
///   _In_  HANDLE  hConsoleOutput,
///   _In_  WORD    wAttribute,
///   _In_  DWORD   nLength,
///   _In_  COORD   dwWriteCoord,
///   _Out_ LPDWORD lpNumberOfAttrsWritten
/// );
/// ```
/// {@category kernel32}
int FillConsoleOutputAttribute(int hConsoleOutput, int wAttribute, int nLength,
        COORD dwWriteCoord, Pointer<Uint32> lpNumberOfAttrsWritten) =>
    _FillConsoleOutputAttribute(hConsoleOutput, wAttribute, nLength,
        dwWriteCoord, lpNumberOfAttrsWritten);

final _FillConsoleOutputAttribute = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, Uint16 wAttribute, Uint32 nLength,
        COORD dwWriteCoord, Pointer<Uint32> lpNumberOfAttrsWritten),
    int Function(
        int hConsoleOutput,
        int wAttribute,
        int nLength,
        COORD dwWriteCoord,
        Pointer<Uint32> lpNumberOfAttrsWritten)>('FillConsoleOutputAttribute');

/// Writes a character to the console screen buffer a specified number of
/// times, beginning at the specified coordinates.
///
/// ```c
/// BOOL FillConsoleOutputCharacterW(
///   _In_  HANDLE  hConsoleOutput,
///   _In_  WCHAR   cCharacter,
///   _In_  DWORD   nLength,
///   _In_  COORD   dwWriteCoord,
///   _Out_ LPDWORD lpNumberOfCharsWritten
/// );
/// ```
/// {@category kernel32}
int FillConsoleOutputCharacter(int hConsoleOutput, int cCharacter, int nLength,
        COORD dwWriteCoord, Pointer<Uint32> lpNumberOfCharsWritten) =>
    _FillConsoleOutputCharacter(hConsoleOutput, cCharacter, nLength,
        dwWriteCoord, lpNumberOfCharsWritten);

final _FillConsoleOutputCharacter = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, Uint16 cCharacter, Uint32 nLength,
        COORD dwWriteCoord, Pointer<Uint32> lpNumberOfCharsWritten),
    int Function(
        int hConsoleOutput,
        int cCharacter,
        int nLength,
        COORD dwWriteCoord,
        Pointer<Uint32> lpNumberOfCharsWritten)>('FillConsoleOutputCharacterW');

/// Closes a file search handle opened by the FindFirstFile,
/// FindFirstFileEx, FindFirstFileNameW, FindFirstFileNameTransactedW,
/// FindFirstFileTransacted, FindFirstStreamTransactedW, or FindFirstStreamW
/// functions.
///
/// ```c
/// BOOL FindClose(
///   HANDLE hFindFile
/// );
/// ```
/// {@category kernel32}
int FindClose(int hFindFile) => _FindClose(hFindFile);

final _FindClose = _kernel32.lookupFunction<Int32 Function(IntPtr hFindFile),
    int Function(int hFindFile)>('FindClose');

/// Stops change notification handle monitoring.
///
/// ```c
/// BOOL FindCloseChangeNotification(
///   HANDLE hChangeHandle
/// );
/// ```
/// {@category kernel32}
int FindCloseChangeNotification(int hChangeHandle) =>
    _FindCloseChangeNotification(hChangeHandle);

final _FindCloseChangeNotification = _kernel32.lookupFunction<
    Int32 Function(IntPtr hChangeHandle),
    int Function(int hChangeHandle)>('FindCloseChangeNotification');

/// Creates a change notification handle and sets up initial change
/// notification filter conditions. A wait on a notification handle succeeds
/// when a change matching the filter conditions occurs in the specified
/// directory or subtree. The function does not report changes to the
/// specified directory itself.
///
/// ```c
/// HANDLE FindFirstChangeNotificationW(
///   LPCWSTR lpPathName,
///   BOOL    bWatchSubtree,
///   DWORD   dwNotifyFilter
/// );
/// ```
/// {@category kernel32}
int FindFirstChangeNotification(
        Pointer<Utf16> lpPathName, int bWatchSubtree, int dwNotifyFilter) =>
    _FindFirstChangeNotification(lpPathName, bWatchSubtree, dwNotifyFilter);

final _FindFirstChangeNotification = _kernel32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpPathName, Int32 bWatchSubtree, Uint32 dwNotifyFilter),
    int Function(Pointer<Utf16> lpPathName, int bWatchSubtree,
        int dwNotifyFilter)>('FindFirstChangeNotificationW');

/// Searches a directory for a file or subdirectory with a name that matches
/// a specific name (or partial name if wildcards are used).
///
/// ```c
/// HANDLE FindFirstFileW(
///   LPCWSTR            lpFileName,
///   LPWIN32_FIND_DATAW lpFindFileData
/// );
/// ```
/// {@category kernel32}
int FindFirstFile(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindFirstFile(lpFileName, lpFindFileData);

final _FindFirstFile = _kernel32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(Pointer<Utf16> lpFileName,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindFirstFileW');

/// Searches a directory for a file or subdirectory with a name and
/// attributes that match those specified.
///
/// ```c
/// HANDLE FindFirstFileExW(
///   [in]  LPCWSTR            lpFileName,
///   [in]  FINDEX_INFO_LEVELS fInfoLevelId,
///   [out] LPVOID             lpFindFileData,
///   [in]  FINDEX_SEARCH_OPS  fSearchOp,
///         LPVOID             lpSearchFilter,
///   [in]  DWORD              dwAdditionalFlags
/// );
/// ```
/// {@category kernel32}
int FindFirstFileEx(
        Pointer<Utf16> lpFileName,
        int fInfoLevelId,
        Pointer lpFindFileData,
        int fSearchOp,
        Pointer lpSearchFilter,
        int dwAdditionalFlags) =>
    _FindFirstFileEx(lpFileName, fInfoLevelId, lpFindFileData, fSearchOp,
        lpSearchFilter, dwAdditionalFlags);

final _FindFirstFileEx = _kernel32.lookupFunction<
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

/// Creates an enumeration of all the hard links to the specified file. The
/// FindFirstFileNameW function returns a handle to the enumeration that can
/// be used on subsequent calls to the FindNextFileNameW function.
///
/// ```c
/// HANDLE FindFirstFileNameW(
///   [in]      LPCWSTR lpFileName,
///   [in]      DWORD   dwFlags,
///   [in, out] LPDWORD StringLength,
///   [in, out] PWSTR   LinkName
/// );
/// ```
/// {@category kernel32}
int FindFirstFileName(Pointer<Utf16> lpFileName, int dwFlags,
        Pointer<Uint32> StringLength, Pointer<Utf16> LinkName) =>
    _FindFirstFileName(lpFileName, dwFlags, StringLength, LinkName);

final _FindFirstFileName = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpFileName, Uint32 dwFlags,
        Pointer<Uint32> StringLength, Pointer<Utf16> LinkName),
    int Function(
        Pointer<Utf16> lpFileName,
        int dwFlags,
        Pointer<Uint32> StringLength,
        Pointer<Utf16> LinkName)>('FindFirstFileNameW');

/// Enumerates the first stream with a ::$DATA stream type in the specified
/// file or directory.
///
/// ```c
/// HANDLE FindFirstStreamW(
///   [in]  LPCWSTR            lpFileName,
///   [in]  STREAM_INFO_LEVELS InfoLevel,
///   [out] LPVOID             lpFindStreamData,
///         DWORD              dwFlags
/// );
/// ```
/// {@category kernel32}
int FindFirstStream(Pointer<Utf16> lpFileName, int InfoLevel,
        Pointer lpFindStreamData, int dwFlags) =>
    _FindFirstStream(lpFileName, InfoLevel, lpFindStreamData, dwFlags);

final _FindFirstStream = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpFileName, Int32 InfoLevel,
        Pointer lpFindStreamData, Uint32 dwFlags),
    int Function(Pointer<Utf16> lpFileName, int InfoLevel,
        Pointer lpFindStreamData, int dwFlags)>('FindFirstStreamW');

/// Retrieves the name of a volume on a computer. FindFirstVolume is used to
/// begin scanning the volumes of a computer.
///
/// ```c
/// HANDLE FindFirstVolumeW(
///   LPWSTR lpszVolumeName,
///   DWORD  cchBufferLength
/// );
/// ```
/// {@category kernel32}
int FindFirstVolume(Pointer<Utf16> lpszVolumeName, int cchBufferLength) =>
    _FindFirstVolume(lpszVolumeName, cchBufferLength);

final _FindFirstVolume = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpszVolumeName, Uint32 cchBufferLength),
    int Function(Pointer<Utf16> lpszVolumeName,
        int cchBufferLength)>('FindFirstVolumeW');

/// Requests that the operating system signal a change notification handle
/// the next time it detects an appropriate change.
///
/// ```c
/// BOOL FindNextChangeNotification(
///   HANDLE hChangeHandle
/// );
/// ```
/// {@category kernel32}
int FindNextChangeNotification(int hChangeHandle) =>
    _FindNextChangeNotification(hChangeHandle);

final _FindNextChangeNotification = _kernel32.lookupFunction<
    Int32 Function(IntPtr hChangeHandle),
    int Function(int hChangeHandle)>('FindNextChangeNotification');

/// Continues a file search from a previous call to the FindFirstFile,
/// FindFirstFileEx, or FindFirstFileTransacted functions.
///
/// ```c
/// BOOL FindNextFileW(
///   HANDLE             hFindFile,
///   LPWIN32_FIND_DATAW lpFindFileData
/// );
/// ```
/// {@category kernel32}
int FindNextFile(int hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindNextFile(hFindFile, lpFindFileData);

final _FindNextFile = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(int hFindFile,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindNextFileW');

/// Continues enumerating the hard links to a file using the handle returned
/// by a successful call to the FindFirstFileNameW function.
///
/// ```c
/// BOOL FindNextFileNameW(
///   [in]      HANDLE  hFindStream,
///   [in, out] LPDWORD StringLength,
///   [in, out] PWSTR   LinkName
/// );
/// ```
/// {@category kernel32}
int FindNextFileName(int hFindStream, Pointer<Uint32> StringLength,
        Pointer<Utf16> LinkName) =>
    _FindNextFileName(hFindStream, StringLength, LinkName);

final _FindNextFileName = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindStream, Pointer<Uint32> StringLength,
        Pointer<Utf16> LinkName),
    int Function(int hFindStream, Pointer<Uint32> StringLength,
        Pointer<Utf16> LinkName)>('FindNextFileNameW');

/// Continues a stream search started by a previous call to the
/// FindFirstStreamW function.
///
/// ```c
/// BOOL FindNextStreamW(
///   [in]  HANDLE hFindStream,
///   [out] LPVOID lpFindStreamData
/// );
/// ```
/// {@category kernel32}
int FindNextStream(int hFindStream, Pointer lpFindStreamData) =>
    _FindNextStream(hFindStream, lpFindStreamData);

final _FindNextStream = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindStream, Pointer lpFindStreamData),
    int Function(int hFindStream, Pointer lpFindStreamData)>('FindNextStreamW');

/// Continues a volume search started by a call to the FindFirstVolume
/// function. FindNextVolume finds one volume per call.
///
/// ```c
/// BOOL FindNextVolumeW(
///   HANDLE hFindVolume,
///   LPWSTR lpszVolumeName,
///   DWORD  cchBufferLength
/// );
/// ```
/// {@category kernel32}
int FindNextVolume(
        int hFindVolume, Pointer<Utf16> lpszVolumeName, int cchBufferLength) =>
    _FindNextVolume(hFindVolume, lpszVolumeName, cchBufferLength);

final _FindNextVolume = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindVolume, Pointer<Utf16> lpszVolumeName,
        Uint32 cchBufferLength),
    int Function(int hFindVolume, Pointer<Utf16> lpszVolumeName,
        int cchBufferLength)>('FindNextVolumeW');

/// Finds the packages with the specified family name for the current user.
///
/// ```c
/// LONG FindPackagesByPackageFamily(
///   PCWSTR packageFamilyName,
///   UINT32 packageFilters,
///   UINT32 *count,
///   PWSTR  *packageFullNames,
///   UINT32 *bufferLength,
///   WCHAR  *buffer,
///   UINT32 *packageProperties
/// );
/// ```
/// {@category kernel32}
int FindPackagesByPackageFamily(
        Pointer<Utf16> packageFamilyName,
        int packageFilters,
        Pointer<Uint32> count,
        Pointer<Pointer<Utf16>> packageFullNames,
        Pointer<Uint32> bufferLength,
        Pointer<Utf16> buffer,
        Pointer<Uint32> packageProperties) =>
    _FindPackagesByPackageFamily(packageFamilyName, packageFilters, count,
        packageFullNames, bufferLength, buffer, packageProperties);

final _FindPackagesByPackageFamily = _kernel32.lookupFunction<
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
        Pointer<Uint32> packageProperties)>('FindPackagesByPackageFamily');

/// Determines the location of a resource with the specified type and name
/// in the specified module.
///
/// ```c
/// HRSRC FindResourceW(
///   HMODULE hModule,
///   LPCWSTR  lpName,
///   LPCWSTR  lpType
/// );
/// ```
/// {@category kernel32}
int FindResource(int hModule, Pointer<Utf16> lpName, Pointer<Utf16> lpType) =>
    _FindResource(hModule, lpName, lpType);

final _FindResource = _kernel32.lookupFunction<
    IntPtr Function(
        IntPtr hModule, Pointer<Utf16> lpName, Pointer<Utf16> lpType),
    int Function(int hModule, Pointer<Utf16> lpName,
        Pointer<Utf16> lpType)>('FindResourceW');

/// Determines the location of the resource with the specified type, name,
/// and language in the specified module.
///
/// ```c
/// HRSRC FindResourceExW(
///   HMODULE hModule,
///   LPCWSTR  lpType,
///   LPCWSTR  lpName,
///   WORD    wLanguage
/// );
/// ```
/// {@category kernel32}
int FindResourceEx(int hModule, Pointer<Utf16> lpType, Pointer<Utf16> lpName,
        int wLanguage) =>
    _FindResourceEx(hModule, lpType, lpName, wLanguage);

final _FindResourceEx = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hModule, Pointer<Utf16> lpType,
        Pointer<Utf16> lpName, Uint16 wLanguage),
    int Function(int hModule, Pointer<Utf16> lpType, Pointer<Utf16> lpName,
        int wLanguage)>('FindResourceExW');

/// Locates a Unicode string (wide characters) in another Unicode string for
/// a non-linguistic comparison.
///
/// ```c
/// int FindStringOrdinal(
///   [in] DWORD   dwFindStringOrdinalFlags,
///   [in] LPCWSTR lpStringSource,
///   [in] int     cchSource,
///   [in] LPCWSTR lpStringValue,
///   [in] int     cchValue,
///   [in] BOOL    bIgnoreCase
/// );
/// ```
/// {@category kernel32}
int FindStringOrdinal(
        int dwFindStringOrdinalFlags,
        Pointer<Utf16> lpStringSource,
        int cchSource,
        Pointer<Utf16> lpStringValue,
        int cchValue,
        int bIgnoreCase) =>
    _FindStringOrdinal(dwFindStringOrdinalFlags, lpStringSource, cchSource,
        lpStringValue, cchValue, bIgnoreCase);

final _FindStringOrdinal = _kernel32.lookupFunction<
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

/// Closes the specified volume search handle. The FindFirstVolume and
/// FindNextVolume functions use this search handle to locate volumes.
///
/// ```c
/// BOOL FindVolumeClose(
///   HANDLE hFindVolume
/// );
/// ```
/// {@category kernel32}
int FindVolumeClose(int hFindVolume) => _FindVolumeClose(hFindVolume);

final _FindVolumeClose = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindVolume),
    int Function(int hFindVolume)>('FindVolumeClose');

/// Flushes the console input buffer. All input records currently in the
/// input buffer are discarded.
///
/// ```c
/// BOOL FlushConsoleInputBuffer(
///   _In_ HANDLE hConsoleInput
/// );
/// ```
/// {@category kernel32}
int FlushConsoleInputBuffer(int hConsoleInput) =>
    _FlushConsoleInputBuffer(hConsoleInput);

final _FlushConsoleInputBuffer = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleInput),
    int Function(int hConsoleInput)>('FlushConsoleInputBuffer');

/// Formats a message string. The function requires a message definition as
/// input. The message definition can come from a buffer passed into the
/// function. It can come from a message table resource in an already-loaded
/// module. Or the caller can ask the function to search the system's
/// message table resource(s) for the message definition. The function finds
/// the message definition in a message table resource based on a message
/// identifier and a language identifier. The function copies the formatted
/// message text to an output buffer, processing any embedded insert
/// sequences if requested.
///
/// ```c
/// DWORD FormatMessageW(
///   DWORD   dwFlags,
///   LPCVOID lpSource,
///   DWORD   dwMessageId,
///   DWORD   dwLanguageId,
///   LPWSTR  lpBuffer,
///   DWORD   nSize,
///   va_list *Arguments
/// );
/// ```
/// {@category kernel32}
int FormatMessage(
        int dwFlags,
        Pointer lpSource,
        int dwMessageId,
        int dwLanguageId,
        Pointer<Utf16> lpBuffer,
        int nSize,
        Pointer<Pointer<Int8>> Arguments) =>
    _FormatMessage(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer,
        nSize, Arguments);

final _FormatMessage = _kernel32.lookupFunction<
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

/// Detaches the calling process from its console.
///
/// ```c
/// BOOL FreeConsole(void);
/// ```
/// {@category kernel32}
int FreeConsole() => _FreeConsole();

final _FreeConsole =
    _kernel32.lookupFunction<Int32 Function(), int Function()>('FreeConsole');

/// Frees the loaded dynamic-link library (DLL) module and, if necessary,
/// decrements its reference count. When the reference count reaches zero,
/// the module is unloaded from the address space of the calling process and
/// the handle is no longer valid.
///
/// ```c
/// BOOL FreeLibrary(
///   HMODULE hLibModule
/// );
/// ```
/// {@category kernel32}
int FreeLibrary(int hLibModule) => _FreeLibrary(hLibModule);

final _FreeLibrary = _kernel32.lookupFunction<Int32 Function(IntPtr hLibModule),
    int Function(int hLibModule)>('FreeLibrary');

/// Decrements the reference count of a loaded dynamic-link library (DLL) by
/// one, then calls ExitThread to terminate the calling thread. The function
/// does not return.
///
/// ```c
/// void FreeLibraryAndExitThread(
///   [in] HMODULE hLibModule,
///   [in] DWORD   dwExitCode
/// );
/// ```
/// {@category kernel32}
void FreeLibraryAndExitThread(int hLibModule, int dwExitCode) =>
    _FreeLibraryAndExitThread(hLibModule, dwExitCode);

final _FreeLibraryAndExitThread = _kernel32.lookupFunction<
    Void Function(IntPtr hLibModule, Uint32 dwExitCode),
    void Function(int hLibModule, int dwExitCode)>('FreeLibraryAndExitThread');

/// Returns the number of active processors in a processor group or in the
/// system.
///
/// ```c
/// DWORD GetActiveProcessorCount(
///   WORD GroupNumber
/// );
/// ```
/// {@category kernel32}
int GetActiveProcessorCount(int GroupNumber) =>
    _GetActiveProcessorCount(GroupNumber);

final _GetActiveProcessorCount = _kernel32.lookupFunction<
    Uint32 Function(Uint16 GroupNumber),
    int Function(int GroupNumber)>('GetActiveProcessorCount');

/// Returns the number of active processor groups in the system.
///
/// ```c
/// WORD GetActiveProcessorGroupCount();
/// ```
/// {@category kernel32}
int GetActiveProcessorGroupCount() => _GetActiveProcessorGroupCount();

final _GetActiveProcessorGroupCount =
    _kernel32.lookupFunction<Uint16 Function(), int Function()>(
        'GetActiveProcessorGroupCount');

/// Determines whether a file is an executable (.exe) file, and if so, which
/// subsystem runs the executable file.
///
/// ```c
/// BOOL GetBinaryTypeW(
///   LPCWSTR lpApplicationName,
///   LPDWORD lpBinaryType);
/// ```
/// {@category kernel32}
int GetBinaryType(
        Pointer<Utf16> lpApplicationName, Pointer<Uint32> lpBinaryType) =>
    _GetBinaryType(lpApplicationName, lpBinaryType);

final _GetBinaryType = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpApplicationName, Pointer<Uint32> lpBinaryType),
    int Function(Pointer<Utf16> lpApplicationName,
        Pointer<Uint32> lpBinaryType)>('GetBinaryTypeW');

/// Parses a Unicode command line string and returns an array of pointers to
/// the command line arguments, along with a count of such arguments, in a
/// way that is similar to the standard C run-time argv and argc values.
///
/// ```c
/// LPWSTR GetCommandLineW();
/// ```
/// {@category kernel32}
Pointer<Utf16> GetCommandLine() => _GetCommandLine();

final _GetCommandLine = _kernel32.lookupFunction<Pointer<Utf16> Function(),
    Pointer<Utf16> Function()>('GetCommandLineW');

/// Retrieves the current configuration of a communications device.
///
/// ```c
/// BOOL GetCommConfig(
///   HANDLE       hCommDev,
///   LPCOMMCONFIG lpCC,
///   LPDWORD      lpdwSize
/// );
/// ```
/// {@category kernel32}
int GetCommConfig(
        int hCommDev, Pointer<COMMCONFIG> lpCC, Pointer<Uint32> lpdwSize) =>
    _GetCommConfig(hCommDev, lpCC, lpdwSize);

final _GetCommConfig = _kernel32.lookupFunction<
    Int32 Function(
        IntPtr hCommDev, Pointer<COMMCONFIG> lpCC, Pointer<Uint32> lpdwSize),
    int Function(int hCommDev, Pointer<COMMCONFIG> lpCC,
        Pointer<Uint32> lpdwSize)>('GetCommConfig');

/// Retrieves the value of the event mask for a specified communications
/// device.
///
/// ```c
/// BOOL GetCommMask(
///   HANDLE  hFile,
///   LPDWORD lpEvtMask
/// );
/// ```
/// {@category kernel32}
int GetCommMask(int hFile, Pointer<Uint32> lpEvtMask) =>
    _GetCommMask(hFile, lpEvtMask);

final _GetCommMask = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<Uint32> lpEvtMask),
    int Function(int hFile, Pointer<Uint32> lpEvtMask)>('GetCommMask');

/// Retrieves the modem control-register values.
///
/// ```c
/// BOOL GetCommModemStatus(
///   HANDLE  hFile,
///   LPDWORD lpModemStat
/// );
/// ```
/// {@category kernel32}
int GetCommModemStatus(int hFile, Pointer<Uint32> lpModemStat) =>
    _GetCommModemStatus(hFile, lpModemStat);

final _GetCommModemStatus = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<Uint32> lpModemStat),
    int Function(int hFile, Pointer<Uint32> lpModemStat)>('GetCommModemStatus');

/// Retrieves information about the communications properties for a
/// specified communications device.
///
/// ```c
/// BOOL GetCommProperties(
///   HANDLE     hFile,
///   LPCOMMPROP lpCommProp
/// );
/// ```
/// {@category kernel32}
int GetCommProperties(int hFile, Pointer<COMMPROP> lpCommProp) =>
    _GetCommProperties(hFile, lpCommProp);

final _GetCommProperties = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<COMMPROP> lpCommProp),
    int Function(int hFile, Pointer<COMMPROP> lpCommProp)>('GetCommProperties');

/// Retrieves the current control settings for a specified communications
/// device.
///
/// ```c
/// BOOL GetCommState(
///   HANDLE hFile,
///   LPDCB  lpDCB
/// );
/// ```
/// {@category kernel32}
int GetCommState(int hFile, Pointer<DCB> lpDCB) => _GetCommState(hFile, lpDCB);

final _GetCommState = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB),
    int Function(int hFile, Pointer<DCB> lpDCB)>('GetCommState');

/// Retrieves the time-out parameters for all read and write operations on a
/// specified communications device.
///
/// ```c
/// BOOL GetCommTimeouts(
///   HANDLE         hFile,
///   LPCOMMTIMEOUTS lpCommTimeouts
/// );
/// ```
/// {@category kernel32}
int GetCommTimeouts(int hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts) =>
    _GetCommTimeouts(hFile, lpCommTimeouts);

final _GetCommTimeouts = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts),
    int Function(
        int hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts)>('GetCommTimeouts');

/// Retrieves the actual number of bytes of disk storage used to store a
/// specified file. If the file is located on a volume that supports
/// compression and the file is compressed, the value obtained is the
/// compressed size of the specified file. If the file is located on a
/// volume that supports sparse files and the file is a sparse file, the
/// value obtained is the sparse size of the specified file.
///
/// ```c
/// DWORD GetCompressedFileSizeW(
///   LPCWSTR lpFileName,
///   LPDWORD lpFileSizeHigh
/// );
/// ```
/// {@category kernel32}
int GetCompressedFileSize(
        Pointer<Utf16> lpFileName, Pointer<Uint32> lpFileSizeHigh) =>
    _GetCompressedFileSize(lpFileName, lpFileSizeHigh);

final _GetCompressedFileSize = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpFileName, Pointer<Uint32> lpFileSizeHigh),
    int Function(Pointer<Utf16> lpFileName,
        Pointer<Uint32> lpFileSizeHigh)>('GetCompressedFileSizeW');

/// Retrieves the NetBIOS name of the local computer. This name is
/// established at system startup, when the system reads it from the
/// registry.
///
/// ```c
/// BOOL GetComputerNameW(
///   LPWSTR  lpBuffer,
///   LPDWORD nSize
/// );
/// ```
/// {@category kernel32}
int GetComputerName(Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize) =>
    _GetComputerName(lpBuffer, nSize);

final _GetComputerName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize),
    int Function(
        Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize)>('GetComputerNameW');

/// Retrieves a NetBIOS or DNS name associated with the local computer. The
/// names are established at system startup, when the system reads them from
/// the registry.
///
/// ```c
/// BOOL GetComputerNameExW(
///   COMPUTER_NAME_FORMAT NameType,
///   LPWSTR               lpBuffer,
///   LPDWORD              nSize
/// );
/// ```
/// {@category kernel32}
int GetComputerNameEx(
        int NameType, Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize) =>
    _GetComputerNameEx(NameType, lpBuffer, nSize);

final _GetComputerNameEx = _kernel32.lookupFunction<
    Int32 Function(
        Int32 NameType, Pointer<Utf16> lpBuffer, Pointer<Uint32> nSize),
    int Function(int NameType, Pointer<Utf16> lpBuffer,
        Pointer<Uint32> nSize)>('GetComputerNameExW');

/// Retrieves the input code page used by the console associated with the
/// calling process. A console uses its input code page to translate
/// keyboard input into the corresponding character value.
///
/// ```c
/// UINT GetConsoleCP(void);
/// ```
/// {@category kernel32}
int GetConsoleCP() => _GetConsoleCP();

final _GetConsoleCP =
    _kernel32.lookupFunction<Uint32 Function(), int Function()>('GetConsoleCP');

/// Retrieves information about the size and visibility of the cursor for
/// the specified console screen buffer.
///
/// ```c
/// BOOL GetConsoleCursorInfo(
///   _In_  HANDLE               hConsoleOutput,
///   _Out_ PCONSOLE_CURSOR_INFO lpConsoleCursorInfo
/// );
/// ```
/// {@category kernel32}
int GetConsoleCursorInfo(
        int hConsoleOutput, Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo) =>
    _GetConsoleCursorInfo(hConsoleOutput, lpConsoleCursorInfo);

final _GetConsoleCursorInfo = _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleOutput,
            Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo),
        int Function(int hConsoleOutput,
            Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo)>(
    'GetConsoleCursorInfo');

/// Retrieves the current input mode of a console's input buffer or the
/// current output mode of a console screen buffer.
///
/// ```c
/// BOOL GetConsoleMode(
///   _In_  HANDLE  hConsoleHandle,
///   _Out_ LPDWORD lpMode
/// );
/// ```
/// {@category kernel32}
int GetConsoleMode(int hConsoleHandle, Pointer<Uint32> lpMode) =>
    _GetConsoleMode(hConsoleHandle, lpMode);

final _GetConsoleMode = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleHandle, Pointer<Uint32> lpMode),
    int Function(int hConsoleHandle, Pointer<Uint32> lpMode)>('GetConsoleMode');

/// Retrieves the output code page used by the console associated with the
/// calling process. A console uses its output code page to translate the
/// character values written by the various output functions into the images
/// displayed in the console window.
///
/// ```c
/// UINT GetConsoleOutputCP(void);
/// ```
/// {@category kernel32}
int GetConsoleOutputCP() => _GetConsoleOutputCP();

final _GetConsoleOutputCP = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetConsoleOutputCP');

/// Retrieves information about the specified console screen buffer.
///
/// ```c
/// BOOL GetConsoleScreenBufferInfo(
///   _In_  HANDLE                      hConsoleOutput,
///   _Out_ PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo
/// );
/// ```
/// {@category kernel32}
int GetConsoleScreenBufferInfo(int hConsoleOutput,
        Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo) =>
    _GetConsoleScreenBufferInfo(hConsoleOutput, lpConsoleScreenBufferInfo);

final _GetConsoleScreenBufferInfo = _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleOutput,
            Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo),
        int Function(int hConsoleOutput,
            Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo)>(
    'GetConsoleScreenBufferInfo');

/// Retrieves information about the current console selection.
///
/// ```c
/// BOOL GetConsoleSelectionInfo(
///   _Out_ PCONSOLE_SELECTION_INFO lpConsoleSelectionInfo
/// );
/// ```
/// {@category kernel32}
int GetConsoleSelectionInfo(
        Pointer<CONSOLE_SELECTION_INFO> lpConsoleSelectionInfo) =>
    _GetConsoleSelectionInfo(lpConsoleSelectionInfo);

final _GetConsoleSelectionInfo = _kernel32.lookupFunction<
        Int32 Function(Pointer<CONSOLE_SELECTION_INFO> lpConsoleSelectionInfo),
        int Function(Pointer<CONSOLE_SELECTION_INFO> lpConsoleSelectionInfo)>(
    'GetConsoleSelectionInfo');

/// Retrieves the title for the current console window.
///
/// ```c
/// DWORD GetConsoleTitleW(
///   _Out_ LPTSTR lpConsoleTitle,
///   _In_  DWORD  nSize
/// );
/// ```
/// {@category kernel32}
int GetConsoleTitle(Pointer<Utf16> lpConsoleTitle, int nSize) =>
    _GetConsoleTitle(lpConsoleTitle, nSize);

final _GetConsoleTitle = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpConsoleTitle, Uint32 nSize),
    int Function(Pointer<Utf16> lpConsoleTitle, int nSize)>('GetConsoleTitleW');

/// Retrieves the window handle used by the console associated with the
/// calling process.
///
/// ```c
/// HWND GetConsoleWindow(void);
/// ```
/// {@category kernel32}
int GetConsoleWindow() => _GetConsoleWindow();

final _GetConsoleWindow = _kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetConsoleWindow');

/// The GetCurrentActCtx function returns the handle to the active
/// activation context of the calling thread.
///
/// ```c
/// BOOL GetCurrentActCtx(
///   HANDLE *lphActCtx
/// );
/// ```
/// {@category kernel32}
int GetCurrentActCtx(Pointer<IntPtr> lphActCtx) => _GetCurrentActCtx(lphActCtx);

final _GetCurrentActCtx = _kernel32.lookupFunction<
    Int32 Function(Pointer<IntPtr> lphActCtx),
    int Function(Pointer<IntPtr> lphActCtx)>('GetCurrentActCtx');

/// Retrieves a pseudo handle for the current process.
///
/// ```c
/// HANDLE GetCurrentProcess();
/// ```
/// {@category kernel32}
int GetCurrentProcess() => _GetCurrentProcess();

final _GetCurrentProcess = _kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');

/// Retrieves the process identifier of the calling process.
///
/// ```c
/// DWORD GetCurrentProcessId();
/// ```
/// {@category kernel32}
int GetCurrentProcessId() => _GetCurrentProcessId();

final _GetCurrentProcessId = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetCurrentProcessId');

/// Retrieves the number of the processor the current thread was running on
/// during the call to this function.
///
/// ```c
/// DWORD GetCurrentProcessorNumber();
/// ```
/// {@category kernel32}
int GetCurrentProcessorNumber() => _GetCurrentProcessorNumber();

final _GetCurrentProcessorNumber =
    _kernel32.lookupFunction<Uint32 Function(), int Function()>(
        'GetCurrentProcessorNumber');

/// Retrieves a pseudo handle for the calling thread.
///
/// ```c
/// HANDLE GetCurrentThread();
/// ```
/// {@category kernel32}
int GetCurrentThread() => _GetCurrentThread();

final _GetCurrentThread = _kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetCurrentThread');

/// Retrieves the thread identifier of the calling thread.
///
/// ```c
/// DWORD GetCurrentThreadId();
/// ```
/// {@category kernel32}
int GetCurrentThreadId() => _GetCurrentThreadId();

final _GetCurrentThreadId = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetCurrentThreadId');

/// Retrieves the default configuration for the specified communications
/// device.
///
/// ```c
/// BOOL GetDefaultCommConfigW(
///   LPCWSTR      lpszName,
///   LPCOMMCONFIG lpCC,
///   LPDWORD      lpdwSize
/// );
/// ```
/// {@category kernel32}
int GetDefaultCommConfig(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
        Pointer<Uint32> lpdwSize) =>
    _GetDefaultCommConfig(lpszName, lpCC, lpdwSize);

final _GetDefaultCommConfig = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
        Pointer<Uint32> lpdwSize),
    int Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
        Pointer<Uint32> lpdwSize)>('GetDefaultCommConfigW');

/// Retrieves information about the specified disk, including the amount of
/// free space on the disk.
///
/// ```c
/// BOOL GetDiskFreeSpaceW(
///   LPCWSTR lpRootPathName,
///   LPDWORD lpSectorsPerCluster,
///   LPDWORD lpBytesPerSector,
///   LPDWORD lpNumberOfFreeClusters,
///   LPDWORD lpTotalNumberOfClusters
/// );
/// ```
/// {@category kernel32}
int GetDiskFreeSpace(
        Pointer<Utf16> lpRootPathName,
        Pointer<Uint32> lpSectorsPerCluster,
        Pointer<Uint32> lpBytesPerSector,
        Pointer<Uint32> lpNumberOfFreeClusters,
        Pointer<Uint32> lpTotalNumberOfClusters) =>
    _GetDiskFreeSpace(lpRootPathName, lpSectorsPerCluster, lpBytesPerSector,
        lpNumberOfFreeClusters, lpTotalNumberOfClusters);

final _GetDiskFreeSpace = _kernel32.lookupFunction<
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

/// Retrieves information about the amount of space that is available on a
/// disk volume, which is the total amount of space, the total amount of
/// free space, and the total amount of free space available to the user
/// that is associated with the calling thread.
///
/// ```c
/// BOOL GetDiskFreeSpaceExW(
///   [in, optional]  LPCWSTR         lpDirectoryName,
///   [out, optional] PULARGE_INTEGER lpFreeBytesAvailableToCaller,
///   [out, optional] PULARGE_INTEGER lpTotalNumberOfBytes,
///   [out, optional] PULARGE_INTEGER lpTotalNumberOfFreeBytes
/// );
/// ```
/// {@category kernel32}
int GetDiskFreeSpaceEx(
        Pointer<Utf16> lpDirectoryName,
        Pointer<Uint64> lpFreeBytesAvailableToCaller,
        Pointer<Uint64> lpTotalNumberOfBytes,
        Pointer<Uint64> lpTotalNumberOfFreeBytes) =>
    _GetDiskFreeSpaceEx(lpDirectoryName, lpFreeBytesAvailableToCaller,
        lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes);

final _GetDiskFreeSpaceEx = _kernel32.lookupFunction<
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

/// Retrieves the application-specific portion of the search path used to
/// locate DLLs for the application.
///
/// ```c
/// DWORD GetDllDirectoryW(
///   DWORD  nBufferLength,
///   LPWSTR lpBuffer
/// );
/// ```
/// {@category kernel32}
int GetDllDirectory(int nBufferLength, Pointer<Utf16> lpBuffer) =>
    _GetDllDirectory(nBufferLength, lpBuffer);

final _GetDllDirectory = _kernel32.lookupFunction<
    Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
    int Function(
        int nBufferLength, Pointer<Utf16> lpBuffer)>('GetDllDirectoryW');

/// Determines whether a disk drive is a removable, fixed, CD-ROM, RAM disk,
/// or network drive.
///
/// ```c
/// UINT GetDriveTypeW(
///   LPCWSTR lpRootPathName
/// );
/// ```
/// {@category kernel32}
int GetDriveType(Pointer<Utf16> lpRootPathName) =>
    _GetDriveType(lpRootPathName);

final _GetDriveType = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpRootPathName),
    int Function(Pointer<Utf16> lpRootPathName)>('GetDriveTypeW');

/// Retrieves the contents of the specified variable from the environment
/// block of the calling process.
///
/// ```c
/// DWORD GetEnvironmentVariableW(
///   LPCTSTR lpName,
///   LPTSTR  lpBuffer,
///   DWORD   nSize
/// );
/// ```
/// {@category kernel32}
int GetEnvironmentVariable(
        Pointer<Utf16> lpName, Pointer<Utf16> lpBuffer, int nSize) =>
    _GetEnvironmentVariable(lpName, lpBuffer, nSize);

final _GetEnvironmentVariable = _kernel32.lookupFunction<
    Uint32 Function(
        Pointer<Utf16> lpName, Pointer<Utf16> lpBuffer, Uint32 nSize),
    int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpBuffer,
        int nSize)>('GetEnvironmentVariableW');

/// Retrieves the termination status of the specified process.
///
/// ```c
/// BOOL GetExitCodeProcess(
///   HANDLE  hProcess,
///   LPDWORD lpExitCode);
/// ```
/// {@category kernel32}
int GetExitCodeProcess(int hProcess, Pointer<Uint32> lpExitCode) =>
    _GetExitCodeProcess(hProcess, lpExitCode);

final _GetExitCodeProcess = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<Uint32> lpExitCode),
    int Function(
        int hProcess, Pointer<Uint32> lpExitCode)>('GetExitCodeProcess');

/// Retrieves file system attributes for a specified file or directory.
///
/// ```c
/// DWORD GetFileAttributesW(
///   LPCWSTR lpFileName
/// );
/// ```
/// {@category kernel32}
int GetFileAttributes(Pointer<Utf16> lpFileName) =>
    _GetFileAttributes(lpFileName);

final _GetFileAttributes = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpFileName),
    int Function(Pointer<Utf16> lpFileName)>('GetFileAttributesW');

/// Retrieves attributes for a specified file or directory.
///
/// ```c
/// BOOL GetFileAttributesExW(
///   LPCWSTR                lpFileName,
///   GET_FILEEX_INFO_LEVELS fInfoLevelId,
///   LPVOID                 lpFileInformation
/// );
/// ```
/// {@category kernel32}
int GetFileAttributesEx(Pointer<Utf16> lpFileName, int fInfoLevelId,
        Pointer lpFileInformation) =>
    _GetFileAttributesEx(lpFileName, fInfoLevelId, lpFileInformation);

final _GetFileAttributesEx = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName, Int32 fInfoLevelId,
        Pointer lpFileInformation),
    int Function(Pointer<Utf16> lpFileName, int fInfoLevelId,
        Pointer lpFileInformation)>('GetFileAttributesExW');

/// Retrieves file information for the specified file.
///
/// ```c
/// BOOL GetFileInformationByHandle(
///   HANDLE                       hFile,
///   LPBY_HANDLE_FILE_INFORMATION lpFileInformation
/// );
/// ```
/// {@category kernel32}
int GetFileInformationByHandle(
        int hFile, Pointer<BY_HANDLE_FILE_INFORMATION> lpFileInformation) =>
    _GetFileInformationByHandle(hFile, lpFileInformation);

final _GetFileInformationByHandle = _kernel32.lookupFunction<
        Int32 Function(IntPtr hFile,
            Pointer<BY_HANDLE_FILE_INFORMATION> lpFileInformation),
        int Function(
            int hFile, Pointer<BY_HANDLE_FILE_INFORMATION> lpFileInformation)>(
    'GetFileInformationByHandle');

/// Retrieves the size of the specified file, in bytes. It is recommended
/// that you use GetFileSizeEx.
///
/// ```c
/// DWORD GetFileSize(
///   HANDLE  hFile,
///   LPDWORD lpFileSizeHigh
/// );
/// ```
/// {@category kernel32}
int GetFileSize(int hFile, Pointer<Uint32> lpFileSizeHigh) =>
    _GetFileSize(hFile, lpFileSizeHigh);

final _GetFileSize = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hFile, Pointer<Uint32> lpFileSizeHigh),
    int Function(int hFile, Pointer<Uint32> lpFileSizeHigh)>('GetFileSize');

/// Retrieves the size of the specified file.
///
/// ```c
/// BOOL GetFileSizeEx(
///   HANDLE         hFile,
///   PLARGE_INTEGER lpFileSize
/// );
/// ```
/// {@category kernel32}
int GetFileSizeEx(int hFile, Pointer<Int64> lpFileSize) =>
    _GetFileSizeEx(hFile, lpFileSize);

final _GetFileSizeEx = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<Int64> lpFileSize),
    int Function(int hFile, Pointer<Int64> lpFileSize)>('GetFileSizeEx');

/// Retrieves the file type of the specified file.
///
/// ```c
/// DWORD GetFileType(
///   HANDLE hFile
/// );
/// ```
/// {@category kernel32}
int GetFileType(int hFile) => _GetFileType(hFile);

final _GetFileType = _kernel32.lookupFunction<Uint32 Function(IntPtr hFile),
    int Function(int hFile)>('GetFileType');

/// Retrieves the final path for the specified file.
///
/// ```c
/// DWORD GetFinalPathNameByHandleW(
///   HANDLE hFile,
///   LPWSTR lpszFilePath,
///   DWORD  cchFilePath,
///   DWORD  dwFlags
/// );
/// ```
/// {@category kernel32}
int GetFinalPathNameByHandle(
        int hFile, Pointer<Utf16> lpszFilePath, int cchFilePath, int dwFlags) =>
    _GetFinalPathNameByHandle(hFile, lpszFilePath, cchFilePath, dwFlags);

final _GetFinalPathNameByHandle = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hFile, Pointer<Utf16> lpszFilePath,
        Uint32 cchFilePath, Uint32 dwFlags),
    int Function(int hFile, Pointer<Utf16> lpszFilePath, int cchFilePath,
        int dwFlags)>('GetFinalPathNameByHandleW');

/// Retrieves the full path and file name of the specified file.
///
/// ```c
/// DWORD GetFullPathNameW(
///   LPCWSTR lpFileName,
///   DWORD   nBufferLength,
///   LPWSTR  lpBuffer,
///   LPWSTR  *lpFilePart
/// );
/// ```
/// {@category kernel32}
int GetFullPathName(Pointer<Utf16> lpFileName, int nBufferLength,
        Pointer<Utf16> lpBuffer, Pointer<Pointer<Utf16>> lpFilePart) =>
    _GetFullPathName(lpFileName, nBufferLength, lpBuffer, lpFilePart);

final _GetFullPathName = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpFileName, Uint32 nBufferLength,
        Pointer<Utf16> lpBuffer, Pointer<Pointer<Utf16>> lpFilePart),
    int Function(
        Pointer<Utf16> lpFileName,
        int nBufferLength,
        Pointer<Utf16> lpBuffer,
        Pointer<Pointer<Utf16>> lpFilePart)>('GetFullPathNameW');

/// Retrieves certain properties of an object handle.
///
/// ```c
/// BOOL GetHandleInformation(
///   HANDLE  hObject,
///   LPDWORD lpdwFlags
/// );
/// ```
/// {@category kernel32}
int GetHandleInformation(int hObject, Pointer<Uint32> lpdwFlags) =>
    _GetHandleInformation(hObject, lpdwFlags);

final _GetHandleInformation = _kernel32.lookupFunction<
    Int32 Function(IntPtr hObject, Pointer<Uint32> lpdwFlags),
    int Function(
        int hObject, Pointer<Uint32> lpdwFlags)>('GetHandleInformation');

/// Retrieves the size of the largest possible console window, based on the
/// current font and the size of the display.
///
/// ```c
/// COORD GetLargestConsoleWindowSize(
///   _In_ HANDLE hConsoleOutput
/// );
/// ```
/// {@category kernel32}
COORD GetLargestConsoleWindowSize(int hConsoleOutput) =>
    _GetLargestConsoleWindowSize(hConsoleOutput);

final _GetLargestConsoleWindowSize = _kernel32.lookupFunction<
    COORD Function(IntPtr hConsoleOutput),
    COORD Function(int hConsoleOutput)>('GetLargestConsoleWindowSize');

/// Retrieves the calling thread's last-error code value. The last-error
/// code is maintained on a per-thread basis. Multiple threads do not
/// overwrite each other's last-error code.
///
/// ```c
/// DWORD GetLastError();
/// ```
/// {@category kernel32}
int GetLastError() => _GetLastError();

final _GetLastError =
    _kernel32.lookupFunction<Uint32 Function(), int Function()>('GetLastError');

/// Retrieves information about a locale specified by name.
///
/// ```c
/// int GetLocaleInfoEx(
///   LPCWSTR lpLocaleName,
///   LCTYPE  LCType,
///   LPWSTR  lpLCData,
///   int     cchData
/// );
/// ```
/// {@category kernel32}
int GetLocaleInfoEx(Pointer<Utf16> lpLocaleName, int LCType,
        Pointer<Utf16> lpLCData, int cchData) =>
    _GetLocaleInfoEx(lpLocaleName, LCType, lpLCData, cchData);

final _GetLocaleInfoEx = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpLocaleName, Uint32 LCType,
        Pointer<Utf16> lpLCData, Int32 cchData),
    int Function(Pointer<Utf16> lpLocaleName, int LCType,
        Pointer<Utf16> lpLCData, int cchData)>('GetLocaleInfoEx');

/// Retrieves the current local date and time.
///
/// ```c
/// void GetLocalTime(
///   LPSYSTEMTIME lpSystemTime
/// );
/// ```
/// {@category kernel32}
void GetLocalTime(Pointer<SYSTEMTIME> lpSystemTime) =>
    _GetLocalTime(lpSystemTime);

final _GetLocalTime = _kernel32.lookupFunction<
    Void Function(Pointer<SYSTEMTIME> lpSystemTime),
    void Function(Pointer<SYSTEMTIME> lpSystemTime)>('GetLocalTime');

/// Retrieves a bitmask representing the currently available disk drives.
///
/// ```c
/// DWORD GetLogicalDrives();
/// ```
/// {@category kernel32}
int GetLogicalDrives() => _GetLogicalDrives();

final _GetLogicalDrives = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetLogicalDrives');

/// Fills a buffer with strings that specify valid drives in the system.
///
/// ```c
/// DWORD GetLogicalDriveStringsW(
///   DWORD  nBufferLength,
///   LPWSTR lpBuffer
/// );
/// ```
/// {@category kernel32}
int GetLogicalDriveStrings(int nBufferLength, Pointer<Utf16> lpBuffer) =>
    _GetLogicalDriveStrings(nBufferLength, lpBuffer);

final _GetLogicalDriveStrings = _kernel32.lookupFunction<
    Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
    int Function(
        int nBufferLength, Pointer<Utf16> lpBuffer)>('GetLogicalDriveStringsW');

/// Converts the specified path to its long form.
///
/// ```c
/// DWORD GetLongPathNameW(
///   [in]  LPCWSTR lpszShortPath,
///   [out] LPWSTR  lpszLongPath,
///   [in]  DWORD   cchBuffer
/// );
/// ```
/// {@category kernel32}
int GetLongPathName(Pointer<Utf16> lpszShortPath, Pointer<Utf16> lpszLongPath,
        int cchBuffer) =>
    _GetLongPathName(lpszShortPath, lpszLongPath, cchBuffer);

final _GetLongPathName = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpszShortPath, Pointer<Utf16> lpszLongPath,
        Uint32 cchBuffer),
    int Function(Pointer<Utf16> lpszShortPath, Pointer<Utf16> lpszLongPath,
        int cchBuffer)>('GetLongPathNameW');

/// Queries if the specified architecture is supported on the current
/// system, either natively or by any form of compatibility or emulation
/// layer.
///
/// ```c
/// HRESULT GetMachineTypeAttributes(
///   USHORT Machine,
///   MACHINE_ATTRIBUTES *MachineTypeAttributes
/// );
/// ```
/// {@category kernel32}
int GetMachineTypeAttributes(
        int Machine, Pointer<Uint32> MachineTypeAttributes) =>
    _GetMachineTypeAttributes(Machine, MachineTypeAttributes);

final _GetMachineTypeAttributes = _kernel32.lookupFunction<
    Int32 Function(Uint16 Machine, Pointer<Uint32> MachineTypeAttributes),
    int Function(int Machine,
        Pointer<Uint32> MachineTypeAttributes)>('GetMachineTypeAttributes');

/// Returns the maximum number of logical processors that a processor group
/// or the system can have.
///
/// ```c
/// DWORD GetMaximumProcessorCount(
///   WORD GroupNumber
/// );
/// ```
/// {@category kernel32}
int GetMaximumProcessorCount(int GroupNumber) =>
    _GetMaximumProcessorCount(GroupNumber);

final _GetMaximumProcessorCount = _kernel32.lookupFunction<
    Uint32 Function(Uint16 GroupNumber),
    int Function(int GroupNumber)>('GetMaximumProcessorCount');

/// Returns the maximum number of processor groups that the system can have.
///
/// ```c
/// WORD GetMaximumProcessorGroupCount();
/// ```
/// {@category kernel32}
int GetMaximumProcessorGroupCount() => _GetMaximumProcessorGroupCount();

final _GetMaximumProcessorGroupCount =
    _kernel32.lookupFunction<Uint16 Function(), int Function()>(
        'GetMaximumProcessorGroupCount');

/// Retrieves the base name of the specified module.
///
/// ```c
/// DWORD K32GetModuleBaseNameW(
///   HANDLE  hProcess,
///   HMODULE hModule,
///   LPWSTR  lpBaseName,
///   DWORD   nSize
/// );
/// ```
/// {@category kernel32}
int GetModuleBaseName(
        int hProcess, int hModule, Pointer<Utf16> lpBaseName, int nSize) =>
    _K32GetModuleBaseName(hProcess, hModule, lpBaseName, nSize);

final _K32GetModuleBaseName = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hProcess, IntPtr hModule, Pointer<Utf16> lpBaseName,
        Uint32 nSize),
    int Function(int hProcess, int hModule, Pointer<Utf16> lpBaseName,
        int nSize)>('K32GetModuleBaseNameW');

/// Retrieves the fully qualified path for the file that contains the
/// specified module. The module must have been loaded by the current
/// process.
///
/// ```c
/// DWORD GetModuleFileNameW(
///   HMODULE hModule,
///   LPWSTR  lpFilename,
///   DWORD   nSize
/// );
/// ```
/// {@category kernel32}
int GetModuleFileName(int hModule, Pointer<Utf16> lpFilename, int nSize) =>
    _GetModuleFileName(hModule, lpFilename, nSize);

final _GetModuleFileName = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hModule, Pointer<Utf16> lpFilename, Uint32 nSize),
    int Function(int hModule, Pointer<Utf16> lpFilename,
        int nSize)>('GetModuleFileNameW');

/// Retrieves the fully qualified path for the file containing the specified
/// module.
///
/// ```c
/// DWORD K32GetModuleFileNameExW(
///   HANDLE  hProcess,
///   HMODULE hModule,
///   LPWSTR  lpFilename,
///   DWORD   nSize
/// );
/// ```
/// {@category kernel32}
int GetModuleFileNameEx(
        int hProcess, int hModule, Pointer<Utf16> lpFilename, int nSize) =>
    _K32GetModuleFileNameEx(hProcess, hModule, lpFilename, nSize);

final _K32GetModuleFileNameEx = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hProcess, IntPtr hModule, Pointer<Utf16> lpFilename,
        Uint32 nSize),
    int Function(int hProcess, int hModule, Pointer<Utf16> lpFilename,
        int nSize)>('K32GetModuleFileNameExW');

/// Retrieves a module handle for the specified module. The module must have
/// been loaded by the calling process.
///
/// ```c
/// HMODULE GetModuleHandleW(
///   LPCWSTR lpModuleName
/// );
/// ```
/// {@category kernel32}
int GetModuleHandle(Pointer<Utf16> lpModuleName) =>
    _GetModuleHandle(lpModuleName);

final _GetModuleHandle = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpModuleName),
    int Function(Pointer<Utf16> lpModuleName)>('GetModuleHandleW');

/// Retrieves a module handle for the specified module and increments the
/// module's reference count unless
/// GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT is specified. The module
/// must have been loaded by the calling process.
///
/// ```c
/// BOOL GetModuleHandleExW(
///   [in]           DWORD   dwFlags,
///   [in, optional] LPCWSTR lpModuleName,
///   [out]          HMODULE *phModule
/// );
/// ```
/// {@category kernel32}
int GetModuleHandleEx(
        int dwFlags, Pointer<Utf16> lpModuleName, Pointer<IntPtr> phModule) =>
    _GetModuleHandleEx(dwFlags, lpModuleName, phModule);

final _GetModuleHandleEx = _kernel32.lookupFunction<
    Int32 Function(
        Uint32 dwFlags, Pointer<Utf16> lpModuleName, Pointer<IntPtr> phModule),
    int Function(int dwFlags, Pointer<Utf16> lpModuleName,
        Pointer<IntPtr> phModule)>('GetModuleHandleExW');

/// Retrieves the client computer name for the specified named pipe.
///
/// ```c
/// BOOL GetNamedPipeClientComputerNameW(
///   HANDLE Pipe,
///   LPWSTR ClientComputerName,
///   ULONG  ClientComputerNameLength
/// );
/// ```
/// {@category kernel32}
int GetNamedPipeClientComputerName(int Pipe, Pointer<Utf16> ClientComputerName,
        int ClientComputerNameLength) =>
    _GetNamedPipeClientComputerName(
        Pipe, ClientComputerName, ClientComputerNameLength);

final _GetNamedPipeClientComputerName = _kernel32.lookupFunction<
    Int32 Function(IntPtr Pipe, Pointer<Utf16> ClientComputerName,
        Uint32 ClientComputerNameLength),
    int Function(int Pipe, Pointer<Utf16> ClientComputerName,
        int ClientComputerNameLength)>('GetNamedPipeClientComputerNameW');

/// Retrieves the client process identifier for the specified named pipe.
///
/// ```c
/// BOOL GetNamedPipeClientProcessId(
///   HANDLE Pipe,
///   PULONG ClientProcessId
/// );
/// ```
/// {@category kernel32}
int GetNamedPipeClientProcessId(int Pipe, Pointer<Uint32> ClientProcessId) =>
    _GetNamedPipeClientProcessId(Pipe, ClientProcessId);

final _GetNamedPipeClientProcessId = _kernel32.lookupFunction<
    Int32 Function(IntPtr Pipe, Pointer<Uint32> ClientProcessId),
    int Function(int Pipe,
        Pointer<Uint32> ClientProcessId)>('GetNamedPipeClientProcessId');

/// Retrieves the client process identifier for the specified named pipe.
///
/// ```c
/// BOOL GetNamedPipeClientSessionId(
///   HANDLE Pipe,
///   PULONG ClientSessionId
/// );
/// ```
/// {@category kernel32}
int GetNamedPipeClientSessionId(int Pipe, Pointer<Uint32> ClientSessionId) =>
    _GetNamedPipeClientSessionId(Pipe, ClientSessionId);

final _GetNamedPipeClientSessionId = _kernel32.lookupFunction<
    Int32 Function(IntPtr Pipe, Pointer<Uint32> ClientSessionId),
    int Function(int Pipe,
        Pointer<Uint32> ClientSessionId)>('GetNamedPipeClientSessionId');

/// Retrieves information about a specified named pipe. The information
/// returned can vary during the lifetime of an instance of the named pipe.
///
/// ```c
/// BOOL GetNamedPipeHandleStateW(
///   HANDLE  hNamedPipe,
///   LPDWORD lpState,
///   LPDWORD lpCurInstances,
///   LPDWORD lpMaxCollectionCount,
///   LPDWORD lpCollectDataTimeout,
///   LPWSTR  lpUserName,
///   DWORD   nMaxUserNameSize
/// );
/// ```
/// {@category kernel32}
int GetNamedPipeHandleState(
        int hNamedPipe,
        Pointer<Uint32> lpState,
        Pointer<Uint32> lpCurInstances,
        Pointer<Uint32> lpMaxCollectionCount,
        Pointer<Uint32> lpCollectDataTimeout,
        Pointer<Utf16> lpUserName,
        int nMaxUserNameSize) =>
    _GetNamedPipeHandleState(
        hNamedPipe,
        lpState,
        lpCurInstances,
        lpMaxCollectionCount,
        lpCollectDataTimeout,
        lpUserName,
        nMaxUserNameSize);

final _GetNamedPipeHandleState = _kernel32.lookupFunction<
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

/// Retrieves information about the specified named pipe.
///
/// ```c
/// BOOL GetNamedPipeInfo(
///   HANDLE  hNamedPipe,
///   LPDWORD lpFlags,
///   LPDWORD lpOutBufferSize,
///   LPDWORD lpInBufferSize,
///   LPDWORD lpMaxInstances);
/// ```
/// {@category kernel32}
int GetNamedPipeInfo(
        int hNamedPipe,
        Pointer<Uint32> lpFlags,
        Pointer<Uint32> lpOutBufferSize,
        Pointer<Uint32> lpInBufferSize,
        Pointer<Uint32> lpMaxInstances) =>
    _GetNamedPipeInfo(
        hNamedPipe, lpFlags, lpOutBufferSize, lpInBufferSize, lpMaxInstances);

final _GetNamedPipeInfo = _kernel32.lookupFunction<
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

/// Retrieves information about the current system to an application running
/// under WOW64. If the function is called from a 64-bit application, or on
/// a 64-bit system that does not have an Intel64 or x64 processor (such as
/// ARM64), it is equivalent to the GetSystemInfo function.
///
/// ```c
/// void GetNativeSystemInfo(
///   LPSYSTEM_INFO lpSystemInfo
/// );
/// ```
/// {@category kernel32}
void GetNativeSystemInfo(Pointer<SYSTEM_INFO> lpSystemInfo) =>
    _GetNativeSystemInfo(lpSystemInfo);

final _GetNativeSystemInfo = _kernel32.lookupFunction<
    Void Function(Pointer<SYSTEM_INFO> lpSystemInfo),
    void Function(Pointer<SYSTEM_INFO> lpSystemInfo)>('GetNativeSystemInfo');

/// Retrieves the number of unread input records in the console's input
/// buffer.
///
/// ```c
/// BOOL GetNumberOfConsoleInputEvents(
///   HANDLE hConsoleInput,
///   LPDWORD lpcNumberOfEvents
/// );
/// ```
/// {@category kernel32}
int GetNumberOfConsoleInputEvents(
        int hConsoleInput, Pointer<Uint32> lpNumberOfEvents) =>
    _GetNumberOfConsoleInputEvents(hConsoleInput, lpNumberOfEvents);

final _GetNumberOfConsoleInputEvents = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleInput, Pointer<Uint32> lpNumberOfEvents),
    int Function(int hConsoleInput,
        Pointer<Uint32> lpNumberOfEvents)>('GetNumberOfConsoleInputEvents');

/// Retrieves the results of an overlapped operation on the specified file,
/// named pipe, or communications device. To specify a timeout interval or
/// wait on an alertable thread, use GetOverlappedResultEx.
///
/// ```c
/// BOOL GetOverlappedResult(
///   HANDLE       hFile,
///   LPOVERLAPPED lpOverlapped,
///   LPDWORD      lpNumberOfBytesTransferred,
///   BOOL         bWait
/// );
/// ```
/// {@category kernel32}
int GetOverlappedResult(int hFile, Pointer<OVERLAPPED> lpOverlapped,
        Pointer<Uint32> lpNumberOfBytesTransferred, int bWait) =>
    _GetOverlappedResult(
        hFile, lpOverlapped, lpNumberOfBytesTransferred, bWait);

final _GetOverlappedResult = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<OVERLAPPED> lpOverlapped,
        Pointer<Uint32> lpNumberOfBytesTransferred, Int32 bWait),
    int Function(
        int hFile,
        Pointer<OVERLAPPED> lpOverlapped,
        Pointer<Uint32> lpNumberOfBytesTransferred,
        int bWait)>('GetOverlappedResult');

/// Retrieves the results of an overlapped operation on the specified file,
/// named pipe, or communications device within the specified time-out
/// interval. The calling thread can perform an alertable wait.
///
/// ```c
/// BOOL GetOverlappedResultEx(
///   HANDLE       hFile,
///   LPOVERLAPPED lpOverlapped,
///   LPDWORD      lpNumberOfBytesTransferred,
///   DWORD        dwMilliseconds,
///   BOOL         bAlertable
/// );
/// ```
/// {@category kernel32}
int GetOverlappedResultEx(
        int hFile,
        Pointer<OVERLAPPED> lpOverlapped,
        Pointer<Uint32> lpNumberOfBytesTransferred,
        int dwMilliseconds,
        int bAlertable) =>
    _GetOverlappedResultEx(hFile, lpOverlapped, lpNumberOfBytesTransferred,
        dwMilliseconds, bAlertable);

final _GetOverlappedResultEx = _kernel32.lookupFunction<
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

/// Retrieves the amount of RAM that is physically installed on the
/// computer.
///
/// ```c
/// BOOL GetPhysicallyInstalledSystemMemory(
///   PULONGLONG TotalMemoryInKilobytes
/// );
/// ```
/// {@category kernel32}
int GetPhysicallyInstalledSystemMemory(
        Pointer<Uint64> TotalMemoryInKilobytes) =>
    _GetPhysicallyInstalledSystemMemory(TotalMemoryInKilobytes);

final _GetPhysicallyInstalledSystemMemory = _kernel32.lookupFunction<
        Int32 Function(Pointer<Uint64> TotalMemoryInKilobytes),
        int Function(Pointer<Uint64> TotalMemoryInKilobytes)>(
    'GetPhysicallyInstalledSystemMemory');

/// Retrieves the address of an exported function or variable from the
/// specified dynamic-link library (DLL).
///
/// ```c
/// FARPROC GetProcAddress(
///   HMODULE hModule,
///   LPCSTR  lpProcName
/// );
/// ```
/// {@category kernel32}
Pointer GetProcAddress(int hModule, Pointer<Utf8> lpProcName) =>
    _GetProcAddress(hModule, lpProcName);

final _GetProcAddress = _kernel32.lookupFunction<
    Pointer Function(IntPtr hModule, Pointer<Utf8> lpProcName),
    Pointer Function(int hModule, Pointer<Utf8> lpProcName)>('GetProcAddress');

/// Retrieves a handle to the default heap of the calling process. This
/// handle can then be used in subsequent calls to the heap functions.
///
/// ```c
/// HANDLE GetProcessHeap();
/// ```
/// {@category kernel32}
int GetProcessHeap() => _GetProcessHeap();

final _GetProcessHeap = _kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetProcessHeap');

/// Returns the number of active heaps and retrieves handles to all of the
/// active heaps for the calling process.
///
/// ```c
/// DWORD GetProcessHeaps(
///   DWORD   NumberOfHeaps,
///   PHANDLE ProcessHeaps
/// );
/// ```
/// {@category kernel32}
int GetProcessHeaps(int NumberOfHeaps, Pointer<IntPtr> ProcessHeaps) =>
    _GetProcessHeaps(NumberOfHeaps, ProcessHeaps);

final _GetProcessHeaps = _kernel32.lookupFunction<
    Uint32 Function(Uint32 NumberOfHeaps, Pointer<IntPtr> ProcessHeaps),
    int Function(
        int NumberOfHeaps, Pointer<IntPtr> ProcessHeaps)>('GetProcessHeaps');

/// Retrieves the process identifier of the specified process.
///
/// ```c
/// DWORD GetProcessId(
///   HANDLE Process
/// );
/// ```
/// {@category kernel32}
int GetProcessId(int Process) => _GetProcessId(Process);

final _GetProcessId = _kernel32.lookupFunction<Uint32 Function(IntPtr Process),
    int Function(int Process)>('GetProcessId');

/// Retrieves the shutdown parameters for the currently calling process.
///
/// ```c
/// BOOL GetProcessShutdownParameters(
///   LPDWORD lpdwLevel,
///   LPDWORD lpdwFlags
/// );
/// ```
/// {@category kernel32}
int GetProcessShutdownParameters(
        Pointer<Uint32> lpdwLevel, Pointer<Uint32> lpdwFlags) =>
    _GetProcessShutdownParameters(lpdwLevel, lpdwFlags);

final _GetProcessShutdownParameters = _kernel32.lookupFunction<
    Int32 Function(Pointer<Uint32> lpdwLevel, Pointer<Uint32> lpdwFlags),
    int Function(Pointer<Uint32> lpdwLevel,
        Pointer<Uint32> lpdwFlags)>('GetProcessShutdownParameters');

/// Retrieves timing information for the specified process.
///
/// ```c
/// BOOL GetProcessTimes(
///   HANDLE hProcess,
///   LPFILETIME lpCreationTime,
///   LPFILETIME lpExitTime,
///   LPFILETIME lpKernelTime,
///   LPFILETIME lpUserTime
/// );
/// ```
/// {@category kernel32}
int GetProcessTimes(
        int hProcess,
        Pointer<FILETIME> lpCreationTime,
        Pointer<FILETIME> lpExitTime,
        Pointer<FILETIME> lpKernelTime,
        Pointer<FILETIME> lpUserTime) =>
    _GetProcessTimes(
        hProcess, lpCreationTime, lpExitTime, lpKernelTime, lpUserTime);

final _GetProcessTimes = _kernel32.lookupFunction<
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

/// Retrieves the major and minor version numbers of the system on which the
/// specified process expects to run.
///
/// ```c
/// DWORD GetProcessVersion(
///   DWORD ProcessId
/// );
/// ```
/// {@category kernel32}
int GetProcessVersion(int ProcessId) => _GetProcessVersion(ProcessId);

final _GetProcessVersion = _kernel32.lookupFunction<
    Uint32 Function(Uint32 ProcessId),
    int Function(int ProcessId)>('GetProcessVersion');

/// Retrieves the minimum and maximum working set sizes of the specified
/// process.
///
/// ```c
/// BOOL GetProcessWorkingSetSize(
///   HANDLE  hProcess,
///   PSIZE_T lpMinimumWorkingSetSize,
///   PSIZE_T lpMaximumWorkingSetSize
/// );
/// ```
/// {@category kernel32}
int GetProcessWorkingSetSize(
        int hProcess,
        Pointer<IntPtr> lpMinimumWorkingSetSize,
        Pointer<IntPtr> lpMaximumWorkingSetSize) =>
    _GetProcessWorkingSetSize(
        hProcess, lpMinimumWorkingSetSize, lpMaximumWorkingSetSize);

final _GetProcessWorkingSetSize = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<IntPtr> lpMinimumWorkingSetSize,
        Pointer<IntPtr> lpMaximumWorkingSetSize),
    int Function(int hProcess, Pointer<IntPtr> lpMinimumWorkingSetSize,
        Pointer<IntPtr> lpMaximumWorkingSetSize)>('GetProcessWorkingSetSize');

/// Retrieves the product type for the operating system on the local
/// computer, and maps the type to the product types supported by the
/// specified operating system.
///
/// ```c
/// BOOL GetProductInfo(
///   DWORD  dwOSMajorVersion,
///   DWORD  dwOSMinorVersion,
///   DWORD  dwSpMajorVersion,
///   DWORD  dwSpMinorVersion,
///   PDWORD pdwReturnedProductType
/// );
/// ```
/// {@category kernel32}
int GetProductInfo(
        int dwOSMajorVersion,
        int dwOSMinorVersion,
        int dwSpMajorVersion,
        int dwSpMinorVersion,
        Pointer<Uint32> pdwReturnedProductType) =>
    _GetProductInfo(dwOSMajorVersion, dwOSMinorVersion, dwSpMajorVersion,
        dwSpMinorVersion, pdwReturnedProductType);

final _GetProductInfo = _kernel32.lookupFunction<
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

/// Attempts to dequeue an I/O completion packet from the specified I/O
/// completion port. If there is no completion packet queued, the function
/// waits for a pending I/O operation associated with the completion port to
/// complete.
///
/// ```c
/// BOOL GetQueuedCompletionStatus(
///   HANDLE       CompletionPort,
///   LPDWORD      lpNumberOfBytesTransferred,
///   PULONG_PTR   lpCompletionKey,
///   LPOVERLAPPED *lpOverlapped,
///   DWORD        dwMilliseconds
/// );
/// ```
/// {@category kernel32}
int GetQueuedCompletionStatus(
        int CompletionPort,
        Pointer<Uint32> lpNumberOfBytesTransferred,
        Pointer<IntPtr> lpCompletionKey,
        Pointer<Pointer<OVERLAPPED>> lpOverlapped,
        int dwMilliseconds) =>
    _GetQueuedCompletionStatus(CompletionPort, lpNumberOfBytesTransferred,
        lpCompletionKey, lpOverlapped, dwMilliseconds);

final _GetQueuedCompletionStatus = _kernel32.lookupFunction<
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

/// Retrieves multiple completion port entries simultaneously. It waits for
/// pending I/O operations that are associated with the specified completion
/// port to complete.
///
/// ```c
/// BOOL GetQueuedCompletionStatusEx(
///   HANDLE             CompletionPort,
///   LPOVERLAPPED_ENTRY lpCompletionPortEntries,
///   ULONG              ulCount,
///   PULONG             ulNumEntriesRemoved,
///   DWORD              dwMilliseconds,
///   BOOL               fAlertable
/// );
/// ```
/// {@category kernel32}
int GetQueuedCompletionStatusEx(
        int CompletionPort,
        Pointer<OVERLAPPED_ENTRY> lpCompletionPortEntries,
        int ulCount,
        Pointer<Uint32> ulNumEntriesRemoved,
        int dwMilliseconds,
        int fAlertable) =>
    _GetQueuedCompletionStatusEx(CompletionPort, lpCompletionPortEntries,
        ulCount, ulNumEntriesRemoved, dwMilliseconds, fAlertable);

final _GetQueuedCompletionStatusEx = _kernel32.lookupFunction<
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

/// Retrieves the short path form of the specified path.
///
/// ```c
/// DWORD GetShortPathNameW(
///   [in]  LPCWSTR lpszLongPath,
///   [out] LPWSTR  lpszShortPath,
///   [in]  DWORD   cchBuffer
/// );
/// ```
/// {@category kernel32}
int GetShortPathName(Pointer<Utf16> lpszLongPath, Pointer<Utf16> lpszShortPath,
        int cchBuffer) =>
    _GetShortPathName(lpszLongPath, lpszShortPath, cchBuffer);

final _GetShortPathName = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpszLongPath, Pointer<Utf16> lpszShortPath,
        Uint32 cchBuffer),
    int Function(Pointer<Utf16> lpszLongPath, Pointer<Utf16> lpszShortPath,
        int cchBuffer)>('GetShortPathNameW');

/// Retrieves the contents of the STARTUPINFO structure that was specified
/// when the calling process was created.
///
/// ```c
/// void GetStartupInfoW(
///   LPSTARTUPINFOW lpStartupInfo
/// );
/// ```
/// {@category kernel32}
void GetStartupInfo(Pointer<STARTUPINFO> lpStartupInfo) =>
    _GetStartupInfo(lpStartupInfo);

final _GetStartupInfo = _kernel32.lookupFunction<
    Void Function(Pointer<STARTUPINFO> lpStartupInfo),
    void Function(Pointer<STARTUPINFO> lpStartupInfo)>('GetStartupInfoW');

/// Retrieves a handle to the specified standard device (standard input,
/// standard output, or standard error).
///
/// ```c
/// HANDLE GetStdHandle(
///   _In_ DWORD nStdHandle
/// );
/// ```
/// {@category kernel32}
int GetStdHandle(int nStdHandle) => _GetStdHandle(nStdHandle);

final _GetStdHandle = _kernel32.lookupFunction<
    IntPtr Function(Uint32 nStdHandle),
    int Function(int nStdHandle)>('GetStdHandle');

/// Returns the language identifier for the system locale.
///
/// ```c
/// LANGID GetSystemDefaultLangID();
/// ```
/// {@category kernel32}
int GetSystemDefaultLangID() => _GetSystemDefaultLangID();

final _GetSystemDefaultLangID =
    _kernel32.lookupFunction<Uint16 Function(), int Function()>(
        'GetSystemDefaultLangID');

/// Retrieves the system default locale name.
///
/// ```c
/// int GetSystemDefaultLocaleName(
///   LPWSTR lpLocaleName,
///   int    cchLocaleName
/// );
/// ```
/// {@category kernel32}
int GetSystemDefaultLocaleName(
        Pointer<Utf16> lpLocaleName, int cchLocaleName) =>
    _GetSystemDefaultLocaleName(lpLocaleName, cchLocaleName);

final _GetSystemDefaultLocaleName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpLocaleName, Int32 cchLocaleName),
    int Function(Pointer<Utf16> lpLocaleName,
        int cchLocaleName)>('GetSystemDefaultLocaleName');

/// Retrieves the path of the system directory. The system directory
/// contains system files such as dynamic-link libraries and drivers.
///
/// ```c
/// UINT GetSystemDirectoryW(
///   LPWSTR lpBuffer,
///   UINT   uSize
/// );
/// ```
/// {@category kernel32}
int GetSystemDirectory(Pointer<Utf16> lpBuffer, int uSize) =>
    _GetSystemDirectory(lpBuffer, uSize);

final _GetSystemDirectory = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpBuffer, Uint32 uSize),
    int Function(Pointer<Utf16> lpBuffer, int uSize)>('GetSystemDirectoryW');

/// Retrieves information about the current system. To retrieve accurate
/// information for an application running on WOW64, call the
/// GetNativeSystemInfo function.
///
/// ```c
/// void GetSystemInfo(
///   LPSYSTEM_INFO lpSystemInfo
/// );
/// ```
/// {@category kernel32}
void GetSystemInfo(Pointer<SYSTEM_INFO> lpSystemInfo) =>
    _GetSystemInfo(lpSystemInfo);

final _GetSystemInfo = _kernel32.lookupFunction<
    Void Function(Pointer<SYSTEM_INFO> lpSystemInfo),
    void Function(Pointer<SYSTEM_INFO> lpSystemInfo)>('GetSystemInfo');

/// Retrieves the power status of the system. The status indicates whether
/// the system is running on AC or DC power, whether the battery is
/// currently charging, how much battery life remains, and if battery saver
/// is on or off.
///
/// ```c
/// BOOL GetSystemPowerStatus(
///   LPSYSTEM_POWER_STATUS lpSystemPowerStatus
/// );
/// ```
/// {@category kernel32}
int GetSystemPowerStatus(Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus) =>
    _GetSystemPowerStatus(lpSystemPowerStatus);

final _GetSystemPowerStatus = _kernel32.lookupFunction<
        Int32 Function(Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus),
        int Function(Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus)>(
    'GetSystemPowerStatus');

/// Retrieves the current local date and time.
///
/// ```c
/// void GetSystemTime(
///   LPSYSTEMTIME lpSystemTime
/// );
/// ```
/// {@category kernel32}
void GetSystemTime(Pointer<SYSTEMTIME> lpSystemTime) =>
    _GetSystemTime(lpSystemTime);

final _GetSystemTime = _kernel32.lookupFunction<
    Void Function(Pointer<SYSTEMTIME> lpSystemTime),
    void Function(Pointer<SYSTEMTIME> lpSystemTime)>('GetSystemTime');

/// Retrieves system timing information. On a multiprocessor system, the
/// values returned are the sum of the designated times across all
/// processors.
///
/// ```c
/// BOOL GetSystemTimes(
///   PFILETIME lpIdleTime,
///   PFILETIME lpKernelTime,
///   PFILETIME lpUserTime
/// );
/// ```
/// {@category kernel32}
int GetSystemTimes(Pointer<FILETIME> lpIdleTime, Pointer<FILETIME> lpKernelTime,
        Pointer<FILETIME> lpUserTime) =>
    _GetSystemTimes(lpIdleTime, lpKernelTime, lpUserTime);

final _GetSystemTimes = _kernel32.lookupFunction<
    Int32 Function(Pointer<FILETIME> lpIdleTime, Pointer<FILETIME> lpKernelTime,
        Pointer<FILETIME> lpUserTime),
    int Function(Pointer<FILETIME> lpIdleTime, Pointer<FILETIME> lpKernelTime,
        Pointer<FILETIME> lpUserTime)>('GetSystemTimes');

/// Creates a name for a temporary file. If a unique file name is generated,
/// an empty file is created and the handle to it is released; otherwise,
/// only a file name is generated.
///
/// ```c
/// UINT GetTempFileNameW(
///   [in]  LPCWSTR lpPathName,
///   [in]  LPCWSTR lpPrefixString,
///   [in]  UINT    uUnique,
///   [out] LPWSTR  lpTempFileName
/// );
/// ```
/// {@category kernel32}
int GetTempFileName(Pointer<Utf16> lpPathName, Pointer<Utf16> lpPrefixString,
        int uUnique, Pointer<Utf16> lpTempFileName) =>
    _GetTempFileName(lpPathName, lpPrefixString, uUnique, lpTempFileName);

final _GetTempFileName = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpPathName, Pointer<Utf16> lpPrefixString,
        Uint32 uUnique, Pointer<Utf16> lpTempFileName),
    int Function(Pointer<Utf16> lpPathName, Pointer<Utf16> lpPrefixString,
        int uUnique, Pointer<Utf16> lpTempFileName)>('GetTempFileNameW');

/// Retrieves the path of the directory designated for temporary files.
///
/// ```c
/// DWORD GetTempPathW(
///   DWORD  nBufferLength,
///   LPWSTR lpBuffer
/// );
/// ```
/// {@category kernel32}
int GetTempPath(int nBufferLength, Pointer<Utf16> lpBuffer) =>
    _GetTempPath(nBufferLength, lpBuffer);

final _GetTempPath = _kernel32.lookupFunction<
    Uint32 Function(Uint32 nBufferLength, Pointer<Utf16> lpBuffer),
    int Function(int nBufferLength, Pointer<Utf16> lpBuffer)>('GetTempPathW');

/// Retrieves the path of the directory designated for temporary files,
/// based on the privileges of the calling process.
///
/// ```c
/// DWORD GetTempPath2W(
///   [in]  DWORD  BufferLength,
///   [out] LPWSTR Buffer
/// );
/// ```
/// {@category kernel32}
int GetTempPath2(int BufferLength, Pointer<Utf16> Buffer) =>
    _GetTempPath2(BufferLength, Buffer);

final _GetTempPath2 = _kernel32.lookupFunction<
    Uint32 Function(Uint32 BufferLength, Pointer<Utf16> Buffer),
    int Function(int BufferLength, Pointer<Utf16> Buffer)>('GetTempPath2W');

/// Retrieves the thread identifier of the specified thread.
///
/// ```c
/// DWORD GetThreadId(
///   HANDLE Thread
/// );
/// ```
/// {@category kernel32}
int GetThreadId(int Thread) => _GetThreadId(Thread);

final _GetThreadId = _kernel32.lookupFunction<Uint32 Function(IntPtr Thread),
    int Function(int Thread)>('GetThreadId');

/// Returns the locale identifier of the current locale for the calling
/// thread.
///
/// ```c
/// LCID GetThreadLocale();
/// ```
/// {@category kernel32}
int GetThreadLocale() => _GetThreadLocale();

final _GetThreadLocale = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetThreadLocale');

/// Retrieves timing information for the specified thread.
///
/// ```c
/// BOOL GetThreadTimes(
///   HANDLE     hThread,
///   LPFILETIME lpCreationTime,
///   LPFILETIME lpExitTime,
///   LPFILETIME lpKernelTime,
///   LPFILETIME lpUserTime
/// );
/// ```
/// {@category kernel32}
int GetThreadTimes(
        int hThread,
        Pointer<FILETIME> lpCreationTime,
        Pointer<FILETIME> lpExitTime,
        Pointer<FILETIME> lpKernelTime,
        Pointer<FILETIME> lpUserTime) =>
    _GetThreadTimes(
        hThread, lpCreationTime, lpExitTime, lpKernelTime, lpUserTime);

final _GetThreadTimes = _kernel32.lookupFunction<
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

/// Returns the language identifier of the first user interface language for
/// the current thread.
///
/// ```c
/// LANGID GetThreadUILanguage();
/// ```
/// {@category kernel32}
int GetThreadUILanguage() => _GetThreadUILanguage();

final _GetThreadUILanguage = _kernel32
    .lookupFunction<Uint16 Function(), int Function()>('GetThreadUILanguage');

/// Returns the language identifier of the Region Format setting for the
/// current user.
///
/// ```c
/// LANGID GetUserDefaultLangID();
/// ```
/// {@category kernel32}
int GetUserDefaultLangID() => _GetUserDefaultLangID();

final _GetUserDefaultLangID = _kernel32
    .lookupFunction<Uint16 Function(), int Function()>('GetUserDefaultLangID');

/// Returns the locale identifier for the user default locale.
///
/// ```c
/// LCID GetUserDefaultLCID();
/// ```
/// {@category kernel32}
int GetUserDefaultLCID() => _GetUserDefaultLCID();

final _GetUserDefaultLCID = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetUserDefaultLCID');

/// Retrieves the user default locale name.
///
/// ```c
/// int GetUserDefaultLocaleName(
///   LPWSTR lpLocaleName,
///   int    cchLocaleName
/// );
/// ```
/// {@category kernel32}
int GetUserDefaultLocaleName(Pointer<Utf16> lpLocaleName, int cchLocaleName) =>
    _GetUserDefaultLocaleName(lpLocaleName, cchLocaleName);

final _GetUserDefaultLocaleName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpLocaleName, Int32 cchLocaleName),
    int Function(Pointer<Utf16> lpLocaleName,
        int cchLocaleName)>('GetUserDefaultLocaleName');

/// Gets information about the operating system version.
///
/// ```c
/// BOOL GetVersionExW(
///   LPOSVERSIONINFOW lpVersionInformation
/// );
/// ```
/// {@category kernel32}
int GetVersionEx(Pointer<OSVERSIONINFO> lpVersionInformation) =>
    _GetVersionEx(lpVersionInformation);

final _GetVersionEx = _kernel32.lookupFunction<
    Int32 Function(Pointer<OSVERSIONINFO> lpVersionInformation),
    int Function(Pointer<OSVERSIONINFO> lpVersionInformation)>('GetVersionExW');

/// Retrieves information about the file system and volume associated with
/// the specified root directory.
///
/// ```c
/// BOOL GetVolumeInformationW(
///   LPCWSTR lpRootPathName,
///   LPWSTR  lpVolumeNameBuffer,
///   DWORD   nVolumeNameSize,
///   LPDWORD lpVolumeSerialNumber,
///   LPDWORD lpMaximumComponentLength,
///   LPDWORD lpFileSystemFlags,
///   LPWSTR  lpFileSystemNameBuffer,
///   DWORD   nFileSystemNameSize
/// );
/// ```
/// {@category kernel32}
int GetVolumeInformation(
        Pointer<Utf16> lpRootPathName,
        Pointer<Utf16> lpVolumeNameBuffer,
        int nVolumeNameSize,
        Pointer<Uint32> lpVolumeSerialNumber,
        Pointer<Uint32> lpMaximumComponentLength,
        Pointer<Uint32> lpFileSystemFlags,
        Pointer<Utf16> lpFileSystemNameBuffer,
        int nFileSystemNameSize) =>
    _GetVolumeInformation(
        lpRootPathName,
        lpVolumeNameBuffer,
        nVolumeNameSize,
        lpVolumeSerialNumber,
        lpMaximumComponentLength,
        lpFileSystemFlags,
        lpFileSystemNameBuffer,
        nFileSystemNameSize);

final _GetVolumeInformation = _kernel32.lookupFunction<
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

/// Retrieves information about the file system and volume associated with
/// the specified file.
///
/// ```c
/// BOOL GetVolumeInformationByHandleW(
///   HANDLE  hFile,
///   LPWSTR  lpVolumeNameBuffer,
///   DWORD   nVolumeNameSize,
///   LPDWORD lpVolumeSerialNumber,
///   LPDWORD lpMaximumComponentLength,
///   LPDWORD lpFileSystemFlags,
///   LPWSTR  lpFileSystemNameBuffer,
///   DWORD   nFileSystemNameSize
/// );
/// ```
/// {@category kernel32}
int GetVolumeInformationByHandle(
        int hFile,
        Pointer<Utf16> lpVolumeNameBuffer,
        int nVolumeNameSize,
        Pointer<Uint32> lpVolumeSerialNumber,
        Pointer<Uint32> lpMaximumComponentLength,
        Pointer<Uint32> lpFileSystemFlags,
        Pointer<Utf16> lpFileSystemNameBuffer,
        int nFileSystemNameSize) =>
    _GetVolumeInformationByHandle(
        hFile,
        lpVolumeNameBuffer,
        nVolumeNameSize,
        lpVolumeSerialNumber,
        lpMaximumComponentLength,
        lpFileSystemFlags,
        lpFileSystemNameBuffer,
        nFileSystemNameSize);

final _GetVolumeInformationByHandle = _kernel32.lookupFunction<
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

/// Retrieves a volume GUID path for the volume that is associated with the
/// specified volume mount point (drive letter, volume GUID path, or mounted
/// folder).
///
/// ```c
/// BOOL GetVolumeNameForVolumeMountPointW(
///   [in]  LPCWSTR lpszVolumeMountPoint,
///   [out] LPWSTR  lpszVolumeName,
///   [in]  DWORD   cchBufferLength
/// );
/// ```
/// {@category kernel32}
int GetVolumeNameForVolumeMountPoint(Pointer<Utf16> lpszVolumeMountPoint,
        Pointer<Utf16> lpszVolumeName, int cchBufferLength) =>
    _GetVolumeNameForVolumeMountPoint(
        lpszVolumeMountPoint, lpszVolumeName, cchBufferLength);

final _GetVolumeNameForVolumeMountPoint = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpszVolumeMountPoint,
        Pointer<Utf16> lpszVolumeName, Uint32 cchBufferLength),
    int Function(
        Pointer<Utf16> lpszVolumeMountPoint,
        Pointer<Utf16> lpszVolumeName,
        int cchBufferLength)>('GetVolumeNameForVolumeMountPointW');

/// Retrieves the volume mount point where the specified path is mounted.
///
/// ```c
/// BOOL GetVolumePathNameW(
///   LPCWSTR lpszFileName,
///   LPWSTR  lpszVolumePathName,
///   DWORD   cchBufferLength);
/// ```
/// {@category kernel32}
int GetVolumePathName(Pointer<Utf16> lpszFileName,
        Pointer<Utf16> lpszVolumePathName, int cchBufferLength) =>
    _GetVolumePathName(lpszFileName, lpszVolumePathName, cchBufferLength);

final _GetVolumePathName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpszFileName,
        Pointer<Utf16> lpszVolumePathName, Uint32 cchBufferLength),
    int Function(Pointer<Utf16> lpszFileName, Pointer<Utf16> lpszVolumePathName,
        int cchBufferLength)>('GetVolumePathNameW');

/// Retrieves a list of drive letters and mounted folder paths for the
/// specified volume.
///
/// ```c
/// BOOL GetVolumePathNamesForVolumeNameW(
///   LPCWSTR lpszVolumeName,
///   LPWCH   lpszVolumePathNames,
///   DWORD   cchBufferLength,
///   PDWORD  lpcchReturnLength
/// );
/// ```
/// {@category kernel32}
int GetVolumePathNamesForVolumeName(
        Pointer<Utf16> lpszVolumeName,
        Pointer<Utf16> lpszVolumePathNames,
        int cchBufferLength,
        Pointer<Uint32> lpcchReturnLength) =>
    _GetVolumePathNamesForVolumeName(lpszVolumeName, lpszVolumePathNames,
        cchBufferLength, lpcchReturnLength);

final _GetVolumePathNamesForVolumeName = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpszVolumeName,
        Pointer<Utf16> lpszVolumePathNames,
        Uint32 cchBufferLength,
        Pointer<Uint32> lpcchReturnLength),
    int Function(
        Pointer<Utf16> lpszVolumeName,
        Pointer<Utf16> lpszVolumePathNames,
        int cchBufferLength,
        Pointer<Uint32> lpcchReturnLength)>('GetVolumePathNamesForVolumeNameW');

/// Allocates the specified number of bytes from the heap.
///
/// ```c
/// HGLOBAL GlobalAlloc(
///   UINT   uFlags,
///   SIZE_T dwBytes
/// );
/// ```
/// {@category kernel32}
int GlobalAlloc(int uFlags, int dwBytes) => _GlobalAlloc(uFlags, dwBytes);

final _GlobalAlloc = _kernel32.lookupFunction<
    IntPtr Function(Uint32 uFlags, IntPtr dwBytes),
    int Function(int uFlags, int dwBytes)>('GlobalAlloc');

/// Frees the specified global memory object and invalidates its handle.
///
/// ```c
/// HGLOBAL GlobalFree(
///   _Frees_ptr_opt_ HGLOBAL hMem
/// );
/// ```
/// {@category kernel32}
int GlobalFree(int hMem) => _GlobalFree(hMem);

final _GlobalFree = _kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
    int Function(int hMem)>('GlobalFree');

/// Locks a global memory object and returns a pointer to the first byte of
/// the object's memory block.
///
/// ```c
/// LPVOID GlobalLock(
///   HGLOBAL hMem
/// );
/// ```
/// {@category kernel32}
Pointer GlobalLock(int hMem) => _GlobalLock(hMem);

final _GlobalLock = _kernel32.lookupFunction<Pointer Function(IntPtr hMem),
    Pointer Function(int hMem)>('GlobalLock');

/// Retrieves the current size of the specified global memory object, in
/// bytes.
///
/// ```c
/// SIZE_T GlobalSize(
///   HGLOBAL hMem
/// );
/// ```
/// {@category kernel32}
int GlobalSize(int hMem) => _GlobalSize(hMem);

final _GlobalSize = _kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
    int Function(int hMem)>('GlobalSize');

/// Decrements the lock count associated with a memory object that was
/// allocated with GMEM_MOVEABLE. This function has no effect on memory
/// objects allocated with GMEM_FIXED.
///
/// ```c
/// BOOL GlobalUnlock(
///   HGLOBAL hMem
/// );
/// ```
/// {@category kernel32}
int GlobalUnlock(int hMem) => _GlobalUnlock(hMem);

final _GlobalUnlock = _kernel32.lookupFunction<Int32 Function(IntPtr hMem),
    int Function(int hMem)>('GlobalUnlock');

/// Allocates a block of memory from a heap. The allocated memory is not
/// movable.
///
/// ```c
/// LPVOID HeapAlloc(
///   HANDLE hHeap,
///   DWORD  dwFlags,
///   SIZE_T dwBytes
/// );
/// ```
/// {@category kernel32}
Pointer HeapAlloc(int hHeap, int dwFlags, int dwBytes) =>
    _HeapAlloc(hHeap, dwFlags, dwBytes);

final _HeapAlloc = _kernel32.lookupFunction<
    Pointer Function(IntPtr hHeap, Uint32 dwFlags, IntPtr dwBytes),
    Pointer Function(int hHeap, int dwFlags, int dwBytes)>('HeapAlloc');

/// Returns the size of the largest committed free block in the specified
/// heap. If the Disable heap coalesce on free global flag is set, this
/// function also coalesces adjacent free blocks of memory in the heap.
///
/// ```c
/// SIZE_T HeapCompact(
///   HANDLE hHeap,
///   DWORD  dwFlags
/// );
/// ```
/// {@category kernel32}
int HeapCompact(int hHeap, int dwFlags) => _HeapCompact(hHeap, dwFlags);

final _HeapCompact = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hHeap, Uint32 dwFlags),
    int Function(int hHeap, int dwFlags)>('HeapCompact');

/// Creates a private heap object that can be used by the calling process.
/// The function reserves space in the virtual address space of the process
/// and allocates physical storage for a specified initial portion of this
/// block.
///
/// ```c
/// HANDLE HeapCreate(
///   DWORD  flOptions,
///   SIZE_T dwInitialSize,
///   SIZE_T dwMaximumSize
/// );
/// ```
/// {@category kernel32}
int HeapCreate(int flOptions, int dwInitialSize, int dwMaximumSize) =>
    _HeapCreate(flOptions, dwInitialSize, dwMaximumSize);

final _HeapCreate = _kernel32.lookupFunction<
    IntPtr Function(
        Uint32 flOptions, IntPtr dwInitialSize, IntPtr dwMaximumSize),
    int Function(
        int flOptions, int dwInitialSize, int dwMaximumSize)>('HeapCreate');

/// Destroys the specified heap object. It decommits and releases all the
/// pages of a private heap object, and it invalidates the handle to the
/// heap.
///
/// ```c
/// BOOL HeapDestroy(
///   HANDLE hHeap
/// );
/// ```
/// {@category kernel32}
int HeapDestroy(int hHeap) => _HeapDestroy(hHeap);

final _HeapDestroy = _kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
    int Function(int hHeap)>('HeapDestroy');

/// Frees a memory block allocated from a heap by the HeapAlloc or
/// HeapReAlloc function.
///
/// ```c
/// BOOL HeapFree(
///   HANDLE                 hHeap,
///   DWORD                  dwFlags,
///   _Frees_ptr_opt_ LPVOID lpMem
/// );
/// ```
/// {@category kernel32}
int HeapFree(int hHeap, int dwFlags, Pointer lpMem) =>
    _HeapFree(hHeap, dwFlags, lpMem);

final _HeapFree = _kernel32.lookupFunction<
    Int32 Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
    int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapFree');

/// Attempts to acquire the critical section object, or lock, that is
/// associated with a specified heap.
///
/// ```c
/// BOOL HeapLock(
///   HANDLE hHeap
/// );
/// ```
/// {@category kernel32}
int HeapLock(int hHeap) => _HeapLock(hHeap);

final _HeapLock = _kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
    int Function(int hHeap)>('HeapLock');

/// Retrieves information about the specified heap.
///
/// ```c
/// BOOL HeapQueryInformation(
///   HANDLE                 HeapHandle,
///   HEAP_INFORMATION_CLASS HeapInformationClass,
///   PVOID                  HeapInformation,
///   SIZE_T                 HeapInformationLength,
///   PSIZE_T                ReturnLength
/// );
/// ```
/// {@category kernel32}
int HeapQueryInformation(
        int HeapHandle,
        int HeapInformationClass,
        Pointer HeapInformation,
        int HeapInformationLength,
        Pointer<IntPtr> ReturnLength) =>
    _HeapQueryInformation(HeapHandle, HeapInformationClass, HeapInformation,
        HeapInformationLength, ReturnLength);

final _HeapQueryInformation = _kernel32.lookupFunction<
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

/// Retrieves information about the specified heap.
///
/// ```c
/// LPVOID HeapReAlloc(
///   HANDLE                 hHeap,
///   DWORD                  dwFlags,
///   _Frees_ptr_opt_ LPVOID lpMem,
///   SIZE_T                 dwBytes
/// );
/// ```
/// {@category kernel32}
Pointer HeapReAlloc(int hHeap, int dwFlags, Pointer lpMem, int dwBytes) =>
    _HeapReAlloc(hHeap, dwFlags, lpMem, dwBytes);

final _HeapReAlloc = _kernel32.lookupFunction<
    Pointer Function(
        IntPtr hHeap, Uint32 dwFlags, Pointer lpMem, IntPtr dwBytes),
    Pointer Function(
        int hHeap, int dwFlags, Pointer lpMem, int dwBytes)>('HeapReAlloc');

/// Enables features for a specified heap.
///
/// ```c
/// BOOL HeapSetInformation(
///   HANDLE                 HeapHandle,
///   HEAP_INFORMATION_CLASS HeapInformationClass,
///   PVOID                  HeapInformation,
///   SIZE_T                 HeapInformationLength
/// );
/// ```
/// {@category kernel32}
int HeapSetInformation(int HeapHandle, int HeapInformationClass,
        Pointer HeapInformation, int HeapInformationLength) =>
    _HeapSetInformation(HeapHandle, HeapInformationClass, HeapInformation,
        HeapInformationLength);

final _HeapSetInformation = _kernel32.lookupFunction<
    Int32 Function(IntPtr HeapHandle, Int32 HeapInformationClass,
        Pointer HeapInformation, IntPtr HeapInformationLength),
    int Function(
        int HeapHandle,
        int HeapInformationClass,
        Pointer HeapInformation,
        int HeapInformationLength)>('HeapSetInformation');

/// Retrieves the size of a memory block allocated from a heap by the
/// HeapAlloc or HeapReAlloc function.
///
/// ```c
/// SIZE_T HeapSize(
///   HANDLE  hHeap,
///   DWORD   dwFlags,
///   LPCVOID lpMem
/// );
/// ```
/// {@category kernel32}
int HeapSize(int hHeap, int dwFlags, Pointer lpMem) =>
    _HeapSize(hHeap, dwFlags, lpMem);

final _HeapSize = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
    int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapSize');

/// Releases ownership of the critical section object, or lock, that is
/// associated with a specified heap. It reverses the action of the HeapLock
/// function.
///
/// ```c
/// BOOL HeapUnlock(
///   HANDLE hHeap
/// );
/// ```
/// {@category kernel32}
int HeapUnlock(int hHeap) => _HeapUnlock(hHeap);

final _HeapUnlock = _kernel32.lookupFunction<Int32 Function(IntPtr hHeap),
    int Function(int hHeap)>('HeapUnlock');

/// Validates the specified heap. The function scans all the memory blocks
/// in the heap and verifies that the heap control structures maintained by
/// the heap manager are in a consistent state. You can also use the
/// HeapValidate function to validate a single memory block within a
/// specified heap without checking the validity of the entire heap.
///
/// ```c
/// BOOL HeapValidate(
///   HANDLE  hHeap,
///   DWORD   dwFlags,
///   LPCVOID lpMem
/// );
/// ```
/// {@category kernel32}
int HeapValidate(int hHeap, int dwFlags, Pointer lpMem) =>
    _HeapValidate(hHeap, dwFlags, lpMem);

final _HeapValidate = _kernel32.lookupFunction<
    Int32 Function(IntPtr hHeap, Uint32 dwFlags, Pointer lpMem),
    int Function(int hHeap, int dwFlags, Pointer lpMem)>('HeapValidate');

/// Enumerates the memory blocks in the specified heap.
///
/// ```c
/// BOOL HeapWalk(
///   HANDLE               hHeap,
///   LPPROCESS_HEAP_ENTRY lpEntry
/// );
/// ```
/// {@category kernel32}
int HeapWalk(int hHeap, Pointer<PROCESS_HEAP_ENTRY> lpEntry) =>
    _HeapWalk(hHeap, lpEntry);

final _HeapWalk = _kernel32.lookupFunction<
    Int32 Function(IntPtr hHeap, Pointer<PROCESS_HEAP_ENTRY> lpEntry),
    int Function(int hHeap, Pointer<PROCESS_HEAP_ENTRY> lpEntry)>('HeapWalk');

/// Initializes the specified list of attributes for process and thread
/// creation.
///
/// ```c
/// BOOL InitializeProcThreadAttributeList(
///   LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList,
///   DWORD                        dwAttributeCount,
///   DWORD                        dwFlags,
///   PSIZE_T                      lpSize
/// );
/// ```
/// {@category kernel32}
int InitializeProcThreadAttributeList(Pointer lpAttributeList,
        int dwAttributeCount, int dwFlags, Pointer<IntPtr> lpSize) =>
    _InitializeProcThreadAttributeList(
        lpAttributeList, dwAttributeCount, dwFlags, lpSize);

final _InitializeProcThreadAttributeList = _kernel32.lookupFunction<
    Int32 Function(Pointer lpAttributeList, Uint32 dwAttributeCount,
        Uint32 dwFlags, Pointer<IntPtr> lpSize),
    int Function(Pointer lpAttributeList, int dwAttributeCount, int dwFlags,
        Pointer<IntPtr> lpSize)>('InitializeProcThreadAttributeList');

/// Determines whether the calling process is being debugged by a user-mode
/// debugger.
///
/// ```c
/// BOOL IsDebuggerPresent();
/// ```
/// {@category kernel32}
int IsDebuggerPresent() => _IsDebuggerPresent();

final _IsDebuggerPresent = _kernel32
    .lookupFunction<Int32 Function(), int Function()>('IsDebuggerPresent');

/// Indicates if the OS was booted from a VHD container.
///
/// ```c
/// BOOL IsNativeVhdBoot(
///   PBOOL NativeVhdBoot
/// );
/// ```
/// {@category kernel32}
int IsNativeVhdBoot(Pointer<Int32> NativeVhdBoot) =>
    _IsNativeVhdBoot(NativeVhdBoot);

final _IsNativeVhdBoot = _kernel32.lookupFunction<
    Int32 Function(Pointer<Int32> NativeVhdBoot),
    int Function(Pointer<Int32> NativeVhdBoot)>('IsNativeVhdBoot');

/// Determines the current state of the computer.
///
/// ```c
/// BOOL IsSystemResumeAutomatic();
/// ```
/// {@category kernel32}
int IsSystemResumeAutomatic() => _IsSystemResumeAutomatic();

final _IsSystemResumeAutomatic =
    _kernel32.lookupFunction<Int32 Function(), int Function()>(
        'IsSystemResumeAutomatic');

/// Determines if the specified locale name is valid for a locale that is
/// installed or supported on the operating system.
///
/// ```c
/// BOOL IsValidLocaleName(
///   LPCWSTR lpLocaleName
///   );
/// ```
/// {@category kernel32}
int IsValidLocaleName(Pointer<Utf16> lpLocaleName) =>
    _IsValidLocaleName(lpLocaleName);

final _IsValidLocaleName = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpLocaleName),
    int Function(Pointer<Utf16> lpLocaleName)>('IsValidLocaleName');

/// Determines whether the specified process is running under WOW64. Also
/// returns additional machine process and architecture information.
///
/// ```c
/// BOOL IsWow64Process2(
///   HANDLE hProcess,
///   USHORT *pProcessMachine,
///   USHORT *pNativeMachine
/// );
/// ```
/// {@category kernel32}
int IsWow64Process2(int hProcess, Pointer<Uint16> pProcessMachine,
        Pointer<Uint16> pNativeMachine) =>
    _IsWow64Process2(hProcess, pProcessMachine, pNativeMachine);

final _IsWow64Process2 = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<Uint16> pProcessMachine,
        Pointer<Uint16> pNativeMachine),
    int Function(int hProcess, Pointer<Uint16> pProcessMachine,
        Pointer<Uint16> pNativeMachine)>('IsWow64Process2');

/// Loads the specified module into the address space of the calling
/// process. The specified module may cause other modules to be loaded.
///
/// ```c
/// HMODULE LoadLibraryW(
///   LPCWSTR lpLibFileName
/// );
/// ```
/// {@category kernel32}
int LoadLibrary(Pointer<Utf16> lpLibFileName) => _LoadLibrary(lpLibFileName);

final _LoadLibrary = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpLibFileName),
    int Function(Pointer<Utf16> lpLibFileName)>('LoadLibraryW');

/// Loads the specified module into the address space of the calling
/// process. The specified module may cause other modules to be loaded.
///
/// ```c
/// HMODULE LoadLibraryExW(
///   [in] LPCWSTR lpLibFileName,
///        HANDLE  hFile,
///   [in] DWORD   dwFlags
/// );
/// ```
/// {@category kernel32}
int LoadLibraryEx(Pointer<Utf16> lpLibFileName, int hFile, int dwFlags) =>
    _LoadLibraryEx(lpLibFileName, hFile, dwFlags);

final _LoadLibraryEx = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpLibFileName, IntPtr hFile, Uint32 dwFlags),
    int Function(Pointer<Utf16> lpLibFileName, int hFile,
        int dwFlags)>('LoadLibraryExW');

/// Retrieves a handle that can be used to obtain a pointer to the first
/// byte of the specified resource in memory.
///
/// ```c
/// HGLOBAL LoadResource(
///   HMODULE hModule,
///   HRSRC   hResInfo
/// );
/// ```
/// {@category kernel32}
int LoadResource(int hModule, int hResInfo) => _LoadResource(hModule, hResInfo);

final _LoadResource = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hModule, IntPtr hResInfo),
    int Function(int hModule, int hResInfo)>('LoadResource');

/// Frees the specified local memory object and invalidates its handle.
///
/// ```c
/// HLOCAL LocalFree(
///   _Frees_ptr_opt_ HLOCAL hMem
/// );
/// ```
/// {@category kernel32}
int LocalFree(int hMem) => _LocalFree(hMem);

final _LocalFree = _kernel32.lookupFunction<IntPtr Function(IntPtr hMem),
    int Function(int hMem)>('LocalFree');

/// Locks the specified file for exclusive access by the calling process.
///
/// ```c
/// BOOL LockFile(
///   [in] HANDLE hFile,
///   [in] DWORD  dwFileOffsetLow,
///   [in] DWORD  dwFileOffsetHigh,
///   [in] DWORD  nNumberOfBytesToLockLow,
///   [in] DWORD  nNumberOfBytesToLockHigh
/// );
/// ```
/// {@category kernel32}
int LockFile(int hFile, int dwFileOffsetLow, int dwFileOffsetHigh,
        int nNumberOfBytesToLockLow, int nNumberOfBytesToLockHigh) =>
    _LockFile(hFile, dwFileOffsetLow, dwFileOffsetHigh, nNumberOfBytesToLockLow,
        nNumberOfBytesToLockHigh);

final _LockFile = _kernel32.lookupFunction<
    Int32 Function(
        IntPtr hFile,
        Uint32 dwFileOffsetLow,
        Uint32 dwFileOffsetHigh,
        Uint32 nNumberOfBytesToLockLow,
        Uint32 nNumberOfBytesToLockHigh),
    int Function(int hFile, int dwFileOffsetLow, int dwFileOffsetHigh,
        int nNumberOfBytesToLockLow, int nNumberOfBytesToLockHigh)>('LockFile');

/// Locks the specified file for exclusive access by the calling process.
/// This function can operate either synchronously or asynchronously and can
/// request either an exclusive or a shared lock.
///
/// ```c
/// BOOL LockFileEx(
///   [in]      HANDLE       hFile,
///   [in]      DWORD        dwFlags,
///             DWORD        dwReserved,
///   [in]      DWORD        nNumberOfBytesToLockLow,
///   [in]      DWORD        nNumberOfBytesToLockHigh,
///   [in, out] LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int LockFileEx(
        int hFile,
        int dwFlags,
        int dwReserved,
        int nNumberOfBytesToLockLow,
        int nNumberOfBytesToLockHigh,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _LockFileEx(hFile, dwFlags, dwReserved, nNumberOfBytesToLockLow,
        nNumberOfBytesToLockHigh, lpOverlapped);

final _LockFileEx = _kernel32.lookupFunction<
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

/// Retrieves a pointer to the specified resource in memory.
///
/// ```c
/// LPVOID LockResource(
///   HGLOBAL hResData
/// );
/// ```
/// {@category kernel32}
Pointer LockResource(int hResData) => _LockResource(hResData);

final _LockResource = _kernel32.lookupFunction<
    Pointer Function(IntPtr hResData),
    Pointer Function(int hResData)>('LockResource');

/// Moves an existing file or a directory, including its children.
///
/// ```c
/// BOOL MoveFileW(
///   LPCWSTR lpExistingFileName,
///   LPCWSTR lpNewFileName
/// );
/// ```
/// {@category kernel32}
int MoveFile(Pointer<Utf16> lpExistingFileName, Pointer<Utf16> lpNewFileName) =>
    _MoveFile(lpExistingFileName, lpNewFileName);

final _MoveFile = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpExistingFileName, Pointer<Utf16> lpNewFileName),
    int Function(Pointer<Utf16> lpExistingFileName,
        Pointer<Utf16> lpNewFileName)>('MoveFileW');

/// Opens an existing named event object.
///
/// ```c
/// HANDLE OpenEventW(
///   DWORD   dwDesiredAccess,
///   BOOL    bInheritHandle,
///   LPCWSTR lpName
/// );
/// ```
/// {@category kernel32}
int OpenEvent(int dwDesiredAccess, int bInheritHandle, Pointer<Utf16> lpName) =>
    _OpenEvent(dwDesiredAccess, bInheritHandle, lpName);

final _OpenEvent = _kernel32.lookupFunction<
    IntPtr Function(
        Uint32 dwDesiredAccess, Int32 bInheritHandle, Pointer<Utf16> lpName),
    int Function(int dwDesiredAccess, int bInheritHandle,
        Pointer<Utf16> lpName)>('OpenEventW');

/// Opens an existing local process object.
///
/// ```c
/// HANDLE OpenProcess(
///   DWORD dwDesiredAccess,
///   BOOL  bInheritHandle,
///   DWORD dwProcessId
/// );
/// ```
/// {@category kernel32}
int OpenProcess(int dwDesiredAccess, int bInheritHandle, int dwProcessId) =>
    _OpenProcess(dwDesiredAccess, bInheritHandle, dwProcessId);

final _OpenProcess = _kernel32.lookupFunction<
    IntPtr Function(
        Uint32 dwDesiredAccess, Int32 bInheritHandle, Uint32 dwProcessId),
    int Function(int dwDesiredAccess, int bInheritHandle,
        int dwProcessId)>('OpenProcess');

/// Sends a string to the debugger for display.
///
/// ```c
/// void OutputDebugStringW(
///   LPCWSTR lpOutputString
/// );
/// ```
/// {@category kernel32}
void OutputDebugString(Pointer<Utf16> lpOutputString) =>
    _OutputDebugString(lpOutputString);

final _OutputDebugString = _kernel32.lookupFunction<
    Void Function(Pointer<Utf16> lpOutputString),
    void Function(Pointer<Utf16> lpOutputString)>('OutputDebugStringW');

/// Gets the package family name for the specified package full name.
///
/// ```c
/// LONG PackageFamilyNameFromFullName(
///   PCWSTR packageFullName,
///   UINT32 *packageFamilyNameLength,
///   PWSTR  packageFamilyName
/// );
/// ```
/// {@category kernel32}
int PackageFamilyNameFromFullName(
        Pointer<Utf16> packageFullName,
        Pointer<Uint32> packageFamilyNameLength,
        Pointer<Utf16> packageFamilyName) =>
    _PackageFamilyNameFromFullName(
        packageFullName, packageFamilyNameLength, packageFamilyName);

final _PackageFamilyNameFromFullName = _kernel32.lookupFunction<
    Uint32 Function(
        Pointer<Utf16> packageFullName,
        Pointer<Uint32> packageFamilyNameLength,
        Pointer<Utf16> packageFamilyName),
    int Function(
        Pointer<Utf16> packageFullName,
        Pointer<Uint32> packageFamilyNameLength,
        Pointer<Utf16> packageFamilyName)>('PackageFamilyNameFromFullName');

/// Reads data from the specified console input buffer without removing it
/// from the buffer.
///
/// ```c
/// BOOL PeekConsoleInputW(
///   HANDLE        hConsoleInput,
///   PINPUT_RECORD lpBuffer,
///   DWORD         nLength,
///   LPDWORD       lpNumberOfEventsRead
/// );
/// ```
/// {@category kernel32}
int PeekConsoleInput(int hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
        int nLength, Pointer<Uint32> lpNumberOfEventsRead) =>
    _PeekConsoleInput(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);

final _PeekConsoleInput = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
        Uint32 nLength, Pointer<Uint32> lpNumberOfEventsRead),
    int Function(int hConsoleInput, Pointer<INPUT_RECORD> lpBuffer, int nLength,
        Pointer<Uint32> lpNumberOfEventsRead)>('PeekConsoleInputW');

/// Copies data from a named or anonymous pipe into a buffer without
/// removing it from the pipe. It also returns information about data in the
/// pipe.
///
/// ```c
/// BOOL PeekNamedPipe(
///   HANDLE  hNamedPipe,
///   LPVOID  lpBuffer,
///   DWORD   nBufferSize,
///   LPDWORD lpBytesRead,
///   LPDWORD lpTotalBytesAvail,
///   LPDWORD lpBytesLeftThisMessage);
/// ```
/// {@category kernel32}
int PeekNamedPipe(
        int hNamedPipe,
        Pointer lpBuffer,
        int nBufferSize,
        Pointer<Uint32> lpBytesRead,
        Pointer<Uint32> lpTotalBytesAvail,
        Pointer<Uint32> lpBytesLeftThisMessage) =>
    _PeekNamedPipe(hNamedPipe, lpBuffer, nBufferSize, lpBytesRead,
        lpTotalBytesAvail, lpBytesLeftThisMessage);

final _PeekNamedPipe = _kernel32.lookupFunction<
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

/// Posts an I/O completion packet to an I/O completion port.
///
/// ```c
/// BOOL PostQueuedCompletionStatus(
///   HANDLE       CompletionPort,
///   DWORD        dwNumberOfBytesTransferred,
///   ULONG_PTR    dwCompletionKey,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int PostQueuedCompletionStatus(
        int CompletionPort,
        int dwNumberOfBytesTransferred,
        int dwCompletionKey,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _PostQueuedCompletionStatus(CompletionPort, dwNumberOfBytesTransferred,
        dwCompletionKey, lpOverlapped);

final _PostQueuedCompletionStatus = _kernel32.lookupFunction<
    Int32 Function(IntPtr CompletionPort, Uint32 dwNumberOfBytesTransferred,
        IntPtr dwCompletionKey, Pointer<OVERLAPPED> lpOverlapped),
    int Function(
        int CompletionPort,
        int dwNumberOfBytesTransferred,
        int dwCompletionKey,
        Pointer<OVERLAPPED> lpOverlapped)>('PostQueuedCompletionStatus');

/// Discards all characters from the output or input buffer of a specified
/// communications resource. It can also terminate pending read or write
/// operations on the resource.
///
/// ```c
/// BOOL PurgeComm(
///   HANDLE hFile,
///   DWORD  dwFlags
/// );
/// ```
/// {@category kernel32}
int PurgeComm(int hFile, int dwFlags) => _PurgeComm(hFile, dwFlags);

final _PurgeComm = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Uint32 dwFlags),
    int Function(int hFile, int dwFlags)>('PurgeComm');

/// Retrieves information about MS-DOS device names. The function can obtain
/// the current mapping for a particular MS-DOS device name. The function
/// can also obtain a list of all existing MS-DOS device names.
///
/// ```c
/// DWORD QueryDosDeviceW(
///   LPCWSTR lpDeviceName,
///   LPWSTR  lpTargetPath,
///   DWORD   ucchMax
/// );
/// ```
/// {@category kernel32}
int QueryDosDevice(Pointer<Utf16> lpDeviceName, Pointer<Utf16> lpTargetPath,
        int ucchMax) =>
    _QueryDosDevice(lpDeviceName, lpTargetPath, ucchMax);

final _QueryDosDevice = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpDeviceName, Pointer<Utf16> lpTargetPath,
        Uint32 ucchMax),
    int Function(Pointer<Utf16> lpDeviceName, Pointer<Utf16> lpTargetPath,
        int ucchMax)>('QueryDosDeviceW');

/// Retrieves the current value of the performance counter, which is a high
/// resolution (<1us) time stamp that can be used for time-interval
/// measurements.
///
/// ```c
/// BOOL QueryPerformanceCounter(
///   LARGE_INTEGER *lpPerformanceCount
/// );
/// ```
/// {@category kernel32}
int QueryPerformanceCounter(Pointer<Int64> lpPerformanceCount) =>
    _QueryPerformanceCounter(lpPerformanceCount);

final _QueryPerformanceCounter = _kernel32.lookupFunction<
    Int32 Function(Pointer<Int64> lpPerformanceCount),
    int Function(Pointer<Int64> lpPerformanceCount)>('QueryPerformanceCounter');

/// Retrieves the frequency of the performance counter. The frequency of the
/// performance counter is fixed at system boot and is consistent across all
/// processors. Therefore, the frequency need only be queried upon
/// application initialization, and the result can be cached.
///
/// ```c
/// BOOL QueryPerformanceFrequency(
///   LARGE_INTEGER *lpFrequency
/// );
/// ```
/// {@category kernel32}
int QueryPerformanceFrequency(Pointer<Int64> lpFrequency) =>
    _QueryPerformanceFrequency(lpFrequency);

final _QueryPerformanceFrequency = _kernel32.lookupFunction<
    Int32 Function(Pointer<Int64> lpFrequency),
    int Function(Pointer<Int64> lpFrequency)>('QueryPerformanceFrequency');

/// Reads character input from the console input buffer and removes it from
/// the buffer.
///
/// ```c
/// BOOL ReadConsoleW(
///   _In_     HANDLE  hConsoleInput,
///   _Out_    LPVOID  lpBuffer,
///   _In_     DWORD   nNumberOfCharsToRead,
///   _Out_    LPDWORD lpNumberOfCharsRead,
///   _In_opt_ LPVOID  pInputControl
/// );
/// ```
/// {@category kernel32}
int ReadConsole(
        int hConsoleInput,
        Pointer lpBuffer,
        int nNumberOfCharsToRead,
        Pointer<Uint32> lpNumberOfCharsRead,
        Pointer<CONSOLE_READCONSOLE_CONTROL> pInputControl) =>
    _ReadConsole(hConsoleInput, lpBuffer, nNumberOfCharsToRead,
        lpNumberOfCharsRead, pInputControl);

final _ReadConsole = _kernel32.lookupFunction<
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
        Pointer<CONSOLE_READCONSOLE_CONTROL> pInputControl)>('ReadConsoleW');

/// Reads data from a console input buffer and removes it from the buffer.
///
/// ```c
/// BOOL ReadConsoleInputW(
///   HANDLE        hConsoleInput,
///   PINPUT_RECORD lpBuffer,
///   DWORD         nLength,
///   LPDWORD       lpNumberOfEventsRead
/// );
/// ```
/// {@category kernel32}
int ReadConsoleInput(int hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
        int nLength, Pointer<Uint32> lpNumberOfEventsRead) =>
    _ReadConsoleInput(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);

final _ReadConsoleInput = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleInput, Pointer<INPUT_RECORD> lpBuffer,
        Uint32 nLength, Pointer<Uint32> lpNumberOfEventsRead),
    int Function(int hConsoleInput, Pointer<INPUT_RECORD> lpBuffer, int nLength,
        Pointer<Uint32> lpNumberOfEventsRead)>('ReadConsoleInputW');

/// Reads data from the specified file or input/output (I/O) device. Reads
/// occur at the position specified by the file pointer if supported by the
/// device.
///
/// ```c
/// BOOL ReadFile(
///   HANDLE       hFile,
///   LPVOID       lpBuffer,
///   DWORD        nNumberOfBytesToRead,
///   LPDWORD      lpNumberOfBytesRead,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int ReadFile(
        int hFile,
        Pointer lpBuffer,
        int nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead,
        lpOverlapped);

final _ReadFile = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer lpBuffer, Uint32 nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead, Pointer<OVERLAPPED> lpOverlapped),
    int Function(
        int hFile,
        Pointer lpBuffer,
        int nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead,
        Pointer<OVERLAPPED> lpOverlapped)>('ReadFile');

/// Reads data from the specified file or input/output (I/O) device. It
/// reports its completion status asynchronously, calling the specified
/// completion routine when reading is completed or canceled and the calling
/// thread is in an alertable wait state.
///
/// ```c
/// BOOL ReadFileEx(
///   [in]            HANDLE                          hFile,
///   [out, optional] LPVOID                          lpBuffer,
///   [in]            DWORD                           nNumberOfBytesToRead,
///   [in, out]       LPOVERLAPPED                    lpOverlapped,
///   [in]            LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
/// );
/// ```
/// {@category kernel32}
int ReadFileEx(
        int hFile,
        Pointer lpBuffer,
        int nNumberOfBytesToRead,
        Pointer<OVERLAPPED> lpOverlapped,
        Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
            lpCompletionRoutine) =>
    _ReadFileEx(hFile, lpBuffer, nNumberOfBytesToRead, lpOverlapped,
        lpCompletionRoutine);

final _ReadFileEx = _kernel32.lookupFunction<
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

/// Reads data from a file and stores it in an array of buffers. The
/// function starts reading data from the file at a position that is
/// specified by an OVERLAPPED structure. The ReadFileScatter function
/// operates asynchronously.
///
/// ```c
/// BOOL ReadFileScatter(
///   [in]      HANDLE                  hFile,
///   [in]      FILE_SEGMENT_ELEMENT [] aSegmentArray,
///   [in]      DWORD                   nNumberOfBytesToRead,
///             LPDWORD                 lpReserved,
///   [in, out] LPOVERLAPPED            lpOverlapped
/// );
/// ```
/// {@category kernel32}
int ReadFileScatter(
        int hFile,
        Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
        int nNumberOfBytesToRead,
        Pointer<Uint32> lpReserved,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _ReadFileScatter(
        hFile, aSegmentArray, nNumberOfBytesToRead, lpReserved, lpOverlapped);

final _ReadFileScatter = _kernel32.lookupFunction<
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

/// ReadProcessMemory copies the data in the specified address range from
/// the address space of the specified process into the specified buffer of
/// the current process. Any process that has a handle with PROCESS_VM_READ
/// access can call the function.
///
/// ```c
/// BOOL ReadProcessMemory(
///   HANDLE  hProcess,
///   LPCVOID lpBaseAddress,
///   LPVOID  lpBuffer,
///   SIZE_T  nSize,
///   SIZE_T  *lpNumberOfBytesRead
/// );
/// ```
/// {@category kernel32}
int ReadProcessMemory(int hProcess, Pointer lpBaseAddress, Pointer lpBuffer,
        int nSize, Pointer<IntPtr> lpNumberOfBytesRead) =>
    _ReadProcessMemory(
        hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesRead);

final _ReadProcessMemory = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer lpBaseAddress, Pointer lpBuffer,
        IntPtr nSize, Pointer<IntPtr> lpNumberOfBytesRead),
    int Function(int hProcess, Pointer lpBaseAddress, Pointer lpBuffer,
        int nSize, Pointer<IntPtr> lpNumberOfBytesRead)>('ReadProcessMemory');

/// The ReleaseActCtx function decrements the reference count of the
/// specified activation context.
///
/// ```c
/// void ReleaseActCtx(
///   HANDLE hActCtx
/// );
/// ```
/// {@category kernel32}
void ReleaseActCtx(int hActCtx) => _ReleaseActCtx(hActCtx);

final _ReleaseActCtx = _kernel32.lookupFunction<Void Function(IntPtr hActCtx),
    void Function(int hActCtx)>('ReleaseActCtx');

/// Deletes an existing empty directory.
///
/// ```c
/// BOOL RemoveDirectoryW(
///   LPCWSTR lpPathName
/// );
/// ```
/// {@category kernel32}
int RemoveDirectory(Pointer<Utf16> lpPathName) => _RemoveDirectory(lpPathName);

final _RemoveDirectory = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpPathName),
    int Function(Pointer<Utf16> lpPathName)>('RemoveDirectoryW');

/// Removes a directory that was added to the process DLL search path by
/// using AddDllDirectory.
///
/// ```c
/// BOOL RemoveDllDirectory(
///   [in] DLL_DIRECTORY_COOKIE Cookie
/// );
/// ```
/// {@category kernel32}
int RemoveDllDirectory(Pointer Cookie) => _RemoveDllDirectory(Cookie);

final _RemoveDllDirectory = _kernel32.lookupFunction<
    Int32 Function(Pointer Cookie),
    int Function(Pointer Cookie)>('RemoveDllDirectory');

/// Reopens the specified file system object with different access rights,
/// sharing mode, and flags.
///
/// ```c
/// HANDLE ReOpenFile(
///   HANDLE hOriginalFile,
///   DWORD  dwDesiredAccess,
///   DWORD  dwShareMode,
///   DWORD  dwFlagsAndAttributes);
/// ```
/// {@category kernel32}
int ReOpenFile(int hOriginalFile, int dwDesiredAccess, int dwShareMode,
        int dwFlagsAndAttributes) =>
    _ReOpenFile(
        hOriginalFile, dwDesiredAccess, dwShareMode, dwFlagsAndAttributes);

final _ReOpenFile = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hOriginalFile, Uint32 dwDesiredAccess,
        Uint32 dwShareMode, Uint32 dwFlagsAndAttributes),
    int Function(int hOriginalFile, int dwDesiredAccess, int dwShareMode,
        int dwFlagsAndAttributes)>('ReOpenFile');

/// Sets the specified event object to the nonsignaled state.
///
/// ```c
/// BOOL ResetEvent(
///   HANDLE hEvent
/// );
/// ```
/// {@category kernel32}
int ResetEvent(int hEvent) => _ResetEvent(hEvent);

final _ResetEvent = _kernel32.lookupFunction<Int32 Function(IntPtr hEvent),
    int Function(int hEvent)>('ResetEvent');

/// Resizes the internal buffers for a pseudoconsole to the given size.
///
/// ```c
/// HRESULT ResizePseudoConsole(
///   _In_ HPCON hPC ,
///   _In_ COORD size
/// );
/// ```
/// {@category kernel32}
int ResizePseudoConsole(int hPC, COORD size) => _ResizePseudoConsole(hPC, size);

final _ResizePseudoConsole = _kernel32.lookupFunction<
    Int32 Function(IntPtr hPC, COORD size),
    int Function(int hPC, COORD size)>('ResizePseudoConsole');

/// Moves a block of data in a screen buffer. The effects of the move can be
/// limited by specifying a clipping rectangle, so the contents of the
/// console screen buffer outside the clipping rectangle are unchanged.
///
/// ```c
/// BOOL ScrollConsoleScreenBufferW(
///   _In_           HANDLE     hConsoleOutput,
///   _In_     const SMALL_RECT *lpScrollRectangle,
///   _In_opt_ const SMALL_RECT *lpClipRectangle,
///   _In_           COORD      dwDestinationOrigin,
///   _In_     const CHAR_INFO  *lpFill
/// );
/// ```
/// {@category kernel32}
int ScrollConsoleScreenBuffer(
        int hConsoleOutput,
        Pointer<SMALL_RECT> lpScrollRectangle,
        Pointer<SMALL_RECT> lpClipRectangle,
        COORD dwDestinationOrigin,
        Pointer<CHAR_INFO> lpFill) =>
    _ScrollConsoleScreenBuffer(hConsoleOutput, lpScrollRectangle,
        lpClipRectangle, dwDestinationOrigin, lpFill);

final _ScrollConsoleScreenBuffer = _kernel32.lookupFunction<
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

/// Suspends character transmission for a specified communications device
/// and places the transmission line in a break state until the
/// ClearCommBreak function is called.
///
/// ```c
/// BOOL SetCommBreak(
///   HANDLE hFile
/// );
/// ```
/// {@category kernel32}
int SetCommBreak(int hFile) => _SetCommBreak(hFile);

final _SetCommBreak = _kernel32.lookupFunction<Int32 Function(IntPtr hFile),
    int Function(int hFile)>('SetCommBreak');

/// Sets the current configuration of a communications device.
///
/// ```c
/// BOOL SetCommConfig(
///   HANDLE       hCommDev,
///   LPCOMMCONFIG lpCC,
///   DWORD        dwSize
/// );
/// ```
/// {@category kernel32}
int SetCommConfig(int hCommDev, Pointer<COMMCONFIG> lpCC, int dwSize) =>
    _SetCommConfig(hCommDev, lpCC, dwSize);

final _SetCommConfig = _kernel32.lookupFunction<
    Int32 Function(IntPtr hCommDev, Pointer<COMMCONFIG> lpCC, Uint32 dwSize),
    int Function(
        int hCommDev, Pointer<COMMCONFIG> lpCC, int dwSize)>('SetCommConfig');

/// Specifies a set of events to be monitored for a communications device.
///
/// ```c
/// BOOL SetCommMask(
///   HANDLE hFile,
///   DWORD  dwEvtMask
/// );
/// ```
/// {@category kernel32}
int SetCommMask(int hFile, int dwEvtMask) => _SetCommMask(hFile, dwEvtMask);

final _SetCommMask = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Uint32 dwEvtMask),
    int Function(int hFile, int dwEvtMask)>('SetCommMask');

/// Configures a communications device according to the specifications in a
/// device-control block (a DCB structure). The function reinitializes all
/// hardware and control settings, but it does not empty output or input
/// queues.
///
/// ```c
/// BOOL SetCommState(
///   HANDLE hFile,
///   LPDCB  lpDCB
/// );
/// ```
/// {@category kernel32}
int SetCommState(int hFile, Pointer<DCB> lpDCB) => _SetCommState(hFile, lpDCB);

final _SetCommState = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB),
    int Function(int hFile, Pointer<DCB> lpDCB)>('SetCommState');

/// Sets the time-out parameters for all read and write operations on a
/// specified communications device.
///
/// ```c
/// BOOL SetCommTimeouts(
///   HANDLE         hFile,
///   LPCOMMTIMEOUTS lpCommTimeouts
/// );
/// ```
/// {@category kernel32}
int SetCommTimeouts(int hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts) =>
    _SetCommTimeouts(hFile, lpCommTimeouts);

final _SetCommTimeouts = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts),
    int Function(
        int hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts)>('SetCommTimeouts');

/// Adds or removes an application-defined HandlerRoutine function from the
/// list of handler functions for the calling process.
///
/// ```c
/// BOOL SetConsoleCtrlHandler(
///   _In_opt_ PHANDLER_ROUTINE HandlerRoutine,
///   _In_     BOOL             Add
/// );
/// ```
/// {@category kernel32}
int SetConsoleCtrlHandler(
        Pointer<NativeFunction<HandlerRoutine>> HandlerRoutine, int Add) =>
    _SetConsoleCtrlHandler(HandlerRoutine, Add);

final _SetConsoleCtrlHandler = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<NativeFunction<HandlerRoutine>> HandlerRoutine, Int32 Add),
    int Function(Pointer<NativeFunction<HandlerRoutine>> HandlerRoutine,
        int Add)>('SetConsoleCtrlHandler');

/// Sets the size and visibility of the cursor for the specified console
/// screen buffer.
///
/// ```c
/// BOOL SetConsoleCursorInfo(
///   _In_       HANDLE              hConsoleOutput,
///   _In_ const CONSOLE_CURSOR_INFO *lpConsoleCursorInfo
/// );
/// ```
/// {@category kernel32}
int SetConsoleCursorInfo(
        int hConsoleOutput, Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo) =>
    _SetConsoleCursorInfo(hConsoleOutput, lpConsoleCursorInfo);

final _SetConsoleCursorInfo = _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleOutput,
            Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo),
        int Function(int hConsoleOutput,
            Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo)>(
    'SetConsoleCursorInfo');

/// Sets the cursor position in the specified console screen buffer.
///
/// ```c
/// BOOL SetConsoleCursorPosition(
///   _In_ HANDLE hConsoleOutput,
///   _In_ COORD  dwCursorPosition
/// );
/// ```
/// {@category kernel32}
int SetConsoleCursorPosition(int hConsoleOutput, COORD dwCursorPosition) =>
    _SetConsoleCursorPosition(hConsoleOutput, dwCursorPosition);

final _SetConsoleCursorPosition = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, COORD dwCursorPosition),
    int Function(int hConsoleOutput,
        COORD dwCursorPosition)>('SetConsoleCursorPosition');

/// Sets the display mode of the specified console screen buffer.
///
/// ```c
/// BOOL SetConsoleDisplayMode(
///   _In_      HANDLE hConsoleOutput,
///   _In_      DWORD  dwFlags,
///   _Out_opt_ PCOORD lpNewScreenBufferDimensions
/// );
/// ```
/// {@category kernel32}
int SetConsoleDisplayMode(int hConsoleOutput, int dwFlags,
        Pointer<COORD> lpNewScreenBufferDimensions) =>
    _SetConsoleDisplayMode(
        hConsoleOutput, dwFlags, lpNewScreenBufferDimensions);

final _SetConsoleDisplayMode = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, Uint32 dwFlags,
        Pointer<COORD> lpNewScreenBufferDimensions),
    int Function(int hConsoleOutput, int dwFlags,
        Pointer<COORD> lpNewScreenBufferDimensions)>('SetConsoleDisplayMode');

/// Sets the input mode of a console's input buffer or the output mode of a
/// console screen buffer.
///
/// ```c
/// BOOL SetConsoleMode(
///   _In_ HANDLE hConsoleHandle,
///   _In_ DWORD  dwMode
/// );
/// ```
/// {@category kernel32}
int SetConsoleMode(int hConsoleHandle, int dwMode) =>
    _SetConsoleMode(hConsoleHandle, dwMode);

final _SetConsoleMode = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleHandle, Uint32 dwMode),
    int Function(int hConsoleHandle, int dwMode)>('SetConsoleMode');

/// Sets the attributes of characters written to the console screen buffer
/// by the WriteFile or WriteConsole function, or echoed by the ReadFile or
/// ReadConsole function. This function affects text written after the
/// function call.
///
/// ```c
/// BOOL SetConsoleTextAttribute(
///   _In_ HANDLE hConsoleOutput,
///   _In_ WORD   wAttributes
/// );
/// ```
/// {@category kernel32}
int SetConsoleTextAttribute(int hConsoleOutput, int wAttributes) =>
    _SetConsoleTextAttribute(hConsoleOutput, wAttributes);

final _SetConsoleTextAttribute = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, Uint16 wAttributes),
    int Function(
        int hConsoleOutput, int wAttributes)>('SetConsoleTextAttribute');

/// Sets the current size and position of a console screen buffer's window.
///
/// ```c
/// BOOL SetConsoleWindowInfo(
///   _In_       HANDLE     hConsoleOutput,
///   _In_       BOOL       bAbsolute,
///   _In_ const SMALL_RECT *lpConsoleWindow
/// );
/// ```
/// {@category kernel32}
int SetConsoleWindowInfo(int hConsoleOutput, int bAbsolute,
        Pointer<SMALL_RECT> lpConsoleWindow) =>
    _SetConsoleWindowInfo(hConsoleOutput, bAbsolute, lpConsoleWindow);

final _SetConsoleWindowInfo = _kernel32.lookupFunction<
    Int32 Function(IntPtr hConsoleOutput, Int32 bAbsolute,
        Pointer<SMALL_RECT> lpConsoleWindow),
    int Function(int hConsoleOutput, int bAbsolute,
        Pointer<SMALL_RECT> lpConsoleWindow)>('SetConsoleWindowInfo');

/// Changes the current directory for the current process.
///
/// ```c
/// BOOL SetCurrentDirectoryW(
///   LPCTSTR lpPathName
/// );
/// ```
/// {@category kernel32}
int SetCurrentDirectory(Pointer<Utf16> lpPathName) =>
    _SetCurrentDirectory(lpPathName);

final _SetCurrentDirectory = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpPathName),
    int Function(Pointer<Utf16> lpPathName)>('SetCurrentDirectoryW');

/// Sets the default configuration for a communications device.
///
/// ```c
/// BOOL SetDefaultCommConfigW(
///   LPCWSTR      lpszName,
///   LPCOMMCONFIG lpCC,
///   DWORD        dwSize
/// );
/// ```
/// {@category kernel32}
int SetDefaultCommConfig(
        Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC, int dwSize) =>
    _SetDefaultCommConfig(lpszName, lpCC, dwSize);

final _SetDefaultCommConfig = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC, Uint32 dwSize),
    int Function(Pointer<Utf16> lpszName, Pointer<COMMCONFIG> lpCC,
        int dwSize)>('SetDefaultCommConfigW');

/// Specifies a default set of directories to search when the calling
/// process loads a DLL. This search path is used when LoadLibraryEx is
/// called with no LOAD_LIBRARY_SEARCH flags.
///
/// ```c
/// BOOL SetDefaultDllDirectories(
///   [in] DWORD DirectoryFlags
/// );
/// ```
/// {@category kernel32}
int SetDefaultDllDirectories(int DirectoryFlags) =>
    _SetDefaultDllDirectories(DirectoryFlags);

final _SetDefaultDllDirectories = _kernel32.lookupFunction<
    Int32 Function(Uint32 DirectoryFlags),
    int Function(int DirectoryFlags)>('SetDefaultDllDirectories');

/// Sets the physical file size for the specified file to the current
/// position of the file pointer.
///
/// ```c
/// BOOL SetEndOfFile(
///   [in] HANDLE hFile
/// );
/// ```
/// {@category kernel32}
int SetEndOfFile(int hFile) => _SetEndOfFile(hFile);

final _SetEndOfFile = _kernel32.lookupFunction<Int32 Function(IntPtr hFile),
    int Function(int hFile)>('SetEndOfFile');

/// Sets the contents of the specified environment variable for the current
/// process.
///
/// ```c
/// BOOL SetEnvironmentVariableW(
///   LPCWSTR lpName,
///   LPCWSTR lpValue
/// );
/// ```
/// {@category kernel32}
int SetEnvironmentVariable(Pointer<Utf16> lpName, Pointer<Utf16> lpValue) =>
    _SetEnvironmentVariable(lpName, lpValue);

final _SetEnvironmentVariable = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpValue),
    int Function(Pointer<Utf16> lpName,
        Pointer<Utf16> lpValue)>('SetEnvironmentVariableW');

/// Sets the specified event object to the signaled state.
///
/// ```c
/// UINT SetErrorMode(
///   UINT uMode
/// );
/// ```
/// {@category kernel32}
int SetErrorMode(int uMode) => _SetErrorMode(uMode);

final _SetErrorMode = _kernel32.lookupFunction<Uint32 Function(Uint32 uMode),
    int Function(int uMode)>('SetErrorMode');

/// Sets the specified event object to the signaled state.
///
/// ```c
/// BOOL SetEvent(
///   HANDLE hEvent
/// );
/// ```
/// {@category kernel32}
int SetEvent(int hEvent) => _SetEvent(hEvent);

final _SetEvent = _kernel32.lookupFunction<Int32 Function(IntPtr hEvent),
    int Function(int hEvent)>('SetEvent');

/// Causes the file I/O functions to use the ANSI character set code page
/// for the current process.
///
/// ```c
/// void SetFileApisToANSI();
/// ```
/// {@category kernel32}
void SetFileApisToANSI() => _SetFileApisToANSI();

final _SetFileApisToANSI = _kernel32
    .lookupFunction<Void Function(), void Function()>('SetFileApisToANSI');

/// Causes the file I/O functions for the process to use the OEM character
/// set code page.
///
/// ```c
/// void SetFileApisToOEM();
/// ```
/// {@category kernel32}
void SetFileApisToOEM() => _SetFileApisToOEM();

final _SetFileApisToOEM = _kernel32
    .lookupFunction<Void Function(), void Function()>('SetFileApisToOEM');

/// Sets the attributes for a file or directory.
///
/// ```c
/// BOOL SetFileAttributesW(
///   [in] LPCWSTR lpFileName,
///   [in] DWORD   dwFileAttributes
/// );
/// ```
/// {@category kernel32}
int SetFileAttributes(Pointer<Utf16> lpFileName, int dwFileAttributes) =>
    _SetFileAttributes(lpFileName, dwFileAttributes);

final _SetFileAttributes = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName, Uint32 dwFileAttributes),
    int Function(
        Pointer<Utf16> lpFileName, int dwFileAttributes)>('SetFileAttributesW');

/// Sets the file information for the specified file.
///
/// ```c
/// BOOL SetFileInformationByHandle(
///   [in] HANDLE                    hFile,
///   [in] FILE_INFO_BY_HANDLE_CLASS FileInformationClass,
///   [in] LPVOID                    lpFileInformation,
///   [in] DWORD                     dwBufferSize
/// );
/// ```
/// {@category kernel32}
int SetFileInformationByHandle(int hFile, int FileInformationClass,
        Pointer lpFileInformation, int dwBufferSize) =>
    _SetFileInformationByHandle(
        hFile, FileInformationClass, lpFileInformation, dwBufferSize);

final _SetFileInformationByHandle = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Int32 FileInformationClass,
        Pointer lpFileInformation, Uint32 dwBufferSize),
    int Function(int hFile, int FileInformationClass, Pointer lpFileInformation,
        int dwBufferSize)>('SetFileInformationByHandle');

/// Associates a virtual address range with the specified file handle. This
/// indicates that the kernel should optimize any further asynchronous I/O
/// requests with overlapped structures inside this range. The overlapped
/// range is locked in memory, and then unlocked when the file is closed.
/// After a range is associated with a file handle, it cannot be
/// disassociated.
///
/// ```c
/// BOOL SetFileIoOverlappedRange(
///   [in] HANDLE FileHandle,
///   [in] PUCHAR OverlappedRangeStart,
///   [in] ULONG  Length
/// );
/// ```
/// {@category kernel32}
int SetFileIoOverlappedRange(
        int FileHandle, Pointer<Uint8> OverlappedRangeStart, int Length) =>
    _SetFileIoOverlappedRange(FileHandle, OverlappedRangeStart, Length);

final _SetFileIoOverlappedRange = _kernel32.lookupFunction<
    Int32 Function(
        IntPtr FileHandle, Pointer<Uint8> OverlappedRangeStart, Uint32 Length),
    int Function(int FileHandle, Pointer<Uint8> OverlappedRangeStart,
        int Length)>('SetFileIoOverlappedRange');

/// Moves the file pointer of the specified file.
///
/// ```c
/// DWORD SetFilePointer(
///   HANDLE hFile,
///   LONG   lDistanceToMove,
///   PLONG  lpDistanceToMoveHigh,
///   DWORD  dwMoveMethod
/// );
/// ```
/// {@category kernel32}
int SetFilePointer(int hFile, int lDistanceToMove,
        Pointer<Int32> lpDistanceToMoveHigh, int dwMoveMethod) =>
    _SetFilePointer(hFile, lDistanceToMove, lpDistanceToMoveHigh, dwMoveMethod);

final _SetFilePointer = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hFile, Int32 lDistanceToMove,
        Pointer<Int32> lpDistanceToMoveHigh, Uint32 dwMoveMethod),
    int Function(
        int hFile,
        int lDistanceToMove,
        Pointer<Int32> lpDistanceToMoveHigh,
        int dwMoveMethod)>('SetFilePointer');

/// Moves the file pointer of the specified file.
///
/// ```c
/// BOOL SetFilePointerEx(
///   HANDLE         hFile,
///   LARGE_INTEGER  liDistanceToMove,
///   PLARGE_INTEGER lpNewFilePointer,
///   DWORD          dwMoveMethod
/// );
/// ```
/// {@category kernel32}
int SetFilePointerEx(int hFile, int liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, int dwMoveMethod) =>
    _SetFilePointerEx(hFile, liDistanceToMove, lpNewFilePointer, dwMoveMethod);

final _SetFilePointerEx = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Int64 liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, Uint32 dwMoveMethod),
    int Function(int hFile, int liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, int dwMoveMethod)>('SetFilePointerEx');

/// Sets the short name for the specified file. The file must be on an NTFS
/// file system volume.
///
/// ```c
/// BOOL SetFileShortNameW(
///   HANDLE  hFile,
///   LPCWSTR lpShortName);
/// ```
/// {@category kernel32}
int SetFileShortName(int hFile, Pointer<Utf16> lpShortName) =>
    _SetFileShortName(hFile, lpShortName);

final _SetFileShortName = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<Utf16> lpShortName),
    int Function(int hFile, Pointer<Utf16> lpShortName)>('SetFileShortNameW');

/// Sets the valid data length of the specified file. This function is
/// useful in very limited scenarios.
///
/// ```c
/// BOOL SetFileValidData(
///   [in] HANDLE   hFile,
///   [in] LONGLONG ValidDataLength
/// );
/// ```
/// {@category kernel32}
int SetFileValidData(int hFile, int ValidDataLength) =>
    _SetFileValidData(hFile, ValidDataLength);

final _SetFileValidData = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Int64 ValidDataLength),
    int Function(int hFile, int ValidDataLength)>('SetFileValidData');

/// Sets the value of the specified firmware environment variable.
///
/// ```c
/// BOOL SetFirmwareEnvironmentVariableW(
///   LPCWSTR lpName,
///   LPCWSTR lpGuid,
///   PVOID   pValue,
///   DWORD   nSize
/// );
/// ```
/// {@category kernel32}
int SetFirmwareEnvironmentVariable(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid,
        Pointer pValue, int nSize) =>
    _SetFirmwareEnvironmentVariable(lpName, lpGuid, pValue, nSize);

final _SetFirmwareEnvironmentVariable = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid, Pointer pValue,
        Uint32 nSize),
    int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid, Pointer pValue,
        int nSize)>('SetFirmwareEnvironmentVariableW');

/// Sets the value of the specified firmware environment variable and the
/// attributes that indicate how this variable is stored and maintained.
///
/// ```c
/// BOOL SetFirmwareEnvironmentVariableExW(
///   LPCWSTR lpName,
///   LPCWSTR lpGuid,
///   PVOID   pValue,
///   DWORD   nSize,
///   DWORD   dwAttributes
/// );
/// ```
/// {@category kernel32}
int SetFirmwareEnvironmentVariableEx(Pointer<Utf16> lpName,
        Pointer<Utf16> lpGuid, Pointer pValue, int nSize, int dwAttributes) =>
    _SetFirmwareEnvironmentVariableEx(
        lpName, lpGuid, pValue, nSize, dwAttributes);

final _SetFirmwareEnvironmentVariableEx = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid, Pointer pValue,
        Uint32 nSize, Uint32 dwAttributes),
    int Function(Pointer<Utf16> lpName, Pointer<Utf16> lpGuid, Pointer pValue,
        int nSize, int dwAttributes)>('SetFirmwareEnvironmentVariableExW');

/// Sets certain properties of an object handle.
///
/// ```c
/// BOOL SetHandleInformation(
///   HANDLE hObject,
///   DWORD  dwMask,
///   DWORD  dwFlags
/// );
/// ```
/// {@category kernel32}
int SetHandleInformation(int hObject, int dwMask, int dwFlags) =>
    _SetHandleInformation(hObject, dwMask, dwFlags);

final _SetHandleInformation = _kernel32.lookupFunction<
    Int32 Function(IntPtr hObject, Uint32 dwMask, Uint32 dwFlags),
    int Function(int hObject, int dwMask, int dwFlags)>('SetHandleInformation');

/// Sets the read mode and the blocking mode of the specified named pipe. If
/// the specified handle is to the client end of a named pipe and if the
/// named pipe server process is on a remote computer, the function can also
/// be used to control local buffering.
///
/// ```c
/// BOOL SetNamedPipeHandleState(
///   HANDLE  hNamedPipe,
///   LPDWORD lpMode,
///   LPDWORD lpMaxCollectionCount,
///   LPDWORD lpCollectDataTimeout);
/// ```
/// {@category kernel32}
int SetNamedPipeHandleState(
        int hNamedPipe,
        Pointer<Uint32> lpMode,
        Pointer<Uint32> lpMaxCollectionCount,
        Pointer<Uint32> lpCollectDataTimeout) =>
    _SetNamedPipeHandleState(
        hNamedPipe, lpMode, lpMaxCollectionCount, lpCollectDataTimeout);

final _SetNamedPipeHandleState = _kernel32.lookupFunction<
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

/// Sets a processor affinity mask for the threads of the specified process.
///
/// ```c
/// BOOL SetProcessAffinityMask(
///   HANDLE    hProcess,
///   DWORD_PTR dwProcessAffinityMask
/// );
/// ```
/// {@category kernel32}
int SetProcessAffinityMask(int hProcess, int dwProcessAffinityMask) =>
    _SetProcessAffinityMask(hProcess, dwProcessAffinityMask);

final _SetProcessAffinityMask = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, IntPtr dwProcessAffinityMask),
    int Function(
        int hProcess, int dwProcessAffinityMask)>('SetProcessAffinityMask');

/// Disables or enables the ability of the system to temporarily boost the
/// priority of the threads of the specified process.
///
/// ```c
/// BOOL SetProcessPriorityBoost(
///   HANDLE hProcess,
///   BOOL   bDisablePriorityBoost
/// );
/// ```
/// {@category kernel32}
int SetProcessPriorityBoost(int hProcess, int bDisablePriorityBoost) =>
    _SetProcessPriorityBoost(hProcess, bDisablePriorityBoost);

final _SetProcessPriorityBoost = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Int32 bDisablePriorityBoost),
    int Function(
        int hProcess, int bDisablePriorityBoost)>('SetProcessPriorityBoost');

/// Sets the minimum and maximum working set sizes for the specified
/// process.
///
/// ```c
/// BOOL SetProcessWorkingSetSize(
///   HANDLE hProcess,
///   SIZE_T dwMinimumWorkingSetSize,
///   SIZE_T dwMaximumWorkingSetSize
/// );
/// ```
/// {@category kernel32}
int SetProcessWorkingSetSize(int hProcess, int dwMinimumWorkingSetSize,
        int dwMaximumWorkingSetSize) =>
    _SetProcessWorkingSetSize(
        hProcess, dwMinimumWorkingSetSize, dwMaximumWorkingSetSize);

final _SetProcessWorkingSetSize = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize,
        IntPtr dwMaximumWorkingSetSize),
    int Function(int hProcess, int dwMinimumWorkingSetSize,
        int dwMaximumWorkingSetSize)>('SetProcessWorkingSetSize');

/// Sets the handle for the specified standard device (standard input,
/// standard output, or standard error).
///
/// ```c
/// BOOL SetStdHandle(
///   _In_ DWORD  nStdHandle,
///   _In_ HANDLE hHandle
/// );
/// ```
/// {@category kernel32}
int SetStdHandle(int nStdHandle, int hHandle) =>
    _SetStdHandle(nStdHandle, hHandle);

final _SetStdHandle = _kernel32.lookupFunction<
    Int32 Function(Uint32 nStdHandle, IntPtr hHandle),
    int Function(int nStdHandle, int hHandle)>('SetStdHandle');

/// Sets a processor affinity mask for the specified thread.
///
/// ```c
/// DWORD_PTR SetThreadAffinityMask(
///   HANDLE    hThread,
///   DWORD_PTR dwThreadAffinityMask
/// );
/// ```
/// {@category kernel32}
int SetThreadAffinityMask(int hThread, int dwThreadAffinityMask) =>
    _SetThreadAffinityMask(hThread, dwThreadAffinityMask);

final _SetThreadAffinityMask = _kernel32.lookupFunction<
    IntPtr Function(IntPtr hThread, IntPtr dwThreadAffinityMask),
    int Function(
        int hThread, int dwThreadAffinityMask)>('SetThreadAffinityMask');

/// Controls whether the system will handle the specified types of serious
/// errors or whether the calling thread will handle them.
///
/// ```c
/// BOOL SetThreadErrorMode(
///   DWORD   dwNewMode,
///   LPDWORD lpOldMode
/// );
/// ```
/// {@category kernel32}
int SetThreadErrorMode(int dwNewMode, Pointer<Uint32> lpOldMode) =>
    _SetThreadErrorMode(dwNewMode, lpOldMode);

final _SetThreadErrorMode = _kernel32.lookupFunction<
    Int32 Function(Uint32 dwNewMode, Pointer<Uint32> lpOldMode),
    int Function(
        int dwNewMode, Pointer<Uint32> lpOldMode)>('SetThreadErrorMode');

/// Enables an application to inform the system that it is in use, thereby
/// preventing the system from entering sleep or turning off the display
/// while the application is running.
///
/// ```c
/// EXECUTION_STATE SetThreadExecutionState(
///   EXECUTION_STATE esFlags
///   );
/// ```
/// {@category kernel32}
int SetThreadExecutionState(int esFlags) => _SetThreadExecutionState(esFlags);

final _SetThreadExecutionState = _kernel32.lookupFunction<
    Uint32 Function(Uint32 esFlags),
    int Function(int esFlags)>('SetThreadExecutionState');

/// Sets the user interface language for the current thread.
///
/// ```c
/// LANGID SetThreadUILanguage(
///   LANGID LangId
/// );
/// ```
/// {@category kernel32}
int SetThreadUILanguage(int LangId) => _SetThreadUILanguage(LangId);

final _SetThreadUILanguage = _kernel32.lookupFunction<
    Uint16 Function(Uint16 LangId),
    int Function(int LangId)>('SetThreadUILanguage');

/// Initializes the communications parameters for a specified communications
/// device.
///
/// ```c
/// BOOL SetupComm(
///   HANDLE hFile,
///   DWORD  dwInQueue,
///   DWORD  dwOutQueue
/// );
/// ```
/// {@category kernel32}
int SetupComm(int hFile, int dwInQueue, int dwOutQueue) =>
    _SetupComm(hFile, dwInQueue, dwOutQueue);

final _SetupComm = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Uint32 dwInQueue, Uint32 dwOutQueue),
    int Function(int hFile, int dwInQueue, int dwOutQueue)>('SetupComm');

/// Sets the label of a file system volume.
///
/// ```c
/// BOOL SetVolumeLabelW(
///   LPCWSTR lpRootPathName,
///   LPCWSTR lpVolumeName);
/// ```
/// {@category kernel32}
int SetVolumeLabel(
        Pointer<Utf16> lpRootPathName, Pointer<Utf16> lpVolumeName) =>
    _SetVolumeLabel(lpRootPathName, lpVolumeName);

final _SetVolumeLabel = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpRootPathName, Pointer<Utf16> lpVolumeName),
    int Function(Pointer<Utf16> lpRootPathName,
        Pointer<Utf16> lpVolumeName)>('SetVolumeLabelW');

/// Retrieves the size, in bytes, of the specified resource.
///
/// ```c
/// DWORD SizeofResource(
///   [in, optional] HMODULE hModule,
///   [in]           HRSRC   hResInfo
/// );
/// ```
/// {@category kernel32}
int SizeofResource(int hModule, int hResInfo) =>
    _SizeofResource(hModule, hResInfo);

final _SizeofResource = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hModule, IntPtr hResInfo),
    int Function(int hModule, int hResInfo)>('SizeofResource');

/// Suspends the execution of the current thread until the time-out interval
/// elapses.
///
/// ```c
/// void Sleep(
///   DWORD dwMilliseconds
/// );
/// ```
/// {@category kernel32}
void Sleep(int dwMilliseconds) => _Sleep(dwMilliseconds);

final _Sleep = _kernel32.lookupFunction<Void Function(Uint32 dwMilliseconds),
    void Function(int dwMilliseconds)>('Sleep');

/// Suspends the current thread until the specified condition is met.
/// Execution resumes when one of the following occurs: (i) an I/O
/// completion callback function is called; (ii) an asynchronous procedure
/// call (APC) is queued to the thread; (iii) the time-out interval elapses.
///
/// ```c
/// DWORD SleepEx(
///   DWORD dwMilliseconds,
///   BOOL  bAlertable
/// );
/// ```
/// {@category kernel32}
int SleepEx(int dwMilliseconds, int bAlertable) =>
    _SleepEx(dwMilliseconds, bAlertable);

final _SleepEx = _kernel32.lookupFunction<
    Uint32 Function(Uint32 dwMilliseconds, Int32 bAlertable),
    int Function(int dwMilliseconds, int bAlertable)>('SleepEx');

/// Converts a system time to file time format. System time is based on
/// Coordinated Universal Time (UTC).
///
/// ```c
/// BOOL SystemTimeToFileTime(
///   const SYSTEMTIME *lpSystemTime,
///   LPFILETIME       lpFileTime
/// );
/// ```
/// {@category kernel32}
int SystemTimeToFileTime(
        Pointer<SYSTEMTIME> lpSystemTime, Pointer<FILETIME> lpFileTime) =>
    _SystemTimeToFileTime(lpSystemTime, lpFileTime);

final _SystemTimeToFileTime = _kernel32.lookupFunction<
    Int32 Function(
        Pointer<SYSTEMTIME> lpSystemTime, Pointer<FILETIME> lpFileTime),
    int Function(Pointer<SYSTEMTIME> lpSystemTime,
        Pointer<FILETIME> lpFileTime)>('SystemTimeToFileTime');

/// Terminates the specified process and all of its threads.
///
/// ```c
/// BOOL TerminateProcess(
///   HANDLE hProcess,
///   UINT   uExitCode);
/// ```
/// {@category kernel32}
int TerminateProcess(int hProcess, int uExitCode) =>
    _TerminateProcess(hProcess, uExitCode);

final _TerminateProcess = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint32 uExitCode),
    int Function(int hProcess, int uExitCode)>('TerminateProcess');

/// Terminates a thread.
///
/// ```c
/// BOOL TerminateThread(
///   HANDLE hThread,
///   DWORD  dwExitCode
/// );
/// ```
/// {@category kernel32}
int TerminateThread(int hThread, int dwExitCode) =>
    _TerminateThread(hThread, dwExitCode);

final _TerminateThread = _kernel32.lookupFunction<
    Int32 Function(IntPtr hThread, Uint32 dwExitCode),
    int Function(int hThread, int dwExitCode)>('TerminateThread');

/// Combines the functions that write a message to and read a message from
/// the specified named pipe into a single network operation.
///
/// ```c
/// BOOL TransactNamedPipe(
///   HANDLE       hNamedPipe,
///   LPVOID       lpInBuffer,
///   DWORD        nInBufferSize,
///   LPVOID       lpOutBuffer,
///   DWORD        nOutBufferSize,
///   LPDWORD      lpBytesRead,
///   LPOVERLAPPED lpOverlapped);
/// ```
/// {@category kernel32}
int TransactNamedPipe(
        int hNamedPipe,
        Pointer lpInBuffer,
        int nInBufferSize,
        Pointer lpOutBuffer,
        int nOutBufferSize,
        Pointer<Uint32> lpBytesRead,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _TransactNamedPipe(hNamedPipe, lpInBuffer, nInBufferSize, lpOutBuffer,
        nOutBufferSize, lpBytesRead, lpOverlapped);

final _TransactNamedPipe = _kernel32.lookupFunction<
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

/// Transmits a specified character ahead of any pending data in the output
/// buffer of the specified communications device.
///
/// ```c
/// BOOL TransmitCommChar(
///   HANDLE hFile,
///   char   cChar
/// );
/// ```
/// {@category kernel32}
int TransmitCommChar(int hFile, int cChar) => _TransmitCommChar(hFile, cChar);

final _TransmitCommChar = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Uint8 cChar),
    int Function(int hFile, int cChar)>('TransmitCommChar');

/// Unlocks a region in an open file. Unlocking a region enables other
/// processes to access the region.
///
/// ```c
/// BOOL UnlockFile(
///   [in] HANDLE hFile,
///   [in] DWORD  dwFileOffsetLow,
///   [in] DWORD  dwFileOffsetHigh,
///   [in] DWORD  nNumberOfBytesToUnlockLow,
///   [in] DWORD  nNumberOfBytesToUnlockHigh
/// );
/// ```
/// {@category kernel32}
int UnlockFile(int hFile, int dwFileOffsetLow, int dwFileOffsetHigh,
        int nNumberOfBytesToUnlockLow, int nNumberOfBytesToUnlockHigh) =>
    _UnlockFile(hFile, dwFileOffsetLow, dwFileOffsetHigh,
        nNumberOfBytesToUnlockLow, nNumberOfBytesToUnlockHigh);

final _UnlockFile = _kernel32.lookupFunction<
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

/// Unlocks a region in the specified file. This function can operate either
/// synchronously or asynchronously.
///
/// ```c
/// BOOL UnlockFileEx(
///   [in]      HANDLE       hFile,
///             DWORD        dwReserved,
///   [in]      DWORD        nNumberOfBytesToUnlockLow,
///   [in]      DWORD        nNumberOfBytesToUnlockHigh,
///   [in, out] LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int UnlockFileEx(int hFile, int dwReserved, int nNumberOfBytesToUnlockLow,
        int nNumberOfBytesToUnlockHigh, Pointer<OVERLAPPED> lpOverlapped) =>
    _UnlockFileEx(hFile, dwReserved, nNumberOfBytesToUnlockLow,
        nNumberOfBytesToUnlockHigh, lpOverlapped);

final _UnlockFileEx = _kernel32.lookupFunction<
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

/// Updates the specified attribute in a list of attributes for process and
/// thread creation.
///
/// ```c
/// BOOL UpdateProcThreadAttribute(
///   LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList,
///   DWORD                        dwFlags,
///   DWORD_PTR                    Attribute,
///   PVOID                        lpValue,
///   SIZE_T                       cbSize,
///   PVOID                        lpPreviousValue,
///   PSIZE_T                      lpReturnSize
/// );
/// ```
/// {@category kernel32}
int UpdateProcThreadAttribute(
        Pointer lpAttributeList,
        int dwFlags,
        int Attribute,
        Pointer lpValue,
        int cbSize,
        Pointer lpPreviousValue,
        Pointer<IntPtr> lpReturnSize) =>
    _UpdateProcThreadAttribute(lpAttributeList, dwFlags, Attribute, lpValue,
        cbSize, lpPreviousValue, lpReturnSize);

final _UpdateProcThreadAttribute = _kernel32.lookupFunction<
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

/// Adds, deletes, or replaces a resource in a portable executable (PE)
/// file.
///
/// ```c
/// BOOL UpdateResourceW(
///   HANDLE  hUpdate,
///   LPCWSTR lpType,
///   LPCWSTR lpName,
///   WORD    wLanguage,
///   LPVOID  lpData,
///   DWORD   cb
/// );
/// ```
/// {@category kernel32}
int UpdateResource(int hUpdate, Pointer<Utf16> lpType, Pointer<Utf16> lpName,
        int wLanguage, Pointer lpData, int cb) =>
    _UpdateResource(hUpdate, lpType, lpName, wLanguage, lpData, cb);

final _UpdateResource = _kernel32.lookupFunction<
    Int32 Function(IntPtr hUpdate, Pointer<Utf16> lpType, Pointer<Utf16> lpName,
        Uint16 wLanguage, Pointer lpData, Uint32 cb),
    int Function(int hUpdate, Pointer<Utf16> lpType, Pointer<Utf16> lpName,
        int wLanguage, Pointer lpData, int cb)>('UpdateResourceW');

/// Compares a set of operating system version requirements to the
/// corresponding values for the currently running version of the system.
/// This function is subject to manifest-based behavior.
///
/// ```c
/// BOOL VerifyVersionInfoW(
///   [in] LPOSVERSIONINFOEXW lpVersionInformation,
///   [in] DWORD              dwTypeMask,
///   [in] DWORDLONG          dwlConditionMask
/// );
/// ```
/// {@category kernel32}
int VerifyVersionInfo(Pointer<OSVERSIONINFOEX> lpVersionInformation,
        int dwTypeMask, int dwlConditionMask) =>
    _VerifyVersionInfo(lpVersionInformation, dwTypeMask, dwlConditionMask);

final _VerifyVersionInfo = _kernel32.lookupFunction<
    Int32 Function(Pointer<OSVERSIONINFOEX> lpVersionInformation,
        Uint32 dwTypeMask, Uint64 dwlConditionMask),
    int Function(Pointer<OSVERSIONINFOEX> lpVersionInformation, int dwTypeMask,
        int dwlConditionMask)>('VerifyVersionInfoW');

/// Retrieves a description string for the language associated with a
/// specified binary Microsoft language identifier.
///
/// ```c
/// DWORD VerLanguageNameW(
///   DWORD  wLang,
///   LPWSTR szLang,
///   DWORD  cchLang
/// );
/// ```
/// {@category kernel32}
int VerLanguageName(int wLang, Pointer<Utf16> szLang, int cchLang) =>
    _VerLanguageName(wLang, szLang, cchLang);

final _VerLanguageName = _kernel32.lookupFunction<
    Uint32 Function(Uint32 wLang, Pointer<Utf16> szLang, Uint32 cchLang),
    int Function(
        int wLang, Pointer<Utf16> szLang, int cchLang)>('VerLanguageNameW');

/// Sets the bits of a 64-bit value to indicate the comparison operator to
/// use for a specified operating system version attribute. This function is
/// used to build the dwlConditionMask parameter of the VerifyVersionInfo
/// function.
///
/// ```c
/// ULONGLONG VerSetConditionMask(
/// [in] ULONGLONG ConditionMask,
/// [in] DWORD     TypeMask,
/// [in] BYTE      Condition
/// );
/// ```
/// {@category kernel32}
int VerSetConditionMask(int ConditionMask, int TypeMask, int Condition) =>
    _VerSetConditionMask(ConditionMask, TypeMask, Condition);

final _VerSetConditionMask = _kernel32.lookupFunction<
    Uint64 Function(Uint64 ConditionMask, Uint32 TypeMask, Uint8 Condition),
    int Function(
        int ConditionMask, int TypeMask, int Condition)>('VerSetConditionMask');

/// Reserves, commits, or changes the state of a region of pages in the
/// virtual address space of the calling process. Memory allocated by this
/// function is automatically initialized to zero.
///
/// ```c
/// LPVOID VirtualAlloc(
///   LPVOID lpAddress,
///   SIZE_T dwSize,
///   DWORD  flAllocationType,
///   DWORD  flProtect
/// );
/// ```
/// {@category kernel32}
Pointer VirtualAlloc(
        Pointer lpAddress, int dwSize, int flAllocationType, int flProtect) =>
    _VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect);

final _VirtualAlloc = _kernel32.lookupFunction<
    Pointer Function(Pointer lpAddress, IntPtr dwSize, Uint32 flAllocationType,
        Uint32 flProtect),
    Pointer Function(Pointer lpAddress, int dwSize, int flAllocationType,
        int flProtect)>('VirtualAlloc');

/// Reserves, commits, or changes the state of a region of memory within the
/// virtual address space of a specified process. The function initializes
/// the memory it allocates to zero.
///
/// ```c
/// LPVOID VirtualAllocEx(
///   HANDLE hProcess,
///   LPVOID lpAddress,
///   SIZE_T dwSize,
///   DWORD  flAllocationType,
///   DWORD  flProtect
/// );
/// ```
/// {@category kernel32}
Pointer VirtualAllocEx(int hProcess, Pointer lpAddress, int dwSize,
        int flAllocationType, int flProtect) =>
    _VirtualAllocEx(hProcess, lpAddress, dwSize, flAllocationType, flProtect);

final _VirtualAllocEx = _kernel32.lookupFunction<
    Pointer Function(IntPtr hProcess, Pointer lpAddress, IntPtr dwSize,
        Uint32 flAllocationType, Uint32 flProtect),
    Pointer Function(int hProcess, Pointer lpAddress, int dwSize,
        int flAllocationType, int flProtect)>('VirtualAllocEx');

/// Releases, decommits, or releases and decommits a region of pages within
/// the virtual address space of the calling process.
///
/// ```c
/// BOOL VirtualFree(
///   LPVOID lpAddress,
///   SIZE_T dwSize,
///   DWORD  dwFreeType
/// );
/// ```
/// {@category kernel32}
int VirtualFree(Pointer lpAddress, int dwSize, int dwFreeType) =>
    _VirtualFree(lpAddress, dwSize, dwFreeType);

final _VirtualFree = _kernel32.lookupFunction<
    Int32 Function(Pointer lpAddress, IntPtr dwSize, Uint32 dwFreeType),
    int Function(Pointer lpAddress, int dwSize, int dwFreeType)>('VirtualFree');

/// Releases, decommits, or releases and decommits a region of memory within
/// the virtual address space of a specified process.
///
/// ```c
/// BOOL VirtualFreeEx(
///   HANDLE hProcess,
///   LPVOID lpAddress,
///   SIZE_T dwSize,
///   DWORD  dwFreeType
/// );
/// ```
/// {@category kernel32}
int VirtualFreeEx(
        int hProcess, Pointer lpAddress, int dwSize, int dwFreeType) =>
    _VirtualFreeEx(hProcess, lpAddress, dwSize, dwFreeType);

final _VirtualFreeEx = _kernel32.lookupFunction<
    Int32 Function(
        IntPtr hProcess, Pointer lpAddress, IntPtr dwSize, Uint32 dwFreeType),
    int Function(int hProcess, Pointer lpAddress, int dwSize,
        int dwFreeType)>('VirtualFreeEx');

/// Locks the specified region of the process's virtual address space into
/// physical memory, ensuring that subsequent access to the region will not
/// incur a page fault.
///
/// ```c
/// BOOL VirtualLock(
///   LPVOID lpAddress,
///   SIZE_T dwSize
/// );
/// ```
/// {@category kernel32}
int VirtualLock(Pointer lpAddress, int dwSize) =>
    _VirtualLock(lpAddress, dwSize);

final _VirtualLock = _kernel32.lookupFunction<
    Int32 Function(Pointer lpAddress, IntPtr dwSize),
    int Function(Pointer lpAddress, int dwSize)>('VirtualLock');

/// Unlocks a specified range of pages in the virtual address space of a
/// process, enabling the system to swap the pages out to the paging file if
/// necessary.
///
/// ```c
/// BOOL VirtualUnlock(
///   LPVOID lpAddress,
///   SIZE_T dwSize
/// );
/// ```
/// {@category kernel32}
int VirtualUnlock(Pointer lpAddress, int dwSize) =>
    _VirtualUnlock(lpAddress, dwSize);

final _VirtualUnlock = _kernel32.lookupFunction<
    Int32 Function(Pointer lpAddress, IntPtr dwSize),
    int Function(Pointer lpAddress, int dwSize)>('VirtualUnlock');

/// Waits for an event to occur for a specified communications device. The
/// set of events that are monitored by this function is contained in the
/// event mask associated with the device handle.
///
/// ```c
/// BOOL WaitCommEvent(
///   HANDLE       hFile,
///   LPDWORD      lpEvtMask,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int WaitCommEvent(int hFile, Pointer<Uint32> lpEvtMask,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _WaitCommEvent(hFile, lpEvtMask, lpOverlapped);

final _WaitCommEvent = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Pointer<Uint32> lpEvtMask,
        Pointer<OVERLAPPED> lpOverlapped),
    int Function(int hFile, Pointer<Uint32> lpEvtMask,
        Pointer<OVERLAPPED> lpOverlapped)>('WaitCommEvent');

/// Waits until the specified object is in the signaled state or the
/// time-out interval elapses.
///
/// ```c
/// DWORD WaitForSingleObject(
///   HANDLE hHandle,
///   DWORD  dwMilliseconds
/// );
/// ```
/// {@category kernel32}
int WaitForSingleObject(int hHandle, int dwMilliseconds) =>
    _WaitForSingleObject(hHandle, dwMilliseconds);

final _WaitForSingleObject = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hHandle, Uint32 dwMilliseconds),
    int Function(int hHandle, int dwMilliseconds)>('WaitForSingleObject');

/// Maps a UTF-16 (wide character) string to a new character string. The new
/// character string is not necessarily from a multibyte character set.
///
/// ```c
/// int WideCharToMultiByte(
///   UINT   CodePage,
///   DWORD  dwFlags,
///   LPCWCH lpWideCharStr,
///   int    cchWideChar,
///   LPSTR  lpMultiByteStr,
///   int    cbMultiByte,
///   LPCCH  lpDefaultChar,
///   LPBOOL lpUsedDefaultChar
/// );
/// ```
/// {@category kernel32}
int WideCharToMultiByte(
        int CodePage,
        int dwFlags,
        Pointer<Utf16> lpWideCharStr,
        int cchWideChar,
        Pointer<Utf8> lpMultiByteStr,
        int cbMultiByte,
        Pointer<Utf8> lpDefaultChar,
        Pointer<Int32> lpUsedDefaultChar) =>
    _WideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar,
        lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUsedDefaultChar);

final _WideCharToMultiByte = _kernel32.lookupFunction<
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

/// Suspends the specified WOW64 thread.
///
/// ```c
/// DWORD Wow64SuspendThread(
///   HANDLE hThread
/// );
/// ```
/// {@category kernel32}
int Wow64SuspendThread(int hThread) => _Wow64SuspendThread(hThread);

final _Wow64SuspendThread = _kernel32.lookupFunction<
    Uint32 Function(IntPtr hThread),
    int Function(int hThread)>('Wow64SuspendThread');

/// Writes a character string to a console screen buffer beginning at the
/// current cursor location.
///
/// ```c
/// BOOL WriteConsoleW(
///   _In_             HANDLE  hConsoleOutput,
///   _In_       const VOID    *lpBuffer,
///   _In_             DWORD   nNumberOfCharsToWrite,
///   _Out_opt_        LPDWORD lpNumberOfCharsWritten,
///   _Reserved_       LPVOID  lpReserved
/// );
/// ```
/// {@category kernel32}
int WriteConsole(
        int hConsoleOutput,
        Pointer lpBuffer,
        int nNumberOfCharsToWrite,
        Pointer<Uint32> lpNumberOfCharsWritten,
        Pointer lpReserved) =>
    _WriteConsole(hConsoleOutput, lpBuffer, nNumberOfCharsToWrite,
        lpNumberOfCharsWritten, lpReserved);

final _WriteConsole = _kernel32.lookupFunction<
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

/// Writes data to the specified file or input/output (I/O) device.
///
/// ```c
/// BOOL WriteFile(
///   HANDLE       hFile,
///   LPCVOID      lpBuffer,
///   DWORD        nNumberOfBytesToWrite,
///   LPDWORD      lpNumberOfBytesWritten,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int WriteFile(
        int hFile,
        Pointer lpBuffer,
        int nNumberOfBytesToWrite,
        Pointer<Uint32> lpNumberOfBytesWritten,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten,
        lpOverlapped);

final _WriteFile = _kernel32.lookupFunction<
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

/// Writes data to the specified file or input/output (I/O) device. It
/// reports its completion status asynchronously, calling the specified
/// completion routine when writing is completed or canceled and the calling
/// thread is in an alertable wait state.
///
/// ```c
/// BOOL WriteFileEx(
///   [in]           HANDLE                          hFile,
///   [in, optional] LPCVOID                         lpBuffer,
///   [in]           DWORD                           nNumberOfBytesToWrite,
///   [in, out]      LPOVERLAPPED                    lpOverlapped,
///   [in]           LPOVERLAPPED_COMPLETION_ROUTINE lpCompletionRoutine
/// );
/// ```
/// {@category kernel32}
int WriteFileEx(
        int hFile,
        Pointer lpBuffer,
        int nNumberOfBytesToWrite,
        Pointer<OVERLAPPED> lpOverlapped,
        Pointer<NativeFunction<LpoverlappedCompletionRoutine>>
            lpCompletionRoutine) =>
    _WriteFileEx(hFile, lpBuffer, nNumberOfBytesToWrite, lpOverlapped,
        lpCompletionRoutine);

final _WriteFileEx = _kernel32.lookupFunction<
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

/// Retrieves data from an array of buffers and writes the data to a file.
/// The function starts writing data to the file at a position that is
/// specified by an OVERLAPPED structure. The WriteFileGather function
/// operates asynchronously.
///
/// ```c
/// BOOL WriteFileGather(
///   [in]      HANDLE                  hFile,
///   [in]      FILE_SEGMENT_ELEMENT [] aSegmentArray,
///   [in]      DWORD                   nNumberOfBytesToWrite,
///             LPDWORD                 lpReserved,
///   [in, out] LPOVERLAPPED            lpOverlapped
/// );
/// ```
/// {@category kernel32}
int WriteFileGather(
        int hFile,
        Pointer<FILE_SEGMENT_ELEMENT> aSegmentArray,
        int nNumberOfBytesToWrite,
        Pointer<Uint32> lpReserved,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _WriteFileGather(
        hFile, aSegmentArray, nNumberOfBytesToWrite, lpReserved, lpOverlapped);

final _WriteFileGather = _kernel32.lookupFunction<
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

/// Writes data to an area of memory in a specified process. The entire area
/// to be written to must be accessible or the operation fails.
///
/// ```c
/// BOOL WriteProcessMemory(
///   HANDLE  hProcess,
///   LPVOID  lpBaseAddress,
///   LPCVOID lpBuffer,
///   SIZE_T  nSize,
///   SIZE_T  *lpNumberOfBytesWritten
/// );
/// ```
/// {@category kernel32}
int WriteProcessMemory(int hProcess, Pointer lpBaseAddress, Pointer lpBuffer,
        int nSize, Pointer<IntPtr> lpNumberOfBytesWritten) =>
    _WriteProcessMemory(
        hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesWritten);

final _WriteProcessMemory = _kernel32.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer lpBaseAddress, Pointer lpBuffer,
        IntPtr nSize, Pointer<IntPtr> lpNumberOfBytesWritten),
    int Function(
        int hProcess,
        Pointer lpBaseAddress,
        Pointer lpBuffer,
        int nSize,
        Pointer<IntPtr> lpNumberOfBytesWritten)>('WriteProcessMemory');
