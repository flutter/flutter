# Uploading New Gradle Version for CI to CIPD

We store multiple Gradle version packages on CIPD for use on CI. For more information read the internal
docs [here](https://goto.google.com/luci-cipd).

Some links in the instructions below are Google-internal.

## Steps

### Request Access to CIPD

1. Request temporary write access to upload packages to CIPD
   via https://goto.google.com/flutter-luci-cipd#requesting-write-read-access-to-cipd-packages.

2. Wait about 5-30 minutes for access rights to sync. To check if your rights have synced, see if
   you are a member of this
   group [here](https://chrome-infra-auth.appspot.com/auth/groups/google%2Fflutter-cipd-writers@twosync.google.com).

### Identify the New Gradle Version 

3. Identify the new Gradle Version to include in the upload script. From the dev folder run: 
   ```sh
   git grep "distributionUrl" {} + | sed -E 's/.*\/gradle-([0-9.]+[^.]*)\.zip.*/\1/'
   ```
   For REPLACEME versions check the ModuleTest versions
   [here](https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/build_android_host_app_with_module_aar.dart#L449-L456).

4. Update the versions array with these new versions in the generate_gradle_cipd_packages.dart script. Gradle distributions in the dev folder should only use the 'bin' distribution type.

### Upload to CIPD

5. To run CIPD commands, please run this command:

    ```sh
    cipd auth-login
    ```

6. Dry run the generate_gradle_cipd_packages.dart script from the root of
   the flutter checkout:

    ```sh
    dart run
    engine/src/flutter/tools/gradle/generate_gradle_cipd_packages.dart
    --dry-run
    ```

7. Ensure everything looks correct fo the dry run.

   Note: Please check you have the correct name, tags, package structure before uploading to CIPD
   because deleting the package on CIPD is difficult.

8. Run without `--dry-run`

9. Check to see if your new Gradle version has successfully uploaded to CIPD by clicking on the
   relevant dir [here](https://chrome-infra-packages.appspot.com/p/flutter/gradle_dists).

### Troubleshooting CIPD (Optional)

If you accidentally uploaded the incorrect package to CIPD, you can delete the tag using these
instructions [here](https://goto.google.com/flutter-luci-playbook#remove-duplicated-cipd-tags).
Then, re-upload the correct Gradle version package to CIPD.
