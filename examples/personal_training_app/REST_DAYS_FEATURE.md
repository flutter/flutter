# Rest Days Feature - Version 1.0.0+24

## Overview
Added rest day scheduling functionality allowing instructors to schedule rest/recovery days for clients. These days appear in blue on the client's calendar.

## New Features

### For Instructors
- **New "Rest Days" Tab**: Added to instructor dashboard navigation
- **Rest Day Scheduler Screen**: 
  - Select client from dropdown
  - Pick date using date picker
  - Add optional notes (e.g., "Recovery day", "Injury prevention")
  - Schedule button creates the rest day
- **Visual Feedback**: Success confirmation when rest day is scheduled

### For Clients
- **Blue Calendar Days**: Rest days show in light blue (Color: #3B82F6 with 20% opacity)
- **Blue Border**: Rest days have distinctive blue border for easy identification
- **Rest Day Dialog**: Tap rest day to view:
  - Hotel icon indicator
  - Date
  - Optional notes from instructor
- **Prevents Workout Scheduling**: Clients cannot schedule workouts on rest days (future enhancement)

## Technical Implementation

### Models
- **RestDay Model** (`lib/models/rest_day.dart`)
  ```dart
  class RestDay {
    final String id;
    final DateTime date;
    final String clientName;
    final String? notes;
  }
  ```

### UI Components
- **_RestDayScheduler Widget**: Full-featured scheduling interface in instructor dashboard
- **TrainingCalendar Widget**: Enhanced to display rest days
  - `_isRestDay()`: Check if date is a rest day
  - `_getRestDayForDay()`: Retrieve rest day for specific date
  - `_showRestDayDialog()`: Display rest day information

### State Management
- Added `_restDays` list to `_AppRootState`
- Rest days passed through component tree: `MainNavigation` → `HomeScreen` → `TrainingCalendar`

### Data Persistence

#### Local Storage
- **Rest Day Data**: `restday_<id>` - Serialized format: `id|timestamp|clientName|notes`
- **Global List**: `all_restdays` - Comma-separated list of rest day IDs
- Methods:
  - `_saveRestDayToStorage()`: Persist rest day locally
  - `_loadAllRestDays()`: Load all rest days on app start
  - `_saveRestDayToLocalOnly()`: Save during Firebase sync

#### Firebase Realtime Database
- **Path**: `restDays/<restDayId>`
- **Structure**:
  ```json
  {
    "id": "1234567890",
    "date": "2024-01-15T00:00:00.000Z",
    "clientName": "John Doe",
    "notes": "Recovery day"
  }
  ```
- **Methods** (`lib/utils/firebase_service.dart`):
  - `saveRestDay()`: Save to Firebase
  - `getAllRestDays()`: Retrieve all rest days
  - `watchAllRestDays()`: Real-time stream listener
  - `deleteRestDay()`: Remove rest day

### Real-Time Sync
- Firebase listener in `_setupFirebaseListeners()` watches for rest day changes
- `_syncRestDaysFromFirebase()`: Syncs Firebase data to local state
- Automatic updates across all connected devices

## Callbacks & Flow

### Instructor Workflow
1. Navigate to "Rest Days" tab
2. Select client from dropdown
3. Choose date via date picker
4. Optionally add notes
5. Click "Schedule Rest Day"
6. Data flows through: `_RestDayScheduler` → `onRestDayAdded` → `_saveRestDayToStorage` → `FirebaseService.saveRestDay()`

### Client View Workflow
1. Open Home screen
2. Calendar automatically loads rest days
3. Blue days indicate rest days
4. Tap to view details

## Files Modified

### New Files
- `lib/models/rest_day.dart` - Rest day model

### Modified Files
- `lib/main.dart`:
  - Added `_restDays` state list
  - Added `_restDaysSubscription` for Firebase listener
  - Added `_saveRestDayToStorage()`, `_loadAllRestDays()`, `_syncRestDaysFromFirebase()`, `_saveRestDayToLocalOnly()`
  - Updated `_setupFirebaseListeners()` to watch rest days
  - Updated `dispose()` to cancel rest days subscription
  - Added `onRestDayAdded` callback to InstructorDashboard

- `lib/screens/instructor_dashboard.dart`:
  - Added "Rest Days" navigation destination (icon: hotel)
  - Added `onRestDayAdded` callback parameter
  - Created `_RestDayScheduler` widget with full UI
  - Imported RestDay model

- `lib/widgets/training_calendar.dart`:
  - Added `restDays` parameter
  - Added `_isRestDay()` method
  - Added `_getRestDayForDay()` method
  - Added `_showRestDayDialog()` method
  - Updated rendering logic for blue rest day styling

- `lib/screens/home_screen.dart`:
  - Added `restDays` parameter (default: empty list)
  - Passed rest days to TrainingCalendar

- `lib/utils/firebase_service.dart`:
  - Added `saveRestDay()` method
  - Added `getAllRestDays()` method
  - Added `watchAllRestDays()` stream
  - Added `deleteRestDay()` method

- `pubspec.yaml`:
  - Updated version to 1.0.0+24

## Color Scheme
- **Rest Day Background**: `Color(0xFF3B82F6).withOpacity(0.2)` (Light blue, 20% opacity)
- **Rest Day Border**: `Color(0xFF3B82F6)` (Blue)
- **Primary Button**: `Color(0xFF3B82F6)` (Blue)
- **Hotel Icon**: Blue color for rest day indicator

## Future Enhancements
- [ ] Prevent workout scheduling on rest days
- [ ] Bulk rest day scheduling (e.g., schedule every Sunday)
- [ ] Rest day templates with pre-written notes
- [ ] Edit/delete rest days functionality
- [ ] Rest day statistics (total rest days per client)
- [ ] Calendar view for instructors showing all clients' rest days

## Build Information
- **Version**: 1.0.0+24
- **Build Type**: Release App Bundle (AAB)
- **Output**: `build\app\outputs\bundle\release\app-release.aab`
- **Size**: 43.4MB
- **Build Date**: December 2024
