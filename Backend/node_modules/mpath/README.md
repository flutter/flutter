#mpath

{G,S}et javascript object values using MongoDB-like path notation.

###Getting

```js
var mpath = require('mpath');

var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.get('comments.1.title', obj) // 'exciting!'
```

`mpath.get` supports array property notation as well.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.get('comments.title', obj) // ['funny', 'exciting!']
```

Array property and indexing syntax, when used together, are very powerful.

```js
var obj = {
  array: [
      { o: { array: [{x: {b: [4,6,8]}}, { y: 10} ] }}
    , { o: { array: [{x: {b: [1,2,3]}}, { x: {z: 10 }}, { x: 'Turkey Day' }] }}
    , { o: { array: [{x: {b: null }}, { x: { b: [null, 1]}}] }}
    , { o: { array: [{x: null }] }}
    , { o: { array: [{y: 3 }] }}
    , { o: { array: [3, 0, null] }}
    , { o: { name: 'ha' }}
  ];
}

var found = mpath.get('array.o.array.x.b.1', obj);

console.log(found); // prints..

    [ [6, undefined]
    , [2, undefined, undefined]
    , [null, 1]
    , [null]
    , [undefined]
    , [undefined, undefined, undefined]
    , undefined
    ]

```

#####Field selection rules:

The following rules are iteratively applied to each `segment` in the passed `path`. For example:

```js
var path = 'one.two.14'; // path
'one' // segment 0
'two' // segment 1
14    // segment 2
```

- 1) when value of the segment parent is not an array, return the value of `parent.segment`
- 2) when value of the segment parent is an array
  - a) if the segment is an integer, replace the parent array with the value at `parent[segment]`
  - b) if not an integer, keep the array but replace each array `item` with the value returned from calling `get(remainingSegments, item)` or undefined if falsey.

#####Maps

`mpath.get` also accepts an optional `map` argument which receives each individual found value. The value returned from the `map` function will be used in the original found values place.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.get('comments.title', obj, function (val) {
  return 'funny' == val
    ? 'amusing'
    : val;
});
// ['amusing', 'exciting!']
```

###Setting

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.set('comments.1.title', 'hilarious', obj)
console.log(obj.comments[1].title) // 'hilarious'
```

`mpath.set` supports the same array property notation as `mpath.get`.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.set('comments.title', ['hilarious', 'fruity'], obj);

console.log(obj); // prints..

  { comments: [
      { title: 'hilarious' },
      { title: 'fruity' }
  ]}
```

Array property and indexing syntax can be used together also when setting.

```js
var obj = {
  array: [
      { o: { array: [{x: {b: [4,6,8]}}, { y: 10} ] }}
    , { o: { array: [{x: {b: [1,2,3]}}, { x: {z: 10 }}, { x: 'Turkey Day' }] }}
    , { o: { array: [{x: {b: null }}, { x: { b: [null, 1]}}] }}
    , { o: { array: [{x: null }] }}
    , { o: { array: [{y: 3 }] }}
    , { o: { array: [3, 0, null] }}
    , { o: { name: 'ha' }}
  ]
}

mpath.set('array.1.o', 'this was changed', obj);

console.log(require('util').inspect(obj, false, 1000)); // prints..

{
  array: [
      { o: { array: [{x: {b: [4,6,8]}}, { y: 10} ] }}
    , { o: 'this was changed' }
    , { o: { array: [{x: {b: null }}, { x: { b: [null, 1]}}] }}
    , { o: { array: [{x: null }] }}
    , { o: { array: [{y: 3 }] }}
    , { o: { array: [3, 0, null] }}
    , { o: { name: 'ha' }}
  ];
}

mpath.set('array.o.array.x', 'this was changed too', obj);

console.log(require('util').inspect(obj, false, 1000)); // prints..

{
  array: [
      { o: { array: [{x: 'this was changed too'}, { y: 10, x: 'this was changed too'} ] }}
    , { o: 'this was changed' }
    , { o: { array: [{x: 'this was changed too'}, { x: 'this was changed too'}] }}
    , { o: { array: [{x: 'this was changed too'}] }}
    , { o: { array: [{x: 'this was changed too', y: 3 }] }}
    , { o: { array: [3, 0, null] }}
    , { o: { name: 'ha' }}
  ];
}
```

####Setting arrays

By default, setting a property within an array to another array results in each element of the new array being set to the item in the destination array at the matching index. An example is helpful.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.set('comments.title', ['hilarious', 'fruity'], obj);

console.log(obj); // prints..

  { comments: [
      { title: 'hilarious' },
      { title: 'fruity' }
  ]}
```

If we do not desire this destructuring-like assignment behavior we may instead specify the `$` operator in the path being set to force the array to be copied directly.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.set('comments.$.title', ['hilarious', 'fruity'], obj);

console.log(obj); // prints..

  { comments: [
      { title: ['hilarious', 'fruity'] },
      { title: ['hilarious', 'fruity'] }
  ]}
```

####Field assignment rules

The rules utilized mirror those used on `mpath.get`, meaning we can take values returned from `mpath.get`, update them, and reassign them using `mpath.set`. Note that setting nested arrays of arrays can get unweildy quickly. Check out the [tests](https://github.com/aheckmann/mpath/blob/master/test/index.js) for more extreme examples.

#####Maps

`mpath.set` also accepts an optional `map` argument which receives each individual value being set. The value returned from the `map` function will be used in the original values place.

```js
var obj = {
    comments: [
      { title: 'funny' },
      { title: 'exciting!' }
    ]
}

mpath.set('comments.title', ['hilarious', 'fruity'], obj, function (val) {
  return val.length;
});

console.log(obj); // prints..

  { comments: [
      { title: 9 },
      { title: 6 }
  ]}
```

### Custom object types

Sometimes you may want to enact the same functionality on custom object types that store all their real data internally, say for an ODM type object. No fear, `mpath` has you covered. Simply pass the name of the property being used to store the internal data and it will be traversed instead:

```js
var mpath = require('mpath');

var obj = {
    comments: [
      { title: 'exciting!', _doc: { title: 'great!' }}
    ]
}

mpath.get('comments.0.title', obj, '_doc')            // 'great!'
mpath.set('comments.0.title', 'nov 3rd', obj, '_doc')
mpath.get('comments.0.title', obj, '_doc')            // 'nov 3rd'
mpath.get('comments.0.title', obj)                    // 'exciting'
```

When used with a `map`, the `map` argument comes last.

```js
mpath.get(path, obj, '_doc', map);
mpath.set(path, val, obj, '_doc', map);
```

[LICENSE](https://github.com/aheckmann/mpath/blob/master/LICENSE)

