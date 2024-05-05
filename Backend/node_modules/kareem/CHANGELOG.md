# Changelog

<a name="2.6.0"></a>
## 2.6.0 (2024-03-04)

* feat: add TypeScript types

<a name="2.5.1"></a>
## 2.5.1 (2023-01-06)

* fix: avoid passing final callback to pre hook, because calling the callback can mess up hook execution #36 Automattic/mongoose#12836

<a name="2.5.0"></a>
## 2.5.0 (2022-12-01)

* feat: add errorHandler option to `post()` #34

<a name="2.4.0"></a>
## 2.4.0 (2022-06-13)

* feat: add `overwriteResult()` and `skipWrappedFunction()` for more advanced control flow

<a name="2.3.4"></a>
## 2.3.4 (2022-02-10)

* perf: various performance improvements #27 #24 #23 #22 #21 #20

<a name="2.3.3"></a>
## 2.3.3 (2021-12-26)

* fix: handle sync errors in `wrap()`

<a name="2.3.2"></a>
## 2.3.2 (2020-12-08)

* fix: handle sync errors in pre hooks if there are multiple hooks

<a name="2.3.0"></a>
## 2.3.0 (2018-09-24)

* chore(release): 2.2.3 ([c8f2695](https://github.com/vkarpov15/kareem/commit/c8f2695))
* chore(release): 2.2.4 ([a377a4f](https://github.com/vkarpov15/kareem/commit/a377a4f))
* chore(release): 2.2.5 ([5a495e3](https://github.com/vkarpov15/kareem/commit/5a495e3))
* fix(filter): copy async pres correctly with `filter()` ([1b1ed8a](https://github.com/vkarpov15/kareem/commit/1b1ed8a)), closes [Automattic/mongoose#3054](https://github.com/Automattic/mongoose/issues/3054)
* feat: add filter() function ([1f641f4](https://github.com/vkarpov15/kareem/commit/1f641f4))
* feat: support storing options on pre and post hooks ([59220b9](https://github.com/vkarpov15/kareem/commit/59220b9))



<a name="2.2.3"></a>
## <small>2.2.3 (2018-09-10)</small>

* chore: release 2.2.3 ([af653a3](https://github.com/vkarpov15/kareem/commit/af653a3))



<a name="2.2.2"></a>
## <small>2.2.2 (2018-09-10)</small>

* chore: release 2.2.2 ([3f0144d](https://github.com/vkarpov15/kareem/commit/3f0144d))
* fix: allow merge() to not clone ([e628d65](https://github.com/vkarpov15/kareem/commit/e628d65))



<a name="2.2.1"></a>
## <small>2.2.1 (2018-06-05)</small>

* chore: release 2.2.1 ([4625a64](https://github.com/vkarpov15/kareem/commit/4625a64))
* chore: remove lockfile from git ([7f3e4e6](https://github.com/vkarpov15/kareem/commit/7f3e4e6))
* fix: handle numAsync correctly when merging ([fef8e7e](https://github.com/vkarpov15/kareem/commit/fef8e7e))
* test: repro issue with not copying numAsync ([952d9db](https://github.com/vkarpov15/kareem/commit/952d9db))



<a name="2.2.0"></a>
## 2.2.0 (2018-06-05)

* chore: release 2.2.0 ([ff9ad03](https://github.com/vkarpov15/kareem/commit/ff9ad03))
* fix: use maps instead of objects for _pres and _posts so `toString()` doesn't get reported as having ([55df303](https://github.com/vkarpov15/kareem/commit/55df303)), closes [Automattic/mongoose#6538](https://github.com/Automattic/mongoose/issues/6538)



<a name="2.1.0"></a>
## 2.1.0 (2018-05-16)

* chore: release 2.1.0 ([ba5f1bc](https://github.com/vkarpov15/kareem/commit/ba5f1bc))
* feat: add option to check wrapped function return value for promises ([c9d7dd1](https://github.com/vkarpov15/kareem/commit/c9d7dd1))
* refactor: use const in wrap() ([0fc21f9](https://github.com/vkarpov15/kareem/commit/0fc21f9))



<a name="2.0.7"></a>
## <small>2.0.7 (2018-04-28)</small>

* chore: release 2.0.7 ([0bf91e6](https://github.com/vkarpov15/kareem/commit/0bf91e6))
* feat: add `hasHooks()` ([225f18d](https://github.com/vkarpov15/kareem/commit/225f18d)), closes [Automattic/mongoose#6385](https://github.com/Automattic/mongoose/issues/6385)



<a name="2.0.6"></a>
## <small>2.0.6 (2018-03-22)</small>

* chore: release 2.0.6 ([f3d406b](https://github.com/vkarpov15/kareem/commit/f3d406b))
* fix(wrap): ensure fast path still wraps function in `nextTick()` for chaining ([7000494](https://github.com/vkarpov15/kareem/commit/7000494)), closes [Automattic/mongoose#6250](https://github.com/Automattic/mongoose/issues/6250) [dsanel/mongoose-delete#36](https://github.com/dsanel/mongoose-delete/issues/36)



<a name="2.0.5"></a>
## <small>2.0.5 (2018-02-22)</small>

* chore: release 2.0.5 ([3286612](https://github.com/vkarpov15/kareem/commit/3286612))
* perf(createWrapper): don't create wrapper if there are no hooks ([5afc5b9](https://github.com/vkarpov15/kareem/commit/5afc5b9)), closes [Automattic/mongoose#6126](https://github.com/Automattic/mongoose/issues/6126)



<a name="2.0.4"></a>
## <small>2.0.4 (2018-02-08)</small>

* chore: release 2.0.4 ([2ab0293](https://github.com/vkarpov15/kareem/commit/2ab0293))



<a name="2.0.3"></a>
## <small>2.0.3 (2018-02-01)</small>

* chore: release 2.0.3 ([3c1abe5](https://github.com/vkarpov15/kareem/commit/3c1abe5))
* fix: use process.nextTick() re: Automattic/mongoose#6074 ([e5bfe33](https://github.com/vkarpov15/kareem/commit/e5bfe33)), closes [Automattic/mongoose#6074](https://github.com/Automattic/mongoose/issues/6074)



<a name="2.0.2"></a>
## <small>2.0.2 (2018-01-24)</small>

* chore: fix license ([a9d755c](https://github.com/vkarpov15/kareem/commit/a9d755c)), closes [#10](https://github.com/vkarpov15/kareem/issues/10)
* chore: release 2.0.2 ([fe87ab6](https://github.com/vkarpov15/kareem/commit/fe87ab6))



<a name="2.0.1"></a>
## <small>2.0.1 (2018-01-09)</small>

* chore: release 2.0.1 with lockfile bump ([09c44fb](https://github.com/vkarpov15/kareem/commit/09c44fb))



<a name="2.0.0"></a>
## 2.0.0 (2018-01-09)

* chore: bump marked re: security ([cc564a9](https://github.com/vkarpov15/kareem/commit/cc564a9))
* chore: release 2.0.0 ([f511d1c](https://github.com/vkarpov15/kareem/commit/f511d1c))



<a name="2.0.0-rc5"></a>
## 2.0.0-rc5 (2017-12-23)

* chore: fix build on node 4+5 ([6dac5a4](https://github.com/vkarpov15/kareem/commit/6dac5a4))
* chore: fix built on node 4 + 5 again ([434ef0a](https://github.com/vkarpov15/kareem/commit/434ef0a))
* chore: release 2.0.0-rc5 ([25a32ee](https://github.com/vkarpov15/kareem/commit/25a32ee))



<a name="2.0.0-rc4"></a>
## 2.0.0-rc4 (2017-12-22)

* chore: release 2.0.0-rc4 ([49fc083](https://github.com/vkarpov15/kareem/commit/49fc083))
* BREAKING CHANGE: deduplicate when merging hooks re: Automattic/mongoose#2945 ([d458573](https://github.com/vkarpov15/kareem/commit/d458573)), closes [Automattic/mongoose#2945](https://github.com/Automattic/mongoose/issues/2945)



<a name="2.0.0-rc3"></a>
## 2.0.0-rc3 (2017-12-22)

* chore: release 2.0.0-rc3 ([adaaa00](https://github.com/vkarpov15/kareem/commit/adaaa00))
* feat: support returning promises from middleware functions ([05b4480](https://github.com/vkarpov15/kareem/commit/05b4480)), closes [Automattic/mongoose#3779](https://github.com/Automattic/mongoose/issues/3779)



<a name="2.0.0-rc2"></a>
## 2.0.0-rc2 (2017-12-21)

* chore: release 2.0.0-rc2 ([76325fa](https://github.com/vkarpov15/kareem/commit/76325fa))
* fix: ensure next() and done() run in next tick ([6c20684](https://github.com/vkarpov15/kareem/commit/6c20684))



<a name="2.0.0-rc1"></a>
## 2.0.0-rc1 (2017-12-21)

* chore: improve test coverage re: Automattic/mongoose#3232 ([7b45cf0](https://github.com/vkarpov15/kareem/commit/7b45cf0)), closes [Automattic/mongoose#3232](https://github.com/Automattic/mongoose/issues/3232)
* chore: release 2.0.0-rc1 ([9b83f52](https://github.com/vkarpov15/kareem/commit/9b83f52))
* BREAKING CHANGE: report sync exceptions as errors, only allow calling next() and done() once ([674adcc](https://github.com/vkarpov15/kareem/commit/674adcc)), closes [Automattic/mongoose#3483](https://github.com/Automattic/mongoose/issues/3483)



<a name="2.0.0-rc0"></a>
## 2.0.0-rc0 (2017-12-17)

* chore: release 2.0.0-rc0 ([16b44b5](https://github.com/vkarpov15/kareem/commit/16b44b5))
* BREAKING CHANGE: drop support for node < 4 ([9cbb8c7](https://github.com/vkarpov15/kareem/commit/9cbb8c7))
* BREAKING CHANGE: remove useLegacyPost and add several new features ([6dd8531](https://github.com/vkarpov15/kareem/commit/6dd8531)), closes [Automattic/mongoose#3232](https://github.com/Automattic/mongoose/issues/3232)



<a name="1.5.0"></a>
## 1.5.0 (2017-07-20)

* chore: release 1.5.0 ([9c491a0](https://github.com/vkarpov15/kareem/commit/9c491a0))
* fix: improve post error handlers results ([9928dd5](https://github.com/vkarpov15/kareem/commit/9928dd5)), closes [Automattic/mongoose#5466](https://github.com/Automattic/mongoose/issues/5466)



<a name="1.4.2"></a>
## <small>1.4.2 (2017-07-06)</small>

* chore: release 1.4.2 ([8d14ac5](https://github.com/vkarpov15/kareem/commit/8d14ac5))
* fix: correct args re: Automattic/mongoose#5405 ([3f28ae6](https://github.com/vkarpov15/kareem/commit/3f28ae6)), closes [Automattic/mongoose#5405](https://github.com/Automattic/mongoose/issues/5405)



<a name="1.4.1"></a>
## <small>1.4.1 (2017-04-25)</small>

* chore: release 1.4.1 ([5ecf0c2](https://github.com/vkarpov15/kareem/commit/5ecf0c2))
* fix: handle numAsyncPres with clone() ([c72e857](https://github.com/vkarpov15/kareem/commit/c72e857)), closes [#8](https://github.com/vkarpov15/kareem/issues/8)
* test: repro #8 ([9b4d6b2](https://github.com/vkarpov15/kareem/commit/9b4d6b2)), closes [#8](https://github.com/vkarpov15/kareem/issues/8)



<a name="1.4.0"></a>
## 1.4.0 (2017-04-19)

* chore: release 1.4.0 ([101c5f5](https://github.com/vkarpov15/kareem/commit/101c5f5))
* feat: add merge() function ([285325e](https://github.com/vkarpov15/kareem/commit/285325e))



<a name="1.3.0"></a>
## 1.3.0 (2017-03-26)

* chore: release 1.3.0 ([f3a9e50](https://github.com/vkarpov15/kareem/commit/f3a9e50))
* feat: pass function args to execPre ([4dd466d](https://github.com/vkarpov15/kareem/commit/4dd466d))



<a name="1.2.1"></a>
## <small>1.2.1 (2017-02-03)</small>

* chore: release 1.2.1 ([d97081f](https://github.com/vkarpov15/kareem/commit/d97081f))
* fix: filter out _kareemIgnored args for error handlers re: Automattic/mongoose#4925 ([ddc7aeb](https://github.com/vkarpov15/kareem/commit/ddc7aeb)), closes [Automattic/mongoose#4925](https://github.com/Automattic/mongoose/issues/4925)
* fix: make error handlers handle errors in pre hooks ([af38033](https://github.com/vkarpov15/kareem/commit/af38033)), closes [Automattic/mongoose#4927](https://github.com/Automattic/mongoose/issues/4927)



<a name="1.2.0"></a>
## 1.2.0 (2017-01-02)

* chore: release 1.2.0 ([033225c](https://github.com/vkarpov15/kareem/commit/033225c))
* chore: upgrade deps ([f9e9a09](https://github.com/vkarpov15/kareem/commit/f9e9a09))
* feat: add _kareemIgnore re: Automattic/mongoose#4836 ([7957771](https://github.com/vkarpov15/kareem/commit/7957771)), closes [Automattic/mongoose#4836](https://github.com/Automattic/mongoose/issues/4836)



<a name="1.1.5"></a>
## <small>1.1.5 (2016-12-13)</small>

* chore: release 1.1.5 ([1a9f684](https://github.com/vkarpov15/kareem/commit/1a9f684))
* fix: correct field name ([04a0e9d](https://github.com/vkarpov15/kareem/commit/04a0e9d))



<a name="1.1.4"></a>
## <small>1.1.4 (2016-12-09)</small>

* chore: release 1.1.4 ([ece401c](https://github.com/vkarpov15/kareem/commit/ece401c))
* chore: run tests on node 6 ([e0cb1cb](https://github.com/vkarpov15/kareem/commit/e0cb1cb))
* fix: only copy own properties in clone() ([dfe28ce](https://github.com/vkarpov15/kareem/commit/dfe28ce)), closes [#7](https://github.com/vkarpov15/kareem/issues/7)



<a name="1.1.3"></a>
## <small>1.1.3 (2016-06-27)</small>

* chore: release 1.1.3 ([87171c8](https://github.com/vkarpov15/kareem/commit/87171c8))
* fix: couple more issues with arg processing ([c65f523](https://github.com/vkarpov15/kareem/commit/c65f523))



<a name="1.1.2"></a>
## <small>1.1.2 (2016-06-27)</small>

* chore: release 1.1.2 ([8e102b6](https://github.com/vkarpov15/kareem/commit/8e102b6))
* fix: add early return ([4feda4e](https://github.com/vkarpov15/kareem/commit/4feda4e))



<a name="1.1.1"></a>
## <small>1.1.1 (2016-06-27)</small>

* chore: release 1.1.1 ([8bb3050](https://github.com/vkarpov15/kareem/commit/8bb3050))
* fix: skip error handlers if no error ([0eb3a44](https://github.com/vkarpov15/kareem/commit/0eb3a44))



<a name="1.1.0"></a>
## 1.1.0 (2016-05-11)

* chore: release 1.1.0 ([85332d9](https://github.com/vkarpov15/kareem/commit/85332d9))
* chore: test on node 4 and node 5 ([1faefa1](https://github.com/vkarpov15/kareem/commit/1faefa1))
* 100% coverage again ([c9aee4e](https://github.com/vkarpov15/kareem/commit/c9aee4e))
* add support for error post hooks ([d378113](https://github.com/vkarpov15/kareem/commit/d378113))
* basic setup for sync hooks #4 ([55aa081](https://github.com/vkarpov15/kareem/commit/55aa081)), closes [#4](https://github.com/vkarpov15/kareem/issues/4)
* proof of concept for error handlers ([e4a07d9](https://github.com/vkarpov15/kareem/commit/e4a07d9))
* refactor out handleWrapError helper ([b19af38](https://github.com/vkarpov15/kareem/commit/b19af38))



<a name="1.0.1"></a>
## <small>1.0.1 (2015-05-10)</small>

* Fix #1 ([de60dc6](https://github.com/vkarpov15/kareem/commit/de60dc6)), closes [#1](https://github.com/vkarpov15/kareem/issues/1)
* release 1.0.1 ([6971088](https://github.com/vkarpov15/kareem/commit/6971088))
* Run tests on iojs in travis ([adcd201](https://github.com/vkarpov15/kareem/commit/adcd201))
* support legacy post hook behavior in wrap() ([23fa74c](https://github.com/vkarpov15/kareem/commit/23fa74c))
* Use node 0.12 in travis ([834689d](https://github.com/vkarpov15/kareem/commit/834689d))



<a name="1.0.0"></a>
## 1.0.0 (2015-01-28)

* Tag 1.0.0 ([4c5a35a](https://github.com/vkarpov15/kareem/commit/4c5a35a))



<a name="0.0.8"></a>
## <small>0.0.8 (2015-01-27)</small>

* Add clone function ([688bba7](https://github.com/vkarpov15/kareem/commit/688bba7))
* Add jscs for style checking ([5c93149](https://github.com/vkarpov15/kareem/commit/5c93149))
* Bump 0.0.8 ([03c0d2f](https://github.com/vkarpov15/kareem/commit/03c0d2f))
* Fix jscs config, add gulp rules ([9989abf](https://github.com/vkarpov15/kareem/commit/9989abf))
* fix Makefile typo ([1f7e61a](https://github.com/vkarpov15/kareem/commit/1f7e61a))



<a name="0.0.7"></a>
## <small>0.0.7 (2015-01-04)</small>

* Bump 0.0.7 ([98ef173](https://github.com/vkarpov15/kareem/commit/98ef173))
* fix LearnBoost/mongoose#2553 - use null instead of undefined for err ([9157b48](https://github.com/vkarpov15/kareem/commit/9157b48)), closes [LearnBoost/mongoose#2553](https://github.com/LearnBoost/mongoose/issues/2553)
* Regenerate docs ([2331cdf](https://github.com/vkarpov15/kareem/commit/2331cdf))



<a name="0.0.6"></a>
## <small>0.0.6 (2015-01-01)</small>

* Update docs and bump 0.0.6 ([92c12a7](https://github.com/vkarpov15/kareem/commit/92c12a7))



<a name="0.0.5"></a>
## <small>0.0.5 (2015-01-01)</small>

* Add coverage rule to Makefile ([825a91c](https://github.com/vkarpov15/kareem/commit/825a91c))
* Add coveralls to README ([fb52369](https://github.com/vkarpov15/kareem/commit/fb52369))
* Add coveralls to travis ([93f6f15](https://github.com/vkarpov15/kareem/commit/93f6f15))
* Add createWrapper() function ([ea77741](https://github.com/vkarpov15/kareem/commit/ea77741))
* Add istanbul code coverage ([6eceeef](https://github.com/vkarpov15/kareem/commit/6eceeef))
* Add some more comments for examples ([c5b0c6f](https://github.com/vkarpov15/kareem/commit/c5b0c6f))
* Add travis ([e6dcb06](https://github.com/vkarpov15/kareem/commit/e6dcb06))
* Add travis badge to docs ([ad8c9b3](https://github.com/vkarpov15/kareem/commit/ad8c9b3))
* Add wrap() tests, 100% coverage ([6945be4](https://github.com/vkarpov15/kareem/commit/6945be4))
* Better test coverage for execPost ([d9ad539](https://github.com/vkarpov15/kareem/commit/d9ad539))
* Bump 0.0.5 ([69875b1](https://github.com/vkarpov15/kareem/commit/69875b1))
* Docs fix ([15b7098](https://github.com/vkarpov15/kareem/commit/15b7098))
* Fix silly mistake in docs generation ([50373eb](https://github.com/vkarpov15/kareem/commit/50373eb))
* Fix typo in readme ([fec4925](https://github.com/vkarpov15/kareem/commit/fec4925))
* Linkify travis badge ([92b25fe](https://github.com/vkarpov15/kareem/commit/92b25fe))
* Make travis run coverage ([747157b](https://github.com/vkarpov15/kareem/commit/747157b))
* Move travis status badge ([d52e89b](https://github.com/vkarpov15/kareem/commit/d52e89b))
* Quick fix for coverage ([50bbddb](https://github.com/vkarpov15/kareem/commit/50bbddb))
* Typo fix ([adea794](https://github.com/vkarpov15/kareem/commit/adea794))



<a name="0.0.4"></a>
## <small>0.0.4 (2014-12-13)</small>

* Bump 0.0.4, run docs generation ([51a15fe](https://github.com/vkarpov15/kareem/commit/51a15fe))
* Use correct post parameters in wrap() ([9bb5da3](https://github.com/vkarpov15/kareem/commit/9bb5da3))



<a name="0.0.3"></a>
## <small>0.0.3 (2014-12-12)</small>

* Add npm test script, fix small bug with args not getting passed through post ([49e3e68](https://github.com/vkarpov15/kareem/commit/49e3e68))
* Bump 0.0.3 ([65621d8](https://github.com/vkarpov15/kareem/commit/65621d8))
* Update readme ([901388b](https://github.com/vkarpov15/kareem/commit/901388b))



<a name="0.0.2"></a>
## <small>0.0.2 (2014-12-12)</small>

* Add github repo and bump 0.0.2 ([59db8be](https://github.com/vkarpov15/kareem/commit/59db8be))



<a name="0.0.1"></a>
## <small>0.0.1 (2014-12-12)</small>

* Add basic docs ([ad29ea4](https://github.com/vkarpov15/kareem/commit/ad29ea4))
* Add pre hooks ([2ffc356](https://github.com/vkarpov15/kareem/commit/2ffc356))
* Add wrap function ([68c540c](https://github.com/vkarpov15/kareem/commit/68c540c))
* Bump to version 0.0.1 ([a4bfd68](https://github.com/vkarpov15/kareem/commit/a4bfd68))
* Initial commit ([4002458](https://github.com/vkarpov15/kareem/commit/4002458))
* Initial deposit ([98fc489](https://github.com/vkarpov15/kareem/commit/98fc489))
* Post hooks ([395b67c](https://github.com/vkarpov15/kareem/commit/395b67c))
* Some basic setup work ([82df75e](https://github.com/vkarpov15/kareem/commit/82df75e))
* Support sync pre hooks ([1cc1b9f](https://github.com/vkarpov15/kareem/commit/1cc1b9f))
* Update package.json description ([978da18](https://github.com/vkarpov15/kareem/commit/978da18))



<a name="2.2.5"></a>
## <small>2.2.5 (2018-09-24)</small>




<a name="2.2.4"></a>
## <small>2.2.4 (2018-09-24)</small>




<a name="2.2.3"></a>
## <small>2.2.3 (2018-09-24)</small>

* fix(filter): copy async pres correctly with `filter()` ([1b1ed8a](https://github.com/vkarpov15/kareem/commit/1b1ed8a)), closes [Automattic/mongoose#3054](https://github.com/Automattic/mongoose/issues/3054)
* feat: add filter() function ([1f641f4](https://github.com/vkarpov15/kareem/commit/1f641f4))
* feat: support storing options on pre and post hooks ([59220b9](https://github.com/vkarpov15/kareem/commit/59220b9))



<a name="2.2.3"></a>
## <small>2.2.3 (2018-09-10)</small>

* chore: release 2.2.3 ([af653a3](https://github.com/vkarpov15/kareem/commit/af653a3))



<a name="2.2.2"></a>
## <small>2.2.2 (2018-09-10)</small>

* chore: release 2.2.2 ([3f0144d](https://github.com/vkarpov15/kareem/commit/3f0144d))
* fix: allow merge() to not clone ([e628d65](https://github.com/vkarpov15/kareem/commit/e628d65))



<a name="2.2.1"></a>
## <small>2.2.1 (2018-06-05)</small>

* chore: release 2.2.1 ([4625a64](https://github.com/vkarpov15/kareem/commit/4625a64))
* chore: remove lockfile from git ([7f3e4e6](https://github.com/vkarpov15/kareem/commit/7f3e4e6))
* fix: handle numAsync correctly when merging ([fef8e7e](https://github.com/vkarpov15/kareem/commit/fef8e7e))
* test: repro issue with not copying numAsync ([952d9db](https://github.com/vkarpov15/kareem/commit/952d9db))



<a name="2.2.0"></a>
## 2.2.0 (2018-06-05)

* chore: release 2.2.0 ([ff9ad03](https://github.com/vkarpov15/kareem/commit/ff9ad03))
* fix: use maps instead of objects for _pres and _posts so `toString()` doesn't get reported as having ([55df303](https://github.com/vkarpov15/kareem/commit/55df303)), closes [Automattic/mongoose#6538](https://github.com/Automattic/mongoose/issues/6538)



<a name="2.1.0"></a>
## 2.1.0 (2018-05-16)

* chore: release 2.1.0 ([ba5f1bc](https://github.com/vkarpov15/kareem/commit/ba5f1bc))
* feat: add option to check wrapped function return value for promises ([c9d7dd1](https://github.com/vkarpov15/kareem/commit/c9d7dd1))
* refactor: use const in wrap() ([0fc21f9](https://github.com/vkarpov15/kareem/commit/0fc21f9))



<a name="2.0.7"></a>
## <small>2.0.7 (2018-04-28)</small>

* chore: release 2.0.7 ([0bf91e6](https://github.com/vkarpov15/kareem/commit/0bf91e6))
* feat: add `hasHooks()` ([225f18d](https://github.com/vkarpov15/kareem/commit/225f18d)), closes [Automattic/mongoose#6385](https://github.com/Automattic/mongoose/issues/6385)



<a name="2.0.6"></a>
## <small>2.0.6 (2018-03-22)</small>

* chore: release 2.0.6 ([f3d406b](https://github.com/vkarpov15/kareem/commit/f3d406b))
* fix(wrap): ensure fast path still wraps function in `nextTick()` for chaining ([7000494](https://github.com/vkarpov15/kareem/commit/7000494)), closes [Automattic/mongoose#6250](https://github.com/Automattic/mongoose/issues/6250) [dsanel/mongoose-delete#36](https://github.com/dsanel/mongoose-delete/issues/36)



<a name="2.0.5"></a>
## <small>2.0.5 (2018-02-22)</small>

* chore: release 2.0.5 ([3286612](https://github.com/vkarpov15/kareem/commit/3286612))
* perf(createWrapper): don't create wrapper if there are no hooks ([5afc5b9](https://github.com/vkarpov15/kareem/commit/5afc5b9)), closes [Automattic/mongoose#6126](https://github.com/Automattic/mongoose/issues/6126)



<a name="2.0.4"></a>
## <small>2.0.4 (2018-02-08)</small>

* chore: release 2.0.4 ([2ab0293](https://github.com/vkarpov15/kareem/commit/2ab0293))



<a name="2.0.3"></a>
## <small>2.0.3 (2018-02-01)</small>

* chore: release 2.0.3 ([3c1abe5](https://github.com/vkarpov15/kareem/commit/3c1abe5))
* fix: use process.nextTick() re: Automattic/mongoose#6074 ([e5bfe33](https://github.com/vkarpov15/kareem/commit/e5bfe33)), closes [Automattic/mongoose#6074](https://github.com/Automattic/mongoose/issues/6074)



<a name="2.0.2"></a>
## <small>2.0.2 (2018-01-24)</small>

* chore: fix license ([a9d755c](https://github.com/vkarpov15/kareem/commit/a9d755c)), closes [#10](https://github.com/vkarpov15/kareem/issues/10)
* chore: release 2.0.2 ([fe87ab6](https://github.com/vkarpov15/kareem/commit/fe87ab6))



<a name="2.0.1"></a>
## <small>2.0.1 (2018-01-09)</small>

* chore: release 2.0.1 with lockfile bump ([09c44fb](https://github.com/vkarpov15/kareem/commit/09c44fb))



<a name="2.0.0"></a>
## 2.0.0 (2018-01-09)

* chore: bump marked re: security ([cc564a9](https://github.com/vkarpov15/kareem/commit/cc564a9))
* chore: release 2.0.0 ([f511d1c](https://github.com/vkarpov15/kareem/commit/f511d1c))



<a name="2.0.0-rc5"></a>
## 2.0.0-rc5 (2017-12-23)

* chore: fix build on node 4+5 ([6dac5a4](https://github.com/vkarpov15/kareem/commit/6dac5a4))
* chore: fix built on node 4 + 5 again ([434ef0a](https://github.com/vkarpov15/kareem/commit/434ef0a))
* chore: release 2.0.0-rc5 ([25a32ee](https://github.com/vkarpov15/kareem/commit/25a32ee))



<a name="2.0.0-rc4"></a>
## 2.0.0-rc4 (2017-12-22)

* chore: release 2.0.0-rc4 ([49fc083](https://github.com/vkarpov15/kareem/commit/49fc083))
* BREAKING CHANGE: deduplicate when merging hooks re: Automattic/mongoose#2945 ([d458573](https://github.com/vkarpov15/kareem/commit/d458573)), closes [Automattic/mongoose#2945](https://github.com/Automattic/mongoose/issues/2945)



<a name="2.0.0-rc3"></a>
## 2.0.0-rc3 (2017-12-22)

* chore: release 2.0.0-rc3 ([adaaa00](https://github.com/vkarpov15/kareem/commit/adaaa00))
* feat: support returning promises from middleware functions ([05b4480](https://github.com/vkarpov15/kareem/commit/05b4480)), closes [Automattic/mongoose#3779](https://github.com/Automattic/mongoose/issues/3779)



<a name="2.0.0-rc2"></a>
## 2.0.0-rc2 (2017-12-21)

* chore: release 2.0.0-rc2 ([76325fa](https://github.com/vkarpov15/kareem/commit/76325fa))
* fix: ensure next() and done() run in next tick ([6c20684](https://github.com/vkarpov15/kareem/commit/6c20684))



<a name="2.0.0-rc1"></a>
## 2.0.0-rc1 (2017-12-21)

* chore: improve test coverage re: Automattic/mongoose#3232 ([7b45cf0](https://github.com/vkarpov15/kareem/commit/7b45cf0)), closes [Automattic/mongoose#3232](https://github.com/Automattic/mongoose/issues/3232)
* chore: release 2.0.0-rc1 ([9b83f52](https://github.com/vkarpov15/kareem/commit/9b83f52))
* BREAKING CHANGE: report sync exceptions as errors, only allow calling next() and done() once ([674adcc](https://github.com/vkarpov15/kareem/commit/674adcc)), closes [Automattic/mongoose#3483](https://github.com/Automattic/mongoose/issues/3483)



<a name="2.0.0-rc0"></a>
## 2.0.0-rc0 (2017-12-17)

* chore: release 2.0.0-rc0 ([16b44b5](https://github.com/vkarpov15/kareem/commit/16b44b5))
* BREAKING CHANGE: drop support for node < 4 ([9cbb8c7](https://github.com/vkarpov15/kareem/commit/9cbb8c7))
* BREAKING CHANGE: remove useLegacyPost and add several new features ([6dd8531](https://github.com/vkarpov15/kareem/commit/6dd8531)), closes [Automattic/mongoose#3232](https://github.com/Automattic/mongoose/issues/3232)



<a name="1.5.0"></a>
## 1.5.0 (2017-07-20)

* chore: release 1.5.0 ([9c491a0](https://github.com/vkarpov15/kareem/commit/9c491a0))
* fix: improve post error handlers results ([9928dd5](https://github.com/vkarpov15/kareem/commit/9928dd5)), closes [Automattic/mongoose#5466](https://github.com/Automattic/mongoose/issues/5466)



<a name="1.4.2"></a>
## <small>1.4.2 (2017-07-06)</small>

* chore: release 1.4.2 ([8d14ac5](https://github.com/vkarpov15/kareem/commit/8d14ac5))
* fix: correct args re: Automattic/mongoose#5405 ([3f28ae6](https://github.com/vkarpov15/kareem/commit/3f28ae6)), closes [Automattic/mongoose#5405](https://github.com/Automattic/mongoose/issues/5405)



<a name="1.4.1"></a>
## <small>1.4.1 (2017-04-25)</small>

* chore: release 1.4.1 ([5ecf0c2](https://github.com/vkarpov15/kareem/commit/5ecf0c2))
* fix: handle numAsyncPres with clone() ([c72e857](https://github.com/vkarpov15/kareem/commit/c72e857)), closes [#8](https://github.com/vkarpov15/kareem/issues/8)
* test: repro #8 ([9b4d6b2](https://github.com/vkarpov15/kareem/commit/9b4d6b2)), closes [#8](https://github.com/vkarpov15/kareem/issues/8)



<a name="1.4.0"></a>
## 1.4.0 (2017-04-19)

* chore: release 1.4.0 ([101c5f5](https://github.com/vkarpov15/kareem/commit/101c5f5))
* feat: add merge() function ([285325e](https://github.com/vkarpov15/kareem/commit/285325e))



<a name="1.3.0"></a>
## 1.3.0 (2017-03-26)

* chore: release 1.3.0 ([f3a9e50](https://github.com/vkarpov15/kareem/commit/f3a9e50))
* feat: pass function args to execPre ([4dd466d](https://github.com/vkarpov15/kareem/commit/4dd466d))



<a name="1.2.1"></a>
## <small>1.2.1 (2017-02-03)</small>

* chore: release 1.2.1 ([d97081f](https://github.com/vkarpov15/kareem/commit/d97081f))
* fix: filter out _kareemIgnored args for error handlers re: Automattic/mongoose#4925 ([ddc7aeb](https://github.com/vkarpov15/kareem/commit/ddc7aeb)), closes [Automattic/mongoose#4925](https://github.com/Automattic/mongoose/issues/4925)
* fix: make error handlers handle errors in pre hooks ([af38033](https://github.com/vkarpov15/kareem/commit/af38033)), closes [Automattic/mongoose#4927](https://github.com/Automattic/mongoose/issues/4927)



<a name="1.2.0"></a>
## 1.2.0 (2017-01-02)

* chore: release 1.2.0 ([033225c](https://github.com/vkarpov15/kareem/commit/033225c))
* chore: upgrade deps ([f9e9a09](https://github.com/vkarpov15/kareem/commit/f9e9a09))
* feat: add _kareemIgnore re: Automattic/mongoose#4836 ([7957771](https://github.com/vkarpov15/kareem/commit/7957771)), closes [Automattic/mongoose#4836](https://github.com/Automattic/mongoose/issues/4836)



<a name="1.1.5"></a>
## <small>1.1.5 (2016-12-13)</small>

* chore: release 1.1.5 ([1a9f684](https://github.com/vkarpov15/kareem/commit/1a9f684))
* fix: correct field name ([04a0e9d](https://github.com/vkarpov15/kareem/commit/04a0e9d))



<a name="1.1.4"></a>
## <small>1.1.4 (2016-12-09)</small>

* chore: release 1.1.4 ([ece401c](https://github.com/vkarpov15/kareem/commit/ece401c))
* chore: run tests on node 6 ([e0cb1cb](https://github.com/vkarpov15/kareem/commit/e0cb1cb))
* fix: only copy own properties in clone() ([dfe28ce](https://github.com/vkarpov15/kareem/commit/dfe28ce)), closes [#7](https://github.com/vkarpov15/kareem/issues/7)



<a name="1.1.3"></a>
## <small>1.1.3 (2016-06-27)</small>

* chore: release 1.1.3 ([87171c8](https://github.com/vkarpov15/kareem/commit/87171c8))
* fix: couple more issues with arg processing ([c65f523](https://github.com/vkarpov15/kareem/commit/c65f523))



<a name="1.1.2"></a>
## <small>1.1.2 (2016-06-27)</small>

* chore: release 1.1.2 ([8e102b6](https://github.com/vkarpov15/kareem/commit/8e102b6))
* fix: add early return ([4feda4e](https://github.com/vkarpov15/kareem/commit/4feda4e))



<a name="1.1.1"></a>
## <small>1.1.1 (2016-06-27)</small>

* chore: release 1.1.1 ([8bb3050](https://github.com/vkarpov15/kareem/commit/8bb3050))
* fix: skip error handlers if no error ([0eb3a44](https://github.com/vkarpov15/kareem/commit/0eb3a44))



<a name="1.1.0"></a>
## 1.1.0 (2016-05-11)

* chore: release 1.1.0 ([85332d9](https://github.com/vkarpov15/kareem/commit/85332d9))
* chore: test on node 4 and node 5 ([1faefa1](https://github.com/vkarpov15/kareem/commit/1faefa1))
* 100% coverage again ([c9aee4e](https://github.com/vkarpov15/kareem/commit/c9aee4e))
* add support for error post hooks ([d378113](https://github.com/vkarpov15/kareem/commit/d378113))
* basic setup for sync hooks #4 ([55aa081](https://github.com/vkarpov15/kareem/commit/55aa081)), closes [#4](https://github.com/vkarpov15/kareem/issues/4)
* proof of concept for error handlers ([e4a07d9](https://github.com/vkarpov15/kareem/commit/e4a07d9))
* refactor out handleWrapError helper ([b19af38](https://github.com/vkarpov15/kareem/commit/b19af38))



<a name="1.0.1"></a>
## <small>1.0.1 (2015-05-10)</small>

* Fix #1 ([de60dc6](https://github.com/vkarpov15/kareem/commit/de60dc6)), closes [#1](https://github.com/vkarpov15/kareem/issues/1)
* release 1.0.1 ([6971088](https://github.com/vkarpov15/kareem/commit/6971088))
* Run tests on iojs in travis ([adcd201](https://github.com/vkarpov15/kareem/commit/adcd201))
* support legacy post hook behavior in wrap() ([23fa74c](https://github.com/vkarpov15/kareem/commit/23fa74c))
* Use node 0.12 in travis ([834689d](https://github.com/vkarpov15/kareem/commit/834689d))



<a name="1.0.0"></a>
## 1.0.0 (2015-01-28)

* Tag 1.0.0 ([4c5a35a](https://github.com/vkarpov15/kareem/commit/4c5a35a))



<a name="0.0.8"></a>
## <small>0.0.8 (2015-01-27)</small>

* Add clone function ([688bba7](https://github.com/vkarpov15/kareem/commit/688bba7))
* Add jscs for style checking ([5c93149](https://github.com/vkarpov15/kareem/commit/5c93149))
* Bump 0.0.8 ([03c0d2f](https://github.com/vkarpov15/kareem/commit/03c0d2f))
* Fix jscs config, add gulp rules ([9989abf](https://github.com/vkarpov15/kareem/commit/9989abf))
* fix Makefile typo ([1f7e61a](https://github.com/vkarpov15/kareem/commit/1f7e61a))



<a name="0.0.7"></a>
## <small>0.0.7 (2015-01-04)</small>

* Bump 0.0.7 ([98ef173](https://github.com/vkarpov15/kareem/commit/98ef173))
* fix LearnBoost/mongoose#2553 - use null instead of undefined for err ([9157b48](https://github.com/vkarpov15/kareem/commit/9157b48)), closes [LearnBoost/mongoose#2553](https://github.com/LearnBoost/mongoose/issues/2553)
* Regenerate docs ([2331cdf](https://github.com/vkarpov15/kareem/commit/2331cdf))



<a name="0.0.6"></a>
## <small>0.0.6 (2015-01-01)</small>

* Update docs and bump 0.0.6 ([92c12a7](https://github.com/vkarpov15/kareem/commit/92c12a7))



<a name="0.0.5"></a>
## <small>0.0.5 (2015-01-01)</small>

* Add coverage rule to Makefile ([825a91c](https://github.com/vkarpov15/kareem/commit/825a91c))
* Add coveralls to README ([fb52369](https://github.com/vkarpov15/kareem/commit/fb52369))
* Add coveralls to travis ([93f6f15](https://github.com/vkarpov15/kareem/commit/93f6f15))
* Add createWrapper() function ([ea77741](https://github.com/vkarpov15/kareem/commit/ea77741))
* Add istanbul code coverage ([6eceeef](https://github.com/vkarpov15/kareem/commit/6eceeef))
* Add some more comments for examples ([c5b0c6f](https://github.com/vkarpov15/kareem/commit/c5b0c6f))
* Add travis ([e6dcb06](https://github.com/vkarpov15/kareem/commit/e6dcb06))
* Add travis badge to docs ([ad8c9b3](https://github.com/vkarpov15/kareem/commit/ad8c9b3))
* Add wrap() tests, 100% coverage ([6945be4](https://github.com/vkarpov15/kareem/commit/6945be4))
* Better test coverage for execPost ([d9ad539](https://github.com/vkarpov15/kareem/commit/d9ad539))
* Bump 0.0.5 ([69875b1](https://github.com/vkarpov15/kareem/commit/69875b1))
* Docs fix ([15b7098](https://github.com/vkarpov15/kareem/commit/15b7098))
* Fix silly mistake in docs generation ([50373eb](https://github.com/vkarpov15/kareem/commit/50373eb))
* Fix typo in readme ([fec4925](https://github.com/vkarpov15/kareem/commit/fec4925))
* Linkify travis badge ([92b25fe](https://github.com/vkarpov15/kareem/commit/92b25fe))
* Make travis run coverage ([747157b](https://github.com/vkarpov15/kareem/commit/747157b))
* Move travis status badge ([d52e89b](https://github.com/vkarpov15/kareem/commit/d52e89b))
* Quick fix for coverage ([50bbddb](https://github.com/vkarpov15/kareem/commit/50bbddb))
* Typo fix ([adea794](https://github.com/vkarpov15/kareem/commit/adea794))



<a name="0.0.4"></a>
## <small>0.0.4 (2014-12-13)</small>

* Bump 0.0.4, run docs generation ([51a15fe](https://github.com/vkarpov15/kareem/commit/51a15fe))
* Use correct post parameters in wrap() ([9bb5da3](https://github.com/vkarpov15/kareem/commit/9bb5da3))



<a name="0.0.3"></a>
## <small>0.0.3 (2014-12-12)</small>

* Add npm test script, fix small bug with args not getting passed through post ([49e3e68](https://github.com/vkarpov15/kareem/commit/49e3e68))
* Bump 0.0.3 ([65621d8](https://github.com/vkarpov15/kareem/commit/65621d8))
* Update readme ([901388b](https://github.com/vkarpov15/kareem/commit/901388b))



<a name="0.0.2"></a>
## <small>0.0.2 (2014-12-12)</small>

* Add github repo and bump 0.0.2 ([59db8be](https://github.com/vkarpov15/kareem/commit/59db8be))



<a name="0.0.1"></a>
## <small>0.0.1 (2014-12-12)</small>

* Add basic docs ([ad29ea4](https://github.com/vkarpov15/kareem/commit/ad29ea4))
* Add pre hooks ([2ffc356](https://github.com/vkarpov15/kareem/commit/2ffc356))
* Add wrap function ([68c540c](https://github.com/vkarpov15/kareem/commit/68c540c))
* Bump to version 0.0.1 ([a4bfd68](https://github.com/vkarpov15/kareem/commit/a4bfd68))
* Initial commit ([4002458](https://github.com/vkarpov15/kareem/commit/4002458))
* Initial deposit ([98fc489](https://github.com/vkarpov15/kareem/commit/98fc489))
* Post hooks ([395b67c](https://github.com/vkarpov15/kareem/commit/395b67c))
* Some basic setup work ([82df75e](https://github.com/vkarpov15/kareem/commit/82df75e))
* Support sync pre hooks ([1cc1b9f](https://github.com/vkarpov15/kareem/commit/1cc1b9f))
* Update package.json description ([978da18](https://github.com/vkarpov15/kareem/commit/978da18))
