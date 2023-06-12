# Desktop support

`sqflite` only includes native Android, iOS and MacOS support. 

Desktop support is provided by [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).
Since support is provided both on flutter and on DartVM on MacOS/Linux/Windows, it is not a flutter plugin.

See also some notes about how to keep you sqflite code as is and [supports Windows and Linux](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md)