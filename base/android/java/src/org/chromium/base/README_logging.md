## Logging ##

Logging used to be done using Android's [android.util.Log]
(http://developer.android.com/reference/android/util/Log.html).

A wrapper on that is now available: org.chromium.base.Log. It is designed to write logs as
belonging to logical groups going beyond single classes, and to make it easy to switch logging on
or off for individual groups.

Usage:

    private static final String TAG = "cr.YourModuleTag";
    ...
    Log.i(TAG, "Logged INFO message.");
    Log.d(TAG, "Some DEBUG info: %s", data);

Output:

    I/cr.YourModuleTag: ( 999): Logged INFO message
    D/cr.YourModuleTag: ( 999): [MyClass.java:42] Some DEBUG info: data's toString output

Here, **TAG** will be a feature or package name, "MediaRemote" or "NFC" for example. In most
cases, the class name is not needed.

**Caveat:** Property keys are limited to 23 characters. If the tag is too long, `Log#isLoggable`
throws a RuntimeException.

### Verbose and Debug logs have special handling ###

*   `Log.v` and `Log.d` Calls made using `org.chromium.base.Log` are stripped
    out of production binaries using Proguard. There is no way to get those logs
	in release builds.

*   The file name and line number will be prepended to the log message.
    For higher priority logs, those are not added for performance concerns.

*   By default, Verbose and Debug logs are not enabled, see guarding:

### Log calls are guarded: Tag groups can be enabled or disabled using ADB ###

    adb shell setprop log.tag.cr.YourModuleTag <LEVEL>

Level here is either `VERBOSE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `ASSERT`, or `SUPPRESS`
By default, the level for all tags is `INFO`.

### An exception trace is printed when the exception is the last parameter ###

As with `java.util.Log`, putting a throwable as last parameter will dump the corresponding stack
trace:

    Log.i(TAG, "An error happened: %s", e)

    I/cr.YourModuleTag: ( 999): An error happened: This is the exception's message
    I/cr.YourModuleTag: ( 999): java.lang.Exception: This is the exception's message
    I/cr.YourModuleTag: ( 999):     at foo.bar.MyClass.test(MyClass.java:42)
    I/cr.YourModuleTag: ( 999):     ...

Having the exception as last parameter doesn't prevent it from being used for string formatting.

### Logging Best Practices

#### Rule #1: Never log PII (Personal Identification Information):

This is a huge concern, because other applications can access the log and extract a lot of data
from your own by doing so. Even if JellyBean restricted this, people are going to run your
application on rooted devices and allow some apps to access it. Also anyone with USB access to the
device can use ADB to get the full logcat and get the same data right now.

If you really need to print something , print a series of Xs instead (e.g. "XXXXXX"), or print a
truncated hash of the PII instead. Truncation is required to make it harder for an attacker to
recover the full data through rainbow tables and similar methods.

Similarly, avoid dumping API keys, cookies, etc...

#### Rule #2: Do not write debug logs in production code:

The kernel log buffer is global and of limited size. Any extra debug log you add to your activity
or service makes it more difficult to diagnose problems on other parts of the system, because they
tend to push the interesting bit out of the buffer too soon. This is a recurring problem on
Android, so avoid participating into it.

Logs can be disabled using system properties. Because log messages might not be
written, the cost of creating them should also be avoided. This can be done using three
complementary ways:

-   Use string formatting instead of concatenations

        // BAD
        Log.d(TAG, "I " + preference + " writing logs.");

        // BETTER
        Log.d(TAG, "I %s writing logs.", preference);

    If logging is disabled, the function's arguments will still have to be computed and provided
    as input. The first call above will always lead to the creation of a `StringBuilder` and a few
    concatenations, while the second just passes the arguments and won't need that.

-   Guard expensive calls

    Sometimes the values to log aren't readily available and need to be computed specially. This
    should be avoided when logging is disabled.

    Using `Log#isLoggable` will return whether logging for a specific tag is allowed or not. It is
    the call used inside the log functions and using allows to know when running the expensive
    functions is needed.

        if (Log.isLoggable(TAG, Log.DEBUG) {
          Log.d(TAG, "Something happened: %s", dumpDom(tab));
        }

    For more info, See the [android framework documentation]
    (http://developer.android.com/tools/debugging/debugging-log.html).

    Using a debug constant is a less flexible, but more perfomance oriented alternative.

        static private final boolean DEBUG = false;  // set to 'true' to enable debug
        ...
        if (DEBUG) {
          Log.i(TAG, createThatExpensiveLogMessage(activity))
        }

    Because the variable is a `static final` that can be evaluated at compile time, the Java
    compiler will optimize out all guarded calls from the generated `.class` file. Changing it
    however requires editing each of the files for which debug should be enabled and recompiling,
    while the previous method can enable or disable debugging for a whole feature without changing
    any source file.

-   Annotate debug functions with the `@RemovableInRelease` annotation.

    That annotation tells Proguard to assume that a given function has no side effects, and is
    called only for its returned value. If this value is unused, the call will be removed. If the
    function is not called at all, it will also be removed. Since Proguard is already used to
    strip debug and verbose calls out of release builds, this annotation allows it to have a
    deeper action by removing also function calls used to generate the log call's arguments.
  
        /* If that function is only used in Log.d calls, proguard should completely remove it from
         * the release builds. */
        @RemovableInRelease
        private static String getSomeDebugLogString(Thing[] things) {
          /* Still needs to be guarded to avoid impacting debug builds, or in case it's used for
           * some other log levels. But at least it is done only once, inside the function. */
          if (!Log.isLoggable(TAG, Log.DEBUG)) return null;

          StringBuilder sb = new StringBuilder("Reporting " + thing.length + " things:");
          for (Thing thing : things) {
            sb.append('\n').append(thing.id).append(' ').append(report.foo);
          }
          return sb.toString();
        }

        public void bar() {
          ...
          Log.d(TAG, getSomeDebugLogString(things)); /* In debug builds, the function does nothing
                                                      * is debug is disabled, and the entire line 
                                                      * is removed in release builds. */
        }

    Again, this is useful only if the input to that function are variables already available in
    the scope. The idea is to move computations, concatenations, etc. to a place where that can be
    removed when not needed, without invading the main function's logic.

#### Rule #3: Favor small log messages

This is still related to the global fixed-sized kernel buffer used to keep all logs. Try to make
your log information as terse as possible. This reduces the risk of pushing interesting log data
out of the buffer when something really nasty happens. It's really better to have a single-line
log message, than several ones. I.e. don't use:

    Log.GROUP.d(TAG, "field1 = %s", value1);
    Log.GROUP.d(TAG, "field2 = %s", value2);
    Log.GROUP.d(TAG, "field3 = %s", value3);

Instead, write this as:

    Log.d(TAG, "field1 = %s, field2 = %s, field3 = %s", value1, value2, value3);

That doesn't seem to be much different if you count overall character counts, but each independent
log entry also implies a small, but non-trivial header, in the kernel log buffer.
And since every byte count, you can also try something even shorter, as in:

    Log.d(TAG, "fields [%s,%s,%s]", value1, value2, value3);
