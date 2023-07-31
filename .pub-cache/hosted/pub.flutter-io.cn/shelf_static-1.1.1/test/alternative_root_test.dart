// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_util.dart';

void main() {
  setUp(() async {
    await d.file('root.txt', 'root txt').create();
    await d.dir('files', [
      d.file('test.txt', 'test txt content'),
      d.file('with space.txt', 'with space content')
    ]).create();
  });

  test('access root file', () async {
    final handler = createStaticHandler(d.sandbox);

    final response =
        await makeRequest(handler, '/static/root.txt', handlerPath: 'static');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 8);
    expect(response.readAsString(), completion('root txt'));
  });

  test('access root file with space', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(
        handler, '/static/files/with%20space.txt',
        handlerPath: 'static');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 18);
    expect(response.readAsString(), completion('with space content'));
  });

  test('access root file with unencoded space', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(
        handler, '/static/files/with%20space.txt',
        handlerPath: 'static');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 18);
    expect(response.readAsString(), completion('with space content'));
  });

  test('access file under directory', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/static/files/test.txt',
        handlerPath: 'static');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentLength, 16);
    expect(response.readAsString(), completion('test txt content'));
  });

  test('file not found', () async {
    final handler = createStaticHandler(d.sandbox);

    final response = await makeRequest(handler, '/static/not_here.txt',
        handlerPath: 'static');
    expect(response.statusCode, HttpStatus.notFound);
  });
}
