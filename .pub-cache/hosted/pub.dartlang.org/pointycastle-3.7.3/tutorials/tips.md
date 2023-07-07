# Tips on using Pointy Castle

### Use correct typing

The package makes great use of abstract classes, inheritance and
generic types.

Sometimes a method will return an abstract class that needs to be
cast into its actual type before it can be properly used.

```dart
final pair = keyGen.generateKeyPair(); // returns AsymmetricKeyPair<PublicKey, PrivateKey>

final pub = pair.publicKey; // PublicKey - not very useful
final pvt = pair.privateKey; // PrivateKey - not very useful

final rsaPub = pair.publicKey as RSAPublicKey;
final rsaPvt = pair.privateKey as RSAPrivateKey;
```

At other times, a generic typed parameter needs to be of a specific
subtype for the method to work (even though the type system accepts
the base generic type). Make the generic type more specific for the
subclass that is being used.

```dart
RSAPrivateKey pvtKey = ... // RSAPrivateKey implements PrivateKey
RSASigner signer = ...

// PrivateKeyParameter is defined as:
//
// class PrivateKeyParameter<T extends PrivateKey>
//     extends AsymmetricKeyParameter<T> {
//   PrivateKeyParameter(PrivateKey key) : super(key);
// }

// This is type correct, but won't work:

signer.init(true, PrivateKeyParameter(pvtKey)); // incorrect: fails at runtime

// This works:

signer.init(true, PrivateKeyParameter<RSAPrivateKey>(pvtKey)); // correct
```



### Algorithm name property

Every implementation classes have an `algorithmName` property.

If you have created an object and want to find out the name to use
with the registry, print out its `algorithmName`.

How do you find the class to create? A recursive _grep_ over the
source code can be very useful.

### Navigating the API reference

The [Pointy Castle API
reference](https://pub.dev/documentation/pointycastle/latest/) can be
difficult to navigate. Each implementation class is in a separate
library to improve the performance of loading (when used without the
registry) and the library names are long.

Try looking in the one of the combined libraries for classes:

- [export](https://pub.dev/documentation/pointycastle/latest/export/export-library.html)
- [api](https://pub.dev/documentation/pointycastle/latest/api/api-library.html)
- [pointycastle](https://pub.dev/documentation/pointycastle/latest/pointycastle/pointycastle-library.html)
