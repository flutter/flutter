# Development guide

## Check list

* run test
* no warning
* string mode / implicit-casts: false
* run the example

## Publishing

    flutter packages pub publish
    
## Testing

### Using `test_driver`

Check [sqflite_test_app](../../sqflite_test_app/README.md).

Also, from the `example` folder, you should be able to run some native tests using:

    flutter driver test_driver/main.dart
    

### Github Branches

#### develop

Development is done on the develop branch.

[![pub package](https://img.shields.io/pub/vpre/sqflite.svg)](https://pub.dev/packages/sqflite)

#### master

Published version are merged on master.

[![pub package](https://img.shields.io/pub/v/sqflite.svg)](https://pub.dev/packages/sqflite)
