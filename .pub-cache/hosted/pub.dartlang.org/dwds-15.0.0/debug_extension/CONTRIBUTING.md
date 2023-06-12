## Building

- With dart2js:

```
dart run build_runner build web -o build -r
```

This will build to the `/web` directory.

- With DDC:

```
dart run build_runner build web -o build
```

This will build to the `/build/web` directory. 
## Local Development

### Update `manifest.json`:

* Change the `default_icon` in `manifest.json` to `dart_dev.png` (Note: this is not strictly necessary, but will help you to distinguish your local version of the extension from the published version)
* [For Googlers] The developer key is needed for local development and testing. Add one of the whitelisted keys to `web/manifest.json`. IMPORTANT: DO NOT COMMIT THE KEY.

```
{
    "name": "Dart Debug Extension",
    "key": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    ...
}
```

### Build and upload your local extension

* Build the extension following the instructions above
* Visit chrome://extensions
* Toggle "Developer mode" on
* Click the "Load unpacked" button
* Select the extension directory: `/dwds/debug_extension/web`

### Debug your local extension
* Click the Extensions puzzle piece, and pin the Dart Debug Extension with the dev icon (unpin the published version so you don't confuse them)
* You can now use the extension normally by clicking it when a local Dart web application has loaded in a Chrome tab
* To debug, visit chrome://extensions and click "Inspect view on background page" to open Chrome DevTools for the extension 
* More debugging information can be found in the [Chrome Developers documentation](https://developer.chrome.com/docs/extensions/mv3/devguide/)


## Release process

1. Update the version in `web/manifest.json`, `pubspec.yaml`, and in the `CHANGELOG`. 
2. Build dart2js: `pub run build_runner build web -o build -r`
> *At this point, you should manually verify that everything is working by following the steps in [Local Development](#local-development).*
3. Open a PR to submit the version and build changes.
4. Once submitted, pull the changes down to your local branch, and create a zip of the `debug_extension/web` directory (NOT `debug_extension/build/web`). 
5. Rename the zip `version_XX.XX.XX.zip` (eg, `version_1.24.0.zip`) and add it to the go/dart-debug-extension-zips folder 
> *You must be a Googler to do this. Ask for help if not.*
6. Go to the [Chrome Web Store Developer Dashboard](https://chrome.google.com/webstore/devconsole).
7. At the top-right, under Publisher, select dart-bat.
> *If you don’t see dart-bat as an option, you will need someone on the Dart team to add you to the dart-bat Google group.*
7. Under Items, select the "Dart Debug Extension".
8. Go to “Package” then select “Upload new package”.
> *The first time you do this, you will be asked to pay a $5 registration fee. The registration fee can be expensed.*
9. Upload the zip file you created in step 4.
10. Save as draft, and verify that the new version is correct.
11. Publish. The extension will be published immediately after going through the review process. 

## Rollback process 
> The Chrome Web Store Developer Dashboard does not support rollbacks. Instead you must re-publish an earlier version. This means that the extension will still have to go through the review process, which can take anywhere from a few hours (most common) to a few days.
1. Find the previous version you want to rollback to in the go/dart-debug-extension-zips folder. 
> > *You must be a Googler to do this. Ask for help if not.*
2. Unzip the version you have chosen, and in `manifest.json` edit the version number to be the next sequential version after the current "bad" version (eg, the bad version is `1.28.0` and you are rolling back to version `1.27.0`. Therefore you change `1.27.0` to `1.29.0`).
3. Re-zip the directory and rename it to the new version number. Add it to the go/dart-debug-extension-zips folder.
4. Now, follow steps 6 - 11 in [Release process](#release-process).


