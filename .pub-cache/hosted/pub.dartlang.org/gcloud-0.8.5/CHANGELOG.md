## 0.8.5

- Support the latest version 7.0.0 of the `googleapis` package.

## 0.8.4

- Support the latest version 6.0.0 of the `googleapis` package.

## 0.8.3

- Support the latest version of the `googleapis` package.

## 0.8.2

 * **BREAKING CHANGE:** `Page.next()` throws if `Page.isLast`, this change only
   affects code not migrated to null-safety, when paging through results in
   pub-sub and storage without checking `Page.isLast`.
   Code fully migrated to null-safety will have experienced a runtime null check
   error, and paging code for datastore already throw an `Error`.

## 0.8.1

 * `lookupOrNull` method in `DatastoreDB` and `Transaction`. 

## 0.8.0

 * Require Dart 2.12 or later
 * Migration to null safety.

## 0.7.3
 * Fixed issue in reflection code affecting `Model<int>` and `Model<String>`,
   but not `Model<dynamic>`.

## 0.7.2

 * Added `delimiter` to `Bucket.list` and `Bucket.page`
   (`0.7.1` only added them the implementation).

## 0.7.1

 * Added `delimiter` to `Bucket.list` and `Bucket.page`.
 * Fix typing of `ExpandoModel` to `ExpandoModel<T>` as we should have done in
   version `0.7.0`.

## 0.7.0+2
 
 * Upgrade dependency on `_discoveryapis_commons`, changing `ApiRequestError`
   from an `Error` to an `Exception`. Version constraints on
   `_discoveryapis_commons` allows both new and old versions.

## 0.7.0+1

 * Fix path separator in Bucket.list().
 
## 0.7.0

 * **BREAKING CHANGE:** Add generics support for `Model.id`.  
   It is now possible to define the type of the id a model has (either `String`
   or `int`). A model can now be defined as
   `class MyModel extends Model<String> {}` and `myModel.id` will then
   be of type `String` and `myModel.key` of type `Key<String>`.

## 0.6.4

 * Require minimum Dart SDK `2.3.0`.

## 0.6.3

 * Added `DatastoreDB.lookupValue()`

## 0.6.2

 * Fixed bug in `Transaction.rollback()`.

## 0.6.1

 * Added examples.
 * Fixed formatting and lints.
 * Allow `Model` classes to contain constructors with optional or named
   arguments (as long as they're annotated with `@required`).
 * Add generics support to `withTransaction()`.

## 0.6.0+4

 * Updated package description.
 * Added an example showing how to use Google Cloud Storage.

## 0.6.0+3

 * Fixed code formatting and lints.

## 0.6.0+2

* Support the latest `pkg:http`.

## 0.6.0+1

* Add explicit dependency to `package:_discoveryapis_commons`
* Widen sdk constraint to <3.0.0

## 0.6.0

* **BREAKING CHANGE:** Add generics support. Instead of writing
  `db.query(Person).run()` and getting back a generic `Stream<Model>`, you now
  write `db.query<Person>().run()` and get `Stream<Person>`.
  The same goes for `.lookup([key])`, which can now be written as
  `.lookup<Person>([key])` and will return a `List<Person>`.

## 0.5.0

* Fixes to support Dart 2.

## 0.4.0+1

* Made a number of strong-mode improvements.

* Updated dependency on `googleapis` and `googleapis_beta`.

## 0.4.0

* Remove support for `FilterRelation.In` and "propertyname IN" for queries:
  This is not supported by the newer APIs and was originally part of fat-client
  libraries which performed multiple queries for each iten in the list.

* Adds optional `forComparision` named argument to `Property.encodeValue` which
  will be set to `true` when encoding a value for comparison in queries.

* Upgrade to newer versions of `package:googleapis` and `package:googleapis_beta`

## 0.3.0

* Upgrade to use stable `package:googleapis/datastore/v1.dart`.

* The internal [DatastoreImpl] class takes now a project name without the `s~`
  prefix.

## 0.2.0+14

* Fix analyzer warning.

## 0.2.0+13

* Remove crypto dependency and upgrade dart dependency to >=1.13 since
  this dart version provides the Base64 codec.

## 0.2.0+11

* Throw a [StateError] in case a query returned a kind for which there was no
  model registered.

## 0.2.0+10

* Address analyzer warnings.

## 0.2.0+9

* Support value transformation in `db.query().filter()`.
* Widen constraint on `googleapis` and `googleapis_beta`.

## 0.2.0+8

* Widen constraint on `googleapis` and `googleapis_beta`.

## 0.2.0+4

* `Storage.read` now honors `offset` and `length` arguments.

## 0.2.0+2

* Widen constraint on `googleapis/googleapis_beta`

## 0.2.0+1

* Fix broken import of package:googleapis/common/common.dart.

## 0.2.0

* Add support for Cloud Pub/Sub.
* Require Dart version 1.9.

## 0.1.4+2

* Enforce fully populated entity keys in a number of places.

## 0.1.4+1

* Deduce the query partition automatically from query ancestor key.

## 0.1.4

* Added optional `defaultPartition` parameter to the constructor of
  `DatastoreDB`.

## 0.1.3+2

* Widened googleapis/googleapis_beta constraints in pubspec.yaml.

## 0.1.3+1

* Change the service scope keys keys to non-private symbols.

## 0.1.3

* Widen package:googleapis dependency constraint in pubspec.yaml.
* Bugfix in `package:appengine/db.dart`: Correctly handle ListProperties
of length 1.

## 0.1.2

* Introduced `package:gcloud/service_scope.dart` library.
* Added global getters for getting gcloud services from the current service
scope.
* Added an `package:gcloud/http.dart` library using service scopes.

## 0.1.1

* Increased version constraint on googleapis{,_auth,_beta}.

* Removed unused imports.

## 0.1.0

* First release.
