# ASN1

Pointycastle has a build in ASN1 support to handle the most common ASN1 objects.

## Overview

The package contains an ASN1Parser that can parse the ASN1 objects, like ASN1Integer, ASN1Sequence, ASN1BitString and many more.

## Supported ASN1 objects

The following table lists all supported types and the possible encoding and decoding rules supported.

| ASN1 Type         | Decode From                                                                                   | Encode To                                                                                     |
| ----------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| BOOLEAN           | DER                                                                                           | DER                                                                                           |
| INTEGER           | DER                                                                                           | DER                                                                                           |
| BIT_STRING        | DER / BER Constructed / BER Long Length Form / BER Padded / BER Constructed Indefinite Length | DER / BER Constructed / BER Long Length Form / BER Padded / BER Constructed Indefinite Length |
| OCTET_STRING      | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              |
| NULL              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              |
| OBJECT_IDENTIFIER | DER                                                                                           | DER                                                                                           |
| ENUMERATED        | DER                                                                                           | DER                                                                                           |
| UTF8_STRING       | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              |
| SEQUENCE          | DER                                                                                           | DER                                                                                           |
| SET               | DER                                                                                           | DER                                                                                           |
| PRINTABLE_STRING  | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              |
| IA5_STRING        | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              | DER / BER Constructed / BER Long Length Form / BER Constructed Indefinite Length              |
| UTC_TIME          | DER                                                                                           | DER                                                                                           |

More information about the different encoding rules can be found at <https://www.bouncycastle.org/asn1_layman_93.txt>

### Working with ASN1 objects

Every ASN1 object can be instanced in several ways.

#### Named constructor fromBytes

The fromBytes constructed will create an instance according to the given bytes. It detects automatically the encoding rule used within the given bytes.

#### Default constructor

The default constructor takes different arguments, depending on the object. Every default constructor automatically sets the right ASN1 tag. If needed the tag can also be overridden.

Example for the default constructor of an ASN1UTF8String entity:

```dart
var asn1Object = ASN1UTF8String(utf8StringValue: 'Hello World');
```

If an ASN1 object supports **constructed** encoding/decoding, the default constructor allows to pass a list of child elements. In this case, the tag needs to be set manually to the right constructed tag.

```dart
var e1 = ASN1UTF8String(utf8StringValue: 'Hello');

var e2 = ASN1UTF8String(utf8StringValue: ' World');

varar asn1Object = ASN1UTF8String(elements: [e1, e2], tag: ASN1Tags.UTF8_STRING_CONSTRUCTED);
```

## Parsing ASN1

To parse an ASN1Object, we need to pass the bytes representing the object to the parser. In this example we use the following structure :

```bash
   SEQUENCE (4 elem)
      SET (1 elem)
        SEQUENCE (2 elem)
          OBJECT IDENTIFIER 2.5.4.6 countryName (X.520 DN component)
          PrintableString US
      SET (1 elem)
        SEQUENCE (2 elem)
          OBJECT IDENTIFIER 2.5.4.10 organizationName (X.520 DN component)
          PrintableString DigiCert Inc
      SET (1 elem)
        SEQUENCE (2 elem)
          OBJECT IDENTIFIER 2.5.4.11 organizationalUnitName (X.520 DN component)
          PrintableString www.digicert.com
      SET (1 elem)
        SEQUENCE (2 elem)
          OBJECT IDENTIFIER 2.5.4.3 commonName (X.520 DN component)
          PrintableString Thawte RSA CA 2018
```

```dart
// Base64 encoded string that represents the above structure
var base64String =
        'MFwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xGzAZBgNVBAMTElRoYXd0ZSBSU0EgQ0EgMjAxOA==';
// Convert to byte list
var bytes = base64.decode(base64String);
// Pass the byte list to the ASN1Parser
var parser = ASN1Parser(bytes);
```

Now we can use the parser to move between every object within the above structure. The first element is an ASN1Sequence with 4 child elements.

```dart
// Grab the first element by calling nextObject() and cast it to ASN1Sequence
var sequence = parser.nextObject() as ASN1Sequence;
// Iterate over each element
sequence.elements.forEach((element) {
    var asn1Set = element as ASN1Set;
    var seq = asn1Set.elements.elementAt(0) as ASN1Sequence
    var objectIdentifier = seq.elements.elementAt(0) as ASN1ObjectIdentifier;
    var printableString = seq.elements.elementAt(1) as ASN1PrintableString;
    print('${objectIdentifier.objectIdentifierAsString} = ${printableString.stringValue}')
});
```

The above code will print out the following lines :

```bash
2.5.4.6 = US
2.5.4.10 = DigiCert Inc
2.5.4.11 = www.digicert.com
2.5.4.3 = Thawte RSA CA 2018
```

## Encoding ASN1

The ASN1 objects can be also used to create ASN1 structures and encode them and process them as base64 encoded string in other software. As an example, we will create a RSA Public Key PEM string.

```dart

final BEGIN_PUBLIC_KEY = '-----BEGIN PUBLIC KEY-----';
final END_PUBLIC_KEY = '-----END PUBLIC KEY-----';

// Create a new RSA pulic key
var publicKey;

// Create the top level sequence
var topLevelSeq = ASN1Sequence();

// Create the sequence holding the algorithm information
var algorithmSeq = ASN1Sequence();
var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
algorithmSeq.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1'));
algorithmSeq.add(paramsAsn1Obj);

// Create the constructed ASN1BitString
var modulus = ASN1Integer(publicKey.modulus);
var exponent = ASN1Integer(publicKey.exponent);
var publicKeySeqBitString = ASN1BitString(elements : [modulus, exponent], tag: ASN1Tags.BIT_STRING_CONSTRUCTED);

// Add ASN1 objects to the top level sequence
topLevelSeq.add(algorithmSeq);
topLevelSeq.add(publicKeySeqBitString);

// Encode base64
var dataBase64 = base64.encode(topLevelSeq.encodedBytes);
var chunks = StringUtils.chunk(dataBase64, 64);

print('$BEGIN_PUBLIC_KEY\n${chunks.join('\n')}\n$END_PUBLIC_KEY');
```

The result will be something similar to this:

```bash
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAg1ea9Y7zO2Gt7kzYOSp5
I4dZHY75ZCYNMegmg0obKVxauRXeBL+pfhuDgq1+k0Z3iOfOELczOgaonTsJiHo8
kQcqgYNj0dmKKb+/318+3aEIZa6PreIgWJ0scM0oupHeiEA/M45vQIDMOv6jjVa5
mB1u/nHXQpvzH1i4H9tlODTSvIoIabW2/14+JNIm1KNQz/H/NsbooraY6POvqGtr
Ek743CRJNH9mgEYEQnOF0dYiS8h+JoXxcIDuaLz/WCRx1AWvINj3YNBgiIc6N4/Y
2nv5lAKajhfh8grs7hCRvXUzT9wcvj9aNtmOHm4cH/WpVK4sXGuLxN1MxDyqaPIv
9QIDAQAB
-----END PUBLIC KEY-----
```

And the ASN1 structure looks like this :

```bash
SEQUENCE (2 elem)
  SEQUENCE (2 elem)
    OBJECT IDENTIFIER 1.2.840.113549.1.1.1 rsaEncryption (PKCS #1)
    NULL
  BIT STRING (2160 bit) 001100001000001000000001000010100000001010000010000000010000000100000…
    SEQUENCE (2 elem)
      INTEGER (2048 bit) 165804177387087149617220457493747588873959131224426853644136343567339…
      INTEGER 65537
```
