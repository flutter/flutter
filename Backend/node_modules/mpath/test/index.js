'use strict';

/**
 * Test dependencies.
 */

const mpath = require('../');
const assert = require('assert');

/**
 * logging helper
 */

function log(o) {
  console.log();
  console.log(require('util').inspect(o, false, 1000));
}

/**
 * special path for override tests
 */

const special = '_doc';

/**
 * Tests
 */

describe('mpath', function() {

  /**
   * test doc creator
   */

  function doc() {
    const o = { first: { second: { third: [3, { name: 'aaron' }, 9] } } };
    o.comments = [
      { name: 'one' },
      { name: 'two', _doc: { name: '2' } },
      { name: 'three',
        comments: [{}, { comments: [{ val: 'twoo' }] }],
        _doc: { name: '3', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }
    ];
    o.name = 'jiro';
    o.array = [
      { o: { array: [{ x: { b: [4, 6, 8] } }, { y: 10 }] } },
      { o: { array: [{ x: { b: [1, 2, 3] } }, { x: { z: 10 } }, { x: { b: 'hi' } }] } },
      { o: { array: [{ x: { b: null } }, { x: { b: [null, 1] } }] } },
      { o: { array: [{ x: null }] } },
      { o: { array: [{ y: 3 }] } },
      { o: { array: [3, 0, null] } },
      { o: { name: 'ha' } }
    ];
    o.arr = [
      { arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
      { yep: true }
    ];
    return o;
  }

  describe('get', function() {
    const o = doc();

    it('`path` must be a string or array', function(done) {
      assert.throws(function() {
        mpath.get({}, o);
      }, /Must be either string or array/);
      assert.throws(function() {
        mpath.get(4, o);
      }, /Must be either string or array/);
      assert.throws(function() {
        mpath.get(function() {}, o);
      }, /Must be either string or array/);
      assert.throws(function() {
        mpath.get(/asdf/, o);
      }, /Must be either string or array/);
      assert.throws(function() {
        mpath.get(Math, o);
      }, /Must be either string or array/);
      assert.throws(function() {
        mpath.get(Buffer, o);
      }, /Must be either string or array/);
      assert.doesNotThrow(function() {
        mpath.get('string', o);
      });
      assert.doesNotThrow(function() {
        mpath.get([], o);
      });
      done();
    });

    describe('without `special`', function() {
      it('works', function(done) {
        assert.equal('jiro', mpath.get('name', o));

        assert.deepEqual(
          { second: { third: [3, { name: 'aaron' }, 9] } }
          , mpath.get('first', o)
        );

        assert.deepEqual(
          { third: [3, { name: 'aaron' }, 9] }
          , mpath.get('first.second', o)
        );

        assert.deepEqual(
          [3, { name: 'aaron' }, 9]
          , mpath.get('first.second.third', o)
        );

        assert.deepEqual(
          3
          , mpath.get('first.second.third.0', o)
        );

        assert.deepEqual(
          9
          , mpath.get('first.second.third.2', o)
        );

        assert.deepEqual(
          { name: 'aaron' }
          , mpath.get('first.second.third.1', o)
        );

        assert.deepEqual(
          'aaron'
          , mpath.get('first.second.third.1.name', o)
        );

        assert.deepEqual([
          { name: 'one' },
          { name: 'two', _doc: { name: '2' } },
          { name: 'three',
            comments: [{}, { comments: [{ val: 'twoo' }] }],
            _doc: { name: '3', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }],
        mpath.get('comments', o));

        assert.deepEqual({ name: 'one' }, mpath.get('comments.0', o));
        assert.deepEqual('one', mpath.get('comments.0.name', o));
        assert.deepEqual('two', mpath.get('comments.1.name', o));
        assert.deepEqual('three', mpath.get('comments.2.name', o));

        assert.deepEqual([{}, { comments: [{ val: 'twoo' }] }]
          , mpath.get('comments.2.comments', o));

        assert.deepEqual({ comments: [{ val: 'twoo' }] }
          , mpath.get('comments.2.comments.1', o));

        assert.deepEqual('twoo', mpath.get('comments.2.comments.1.comments.0.val', o));

        done();
      });

      it('handles array.property dot-notation', function(done) {
        assert.deepEqual(
          ['one', 'two', 'three']
          , mpath.get('comments.name', o)
        );
        done();
      });

      it('handles array.array notation', function(done) {
        assert.deepEqual(
          [undefined, undefined, [{}, { comments: [{ val: 'twoo' }] }]]
          , mpath.get('comments.comments', o)
        );
        done();
      });

      it('handles prop.prop.prop.arrayProperty notation', function(done) {
        assert.deepEqual(
          [undefined, 'aaron', undefined]
          , mpath.get('first.second.third.name', o)
        );
        assert.deepEqual(
          [1, 'aaron', 1]
          , mpath.get('first.second.third.name', o, function(v) {
            return undefined === v ? 1 : v;
          })
        );
        done();
      });

      it('handles array.prop.array', function(done) {
        assert.deepEqual(
          [[{ x: { b: [4, 6, 8] } }, { y: 10 }],
            [{ x: { b: [1, 2, 3] } }, { x: { z: 10 } }, { x: { b: 'hi' } }],
            [{ x: { b: null } }, { x: { b: [null, 1] } }],
            [{ x: null }],
            [{ y: 3 }],
            [3, 0, null],
            undefined
          ]
          , mpath.get('array.o.array', o)
        );
        done();
      });

      it('handles array.prop.array.index', function(done) {
        assert.deepEqual(
          [{ x: { b: [4, 6, 8] } },
            { x: { b: [1, 2, 3] } },
            { x: { b: null } },
            { x: null },
            { y: 3 },
            3,
            undefined
          ]
          , mpath.get('array.o.array.0', o)
        );
        done();
      });

      it('handles array.prop.array.index.prop', function(done) {
        assert.deepEqual(
          [{ b: [4, 6, 8] },
            { b: [1, 2, 3] },
            { b: null },
            null,
            undefined,
            undefined,
            undefined
          ]
          , mpath.get('array.o.array.0.x', o)
        );
        done();
      });

      it('handles array.prop.array.prop', function(done) {
        assert.deepEqual(
          [[undefined, 10],
            [undefined, undefined, undefined],
            [undefined, undefined],
            [undefined],
            [3],
            [undefined, undefined, undefined],
            undefined
          ]
          , mpath.get('array.o.array.y', o)
        );
        assert.deepEqual(
          [[{ b: [4, 6, 8] }, undefined],
            [{ b: [1, 2, 3] }, { z: 10 }, { b: 'hi' }],
            [{ b: null }, { b: [null, 1] }],
            [null],
            [undefined],
            [undefined, undefined, undefined],
            undefined
          ]
          , mpath.get('array.o.array.x', o)
        );
        done();
      });

      it('handles array.prop.array.prop.prop', function(done) {
        assert.deepEqual(
          [[[4, 6, 8], undefined],
            [[1, 2, 3], undefined, 'hi'],
            [null, [null, 1]],
            [null],
            [undefined],
            [undefined, undefined, undefined],
            undefined
          ]
          , mpath.get('array.o.array.x.b', o)
        );
        done();
      });

      it('handles array.prop.array.prop.prop.index', function(done) {
        assert.deepEqual(
          [[6, undefined],
            [2, undefined, 'i'], // undocumented feature (string indexing)
            [null, 1],
            [null],
            [undefined],
            [undefined, undefined, undefined],
            undefined
          ]
          , mpath.get('array.o.array.x.b.1', o)
        );
        assert.deepEqual(
          [[6, 0],
            [2, 0, 'i'], // undocumented feature (string indexing)
            [null, 1],
            [null],
            [0],
            [0, 0, 0],
            0
          ]
          , mpath.get('array.o.array.x.b.1', o, function(v) {
            return undefined === v ? 0 : v;
          })
        );
        done();
      });

      it('handles array.index.prop.prop', function(done) {
        assert.deepEqual(
          [{ x: { b: [1, 2, 3] } }, { x: { z: 10 } }, { x: { b: 'hi' } }]
          , mpath.get('array.1.o.array', o)
        );
        assert.deepEqual(
          ['hi', 'hi', 'hi']
          , mpath.get('array.1.o.array', o, function(v) {
            if (Array.isArray(v)) {
              return v.map(function(val) {
                return 'hi';
              });
            }
            return v;
          })
        );
        done();
      });

      it('handles array.array.index', function(done) {
        assert.deepEqual(
          [{ a: { c: 48 } }, undefined]
          , mpath.get('arr.arr.1', o)
        );
        assert.deepEqual(
          ['woot', undefined]
          , mpath.get('arr.arr.1', o, function(v) {
            if (v && v.a && v.a.c) return 'woot';
            return v;
          })
        );
        done();
      });

      it('handles array.array.index.prop', function(done) {
        assert.deepEqual(
          [{ c: 48 }, 'woot']
          , mpath.get('arr.arr.1.a', o, function(v) {
            if (undefined === v) return 'woot';
            return v;
          })
        );
        assert.deepEqual(
          [{ c: 48 }, undefined]
          , mpath.get('arr.arr.1.a', o)
        );
        mpath.set('arr.arr.1.a', [{ c: 49 }, undefined], o);
        assert.deepEqual(
          [{ c: 49 }, undefined]
          , mpath.get('arr.arr.1.a', o)
        );
        mpath.set('arr.arr.1.a', [{ c: 48 }, undefined], o);
        done();
      });

      it('handles array.array.index.prop.prop', function(done) {
        assert.deepEqual(
          [48, undefined]
          , mpath.get('arr.arr.1.a.c', o)
        );
        assert.deepEqual(
          [48, 'woot']
          , mpath.get('arr.arr.1.a.c', o, function(v) {
            if (undefined === v) return 'woot';
            return v;
          })
        );
        done();
      });

    });

    describe('with `special`', function() {
      describe('that is a string', function() {
        it('works', function(done) {
          assert.equal('jiro', mpath.get('name', o, special));

          assert.deepEqual(
            { second: { third: [3, { name: 'aaron' }, 9] } }
            , mpath.get('first', o, special)
          );

          assert.deepEqual(
            { third: [3, { name: 'aaron' }, 9] }
            , mpath.get('first.second', o, special)
          );

          assert.deepEqual(
            [3, { name: 'aaron' }, 9]
            , mpath.get('first.second.third', o, special)
          );

          assert.deepEqual(
            3
            , mpath.get('first.second.third.0', o, special)
          );

          assert.deepEqual(
            4
            , mpath.get('first.second.third.0', o, special, function(v) {
              return 3 === v ? 4 : v;
            })
          );

          assert.deepEqual(
            9
            , mpath.get('first.second.third.2', o, special)
          );

          assert.deepEqual(
            { name: 'aaron' }
            , mpath.get('first.second.third.1', o, special)
          );

          assert.deepEqual(
            'aaron'
            , mpath.get('first.second.third.1.name', o, special)
          );

          assert.deepEqual([
            { name: 'one' },
            { name: 'two', _doc: { name: '2' } },
            { name: 'three',
              comments: [{}, { comments: [{ val: 'twoo' }] }],
              _doc: { name: '3', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }],
          mpath.get('comments', o, special));

          assert.deepEqual({ name: 'one' }, mpath.get('comments.0', o, special));
          assert.deepEqual('one', mpath.get('comments.0.name', o, special));
          assert.deepEqual('2', mpath.get('comments.1.name', o, special));
          assert.deepEqual('3', mpath.get('comments.2.name', o, special));
          assert.deepEqual('nice', mpath.get('comments.2.name', o, special, function(v) {
            return '3' === v ? 'nice' : v;
          }));

          assert.deepEqual([{}, { _doc: { comments: [{ val: 2 }] } }]
            , mpath.get('comments.2.comments', o, special));

          assert.deepEqual({ _doc: { comments: [{ val: 2 }] } }
            , mpath.get('comments.2.comments.1', o, special));

          assert.deepEqual(2, mpath.get('comments.2.comments.1.comments.0.val', o, special));
          done();
        });

        it('handles array.property dot-notation', function(done) {
          assert.deepEqual(
            ['one', '2', '3']
            , mpath.get('comments.name', o, special)
          );
          assert.deepEqual(
            ['one', 2, '3']
            , mpath.get('comments.name', o, special, function(v) {
              return '2' === v ? 2 : v;
            })
          );
          done();
        });

        it('handles array.array notation', function(done) {
          assert.deepEqual(
            [undefined, undefined, [{}, { _doc: { comments: [{ val: 2 }] } }]]
            , mpath.get('comments.comments', o, special)
          );
          done();
        });

        it('handles array.array.index.array', function(done) {
          assert.deepEqual(
            [undefined, undefined, [{ val: 2 }]]
            , mpath.get('comments.comments.1.comments', o, special)
          );
          done();
        });

        it('handles array.array.index.array.prop', function(done) {
          assert.deepEqual(
            [undefined, undefined, [2]]
            , mpath.get('comments.comments.1.comments.val', o, special)
          );
          assert.deepEqual(
            ['nil', 'nil', [2]]
            , mpath.get('comments.comments.1.comments.val', o, special, function(v) {
              return undefined === v ? 'nil' : v;
            })
          );
          done();
        });
      });

      describe('that is a function', function() {
        const special = function(obj, key) {
          return obj[key];
        };

        it('works', function(done) {
          assert.equal('jiro', mpath.get('name', o, special));

          assert.deepEqual(
            { second: { third: [3, { name: 'aaron' }, 9] } }
            , mpath.get('first', o, special)
          );

          assert.deepEqual(
            { third: [3, { name: 'aaron' }, 9] }
            , mpath.get('first.second', o, special)
          );

          assert.deepEqual(
            [3, { name: 'aaron' }, 9]
            , mpath.get('first.second.third', o, special)
          );

          assert.deepEqual(
            3
            , mpath.get('first.second.third.0', o, special)
          );

          assert.deepEqual(
            4
            , mpath.get('first.second.third.0', o, special, function(v) {
              return 3 === v ? 4 : v;
            })
          );

          assert.deepEqual(
            9
            , mpath.get('first.second.third.2', o, special)
          );

          assert.deepEqual(
            { name: 'aaron' }
            , mpath.get('first.second.third.1', o, special)
          );

          assert.deepEqual(
            'aaron'
            , mpath.get('first.second.third.1.name', o, special)
          );

          assert.deepEqual([
            { name: 'one' },
            { name: 'two', _doc: { name: '2' } },
            { name: 'three',
              comments: [{}, { comments: [{ val: 'twoo' }] }],
              _doc: { name: '3', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }],
          mpath.get('comments', o, special));

          assert.deepEqual({ name: 'one' }, mpath.get('comments.0', o, special));
          assert.deepEqual('one', mpath.get('comments.0.name', o, special));
          assert.deepEqual('two', mpath.get('comments.1.name', o, special));
          assert.deepEqual('three', mpath.get('comments.2.name', o, special));
          assert.deepEqual('nice', mpath.get('comments.2.name', o, special, function(v) {
            return 'three' === v ? 'nice' : v;
          }));

          assert.deepEqual([{}, { comments: [{ val: 'twoo' }] }]
            , mpath.get('comments.2.comments', o, special));

          assert.deepEqual({ comments: [{ val: 'twoo' }] }
            , mpath.get('comments.2.comments.1', o, special));

          assert.deepEqual('twoo', mpath.get('comments.2.comments.1.comments.0.val', o, special));

          let overide = false;
          assert.deepEqual('twoo', mpath.get('comments.8.comments.1.comments.0.val', o, function(obj, path) {
            if (Array.isArray(obj) && 8 == path) {
              overide = true;
              return obj[2];
            }
            return obj[path];
          }));
          assert.ok(overide);

          done();
        });

        it('in combination with map', function(done) {
          const special = function(obj, key) {
            if (Array.isArray(obj)) return obj[key];
            return obj.mpath;
          };
          const map = function(val) {
            return 'convert' == val
              ? 'mpath'
              : val;
          };
          const o = { mpath: [{ mpath: 'converse' }, { mpath: 'convert' }] };

          assert.equal('mpath', mpath.get('something.1.kewl', o, special, map));
          done();
        });
      });
    });
  });

  describe('set', function() {
    it('prevents writing to __proto__', function() {
      const obj = {};
      mpath.set('__proto__.x', 'foobar', obj);
      assert.ok(!({}.x));

      mpath.set('constructor.prototype.x', 'foobar', obj);
      assert.ok(!({}.x));
    });

    describe('without `special`', function() {
      const o = doc();

      it('works', function(done) {
        mpath.set('name', 'a new val', o, function(v) {
          return 'a new val' === v ? 'changed' : v;
        });
        assert.deepEqual('changed', o.name);

        mpath.set('name', 'changed', o);
        assert.deepEqual('changed', o.name);

        mpath.set('first.second.third', [1, { name: 'x' }, 9], o);
        assert.deepEqual([1, { name: 'x' }, 9], o.first.second.third);

        mpath.set('first.second.third.1.name', 'y', o);
        assert.deepEqual([1, { name: 'y' }, 9], o.first.second.third);

        mpath.set('comments.1.name', 'ttwwoo', o);
        assert.deepEqual({ name: 'ttwwoo', _doc: { name: '2' } }, o.comments[1]);

        mpath.set('comments.2.comments.1.comments.0.expand', 'added', o);
        assert.deepEqual(
          { val: 'twoo', expand: 'added' }
          , o.comments[2].comments[1].comments[0]);

        mpath.set('comments.2.comments.1.comments.2', 'added', o);
        assert.equal(3, o.comments[2].comments[1].comments.length);
        assert.deepEqual(
          { val: 'twoo', expand: 'added' }
          , o.comments[2].comments[1].comments[0]);
        assert.deepEqual(
          undefined
          , o.comments[2].comments[1].comments[1]);
        assert.deepEqual(
          'added'
          , o.comments[2].comments[1].comments[2]);

        done();
      });

      describe('array.path', function() {
        describe('with single non-array value', function() {
          it('works', function(done) {
            mpath.set('arr.yep', false, o, function(v) {
              return false === v ? true : v;
            });
            assert.deepEqual([
              { yep: true, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true }
            ], o.arr);

            mpath.set('arr.yep', false, o);

            assert.deepEqual([
              { yep: false, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: false }
            ], o.arr);

            done();
          });
        });
        describe('with array of values', function() {
          it('that are equal in length', function(done) {
            mpath.set('arr.yep', ['one', 2], o, function(v) {
              return 'one' === v ? 1 : v;
            });
            assert.deepEqual([
              { yep: 1, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 2 }
            ], o.arr);
            mpath.set('arr.yep', ['one', 2], o);

            assert.deepEqual([
              { yep: 'one', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 2 }
            ], o.arr);

            done();
          });

          it('that is less than length', function(done) {
            mpath.set('arr.yep', [47], o, function(v) {
              return 47 === v ? 4 : v;
            });
            assert.deepEqual([
              { yep: 4, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 2 }
            ], o.arr);

            mpath.set('arr.yep', [47], o);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 2 }
            ], o.arr);

            done();
          });

          it('that is greater than length', function(done) {
            mpath.set('arr.yep', [5, 6, 7], o, function(v) {
              return 5 === v ? 'five' : v;
            });
            assert.deepEqual([
              { yep: 'five', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 6 }
            ], o.arr);

            mpath.set('arr.yep', [5, 6, 7], o);
            assert.deepEqual([
              { yep: 5, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 6 }
            ], o.arr);

            done();
          });
        });
      });

      describe('array.$.path', function() {
        describe('with single non-array value', function() {
          it('copies the value to each item in array', function(done) {
            mpath.set('arr.$.yep', { xtra: 'double good' }, o, function(v) {
              return v && v.xtra ? 'hi' : v;
            });
            assert.deepEqual([
              { yep: 'hi', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: 'hi' }
            ], o.arr);

            mpath.set('arr.$.yep', { xtra: 'double good' }, o);
            assert.deepEqual([
              { yep: { xtra: 'double good' }, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: { xtra: 'double good' } }
            ], o.arr);

            done();
          });
        });
        describe('with array of values', function() {
          it('copies the value to each item in array', function(done) {
            mpath.set('arr.$.yep', [15], o, function(v) {
              return v.length === 1 ? [] : v;
            });
            assert.deepEqual([
              { yep: [], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: [] }
            ], o.arr);

            mpath.set('arr.$.yep', [15], o);
            assert.deepEqual([
              { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: [15] }
            ], o.arr);

            done();
          });
        });
      });

      describe('array.index.path', function() {
        it('works', function(done) {
          mpath.set('arr.1.yep', 0, o, function(v) {
            return 0 === v ? 'zero' : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
            { yep: 'zero' }
          ], o.arr);

          mpath.set('arr.1.yep', 0, o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.e', 35, o, function(v) {
            return 35 === v ? 3 : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 }, e: 3 }, { a: { c: 48 }, e: 3 }, { d: 'yep', e: 3 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.e', 35, o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 }, e: 35 }, { a: { c: 48 }, e: 35 }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.e', ['a', 'b'], o, function(v) {
            return 'a' === v ? 'x' : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 }, e: 'x' }, { a: { c: 48 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.e', ['a', 'b'], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 47 }, e: 'a' }, { a: { c: 48 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.path.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.a.b', 36, o, function(v) {
            return 36 === v ? 3 : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 3 }, e: 'a' }, { a: { c: 48, b: 3 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.a.b', 36, o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 36 }, e: 'a' }, { a: { c: 48, b: 36 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.a.b', [1, 2, 3, 4], o, function(v) {
            return 2 === v ? 'two' : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 1 }, e: 'a' }, { a: { c: 48, b: 'two' }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.a.b', [1, 2, 3, 4], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 1 }, e: 'a' }, { a: { c: 48, b: 2 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.$.path.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.$.a.b', '$', o, function(v) {
            return '$' === v ? 'dolla billz' : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: 'dolla billz' }, e: 'a' }, { a: { c: 48, b: 'dolla billz' }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.$.a.b', '$', o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: '$' }, e: 'a' }, { a: { c: 48, b: '$' }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.$.a.b', [1], o, function(v) {
            return Array.isArray(v) ? {} : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: {} }, e: 'a' }, { a: { c: 48, b: {} }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.0.arr.$.a.b', [1], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: { b: [1] }, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
      });

      describe('array.array.index.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.0.a', 'single', o, function(v) {
            return 'single' === v ? 'double' : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: 'double', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.arr.0.a', 'single', o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: 'single', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.arr.0.a', [4, 8, 15, 16, 23, 42], o, function(v) {
            return 4 === v ? 3 : v;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: 3, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: false }
          ], o.arr);

          mpath.set('arr.arr.0.a', [4, 8, 15, 16, 23, 42], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: 4, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: false }
          ], o.arr);

          done();
        });
      });

      describe('array.array.$.index.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.$.0.a', 'singles', o, function(v) {
            return 0;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: 0, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.arr.$.0.a', 'singles', o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: 'singles', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('$.arr.arr.0.a', 'single', o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: 'single', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.arr.$.0.a', [4, 8, 15, 16, 23, 42], o, function(v) {
            return 'nope';
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: 'nope', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.arr.$.0.a', [4, 8, 15, 16, 23, 42], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42], e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.$.arr.0.a', [4, 8, 15, 16, 23, 42, 108], o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108], e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
      });

      describe('array.array.path.index', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.a.7', 47, o, function(v) {
            return 1;
          });
          assert.deepEqual([
            { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, 1], e: 'a' }, { a: { c: 48, b: [1], 7: 1 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          mpath.set('arr.arr.a.7', 47, o);
          assert.deepEqual([
            { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, 47], e: 'a' }, { a: { c: 48, b: [1], 7: 47 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0 }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          o.arr[1].arr = [{ a: [] }, { a: [] }, { a: null }];
          mpath.set('arr.arr.a.7', [[null, 46], [undefined, 'woot']], o);

          const a1 = [];
          const a2 = [];
          a1[7] = undefined;
          a2[7] = 'woot';

          assert.deepEqual([
            { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, null], e: 'a' }, { a: { c: 48, b: [1], 7: 46 }, e: 'b' }, { d: 'yep', e: 35 }] },
            { yep: 0, arr: [{ a: a1 }, { a: a2 }, { a: null }] }
          ], o.arr);

          done();
        });
      });

      describe('handles array.array.path', function() {
        it('with single', function(done) {
          o.arr[1].arr = [{}, {}];
          assert.deepEqual([{}, {}], o.arr[1].arr);
          o.arr.push({ arr: 'something else' });
          o.arr.push({ arr: ['something else'] });
          o.arr.push({ arr: [[]] });
          o.arr.push({ arr: [5] });

          const weird = [];
          weird.e = 'xmas';

          // test
          mpath.set('arr.arr.e', 47, o, function(v) {
            return 'xmas';
          });
          assert.deepEqual([
            { yep: [15], arr: [
              { a: [4, 8, 15, 16, 23, 42, 108, null], e: 'xmas' },
              { a: { c: 48, b: [1], 7: 46 }, e: 'xmas' },
              { d: 'yep', e: 'xmas' }
            ]
            },
            { yep: 0, arr: [{ e: 'xmas' }, { e: 'xmas' }] },
            { arr: 'something else' },
            { arr: ['something else'] },
            { arr: [weird] },
            { arr: [5] }
          ]
          , o.arr);

          weird.e = 47;

          mpath.set('arr.arr.e', 47, o);
          assert.deepEqual([
            { yep: [15], arr: [
              { a: [4, 8, 15, 16, 23, 42, 108, null], e: 47 },
              { a: { c: 48, b: [1], 7: 46 }, e: 47 },
              { d: 'yep', e: 47 }
            ]
            },
            { yep: 0, arr: [{ e: 47 }, { e: 47 }] },
            { arr: 'something else' },
            { arr: ['something else'] },
            { arr: [weird] },
            { arr: [5] }
          ]
          , o.arr);

          done();
        });
        it('with arrays', function(done) {
          mpath.set('arr.arr.e', [[1, 2, 3], [4, 5], null, [], [6], [7, 8, 9]], o, function(v) {
            return 10;
          });

          const weird = [];
          weird.e = 10;

          assert.deepEqual([
            { yep: [15], arr: [
              { a: [4, 8, 15, 16, 23, 42, 108, null], e: 10 },
              { a: { c: 48, b: [1], 7: 46 }, e: 10 },
              { d: 'yep', e: 10 }
            ]
            },
            { yep: 0, arr: [{ e: 10 }, { e: 10 }] },
            { arr: 'something else' },
            { arr: ['something else'] },
            { arr: [weird] },
            { arr: [5] }
          ]
          , o.arr);

          mpath.set('arr.arr.e', [[1, 2, 3], [4, 5], null, [], [6], [7, 8, 9]], o);

          weird.e = 6;

          assert.deepEqual([
            { yep: [15], arr: [
              { a: [4, 8, 15, 16, 23, 42, 108, null], e: 1 },
              { a: { c: 48, b: [1], 7: 46 }, e: 2 },
              { d: 'yep', e: 3 }
            ]
            },
            { yep: 0, arr: [{ e: 4 }, { e: 5 }] },
            { arr: 'something else' },
            { arr: ['something else'] },
            { arr: [weird] },
            { arr: [5] }
          ]
          , o.arr);

          done();
        });
      });
    });

    describe('with `special`', function() {
      const o = doc();

      it('works', function(done) {
        mpath.set('name', 'chan', o, special, function(v) {
          return 'hi';
        });
        assert.deepEqual('hi', o.name);

        mpath.set('name', 'changer', o, special);
        assert.deepEqual('changer', o.name);

        mpath.set('first.second.third', [1, { name: 'y' }, 9], o, special);
        assert.deepEqual([1, { name: 'y' }, 9], o.first.second.third);

        mpath.set('first.second.third.1.name', 'z', o, special);
        assert.deepEqual([1, { name: 'z' }, 9], o.first.second.third);

        mpath.set('comments.1.name', 'ttwwoo', o, special);
        assert.deepEqual({ name: 'two', _doc: { name: 'ttwwoo' } }, o.comments[1]);

        mpath.set('comments.2.comments.1.comments.0.expander', 'adder', o, special, function(v) {
          return 'super';
        });
        assert.deepEqual(
          { val: 2, expander: 'super' }
          , o.comments[2]._doc.comments[1]._doc.comments[0]);

        mpath.set('comments.2.comments.1.comments.0.expander', 'adder', o, special);
        assert.deepEqual(
          { val: 2, expander: 'adder' }
          , o.comments[2]._doc.comments[1]._doc.comments[0]);

        mpath.set('comments.2.comments.1.comments.2', 'set', o, special);
        assert.equal(3, o.comments[2]._doc.comments[1]._doc.comments.length);
        assert.deepEqual(
          { val: 2, expander: 'adder' }
          , o.comments[2]._doc.comments[1]._doc.comments[0]);
        assert.deepEqual(
          undefined
          , o.comments[2]._doc.comments[1]._doc.comments[1]);
        assert.deepEqual(
          'set'
          , o.comments[2]._doc.comments[1]._doc.comments[2]);
        done();
      });

      describe('array.path', function() {
        describe('with single non-array value', function() {
          it('works', function(done) {
            o.arr[1]._doc = { special: true };

            mpath.set('arr.yep', false, o, special, function(v) {
              return 'yes';
            });
            assert.deepEqual([
              { yep: 'yes', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: 'yes' } }
            ], o.arr);

            mpath.set('arr.yep', false, o, special);
            assert.deepEqual([
              { yep: false, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: false } }
            ], o.arr);

            done();
          });
        });
        describe('with array of values', function() {
          it('that are equal in length', function(done) {
            mpath.set('arr.yep', ['one', 2], o, special, function(v) {
              return 2 === v ? 20 : v;
            });
            assert.deepEqual([
              { yep: 'one', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: 20 } }
            ], o.arr);

            mpath.set('arr.yep', ['one', 2], o, special);
            assert.deepEqual([
              { yep: 'one', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: 2 } }
            ], o.arr);

            done();
          });

          it('that is less than length', function(done) {
            mpath.set('arr.yep', [47], o, special, function(v) {
              return 80;
            });
            assert.deepEqual([
              { yep: 80, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: 2 } }
            ], o.arr);

            mpath.set('arr.yep', [47], o, special);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] },
              { yep: true, _doc: { special: true, yep: 2 } }
            ], o.arr);

            // add _doc to first element
            o.arr[0]._doc = { yep: 46, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] };

            mpath.set('arr.yep', [20], o, special);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }], _doc: { yep: 20, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: 2 } }
            ], o.arr);

            done();
          });

          it('that is greater than length', function(done) {
            mpath.set('arr.yep', [5, 6, 7], o, special, function() {
              return 'x';
            });
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }], _doc: { yep: 'x', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: 'x' } }
            ], o.arr);

            mpath.set('arr.yep', [5, 6, 7], o, special);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }], _doc: { yep: 5, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: 6 } }
            ], o.arr);

            done();
          });
        });
      });

      describe('array.$.path', function() {
        describe('with single non-array value', function() {
          it('copies the value to each item in array', function(done) {
            mpath.set('arr.$.yep', { xtra: 'double good' }, o, special, function(v) {
              return 9;
            });
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
                _doc: { yep: 9, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: 9 } }
            ], o.arr);

            mpath.set('arr.$.yep', { xtra: 'double good' }, o, special);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
                _doc: { yep: { xtra: 'double good' }, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: { xtra: 'double good' } } }
            ], o.arr);

            done();
          });
        });
        describe('with array of values', function() {
          it('copies the value to each item in array', function(done) {
            mpath.set('arr.$.yep', [15], o, special, function(v) {
              return 'array';
            });
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
                _doc: { yep: 'array', arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: 'array' } }
            ], o.arr);

            mpath.set('arr.$.yep', [15], o, special);
            assert.deepEqual([
              { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
                _doc: { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
              { yep: true, _doc: { special: true, yep: [15] } }
            ], o.arr);

            done();
          });
        });
      });

      describe('array.index.path', function() {
        it('works', function(done) {
          mpath.set('arr.1.yep', 0, o, special, function(v) {
            return 1;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
            { yep: true, _doc: { special: true, yep: 1 } }
          ], o.arr);

          mpath.set('arr.1.yep', 0, o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.e', 35, o, special, function(v) {
            return 30;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 }, e: 30 }, { a: { c: 48 }, e: 30 }, { d: 'yep', e: 30 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.e', 35, o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 }, e: 35 }, { a: { c: 48 }, e: 35 }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.e', ['a', 'b'], o, special, function(v) {
            return 'a' === v ? 'A' : v;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 }, e: 'A' }, { a: { c: 48 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.e', ['a', 'b'], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 47 }, e: 'a' }, { a: { c: 48 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.path.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.a.b', 36, o, special, function(v) {
            return 20;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 20 }, e: 'a' }, { a: { c: 48, b: 20 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.a.b', 36, o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 36 }, e: 'a' }, { a: { c: 48, b: 36 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.a.b', [1, 2, 3, 4], o, special, function(v) {
            return v * 2;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 2 }, e: 'a' }, { a: { c: 48, b: 4 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.a.b', [1, 2, 3, 4], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 1 }, e: 'a' }, { a: { c: 48, b: 2 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.index.array.$.path.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.0.arr.$.a.b', '$', o, special, function(v) {
            return 'dollaz';
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: 'dollaz' }, e: 'a' }, { a: { c: 48, b: 'dollaz' }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.$.a.b', '$', o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: '$' }, e: 'a' }, { a: { c: 48, b: '$' }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.0.arr.$.a.b', [1], o, special, function(v) {
            return {};
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: {} }, e: 'a' }, { a: { c: 48, b: {} }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.0.arr.$.a.b', [1], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: { b: [1] }, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.array.index.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.0.a', 'single', o, special, function(v) {
            return 88;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 88, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.0.a', 'single', o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 'single', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.arr.0.a', [4, 8, 15, 16, 23, 42], o, special, function(v) {
            return v * 2;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 8, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.0.a', [4, 8, 15, 16, 23, 42], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 4, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.array.$.index.path', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.$.0.a', 'singles', o, special, function(v) {
            return v.toUpperCase();
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 'SINGLES', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.$.0.a', 'singles', o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 'singles', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('$.arr.arr.0.a', 'single', o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: 'single', e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          mpath.set('arr.arr.$.0.a', [4, 8, 15, 16, 23, 42], o, special, function(v) {
            return Array;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: Array, e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.$.0.a', [4, 8, 15, 16, 23, 42], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42], e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.$.arr.0.a', [4, 8, 15, 16, 23, 42, 108], o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108], e: 'a' }, { a: { c: 48, b: [1] }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('array.array.path.index', function() {
        it('with single value', function(done) {
          mpath.set('arr.arr.a.7', 47, o, special, function(v) {
            return Object;
          });
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, Object], e: 'a' }, { a: { c: 48, b: [1], 7: Object }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.a.7', 47, o, special);
          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, 47], e: 'a' }, { a: { c: 48, b: [1], 7: 47 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { special: true, yep: 0 } }
          ], o.arr);

          done();
        });
        it('with array', function(done) {
          o.arr[1]._doc.arr = [{ a: [] }, { a: [] }, { a: null }];
          mpath.set('arr.arr.a.7', [[null, 46], [undefined, 'woot']], o, special, function(v) {
            return undefined === v ? 'nope' : v;
          });

          const a1 = [];
          const a2 = [];
          a1[7] = 'nope';
          a2[7] = 'woot';

          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, null], e: 'a' }, { a: { c: 48, b: [1], 7: 46 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { arr: [{ a: a1 }, { a: a2 }, { a: null }], special: true, yep: 0 } }
          ], o.arr);

          mpath.set('arr.arr.a.7', [[null, 46], [undefined, 'woot']], o, special);

          a1[7] = undefined;

          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: { yep: [15], arr: [{ a: [4, 8, 15, 16, 23, 42, 108, null], e: 'a' }, { a: { c: 48, b: [1], 7: 46 }, e: 'b' }, { d: 'yep', e: 35 }] } },
            { yep: true, _doc: { arr: [{ a: a1 }, { a: a2 }, { a: null }], special: true, yep: 0 } }
          ], o.arr);

          done();
        });
      });

      describe('handles array.array.path', function() {
        it('with single', function(done) {
          o.arr[1]._doc.arr = [{}, {}];
          assert.deepEqual([{}, {}], o.arr[1]._doc.arr);
          o.arr.push({ _doc: { arr: 'something else' } });
          o.arr.push({ _doc: { arr: ['something else'] } });
          o.arr.push({ _doc: { arr: [[]] } });
          o.arr.push({ _doc: { arr: [5] } });

          // test
          mpath.set('arr.arr.e', 47, o, special);

          const weird = [];
          weird.e = 47;

          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: {
                yep: [15],
                arr: [
                  { a: [4, 8, 15, 16, 23, 42, 108, null], e: 47 },
                  { a: { c: 48, b: [1], 7: 46 }, e: 47 },
                  { d: 'yep', e: 47 }
                ]
              }
            },
            { yep: true,
              _doc: {
                arr: [
                  { e: 47 },
                  { e: 47 }
                ],
                special: true,
                yep: 0
              }
            },
            { _doc: { arr: 'something else' } },
            { _doc: { arr: ['something else'] } },
            { _doc: { arr: [weird] } },
            { _doc: { arr: [5] } }
          ]
          , o.arr);

          done();
        });
        it('with arrays', function(done) {
          mpath.set('arr.arr.e', [[1, 2, 3], [4, 5], null, [], [6], [7, 8, 9]], o, special);

          const weird = [];
          weird.e = 6;

          assert.deepEqual([
            { yep: 47, arr: [{ a: { b: 47 } }, { a: { c: 48 } }, { d: 'yep' }],
              _doc: {
                yep: [15],
                arr: [
                  { a: [4, 8, 15, 16, 23, 42, 108, null], e: 1 },
                  { a: { c: 48, b: [1], 7: 46 }, e: 2 },
                  { d: 'yep', e: 3 }
                ]
              }
            },
            { yep: true,
              _doc: {
                arr: [
                  { e: 4 },
                  { e: 5 }
                ],
                special: true,
                yep: 0
              }
            },
            { _doc: { arr: 'something else' } },
            { _doc: { arr: ['something else'] } },
            { _doc: { arr: [weird] } },
            { _doc: { arr: [5] } }
          ]
          , o.arr);

          done();
        });
      });

      describe('that is a function', function() {
        describe('without map', function() {
          it('works on array value', function(done) {
            const o = { hello: { world: [{ how: 'are' }, { you: '?' }] } };
            const special = function(obj, key, val) {
              if (val) {
                obj[key] = val;
              } else {
                return 'thing' == key
                  ? obj.world
                  : obj[key];
              }
            };
            mpath.set('hello.thing.how', 'arrrr', o, special);
            assert.deepEqual(o, { hello: { world: [{ how: 'arrrr' }, { you: '?', how: 'arrrr' }] } });
            done();
          });
          it('works on non-array value', function(done) {
            const o = { hello: { world: { how: 'are you' } } };
            const special = function(obj, key, val) {
              if (val) {
                obj[key] = val;
              } else {
                return 'thing' == key
                  ? obj.world
                  : obj[key];
              }
            };
            mpath.set('hello.thing.how', 'RU', o, special);
            assert.deepEqual(o, { hello: { world: { how: 'RU' } } });
            done();
          });
        });
        it('works with map', function(done) {
          const o = { hello: { world: [{ how: 'are' }, { you: '?' }] } };
          const special = function(obj, key, val) {
            if (val) {
              obj[key] = val;
            } else {
              return 'thing' == key
                ? obj.world
                : obj[key];
            }
          };
          const map = function(val) {
            return 'convert' == val
              ? 'ºº'
              : val;
          };
          mpath.set('hello.thing.how', 'convert', o, special, map);
          assert.deepEqual(o, { hello: { world: [{ how: 'ºº' }, { you: '?', how: 'ºº' }] } });
          done();
        });
      });

    });

    describe('get/set integration', function() {
      const o = doc();

      it('works', function(done) {
        const vals = mpath.get('array.o.array.x.b', o);

        vals[0][0][2] = 10;
        vals[1][0][1] = 0;
        vals[1][1] = 'Rambaldi';
        vals[1][2] = [12, 14];
        vals[2] = [{ changed: true }, [null, ['changed', 'to', 'array']]];

        mpath.set('array.o.array.x.b', vals, o);

        const t = [
          { o: { array: [{ x: { b: [4, 6, 10] } }, { y: 10 }] } },
          { o: { array: [{ x: { b: [1, 0, 3] } }, { x: { b: 'Rambaldi', z: 10 } }, { x: { b: [12, 14] } }] } },
          { o: { array: [{ x: { b: { changed: true } } }, { x: { b: [null, ['changed', 'to', 'array']] } }] } },
          { o: { array: [{ x: null }] } },
          { o: { array: [{ y: 3 }] } },
          { o: { array: [3, 0, null] } },
          { o: { name: 'ha' } }
        ];
        assert.deepEqual(t, o.array);
        done();
      });

      it('array.prop', function(done) {
        mpath.set('comments.name', ['this', 'was', 'changed'], o);

        assert.deepEqual([
          { name: 'this' },
          { name: 'was', _doc: { name: '2' } },
          { name: 'changed',
            comments: [{}, { comments: [{ val: 'twoo' }] }],
            _doc: { name: '3', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }
        ], o.comments);

        mpath.set('comments.name', ['also', 'changed', 'this'], o, special);

        assert.deepEqual([
          { name: 'also' },
          { name: 'was', _doc: { name: 'changed' } },
          { name: 'changed',
            comments: [{}, { comments: [{ val: 'twoo' }] }],
            _doc: { name: 'this', comments: [{}, { _doc: { comments: [{ val: 2 }] } }] } }
        ], o.comments);

        done();
      });

      it('nested array', function(done) {
        const obj = { arr: [[{ test: 41 }]] };
        mpath.set('arr.test', [[42]], obj);
        assert.deepEqual(obj.arr, [[{ test: 42 }]]);
        done();
      });
    });

    describe('multiple $ use', function() {
      const o = doc();
      it('is ok', function(done) {
        assert.doesNotThrow(function() {
          mpath.set('arr.$.arr.$.a', 35, o);
        });
        done();
      });
    });

    it('has', function(done) {
      assert.ok(mpath.has('a', { a: 1 }));
      assert.ok(mpath.has('a', { a: undefined }));
      assert.ok(!mpath.has('a', {}));
      assert.ok(!mpath.has('a', null));

      assert.ok(mpath.has('a.b', { a: { b: 1 } }));
      assert.ok(mpath.has('a.b', { a: { b: undefined } }));
      assert.ok(!mpath.has('a.b', { a: 1 }));
      assert.ok(!mpath.has('a.b', { a: null }));

      done();
    });

    it('underneath a map', function(done) {
      if (!global.Map) {
        done();
        return;
      }
      assert.equal(mpath.get('a.b', { a: new Map([['b', 1]]) }), 1);

      const m = new Map([['b', 1]]);
      const obj = { a: m };
      mpath.set('a.c', 2, obj);
      assert.equal(m.get('c'), 2);

      done();
    });

    it('unset', function(done) {
      let o = { a: 1 };
      mpath.unset('a', o);
      assert.deepEqual(o, {});

      o = { a: { b: 1 } };
      mpath.unset('a.b', o);
      assert.deepEqual(o, { a: {} });

      o = { a: null };
      mpath.unset('a.b', o);
      assert.deepEqual(o, { a: null });

      done();
    });

    it('unset with __proto__', function(done) {
      // Should refuse to set __proto__
      function Clazz() {}
      Clazz.prototype.foobar = true;

      mpath.unset('__proto__.foobar', new Clazz());
      assert.ok(Clazz.prototype.foobar);

      mpath.unset('constructor.prototype.foobar', new Clazz());
      assert.ok(Clazz.prototype.foobar);

      done();
    });

    it('get() underneath subclassed array', function(done) {
      class MyArray extends Array {}

      const obj = {
        arr: new MyArray()
      };
      obj.arr.push({ test: 2 });

      const arr = mpath.get('arr.test', obj);
      assert.equal(arr.constructor.name, 'Array');
      assert.ok(!(arr instanceof MyArray));

      done();
    });

    it('ignores setting a nested path that doesnt exist', function(done) {
      const o = doc();
      assert.doesNotThrow(function() {
        mpath.set('thing.that.is.new', 10, o);
      });
      done();
    });
  });
});
