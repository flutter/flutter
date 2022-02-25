// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for SharedAppData

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// A single lazily constructed object that's shared with the entire
// application via `SharedObject.of(context)`. The value of the object
// can be changed with `SharedObject.reset(context)`. Resetting the value
// will cause all of the widgets that depend on it to be rebuilt.
class SharedObject {
  SharedObject._();

  static final Object _sharedObjectKey = Object();

  @override
  String toString() => describeIdentity(this);

  static void reset(BuildContext context) {
    // Calling SharedAppData.setValue() causes dependent widgets to be rebuilt.
    SharedAppData.setValue<Object, SharedObject>(context, _sharedObjectKey, SharedObject._());
  }

  static SharedObject of(BuildContext context) {
    // If a value for _sharedObjectKey has never been set then the third
    // callback parameter is used to generate an initial value.
    return SharedAppData.getValue<Object, SharedObject>(context, _sharedObjectKey, () => SharedObject._());
  }
}

// An example of a widget which depends on the SharedObject's value,
// which might be provided - along with SharedObject - in a Dart package.
class CustomWidget extends StatelessWidget {
  const CustomWidget({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Will be rebuilt if the shared object's value is changed.
    return ElevatedButton(
      child: Text('Replace ${SharedObject.of(context)}'),
      onPressed: () {
        SharedObject.reset(context);
      },
    );
  }
}

class Home extends StatelessWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CustomWidget()
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Home()));
}
