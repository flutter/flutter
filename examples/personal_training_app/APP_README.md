# SIM Training partner

A comprehensive Flutter application for tracking and managing personal workout routines, exercises, and fitness progress.

## Features

### 🏠 Home Screen
- **Dashboard Overview**: Quick stats showing total workouts, total volume, sets, and averages
- **Today's Workout**: View the current day's scheduled workout with all exercises
- **Quick Stats**: At-a-glance metrics for motivation and tracking

### 📋 Workout History
- **Chronological Log**: View all workouts sorted by date (newest first)
- **Detailed Breakdown**: Expandable workout cards showing:
  - Exercise names with sets × reps × weight
  - Notes and comments on performance
  - Total volume per exercise
  - Cumulative workout statistics
- **Search & Filter**: Easily find previous workouts

### ➕ Add Workout
- **Flexible Workout Creation**: Create custom workouts with:
  - Workout name and date selection
  - Add multiple exercises to a single workout
  - Specify sets, reps, and weight for each exercise
  - Optional notes for tracking feelings, PRs, or modifications
- **Exercise Management**: Add and remove exercises before saving
- **Real-time Feedback**: Validation and success notifications

### 📈 Progress Tracking
- **Performance Metrics**:
  - Total workouts completed
  - Total volume lifted (in kg)
  - Average volume per workout
  - Total reps performed
  - Total sets completed
- **Exercise Frequency**: See your most-performed exercises
- **Statistical Analysis**: Detailed breakdowns to identify patterns and progress

## Getting Started

### Prerequisites
- Flutter 3.10.7 or higher
- Dart 3.10.7 or higher
- Android SDK / iOS SDK (for mobile deployment)

### Installation

1. Clone or navigate to the project directory:
```bash
cd examples/personal_training_app
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point and navigation
├── models/
│   └── workout.dart            # Data models for Workout and Exercise
├── screens/
│   ├── home_screen.dart        # Home dashboard
│   ├── workout_history_screen.dart  # Workout log
│   ├── add_workout_screen.dart  # Workout creation
│   └── progress_screen.dart    # Progress analytics
```

## Data Models

### Workout
- `id`: Unique identifier
- `name`: Workout name (e.g., "Chest Day")
- `date`: Date of the workout
- `exercises`: List of exercises performed
- `notes`: Optional workout notes

### Exercise
- `name`: Exercise name
- `sets`: Number of sets
- `reps`: Repetitions per set
- `weight`: Weight used (in kg)
- `notes`: Optional exercise notes
- `restSeconds`: Rest time between sets

## Usage Examples

### Creating a Workout
1. Navigate to the "Add Workout" tab
2. Enter a workout name (e.g., "Leg Day")
3. Select the date
4. Add exercises one by one:
   - Enter exercise name (e.g., "Squats")
   - Specify sets, reps, and weight
   - Add optional notes (e.g., "Felt great, PR on depth")
5. Click "Save Workout"

### Tracking Progress
1. Go to the "Progress" tab
2. Review key metrics:
   - See total workouts completed
   - Track total volume lifted
   - Monitor most frequently performed exercises
   - Analyze workout averages

### Viewing History
1. Navigate to "History" tab
2. Expand any workout card to see:
   - All exercises with detailed info
   - Notes and observations
   - Volume calculations
3. Browse backward through your training history

## Statistics Calculated

- **Total Volume**: Sum of (weight × reps × sets) across all workouts
- **Exercise Frequency**: Count of how many times each exercise has been performed
- **Average Metrics**: Per-workout averages for volume, sets, and reps
- **Performance Trends**: Historical data to identify progress

## Future Enhancement Ideas

- **Persistent Storage**: SQLite database for saving workouts between sessions
- **REST Timer**: Built-in timer for rest periods between sets
- **Workout Templates**: Save and reuse favorite workout routines
- **Goal Setting**: Set personal records and lift targets
- **Charts & Graphs**: Visual progress tracking over time
- **Share & Export**: Export workout data as CSV or PDF
- **Dark Mode**: Theme customization
- **Notifications**: Reminders for scheduled workouts
- **Integration**: Sync with fitness wearables

## Technical Stack

- **Framework**: Flutter
- **Language**: Dart
- **UI**: Material Design 3
- **State Management**: StatefulWidget (can be enhanced with Provider or Riverpod)
- **Localization**: intl package for date formatting

## License

This project is provided as-is for personal use.

## Support

For issues or feature requests, consider:
- Implementing persistent storage with SQLite
- Adding more detailed analytics
- Creating workout plan scheduling features
- Integrating with fitness APIs
