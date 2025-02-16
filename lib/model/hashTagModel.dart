class HashtagModel {
  String tag;
  int count;
  String createdAt;

  HashtagModel({
    required this.tag,
    required this.count,
    required this.createdAt,
  });

  factory HashtagModel.fromJson(Map<dynamic, dynamic> json) => HashtagModel(
        tag: json['tag'],
        count: json['count'],
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'count': count,
        'createdAt': createdAt,
      };
}
