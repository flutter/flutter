**Installation**: `npm install sift`, or `yarn add sift`

## Sift is a tiny library for using MongoDB queries in Javascript

[![Build Status](https://secure.travis-ci.org/crcn/sift.js.png)](https://secure.travis-ci.org/crcn/sift.js)

<!-- [![Coverage Status](https://coveralls.io/repos/crcn/sift.js/badge.svg)](https://coveralls.io/r/crcn/sift.js)  -->
<!-- [![Join the chat at https://gitter.im/crcn/sift.js](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/crcn/sift.js?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) -->

**For extended documentation, checkout http://docs.mongodb.org/manual/reference/operator/query/**

## Features:

- Supported operators: [\$in](#in), [\$nin](#nin), [\$exists](#exists), [\$gte](#gte), [\$gt](#gt), [\$lte](#lte), [\$lt](#lt), [\$eq](#eq), [\$ne](#ne), [\$mod](#mod), [\$all](#all), [\$and](#and), [\$or](#or), [\$nor](#nor), [\$not](#not), [\$size](#size), [\$type](#type), [\$regex](#regex), [\$where](#where), [\$elemMatch](#elemmatch)
- Regexp searches
- Supports node.js, and web
- Custom Operations
- Tree-shaking (omitting functionality from web app bundles)

## Examples

```javascript
import sift from "sift";

//intersecting arrays
const result1 = ["hello", "sifted", "array!"].filter(
  sift({ $in: ["hello", "world"] })
); //['hello']

//regexp filter
const result2 = ["craig", "john", "jake"].filter(sift(/^j/)); //['john','jake']

// function filter
const testFilter = sift({
  //you can also filter against functions
  name: function(value) {
    return value.length == 5;
  }
});

const result3 = [
  {
    name: "craig"
  },
  {
    name: "john"
  },
  {
    name: "jake"
  }
].filter(testFilter); // filtered: [{ name: 'craig' }]

//you can test *single values* against your custom sifter
testFilter({ name: "sarah" }); //true
testFilter({ name: "tim" }); //false
```

## API

### sift(query: MongoQuery, options?: Options): Function

Creates a filter with all of the built-in MongoDB query operations.

- `query` - the filter to use against the target array
- `options`
  - `operations` - [custom operations](#custom-operations)
  - `compare` - compares difference between two values

Example:

```javascript
import sift from "sift";

const test = sift({ $gt: 5 }));

console.log(test(6)); // true
console.log(test(4)); // false

[3, 4, 5, 6, 7].filter(sift({ $exists: true })); // [6, 7]
```

### createQueryTester(query: Query, options?: Options): Function

Creates a filter function **without** built-in MongoDB query operations. This is useful
if you're looking to omit certain operations from application bundles. See [Omitting built-in operations](#omitting-built-in-operations) for more info.

```javascript
import { createQueryTester, $eq, $in } from "sift";
const filter = createQueryTester({ $eq: 5 }, { operations: { $eq, $in } });
```

### createEqualsOperation(params: any, ownerQuery: Query, options: Options): Operation

Used for [custom operations](#custom-operations).

```javascript
import { createQueryTester, createEqualsOperation, $eq, $in } from "sift";
const filter = createQueryTester(
  { $mod: 5 },
  {
    operations: {
      $something(mod, ownerQuery, options) {
        return createEqualsOperation(
          value => value % mod === 0,
          ownerQuery,
          options
        );
      }
    }
  }
);
filter(10); // true
filter(11); // false
```

## Supported Operators

See MongoDB's [advanced queries](http://www.mongodb.org/display/DOCS/Advanced+Queries) for more info.

### \$in

array value must be _\$in_ the given query:

Intersecting two arrays:

```javascript
//filtered: ['Brazil']
["Brazil", "Haiti", "Peru", "Chile"].filter(
  sift({ $in: ["Costa Rica", "Brazil"] })
);
```

Here's another example. This acts more like the \$or operator:

```javascript
[{ name: "Craig", location: "Brazil" }].filter(
  sift({ location: { $in: ["Costa Rica", "Brazil"] } })
);
```

### \$nin

Opposite of \$in:

```javascript
//filtered: ['Haiti','Peru','Chile']
["Brazil", "Haiti", "Peru", "Chile"].filter(
  sift({ $nin: ["Costa Rica", "Brazil"] })
);
```

### \$exists

Checks if whether a value exists:

```javascript
//filtered: ['Craig','Tim']
sift({ $exists: true })(["Craig", null, "Tim"]);
```

You can also filter out values that don't exist

```javascript
//filtered: [{ name: "Tim" }]
[{ name: "Craig", city: "Minneapolis" }, { name: "Tim" }].filter(
  sift({ city: { $exists: false } })
);
```

### \$gte

Checks if a number is >= value:

```javascript
//filtered: [2, 3]
[0, 1, 2, 3].filter(sift({ $gte: 2 }));
```

### \$gt

Checks if a number is > value:

```javascript
//filtered: [3]
[0, 1, 2, 3].filter(sift({ $gt: 2 }));
```

### \$lte

Checks if a number is <= value.

```javascript
//filtered: [0, 1, 2]
[0, 1, 2, 3].filter(sift({ $lte: 2 }));
```

### \$lt

Checks if number is < value.

```javascript
//filtered: [0, 1]
[0, 1, 2, 3].filter(sift({ $lt: 2 }));
```

### \$eq

Checks if `query === value`. Note that **\$eq can be omitted**. For **\$eq**, and **\$ne**

```javascript
//filtered: [{ state: 'MN' }]
[{ state: "MN" }, { state: "CA" }, { state: "WI" }].filter(
  sift({ state: { $eq: "MN" } })
);
```

Or:

```javascript
//filtered: [{ state: 'MN' }]
[{ state: "MN" }, { state: "CA" }, { state: "WI" }].filter(
  sift({ state: "MN" })
);
```

### \$ne

Checks if `query !== value`.

```javascript
//filtered: [{ state: 'CA' }, { state: 'WI'}]
[{ state: "MN" }, { state: "CA" }, { state: "WI" }].filter(
  sift({ state: { $ne: "MN" } })
);
```

### \$mod

Modulus:

```javascript
//filtered: [300, 600]
[100, 200, 300, 400, 500, 600].filter(sift({ $mod: [3, 0] }));
```

### \$all

values must match **everything** in array:

```javascript
//filtered: [ { tags: ['books','programming','travel' ]} ]
[
  { tags: ["books", "programming", "travel"] },
  { tags: ["travel", "cooking"] }
].filter(sift({ tags: { $all: ["books", "programming"] } }));
```

### \$and

ability to use an array of expressions. All expressions must test true.

```javascript
//filtered: [ { name: 'Craig', state: 'MN' }]

[
  { name: "Craig", state: "MN" },
  { name: "Tim", state: "MN" },
  { name: "Joe", state: "CA" }
].filter(sift({ $and: [{ name: "Craig" }, { state: "MN" }] }));
```

### \$or

OR array of expressions.

```javascript
//filtered: [ { name: 'Craig', state: 'MN' }, { name: 'Tim', state: 'MN' }]
[
  { name: "Craig", state: "MN" },
  { name: "Tim", state: "MN" },
  { name: "Joe", state: "CA" }
].filter(sift({ $or: [{ name: "Craig" }, { state: "MN" }] }));
```

### \$nor

opposite of or:

```javascript
//filtered: [{ name: 'Joe', state: 'CA' }]
[
  { name: "Craig", state: "MN" },
  { name: "Tim", state: "MN" },
  { name: "Joe", state: "CA" }
].filter(sift({ $nor: [{ name: "Craig" }, { state: "MN" }] }));
```

### \$size

Matches an array - must match given size:

```javascript
//filtered: ['food','cooking']
[{ tags: ["food", "cooking"] }, { tags: ["traveling"] }].filter(
  sift({ tags: { $size: 2 } })
);
```

### \$type

Matches a values based on the type

```javascript
[new Date(), 4342, "hello world"].filter(sift({ $type: Date })); //returns single date
[new Date(), 4342, "hello world"].filter(sift({ $type: String })); //returns ['hello world']
```

### \$regex

Matches values based on the given regular expression

```javascript
["frank", "fred", "sam", "frost"].filter(
  sift({ $regex: /^f/i, $nin: ["frank"] })
); // ["fred", "frost"]
["frank", "fred", "sam", "frost"].filter(
  sift({ $regex: "^f", $options: "i", $nin: ["frank"] })
); // ["fred", "frost"]
```

### \$where

Matches based on some javascript comparison

```javascript
[{ name: "frank" }, { name: "joe" }].filter(
  sift({ $where: "this.name === 'frank'" })
); // ["frank"]
[{ name: "frank" }, { name: "joe" }].filter(
  sift({
    $where: function() {
      return this.name === "frank";
    }
  })
); // ["frank"]
```

### \$elemMatch

Matches elements of array

```javascript
var bills = [
  {
    month: "july",
    casts: [
      {
        id: 1,
        value: 200
      },
      {
        id: 2,
        value: 1000
      }
    ]
  },
  {
    month: "august",
    casts: [
      {
        id: 3,
        value: 1000
      },
      {
        id: 4,
        value: 4000
      }
    ]
  }
];

var result = bills.filter(
  sift({
    casts: {
      $elemMatch: {
        value: { $gt: 1000 }
      }
    }
  })
); // {month:'august', casts:[{id:3, value: 1000},{id: 4, value: 4000}]}
```

### \$not

Not expression:

```javascript
["craig", "tim", "jake"].filter(sift({ $not: { $in: ["craig", "tim"] } })); //['jake']
["craig", "tim", "jake"].filter(sift({ $not: { $size: 5 } })); //['tim','jake']
```

### Date comparison

Mongodb allows you to do date comparisons like so:

```javascript
db.collection.find({ createdAt: { $gte: "2018-03-22T06:00:00Z" } });
```

In Sift, you'll need to specify a Date object:

```javascript
collection.find(
  sift({ createdAt: { $gte: new Date("2018-03-22T06:00:00Z") } })
);
```

## Custom behavior

Sift works like MongoDB out of the box, but you're also able to modify the behavior to suite your needs.

#### Custom operations

You can register your own custom operations. Here's an example:

```javascript
import sift, { createEqualsOperation } from "sift";

var filter = sift(
  {
    $customMod: 2
  },
  {
    operations: {
      $customMod(params, ownerQuery, options) {
        return createEqualsOperation(
          value => value % params !== 0,
          ownerQuery,
          options
        );
      }
    }
  }
);

[1, 2, 3, 4, 5].filter(filter); // 1, 3, 5
```

#### Omitting built-in operations

You can create a filter function that omits the built-in operations like so:

```javascript
import { createQueryTester, $in, $all, $nin, $lt } from "sift";
const test = createQueryTester(
  {
    $eq: 10
  },
  { operations: { $in, $all, $nin, $lt } }
);

[1, 2, 3, 4, 10].filter(test);
```

For bundlers like `Webpack` and `Rollup`, operations that aren't used are omitted from application bundles via tree-shaking.
