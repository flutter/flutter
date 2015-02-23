Hacking on Sky
==============

Building
--------

* Follow the setup & build instructions for [Mojo](https://github.com/domokit/mojo)

Running applications
--------------------

* ``./sky/tools/skydb start out/Debug [url]``

    `skydb` has numerous commands, visible via `skydb help`.  Common ones include:
    * `skybd start` BUILD_DIR [url]
    * `skydb load` [url]
    * `skydb stop`
    * `skydb start_tracing` # Starts recoding a performance trace (use stop_tracing to stop)
    * `skydb print_crash` # Symbolicate the most recent crash from android.

Once `skydb start` is issued, all subsequent commands will be sent to
the running mojo_shell instance (even on an attached android device).
`skydb start` reads gn args from the passed build directory to
determine whether its using android, for example.

* ``./sky/tools/test_sky --debug``
  * This runs the tests against ``//out/Debug``. If you want to run against
    ``//out/Release``, omit the ``--debug`` flag.

Running tests manually
----------------------

* ``out/downloads/sky_server -t Debug . 8000`` (If you don't have ``sky_server`` yet, run ``sky/tools/download_sky_server``.)
* ``out/Debug/mojo_shell --args-for="mojo:native_viewport_service --use-headless-config --use-osmesa" --args-for"=mojo:sky_viewer --testing" --content-handlers=text/sky,mojo:sky_viewer --url-mappings=mojo:window_manager=mojo:sky_tester,mojo:surfaces_service=mojo:fake_surfaces_service mojo:window_manager``
* The ``sky_tester`` should print ``#READY`` when ready
* Type the URL you wish to run, for example ``http://127.0.0.1:8000/sky/tests/lowlevel/text.html``, and press the enter key
* The harness should print the results of the test.  You can then type another URL.

Writing tests
-------------

* We recommend using the ``unittest.dart`` testing framework.
* See ``sky/tests/lowlevel/attribute-collection.sky`` for an example.

Adding pixel tests
------------------

Sky does not have proper pixel tests. Instead we have only reftests.
If you want a pixel test, you need to dump the png from a reftest,
upload it to googlestorage and then put and <img> pointing to the
uploaded file in the reference.

1. Create your test (e.g. foo.sky).
2. Create an dummy reference file (foo-expected.sky).
3. Run the test (it will fail).
4. Copy the -actual.png file to googlestorage (see below).
5. Put an ``<img>`` pointing to your newly uploaded png in the reference file at
http://storage.googleapis.com/mojo/sky-pngs/SHA1_HASH_HERE

Copying the file to googlestorage:
```bash
$ sha1sum ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png
db0508cdfe69e996a93464050dc383f6480f1283  ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png
$ gsutil.py cp ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png gs://mojo/sky-pngs/db0508cdfe69e996a93464050dc383f6480f1283
```

Long-term, we should not have these tests at all and should just
dump paint commands. In the short-term, if we find we're doing this
a lot we should obviously automate this process, e.g. test_sky could
do all of this work, including spitting out the correct reference file.
