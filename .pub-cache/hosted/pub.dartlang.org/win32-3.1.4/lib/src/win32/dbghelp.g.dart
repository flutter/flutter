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

final _dbghelp = DynamicLibrary.open('dbghelp.dll');

/// Deallocates all resources associated with the process handle.
///
/// ```c
/// BOOL SymCleanup(
///   HANDLE hProcess);
/// ```
/// {@category dbghelp}
int SymCleanup(int hProcess) => _SymCleanup(hProcess);

final _SymCleanup = _dbghelp.lookupFunction<Int32 Function(IntPtr hProcess),
    int Function(int hProcess)>('SymCleanup');

/// Enumerates all symbols in a process.
///
/// ```c
/// BOOL SymEnumSymbolsW(
///   HANDLE                          hProcess,
///   ULONG64                         BaseOfDll,
///   PCWSTR                          Mask,
///   PSYM_ENUMERATESYMBOLS_CALLBACKW EnumSymbolsCallback,
///   PVOID                           UserContext
/// );
/// ```
/// {@category dbghelp}
int SymEnumSymbols(
        int hProcess,
        int BaseOfDll,
        Pointer<Utf16> Mask,
        Pointer<NativeFunction<SymEnumSymbolsProc>> EnumSymbolsCallback,
        Pointer UserContext) =>
    _SymEnumSymbols(
        hProcess, BaseOfDll, Mask, EnumSymbolsCallback, UserContext);

final _SymEnumSymbols = _dbghelp.lookupFunction<
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

/// Retrieves symbol information for the specified address.
///
/// ```c
/// BOOL SymFromAddrW(
///   HANDLE        hProcess,
///   DWORD64       Address,
///   PDWORD64      Displacement,
///   PSYMBOL_INFOW Symbol
/// );
/// ```
/// {@category dbghelp}
int SymFromAddr(int hProcess, int Address, Pointer<Uint64> Displacement,
        Pointer<SYMBOL_INFO> Symbol) =>
    _SymFromAddr(hProcess, Address, Displacement, Symbol);

final _SymFromAddr = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 Address,
        Pointer<Uint64> Displacement, Pointer<SYMBOL_INFO> Symbol),
    int Function(int hProcess, int Address, Pointer<Uint64> Displacement,
        Pointer<SYMBOL_INFO> Symbol)>('SymFromAddrW');

/// Retrieves symbol information for the specified managed code token.
///
/// ```c
/// BOOL SymFromTokenW(
///   HANDLE        hProcess,
///   DWORD64       Base,
///   DWORD         Token,
///   PSYMBOL_INFOW Symbol
/// );
/// ```
/// {@category dbghelp}
int SymFromToken(
        int hProcess, int Base, int Token, Pointer<SYMBOL_INFO> Symbol) =>
    _SymFromToken(hProcess, Base, Token, Symbol);

final _SymFromToken = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 Base, Uint32 Token,
        Pointer<SYMBOL_INFO> Symbol),
    int Function(int hProcess, int Base, int Token,
        Pointer<SYMBOL_INFO> Symbol)>('SymFromTokenW');

/// Gets whether the specified extended symbol option on or off.
///
/// ```c
/// BOOL SymGetExtendedOption(
///   IMAGEHLP_EXTENDED_OPTIONS option
/// );
/// ```
/// {@category dbghelp}
int SymGetExtendedOption(int option) => _SymGetExtendedOption(option);

final _SymGetExtendedOption = _dbghelp.lookupFunction<
    Int32 Function(Int32 option),
    int Function(int option)>('SymGetExtendedOption');

/// Initializes the symbol handler for a process.
///
/// ```c
/// BOOL SymInitializeW(
///   HANDLE hProcess,
///   PCWSTR UserSearchPath,
///   BOOL   fInvadeProcess
/// );
/// ```
/// {@category dbghelp}
int SymInitialize(
        int hProcess, Pointer<Utf16> UserSearchPath, int fInvadeProcess) =>
    _SymInitialize(hProcess, UserSearchPath, fInvadeProcess);

final _SymInitialize = _dbghelp.lookupFunction<
    Int32 Function(
        IntPtr hProcess, Pointer<Utf16> UserSearchPath, Int32 fInvadeProcess),
    int Function(int hProcess, Pointer<Utf16> UserSearchPath,
        int fInvadeProcess)>('SymInitializeW');

/// Loads the symbol table for the specified module.
///
/// ```c
/// DWORD64 SymLoadModuleExW(
///   HANDLE        hProcess,
///   HANDLE        hFile,
///   PCWSTR        ImageName,
///   PCWSTR        ModuleName,
///   DWORD64       BaseOfDll,
///   DWORD         DllSize,
///   PMODLOAD_DATA Data,
///   DWORD         Flags);
/// ```
/// {@category dbghelp}
int SymLoadModuleEx(
        int hProcess,
        int hFile,
        Pointer<Utf16> ImageName,
        Pointer<Utf16> ModuleName,
        int BaseOfDll,
        int DllSize,
        Pointer<MODLOAD_DATA> Data,
        int Flags) =>
    _SymLoadModuleEx(hProcess, hFile, ImageName, ModuleName, BaseOfDll, DllSize,
        Data, Flags);

final _SymLoadModuleEx = _dbghelp.lookupFunction<
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

/// Turns the specified extended symbol option on or off.
///
/// ```c
/// BOOL SymSetExtendedOption(
///   IMAGEHLP_EXTENDED_OPTIONS option,
///   BOOL                      value
/// );
/// ```
/// {@category dbghelp}
int SymSetExtendedOption(int option, int value) =>
    _SymSetExtendedOption(option, value);

