We are excited to have you tinker on [the Impeller Scene Demo presented at Flutter Forward](https://www.youtube.com/live/zKQYGKAe5W8?feature=share&t=7048). While we spend time learning the use-cases and finalizing the API, the functionality for Impeller Scene is behind a compile-time flag. During this time, there are no guarantees around API stability.

**Compiling the Engine**

- Configure your Mac host to compile the Flutter Engine by [following the guidance in wiki](../contributing/Setting-up-the-Engine-development-environment.md).
- Ensure that you are on the [main branch of the Flutter Engine](https://github.com/flutter/engine/tree/main).
- Ensure that you are on the [main branch of the Flutter Framework](https://github.com/flutter/flutter/tree/main).
- Configure the host build: `./flutter/tools/gn --enable-impeller-3d --no-lto`
- Configure the iOS build: `./flutter/tools/gn --enable-impeller-3d --no-lto --ios`
  - Add the `--simulator  --simulator-cpu=arm64` flag to the iOS build if you are going to test on the simulator.
- Build host artifacts (this will take a while): `ninja -C out/host_debug`
- Build iOS artifacts (this will take a while): `ninja -C out/ios_debug`
  - If targeting the simulator: `ninja -C out/ios_debug_sim_arm64`
- Clone the demo repository: `git clone https://github.com/bdero/flutter-scene-example.git` and move into the directory.
- Plug in your device or open `Simulator.app`, then run `flutter devices` to note the device identifier.
- Run the demo application: `flutter run -d [device_id] --local-engine ios_debug --local-engine-host host_debug` (or `ios_debug_sim_arm64` if you are running on the Simulator).
  - On Silicon Macs, prefer `--local-engine-host host_debug_arm64` (adjusting your `ninja` command above accordingly)

We hope to continue evolving the API and have it available on the stable channel soon!
