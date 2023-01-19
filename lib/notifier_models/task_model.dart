import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../models/case.dart';

class TaskModel extends ChangeNotifier {

  List<Case> cases = [];

  bool isOnTask = false;
  List<Position> routePositions = [];
  int currentTaskPrice = 50;
  double totalDistance = 0;
  int secondTotal = 0;

  DateTime? lastRecordTime;
  double currentVelocity = -1;

  Position? lastFiveSecondPosition;

  void addCase(Case newCase){
    cases.add(newCase);
    notifyListeners();
  }

  void setCurrentTaskPrice(){
    if(totalDistance >= 1){
      int times = totalDistance.floor();
      currentTaskPrice = 50 + times*20;
    }else{
      currentTaskPrice = 50;
    }

    int times = secondTotal~/30;
    currentTaskPrice = currentTaskPrice +  times*1;

    print('current velocity $currentVelocity');
    print('total distance $totalDistance');
    print('total second $secondTotal');
    notifyListeners();
  }

  void resetTask(){
    currentTaskPrice = 50;
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