# Updating the Embedding Dependencies

## Requirements

1. Gradle. If you don't have Gradle installed, you can get it on [https://gradle.org/install/#manually](https://gradle.org/install/#manually).
2. [Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up).

## Steps

To update the embedding dependencies, just `cd` into this directory,
modify the dependencies in `build.gradle` and run `gradle updateDependencies`.

Once you have updated the dependencies, you can upload a new version by running
`cipd create --pkg-def cipd.yaml`. For more, see the Chromium instructions on ["Updating a CIPD
dependency"](https://chromium.googlesource.com/chromium/src/+/master/docs/cipd.md#Updating-a-CIPD-dependency) for how to upload a package update to CIPD.

On successful upload, you will receive a hash for the upload such as

`cipd: successfully uploaded and verified flutter/android/embedding_bundle:NZvE-rL3E66nHQZb5Vyl9-1Y_1MWEX7KURgOHqX2cYcC`

Let's further annotate the new upload with the current timestamp.

    $ cipd set-tag flutter/android/embedding_bundle --version=<new_version_hash> -tag=last_updated:<timestamp>

Example of a last-updated timestamp: 2019-07-29T15:27:42-0700

You can generate the same date format with `date +%Y-%m-%dT%T%z`.

You can run `cipd describe flutter/android/embedding_bundle
--version=<new_version_hash>` to verify. You should see:

```
Package:       flutter/android/embedding_bundle
Instance ID:   <new_version_hash>
...
Tags:
 last_updated:<timestamp>
```

Then update the `DEPS` file (located at /src/flutter/DEPS) to use the new version by pointing to
your new `last_updated_at` tag.

```
  'src/third_party/android_embedding_dependencies': {
     'packages': [
       {
        'package': 'flutter/android/embedding_bundle',
        'version': 'last_updated:<timestamp>'
       }
     ],
     'condition': 'download_android_deps',
     'dep_type': 'cipd',
   },
```

You can now re-run `gclient sync` to fetch the latest package version.
