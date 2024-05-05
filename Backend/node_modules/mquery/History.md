5.0.0 / 2023-02-23
==================
 * BREAKING CHANGE: drop callback support #137 [hasezoey](https://github.com/hasezoey)
 * BREAKING CHANGE: remove custom promise library support #137 [hasezoey](https://github.com/hasezoey)
 * BREAKING CHANGE: remove long deprecated `update`, `remove` functions #136 [hasezoey](https://github.com/hasezoey)
 * BREAKING CHANGE: remove collection ducktyping: first param to `mquery()` is now always the query filter #138
 * feat: support MongoDB Node driver 5 #137 [hasezoey](https://github.com/hasezoey)

4.0.3 / 2022-05-17
==================
 * fix: allow using `comment` with `findOneAndUpdate()`, `count()`, `distinct()` and `hint` with `findOneAndUpdate()` Automattic/mongoose#11793

4.0.2 / 2022-01-23
==================
 * perf: replace regexp-clone with native functionality #131 [Uzlopak](https://github.com/Uzlopak)

4.0.1 / 2022-01-20
==================
 * perf: remove sliced, add various microoptimizations #130 [Uzlopak](https://github.com/Uzlopak)
 * refactor: convert NodeCollection to a class #128 [jimmywarting](https://github.com/jimmywarting)

4.0.0 / 2021-08-24

4.0.0-rc0 / 2021-08-19
======================
 * BREAKING CHANGE: drop support for Node < 12 #123
 * BREAKING CHANGE: upgrade to mongodb driver 4.x: drop support for `findAndModify()`, use native `findOneAndUpdate/Delete` #124
 * BREAKING CHANGE: rename findStream -> findCursor #124
 * BREAKING CHANGE: use native ES6 promises by default, remove bluebird dependency #123

3.2.5 / 2021-03-29
==================
 * fix(utils): make `mergeClone()` skip special properties like `__proto__` #121 [zpbrent](https://github.com/zpbrent)

3.2.4 / 2021-02-12
==================
 * fix(utils): make clone() only copy own properties Automattic/mongoose#9876

3.2.3 / 2020-12-10
==================
 * fix(utils): avoid copying special properties like `__proto__` when merging and cloning. Fix CVE-2020-35149

3.2.2 / 2019-09-22
==================
 * fix: dont re-call setOptions() when pulling base class options Automattic/mongoose#8159

3.2.1 / 2018-08-24
==================
 * chore: upgrade deps

3.2.0 / 2018-08-24
==================
 * feat: add $useProjection to opt in to using `projection` instead of `fields` re: MongoDB deprecation warnings Automattic/mongoose#6880

3.1.2 / 2018-08-01
==================
 * chore: move eslint to devDependencies #110 [jakesjews](https://github.com/jakesjews)

3.1.1 / 2018-07-30
==================
 * chore: add eslint #107 [Fonger](https://github.com/Fonger)
 * docs: clean up readConcern docs #106 [Fonger](https://github.com/Fonger)

3.1.0 / 2018-07-29
==================
 * feat: add `readConcern()` helper #105 [Fonger](https://github.com/Fonger)
 * feat: add `maxTimeMS()` as alias of `maxTime()` #105 [Fonger](https://github.com/Fonger)
 * feat: add `collation()` helper #105 [Fonger](https://github.com/Fonger)

3.0.1 / 2018-07-02
==================
 * fix: parse sort array options correctly #103 #102 [Fonger](https://github.com/Fonger)

3.0.0 / 2018-01-20
==================
 * chore: upgrade deps and add nsp

3.0.0-rc0 / 2017-12-06
======================
 * BREAKING CHANGE: remove support for node < 4
 * BREAKING CHANGE: remove support for retainKeyOrder, will always be true by default re: Automattic/mongoose#2749

2.3.3 / 2017-11-19
==================
 * fixed; catch sync errors in cursor.toArray() re: Automattic/mongoose#5812

2.3.2 / 2017-09-27
==================
 * fixed; bumped debug -> 2.6.9 re: #89

2.3.1 / 2017-05-22
==================
 * fixed; bumped debug -> 2.6.7 re: #86

