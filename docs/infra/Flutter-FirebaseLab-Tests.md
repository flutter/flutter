## FirebaseLab Tests

Flutter FirebaseLab tests are used to build flutter applications and to run them using different versions of emulators and physical devices.

These tests consist of two parts:

*   [Firebaselab recipe](https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/firebaselab/firebaselab.py)
*   [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml#L413) configuration file

The recipe supports three properties: **physical\_devices** to specify actual hardware connected to firebase infra to run tests, **virtual\_devices** to specify the virtual devices(avd) to use and **task\_name** for selecting the integration test to build.

physical\_device and virtual\_device are strings that take the **MODEL\_ID** format defined by firebase. Use `gcloud firebase test android models list` (assuming you have [gcloud](https://cloud.google.com/sdk/gcloud) installed) for a list of possible model id’s.

Task name is the subdirectory of [dev/integration\_tests](https://github.com/flutter/flutter/tree/main/dev/integration_tests) (e.g. android\_views, channels, etc ) that contains the integration test to build.

The following is an example of the properties format:

```json
physical_devices: >-
        [
           "--device", "model=oriole,version=33",
           "--device", "model=griffin,version=24"
        ],
virtual_device: >-
        [
          "--device", "model=Nexus5,version=21",
          "--device", "model=Nexus6P,version=27"
        ]
```

The recipe executes the following workflow:



1. Reads **physical\_devices** property and if not empty it builds an app bundle for the integration test referenced by **task\_name**.
2. Reads **virtual\_devices** property and if not empty it builds an apk for the integration test. Apks are built for virtual\_devices to prevent them from picking the wrong binary and using runtime translation.
3. Uses the `gcloud firebase` command to upload the binary and delegates the execution of the test to firebase lab.
4. The gcloud command blocks until the execution is complete
5. The recipe reads the logcat and the test succeeds if no `E/flutter` is found in the logcat file.
6. If the test fails it retries for maximum of 3 times
7. The recipe also supports [infra\_failure\_codes = (1, 15, 20)](https://firebase.google.com/docs/test-lab/ios/command-line#script-exit-codes) to prevent firebaselab infrastructure failures from closing the tree.


## Prerequisites (googlers)

This is only required for manually running the steps

*   [Install gcloud CLI](https://cloud.google.com/sdk/docs/install)
*   Request access on demand write access to `flutter-infra-staging`
*   Build the application and run the gcloud command. You can check the [firebaselab recipe](https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/firebaselab/firebaselab.py) for the details.

## Adding a Firebaselab Test

*   Step 1: Select the integration test to use from [dev/integration\_tests](https://github.com/flutter/flutter/tree/main/dev/integration_tests)
*   Step 2: Select the physical and virtual devices to run the test on. You can use `gcloud firebase test android models list` and `gcloud firebase test ios models list` to find the available devices.
*   Step 3: Write a .ci.yaml target configuration in the [flutter/flutter .ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) file providing the task\_name, virtual\_devices, physical\_devices and recipe properties.
*   Step 4: Create a PR with the new target. The presubmit checks will run basic validations on yaml format.
*   Step 5: Wait for the change to propagate.
*   Step 6: Fix any potential issues and remove `bringup: true` to validate the changes end to end in presubmit.

The following is an example of a full target: **Linux firebase_oriol33_abstract_method_smoke_test**. By convention the name should follow the format “&lt;host os> firebase\_&lt;model id>\_&lt;taskname>”

In the example below `recipe: firebaselab/firebaselab` refers to the recipe to use to run the test and should probably always be the same, `dependencies` refers to the android sdk to use for the test, in general all tests should use the same android sdk unless specifically testing something that changes across android sdk versions, `task_name` refers to the integration test to use see the definition above for where to find the code that is run, `physical_devices` `virtual_devices` are defined above.

```yaml
 - name: Linux firebase_oriol33_abstract_method_smoke_test
   # This is required for new tests to allow the
   # configuration to propagate.
   bringup: true
   recipe: firebaselab/firebaselab
   # The unit for timeout is minutes. 1 hour is enough
   # for most use cases unless the test is using a device
   # with low capacity and the queue is expected to be
   # longer than 30 minutes.
   timeout: 60
   Properties:
      # These top level dependencies are shared between firebaselab
      # tests. For the current values you can copy paste the
      # dependencies from another firebaselab target. Changing these
      # values are only necessary when upgrading to a new android sdk
      # version.
      dependencies: >-
          [
            {"dependency": "android\_sdk", "version": "version:33v6"}
          ]
      # Use for metrics collection and to be able to filter tasks**
      # in swarming.
      tags: >
        ["firebaselab"]
      task_name: abstract_method_smoke_test
      physical_devices: >-
          ["--device", "model=oriole,version=33"]
      virtual_devices: >-
          []
```