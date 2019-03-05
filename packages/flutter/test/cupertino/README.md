# Tests for the Cupertino package

Avoid importing the Material 'package:flutter/material.dart' in these tests as
we're trying to test the Cupertino package in standalone scenarios.

Some tests may be replicated in the Material tests when Material reuses
Cupertino components on iOS such as page transitions and text editing.