final _SymSetExtendedOption = _dbghelp.lookupFunction<
    Int32 Function(Int32 option, Int32 value),
    int Function(int option, int value)>('SymSetExtendedOption');

/// Sets the options mask.
///
/// ```c
/// DWORD SymSetOptions(
///   DWORD SymOptions
/// );
/// ```
/// {@category dbghelp}
int SymSetOptions(int SymOptions) => _SymSetOptions(SymOptions);

final _SymSetOptions = _dbghelp.lookupFunction<
    Uint32 Function(Uint32 SymOptions),
    int Function(int SymOptions)>('SymSetOptions');

/// Sets the window that the caller will use to display a user interface.
///
/// ```c
/// BOOL SymSetParentWindow(
///   HWND hwnd
/// );
/// ```
/// {@category dbghelp}
int SymSetParentWindow(int hwnd) => _SymSetParentWindow(hwnd);

final _SymSetParentWindow = _dbghelp.lookupFunction<Int32 Function(IntPtr hwnd),
    int Function(int hwnd)>('SymSetParentWindow');

/// Sets the local scope to the symbol that matches the specified address.
///
/// ```c
/// BOOL SymSetScopeFromAddr(
///   HANDLE  hProcess,
///   ULONG64 Address
/// );
/// ```
/// {@category dbghelp}
int SymSetScopeFromAddr(int hProcess, int Address) =>
    _SymSetScopeFromAddr(hProcess, Address);

final _SymSetScopeFromAddr = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 Address),
    int Function(int hProcess, int Address)>('SymSetScopeFromAddr');

/// Sets the local scope to the symbol that matches the specified index.
///
/// ```c
/// BOOL SymSetScopeFromIndex(
///   HANDLE  hProcess,
///   ULONG64 BaseOfDll,
///   DWORD   Index
/// );
/// ```
/// {@category dbghelp}
int SymSetScopeFromIndex(int hProcess, int BaseOfDll, int Index) =>
    _SymSetScopeFromIndex(hProcess, BaseOfDll, Index);

final _SymSetScopeFromIndex = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 BaseOfDll, Uint32 Index),
    int Function(
        int hProcess, int BaseOfDll, int Index)>('SymSetScopeFromIndex');

/// Sets the local scope to the symbol that matches the specified address
/// and inline context.
///
/// ```c
/// BOOL SymSetScopeFromInlineContext(
///   HANDLE  hProcess,
///   ULONG64 Address,
///   ULONG   InlineContext
/// );
/// ```
/// {@category dbghelp}
int SymSetScopeFromInlineContext(
        int hProcess, int Address, int InlineContext) =>
    _SymSetScopeFromInlineContext(hProcess, Address, InlineContext);

final _SymSetScopeFromInlineContext = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 Address, Uint32 InlineContext),
    int Function(int hProcess, int Address,
        int InlineContext)>('SymSetScopeFromInlineContext');

/// Sets the search path for the specified process.
///
/// ```c
/// BOOL SymSetSearchPathW(
///   HANDLE hProcess,
///   PCWSTR SearchPath
/// );
/// ```
/// {@category dbghelp}
int SymSetSearchPath(int hProcess, Pointer<Utf16> SearchPathA) =>
    _SymSetSearchPath(hProcess, SearchPathA);

final _SymSetSearchPath = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Pointer<Utf16> SearchPathA),
    int Function(
        int hProcess, Pointer<Utf16> SearchPathA)>('SymSetSearchPathW');

/// Unloads the symbol table.
///
/// ```c
/// BOOL SymUnloadModule(
///   HANDLE hProcess,
///   DWORD  BaseOfDll
/// );
/// ```
/// {@category dbghelp}
int SymUnloadModule(int hProcess, int BaseOfDll) =>
    _SymUnloadModule(hProcess, BaseOfDll);

final _SymUnloadModule = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint32 BaseOfDll),
    int Function(int hProcess, int BaseOfDll)>('SymUnloadModule');

/// Unloads the symbol table.
///
/// ```c
/// BOOL SymUnloadModule64(
///   HANDLE  hProcess,
///   DWORD64 BaseOfDll
/// );
/// ```
/// {@category dbghelp}
int SymUnloadModule64(int hProcess, int BaseOfDll) =>
    _SymUnloadModule64(hProcess, BaseOfDll);

final _SymUnloadModule64 = _dbghelp.lookupFunction<
    Int32 Function(IntPtr hProcess, Uint64 BaseOfDll),
    int Function(int hProcess, int BaseOfDll)>('SymUnloadModule64');

/// Undecorates the specified decorated C++ symbol name.
///
/// ```c
/// DWORD UnDecorateSymbolNameW(
///   PCWSTR name,
///   PWSTR  outputString,
///   DWORD  maxStringLength,
///   DWORD  flags
/// );
/// ```
/// {@category dbghelp}
int UnDecorateSymbolName(Pointer<Utf16> name, Pointer<Utf16> outputString,
        int maxStringLength, int flags) =>
    _UnDecorateSymbolName(name, outputString, maxStringLength, flags);

final _UnDecorateSymbolName = _dbghelp.lookupFunction<
    Uint32 Function(Pointer<Utf16> name, Pointer<Utf16> outputString,
        Uint32 maxStringLength, Uint32 flags),
    int Function(Pointer<Utf16> name, Pointer<Utf16> outputString,
        int maxStringLength, int flags)>('UnDecorateSymbolNameW');
