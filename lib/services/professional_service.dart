import 'dart:convert';
import 'package:Trusty/helper/utility.dart';
import 'package:http/http.dart' as http;

class MockProfessionalModel {
  final String userId;
  final String? userName;
  final String? displayName;
  final String? specialty;
  final double? rating;

  MockProfessionalModel({
    required this.userId,
    this.userName,
    this.displayName,
    this.specialty,
    this.rating,
  });

  factory MockProfessionalModel.fromJson(Map<String, dynamic> json) {
    return MockProfessionalModel(
      userId: json['userId'],
      userName: json['userName'],
      displayName: json['displayName'],
      specialty: json['specialty'],
      rating: json['rating']?.toDouble(),
    );
  }
}

class AISearchResponse {
  final String message;
  final List<MockProfessionalModel> professionals;

  AISearchResponse({
    required this.message,
    required this.professionals,
  });
}

class ProfessionalService {
  static const String _baseUrl = 'https://api.curiosity.tech/trusty/api/v1';
  final bool useMock;
  final String? _token;

  ProfessionalService({
    // true ise mock, false ise real
    this.useMock = false,
    String? token,
  }) : _token = token;

  Future<AISearchResponse> searchProfessionals(String query) async {
    if (useMock) {
      return _mockSearchProfessionals(query);
    }
    return _realSearchProfessionals(query);
  }

  Future<AISearchResponse> _mockSearchProfessionals(String query) async {
    await Future.delayed(const Duration(seconds: 2));

    final mockData = {
      "response":
          "Aradığınız kriterlere uygun Mustafa ve Ali gözüküyor, ikisi de aradığınız yeteneklere sahip.",
      "users": [
        {"userId": "QiAQMXOTPkPaHVs8XipZkw0hJH52"},
        {"userId": "2VsrgfF5mvM9YW2RfYDk2qJX1cw2"},
        {"userId": "c9DQ4I17pCWJcRvkktuDVtDRduZ2"},
        {"userId": "lOBA2aMmlGZNQxRRCLtZfWbBtp12"},
      ]
    };

    return AISearchResponse(
      message: mockData['response'] as String,
      professionals: (mockData['users'] as List)
          .map((data) =>
              MockProfessionalModel.fromJson(Map<String, dynamic>.from(data)))
          .toList(),
    );
  }

  Future<AISearchResponse> _realSearchProfessionals(String query) async {
    if (_token == null) {
      cprint('API token is required for real API calls',
          errorIn: 'realSearchProfessionals');
      throw Exception(
          'AI service is not available right now, please try again later.');
    }

    print('token: $_token');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/searchprofessional'),
        body: json.encode({'query': query}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AISearchResponse(
          message: data['response'] as String,
          professionals: (data['users'] as List)
              .map((user) => MockProfessionalModel.fromJson(
                  Map<String, dynamic>.from(user)))
              .toList(),
        );
      } else {
        cprint('Failed to search professionals: ${response.statusCode}',
            errorIn: 'realSearchProfessionals');
        throw Exception(
            'AI service is not available right now, please try again later. Err 113');
      }
    } catch (e) {
      cprint('Failed to search professionals: $e',
          errorIn: 'realSearchProfessionals');
      throw Exception(
          'AI service is not available right now, please try again later. Err 117');
    }
  }
}
