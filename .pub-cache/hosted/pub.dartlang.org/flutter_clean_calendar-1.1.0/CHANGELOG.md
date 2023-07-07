## [1.1.0]
- Introduction of 'CleanCalendarEvent' class. This makes the former syntax of the 'Map' that stores the events incompatible.
- Null safety
- Requires flutter 2+

## [1.0.2]
- Breaking Changes: Changed naming properties from show to hide, i.e. `hideArrows` instead of `showArrows`
- Fixed dependencies issues with newer flutter versions
- Added more styling options
- Ability to start month on Monday or Sunday. Sunday by default, you need to replace weekDays if changing this value
- Ability to replace day of weeks when starting calendar on Monday 
- Hide or show bottom bar and its color
- Ability to change bottom bar color, arrow color and text style

## [1.0.1]

- Ability to start the calendar with a date other than today
- Ability to start the calendar expanded or not

## [0.1.5]

- Breaking Changes: events now should be a Map with a List of Maps and not Strings as 1.0.4
- Added Done events so you can see diferent eventColors

## [0.1.4]

- Fixed locale dates
- Added render list events

## [0.1.3]

- Minor bug fixes

## [0.1.1]

- Improved UI - Bottom bar now triggers the month/week view

## [0.1.0]

- Slide up/down to show month/week calendar
