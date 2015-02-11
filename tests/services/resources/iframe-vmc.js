#!mojo mojo:js_content_handler

define("main", [
  "console",
  "mojo/public/js/bindings",
  "mojo/services/public/js/application",
  "mojo/services/view_manager/public/interfaces/view_manager.mojom",
  "services/js/test/echo_service.mojom",
], function(console, bindings, application, viewManagerMojom, echoServiceMojom) {

  const Application = application.Application;
  const ViewManagerClient = viewManagerMojom.ViewManagerClient;
  const EchoService = echoServiceMojom.EchoService;

  var serviceImpl;
  var success = new Promise(function(resolve) {
    serviceImpl = {
      onEmbed: function() {
        resolve({value: "success"});
      },
      echoString: function(s) {
        return success;
      },
    }
  });

  class IFrameVMCApp extends Application {
    acceptConnection(initiatorURL, initiatorServiceExchange) {
      var factory = function() { return serviceImpl; }
      initiatorServiceExchange.provideService(ViewManagerClient, factory);
      initiatorServiceExchange.provideService(EchoService, factory);
    }
  }

  return IFrameVMCApp;
});
