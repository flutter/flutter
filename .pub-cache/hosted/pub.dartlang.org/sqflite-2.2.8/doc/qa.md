## Cross-platform support

Cross platform support is a bit weird, sorry about that. The `sqflite` package,
implemented as a "classic" flutter plugin supports only Android, iOS and MacOS.

Desktop support (Linux, Windows) is provided by the `sqflite_common_ffi` package.
It is a dart package so it also works on the dart VM (command line) so it is not
a flutter plugin. Its implementation uses ffi. This implementation can also
support Android, iOS and MacOS but it is not a flutter plugin.

Experimental web support is provided by the `sqflite_common_ffi_web` package.

> Is there a plan to publish a single federated package?

Not at this time. Some might prefer `sqflite_common_ffi` over `sqflite`. The first
giving you access to the latest sqlite3 version and the second giving a smaller binary size.
Some wants encryption support. It is hard to make the proper choice for everyone.

As a side note, I find it weird when creating a linux only flutter application, that
my app has to download the `win32` package. Currently there is no way to limit dependencies
to only the platform you are supporting. More dependencies means more chance to have breaking bugs 
that you cannot fix.

I would even be more inclined to publish a separate packages for each platform that people have to include
one by one for the platforms they want.

Also I'm a freelance developer, maintaining it in my free-time so I don't always have time and
the energy to support it (since 2017!) in the best way. Documentation is poor, I know. I'm not a native english speaker.
Sometimes issues like this one bring me the opportunity to improve the documentation so I will
likely copy this response to the documentation.



