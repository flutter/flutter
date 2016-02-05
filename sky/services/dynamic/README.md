Flutter Dynamic Services Loader
===============================

Third party service implementations are packaged as dylibs. Each dylib implementation needs to import just one file (`dynamic_service_dylib.h`) and implement `FlutterServicePerform` to provide the service implementation. In order to build the dylib, the build step needs the `//sky/services/dynamic:dylib` GN rule.