Packages
================

This directory contains several examples of packages used with Flutter. 
For more information on how to use or develop new packages, see the [Using Packages]
(https://flutter.dev/docs/development/packages-and-plugins/using-packages/) guide.

A package allows the creation of modular code that cen easily be shared. For example, packages
can enable use cases to make network requests, integrate with device APIs, and so on. The minimal
components of a package include:

**`pubspec.yaml`**
A metadata file declaring package name, version, author, etc.

**`lib`**
The lib directory containing the package's public code and minimally contains a single `<package-name>.dart` file.

To implement a pure Dart package, you can either add the functionality inside `lib/<package name>.dart` or add 
the functionality in several files inside the `lib` directory. 


Shared Packages
===============================
Flutter supports users sharing their developed packages to the Flutter and Dark community. 

Flutter packages are published to the pub.dev page. Users can find the most popular downloaded
and most highly recommended Flutter and Dart packages.

To see additional packages created by other users, see the ['pub.dev'](https://pub.dev/) site.


Developing Packages
===============================
Flutter is a supportive and creative commnuity and encourages its members to develop new
packages if no package exists for your specific use case. Please be sure to review the 
['Contributing to Flutter'](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)
page and the ['Code of Conduct'](https://github.com/flutter/flutter/blob/master/CODE_OF_CONDUCT.md) 
page for general contribution guidelines.

To write a new packages, ['Developing Packages']
(https://flutter.dev/docs/development/packages-and-plugins/developing-packages) see the page. 

To test a package, see the ['Unit Tests'](https://flutter.dev/docs/testing#unit-tests) page for guidance. 

To publish your package for other to use, see the [`Publishing Pakcages`]
(https://pub.dev/help/publishing) site.


