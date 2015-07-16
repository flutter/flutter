Contributing to Sky Engine
==========================

Getting the code
----------------

To get the code:

 * Fork https://github.com/domokit/sky_engine into your own GitHub account.
 * [Download depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools)
   and make sure it is in your path.
 * Create a `.gclient` file in an empty directory with the following contents:

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

 * `svn ls https://dart.googlecode.com/` and accept the certificate permanently.
 * `gclient sync`
 * `cd src`
 * `git remote add upstream git@github.com:domokit/sky_engine.git`
 * `./build/install-build-deps.sh`

Building the code
-----------------

 * `./mojo/tools/mojob gn`
 * `ninja -C out/Debug`

Contributing code
-----------------

The Sky engine repository gladly accepts contributions via GitHub pull requests:

 * `git fetch upstream`
 * `git checkout upstream/master -b name_of_your_branch`
 * Hack away
 * `git commit -a`
 * `git push origin name_of_your_branch`
 * Go to `https://github.com/<your_name_here>/sky_engine` and click the
   "Compare & pull request" button
