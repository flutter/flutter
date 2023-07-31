// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_context_collection_test.dart' as analysis_context_collection;
import 'byte_store_test.dart' as byte_store_test;
import 'cache_test.dart' as cache_test;
import 'context_builder_test.dart' as context_builder;
import 'context_locator_test.dart' as context_locator;
import 'context_root_test.dart' as context_root;
import 'crc32_test.dart' as crc32_test;
import 'defined_names_test.dart' as defined_names;
import 'driver_caching_test.dart' as driver_caching;
import 'driver_resolution_test.dart' as driver_resolution;
import 'driver_test.dart' as driver;
import 'experiments_test.dart' as experiments_test;
import 'feature_set_provider_test.dart' as feature_set_provider;
import 'file_byte_store_test.dart' as file_byte_store_test;
import 'file_state_test.dart' as file_state;
import 'fletcher16_test.dart' as fletcher16_test;
import 'index_test.dart' as index;
import 'mutex_test.dart' as mutex;
import 'referenced_names_test.dart' as referenced_names;
import 'resolve_for_completion_test.dart' as resolve_for_completion;
import 'results/test_all.dart' as results;
import 'search_test.dart' as search;
import 'session_helper_test.dart' as session_helper;
import 'session_test.dart' as session;
import 'unlinked_api_signature_test.dart' as unlinked_api_signature;
import 'uri_converter_test.dart' as uri_converter;

main() {
  defineReflectiveSuite(() {
    analysis_context_collection.main();
    byte_store_test.main();
    cache_test.main();
    context_builder.main();
    context_locator.main();
    context_root.main();
    crc32_test.main();
    defined_names.main();
    driver.main();
    driver_caching.main();
    driver_resolution.main();
    experiments_test.main();
    feature_set_provider.main();
    file_byte_store_test.main();
    file_state.main();
    fletcher16_test.main();
    index.main();
    mutex.main();
    referenced_names.main();
    resolve_for_completion.main();
    results.main();
    search.main();
    session.main();
    session_helper.main();
    unlinked_api_signature.main();
    uri_converter.main();
  }, name: 'analysis');
}
