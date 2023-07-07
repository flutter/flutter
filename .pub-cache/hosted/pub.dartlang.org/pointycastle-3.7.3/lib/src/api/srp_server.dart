// See file LICENSE for more information.

part of api;

/// Implements the server side SRP-6a protocol. Note that this class is stateful, and therefore NOT threadsafe.
/// This implementation of SRP is based on the optimized message sequence put forth by Thomas Wu in the paper
/// "SRP-6: Improvements and Refinements to the Secure Remote Password Protocol, 2002"
abstract class SRPServer {
  /// Processes the client's credentials. If valid the shared secret is generated and returned.
  /// @param clientA The client's credentials
  /// @return A shared secret BigInt
  /// @throws CryptoException If client's credentials are invalid
  BigInt? calculateSecret(BigInt clientA);

  /// Computes the final session key as a result of the SRP successful mutual authentication
  /// To be called after calculating the server evidence message M2.
  /// @return Key: the mutual authenticated symmetric session key
  /// @throws CryptoException
  BigInt? calculateSessionKey();

  /// Generates the server's credentials that are to be sent to the client.
  /// @return The server's public value
  BigInt? generateServerCredentials();

  /// Computes the server evidence message M2 using the previously verified values.
  /// To be called after successfully verifying the client evidence message M1.
  /// @return M2: the server side generated evidence message
  /// @throws CryptoException
  BigInt? calculateServerEvidenceMessage();

  /// Authenticates the received client evidence message M1 and saves it only if correct.
  /// To be called after calculating the secret S.
  /// @param clientM1 the client side generated evidence message
  /// @return A boolean indicating if the client message M1 was the expected one.
  /// @throws CryptoException
  bool verifyClientEvidenceMessage(BigInt clientM1);
}
