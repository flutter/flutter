## COM-based APIs

Windows APIs that use the COM invocation model.

Since the Win32 package primarily focuses on providing a lightweight wrapper for
the underlying Windows API primitives, you can use the same API calls as
described in Microsoft documentation to create an manipulate objects (e.g.
`CoCreateInstance` and `IUnknown->QueryInterface`). However, since this
introduces a certain amount of boilerplate and non-idiomatic Dart code, the
library also provides some helper functions that reduce the labor compared to a
pure C-style calling convention.

### Initializing the COM library

Before you call any COM functions, first initialize the COM library by calling
the `CoInitializeEx` function. Details of the threading models are outside the
scope of this document, but typically you should write something like:

```dart
final hr = CoInitializeEx(
    nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
if (FAILED(hr)) throw WindowsException(hr);
```

### Creating a COM object

You can create COM objects using the [C
library](https://docs.microsoft.com/en-us/windows/win32/learnwin32/creating-an-object-in-com):

```dart
hr = CoCreateInstance(clsid, nullptr, CLSCTX_INPROC_SERVER, iid, ppv);
```

However, rather than manually allocate GUID structs for the `clsid` and `iid`
values, checking the `hr` result code and deal with casting the `ppv` return
object, it is easier to use the `createFromID` static helper function:

```dart
final fileDialog2 = IFileDialog2(
  COMObject.createFromID(CLSID_FileOpenDialog, IID_IFileDialog2));
```

`createFromID` returns a `Pointer<COMObject>` containing the requested object,
which can then be cast into the appropriate interface as shown above. It is the
caller's responsibility to free the returned pointer when all interfaces that
derive from it are released.

### Asking a COM object for an interface

COM allows objects to implement multiple interfaces, but it does not let you
merely cast an object to a different interface. Instead, returned pointers are
to a specific interface. However, every COM interface in the Dart Win32 package
derives from `IUnknown`, so as in other language implementations of COM, you may
call `queryInterface` on any object to retrieve a pointer to a different
supported interface.

More information on COM interfaces may be found in the [Microsoft
documentation](https://docs.microsoft.com/en-us/windows/win32/learnwin32/asking-an-object-for-an-interface).

COM interfaces supply a method that wraps `queryInterface`. If you
have an existing COM object, you can call it as follows:

```dart
  final modalWindow = IModalWindow.from(fileDialog2);
```

Where `createFromID` creates a new COM object, `toInterface` casts an existing
COM object to a new interface. As with `createFromID`, it is the caller's
responsibility to free the returned pointer when all interfaces that derive from
it are released.

Attempting to cast a COM object to an interface it does not support will fail,
of course. A `WindowsException` will be thrown with an hr of `E_NOINTERFACE`.

### Calling a method on a COM object

No special considerations are needed here; however, it is wise to assign the
return value to a variable and test it for success or failure. You can use the
`SUCCEEDED()` or `FAILED()` top-level functions to do this, for example:

```dart
final hr = fileOpenDialog.show(NULL);
if (SUCCEEDED(hr)) {
  // Do something with the returned dialog box values
}
```

Failures are reported as `HRESULT` values (e.g. `E_ACCESSDENIED`). Sometimes a
Win32 error code is converted to an `HRESULT`, as in the case where a user
cancels a common dialog box:

```dart
final hr = fileOpenDialog.show(NULL);
if (FAILED(hr) && hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
  // User clicked cancel
}
```

### Releasing COM objects

When you have finished using a COM interface, you should release it with the `release` method:

```dart
fileOpenDialog.release(); // Release the interface
free(fileOpenDialog.ptr); // Release the pointer to the interface
```

Often this will be called as part of a `try` / `finally` block, to guarantee
that the object is released even if an exception is thrown.

### Unloading COM support

When you have finished using COM, you should uninitialize it with the
following call:

```dart
CoUninitialize();
```

A full example of these calls can be found in the `com_demo.dart` file in the
`example\` subfolder.
