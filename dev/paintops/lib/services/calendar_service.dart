import 'package:flutter/foundation.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  Future<bool> scheduleAppointment({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? attendeeEmail,
  }) async {
    try {
      if (kIsWeb) {
        return await _scheduleWebAppointment(
          title: title,
          description: description,
          startTime: startTime,
          endTime: endTime,
          location: location,
          attendeeEmail: attendeeEmail,
        );
      } else {
        return await _scheduleMobileAppointment(
          title: title,
          description: description,
          startTime: startTime,
          endTime: endTime,
          location: location,
          attendeeEmail: attendeeEmail,
        );
      }
    } catch (e) {
      print('Error scheduling appointment: $e');
      return false;
    }
  }

  Future<bool> _scheduleWebAppointment({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? attendeeEmail,
  }) async {
    try {
      // Generate Google Calendar URL for web
      final String googleCalendarUrl = _generateGoogleCalendarUrl(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
      );

      // Open Google Calendar in new tab (web only)
      print('Opening Google Calendar URL: $googleCalendarUrl');

      // In a real implementation, you would use url_launcher
      // For now, we'll log the URL
      return true;
    } catch (e) {
      print('Error scheduling web appointment: $e');
      return false;
    }
  }

  Future<bool> _scheduleMobileAppointment({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? attendeeEmail,
  }) async {
    try {
      // For mobile, we would integrate with the device calendar
      // This would typically use add_2_calendar package or similar

      print('Scheduling mobile appointment: $title');
      return true;
    } catch (e) {
      print('Error scheduling mobile appointment: $e');
      return false;
    }
  }

  String _generateGoogleCalendarUrl({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
  }) {
    final String startTimeFormatted = _formatDateTimeForGoogle(startTime);
    final String endTimeFormatted = _formatDateTimeForGoogle(endTime);

    final Map<String, String> params = {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${startTimeFormatted}/${endTimeFormatted}',
      'details': description,
      'location': location,
    };

    final String queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'https://calendar.google.com/calendar/render?$queryString';
  }

  String _formatDateTimeForGoogle(DateTime dateTime) {
    // Google Calendar expects format: YYYYMMDDTHHmmSSZ
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  Future<String> generateIcsFile({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? attendeeEmail,
  }) async {
    final String startFormatted = _formatDateTimeForIcs(startTime);
    final String endFormatted = _formatDateTimeForIcs(endTime);
    final String now = _formatDateTimeForIcs(DateTime.now());

    final StringBuffer ics = StringBuffer();
    ics.writeln('BEGIN:VCALENDAR');
    ics.writeln('VERSION:2.0');
    ics.writeln('PRODID:-//HWR Painting Services//PaintOps//EN');
    ics.writeln('BEGIN:VEVENT');
    ics.writeln(
      'UID:${DateTime.now().millisecondsSinceEpoch}@hwrpainting.com.au',
    );
    ics.writeln('DTSTAMP:$now');
    ics.writeln('DTSTART:$startFormatted');
    ics.writeln('DTEND:$endFormatted');
    ics.writeln('SUMMARY:$title');
    ics.writeln('DESCRIPTION:$description');
    ics.writeln('LOCATION:$location');

    if (attendeeEmail != null && attendeeEmail.isNotEmpty) {
      ics.writeln('ATTENDEE:mailto:$attendeeEmail');
    }

    ics.writeln('STATUS:CONFIRMED');
    ics.writeln('END:VEVENT');
    ics.writeln('END:VCALENDAR');

    return ics.toString();
  }

  String _formatDateTimeForIcs(DateTime dateTime) {
    // ICS expects format: YYYYMMDDTHHMMSSZ
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  Future<bool> scheduleLeadConsultation({
    required String leadName,
    required String leadPhone,
    required String leadEmail,
    required String address,
    required DateTime proposedTime,
    int durationMinutes = 60,
  }) async {
    final endTime = proposedTime.add(Duration(minutes: durationMinutes));

    return await scheduleAppointment(
      title: 'Painting Consultation - $leadName',
      description:
          'On-site consultation for painting project.\n\n'
          'Client: $leadName\n'
          'Phone: $leadPhone\n'
          'Email: $leadEmail\n\n'
          'Please bring:\n'
          '- Measuring tape\n'
          '- Color samples\n'
          '- Quote template\n'
          '- Camera for photos',
      startTime: proposedTime,
      endTime: endTime,
      location: address,
      attendeeEmail: leadEmail,
    );
  }

  Future<bool> scheduleProjectMeeting({
    required String projectName,
    required String clientName,
    required String clientEmail,
    required DateTime meetingTime,
    required String meetingType, // 'kickoff', 'progress', 'completion'
    int durationMinutes = 30,
  }) async {
    final endTime = meetingTime.add(Duration(minutes: durationMinutes));

    String title;
    String description;

    switch (meetingType.toLowerCase()) {
      case 'kickoff':
        title = 'Project Kickoff - $projectName';
        description =
            'Project kickoff meeting with $clientName\n\n'
            'Agenda:\n'
            '- Project timeline review\n'
            '- Color and material confirmation\n'
            '- Site access arrangements\n'
            '- Contact information exchange';
        break;
      case 'progress':
        title = 'Progress Review - $projectName';
        description =
            'Progress review meeting with $clientName\n\n'
            'Agenda:\n'
            '- Current progress update\n'
            '- Quality inspection\n'
            '- Next phase planning\n'
            '- Address any concerns';
        break;
      case 'completion':
        title = 'Project Completion - $projectName';
        description =
            'Project completion walkthrough with $clientName\n\n'
            'Agenda:\n'
            '- Final inspection\n'
            '- Touch-up identification\n'
            '- Maintenance instructions\n'
            '- Final payment discussion';
        break;
      default:
        title = 'Project Meeting - $projectName';
        description = 'Project meeting with $clientName for $projectName';
    }

    return await scheduleAppointment(
      title: title,
      description: description,
      startTime: meetingTime,
      endTime: endTime,
      location: 'Client Site',
      attendeeEmail: clientEmail,
    );
  }

  List<CalendarEvent> generateCalendarEventsFromTimesheets(
    List<Map<String, dynamic>> timesheets,
  ) {
    return timesheets.map((timesheet) {
      return CalendarEvent(
        id: timesheet['id'],
        title: '${timesheet['worker_name']} - ${timesheet['project_name']}',
        description: timesheet['description'] ?? '',
        startTime: DateTime.parse(timesheet['start_time']),
        endTime: DateTime.parse(timesheet['end_time']),
        type: CalendarEventType.timesheet,
        isApproved: timesheet['is_approved'] ?? false,
      );
    }).toList();
  }

  List<CalendarEvent> generateCalendarEventsFromProjects(
    List<Map<String, dynamic>> projects,
  ) {
    final List<CalendarEvent> events = [];

    for (final project in projects) {
      final startDate = project['start_date'] != null
          ? DateTime.tryParse(project['start_date'])
          : null;
      final endDate = project['end_date'] != null
          ? DateTime.tryParse(project['end_date'])
          : null;

      if (startDate != null) {
        events.add(
          CalendarEvent(
            id: '${project['id']}_start',
            title: '${project['name']} - Start',
            description: 'Project start date',
            startTime: startDate,
            endTime: startDate.add(const Duration(hours: 1)),
            type: CalendarEventType.projectStart,
            isApproved: true,
          ),
        );
      }

      if (endDate != null) {
        events.add(
          CalendarEvent(
            id: '${project['id']}_end',
            title: '${project['name']} - Deadline',
            description: 'Project deadline',
            startTime: endDate,
            endTime: endDate.add(const Duration(hours: 1)),
            type: CalendarEventType.projectDeadline,
            isApproved: true,
          ),
        );
      }
    }

    return events;
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final CalendarEventType type;
  final bool isApproved;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.isApproved,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'isApproved': isApproved,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: CalendarEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CalendarEventType.other,
      ),
      isApproved: json['isApproved'] ?? true,
    );
  }
}

enum CalendarEventType {
  timesheet,
  projectStart,
  projectDeadline,
  consultation,
  meeting,
  other,
}
