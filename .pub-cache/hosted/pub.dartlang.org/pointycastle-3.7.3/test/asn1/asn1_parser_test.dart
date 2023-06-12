import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:test/test.dart';

void main() {
  ///
  /// Test simple structur
  ///
  /// ```
  ///   SEQUENCE (2 elem)
  ///     OBJECT IDENTIFIER 1.2.840.113549.1.1.11 sha256WithRSAEncryption (PKCS #1)
  ///     NULL
  /// ```
  ///
  test('Test nextObject 1', () {
    var bytes = Uint8List.fromList([
      0x30,
      0x0D,
      0x06,
      0x09,
      0x2A,
      0x86,
      0x48,
      0x86,
      0xF7,
      0x0D,
      0x01,
      0x01,
      0x0B,
      0x05,
      0x00
    ]);
    var parser = ASN1Parser(bytes);
    var sequence = parser.nextObject() as ASN1Sequence;
    expect(sequence.encodedBytes!.length, sequence.totalEncodedByteLength);
    expect(sequence.elements!.length, 2);
    expect(sequence.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(sequence.elements!.elementAt(1) is ASN1Null, true);
  });

  ///
  /// Test simple structur
  ///
  /// ```
  /// SEQUENCE (4 elem)
  ///    SET (1 elem)
  ///      SEQUENCE (2 elem)
  ///        OBJECT IDENTIFIER 2.5.4.6 countryName (X.520 DN component)
  ///        PrintableString US
  ///    SET (1 elem)
  ///      SEQUENCE (2 elem)
  ///        OBJECT IDENTIFIER 2.5.4.10 organizationName (X.520 DN component)
  ///        PrintableString DigiCert Inc
  ///    SET (1 elem)
  ///      SEQUENCE (2 elem)
  ///        OBJECT IDENTIFIER 2.5.4.11 organizationalUnitName (X.520 DN component)
  ///        PrintableString www.digicert.com
  ///    SET (1 elem)
  ///      SEQUENCE (2 elem)
  ///        OBJECT IDENTIFIER 2.5.4.3 commonName (X.520 DN component)
  ///        PrintableString Thawte RSA CA 2018
  /// ```
  ///
  test('Test nextObject 2', () {
    var bytes = Uint8List.fromList([
      0x30,
      0x5C,
      0x31,
      0x0B,
      0x30,
      0x09,
      0x06,
      0x03,
      0x55,
      0x04,
      0x06,
      0x13,
      0x02,
      0x55,
      0x53,
      0x31,
      0x15,
      0x30,
      0x13,
      0x06,
      0x03,
      0x55,
      0x04,
      0x0A,
      0x13,
      0x0C,
      0x44,
      0x69,
      0x67,
      0x69,
      0x43,
      0x65,
      0x72,
      0x74,
      0x20,
      0x49,
      0x6E,
      0x63,
      0x31,
      0x19,
      0x30,
      0x17,
      0x06,
      0x03,
      0x55,
      0x04,
      0x0B,
      0x13,
      0x10,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x31,
      0x1B,
      0x30,
      0x19,
      0x06,
      0x03,
      0x55,
      0x04,
      0x03,
      0x13,
      0x12,
      0x54,
      0x68,
      0x61,
      0x77,
      0x74,
      0x65,
      0x20,
      0x52,
      0x53,
      0x41,
      0x20,
      0x43,
      0x41,
      0x20,
      0x32,
      0x30,
      0x31,
      0x38
    ]);

    var parser = ASN1Parser(bytes);
    var sequence = parser.nextObject() as ASN1Sequence;

    expect(sequence.encodedBytes!.length, sequence.totalEncodedByteLength);
    expect(sequence.elements!.length, 4);
    expect(sequence.elements!.elementAt(0) is ASN1Set, true);
    expect(sequence.elements!.elementAt(1) is ASN1Set, true);
    expect(sequence.elements!.elementAt(2) is ASN1Set, true);
    expect(sequence.elements!.elementAt(3) is ASN1Set, true);

    var set1 = sequence.elements!.elementAt(0) as ASN1Set;
    expect(set1.elements!.length, 1);
    expect(set1.elements!.elementAt(0) is ASN1Sequence, true);

    var seq1 = set1.elements!.elementAt(0) as ASN1Sequence;
    expect(seq1.elements!.length, 2);
    expect(seq1.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(seq1.elements!.elementAt(1) is ASN1PrintableString, true);
    var oi1 = seq1.elements!.elementAt(0) as ASN1ObjectIdentifier;
    var string1 = seq1.elements!.elementAt(1) as ASN1PrintableString;
    expect(oi1.objectIdentifierAsString, '2.5.4.6');
    expect(string1.stringValue, 'US');

    var set2 = sequence.elements!.elementAt(1) as ASN1Set;
    expect(set2.elements!.length, 1);
    expect(set2.elements!.elementAt(0) is ASN1Sequence, true);

    var seq2 = set2.elements!.elementAt(0) as ASN1Sequence;
    expect(seq2.elements!.length, 2);
    expect(seq2.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(seq2.elements!.elementAt(1) is ASN1PrintableString, true);
    var oi2 = seq2.elements!.elementAt(0) as ASN1ObjectIdentifier;
    var string2 = seq2.elements!.elementAt(1) as ASN1PrintableString;
    expect(oi2.objectIdentifierAsString, '2.5.4.10');
    expect(string2.stringValue, 'DigiCert Inc');

    var set3 = sequence.elements!.elementAt(2) as ASN1Set;
    expect(set3.elements!.length, 1);
    expect(set3.elements!.elementAt(0) is ASN1Sequence, true);

    var seq3 = set3.elements!.elementAt(0) as ASN1Sequence;
    expect(seq3.elements!.length, 2);
    expect(seq3.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(seq3.elements!.elementAt(1) is ASN1PrintableString, true);
    var oi3 = seq3.elements!.elementAt(0) as ASN1ObjectIdentifier;
    var string3 = seq3.elements!.elementAt(1) as ASN1PrintableString;
    expect(oi3.objectIdentifierAsString, '2.5.4.11');
    expect(string3.stringValue, 'www.digicert.com');

    var set4 = sequence.elements!.elementAt(3) as ASN1Set;
    expect(set4.elements!.length, 1);
    expect(set4.elements!.elementAt(0) is ASN1Sequence, true);

    var seq4 = set4.elements!.elementAt(0) as ASN1Sequence;
    expect(seq4.elements!.length, 2);
    expect(seq4.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(seq4.elements!.elementAt(1) is ASN1PrintableString, true);
    var oi4 = seq4.elements!.elementAt(0) as ASN1ObjectIdentifier;
    var string4 = seq4.elements!.elementAt(1) as ASN1PrintableString;
    expect(oi4.objectIdentifierAsString, '2.5.4.3');
    expect(string4.stringValue, 'Thawte RSA CA 2018');
  });

  test('Test parse X509', () {
    var pem = '''-----BEGIN CERTIFICATE-----
MIIGuDCCBaCgAwIBAgIQJWoxbMUUPa7apOL527blFzANBgkqhkiG9w0BAQsFADCB
sDELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8w
HQYDVQQLExZGT1IgVEVTVCBQVVJQT1NFUyBPTkxZMR8wHQYDVQQLExZTeW1hbnRl
YyBUcnVzdCBOZXR3b3JrMUAwPgYDVQQDEzdTeW1hbnRlYyBDbGFzcyAzIEV4dGVu
ZGVkIFZhbGlkYXRpb24gU0hBMjU2IFNTTCBURVNUIENBMB4XDTE2MTExODAwMDAw
MFoXDTE2MTEyNTIzNTk1OVowge8xEzARBgsrBgEEAYI3PAIBAxMCREUxFzAVBgsr
BgEEAYI3PAIBAhMGQmF5ZXJuMRswGQYLKwYBBAGCNzwCAQETClJlZ2Vuc2J1cmcx
HTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRAwDgYDVQQFEwczNDY2NTY1
MQswCQYDVQQGEwJERTENMAsGA1UECAwESGllcjETMBEGA1UEBwwKVGVzdGhhdXNl
bjESMBAGA1UECgwJVGVzdGZpcm1hMRQwEgYDVQQLDAtFbnR3aWNrbHVuZzEWMBQG
A1UEAwwNZXBoZW5vZHJvbS5kZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBALHYKBMxalQNBwqQVS/NE/Y5eTBORjxqY7jC/vZ881G4uMM+AFvt5iFKabjN
wLT9itYFuJ/k5o7kVn93f0eirxrP0e3wPkzwELJIR6AdZo1EsTzGPW0p41PGOjGv
/GPZwFWEfb7C0Wz4v3b3LtBrWYNJ12RswQAtKdNey/1nxZT2UwGdwESBK0Rvh3qt
33Wqkf1t8X627XTD91dkB/brq6oO3m2ZDyhbqDfMiWqUWl2CVnO0A+eFZ5uFFVdm
NPFuhNqgCmZ6TfFkQJQEKuBadHDTj47qjU27lTJjksCHVDs9PzJzkH49zStjk9D4
UkPw7y37xJ/gUK27VhkIC6QBTuECAwEAAaOCAoswggKHMCsGA1UdEQQkMCKCDWVw
aGVub2Ryb20uZGWCEXd3dy5lcGhlbm9kcm9tLmRlMAkGA1UdEwQCMAAwDgYDVR0P
AQH/BAQDAgWgMG8GA1UdIARoMGYwWwYLYIZIAYb4RQEHFwYwTDAjBggrBgEFBQcC
ARYXaHR0cHM6Ly9kLnN5bWNiLmNvbS9jcHMwJQYIKwYBBQUHAgIwGQwXaHR0cHM6
Ly9kLnN5bWNiLmNvbS9ycGEwBwYFZ4EMAQEwKwYDVR0fBCQwIjAgoB6gHIYaaHR0
cDovL3NoLnN5bWNiLmNvbS9zaC5jcmwwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
AQUFBwMCMB8GA1UdIwQYMBaAFERiHdf3UpjAQwNcU+bmv+ZDJ+tjMFcGCCsGAQUF
BwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3NoLnN5bWNkLmNvbTAmBggrBgEF
BQcwAoYaaHR0cDovL3NoLnN5bWNiLmNvbS9zaC5jcnQwggEEBgorBgEEAdZ5AgQC
BIH1BIHyAPAAdgAR0wud4RKWE7VpXG+auxQlNw9ew3QWYeKO2GKv4jEwuQAAAVh3
IQXYAAAEAwBHMEUCIAWDOM8fYWHm95CEg8eDf85KvCVzPbTKm2ZcS/7Dx5w7AiEA
k/4u83CLUFizih+iJevMVXPHI99yeb6NT0lQnIZ8MFMAdgCRLn+OXTXy73s/VluY
uYC5VyaVUxTiFkYL1+xTql7swQAAAVh3IQXYAAAEAwBHMEUCIHQR9Geg7t98Gk2t
BSPlHIHDFG+XP5UUKa2eUahE973oAiEA6i8/T8IlppNUXcrMbcjjLLPsaSqd158U
BC44Pr90Nw4wDQYJKoZIhvcNAQELBQADggEBACJqJMVEKtBfmB0mvhFtd5GV7818
G/THYsf1AtMuCt80Rtzm+EXAyBupIhRERa+/J40pAE/ZyhmS5lSOjTzViR1RsIUg
bo190CLpEvKHA7ckBssJRySMFQ6RSPavsOkpHvduCqVS2PSb9W1APFzDJPeC9gaM
/EKIy7iLp2fiBZrYkTCaxYEy0SZGaFkXeHC20/d5PXhnylEXEIPR2aogIlbgzaNg
RVTxIJddHhpHfW5c2lX+ERf3Ni0fcJqcCZBPyGHUDSYqNrDwRLQ6dyVxz1Jl0oAc
+IHuDDDKJ0ewjoXgV+KRXqa7URuonqA5stUl/susZzd4BlT2k/XnuS8+iQc=
-----END CERTIFICATE-----''';

    var lines = LineSplitter.split(pem)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    var base64 = lines.sublist(1, lines.length - 1).join('');
    var bytes = Uint8List.fromList(base64Decode(base64));
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    expect(topLevelSeq.elements!.length, 3);
    expect(topLevelSeq.totalEncodedByteLength, 1724);
    expect(topLevelSeq.valueByteLength, 1720);
    expect(topLevelSeq.elements!.elementAt(0) is ASN1Sequence, true);
    expect(topLevelSeq.elements!.elementAt(1) is ASN1Sequence, true);
    expect(topLevelSeq.elements!.elementAt(2) is ASN1BitString, true);

    var e1 = topLevelSeq.elements!.elementAt(0) as ASN1Sequence;
    var e2 = topLevelSeq.elements!.elementAt(1) as ASN1Sequence;
    var e3 = topLevelSeq.elements!.elementAt(2) as ASN1BitString;

    expect(e1.elements!.length, 8);
    expect(e1.totalEncodedByteLength, 1444);
    expect(e1.valueByteLength, 1440);
    expect(e1.elements!.elementAt(1) is ASN1Integer, true);
    expect(e1.elements!.elementAt(2) is ASN1Sequence, true);
    expect(e1.elements!.elementAt(3) is ASN1Sequence, true);
    expect(e1.elements!.elementAt(4) is ASN1Sequence, true);
    expect(e1.elements!.elementAt(5) is ASN1Sequence, true);
    expect(e1.elements!.elementAt(6) is ASN1Sequence, true);

    var asn1Object = e1.elements!.elementAt(0);

    var integer1 =
        ASN1Parser(asn1Object.valueBytes).nextObject() as ASN1Integer;

    expect(integer1.totalEncodedByteLength, 3);
    expect(integer1.valueByteLength, 1);
    expect(integer1.integer.toString(), '2');

    var integer2 = e1.elements!.elementAt(1) as ASN1Integer;
    expect(integer2.totalEncodedByteLength, 18);
    expect(integer2.valueByteLength, 16);
    expect(
        integer2.integer.toString(), '49732821766751726239505489314635506967');

    expect(e2.elements!.length, 2);
    expect(e2.totalEncodedByteLength, 15);
    expect(e2.valueByteLength, 13);
    expect(e2.elements!.elementAt(0) is ASN1ObjectIdentifier, true);
    expect(e2.elements!.elementAt(1) is ASN1Null, true);

    expect(e3.elements, null);
    expect(e3.isConstructed, false);
    expect(e3.encodedBytes!.length, 261);
    expect(e3.valueByteLength, 257);
    expect(e3.stringValues!.length, 256);
  });
}
