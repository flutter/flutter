# Mojo EDK (embedder development kit)

The Mojo EDK is a "library" that provides implementations of the basic Mojo
system primitives (e.g., message pipes). It is not meant for ordinary
applications, but for _embedders_ who in turn expose the basic Mojo primitives
to other applications/content.

For example, this is used by `mojo_shell` to implement the Mojo primitives,
which it in turn exposes to Mojo applications, and by Flutter, which exposes
Mojo primitives to Flutter applications. (`mojo_shell` and Flutter are embedders
of the Mojo system implementation.)

Note: The embedder API is not stable (neither at the source nor at the binary
level) and will evolve over time.

## Organization

### Subdirectories

* [//mojo/edk/base_edk](base_edk): The embedder API requires various things to
  be implemented or injected by the embedder. This contains implementations of
  these things for use with [//base](../../base). (This may also be usable with
  other sufficiently-similar derivatives of Chromium's
  [//base](https://chromium.googlesource.com/chromium/src/+/master/base/).)
* [//mojo/edk/embedder](embedder): The header files in this directory constitute
  the public API available to embedders. (The .cc files are private and mostly
  serve to bridge between the public API and the private API in
  [system](system).)
* [//mojo/edk/platform](platform): This contains platform abstractions and
  declarations of embedder-dependent things. Some of these must be provided by
  the embedder, either by implementing an interface or by implementing a class
  outright.
* [//mojo/edk/system](system): This contains the bulk of the actual
  implementation, and is entirely private.
* [//mojo/edk/system/test](system/test): This contains private test helpers used
  by the EDK's internal tests.
* [//mojo/edk/test](test): In principle, this contains test helpers for use by
  embedders (but see the **TODO** below).
* [//mojo/edk/util](util): This contains basic helpers built on top of the C++
  library and also some POSIX APIs, notably pthreads. These are used by all the
  other parts of the EDK, and are also available for embedders to use. (Outside
  its tests, it should not depend on other parts of the EDK.)

### TODO(vtl)

* [//mojo/edk/test](test) currently contains things that aren't meant for
  embedders. (They can't be moved to [//mojo/edk/system/test](system/test)
  because of their dependencies, but they should be moved elsewhere instead.)
* There should be a "platform" directory. Many of the things in
  [//mojo/edk/embedder](embedder) (especially in the `platform` target) should
  be moved here (though some of the implementations should be moved to
  [//mojo/edk/base_edk](base_edk).

## See also

* [//mojo/public](../public): the Mojo public SDK
