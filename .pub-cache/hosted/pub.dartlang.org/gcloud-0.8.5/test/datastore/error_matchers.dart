// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_matchers;

import 'dart:io';

import 'package:gcloud/datastore.dart';
import 'package:test/test.dart';

const isApplicationError = TypeMatcher<ApplicationError>();

const isDataStoreError = TypeMatcher<DatastoreError>();
const isTransactionAbortedError = TypeMatcher<TransactionAbortedError>();
const isNeedIndexError = TypeMatcher<NeedIndexError>();
const isTimeoutError = TypeMatcher<TimeoutError>();

const isInt = TypeMatcher<int>();

const isSocketException = TypeMatcher<SocketException>();
