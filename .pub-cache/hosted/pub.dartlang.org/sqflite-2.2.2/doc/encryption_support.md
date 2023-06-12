# Encryption support

Encryption is supported on Android, iOS and MacOS support using [`sqflite_sqlcipher`](https://pub.dev/packages/sqflite_sqlcipher)
by David Martos which has some shared code through `sqflite_common` package.

On desktop, encryption is provided by [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi).
Since support is provided both on flutter and on DartVM on MacOS/Linux/Windows, it is not a flutter plugin.
See [here](https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/encryption_support.md) for more information
of how encryption is supported on Desktop.