2.3.0 / 2017-03-05
==================
 * added; replaceOne function
 * added; deleteOne and deleteMany functions

2.2.3 / 2017-01-31
==================
 * fixed; throw correct error when passing incorrectly formatted array to sort()

2.2.2 / 2017-01-31
==================
 * fixed; allow passing maps to sort()

2.2.1 / 2017-01-29
==================
 * fixed; allow passing string to hint()

2.2.0 / 2017-01-08
==================
 * added; updateOne and updateMany functions

2.1.0 / 2016-12-22
==================
 * added; ability to pass an array to select() #81 [dciccale](https://github.com/dciccale)

2.0.0 / 2016-09-25
==================
 * added; support for mongodb driver 2.0 streams

1.12.0 / 2016-09-25
===================
 * added; `retainKeyOrder` option re: Automattic/mongoose#4542

1.11.0 / 2016-06-04
===================
 * added; `.minDistance()` helper and minDistance for `.near()` Automattic/mongoose#4179

1.10.1 / 2016-04-26
===================
 * fixed; ensure conditions is an object before assigning #75

1.10.0 / 2016-03-16
==================

 * updated; bluebird to latest 2.10.2 version #74 [matskiv](https://github.com/matskiv)

1.9.0 / 2016-03-15
==================
 * added; `.eq` as a shortcut for `.equals` #72 [Fonger](https://github.com/Fonger)
 * added; ability to use array syntax for sort re: https://jira.mongodb.org/browse/NODE-578 #67

1.8.0 / 2016-03-01
==================
 * fixed; dont throw an error if count used with sort or select Automattic/mongoose#3914

1.7.0 / 2016-02-23
==================
 * fixed; don't treat objects with a length property as argument objects #70
 * added; `.findCursor()` method #69 [nswbmw](https://github.com/nswbmw)
 * added; `_compiledUpdate` property #68 [nswbmw](https://github.com/nswbmw)

1.6.2 / 2015-07-12
==================

 * fixed; support exec cb being called synchronously #66

