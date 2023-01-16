import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../models/case.dart';

class TaskModel extends ChangeNotifier {

  List<Case> cases = [];

  bool isOnTask = false;
  List<Position> routePositions = [];
  int currentTaskPrice = 90;
  double totalDistance = 0;
  int secondIdle = 0;

  DateTime? lastRecordTime;
  double currentVelocity = -1;

  Position? lastFiveSecondPosition;

  void addCase(Case newCase){
    cases.add(newCase);
    notifyListeners();
  }

  void setCurrentTaskPrice(){
    if(totalDistance >= 1.25){
      int times = ((totalDistance-1.25)/0.2).floor();
      currentTaskPrice = 90 + times*5;
    }else{
      currentTaskPrice = 90;
    }

    if(secondIdle >= 30){
      int times = (secondIdle - 30) ~/80;
      currentTaskPrice = currentTaskPrice +  times*5;
    }

    print('current velocity $currentVelocity');
    print('total distance $totalDistance');
    print('total idle second $secondIdle');
    notifyListeners();
  }

  void resetTask(){
    currentTaskPrice = 90;
    totalDistance = 0;
    routePositions.clear();
    isOnTask = false;
    secondIdle = 0;
    lastRecordTime = null;
    currentVelocity = -1;

    //移除最上面那個 case
    cases.removeAt(0);
    notifyListeners();
  }

}