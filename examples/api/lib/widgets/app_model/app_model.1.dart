// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for AppModel

import 'package:flutter/material.dart';

// A single lazily constructed object that's shared with the entire
// application via `SharedObject.of(context)`. The value of the object
// can be changed with `SharedObject.reset(context)`. Resetting the value
// will cause all of the widgets that depend on it to be rebuilt.
class SharedObject {
  SharedObject._();

  static final Object _sharedObjectKey = Object();

  @override
  String toString() => 'SharedObject#$hashCode';

  static void reset(BuildContext context) {
    // Calling AppModel.set() causes dependent widgets to be rebuilt.
    AppModel.set<Object, SharedObject>(context, _sharedObjectKey, SharedObject._());
  }

  static SharedObject of(BuildContext context) {
    SharedObject? value = AppModel.get<Object, SharedObject>(context, _sharedObjectKey);
    if (value == null) {
      value = SharedObject._();
      // Calling AppModel.init() does not cause dependent widgets to
      // be rebuilt, so it's safe to call it from within a build method.
      AppModel.init<Object, SharedObject>(context, _sharedObjectKey, value);
    }
    return value;
  }
}

class Home extends StatelessWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Replace ${SharedObject.of(context)}'),
          onPressed: () {
            SharedObject.reset(context);
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Home()));
}
