# Change App Package Name for Flutter
Change App Package Name with single command. It makes the process very easy and fast.

## What It does?
- [x] Update AndroidManifest.xml files for release, debug & profile
- [x] Update build.gradle file
- [x] Update MainActivity file. Both java & kotlin supported.
- [x] Move MainActivity file to new package directory structure
- [x] Delete old package name directory structure.

## How to Use?

Add Change App Package Name to your `pubspec.yaml` in `dev_dependencies:` section. 
```yaml
dev_dependencies: 
  change_app_package_name: ^1.1.0
```

Not migrated to null safety yet? use old version like this
```yaml
dev_dependencies: 
  change_app_package_name: ^0.1.3
```


Update dependencies 
```
flutter pub get
```
Run this command to change the package name.

```
flutter pub run change_app_package_name:main com.new.package.name
```
Where `com.new.package.name` is the new package name that you want for your app. replace it with any name you want.

## Meta

Atiq Samtia– [@AtiqSamtia](https://twitter.com/atiqsamtia) – me@atiqsamtia.com

Distributed under the MIT license.

[https://github.com/atiqsamtia/change_app_package_name](https://github.com/atiqsamtia/change_app_package_name)

## Contributing

1. Fork it (<https://github.com/atiqsamtia/change_app_package_name/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
