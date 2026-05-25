import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _isNotificationOn = true; // default

  bool get isNotificationOn => _isNotificationOn;

  void toggleNotification(bool val) {
    _isNotificationOn = val;
    notifyListeners();
  }
}