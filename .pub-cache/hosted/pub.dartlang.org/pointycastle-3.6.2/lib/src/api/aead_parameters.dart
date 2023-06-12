part of '../../api.dart';

// ignore_for_file: omit_local_variable_types, prefer_single_quotes, non_constant_identifier_names, directives_ordering, prefer_typing_uninitialized_variables

class AEADParameters<UnderlyingCipherParameters extends CipherParameters>
    implements CipherParameters {
  final UnderlyingCipherParameters parameters;

  final Uint8List associatedData;

  final Uint8List nonce;

  final int macSize;

  AEADParameters(
      this.parameters, this.macSize, this.nonce, this.associatedData);
}
