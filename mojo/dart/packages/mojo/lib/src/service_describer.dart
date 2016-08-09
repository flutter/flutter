// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of application;

class _ServiceDescriberImpl implements service_describer.ServiceDescriber {
  final HashMap<String, service_describer.ServiceDescription> _data;
  service_describer.ServiceDescriberStub _stub;

  _ServiceDescriberImpl(this._data, core.MojoMessagePipeEndpoint endpoint) {
    _stub =
        new service_describer.ServiceDescriberStub.fromEndpoint(endpoint, this);
  }

  void describeService(String interfaceName,
      service_describer.ServiceDescriptionStub descriptionRequest) {
    if (_data.containsKey(interfaceName)) {
      descriptionRequest.impl = _data[interfaceName];
    }
  }
}
