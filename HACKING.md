Hacking on Sky
==============

Building
--------

* Follow the setup & build instructions for [Mojo](https://github.com/domokit/mojo)

Running applications
--------------------

* ``./sky/tools/skydb --debug [url]``
  * You should see a ``(skydb)`` prompt
  * Type ``help`` to see the list of available commands
  * Note: skydb is currently hard-coded to use ``//out/Debug``

* ``./sky/tools/test_sky --debug``
  * This runs the tests against ``//out/Debug``. If you want to run against
    ``//out/Release``, omit the ``--debug`` flag.

Running tests manually
----------------------

* ``sky/tools/run_sky_httpd``
* ``out/Debug/mojo_shell --args-for="mojo:native_viewport_service --use-headless-config" --content-handlers=text/html,mojo:sky_viewer --url-mappings=mojo:window_manager=mojo:sky_tester mojo:window_manager``
* The ``sky_tester`` should print ``#READY`` when ready
* Type the URL you wish to run, for example ``http://127.0.0.1:8000/lowlevel/text.html``, and press the enter key
* The harness should print the results of the test.  You can then type another URL.

Writing tests
-------------

* Import ``resources/mocha.html`` and ``resources/chai.html``
* Write tests in [mocha format](http://mochajs.org/#getting-started) and use [chai asserts](http://chaijs.com/api/assert/):
```html
describe('My pretty test of my subject', function() {
  var subject = new MySubject();

  it('should be pretty', function() {
    assert.ok(subject.isPretty);
  });
});
```

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
5. Put an <img> pointing to your newly uploaded png in the reference file.

Copying the file to googlestorage:
$ sha1sum ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png
db0508cdfe69e996a93464050dc383f6480f1283  ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png
$ gsutil.py cp ../out/Debug/layout-test-results/framework/flights-app-pixels-actual.png gs://mojo/sky-pngs/db0508cdfe69e996a93464050dc383f6480f1283

Long-term, we should not have these tests at all and should just
dump paint commands. In the short-term, if we find we're doing this
a lot we should obviously automate this process, e.g. test_sky could
do all of this work, including spitting out the correct reference file.
