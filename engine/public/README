Blink Public API
================

This directory contains the public API for Blink. The API consists of a number
of C++ header files, scripts, and GYP build files. We consider all other files
in Blink to be implementation details, which are subject to change at any time
without notice.

The primary consumer of this API is Chromium's Content layer. If you are
interested in using Blink, please consider interfacing with Blink via the
Content layer rather than interfacing directly with this API.

Compatibility
-------------

The API does not support binary compatibility. Instead, the API is intended to
insulate the rest of the Chromium project from internal changes to Blink.  Over
time, the API is likely to evolve in source-incompatible ways as Chromium's and
Blink's needs change.

Organization
------------

The API is organized into two parts:

  - public/platform
  - public/web

The public/platform directory defines an abstract platform upon which Blink
runs. Rather than communicating directly with the underlying operating system,
Blink is designed to run in a sandbox and interacts with the operating system
via the platform API. The central interface in this part of the API is
Platform, which is a pure virtual interface from which Blink obtains many other
interfaces.

The public/web directory defines an interface to Blink's implementation of the
web platform, including the Document Object Model (DOM). The central interface
in this part of the API is WebView, which is a good starting point for
exploring the API.

Note that public/platform should not depend on public/web.

Basic Types
-----------

The API does not use STL types, except for a small number of STL types that are
used internally by Blink (e.g., std::pair). Instead, we use WTF containers to
implement the API.

The API uses some internal types (e.g., WebCore::Node). Typically, these types
are forward declared and are opaque to consumers of the API. In other cases,
the full definitions are available behind the BLINK_IMPLEMENTATION
preprocessor macro. In both cases, we continue to regard these internal types
as implementation details of Blink, and consumers of the API should not rely
upon these types.

Similarly, the API uses STL types outside of the BLINK_IMPLEMENTATION
preprocessor macro, which is for the convenience of the consumer.

Contact Information
-------------------

The public API also contains an OWNERS file, which lists a number of people who
are knowledgeable about the API. If you have questions or comments about the
API that might be of general interest to the Blink community at large, please
consider directing your inquiry to blink-dev@chromium.org rather than to the
OWNERS specifically.
