class EventModel {
  String? key;
  String? title;
  String? description;
  String? image;
  String? createdBy;
  String? startAt;
  String? endAt;
  String? eventLink;
  List<String>? attendeesList;
  int? attendeesCount;

  EventModel({
    this.key,
    this.title,
    this.description,
    this.image,
    this.createdBy,
    this.startAt,
    this.endAt,
    this.eventLink,
    this.attendeesList,
    this.attendeesCount,
  });

  factory EventModel.fromJson(Map<dynamic, dynamic> json) => EventModel(
        key: json['key'],
        title: json['title'],
        description: json['description'],
        image: json['image'],
        createdBy: json['createdBy'],
        startAt: json['startAt'],
        endAt: json['endAt'],
        eventLink: json['eventLink'],
        attendeesList: json['attendeesList'] != null
            ? List<String>.from(json['attendeesList'])
            : [],
        attendeesCount: json['attendeesCount'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'description': description,
        'image': image,
        'createdBy': createdBy,
        'startAt': startAt,
        'endAt': endAt,
        'eventLink': eventLink,
        'attendeesList': attendeesList,
        'attendeesCount': attendeesCount,
      };

  bool hasUserJoined(String userId) {
    return attendeesList?.contains(userId) ?? false;
  }
}
