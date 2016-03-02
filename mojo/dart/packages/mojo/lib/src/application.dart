// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of application;

class _ApplicationImpl implements application_mojom.Application {
  application_mojom.ApplicationStub _stub;
  shell_mojom.ShellProxy shell;
  Application _application;

  _ApplicationImpl(
      Application application, core.MojoMessagePipeEndpoint endpoint) {
    _application = application;
    _stub = new application_mojom.ApplicationStub.fromEndpoint(endpoint, this);
    _stub.onError = ((_) => close());
  }

  _ApplicationImpl.fromHandle(Application application, core.MojoHandle handle) {
    _application = application;
    _stub = new application_mojom.ApplicationStub.fromHandle(handle, this);
    _stub.onError = ((_) => close());
  }

  _ApplicationImpl.fromStub(Application application,
      application_mojom.ApplicationStub applicationStub) {
    _application = application;
    _stub = applicationStub;
    _stub.impl = this;
    _stub.onError = ((_) => close());
  }

  set onError(core.ErrorHandler f) {
    _stub.onError = f;
  }

  void initialize(
      bindings.ProxyBase shellProxy, List<String> args, String url) {
    assert(shell == null);
    shell = shellProxy;
    _application.initialize(args, url);
  }

  @override
  void acceptConnection(String requestorUrl, ServiceProviderStub services,
          bindings.ProxyBase exposedServices, String resolvedUrl) =>
      _application._acceptConnection(
          requestorUrl, services, exposedServices, resolvedUrl);

  @override
  void requestQuit() => _application._requestQuitAndClose();

  Future close({bool immediate: false}) {
    if (shell != null) {
      shell.close(immediate: immediate);
    }
    return _stub.close(immediate: immediate);
  }
}

// TODO(zra): Better documentation and examples.
// To implement, do the following:
// - Optionally override initialize() to process command-line args.
// - Optionally override acceptConnection() if services are to be provided.
// - Optionally override close() to clean up application resources.
abstract class Application implements bindings.ServiceConnector {
  _ApplicationImpl _applicationImpl;
  List<ApplicationConnection> _applicationConnections;
  Function onError;

  Application(core.MojoMessagePipeEndpoint endpoint) {
    _applicationConnections = [];
    _applicationImpl = new _ApplicationImpl(this, endpoint);
    _applicationImpl.onError = _errorHandler;
  }

  Application.fromHandle(core.MojoHandle appHandle) {
    _applicationConnections = [];
    _applicationImpl = new _ApplicationImpl.fromHandle(this, appHandle);
    _applicationImpl.onError = _errorHandler;
  }

  Application.fromStub(application_mojom.ApplicationStub appStub) {
    _applicationConnections = [];
    _applicationImpl = new _ApplicationImpl.fromStub(this, appStub);
    _applicationImpl.onError = _errorHandler;
  }

  void initialize(List<String> args, String url) {}

  // TODO(skydart): This is a temporary fix to allow sky application to consume
  // mojo services. Do not use for any other purpose.
  void initializeFromShellProxy(
          shell_mojom.ShellProxy shellProxy, List<String> args, String url) =>
      _applicationImpl.initialize(shellProxy, args, url);

  // Returns a connection to the app at |url|.
  ApplicationConnection connectToApplication(String url) {
    var proxy = new ServiceProviderProxy.unbound();
    var stub = new ServiceProviderStub.unbound();
    _applicationImpl.shell.ptr.connectToApplication(url, proxy, stub);
    var connection = new ApplicationConnection(stub, proxy);
    _applicationConnections.add(connection);
    return connection;
  }

  void connectToService(String url, bindings.ProxyBase proxy,
      [String serviceName]) {
    connectToApplication(url).requestService(proxy, serviceName);
  }

  void requestQuit() {}

  void _requestQuitAndClose() {
    requestQuit();
    close();
  }

  void _errorHandler(Object e) {
    close().then((_) {
      if (onError != null) onError(e);
    });
  }

  Future close({bool immediate: false}) async {
    assert(_applicationImpl != null);
    await Future.wait(
        _applicationConnections.map((ac) => ac.close(immediate: immediate)));
    _applicationConnections.clear();
    return _applicationImpl.close(immediate: immediate);
  }

  // This method closes all the application connections. Used during apptesting.
  Future resetConnections() async {
    assert(_applicationImpl != null);
    await Future.wait(_applicationConnections.map((ac) => ac.close()));
    _applicationConnections.clear();
  }

  void _acceptConnection(String requestorUrl, ServiceProviderStub services,
      ServiceProviderProxy exposedServices, String resolvedUrl) {
    var connection = new ApplicationConnection(services, exposedServices);
    _applicationConnections.add(connection);
    acceptConnection(requestorUrl, resolvedUrl, connection);
  }

  // Override this method to provide services on |connection|.
  void acceptConnection(String requestorUrl, String resolvedUrl,
      ApplicationConnection connection) {}
}
