This directory contains tools and resources that the Flutter team uses
during the development of the framework. The tools in this directory
should not be necessary for developing Flutter applications, though of
course, they may be interesting if you are curious.

The tests in this directory are run in the `framework_tests_misc-*`
shards.

## Luci builder file
`try_builders.json` and `prod_builders.json` contain the
supported luci try/prod builders for engine. They follow format:
```json
{
    "builders":[
        {
            "name":"xxx1",
            "repo":"flutter"
        },
        {
            "name":"xxx2",
            "repo":"flutter",
            "taskName":"yyy2"
        }
    ]
}
```
These files will be mainly used in [`flutter/cocoon`](https://github.com/flutter/cocoon)
to trigger/update flutter luci tasks.