1.6.1 / 2015-06-16
==================

 * fixed; do not treat $meta projection as inclusive [vkarpov15](https://github.com/vkarpov15)

1.6.0 / 2015-05-27
==================

 * update dependencies #65 [bachp](https://github.com/bachp)

1.5.0 / 2015-03-31
==================

 * fixed; debug output
 * fixed; allow hint usage with count #61 [trueinsider](https://github.com/trueinsider)

1.4.0 / 2015-03-29
==================

 * added; object support to slice() #60 [vkarpov15](https://github.com/vkarpov15)
 * debug; improved output #57 [flyvictor](https://github.com/flyvictor)

1.3.0 / 2014-11-06
==================

 * added; setTraceFunction() #53 from [jlai](https://github.com/jlai)

1.2.1 / 2014-09-26
==================

 * fixed; distinct assignment in toConstructor() #51 from [esco](https://github.com/esco)

1.2.0 / 2014-09-18
==================

 * added; stream() support for find()

1.1.0 / 2014-09-15
==================

 * add #then for co / koa support
 * start checking code coverage

1.0.0 / 2014-07-07
==================

 * Remove broken require() calls until they're actually implemented #48 [vkarpov15](https://github.com/vkarpov15)

0.9.0 / 2014-05-22
==================

 * added; thunk() support
 * release 0.8.0

0.8.0 / 2014-05-15
==================

 * added; support for maxTimeMS #44 [yoitsro](https://github.com/yoitsro)
 * updated; devDependency (driver to 1.4.4)

0.7.0 / 2014-05-02
==================

 * fixed; pass $maxDistance in $near object as described in docs #43 [vkarpov15](https://github.com/vkarpov15)
 * fixed; cloning buffers #42 [gjohnson](https://github.com/gjohnson)
 * tests; a little bit more `mongodb` agnostic #34 [refack](https://github.com/refack)

0.6.0 / 2014-04-01
==================

 * fixed; Allow $meta args in sort() so text search sorting works #37 [vkarpov15](https://github.com/vkarpov15)

0.5.3 / 2014-02-22
==================

 * fixed; cloning mongodb.Binary

0.5.2 / 2014-01-30
==================

 * fixed; cloning ObjectId constructors
 * fixed; cloning of ReadPreferences #30 [ashtuchkin](https://github.com/ashtuchkin)
 * tests; use specific mongodb version #29 [AvianFlu](https://github.com/AvianFlu)
 * tests; remove dependency on ObjectId #28 [refack](https://github.com/refack)
 * tests; add failing ReadPref test

0.5.1 / 2014-01-17
==================

 * added; deprecation notice to tags parameter #27 [ashtuchkin](https://github.com/ashtuchkin)
 * readme; add links

0.5.0 / 2014-01-16
==================

 * removed; mongodb driver dependency #26 [ashtuchkin](https://github.com/ashtuchkin)
 * removed; first class support of read preference tags #26 (still supported though) [ashtuchkin](https://github.com/ashtuchkin)
 * added; better ObjectId clone support
 * fixed; cloning objects that have no constructor #21
 * docs; cleaned up [ashtuchkin](https://github.com/ashtuchkin)

0.4.2 / 2014-01-08
==================

 * updated; debug module 0.7.4 [refack](https://github.com/refack)

0.4.1 / 2014-01-07
==================

 * fixed; inclusive/exclusive logic

0.4.0 / 2014-01-06
==================

 * added; selected()
 * added; selectedInclusively()
 * added; selectedExclusively()

0.3.3 / 2013-11-14
==================

 * Fix Mongo DB Dependency #20 [rschmukler](https://github.com/rschmukler)

0.3.2 / 2013-09-06
==================

  * added; geometry support for near()

0.3.1 / 2013-08-22
==================

  * fixed; update retains key order #19

0.3.0 / 2013-08-22
==================

  * less hardcoded isNode env detection #18 [vshulyak](https://github.com/vshulyak)
  * added; validation of findAndModify varients
  * clone update doc before execution
  * stricter env checks

0.2.7 / 2013-08-2
==================

  * Now support GeoJSON point values for Query#near

0.2.6 / 2013-07-30
==================

  * internally, 'asc' and 'desc' for sorts are now converted into 1 and -1, respectively

0.2.5 / 2013-07-30
==================

  * updated docs
  * changed internal representation of `sort` to use objects instead of arrays

0.2.4 / 2013-07-25
==================

  * updated; sliced to 0.0.5

0.2.3 / 2013-07-09
==================

  * now using a callback in collection.find instead of directly calling toArray() on the cursor [ebensing](https://github.com/ebensing)

0.2.2 / 2013-07-09
==================

  * now exposing mongodb export to allow for better testing [ebensing](https://github.com/ebensing)

0.2.1 / 2013-07-08
==================

  * select no longer accepts arrays as parameters [ebensing](https://github.com/ebensing)

0.2.0 / 2013-07-05
==================

  * use $geoWithin by default

0.1.2 / 2013-07-02
==================

  * added use$geoWithin flag [ebensing](https://github.com/ebensing)
  * fix read preferences typo [ebensing](https://github.com/ebensing)
  * fix reference to old param name in exists() [ebensing](https://github.com/ebensing)

0.1.1 / 2013-06-24
==================

  * fixed; $intersects -> $geoIntersects #14 [ebensing](https://github.com/ebensing)
  * fixed; Retain key order when copying objects #15 [ebensing](https://github.com/ebensing)
  * bump mongodb dev dep

0.1.0 / 2013-05-06
==================

  * findAndModify; return the query
  * move mquery.proto.canMerge to mquery.canMerge
  * overwrite option now works with non-empty objects
  * use strict mode
  * validate count options
  * validate distinct options
  * add aggregate to base collection methods
  * clone merge arguments
  * clone merged update arguments
  * move subclass to mquery.prototype.toConstructor
  * fixed; maxScan casing
  * use regexp-clone
  * added; geometry/intersects support
  * support $and
  * near: do not use "radius"
  * callbacks always fire on next turn of loop
  * defined collection interface
  * remove time from tests
  * clarify goals
  * updated docs;

0.0.1 / 2012-12-15
==================

  * initial release
