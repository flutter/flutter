// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'callbacks.dart';
import 'combase.dart';
import 'guid.dart';
import 'structs.dart';
import 'structs.g.dart';

final _spoolss = DynamicLibrary.open('spoolss.dll');

/// The AbortPrinter function deletes a printer's spool file if the printer
/// is configured for spooling.
///
/// ```c
/// BOOL AbortPrinter(
///   _In_ HANDLE hPrinter
/// );
/// ```
/// {@category winspool}
int AbortPrinter(int hPrinter) => _AbortPrinter(hPrinter);

final _AbortPrinter = _spoolss.lookupFunction<Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('AbortPrinter');

/// The AddForm function adds a form to the list of available forms that
/// can be selected for the specified printer.
///
/// ```c
/// BOOL AddFormW(
///   _In_ HANDLE hPrinter,
///   _In_ DWORD  Level,
///   _In_ LPBYTE pForm
/// );
/// ```
/// {@category winspool}
int AddForm(int hPrinter, int Level, Pointer<Uint8> pForm) =>
    _AddForm(hPrinter, Level, pForm);

final _AddForm = _spoolss.lookupFunction<
    Int32 Function(IntPtr hPrinter, Uint32 Level, Pointer<Uint8> pForm),
    int Function(int hPrinter, int Level, Pointer<Uint8> pForm)>('AddFormW');

/// The ClosePrinter function closes the specified printer object.
///
/// ```c
/// BOOL ClosePrinter(
///   _In_ HANDLE hPrinter
///   );
/// ```
/// {@category winspool}
int ClosePrinter(int hPrinter) => _ClosePrinter(hPrinter);

final _ClosePrinter = _spoolss.lookupFunction<Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('ClosePrinter');

/// The DeletePrinter function deletes the specified printer object.
///
/// ```c
/// BOOL DeletePrinter(
///   _Inout_ HANDLE hPrinter
/// );
/// ```
/// {@category winspool}
int DeletePrinter(int hPrinter) => _DeletePrinter(hPrinter);

final _DeletePrinter = _spoolss.lookupFunction<Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('DeletePrinter');

/// The EndDocPrinter function ends a print job for the specified printer.
///
/// ```c
/// BOOL EndDocPrinter(
///   _In_ HANDLE hPrinter
/// );
/// ```
/// {@category winspool}
int EndDocPrinter(int hPrinter) => _EndDocPrinter(hPrinter);

final _EndDocPrinter = _spoolss.lookupFunction<Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('EndDocPrinter');

/// The EndPagePrinter function notifies the print spooler that the
/// application is at the end of a page in a print job.
///
/// ```c
/// BOOL EndPagePrinter(
///   _In_ HANDLE hPrinter
/// );
/// ```
/// {@category winspool}
int EndPagePrinter(int hPrinter) => _EndPagePrinter(hPrinter);

final _EndPagePrinter = _spoolss.lookupFunction<Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('EndPagePrinter');

/// The FindClosePrinterChangeNotification function closes a change
/// notification object created by calling the
/// FindFirstPrinterChangeNotification function. The printer or print
/// server associated with the change notification object will no longer be
/// monitored by that object.
///
/// ```c
/// BOOL FindClosePrinterChangeNotification(
///   _In_ HANDLE hChange
/// );
/// ```
/// {@category winspool}
int FindClosePrinterChangeNotification(int hChange) =>
    _FindClosePrinterChangeNotification(hChange);

final _FindClosePrinterChangeNotification = _spoolss.lookupFunction<
    Int32 Function(IntPtr hChange),
    int Function(int hChange)>('FindClosePrinterChangeNotification');

/// Retrieves a handle to the specified printer, print server, or other
/// types of handles in the print subsystem, while setting some of the
/// printer options.
///
/// ```c
/// BOOL OpenPrinter2W(
///   _In_  LPCTSTR            pPrinterName,
///   _Out_ LPHANDLE           phPrinter,
///   _In_  LPPRINTER_DEFAULTS pDefault,
///   _In_  PPRINTER_OPTIONS   pOptions
/// );
/// ```
/// {@category winspool}
int OpenPrinter2(
        Pointer<Utf16> pPrinterName,
        Pointer<IntPtr> phPrinter,
        Pointer<PRINTER_DEFAULTS> pDefault,
        Pointer<PRINTER_OPTIONS> pOptions) =>
    _OpenPrinter2(pPrinterName, phPrinter, pDefault, pOptions);

