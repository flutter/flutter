This directory contains resources that the Flutter team uses during 
the development of engine.

## Luci builder file
`try_builders.json` and `prod_builders.json` contains the 
supported luci try/prod builders for engine. It follows format:
```json
{
    "builders":[
        {
            "name":"yyy",
            "repo":"engine",
            "enabled":true
        }
    ]
}
```
for `try_builders.json`, and follows format:
```json
{
    "builders":[
        {
            "name":"yyy",
            "repo":"engine"
        }
    ]
}
```
for `prod_builders.json`. `try_builders.json` will be mainly used in 
[`flutter/cocoon`](https://github.com/flutter/cocoon) to trigger/update pre-submit
engine luci tasks, whereas `prod_builders.json` will be mainly used in `flutter/cocoon`
to push luci task statuses to GitHub.