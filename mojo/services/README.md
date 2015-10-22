# Mojo services "public" interfaces and libraries

This directory contains "public" interfaces and libraries for various Mojo
services (whose implementations are elsewhere, including in particular
[//services](../../services); some implementations may be in separate repos).

(Note that "core", i.e. absolutely essential, interfaces are under
[//mojo/public/interfaces](../public/interfaces).)

The majority of the contents under this directory are mojom files describing the
interfaces, located under `<service_name>/interfaces`. Note that some
subdirectories do not correspond directly to a "service" per se, but to a more
general group of interfaces (which may in turn be used by other "services").

There are also some language-specific libraries (especially for the "client"
side, but occasionally also for the implementation side) in corresponding
subdirectories. For example, C++ libraries are under `<service_name>/cpp`.

## See also

* [//services](../../services)
* [//mojo/public](../public)
* [//mojo/public/interfaces](../public/interfaces)
