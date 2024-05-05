# mquery

`mquery` is a fluent mongodb query builder designed to run in multiple environments.

[![Build Status](https://travis-ci.org/aheckmann/mquery.svg?branch=master)](https://travis-ci.org/aheckmann/mquery)
[![NPM version](https://badge.fury.io/js/mquery.svg)](http://badge.fury.io/js/mquery)

[![npm](https://nodei.co/npm/mquery.png)](https://www.npmjs.com/package/mquery)

## Features

- fluent query builder api
- custom base query support
- MongoDB 2.4 geoJSON support
- method + option combinations validation
- node.js driver compatibility
- environment detection
- [debug](https://github.com/visionmedia/debug) support
- separated collection implementations for maximum flexibility

## Use

```js
const mongo = require('mongodb');

const client = new mongo.MongoClient(uri);
await client.connect();
// get a collection
const collection = client.collection('artists');

// pass it to the constructor
await mquery(collection).find({...});

// or pass it to the collection method
const docs = await mquery().find({...}).collection(collection);

// or better yet, create a custom query constructor that has it always set
const Artist = mquery(collection).toConstructor();
const docs = await Artist().find(...).where(...);
```

`mquery` requires a collection object to work with. In the example above we just pass the collection object created using the official [MongoDB driver](https://github.com/mongodb/node-mongodb-native).

## Fluent API

- [mquery](#mquery)
  - [Features](#features)
  - [Use](#use)
  - [Fluent API](#fluent-api)
  - [Helpers](#helpers)
    - [find()](#find)
    - [findOne()](#findone)
    - [count()](#count)
    - [findOneAndUpdate()](#findoneandupdate)
        - [findOneAndUpdate() options](#findoneandupdate-options)
    - [findOneAndRemove()](#findoneandremove)
        - [findOneAndRemove() options](#findoneandremove-options)
    - [distinct()](#distinct)
    - [exec()](#exec)
    - [stream()](#stream)
    - [all()](#all)
    - [and()](#and)
    - [box()](#box)
    - [circle()](#circle)
    - [elemMatch()](#elemmatch)
    - [equals()](#equals)
    - [exists()](#exists)
    - [geometry()](#geometry)
    - [gt()](#gt)
    - [gte()](#gte)
    - [in()](#in)
    - [intersects()](#intersects)
    - [lt()](#lt)
    - [lte()](#lte)
    - [maxDistance()](#maxdistance)
    - [mod()](#mod)
    - [ne()](#ne)
    - [nin()](#nin)
    - [nor()](#nor)
    - [near()](#near)
      - [Example](#example)
    - [or()](#or)
    - [polygon()](#polygon)
    - [regex()](#regex)
    - [select()](#select)
        - [String syntax](#string-syntax)
    - [selected()](#selected)
    - [selectedInclusively()](#selectedinclusively)
    - [selectedExclusively()](#selectedexclusively)
    - [size()](#size)
    - [slice()](#slice)
    - [within()](#within)
    - [where()](#where)
    - [$where()](#where-1)
    - [batchSize()](#batchsize)
    - [collation()](#collation)
    - [comment()](#comment)
    - [hint()](#hint)
    - [j()](#j)
    - [limit()](#limit)
    - [maxTime()](#maxtime)
    - [skip()](#skip)
    - [sort()](#sort)
    - [read()](#read)
        - [Preferences:](#preferences)
        - [Preference Tags:](#preference-tags)
    - [readConcern()](#readconcern)
        - [Read Concern Level:](#read-concern-level)
    - [writeConcern()](#writeconcern)
        - [Write Concern:](#write-concern)
    - [slaveOk()](#slaveok)
    - [tailable()](#tailable)
    - [wtimeout()](#wtimeout)
  - [Helpers](#helpers-1)
    - [collection()](#collection)
    - [then()](#then)
    - [merge(object)](#mergeobject)
    - [setOptions(options)](#setoptionsoptions)
        - [setOptions() options](#setoptions-options)
    - [setTraceFunction(func)](#settracefunctionfunc)
    - [mquery.setGlobalTraceFunction(func)](#mquerysetglobaltracefunctionfunc)
    - [mquery.canMerge(conditions)](#mquerycanmergeconditions)
  - [mquery.use$geoWithin](#mqueryusegeowithin)
  - [Custom Base Queries](#custom-base-queries)
  - [Validation](#validation)
  - [Debug support](#debug-support)
  - [General compatibility](#general-compatibility)
      - [ObjectIds](#objectids)
      - [Read Preferences](#read-preferences)
  - [Future goals](#future-goals)
  - [Installation](#installation)
  - [License](#license)

## Helpers

- [collection](#collection)
- [then](#then)
- [merge](#mergeobject)
- [setOptions](#setoptionsoptions)
- [setTraceFunction](#settracefunctionfunc)
- [mquery.setGlobalTraceFunction](#mquerysetglobaltracefunctionfunc)
- [mquery.canMerge](#mquerycanmergeconditions)
- [mquery.use$geoWithin](#mqueryusegeowithin)

### find()

Declares this query a _find_ query. Optionally pass a match clause.

```js
mquery().find()
mquery().find(match)
await mquery().find()
const docs = await mquery().find(match);
assert(Array.isArray(docs));
```

### findOne()

Declares this query a _findOne_ query. Optionally pass a match clause.

```js
mquery().findOne()
mquery().findOne(match)
await mquery().findOne()
const doc = await mquery().findOne(match);
if (doc) {
  // the document may not be found
  console.log(doc);
}
```

### count()

Declares this query a _count_ query. Optionally pass a match clause.

```js
mquery().count()
mquery().count(match)
await mquery().count()
const number = await mquery().count(match);
console.log('we found %d matching documents', number);
```

### findOneAndUpdate()

Declares this query a _findAndModify_ with update query. Optionally pass a match clause, update document, options.

When executed, the first matching document (if found) is modified according to the update document and passed back.

#### findOneAndUpdate() options

Options are passed to the `setOptions()` method.

- `returnDocument`: string - `'after'` to return the modified document rather than the original. defaults to `'before'`
- `upsert`: boolean - creates the object if it doesn't exist. defaults to false
- `sort`: if multiple docs are found by the match condition, sets the sort order to choose which doc to update

```js
query.findOneAndUpdate()
query.findOneAndUpdate(updateDocument)
query.findOneAndUpdate(match, updateDocument)
query.findOneAndUpdate(match, updateDocument, options)

// the following all execute the command
await query.findOneAndUpdate()
await query.findOneAndUpdate(updateDocument)
await query.findOneAndUpdate(match, updateDocument)
const doc = await await query.findOneAndUpdate(match, updateDocument, options);
if (doc) {
  // the document may not be found
  console.log(doc);
}
```

### findOneAndRemove()

Declares this query a _findAndModify_ with remove query. Alias of findOneAndDelete.
Optionally pass a match clause, options.

When executed, the first matching document (if found) is modified according to the update document, removed from the collection and passed as a result.

#### findOneAndRemove() options

Options are passed to the `setOptions()` method.

- `sort`: if multiple docs are found by the condition, sets the sort order to choose which doc to modify and remove

```js
A.where().findOneAndDelete()
A.where().findOneAndRemove()
A.where().findOneAndRemove(match)
A.where().findOneAndRemove(match, options)

// the following all execute the command
await A.where().findOneAndRemove()
await A.where().findOneAndRemove(match)
const doc = await A.where().findOneAndRemove(match, options);
if (doc) {
  // the document may not be found
  console.log(doc);
}
```

### distinct()

Declares this query a _distinct_ query. Optionally pass the distinct field, a match clause.

```js
mquery().distinct()
mquery().distinct(match)
mquery().distinct(match, field)
mquery().distinct(field)

// the following all execute the command
await mquery().distinct()
await mquery().distinct(field)
await mquery().distinct(match)
const result = await mquery().distinct(match, field);
console.log(result);
```

### exec()

Executes the query.

```js
const docs = await mquery().findOne().where('route').intersects(polygon).exec()
```

### stream()

Executes the query and returns a stream.

```js
var stream = mquery().find().stream(options);
stream.on('data', cb);
stream.on('close', fn);
```

Note: this only works with `find()` operations.

Note: returns the stream object directly from the node-mongodb-native driver. (currently streams1 type stream). Any options will be passed along to the [driver method](http://mongodb.github.io/node-mongodb-native/api-generated/cursor.html#stream).

---

### all()

Specifies an `$all` query condition

```js
mquery().where('permission').all(['read', 'write'])
```

[MongoDB documentation](http://docs.mongodb.org/manual/reference/operator/all/)

### and()

Specifies arguments for an `$and` condition

```js
mquery().and([{ color: 'green' }, { status: 'ok' }])
```

[MongoDB documentation](http://docs.mongodb.org/manual/reference/operator/and/)

### box()

Specifies a `$box` condition

```js
var lowerLeft = [40.73083, -73.99756]
var upperRight= [40.741404,  -73.988135]

mquery().where('location').within().box(lowerLeft, upperRight)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/box/)

### circle()

Specifies a `$center` or `$centerSphere` condition.

```js
var area = { center: [50, 50], radius: 10, unique: true }
query.where('loc').within().circle(area)
query.circle('loc', area);

// for spherical calculations
var area = { center: [50, 50], radius: 10, unique: true, spherical: true }
query.where('loc').within().circle(area)
query.circle('loc', area);
```

- [MongoDB Documentation - center](http://docs.mongodb.org/manual/reference/operator/center/)
- [MongoDB Documentation - centerSphere](http://docs.mongodb.org/manual/reference/operator/centerSphere/)

### elemMatch()

Specifies an `$elemMatch` condition

```js
query.where('comment').elemMatch({ author: 'autobot', votes: {$gte: 5}})

query.elemMatch('comment', function (elem) {
  elem.where('author').equals('autobot');
  elem.where('votes').gte(5);
})
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/elemMatch/)

### equals()

Specifies the complementary comparison value for the path specified with `where()`.

```js
mquery().where('age').equals(49);

// is the same as

mquery().where({ 'age': 49 });
```

### exists()

Specifies an `$exists` condition

```js
// { name: { $exists: true }}
mquery().where('name').exists()
mquery().where('name').exists(true)
mquery().exists('name')

// { name: { $exists: false }}
mquery().where('name').exists(false);
mquery().exists('name', false);
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/exists/)

### geometry()

Specifies a `$geometry` condition

```js
var polyA = [[[ 10, 20 ], [ 10, 40 ], [ 30, 40 ], [ 30, 20 ]]]
query.where('loc').within().geometry({ type: 'Polygon', coordinates: polyA })

// or
var polyB = [[ 0, 0 ], [ 1, 1 ]]
query.where('loc').within().geometry({ type: 'LineString', coordinates: polyB })

// or
var polyC = [ 0, 0 ]
query.where('loc').within().geometry({ type: 'Point', coordinates: polyC })

// or
query.where('loc').intersects().geometry({ type: 'Point', coordinates: polyC })

// or
query.where('loc').near().geometry({ type: 'Point', coordinates: [3,5] })
```

`geometry()` **must** come after `intersects()`, `within()`, or `near()`.

The `object` argument must contain `type` and `coordinates` properties.

- type `String`
- coordinates `Array`

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/geometry/)

### gt()

Specifies a `$gt` query condition.

```js
mquery().where('clicks').gt(999)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/gt/)

### gte()

Specifies a `$gte` query condition.

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/gte/)

```js
mquery().where('clicks').gte(1000)
```

### in()

Specifies an `$in` query condition.

```js
mquery().where('author_id').in([3, 48901, 761])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/in/)

### intersects()

Declares an `$geoIntersects` query for `geometry()`.

```js
query.where('path').intersects().geometry({
    type: 'LineString'
  , coordinates: [[180.0, 11.0], [180, 9.0]]
})

// geometry arguments are supported
query.where('path').intersects({
    type: 'LineString'
  , coordinates: [[180.0, 11.0], [180, 9.0]]
})
```

**Must** be used after `where()`.

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/geoIntersects/)

### lt()

Specifies a `$lt` query condition.

```js
mquery().where('clicks').lt(50)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/lt/)

### lte()

Specifies a `$lte` query condition.

```js
mquery().where('clicks').lte(49)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/lte/)

### maxDistance()

Specifies a `$maxDistance` query condition.

```js
mquery().where('location').near({ center: [139, 74.3] }).maxDistance(5)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/maxDistance/)

### mod()

Specifies a `$mod` condition

```js
mquery().where('count').mod(2, 0)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/mod/)

### ne()

Specifies a `$ne` query condition.

```js
mquery().where('status').ne('ok')
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/ne/)

### nin()

Specifies an `$nin` query condition.

```js
mquery().where('author_id').nin([3, 48901, 761])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/nin/)

### nor()

Specifies arguments for an `$nor` condition.

```js
mquery().nor([{ color: 'green' }, { status: 'ok' }])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/nor/)

### near()

Specifies arguments for a `$near` or `$nearSphere` condition.

These operators return documents sorted by distance.

#### Example

```js
query.where('loc').near({ center: [10, 10] });
query.where('loc').near({ center: [10, 10], maxDistance: 5 });
query.near('loc', { center: [10, 10], maxDistance: 5 });

// GeoJSON
query.where('loc').near({ center: { type: 'Point', coordinates: [10, 10] }});
query.where('loc').near({ center: { type: 'Point', coordinates: [10, 10] }, maxDistance: 5, spherical: true });
query.where('loc').near().geometry({ type: 'Point', coordinates: [10, 10] });

// For a $nearSphere condition, pass the `spherical` option.
query.near({ center: [10, 10], maxDistance: 5, spherical: true });
```

[MongoDB Documentation](http://www.mongodb.org/display/DOCS/Geospatial+Indexing)

### or()

Specifies arguments for an `$or` condition.

```js
mquery().or([{ color: 'red' }, { status: 'emergency' }])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/or/)

### polygon()

Specifies a `$polygon` condition

```js
mquery().where('loc').within().polygon([10,20], [13, 25], [7,15])
mquery().polygon('loc', [10,20], [13, 25], [7,15])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/polygon/)

### regex()

Specifies a `$regex` query condition.

```js
mquery().where('name').regex(/^sixstepsrecords/)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/regex/)

### select()

Specifies which document fields to include or exclude

```js
// 1 means include, 0 means exclude
mquery().select({ name: 1, address: 1, _id: 0 })

// or

mquery().select('name address -_id')
```

#### String syntax

When passing a string, prefixing a path with `-` will flag that path as excluded. When a path does not have the `-` prefix, it is included.

```js
// include a and b, exclude c
query.select('a b -c');

// or you may use object notation, useful when
// you have keys already prefixed with a "-"
query.select({a: 1, b: 1, c: 0});
```

_Cannot be used with `distinct()`._

### selected()

Determines if the query has selected any fields.

```js
var query = mquery();
query.selected() // false
query.select('-name');
query.selected() // true
```

### selectedInclusively()

Determines if the query has selected any fields inclusively.

```js
var query = mquery().select('name');
query.selectedInclusively() // true

var query = mquery();
query.selected() // false
query.select('-name');
query.selectedInclusively() // false
query.selectedExclusively() // true
```

### selectedExclusively()

Determines if the query has selected any fields exclusively.

```js
var query = mquery().select('-name');
query.selectedExclusively() // true

var query = mquery();
query.selected() // false
query.select('name');
query.selectedExclusively() // false
query.selectedInclusively() // true
```

### size()

Specifies a `$size` query condition.

```js
mquery().where('someArray').size(6)
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/size/)

### slice()

Specifies a `$slice` projection for a `path`

```js
mquery().where('comments').slice(5)
mquery().where('comments').slice(-5)
mquery().where('comments').slice([-10, 5])
```

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/projection/slice/)

### within()

Sets a `$geoWithin` or `$within` argument for geo-spatial queries.

```js
mquery().within().box()
mquery().within().circle()
mquery().within().geometry()

mquery().where('loc').within({ center: [50,50], radius: 10, unique: true, spherical: true });
mquery().where('loc').within({ box: [[40.73, -73.9], [40.7, -73.988]] });
mquery().where('loc').within({ polygon: [[],[],[],[]] });

mquery().where('loc').within([], [], []) // polygon
mquery().where('loc').within([], []) // box
mquery().where('loc').within({ type: 'LineString', coordinates: [...] }); // geometry
```

As of mquery 2.0, `$geoWithin` is used by default. This impacts you if running MongoDB < 2.4. To alter this behavior, see [mquery.use$geoWithin](#mqueryusegeowithin).

**Must** be used after `where()`.

[MongoDB Documentation](http://docs.mongodb.org/manual/reference/operator/geoWithin/)

### where()

Specifies a `path` for use with chaining

```js
// instead of writing:
mquery().find({age: {$gte: 21, $lte: 65}});

// we can instead write:
mquery().where('age').gte(21).lte(65);

// passing query conditions is permitted too
mquery().find().where({ name: 'vonderful' })

// chaining
await mquery()
  .where('age').gte(21).lte(65)
  .where({ 'name': /^vonderful/i })
  .where('friends').slice(10)
  .exec()
```

### $where()

Specifies a `$where` condition.

Use `$where` when you need to select documents using a JavaScript expression.

```js
await query.$where('this.comments.length > 10 || this.name.length > 5').exec()

query.$where(function () {
  return this.comments.length > 10 || this.name.length > 5;
})
```

Only use `$where` when you have a condition that cannot be met using other MongoDB operators like `$lt`. Be sure to read about all of [its caveats](http://docs.mongodb.org/manual/reference/operator/where/) before using.

---

### batchSize()

Specifies the batchSize option.

```js
query.batchSize(100)
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/cursor.batchSize/)

### collation()

Specifies the collation option.

```js
query.collation({ locale: "en_US", strength: 1 })
```

[MongoDB documentation](https://docs.mongodb.com/manual/reference/method/cursor.collation/#cursor.collation)

### comment()

Specifies the comment option.

```js
query.comment('login query');
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/operator/)

### hint()

Sets query hints.

```js
mquery().hint({ indexA: 1, indexB: -1 })
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/operator/hint/)

### j()

Requests acknowledgement that this operation has been persisted to MongoDB's on-disk journal.

This option is only valid for operations that write to the database:

- `deleteOne()`
- `deleteMany()`
- `findOneAndDelete()`
- `findOneAndUpdate()`
- `updateOne()`
- `updateMany()`

Defaults to the `j` value if it is specified in [writeConcern](#writeconcern)

```js
mquery().j(true);
```

### limit()

Specifies the limit option.

```js
query.limit(20)
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/cursor.limit/)

### maxTime()

Specifies the maxTimeMS option.

```js
query.maxTime(100)
query.maxTimeMS(100)
```

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/cursor.maxTimeMS/)

### skip()

Specifies the skip option.

```js
query.skip(100).limit(20)
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/cursor.skip/)

### sort()

Sets the query sort order.

If an object is passed, key values allowed are `asc`, `desc`, `ascending`, `descending`, `1`, and `-1`.

If a string is passed, it must be a space delimited list of path names. The sort order of each path is ascending unless the path name is prefixed with `-` which will be treated as descending.

```js
// these are equivalent
query.sort({ field: 'asc', test: -1 });
query.sort('field -test');
```

_Cannot be used with `distinct()`._

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/cursor.sort/)

### read()

Sets the readPreference option for the query.

```js
mquery().read('primary')
mquery().read('p')  // same as primary

mquery().read('primaryPreferred')
mquery().read('pp') // same as primaryPreferred

mquery().read('secondary')
mquery().read('s')  // same as secondary

mquery().read('secondaryPreferred')
mquery().read('sp') // same as secondaryPreferred

mquery().read('nearest')
mquery().read('n')  // same as nearest

mquery().setReadPreference('primary') // alias of .read()
```

#### Preferences:

- `primary` - (default) Read from primary only. Operations will produce an error if primary is unavailable. Cannot be combined with tags.
- `secondary` - Read from secondary if available, otherwise error.
- `primaryPreferred` - Read from primary if available, otherwise a secondary.
- `secondaryPreferred` - Read from a secondary if available, otherwise read from the primary.
- `nearest` - All operations read from among the nearest candidates, but unlike other modes, this option will include both the primary and all secondaries in the random selection.

Aliases

- `p`   primary
- `pp`  primaryPreferred
- `s`   secondary
- `sp`  secondaryPreferred
- `n`   nearest

#### Preference Tags:

To keep the separation of concerns between `mquery` and your driver
clean, `mquery#read()` no longer handles specifying a second `tags` argument as of version 0.5.
If you need to specify tags, pass any non-string argument as the first argument.
`mquery` will pass this argument untouched to your collections methods later.
For example:

```js
// example of specifying tags using the Node.js driver
var ReadPref = require('mongodb').ReadPreference;
var preference = new ReadPref('secondary', [{ dc:'sf', s: 1 },{ dc:'ma', s: 2 }]);
mquery(...).read(preference).exec();
```

Read more about how to use read preferences [here](http://docs.mongodb.org/manual/applications/replication/#read-preference) and [here](http://mongodb.github.com/node-mongodb-native/driver-articles/anintroductionto1_1and2_2.html#read-preferences).

### readConcern()

Sets the readConcern option for the query.

```js
// local
mquery().readConcern('local')
mquery().readConcern('l')
mquery().r('l')

// available
mquery().readConcern('available')
mquery().readConcern('a')
mquery().r('a')

// majority
mquery().readConcern('majority')
mquery().readConcern('m')
mquery().r('m')

// linearizable
mquery().readConcern('linearizable')
mquery().readConcern('lz')
mquery().r('lz')

// snapshot
mquery().readConcern('snapshot')
mquery().readConcern('s')
mquery().r('s')
```

#### Read Concern Level:

- `local` - The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back). (MongoDB 3.2+)
- `available` - The query returns from the instance with no guarantee guarantee that the data has been written to a majority of the replica set members (i.e. may be rolled back). (MongoDB 3.6+)
- `majority` - The query returns the data that has been acknowledged by a majority of the replica set members. The documents returned by the read operation are durable, even in the event of failure. (MongoDB 3.2+)
- `linearizable` - The query returns data that reflects all successful majority-acknowledged writes that completed prior to the start of the read operation. The query may wait for concurrently executing writes to propagate to a majority of replica set members before returning results. (MongoDB 3.4+)
- `snapshot` - Only available for operations within multi-document transactions. Upon transaction commit with write concern "majority", the transaction operations are guaranteed to have read from a snapshot of majority-committed data. (MongoDB 4.0+)

Aliases

- `l`   local
- `a`   available
- `m`   majority
- `lz`  linearizable
- `s`   snapshot

Read more about how to use read concern [here](https://docs.mongodb.com/manual/reference/read-concern/).

### writeConcern()

Sets the writeConcern option for the query.

This option is only valid for operations that write to the database:

- `deleteOne()`
- `deleteMany()`
- `findOneAndDelete()`
- `findOneAndUpdate()`
- `updateOne()`
- `updateMany()`

```js
mquery().writeConcern(0)
mquery().writeConcern(1)
mquery().writeConcern({ w: 1, j: true, wtimeout: 2000 })
mquery().writeConcern('majority')
mquery().writeConcern('m') // same as majority
mquery().writeConcern('tagSetName') // if the tag set is 'm', use .writeConcern({ w: 'm' }) instead
mquery().w(1) // w is alias of writeConcern
```

#### Write Concern:

writeConcern({ w: `<value>`, j: `<boolean>`, wtimeout: `<number>` }`)

- the w option to request acknowledgement that the write operation has propagated to a specified number of mongod instances or to mongod instances with specified tags
- the j option to request acknowledgement that the write operation has been written to the journal
- the wtimeout option to specify a time limit to prevent write operations from blocking indefinitely

Can be break down to use the following syntax:

mquery().w(`<value>`).j(`<boolean>`).wtimeout(`<number>`)

Read more about how to use write concern [here](https://docs.mongodb.com/manual/reference/write-concern/)

### slaveOk()

Sets the slaveOk option. `true` allows reading from secondaries.

**deprecated** use [read()](#read) preferences instead if on mongodb >= 2.2

```js
query.slaveOk() // true
query.slaveOk(true)
query.slaveOk(false)
```

[MongoDB documentation](http://docs.mongodb.org/manual/reference/method/rs.slaveOk/)

### tailable()

Sets tailable option.

```js
mquery().tailable() <== true
mquery().tailable(true)
mquery().tailable(false)
```

_Cannot be used with `distinct()`._

[MongoDB Documentation](http://docs.mongodb.org/manual/tutorial/create-tailable-cursor/)

### wtimeout()

Specifies a time limit, in milliseconds, for the write concern. If `w > 1`, it is maximum amount of time to
wait for this write to propagate through the replica set before this operation fails. The default is `0`, which means no timeout.

This option is only valid for operations that write to the database:

- `deleteOne()`
- `deleteMany()`
- `findOneAndDelete()`
- `findOneAndUpdate()`
- `updateOne()`
- `updateMany()`

Defaults to `wtimeout` value if it is specified in [writeConcern](#writeconcern)

```js
mquery().wtimeout(2000)
mquery().wTimeout(2000)
```

## Helpers

### collection()

Sets the querys collection.

```js
mquery().collection(aCollection)
```

### then()

Executes the query and returns a promise which will be resolved with the query results or rejected if the query responds with an error.

```js
mquery().find(..).then(success, error);
```

This is very useful when combined with [co](https://github.com/visionmedia/co) or [koa](https://github.com/koajs/koa), which automatically resolve promise-like objects for you.

```js
co(function*(){
  var doc = yield mquery().findOne({ _id: 499 });
  console.log(doc); // { _id: 499, name: 'amazing', .. }
})();
```

_NOTE_:
The returned promise is a [bluebird](https://github.com/petkaantonov/bluebird/) promise but this is customizable. If you want to
use your favorite promise library, simply set `mquery.Promise = YourPromiseConstructor`.
Your `Promise` must be [promises A+](http://promisesaplus.com/) compliant.

### merge(object)

Merges other mquery or match condition objects into this one. When an mquery instance is passed, its match conditions, field selection and options are merged.

```js
const drum = mquery({ type: 'drum' }).collection(instruments);
const redDrum = mquery({ color: 'red' }).merge(drum);
const n = await redDrum.count();
console.log('there are %d red drums', n);
```

Internally uses `mquery.canMerge` to determine validity.

### setOptions(options)

Sets query options.

```js
mquery().setOptions({ collection: coll, limit: 20 })
```

#### setOptions() options

- [tailable](#tailable) *
- [sort](#sort) *
- [limit](#limit) *
- [skip](#skip) *
- [maxTime](#maxtime) *
- [batchSize](#batchsize) *
- [comment](#comment) *
- [hint](#hint) *
- [collection](#collection): the collection to query against

_* denotes a query helper method is also available_

### setTraceFunction(func)

Set a function to trace this query. Useful for profiling or logging.

```js
function traceFunction (method, queryInfo, query) {
  console.log('starting ' + method + ' query');

  return function (err, result, millis) {
    console.log('finished ' + method + ' query in ' + millis + 'ms');
  };
}

mquery().setTraceFunction(traceFunction).findOne({name: 'Joe'}, cb);
```

The trace function is passed (method, queryInfo, query)

- method is the name of the method being called (e.g. findOne)
- queryInfo contains information about the query:
  - conditions: query conditions/criteria
  - options: options such as sort, fields, etc
  - doc: document being updated
- query is the query object

The trace function should return a callback function which accepts:
- err: error, if any
- result: result, if any
- millis: time spent waiting for query result

NOTE: stream requests are not traced.

### mquery.setGlobalTraceFunction(func)

Similar to `setTraceFunction()` but automatically applied to all queries.

```js
mquery.setTraceFunction(traceFunction);
```

### mquery.canMerge(conditions)

Determines if `conditions` can be merged using `mquery().merge()`.

```js
var query = mquery({ type: 'drum' });
var okToMerge = mquery.canMerge(anObject)
if (okToMerge) {
  query.merge(anObject);
}
```

## mquery.use$geoWithin

MongoDB 2.4 introduced the `$geoWithin` operator which replaces and is 100% backward compatible with `$within`. As of mquery 0.2, we default to using `$geoWithin` for all `within()` calls.

If you are running MongoDB < 2.4 this will be problematic. To force `mquery` to be backward compatible and always use `$within`, set the `mquery.use$geoWithin` flag to `false`.

```js
mquery.use$geoWithin = false;
```

## Custom Base Queries

Often times we want custom base queries that encapsulate predefined criteria. With `mquery` this is easy. First create the query you want to reuse and call its `toConstructor()` method which returns a new subclass of `mquery` that retains all options and criteria of the original.

```js
var greatMovies = mquery(movieCollection).where('rating').gte(4.5).toConstructor();

// use it!
const n = await greatMovies().count();
console.log('There are %d great movies', n);

const docs = await greatMovies().where({ name: /^Life/ }).select('name').find();
console.log(docs);
```

## Validation

Method and options combinations are checked for validity at runtime to prevent creation of invalid query constructs. For example, a `distinct` query does not support specifying options like `hint` or field selection. In this case an error will be thrown so you can catch these mistakes in development.

## Debug support

Debug mode is provided through the use of the [debug](https://github.com/visionmedia/debug) module. To enable:

```sh
DEBUG=mquery node yourprogram.js
```

Read the debug module documentation for more details.

## General compatibility

### ObjectIds

`mquery` clones query arguments before passing them to a `collection` method for execution.
This prevents accidental side-affects to the objects you pass.
To clone `ObjectIds` we need to make some assumptions.

First, to check if an object is an `ObjectId`, we check its constructors name. If it matches either
`ObjectId` or `ObjectID` we clone it.

To clone `ObjectIds`, we call its optional `clone` method. If a `clone` method does not exist, we fall
back to calling `new obj.constructor(obj.id)`. We assume, for compatibility with the
Node.js driver, that the `ObjectId` instance has a public `id` property and that
when creating an `ObjectId` instance we can pass that `id` as an argument.

#### Read Preferences

`mquery` supports specifying [Read Preferences](https://www.mongodb.com/docs/manual/core/read-preference/) to control from which MongoDB node your query will read.
The Read Preferences spec also support specifying tags. To pass tags, some
drivers (Node.js driver) require passing a special constructor that handles both the read preference and its tags.
If you need to specify tags, pass an instance of your drivers ReadPreference constructor or roll your own. `mquery` will store whatever you provide and pass later to your collection during execution.

## Future goals

- mongo shell compatibility
- browser compatibility

## Installation

```sh
npm install mquery
```

## License

[MIT](https://github.com/aheckmann/mquery/blob/master/LICENSE)
