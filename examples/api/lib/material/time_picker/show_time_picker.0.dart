import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        buttonTheme: ButtonTheme.of(context).copyWith(
          disabledColor: Colors.black,
          colorScheme: const ColorScheme.light(
            secondary: Colors.green, // Color you want for action buttons (CANCEL and OK)
          ),
        ),
        primaryColor: Colors.orange,
        secondaryHeaderColor: Colors.deepPurpleAccent,
        timePickerTheme: TimePickerThemeData(
            dayPeriodBorderSide: const BorderSide(color: Colors.red),
            dayPeriodColor: Colors.red,
            hourMinuteTextColor: Colors.white,
            dayPeriodTextColor: Colors.white,
            backgroundColor: Colors.black.withOpacity(0.2),
            dialBackgroundColor: Colors.yellow.withOpacity(0.2),
            entryModeIconColor: Colors.green,
            hourMinuteColor: Colors.pink,
            dialHandColor: Colors.purple,
            confirmButtonStyle: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.blue)),
            cancelButtonStyle: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.red))),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHome(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () async {
              await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: false,
                    ),
                    child: child!,
                  );
                },
              );
            },
            child: const Text("picker")),
      ),
    );
  }
}
