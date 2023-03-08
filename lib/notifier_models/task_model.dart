import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../models/case.dart';

class TaskModel extends ChangeNotifier {

  List<Case> cases = [];

  bool isOnTask = false;
  List<Position> routePositions = [];
  double currentTaskPrice = 50.0;
  double totalDistance = 0;
  int secondTotal = 0;

  DateTime? lastRecordTime;
  double currentVelocity = -1;

  void addCase(Case newCase){
    cases.add(newCase);
    notifyListeners();
  }

  void setCurrentTaskPrice(){
    if(totalDistance >= 0.01){
      int totalDistanceInMeter = (totalDistance * 100).floor();
      int times = totalDistanceInMeter ~/ 5;
      currentTaskPrice = 50.0 + times * 0.1;
    }else{
      currentTaskPrice = 50.0;
    }

    int times = secondTotal~/15;
    currentTaskPrice = currentTaskPrice +  times*0.5;

    print('current velocity $currentVelocity');
    print('total distance $totalDistance');
    print('total second $secondTotal');
    notifyListeners();
  }

  void resetTask(){
    currentTaskPrice = 50.0;
    totalDistance = 0;
    routePositions.clear();
    isOnTask = false;
    secondTotal = 0;
    lastRecordTime = null;
    currentVelocity = -1;

    //移除最上面那個 case
    cases.removeAt(0);
    notifyListeners();
  }

}