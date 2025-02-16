class ReferralCode {
  String code;
  String createdFor;
  String? usedBy;
  String createdAt;

  ReferralCode({
    required this.code,
    required this.createdFor,
    this.usedBy,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<dynamic, dynamic> json) => ReferralCode(
        code: json['code'],
        createdFor: json['createdFor'],
        usedBy: json['usedBy'],
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'createdFor': createdFor,
        'usedBy': usedBy,
        'createdAt': createdAt,
      };
}
