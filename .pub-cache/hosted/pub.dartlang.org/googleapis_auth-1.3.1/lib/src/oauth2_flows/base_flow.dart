import 'package:http/http.dart';

import '../access_credentials.dart';
import '../auth_client.dart';
import '../auth_functions.dart';
import '../auth_http_utils.dart';
import '../http_client_base.dart';

/// Base class for "Flows" that provide [AccessCredentials].
abstract class BaseFlow {
  Future<AccessCredentials> run();
}

Future<AutoRefreshingAuthClient> clientFromFlow(
  BaseFlow Function(Client client) flowFactory, {
  Client? baseClient,
}) async {
  if (baseClient == null) {
    baseClient = Client();
  } else {
    baseClient = nonClosingClient(baseClient);
  }

  final flow = flowFactory(baseClient);

  try {
    final credentials = await flow.run();
    return _FlowClient(baseClient, credentials, flow);
  } catch (e) {
    baseClient.close();
    rethrow;
  }
}

// Will close the underlying `http.Client`.
class _FlowClient extends AutoRefreshDelegatingClient {
  final BaseFlow _flow;
  @override
  AccessCredentials credentials;
  Client _authClient;

  _FlowClient(Client client, this.credentials, this._flow)
      : _authClient = authenticatedClient(client, credentials),
        super(client);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (credentials.accessToken.hasExpired) {
      final newCredentials = await _flow.run();
      notifyAboutNewCredentials(newCredentials);
      credentials = newCredentials;
      _authClient = authenticatedClient(baseClient, credentials);
    }
    return _authClient.send(request);
  }
}
