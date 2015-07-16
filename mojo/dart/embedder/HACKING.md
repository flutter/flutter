Dart Embedder Hacking
====

## Debugging

Under Mojo, by default the Dart VM is built in Release mode regardless of the
mode that Mojo is built in. That is, when Mojo is built in Debug mode, the
Dart VM is still built in Release mode. To change this behavior while working
on the embedder, pass dart_debug=true to gn to configure a Debug build of the
Dart VM. I.e.:

```
$ gn gen --check out/Debug --args='... dart_debug=true'
```

## Embedder packages

In order to implement the 'dart:io' library (and run a service isolate hosting
Observatory), the Mojo Dart embedder needs to use some package: imports. Mojo
applications should be able to use a different version of these packages than
the embedder. In other words, the embedder snapshot cannot include any
'package:' imports because they will prohibit an application from using a newer
version of the package. In order to allow the embedder to use packages
without interfering with an application's intended version, we clone the
packages used by the embedder and rewrite the url to start with 'dart:_'
(not 'package:'). Each dart:_ import must have a mapping provided
to gen_snapshot which maps from the import uri to a real file system path.

The complete list of packages used by the embedder is located at
//mojo/dart/embedder/packages.dart.

Adding an embedder package can be done in three steps:

1) Add 'dart:_' import to packages.dart, for example:

import 'dart:_mojo/public/dart/application.dart';

2) Add dart_embedder_package to //mojo/dart/embedder/BUILD.gn, for example:

dart_embedder_package("dart_embedder_package_application") {
  package = "mojo/public/interfaces/application"
}

3) Add the package directory to the list in :generate_snapshot_bin, for example:

rebase_path("//mojo/public/interfaces/application"),

## Dart IO

Under Mojo, the 'dart:io' implementation is not complete and likely suffers
from subtle differences. Implementation status:

| 'dart:io' feature  | Mojo Service         | Implemented |
| ------------------ | -------------------- | ----------- |
| Socket             | mojo:network_service | Yes         |
| ServerSocket       | mojo:network_service | Yes         |
| DNS                | mojo:network_srevice | Yes         |
| SecureSocket       | N/A                  | No          |
| SecureServerSocket | N/A                  | No          |
| Datagram           | mojo:network_service | No          |
| File system        | mojo:files           | No          |
