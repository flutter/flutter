// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:pubspec/pubspec.dart';

main() async {
  // specify the directory
  var myDirectory = Directory('myDir');
  ;

  // load pubSpec
  var pubSpec = await PubSpec.load(myDirectory);

  // change the dependencies to a single path dependency on project 'foo'
  var newPubSpec = pubSpec.copy(dependencies: {'foo': PathReference('../foo')});

  // save it
  await newPubSpec.save(myDirectory);
}
