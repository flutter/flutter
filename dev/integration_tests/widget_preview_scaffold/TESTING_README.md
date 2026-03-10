# Widget Preview Scaffold Testing

This directory contains a hydrated instance of the `widget_preview_scaffold` project template that's used for generating the environment used by `flutter widget-preview start` to host Widget Previews, as well as utilities to detect if the hydrated instance is outdated when compared to the template files.

# Updating the Hydrated Template

If any of the `widget_preview_scaffold` template files are updated, `widget_preview_scaffold/test/template_change_detection_smoke_test.dart` will fail to indicate that the hydrated scaffold needs to be regenerated. To do this, run `dart update_widget_preview_scaffold.dart` to regenerate the project.
