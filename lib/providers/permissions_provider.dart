import 'package:flutter/foundation.dart';

class PermissionsProvider with ChangeNotifier {
  bool _isRequesting = false;

  bool get isRequesting => _isRequesting;

  void startRequest() {
    if (!_isRequesting) {
      _isRequesting = true;
      notifyListeners();
    }
  }

  void finishRequest() {
    if (_isRequesting) {
      _isRequesting = false;
      notifyListeners();
    }
  }
}


