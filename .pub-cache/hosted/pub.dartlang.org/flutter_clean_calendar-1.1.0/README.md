# flutter_clean_calendar

Simple flutter calendar based on flutter_calendar package.
Thanks to @AppleEducate for his contributions.
You can pull up and down the calendar to show between weekly/monthly calendar.
It shows the number of events for thats specific date.
It shows the already Done events in other color

### Breaking Changes
* Introduction of 'CleanCalendarEvent' class. This makes the former syntax of the 'Map' that stores the events incompatible.

![Screenshot](https://github.com/pmcarlos/flutter_clean_Calendar/blob/master/screenshot.png)
![Screenshot](https://github.com/pmcarlos/flutter_clean_Calendar/blob/master/calendar.gif)

## Usage

Embed the 'Calendar' widget in a column. Below the calendar (as the second widget in the Column) place a 'ListView.builder' widget for rendereing the list of events.

```dart
Column(
  mainAxisSize: MainAxisSize.max,
  children: <Widget>[
    Container(
      child: Calendar(
        startOnMonday: true,
        weekDays: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
        events: _events,
        onRangeSelected: (range) =>
            print('Range is ${range.from}, ${range.to}'),
        onDateSelected: (date) => _handleNewDate(date),
        isExpandable: true,
        eventDoneColor: Colors.green,
        selectedColor: Colors.pink,
        todayColor: Colors.blue,
        eventColor: Colors.grey,
        locale: 'de_DE',
        todayButtonText: 'Heute',
        expandableDateFormat: 'EEEE, dd. MMMM yyyy',
        dayOfWeekStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11),
      ),
    ),
    _buildEventList()
  ],
),

...

/// This function [_buildEventList] constructs the list of events of a selected day. This
/// list is rendered below the week view or the month view.
Widget _buildEventList() {
  return Expanded(
    child: ListView.builder(
      padding: EdgeInsets.all(0.0),
      itemBuilder: (BuildContext context, int index) {
        final CleanCalendarEvent event = _selectedEvents[index];
        final String start =
            DateFormat('HH:mm').format(event.startTime).toString();
        final String end =
            DateFormat('HH:mm').format(event.endTime).toString();
        return ListTile(
          contentPadding:
              EdgeInsets.only(left: 2.0, right: 8.0, top: 2.0, bottom: 2.0),
          leading: Container(
            width: 10.0,
            color: event.color,
          ),
          title: Text(event.summary),
          subtitle:
              event.description.isNotEmpty ? Text(event.description) : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text(start), Text(end)],
          ),
          onTap: () {},
        );
      },
      itemCount: _selectedEvents.length,
    ),
  );
}
```

For more details see the **example**.
## Properties

```dart
/// [onDateSelected] is of type [ValueChanged<DateTime>] and it containes the callback function
///     extecuted when tapping a date
/// [onMonthChanged] is of type [ValueChanged<DateTime>] and it containes the callback function
///     extecuted when changing to another month
/// [onExpandStateChanged] is of type [ValueChanged<bool>] and it contains a callback function
///     executed when the view changes to expanded or to condensed
/// [onRangeSelected] contains a callback function of type [ValueChanged], that gets called on changes
///     of the range (switch to next or previous week or month)
/// [isExpandable] is a [bool]. With this parameter you can control, if the view can expand from week view
///     to month view. Default is [false].
/// [dayBuilder] can contain a [Widget]. If this property is not null (!= null), this widget will get used to
///     render the calenar tiles (so you can customize the view)
/// [hideArrows] is a bool. When set to [true] the arrows to navigate to the next or previous week/month in the
///     top bar well get suppressed. Default is [false].
/// [hideTodayIcon] is a bool. When set to [true] the dispaly of the Today-Icon (button to navigate to today) in the
///     top bar well get suppressed. Default is [false].
/// [hideBottomBar] at the moment has no function. Default is [false].
/// [events] are of type [Map<DateTime, List<CleanCalendarEvent>>]. This data structure containes the events to display
/// [selctedColor] this is the color, applied to the circle on the selcted day
/// [todayColor] this is the color of the date of today
/// [todayButtonText] is a [String]. With this property you can set the caption of the today icon (button to navigate to today).
///     If left empty, the calendar will use the string "Today".
/// [eventColor] lets you optionally specify the color of the event (dot). If the [CleanCaendarEvents] property color is not set, the
///     calendar will use this parameter.
/// [eventDoneColor] with this property you can define the color of "done" events, that is events in the past.
/// [initialDate] is of type [DateTime]. It can contain an optional start date. This is the day, that gets initially selected
///     by the calendar. The default is to not set this parameter. Then the calendar uses [DateTime.now()]
/// [isExpanded] is a bool. If is us set to [true], the calendar gets rendered in month view.
/// [weekDays] contains a [List<String>] defining the names of the week days, so that it is possible to name them according
///     to your current locale.
/// [locale] is a [String]. This setting gets used to format dates according to the current locale.
/// [startOnMonday] is a [bool]. This parameter allows the calendar to determine the first day of the week.
/// [dayOfWeekStyle] is a [TextStyle] for styling the text of the weekday names in the top bar.
/// [bottomBarTextStyle] is a [TextStyle], that sets the style of the text in the bottom bar.
/// [bottomBarArrowColor] can set the [Color] of the arrow to expand/compress the calendar in the bottom bar.
/// [bottomBarColor] sets the [Color] of the bottom bar
/// [expandableDateFormat] defines the formatting of the date in the bottom bar
final ValueChanged<DateTime> onDateSelected;
final ValueChanged<DateTime> onMonthChanged;
final ValueChanged<bool> onExpandStateChanged;
final ValueChanged onRangeSelected;
final bool isExpandable;
final DayBuilder dayBuilder;
final bool hideArrows;
final bool hideTodayIcon;
final Map<DateTime, List<CleanCalendarEvent>> events;
final Color selectedColor;
final Color todayColor;
final String todayButtonText;
final Color eventColor;
final Color eventDoneColor;
final DateTime initialDate;
final bool isExpanded;
final List<String> weekDays;
final String locale;
final bool startOnMonday;
final bool hideBottomBar;
final TextStyle dayOfWeekStyle;
final TextStyle bottomBarTextStyle;
final Color bottomBarArrowColor;
final Color bottomBarColor;
final String expandableDateFormat;
```

## Sample event data

The syntax of the event map changed due to the introduction of the 'CleanCalendarEvent' class.

```dart
final Map<DateTime, List<CleanCalendarEvent>> _events = {
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      CleanCalendarEvent('Event A',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, 10, 0),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, 12, 0),
          description: 'A special event',
          color: Colors.blue[700]),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2):
        [
      CleanCalendarEvent('Event B',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 10, 0),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 12, 0),
          color: Colors.orange),
      CleanCalendarEvent('Event C',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 14, 30),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 17, 0),
          color: Colors.pink),
    ],
  };

```

### Acknowledgments
Special thanks to @rwbr for adding the new event class to give more flexibility tot he project