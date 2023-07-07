## [3.0.8]

* Added tablePadding property to CalendarStyle

## [3.0.7]

* Added week numbering feature

## [3.0.6]

* Fixed issue with missing Flutter Web platform tag

## [3.0.5]

* Added a visual indicator to FormatButton
* Header buttons are now platform-aware

## [3.0.4]

* Updated dependencies
* Removed deprecated fields

## [3.0.3]

* Added semantic label to prioritizedBuilder
* Added tableBorder property to CalendarStyle
* Added cellAlignment property to CalendarStyle
* Added cellPadding property to CalendarStyle

## [3.0.2]

* Improved semantic labels for screen readers

## [3.0.1]

* Added pageAnimationEnabled property
* Added currentDay property to improve widget testability

## [3.0.0]

* Migrated to null safety
* Removed CalendarController
* Improved horizontal scrolling
* Improved widget performance
* Improved documentation
* Added date range selection
* Added multiple date selection
* Added selective CalendarBuilders
* Added firstDay and lastDay scroll boundaries
* Added shouldFillViewport property
* Added sixWeekMonthsEnforced property
* Added more options to customize calendar's behavior

## [2.3.3]

* Updated dependencies

## [2.3.2]

* Added previousPage and nextPage methods to CalendarController

## [2.3.1]

* Added chevron visibility properties to HeaderStyle
* Added cellMargin property to CalendarStyle
* Added eventDayStyle property to CalendarStyle
* Added availableCalendarFormats dynamic update
* Added optional BoxDecoration for each calendar row
* Added optional BoxDecoration for days of week row

## [2.3.0]

* Migrated to AndroidX
* Added holidays to onDaySelected callback
* Replaced deprecated overflow property with clipBehavior

## [2.2.3]

* Added onCalendarCreated callback

## [2.2.2]

* Added highlightSelected property to CalendarStyle
* Added highlightToday property to CalendarStyle

## [2.2.1]

* Added onHeaderTapped callback
* Added onHeaderLongPressed callback
* Fixed endDay issue

## [2.2.0]

* Added LongPress Gesture support
* Added option to disable days based on a predicate
* Added option to hide DaysOfWeek row
* Added header Decoration
* Added headerMargin property
* Added headerPadding property
* Added contentPadding property

## [2.1.0]

* Added dynamic events and holidays
* Added StartingDayOfWeek for every weekday
* Added support for custom weekend days
* Added dowWeekdayBuilder and dowWeekendBuilder
* Broadened intl dependency bounds
* markersMaxAmount no longer affects markersBuilder
* Fixed twoWeeks format programmatic issue
* Fixed visibleDays issue
* Fixed null dispose issue

## [2.0.2]

* Updated dependencies

## [2.0.1]

* Fixed issue with custom markers for holidays

## [2.0.0]

* Added CalendarController - TableCalendar now features complete programmatic control
* Removed redundant properties
* Updated example project
* Updated README

## [1.2.5]

* Fixed last day of month animation issue

## [1.2.4]

* Improved DateTime logic
* Event markers can now be set to overflow cell boundaries

## [1.2.3]

* Added startDay and endDay to allow users to specify available date range
* Added unavailableStyle and unavailableDayBuilder for days outside of given date range
* Added onUnavailableDaySelected callback
* Unavailable days will not display event markers

## [1.2.2]

* Fixed issue with Markers being null

## [1.2.1]

* RowHeight can now be set as a fixed value
* MaxMarkersAmount will now affect MarkersBuilder

## [1.2.0]

* Added holiday support
* Added holiday usage guide
* Improved custom markers builder
* Added rendering priority customization
* Added FormatButton behavior customization

## [1.1.4]

* Added TextBuilders for Header and DOW panel
* Improved vertical swipe behavior

## [1.1.3]

* Added title text customization with format skeleton
* Added day of the week text customization with format skeleton
* Rolled-back intl dependency

## [1.1.2]

* Added locale support
* Added locale usage guide
* Updated example project

## [1.1.1]

* Improved chevron customization

## [1.1.0]

* Added programmatic selectedDay
* Removed onFormatChanged callback - it is now integrated into onVisibleDaysChanged callback
* Improved onVisibleDaysChanged behavior 
* Fixed issue with empty Calendar row
* Changed default FormatButton texts
* Updated example project

## [1.0.2]

* FormatButton text can now be customized

## [1.0.1]

* Fixed CalendarFormat issue when not using a callback

## [1.0.0]

* Added custom Builders API
* Added DateTime truncation logic
* onDaySelected callback now contains list of events associated with that day
* Added onVisibleDaysChanged callback
* SwipeConfig can now be customized
* Days outside of current month can be shown/hidden
* Refactored code
* Updated example project

## [0.3.2]

* Added SwipeToExpand for CalendarFormat
* AvailableGestures can now be specified (none, horizontalSwipe, verticalSwipe, all)
* Fixed styling issue with SelectedDay on weekends

## [0.3.1]

* Added slide animation for CalendarFormat
* CalendarFormat animation can now be specified (slide, scale)
* Added Monday-Sunday week format
* Week format can now be specified with StartingDayOfWeek enum

## [0.3.0]

* Any style can now be customized
* Grouped properties into Classes
* Refactored code for better readability
* Added full documentation

## [0.2.2]

* Added optional initial Date (defaults to DateTime.now())

## [0.2.1]

* Added animated Swipe gesture
* CalendarFormat can now be enforced programmatically

## [0.2.0]

* Added animations to CalendarFormat change
* Added animations to Date selection
* Added new CalendarFormat - TwoWeeks
* Available CalendarFormats can now be specified

## [0.1.4]

* Refactored code
* Updated example project

## [0.1.3]

* Added chevron button customization
* Calendar header can be hidden now

## [0.1.2]

* Added OnFormatChanged callback

## [0.1.1]

* Added CalendarFormat button customization

## [0.1.0]

* Added CalendarFormat button - toggle between month view and week view
* Additional customization is now available

## [0.0.2]

* Revamped example
* Improved description

## [0.0.1] - Initial release

* Fully working TableCalendar; example included
