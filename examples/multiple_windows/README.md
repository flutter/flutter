# multiple_windows

A reference application demonstrating multi-window support for Flutter using a
rich semantics windowing API.

## Running
To run the example application, you must:

1. Be on Flutter's main release channel
2. Provide the `--enable-windowing` flag to flutter

## Satellite windows

On Windows, choose **Satellite** in the main window's **New Window** card or
**Create Satellite Window** in a regular window. Satellites can only be opened
from these regular windows, not from dialogs, popups, tooltips, or other satellites.
Native satellite windows are not yet implemented on Linux or macOS.

Each satellite displays its view and parent IDs, size, and device pixel ratio.
Use **Close** or the main window's delete action to close it. Closing its parent
also closes the satellite. The main window's edit action changes its size and
title.

The **Satellite** section in **SETTINGS** controls the initial size or
sized-to-content behavior of new satellites. The **Resizable** setting applies
to sized-to-content satellites; explicitly sized satellites are always resizable.
The shared positioning settings determine a satellite's initial placement
relative to its parent window. Afterwards, it follows its parent and can be
moved independently; changing the settings does not reposition existing satellites.
