This directory contains templates for `flutter create`.

The `app_shared` subdirectory is special. It provides files for all app
templates (as opposed to plugin or module templates).
As of December 2021, there are three app templates: `app` (the counter app),
`empty` (an empty project) and `skeleton` (the more advanced list 
view/detail view app).

```plain
┌──────────────────────────────┐
│          app_shared          │
└──┬─────────┬───────────┬─────┘
   │         │           │
   │         │           │
   ▼         ▼           ▼
┌─────┐  ┌───────┐  ┌──────────┐
│ app │  │ empty │  │ skeleton │
└─────┘  └───────┘  └──────────┘
```

Thanks to `app_shared`, the templates for `app`, `empty` and `skeleton` can contain
only the files that are specific to them alone, and the rest is automatically
kept in sync.
