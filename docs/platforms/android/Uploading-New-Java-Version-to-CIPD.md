# Uploading New Java Version to CIPD

We store the Java Version package on CIPD for use on CI. For more information read the internal
docs [here](http://go/luci-cipd).

Some links in the instructions below are Google-internal.

## Steps

### Request Access to CIPD

1. Request temporary write access to upload packages to CIPD
   via http://go/flutter-luci-cipd#requesting-write-read-access-to-cipd-packages.

2. Wait about 5-30 minutes for access rights to sync. To check if your rights have synced, see if
   you are a member of this
   group [here](https://chrome-infra-auth.appspot.com/auth/groups/google%2Fflutter-cipd-writers@twosync.google.com).

### Download the New Java Version and Set Up for CIPD Upload

3. Download the new Java version via OpenJDK (not Oracle's Java for licensing/legal
   reasons) [here](https://openjdk.org/projects/jdk/) for the following platforms:
   linux-amd64(aka x64), mac-arm64, mac-amd64, and windows-amd64.

4. Download the latest Java version from
   CIPD [here](https://chrome-infra-packages.appspot.com/p/flutter/java/openjdk) for the following
   platforms: linux-amd64(aka x64), mac-arm64, mac-amd64, and windows-amd64.

5. Unzip the new Java version and the latest version.

6. Add a file titled `openjdk.cipd.yaml` at the top-level directory. Copy the contents below into
   the file and replace contents in <> for your new Java version package:
   ```sh
    package: flutter/java/openjdk/<platform-architecture>
    description: OpenJDK <java_version> for <platform>
    install_mode: copy
    data:
    # This directory contains Java <platform-architecture> to be used in automated tests.
    - dir: .
   ```

   Note: `linux-amd64` is an example of `<platform-architecture>`

7. Ensure the file/directory structure of the new Java version package to be uploaded is the same as
   the structure at the top-level of the latest from CIPD.
   This involves potentially deleting contents of the top-level directory.

### Upload to CIPD

8. To run CIPD commands, please run this command:

    ```sh
    cipd auth-login
    ```

9. To upload the new Java version to CIPD, please run this command:

    ```sh
     cipd create -in <path_to_new_java_version_package>  -name flutter/java/openjdk/<platform-architecture> -tag version:<java_version>
    ```

   Note: Please check you have the correct name, tags, package structure before uploading to CIPD
   because deleting the package on CIPD is difficult.

10. Check to see if your new Java version has successfully uploaded to CIPD by clicking on the
    relevant platform [here](https://chrome-infra-packages.appspot.com/p/flutter/java/openjdk).

### Troubleshooting CIPD (Optional)

If you accidentally uploaded the incorrect package to CIPD, you can delete the tag using these
instructions [here](go/flutter-luci-playbook#remove-duplicated-cipd-tags).
Then, re-upload the correct Java version pacakge to CIPD.