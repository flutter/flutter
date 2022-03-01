This directory contains templates for `flutter create`.

The `*_shared` subdirectories provide files for multiple templates.

* `app_shared` for `app` and `skeleton`.
* `plugin_shared` for (method channel) `plugin` and `plugin_ffi`.

For example, there are two app templates: `app` (the counter app)
and `skeleton` (the more advanced list view/detail view app).

```plain
  ┌────────────┐
  │ app_shared │
  └──┬──────┬──┘
     │      │
     │      │
     ▼      ▼
┌─────┐    ┌──────────┐
│ app │    │ skeleton │
└─────┘    └──────────┘
```

Thanks to `app_shared`, the templates for `app` and `skeleton` can contain
only the files that are specific to them alone, and the rest is automatically
kept in sync.
