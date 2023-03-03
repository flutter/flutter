import 'common.dart';

abstract class Extension {
  const Extension();

  /// Must run synchronously.
  void registerHandlers(Map<Type, List<RequestHandler>> registeredHandlers);
}

class TemplateExtension extends Extension {
  @override
  void registerHandlers(Map<Type, List<RequestHandler>> registeredHandlers) {
    final List<RequestHandler> handlers = registeredHandlers[ListTemplatesRequest] ?? <RequestHandler>[];
    handlers.add(_handleListTemplatesRequest);
    // assign in case this was previously null
    registeredHandlers[ListTemplatesRequest] = handlers;
  }

  void _handleListTemplatesRequest(RequestWrapper<Request> message, Response? response) {
    response ??= ListTemplatesResponse(id: message.id)..templates.addAll(templates);
    throw 'foo';
  }

  final List<String> templates = <String>['foo template', 'bar template'];
}

class ListTemplatesRequest implements Request {
  const ListTemplatesRequest();
}

class ListTemplatesResponse extends Response {
  ListTemplatesResponse({required super.id});

  final List<String> templates = <String>[];

  @override
  String toString() => 'Installed templates: [${templates.join(', ')}]';
}
