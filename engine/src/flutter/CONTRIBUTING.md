Contributing to Sky Engine
==========================

Getting the code
----------------

To get the code:

 1. Fork https://github.com/domokit/sky_engine into your own GitHub account.
 2. [Download depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools)
    and make sure it is in your path.
 3. Create a `.gclient` file in an empty directory with the following contents:

```
solutions = [
  {
    "managed": False,
    "name": "src",
    "url": "git@github.com:<your_name_here>/sky_engine.git",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
target_os = ["android"]
```

 4. `svn ls https://dart.googlecode.com/` and accept the certificate permanently.
 5. `gclient sync`
 6. `cd src`
 7. `git remote add upstream git@github.com:domokit/sky_engine.git`
 8. `./build/install-build-deps.sh`

Building the code
-----------------

 1. `./mojo/tools/mojob gn`
 2. `ninja -C out/Debug`

Contributing code
-----------------

The Sky engine repository gladly accepts contributions via GitHub pull requests.
