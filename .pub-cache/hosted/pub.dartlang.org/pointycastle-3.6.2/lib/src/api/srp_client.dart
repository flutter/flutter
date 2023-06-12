// See file LICENSE for more information.

part of api;

abstract class SRPClient {
  ///Computes the client evidence message M1 using the previously received values.
  ///To be called after calculating the secret S.
  ///returns M1: the client side generated evidence message
  ///throws Exception
  BigInt? calculateClientEvidenceMessage();

  ///Generates the secret S given the server's credentials
  ///@param serverB The server's credentials
  ///@return Client's verification message for the server
  ///@throws Exception If server's credentials are invalid
  ///
  BigInt? calculateSecret(BigInt serverB);

  /// Computes the final session key as a result of the SRP successful mutual authentication
  /// To be called after verifying the server evidence message M2.
  /// returns Key: the mutually authenticated symmetric session key
  /// throws Exception
  BigInt? calculateSessionKey();

  /// Generates the client's credentials that are to be sent to the server.
  /// @return The client's public value
  BigInt? generateClientCredentials(
      Uint8List salt, Uint8List identity, Uint8List password);

  /// Authenticates the server evidence message M2 received and saves it only if correct.
  /// [serverM2] the server side generated evidence message
  /// return A boolean indicating if the server message M2 was the expected one.
  /// throws Exception
  bool verifyServerEvidenceMessage(BigInt serverM2);
}
