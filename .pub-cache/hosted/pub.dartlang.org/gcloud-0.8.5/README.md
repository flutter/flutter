## Google Cloud Platform support package (gcloud)

The `gcloud` package provides a high level "idiomatic Dart" interface to
some of the most widely used Google Cloud Platform services. Currently the
following services are supported:

  * Cloud Datastore
  * Cloud Storage
  * Cloud Pub/Sub

The APIs in this package are all based on the generic generated APIs in the
[googleapis] and [googleapis_beta][googleapisbeta] packages.

This means that the authentication model for using the APIs in this package
uses the [googleapis_auth][googleapisauth] package.

Note that this package is only intended for being used with the standalone VM
in a server or command line application. Don't expect this package to work on
the browser or in Flutter.

The code snippets below demonstrating the use of this package all assume that
the following imports are present:

```dart
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:gcloud/db.dart';
import 'package:gcloud/storage.dart';
import 'package:gcloud/pubsub.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:gcloud/datastore.dart' as datastore;
```

### Getting access to the APIs

The first step in using the APIs is to get an authenticated HTTP client and
with that create API class instances for accessing the different APIs. The
code below assumes that you have a Google Cloud Project called `my-project`
with credentials for a service account from that project stored in the file
`my-project.json`.

```dart
// Read the service account credentials from the file.
var jsonCredentials = new File('my-project.json').readAsStringSync();
var credentials = new auth.ServiceAccountCredentials.fromJson(jsonCredentials);

// Get an HTTP authenticated client using the service account credentials.
var scopes = []
    ..addAll(datastore.Datastore.Scopes)
    ..addAll(Storage.SCOPES)
    ..addAll(PubSub.SCOPES);
var client = await auth.clientViaServiceAccount(credentials, scopes);

// Instantiate objects to access Cloud Datastore, Cloud Storage
// and Cloud Pub/Sub APIs.
var db = new DatastoreDB(
    new datastore.Datastore(client, 's~my-project'));
var storage = new Storage(client, 'my-project');
var pubsub = new PubSub(client, 'my-project');
```

All the APIs in this package supports the use of 'service scopes'. Service
scopes are described in details below.

```dart
ss.fork(() {
  // register the services in the new service scope.
  registerDbService(db);
  registerStorageService(storage);
  registerPubSubService(pubsub);

  // Run application using these services.
});
```

The services registered with the service scope can now be reached from within
all the code running in the same service scope using the below getters.

```dart
dbService.
storageService.
pubsubService.
```

This way it is not necessary to pass the service objects around in your code.

### Use with App Engine

The `gcloud` package is also integrated in the Dart [appengine] package. This
means the `gcloud` services are available both via the appengine context and
service scopes. The authentication required to access the Google Cloud Platform
services is handled automatically.

This means that getting to the App Engine Datastore can be through either
the App Engine context

```dart
var db = context.services.db;
```

or just using the service scope registration.

```dart
var db = dbService;
```

## Cloud Datastore
Google Cloud Datastore provide a NoSQL, schemaless database for storing
non-relational data. See the product page
[https://cloud.google.com/datastore/][Datastore] for more information.

The Cloud Datastore API provides a mapping of Dart objects to entities stored
in the Datastore. The following example shows how to annotate a class to
make it possible to store instances of it in the Datastore.

```dart
@db.Kind()
class Person extends db.Model {
  @db.StringProperty()
  String name;

  @db.IntProperty()
  int age;
}
```

The `Kind` annotation tell that instances of this class can be stored. The
class must also inherit from `Model`. Now to store an object into the
Datastore create an instance and use the `commit` function.

```dart
var person = new Person()
    ..name = ''
    ..age = 42;
await db.commit(inserts: [person]);
```

The function `query` is used to build a `Query` object which can be run to
perform the query.

```dart
var persons = (await db.query<Person>().run()).toList();
```

To fetch one or multiple existing entities, use `lookup`.

```dart
var key = new Person()
    ..name = 'UniqueName'
    ..age = 42
    ..parentKey = db.emptyKey;
var person = (await db.lookup<Person>([key])).single;
var people = await db.lookup<Person>([key1, key2]);
```

NOTE: This package include a lower level API provided through the class
`Datastore` on top of which the `DatastoreDB` API is build. The main reason
for this additional API level is to bridge the gap between the different APIs
exposed inside App Engine and through the public REST API. We reserve the
rights to modify and maybe even remove this additional layer at any time.

## Cloud Storage
Google Cloud Storage provide a highly available object store (aka BLOB
store). See the product page [https://cloud.google.com/storage/][GCS]
for more information.

In Cloud Storage the objects (BLOBs) are organized in _buckets_. Each bucket
has a name in a global namespace. The following code creates a new bucket
named `my-bucket` and writes the content of the file `my-file.txt` to the
object named `my-object`.

```dart
var bucket = await storage.createBucket('my-bucket');
new File('my-file.txt').openRead().pipe(bucket.write('my-object'));
```

The following code will read back the object.

```dart
bucket.read('my-object').pipe(new File('my-file-copy.txt').openWrite());
```

## Cloud Pub/Sub
Google Cloud Pub/Sub provides many-to-many, asynchronous messaging. See the
product page [https://cloud.google.com/pubsub/][PubSub] for more information.

Cloud Pub/Sub uses two concepts for messaging. _Topics_ are used if you want
to send messages and _subscriptions_ are used to subscribe to topics and
receive the messages. This decouples the producer of a message from the
consumer of a message.

The following code creates a _topic_ and sends a simple test message:

```dart
var topic = await pubsub.createTopic('my-topic');
await topic.publishString('Hello, world!')
```

With the following code a _subscription_ is created on the _topic_ and
a message is pulled using the subscription. A received message must be
acknowledged when the consumer has processed it.

```dart
var subscription =
    await pubsub.createSubscription('my-subscription', 'my-topic');
var pullEvent = await subscription.pull();
print(pullEvent.message.asString);
await pullEvent.acknowledge();
```

It is also possible to receive messages using push events instead of pulling
from the subscription. To do this the subscription should be configured as a
push subscription with an HTTP endpoint.

```dart
await pubsub.createSubscription(
    'my-subscription',
    'my-topic',
    endpoint: Uri.parse('https://server.example.com/push'));
```

With this subscription all messages will be send to the URL provided in the
`endpoint` argument. The server needs to acknowledge the reception of the
message with a `200 OK` reply.

### Running tests

If you want to run the end-to-end tests, a Google Cloud project is required.
When running these tests the following environment variables need to be set:

    GCLOUD_E2E_TEST_PROJECT

The value of the environment variable `GCLOUD_E2E_TEST_PROJECT` is the name
of the Google Cloud project to use. Authentication for testing uses
[Application Default Credentials][ADC] locally you can provide
`GOOGLE_APPLICATION_CREDENTIALS` or use
[`gcloud auth application-default login`][gcloud-adc].

You will also need to create indexes as follows:

```bash
gcloud --project "$GCLOUD_E2E_TEST_PROJECT" datastore indexes create test/index.yaml
```

[Datastore]: https://cloud.google.com/datastore/
[GCS]: https://cloud.google.com/storage/
[PubSub]: https://cloud.google.com/pubsub/
[googleapis]: https://pub.dartlang.org/packages/googleapis
[googleapisbeta]: https://pub.dartlang.org/packages/googleapis_beta
[googleapisauth]: https://pub.dartlang.org/packages/googleapis_beta
[appengine]: https://pub.dartlang.org/packages/appengine
[ADC]: https://cloud.google.com/docs/authentication/production
[gcloud-adc]: https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login
