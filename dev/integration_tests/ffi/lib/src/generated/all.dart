// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:async";

import "aliasing_test.dart" as main0;
import "data_not_asan_test.dart" as main1;
import "data_test.dart" as main2;
import "extension_methods_test.dart" as main3;
import "external_typed_data_test.dart" as main4;
import "function_callbacks_many_test.dart" as main5;
import "function_callbacks_test.dart" as main6;
import "function_callbacks_very_many_test.dart" as main7;
import "function_structs_test.dart" as main8;
import "function_test.dart" as main9;
import "hardfp_test.dart" as main10;
import "negative_function_test.dart" as main11;
import "null_regress_39068_test.dart" as main12;
import "null_test.dart" as main13;
import "regress_37254_test.dart" as main14;
import "regress_39044_test.dart" as main15;
import "regress_39063_test.dart" as main16;
import "regress_39885_test.dart" as main17;
import "regress_40537_test.dart" as main18;
import "sizeof_test.dart" as main19;
import "snapshot_test.dart" as main20;
import "stacktrace_regress_37910_test.dart" as main21;
import "structs_test.dart" as main22;
import "variance_function_test.dart" as main23;

Future invoke(dynamic fun) async {
  if (fun is void Function() || fun is Future Function()) {
    return await fun();
  } else {
    return await fun(<String>[]);
  }
}

dynamic main() async {
  await invoke(main0.main);
  await invoke(main1.main);
  await invoke(main2.main);
  await invoke(main3.main);
  await invoke(main4.main);
  await invoke(main5.main);
  await invoke(main6.main);
  await invoke(main7.main);
  await invoke(main8.main);
  await invoke(main9.main);
  await invoke(main10.main);
  await invoke(main11.main);
  await invoke(main12.main);
  await invoke(main13.main);
  await invoke(main14.main);
  await invoke(main15.main);
  await invoke(main16.main);
  await invoke(main17.main);
  await invoke(main18.main);
  await invoke(main19.main);
  await invoke(main20.main);
  await invoke(main21.main);
  await invoke(main22.main);
  await invoke(main23.main);
}
