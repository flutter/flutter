# CppWinRT CIPD package

CppWinRT is a tool that generates standard C++17 header-file libraries
for Windows Runtime (WinRT) APIs. These instructions describe how to
update the CIPD package that bundles these tools for Flutter builds.

A more detailed introduction to C++/WinRT can be found in the Microsoft
[documentation](https://docs.microsoft.com/en-us/windows/uwp/cpp-and-winrt-apis/).

The source code is available under an MIT license, from
https://github.com/microsoft/cppwinrt.


## Requirements

Updating this package requires the following dependencies:

1. [Depot tools](http://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up).


## Uploading a new CIPD package version

To update the CIPD package, follow these steps:

1. From the [CppWinRT package](https://www.nuget.org/packages/Microsoft.Windows.CppWinRT/)
   page on nuget, click the _Download package_ link.
2. Copy the downloaded `.nupkg` file into this directory.
3. Unzip the archive to a new subdirectory named `tmp`:
   ```
   unzip microsoft.windows.cppwinrt.<version_number>.nupkg -d tmp
   ```
4. Create the CIPD package:
   ```
   cipd create --pkg-def cppwinrt-win-amd64.cipd.yaml
   ```
   The tool should output that the package was successfully uploaded and
   verified, including the package path and an identifier SHA.
5. Set a new `build:` tag:
   ```
   cipd set-tag flutter/cppwinrt/win-amd64 --version=<new_version_sha> --tag=build:<upstream_version>
   ```
6. Verify the package was successfully created and tagged:
   ```
   cipd describe flutter/cppwinrt/win-amd64 -version <new_version_sha>
   ```
7. Delete the archive and temp directory:
   ```
   rm -rf cppwinrt *.nupkg
   ```


## Updating the Flutter DEPS file

Finally, we'll update the DEPS file to point to the latest version.

1. Open the `DEPS` file in an editor.
2. Locate the block covering `cppwinrt`.
3. Update the `version` value to the version you just tagged.

The block should look like this:
```
  'src/third_party/cppwinrt': {
     'packages': [
       {
        'package': 'flutter/cppwinrt/win-amd64',
        'version': 'build:<upstream_version>'
       }
     ],
     'condition': 'download_windows_deps',
     'dep_type': 'cipd',
   },
```

Finally, re-run `gclient sync` to verify the package downloads
correctly.


## References

* [CIPD for chromium dependencies](https://chromium.googlesource.com/chromium/src/+/67.0.3396.74/docs/cipd.md)