final _OpenPrinter2 = _spoolss.lookupFunction<
    Int32 Function(Pointer<Utf16> pPrinterName, Pointer<IntPtr> phPrinter,
        Pointer<PRINTER_DEFAULTS> pDefault, Pointer<PRINTER_OPTIONS> pOptions),
    int Function(
        Pointer<Utf16> pPrinterName,
        Pointer<IntPtr> phPrinter,
        Pointer<PRINTER_DEFAULTS> pDefault,
        Pointer<PRINTER_OPTIONS> pOptions)>('OpenPrinter2W');

/// The ReadPrinter function retrieves data from the specified printer.
///
/// ```c
/// BOOL ReadPrinter(
///   _In_  HANDLE  hPrinter,
///   _Out_ LPVOID  pBuf,
///   _In_  DWORD   cbBuf,
///   _Out_ LPDWORD pNoBytesRead
/// );
/// ```
/// {@category winspool}
int ReadPrinter(
        int hPrinter, Pointer pBuf, int cbBuf, Pointer<Uint32> pNoBytesRead) =>
    _ReadPrinter(hPrinter, pBuf, cbBuf, pNoBytesRead);

final _ReadPrinter = _spoolss.lookupFunction<
    Int32 Function(IntPtr hPrinter, Pointer pBuf, Uint32 cbBuf,
        Pointer<Uint32> pNoBytesRead),
    int Function(int hPrinter, Pointer pBuf, int cbBuf,
        Pointer<Uint32> pNoBytesRead)>('ReadPrinter');

/// Reports to the Print Spooler service whether an XPS print job is in the
/// spooling or the rendering phase and what part of the processing is
/// currently underway.
///
/// ```c
/// HRESULT ReportJobProcessingProgress(
///   _In_ HANDLE                printerHandle,
///   _In_ ULONG                 jobId,
///        EPrintXPSJobOperation jobOperation,
///        EPrintXPSJobProgress  jobProgress
/// );
/// ```
/// {@category winspool}
int ReportJobProcessingProgress(
        int printerHandle, int jobId, int jobOperation, int jobProgress) =>
    _ReportJobProcessingProgress(
        printerHandle, jobId, jobOperation, jobProgress);

final _ReportJobProcessingProgress = _spoolss.lookupFunction<
    Int32 Function(IntPtr printerHandle, Uint32 jobId, Int32 jobOperation,
        Int32 jobProgress),
    int Function(int printerHandle, int jobId, int jobOperation,
        int jobProgress)>('ReportJobProcessingProgress');

/// The ScheduleJob function requests that the print spooler schedule a
/// specified print job for printing.
///
/// ```c
/// BOOL ScheduleJob(
///   _In_ HANDLE hPrinter,
///   _In_ DWORD  dwJobID
/// );
/// ```
/// {@category winspool}
int ScheduleJob(int hPrinter, int JobId) => _ScheduleJob(hPrinter, JobId);

final _ScheduleJob = _spoolss.lookupFunction<
    Int32 Function(IntPtr hPrinter, Uint32 JobId),
    int Function(int hPrinter, int JobId)>('ScheduleJob');

/// The StartPagePrinter function notifies the spooler that a page is about
/// to be printed on the specified printer.
///
/// ```c
/// BOOL StartPagePrinter(
///   _In_ HANDLE hPrinter
/// );
/// ```
/// {@category winspool}
int StartPagePrinter(int hPrinter) => _StartPagePrinter(hPrinter);

final _StartPagePrinter = _spoolss.lookupFunction<
    Int32 Function(IntPtr hPrinter),
    int Function(int hPrinter)>('StartPagePrinter');

/// The WritePrinter function notifies the print spooler that data should
/// be written to the specified printer.
///
/// ```c
/// BOOL WritePrinter(
///   _In_  HANDLE  hPrinter,
///   _In_  LPVOID  pBuf,
///   _In_  DWORD   cbBuf,
///   _Out_ LPDWORD pcWritten
/// );
/// ```
/// {@category winspool}
int WritePrinter(
        int hPrinter, Pointer pBuf, int cbBuf, Pointer<Uint32> pcWritten) =>
    _WritePrinter(hPrinter, pBuf, cbBuf, pcWritten);

final _WritePrinter = _spoolss.lookupFunction<
    Int32 Function(
        IntPtr hPrinter, Pointer pBuf, Uint32 cbBuf, Pointer<Uint32> pcWritten),
    int Function(int hPrinter, Pointer pBuf, int cbBuf,
        Pointer<Uint32> pcWritten)>('WritePrinter');
