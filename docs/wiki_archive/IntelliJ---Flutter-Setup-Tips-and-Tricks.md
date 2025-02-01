IntelliJ is a full-featured IDE; it supports refactorings, code navigation, debugging, searching, and source control integration.

The following is a subjective take on getting IntelliJ to be a bit more lightweight (and slightly speedier) editor. Your mileage may vary.

## Less Chrome

Less is more! You can hide the IntelliJ toolbar and status line. You're still left with IntelliJ's tool buttons - buttons around the exterior allowing you to toggle visibility of different views - and the navigation bar, for common run actions.

From the View menu, toggle off the Toolbar and Status Bar:

![](http://i.imgur.com/54choqz.png)

## Breadcrumbs

The breadcrumbs view shows at the top of each editor. This view adds visual noise to the UI. To disable it, open the Settings view (ctrl-alt-s) and search for 'breadcrumbs'.

![](http://i.imgur.com/Wkdskls.png)

## Line numbers

Perhaps more controversially, you can disable line numbers in the UI as well. Similarly to disabling breadcrumbs, open the Settings dialog and search for 'line numbers'.

![](http://i.imgur.com/PDa6qtZ.png)

## Code folding

Some people disable it. Whether it adds value is highly subjective; your mileage may vary. In Settings, search for 'code folding'. Uncheck all the checkboxes under 'collapse by default'.

## The structure view

Also called the outline view in other tools. If you have a Dart file open this view will show the class and method structure for the file. This can be invaluable for quickly getting a sense of the structure of a file and for knowing where you are in one.

By default this is inline with the Project view on the left side of the IDE window. This can make it difficult to see your project structure and the structure of your current library at the same time. You can drag the various views around to dock in exterior of your window. To experiment, drag the 'Structure' tab from the left side of the window and dock it on the right-hand side:

![](blob:http://imgur.com/2b8659c2-a529-400c-ba56-4008e2e84cf9)

## Synchronize views

When some people navigate around files in a project, and within the current file, they like the project view and the structure view to stay synchronized with the selection.

From the Project view, click on the gear icon, and ensure that 'Autoscroll to Source' and 'Autoscroll from Source' are checked:

![](http://i.imgur.com/LuHDNxY.png)

And from the Structure view, in the toolbar, ensure that the two icons for 'Autoscroll to Source' and 'Autoscroll from Source' are selected:

![](http://i.imgur.com/SFj4Q2l.png)

## Darcula

Obviously a critical choice when developing - after coming down on one side or the other of the tabs-vs-spaces debate - is to choose a light or dark color theme. 😛  If you prefer a dark theme, you're in good company, with [52.5%](http://stackoverflow.com/research/developer-survey-2015#tech-ide) of other developers.

To set your UI theme to Darcula open the Settings and, under Appearance & Behavior > Appearance, adjust the value of the 'Theme' chooser.

![](http://i.imgur.com/3t0PgJ2.png)

## IDE layout

Some people prefer to have their IDE views positioned so that they are able to see the Project view, the Structure view, and the Dart Analysis view (errors and warnings) at once. Some people think of this as their
[work triangle](https://en.wikipedia.org/wiki/Kitchen_work_triangle),
similar to how you optimize for frequent tasks when designing a kitchen. After some fussing, here's a typical IDE layout:

![](http://i.imgur.com/b3CFeh0.png)

## Remove unused plugins

IntelliJ (especially IntelliJ Ultimate) ships with a lot of plugins installed by default. Many of these plugins are harmless; a few may consume memory and CPU at various times. To disable plugins, open the Settings view and select the 'Plugins' category. Some people err on the side of only disabling plugins they clearly won't use.

## Community Edition vs Ultimate?

The two versions of IntelliJ are very similar. Ultimate includes plugins for web development; if web development is not an important use case for you, you can prefer to use the community edition. It has significantly fewer plugins installed than the Ultimate edition.

## Adjust the default heap

The recommended way of changing the JVM options in IntelliJ is from the Help | Edit Custom VM Options menu. This action will create a copy of the .vmoptions file in the IDE config directory and open an editor where you can change them (see also:
[configuring VM options](https://intellij-support.jetbrains.com/hc/en-us/articles/206544869-Configuring-JVM-options-and-platform-properties)).

Current default values for IntelliJ:

`-Xms128m -Xmx750m`

Increase these for fun and profit.