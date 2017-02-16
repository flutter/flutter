// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class NetworkImageLoadingListenerMock extends NetworkImageLoadingListener {

  bool imageloadingsuccess;
  bool imageloadingfailed;

  @override
  void networkImageLoadingSuccess() {
    this.imageloadingsuccess = true;
  }

  @override
  void networkImageLoadingFailed() {
    this.imageloadingfailed = true;
  }

  Future<bool> waitLoadingSuccessOrFailed() async {
    while(this.imageloadingsuccess == null && this.imageloadingfailed == null) { }
    return true;
  }

}

void main() {

  testWidgets('network image listener, loading failed', (WidgetTester tester) async {

    NetworkImageLoadingListenerMock listener = new NetworkImageLoadingListenerMock();

    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response("return an error.", 404, request: request)
        );
      });
    };

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new Image.network('fake_url', networkImageLoadingListener: listener)
              );
            }
          )
        )
      )
    );

    await (listener.waitLoadingSuccessOrFailed());
    expect(listener.imageloadingsuccess, null);
    expect(listener.imageloadingfailed, true);

  });

  testWidgets('network image listener, loading success but empty answer', (WidgetTester tester) async {

    NetworkImageLoadingListenerMock listener = new NetworkImageLoadingListenerMock();

    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        print('bad answer');
        return new Future<http.Response>.value(
          new http.Response("", 200, request: request)
        );
      });
    };

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new Image.network('fake_url2', networkImageLoadingListener: listener)
              );
            }
          )
        )
      )
    );

    await (listener.waitLoadingSuccessOrFailed());
    expect(listener.imageloadingsuccess, null);
    expect(listener.imageloadingfailed, true);

  });

  testWidgets('network image listener, loading success', (WidgetTester tester) async {

    NetworkImageLoadingListenerMock listener = new NetworkImageLoadingListenerMock();

    var headers= {'charset': 'utf-8', 'content-type': 'image/jpeg'};

    // Override the http client to send expected response.
    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response("data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==",
           200, request: request, headers: headers)
        );
      });
    };

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new Image.network('fake_url3', networkImageLoadingListener: listener)
              );
            }
          )
        )
      )
    );


    await (listener.waitLoadingSuccessOrFailed());
    expect(listener.imageloadingsuccess, true);
    expect(listener.imageloadingfailed, false);
    expect(true, true);
  });

}
