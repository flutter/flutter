## Testing on Emulators in the Devicelab

While the Devicelab is typically for testing on Devices we have added support so that developers can now test Android changes via the LUCI recipes on an Android Emulator.

You can specify a new test via the `.ci.yaml` file in the repository. This allows the infra framework to run the test automatically with minimal work from the developer.

### Adding a Brand New Target

Adding a new Devicelab Android Emulator test for Android feature changes requires the following steps:

Starting with the finished target yaml definition:

```yaml
- name: Linux_android android_defines_test
  recipe: devicelab/devicelab_drone
  presubmit: true
  timeout: 60
  dimensions: {
    kvm: “1”,
    cores: “8”,
    Machine_name: “n1-standard-8”
  }
  properties:
    device_type: “none”
    task_name: android_defines_test
    use_emulator: “true”
    dependencies: >-
      [
        {"dependency": "android_virtual_device", "version": "31"}
      ]
    tags: >
      ["devicelab", “linux”]
    timeout: 300
```

1. The `name` of the target consists of the platform which can be either `Linux` or `Linux_Android`. It is better to pick `Linux_Android` since it will provide you more of the needed dependencies.
2. The `recipe` is always `devicelab/devicelab_drone`. This is the recipe that will launch the emulator and drive the test.
3. `presubmit` can be `true` or `false`. To run the test in any PR that is opened you should set this to `true`. This is the best approach to catch bugs before they are mirrored to google3.
4. `timeout` is an integer value.
5. `dimensions` is needed to tell the LUCI framework that we need to run this test on a machine that supports nested virtualization and should be set as shown.
6. `properties`:

    a. `device_type` must be set to `none` so that we use a machine without an attached android phone. This will cause problems if not set.

    b. `task_name` is the name to apply to the task.

    c. `use_emulator` is the flag to tell the test recipe that we need to create an Emulator for this test.

    d. `dependencies` can be used to override the `android_virtual_device` api version.

    e. `tags` should be set to `devicelab` and `linux`

    f. `timeout` the timeout here is for the time to give the test to run before killing it.

### Updating an Existing Target

If you want to update an existing target you will only need to add the following changes:
1. add a `dimensions` field as described above.
2. Set the `device_type: "none"`.
3. Add `use_emulator: "true"` flag in properties. Note this is not a boolean but must be a string.
4. Add a dependency for the android emulator version to the properties. If there are no dependencies add it as shown above.
5. Remove any tags that specify android. These are for benchmark tests and having them in will cause some of the device checks to fail.