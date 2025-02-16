import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpCenterState extends ChangeNotifier {
  static const String _slackWebhookUrl =
      'https://hooks.slack.com/services/XXXX/XXXX/XXXX';

  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _lastMessageTime;
  static const int _cooldownMinutes = 5;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _messageSent = false;
  bool get messageSent => _messageSent;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInCooldown {
    if (_lastMessageTime == null) return false;
    final difference = DateTime.now().difference(_lastMessageTime!);
    return difference.inMinutes < _cooldownMinutes;
  }

  String get cooldownMessage {
    if (_lastMessageTime == null) return '';
    final difference = DateTime.now().difference(_lastMessageTime!);
    final remainingMinutes = _cooldownMinutes - difference.inMinutes;
    return 'Please do not send another message in a short time. Wait $remainingMinutes minutes.';
  }

  final List<String> topics = [
    'Complaint',
    'Suggestion',
    'Technical Support',
    'Other'
  ];

  HelpCenterState() {
    checkCooldown();
  }

  Future<void> sendToSlack(String topic, String message) async {
    if (isInCooldown) {
      _setError(cooldownMessage);
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final userEmail = _auth.currentUser?.email ?? 'Email cannot be found';

      final response = await http.post(
        Uri.parse(_slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': '*Email:* $userEmail\n*Topic:* $topic\n*Message:* $message',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Message could not be sent: ${response.statusCode}');
      }

      _lastMessageTime = DateTime.now();
      _setLoading(false);
      _messageSent = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'cooldown_timestamp', DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownTimestamp = prefs.getInt('cooldown_timestamp');
    if (cooldownTimestamp != null) {
      final cooldownEndTime =
          DateTime.fromMillisecondsSinceEpoch(cooldownTimestamp)
              .add(Duration(minutes: _cooldownMinutes));
      if (DateTime.now().isBefore(cooldownEndTime)) {
        _lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(cooldownTimestamp);
        notifyListeners();
      }
    }
  }
}
