# Development

## Guidelines

* run tests
* no warning
* string mode / implicit-casts: false

````
# quick run before commiting

dartfmt -w .
dartanalyzer .
pub run test
````

## Browser and node test

````
pub run test -p chrome

# full test in one
pub run test -p chrome -p firefox -p vm
# Using build_runner
pub run build_runner test -- -p chrome -p firefox -p vm
````
    
## Use the git version

```
dependency_overrides:
  synchronized:
    git: https://github.com/tekartik/synchronized.dart
```

## Run perf test

    pub run test -j 1 test/perf_test_.dart 

```
2019-02-21
2.1.0
00:00 +0: BasicLock 500000 operations                                                                                                                                                                                                                                                                                                                        
 none 0:00:00.002481
await 0:00:02.301012
syncd 0:00:06.282630
00:09 +1: ReentrantLock 500000 operations                                                                                                                                                                                                                                                                                                                    
 none 0:00:00.001706
await 0:00:02.245424
syncd 0:00:13.592300
```

### Publishing

     pub publish


Post publish

    git tag vX.Y.Z
    git push origin --tags

