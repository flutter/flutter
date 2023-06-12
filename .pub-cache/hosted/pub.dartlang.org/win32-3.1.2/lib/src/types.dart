/// Simple data types that are commonly used as aliases for C/C++ primitive data
/// types in Win32 development.
///
/// These can be used for FFI pointer allocation, for example:
///
/// ```dart
/// final returnValue = calloc<DWORD>();
/// ```
///
/// For more on Windows data types, see
/// https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types.

// ignore_for_file: camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef ATOM = WORD;
typedef BOOL = Uint32;
typedef BOOLEAN = BYTE;
typedef BYTE = Uint8;
typedef CHAR = Uint8;
typedef COLORREF = DWORD;
typedef DOUBLE = Double;
typedef DWORD = Uint32;
typedef DWORD32 = Uint32;
typedef DWORD64 = Uint64;
typedef DWORDLONG = Uint64;
typedef DWORD_PTR = ULONG_PTR;
typedef FLOAT = Float;
typedef HANDLE = IntPtr;
typedef HCALL = DWORD;
typedef HDC = IntPtr;
typedef HINSTANCE = IntPtr;
typedef HKEY = IntPtr;
typedef HMIDIIN = IntPtr;
typedef HMODULE = IntPtr;
typedef HMONITOR = IntPtr;
typedef HRESULT = LONG;
typedef HRGN = IntPtr;
typedef HSTRING = IntPtr;
typedef HWND = IntPtr;
typedef INT = Int32;
typedef INT16 = Int16;
typedef INT32 = Int32;
typedef INT64 = Int64;
typedef INT8 = Int8;
typedef INT_PTR = IntPtr;
typedef LANGID = WORD;
typedef LCID = DWORD;
typedef LCTYPE = DWORD;
typedef LGRPID = DWORD;
typedef LONG = Int32;
typedef LONG32 = Int32;
typedef LONG64 = Int64;
typedef LONGLONG = Int64;
typedef LONG_PTR = IntPtr;
typedef LPARAM = LONG_PTR;
typedef LPSTR = Pointer<Utf8>;
typedef LPWSTR = Pointer<Utf16>;
typedef LRESULT = LONG_PTR;
typedef NTSTATUS = Int32;
typedef PSTR = Pointer<Utf8>;
typedef PWSTR = Pointer<Utf16>;
typedef QWORD = Uint64;
typedef SHORT = Int16;
typedef SIZE_T = ULONG_PTR;
typedef UCHAR = Uint8;
typedef UINT = Uint32;
typedef UINT16 = Uint16;
typedef UINT32 = Uint32;
typedef UINT64 = Uint64;
typedef UINT8 = Uint8;
typedef UINT_PTR = IntPtr;
typedef ULONG = Uint32;
typedef ULONG32 = Uint32;
typedef ULONG64 = Uint64;
typedef ULONGLONG = Uint64;
typedef ULONG_PTR = IntPtr;
typedef USHORT = Uint16;
typedef WCHAR = Uint16;
typedef WORD = Uint16;
typedef WPARAM = UINT_PTR;
