import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/eventModel.dart';
import 'package:Trusty/state/appState.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventState extends AppState {
  final auth = FirebaseAuth.instance;
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  List<EventModel>? _eventList;

  List<EventModel>? get eventList {
    if (_eventList == null) return null;
    return List.from(_eventList!.where((event) {
      final now = DateTime.now();
      final start = DateTime.parse(event.startAt!);
      final weekBefore = start.subtract(const Duration(days: 30));
      return now.isAfter(weekBefore);
    }));
  }

  Future<void> getEvents() async {
    try {
      _isBusy = true;
      notifyListeners(); // Add this to show loading state immediately

      final event = await kDatabase.child('events').once();
      _eventList = []; // Initialize list before checking snapshot

      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          var valueMap = value as Map<dynamic, dynamic>;
          valueMap['key'] = key; // Add key to the map before creating model
          final model = EventModel.fromJson(valueMap);
          _eventList!.add(model);
        });
      }

      _isBusy = false;
      notifyListeners();
    } catch (e) {
      _isBusy = false;
      notifyListeners();
      cprint(e, errorIn: 'getEvents');
    }
  }

  Future<void> joinEvent(String eventId, String userId) async {
    try {
      // Get current event data
      final eventSnapshot =
          await kDatabase.child('events').child(eventId).once();
      if (eventSnapshot.snapshot.value != null) {
        final eventData =
            Map<dynamic, dynamic>.from(eventSnapshot.snapshot.value as Map);

        // Update attendees list and count
        List<String> attendees = eventData['attendeesList'] != null
            ? List<String>.from(eventData['attendeesList'])
            : [];
        attendees.add(userId);

        // Update event in database
        await kDatabase.child('events').child(eventId).update({
          'attendeesList': attendees,
          'attendeesCount': attendees.length,
        });

        // Record user's attendance separately
        await kDatabase
            .child('eventUsers')
            .child(eventId)
            .child(userId)
            .set(true);

        await getEvents(); // Refresh events list
      }
    } catch (e) {
      cprint(e);
    }
  }

  Future<void> createSampleEvent() async {
    try {
      final eventData = {
        'title': 'Flutter Developers Meetup',
        'description':
            'Join us for an exciting meetup where we\'ll discuss the latest Flutter trends, share experiences, and network with fellow developers. We\'ll have guest speakers, live coding sessions, and Q&A discussions.',
        'image':
            'https://storage.googleapis.com/cms-storage-bucket/70760bf1e88b184bb1bc.png',
        'createdBy': 'QiAQMXOTPkPaHVs8XipZkw0hJH52',
        'startAt': DateTime.now()
            .add(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
        'endAt': DateTime.now()
            .add(const Duration(days: 2, hours: 2))
            .toUtc()
            .toIso8601String(),
        'eventLink': 'https://meet.google.com/sample-link',
        'attendeesList': [],
        'attendeesCount': 0,
      };

      await kDatabase.child('events').push().set(eventData);
    } catch (e) {
      cprint(e, errorIn: 'createSampleEvent');
    }
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      eventData['createdBy'] = auth.currentUser!.uid;
      await kDatabase.child('events').push().set(eventData);
      await getEvents(); // Refresh events list
    } catch (e) {
      cprint(e, errorIn: 'createEvent');
    }
  }
}
