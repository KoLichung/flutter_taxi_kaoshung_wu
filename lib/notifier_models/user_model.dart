import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';

class UserModel extends ChangeNotifier {

  int positionUpdateCount = 0;
  DateTime? lastUpdateLocationTime;

  // User _user = User();
  // User get user => _user;
  User? _user;
  User? get user => _user;
  String? token;
  StreamSubscription<Position>? positionStreamSubscription;

  bool isOnline = false;

  String? fcmToken;
  String? platformType;
  String? deviceId;
  String? currentAppVersion;
  int? currentAppVersionNumber;

  Position? currentPosition;

  void setUser(User theUser){
    _user = theUser;
    notifyListeners();
  }

  void removeUser(BuildContext context){
    _user = User();
    token = null;
    isOnline = false;
    notifyListeners();
  }

  void resetPositionParams(){
    positionUpdateCount = 0;
    lastUpdateLocationTime =null;
  }

  void setCurrentAppVersion(String version){
    currentAppVersion = version;
    notifyListeners();
  }

  void setCurrentAppVersionNumber(int number){
    currentAppVersionNumber = number;
    notifyListeners();
  }

}