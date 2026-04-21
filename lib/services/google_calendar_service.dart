library;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:http/http.dart' as http;

import '../models/application_status.dart';
import '../models/job_application.dart';

class GoogleCalendarSyncResult {
  const GoogleCalendarSyncResult({
    required this.success,
    this.eventId,
    this.eventUrl,
    this.error,
  });

  final bool success;
  final String? eventId;
  final String? eventUrl;
  final String? error;

  factory GoogleCalendarSyncResult.success({
    required String eventId,
    String? eventUrl,
  }) {
    return GoogleCalendarSyncResult(
      success: true,
      eventId: eventId,
      eventUrl: eventUrl,
    );
  }

  factory GoogleCalendarSyncResult.failure(String error) {
    return GoogleCalendarSyncResult(success: false, error: error);
  }
}

class GoogleCalendarService {
  GoogleCalendarService._internal();

  static final GoogleCalendarService instance =
      GoogleCalendarService._internal();

  static const List<String> _calendarScopes = [CalendarApi.calendarEventsScope];
  static const String _calendarId = 'primary';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  Future<GoogleSignInAccount?> _resolveAccount({
    bool interactive = false,
  }) async {
    await _ensureInitialized();

    final lightweight = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
    if (lightweight != null) return lightweight;
    if (!interactive) return null;
    return GoogleSignIn.instance.authenticate(scopeHint: _calendarScopes);
  }

  Future<Map<String, String>?> _authorizationHeaders({
    required bool promptIfNecessary,
  }) async {
    final account = await _resolveAccount(interactive: promptIfNecessary);
    if (account == null) return null;
    return account.authorizationClient.authorizationHeaders(
      _calendarScopes,
      promptIfNecessary: promptIfNecessary,
    );
  }

  Future<bool> ensureAuthorized() async {
    final headers = await _authorizationHeaders(promptIfNecessary: true);
    return headers != null;
  }

  Future<GoogleCalendarSyncResult> syncInterviewEvent({
    required JobApplication application,
    required DateTime interviewDate,
    String? existingEventId,
    bool createMeetConference = true,
  }) async {
    http.Client? client;
    try {
      final headers = await _authorizationHeaders(promptIfNecessary: true);
      if (headers == null) {
        return GoogleCalendarSyncResult.failure(
          'Izin Google Calendar belum diberikan.',
        );
      }

      client = _StaticHeadersClient(headers);
      final api = CalendarApi(client);
      final event = _buildEvent(
        application,
        interviewDate,
        createMeetConference: createMeetConference,
      );

      final result = existingEventId != null && existingEventId.isNotEmpty
          ? await api.events.update(
              event,
              _calendarId,
              existingEventId,
              conferenceDataVersion: createMeetConference ? 1 : null,
            )
          : await api.events.insert(
              event,
              _calendarId,
              conferenceDataVersion: createMeetConference ? 1 : null,
            );

      final eventId = result.id;
      if (eventId == null || eventId.isEmpty) {
        return GoogleCalendarSyncResult.failure(
          'Google Calendar tidak mengembalikan event id.',
        );
      }

      final meetingUrl =
          result.hangoutLink ??
          _extractVideoEntryPoint(result.conferenceData) ??
          result.htmlLink;

      return GoogleCalendarSyncResult.success(
        eventId: eventId,
        eventUrl: meetingUrl,
      );
    } on GoogleSignInException catch (e) {
      return GoogleCalendarSyncResult.failure(
        e.description ?? 'Gagal otorisasi Google Sign-In.',
      );
    } catch (e) {
      return GoogleCalendarSyncResult.failure(
        'Gagal sinkron ke Google Calendar: $e',
      );
    } finally {
      client?.close();
    }
  }

  Event _buildEvent(
    JobApplication application,
    DateTime interviewDate, {
    required bool createMeetConference,
  }) {
    final unitLabel = application.unitLabel ?? 'Hiring Team';
    final location = application.meetingUrl ?? application.location ?? 'TBD';
    final candidateLabel = application.candidateId ?? 'candidate';
    final description = StringBuffer()
      ..writeln('Interview for ${application.jobTitle}')
      ..writeln()
      ..writeln('Unit: $unitLabel')
      ..writeln('Candidate: $candidateLabel')
      ..writeln('Application ID: ${application.id}')
      ..writeln('Current status: ${application.status.displayName}');

    if ((application.meetingUrl ?? '').isNotEmpty) {
      description
        ..writeln()
        ..writeln('Meeting link')
        ..writeln(application.meetingUrl!.trim());
    }

    if ((application.interviewNotes ?? '').isNotEmpty) {
      description
        ..writeln()
        ..writeln('Interview notes')
        ..writeln(application.interviewNotes!.trim());
    }

    if ((application.coverLetter ?? '').isNotEmpty) {
      description
        ..writeln()
        ..writeln('Cover Letter')
        ..writeln(application.coverLetter!.trim());
    }

    final durationMinutes = application.interviewDurationMinutes ?? 60;

    return Event()
      ..summary = 'Interview: ${application.jobTitle}'
      ..location = location
      ..description = description.toString()
      ..conferenceData = (createMeetConference
          ? (ConferenceData()
              ..createRequest = (CreateConferenceRequest()
                ..conferenceSolutionKey = (ConferenceSolutionKey()
                  ..type = 'hangoutsMeet')
                ..requestId =
                    'interview-${application.id}-${interviewDate.millisecondsSinceEpoch}'))
          : null)
      ..start = (EventDateTime()
        ..dateTime = interviewDate
        ..timeZone = 'Asia/Jakarta')
      ..end = (EventDateTime()
        ..dateTime = interviewDate.add(Duration(minutes: durationMinutes))
        ..timeZone = 'Asia/Jakarta')
      ..reminders = (EventReminders()
        ..useDefault = false
        ..overrides = [
          EventReminder()
            ..method = 'popup'
            ..minutes = 30,
        ]);
  }

  String? _extractVideoEntryPoint(ConferenceData? conferenceData) {
    final entries = conferenceData?.entryPoints;
    if (entries == null) return null;
    for (final entry in entries) {
      if (entry.entryPointType == 'video' &&
          entry.uri != null &&
          entry.uri!.isNotEmpty) {
        return entry.uri;
      }
    }
    return null;
  }
}

class _StaticHeadersClient extends http.BaseClient {
  _StaticHeadersClient(this._headers, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
