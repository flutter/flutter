## Widget Testing

Widget tests (also called component tests) test individual widgets.

### Example: Testing a Widget with Mocked Dependencies

When a widget depends on a service or provider, you can use the `mockito` package to mock the dependency during testing.

#### Step 1: Install `mockito`

Add `mockito` as a dev dependency in your `pubspec.yaml` file:

```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```
## Step 2: Create a Mock Class
Generate a mock class for your service:
```yaml
import 'package:mockito/annotations.dart';

@GenerateMocks([DataService])
void main() {}
```
## Run the following command to generate the mock:
```yaml
flutter pub run build_runner build
```
## Step 3: Write the Test
Test a widget with the mocked service:
```yaml
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'my_widget.dart'; // Replace with your widget
import 'data_service.dart'; // Replace with your service
import 'data_service_test.mocks.dart';

void main() {
  testWidgets('Widget displays data from mocked service', (WidgetTester tester) async {
    // Create a mock service
    final mockService = MockDataService();
    when(mockService.fetchData()).thenAnswer((_) async => 'Mocked Data');

    // Inject the mock service into the widget
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(dataService: mockService),
      ),
    );

    // Verify that the widget displays the mocked data
    expect(find.text('Mocked Data'), findsOneWidget);
  });
}
```
