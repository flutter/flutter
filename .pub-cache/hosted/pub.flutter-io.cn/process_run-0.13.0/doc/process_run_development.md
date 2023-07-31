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
  process_run:
    git: https://github.com/tekartik/process_run.dart
```

### Publishing

     pub publish


Post publish

    git tag vX.Y.Z
    git push origin --tags

