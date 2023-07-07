## Windows Runtime API

The Windows Runtime (WinRT) is a suite of APIs and architectural model,
introduced in Windows 8, that powers the latest generation of Windows APIs. It
is an evolution of the COM API that is designed for access from a variety of
languages. WinRT introduces standardized interfaces for collections (e.g.
`IVectorView`), as well as support for generic types and asynchronous
programming models.

### Initializing the Windows Runtime

All threads that activate and interact with Windows Runtime objects must be
initialized prior to calling into the Windows Runtime. This package provides the
[winrtInitialize] helper function to do this. Call the matching
[winrtUninitialize] function to close the Windows Runtime on the current thread.
A successful call to `winrtInitialize` should be balanced with a corresponding
call to `winrtUninitialize`.

### Instantiating Windows Runtime objects

The [CreateObject] function provides a convenient way to create a new Windows
Runtime object. This returns a generic `Pointer<COMObject>`, which can be cast
to the object type desired. For example:

```dart
final comObject = CreateObject('Windows.Globalization.Calendar', IID_ICalendar);
final calendar = ICalendar(comObject);
```

The object should be disposed of when it is no longer in use, for example:

```dart
free(calendar.ptr);
```

### Strings (Windows Runtime)

Windows Runtime APIs use `HSTRING` as their native type. An HSTRING is an
immutable string object, which is created with the [WindowsCreateString] API
and deleted with the [WindowsDeleteString] API. The HSTRING itself is an
integer value, just like other `HANDLE` objects in the Win32 programming
interface.

Helper functions exist to easily convert between the Dart `String` type and Windows Runtime strings: specifically, [convertToHString] and [convertFromHString].

Make sure you dispose of `HSTRING`s by calling `WindowsDeleteString`; you do
not need to free the pointer itself, since Windows reference counts the
backing store and frees the memory when the reference count reaches 0.
