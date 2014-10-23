Hacking on Sky
==============

Running applications
--------------------

* ``./sky/tools/skydb --debug``
  * You should see a ``(skydb)`` prompt
  * Type ``help`` to see the list of available commands
  * The most common command is to load a URL, which youc an do simply by typing
    the URL.  To reload the current page, type enter.

* ``./sky/tools/test_sky --debug``
  * This should run the tests

Running tests manually
----------------------------

 * ``sky/tools/run_sky_httpd``
 * ``out/Debug/mojo_shell --args-for="mojo://native_viewport_service/ --use-headless-config" --content-handlers=text/html,mojo://sky_viewer/ --url-mappings=mojo:window_manager=mojo:sky_tester mojo:window_manager``
 * The ``sky_tester`` should print ``#READY`` when ready
 * Type the URL you wish to run, for example ``http://127.0.0.1:8000/lowlevel/text.html``, and press the enter key
 * The harness should print the results of the test.  You can then type another URL.

Writing tests
-------------

* Import ``tests/http/tests/resources/mocha.html``
* Write tests in [mocha format](http://visionmedia.github.io/mocha/#getting-started) and use [chai asserts](http://chaijs.com/api/assert/):
```
describe('My pretty test of my subject', function() {
  var subject = new MySubject();

  it('should be pretty', function() {
    assert.ok(subject.isPretty);
  });

});
```
