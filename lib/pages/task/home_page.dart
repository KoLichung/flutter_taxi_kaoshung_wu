import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import 'current_task.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isOnlining = false;
  // Position? currentPosition;

  Timer? _timer;
  int timerPeriod = 2;

  late List<Case> myCases = <Case>[];

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10,
  );

  Timer? _taskTimer;
  int _taskWaitingTime = 15;

  void _startTaskTimer(int currentTime) {
    _taskWaitingTime = currentTime;
    const oneSec = Duration(seconds: 1);
    _taskTimer = Timer.periodic(
      oneSec, (Timer timer) {
        _taskWaitingTime--;
        if(_taskWaitingTime == -1){
          if(_taskTimer!=null) {
            print('cancel task timer');
            _taskTimer!.cancel();
            _taskTimer=null;
          }
        }
        setState(() {});
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _handlePermission();
    _getLatestAppVersion();
    var userModel = context.read<UserModel>();

    if(userModel.currentAppVersion == null){
      _initPackageInfo();
    }
    if(userModel.deviceId==null){
      _getDeviceInfo();
    }
    if(userModel.isOnline && userModel.user!.isPassed!){
        print('start timer');
        _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
          // print('Hello world, timer: $timer.tick');
          _fetchCases(userModel.token!);
        });
    }

  }

  @override
  void dispose() {
    super.dispose();
    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }
    if(_taskTimer!=null) {
      print('cancel task timer');
      _taskTimer!.cancel();
      _taskTimer=null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.fromLTRB(0,10,10,10),
        //     child: IconButton(
        //         onPressed: (){},
        //         icon: const Icon(Icons.notifications_outlined)),)],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image:AssetImage('images/logo.png',),
                    fit:BoxFit.scaleDown),),
              height: 25,
              width: 40,
            ),
            // Icon(FontAwesomeIcons.taxi),
            const SizedBox(width: 10,),
            const Text('24h??????'),
          ],
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(105.0),
            child: Container(
              height: 105,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.grey.shade300),
                  )
              ),
              child: Consumer<UserModel>(builder: (context, userModel, child) =>
                  Column(
                    children: [
                      const SizedBox(height: 10,),
                      userModel.isOnline? statusOnlineButton() : statusOfflineButton(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('???????????????'),
                          userModel.isOnline? const Text('?????????') : const Text('?????????'),
                          const SizedBox(width: 10,),
                          const Text('???????????????'),
                          Text(userModel.user!.leftMoney.toString()),
                        ],
                      ),
                    ],
                  ),
              ),
            )
        ),
      ),
      body: Consumer<UserModel>(builder: (context, userModel, child) =>
      userModel.isOnline? checkIsTasks() : offlineScene(),
      ),
    )
    );
  }

  statusOnlineButton(){
    return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: AppColor.red,elevation: 0),
        child: const Text('????????????'),
        onPressed: () async {
          actionOffline();
        },
    );
  }

  void actionOffline(){
    var userModel = context.read<UserModel>();
    userModel.resetPositionParams();
    if(userModel.positionStreamSubscription!=null){
      print("not null positionStreamSubscription");
      userModel.positionStreamSubscription!.pause();
      userModel.positionStreamSubscription!.cancel();
      userModel.positionStreamSubscription = null;
    }

    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }

    _putUpdateOnlineState(userModel.token!, false);
  }

  statusOfflineButton(){
    return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: AppColor.green,elevation: 0),
        child: const Text('????????????'),
        onPressed: () async {

          if(_isOnlining == true){
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('???????????????~~')));
          }else{
            _isOnlining = true;
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????~~')));

            var userModel = context.read<UserModel>();
            var taskModel = context.read<TaskModel>();
            //make sure update location when online

            if(userModel.user!.isPassed!) {
              final result = await _putUpdateOnlineState(userModel.token!, true);
              // result ok ???????????????
              if(result=="ok"){
                print('start timer');
                _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
                  // print('Hello world, timer: $timer.tick');
                  _fetchCases(userModel.token!);
                });
                Position onlinePosition = await _getCurrentPosition();
                userModel.currentPosition = onlinePosition;

                print('onlinePosition ${onlinePosition}');
                _fetchUpdateLatLng(userModel.token!, onlinePosition.latitude, onlinePosition.longitude);

                userModel.positionStreamSubscription =  Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
                  if(position!=null){
                    print('${position.latitude.toString()}, ${position.longitude.toString()}');

                    if(userModel.lastUpdateLocationTime !=null && userModel.currentPosition != null){
                      DateTime nowTime = DateTime.now();
                      DateTime lastTime = userModel.lastUpdateLocationTime!;
                      Duration diff = nowTime.difference(lastTime);
                      double currentVelocity = calCulateSpeed(userModel.currentPosition!, position, diff.inSeconds);

                      if(currentVelocity.isNaN){
                        userModel.positionUpdateCount = 0;
                        _fetchUpdateLatLng(userModel.token!, position.latitude, position.longitude);
                      }else if(currentVelocity >= 30 && userModel.positionUpdateCount >= 6){
                        userModel.positionUpdateCount = 0;
                        _fetchUpdateLatLng(userModel.token!, position.latitude, position.longitude);
                      }else if(currentVelocity < 30 && currentVelocity >= 15 && userModel.positionUpdateCount >= 3){
                        userModel.positionUpdateCount = 0;
                        _fetchUpdateLatLng(userModel.token!, position.latitude, position.longitude);
                      }else if(currentVelocity < 15 && currentVelocity >= 5 && userModel.positionUpdateCount >= 2){
                        userModel.positionUpdateCount = 0;
                        _fetchUpdateLatLng(userModel.token!, position.latitude, position.longitude);
                      }else if(currentVelocity < 5 && currentVelocity > 0){
                        userModel.positionUpdateCount = 0;
                        _fetchUpdateLatLng(userModel.token!, position.latitude, position.longitude);
                      }
                    }

                    userModel.lastUpdateLocationTime = DateTime.now();
                    userModel.positionUpdateCount ++;

                    userModel.currentPosition = position;


                    if(taskModel.isOnTask){
                      // current velocity
                      if(taskModel.routePositions.isNotEmpty && taskModel.lastRecordTime!=null){
                        DateTime nowTime = DateTime.now();
                        DateTime lastTime = taskModel.lastRecordTime!;
                        Duration diff = nowTime.difference(lastTime);
                        try{
                          taskModel.currentVelocity = calCulateSpeed(userModel.currentPosition!, taskModel.routePositions.last, diff.inSeconds);
                        }catch(e){
                          print(e);
                        }
                      }

                      //total distance
                      taskModel.routePositions.add(position);
                      int listLength = taskModel.routePositions.length;
                      if(listLength >= 2){
                        taskModel.totalDistance = taskModel.totalDistance + calculateDistance(taskModel.routePositions[listLength-1].latitude, taskModel.routePositions[listLength-1].longitude, taskModel.routePositions[listLength-2].latitude, taskModel.routePositions[listLength-2].longitude);
                      }

                      taskModel.lastRecordTime = DateTime.now();
                    }
                  }else{
                    print('Unknown position');
                  }
                });
              }
            }else{
              ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('??????????????????')));
            }

          }
        },
    );
  }

  double calCulateSpeed(Position currentPosition, Position lastPosition, int durationSeconds){
    double distance = calculateDistance(currentPosition.latitude, currentPosition.longitude, lastPosition.latitude, lastPosition.longitude);
    double speed = distance * 1000 / durationSeconds;
    return speed;
  }

  //it will return distance in KM
  static double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  checkIsTasks(){
    var userModel = context.read<UserModel>();
    if (myCases.isEmpty || !userModel.user!.isPassed!){
      return onCallScene(userModel.user!.isPassed!);
    } else {
      if(_taskWaitingTime==0 || _taskWaitingTime==-1){
        return onCallScene(userModel.user!.isPassed!);
      }
      return getTaskList(userModel.currentPosition!);
    }
  }

  onCallScene(bool isPassed){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            Column(
              children: [
                const Icon(FontAwesomeIcons.mugHot,size: 28,),
                const SizedBox(height: 5,),
                const Text('??????????????????'),
                (!isPassed)? const Text('(???????????????????????????????????????)'):Container(),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );

  }

  getTaskList(Position currentPosition){
    return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: myCases.length,
            itemBuilder: (BuildContext context,int i){
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary, width: 1),
                    borderRadius: BorderRadius.circular(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('???????????????${myCases[i].shipState!}'),
                    Center(child: Text('?????????$_taskWaitingTime ???')),
                    Row(children: [
                      Container(
                        margin:const EdgeInsets.fromLTRB(0,4,8,0),
                        padding:const EdgeInsets.symmetric(vertical: 2,horizontal: 8),
                        decoration:BoxDecoration(
                          border: Border.all(color: AppColor.primary, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('??????',style: TextStyle(color: AppColor.primary),),
                      ),
                      if(currentPosition!=null)Text('?????? ${getDistance(myCases[i], currentPosition)}'),
                    ],),
                    Text('?????????????????????${_getExpectTimeString(myCases[i].expectSecond! + 120)}'),
                    Text('????????????${myCases[i].onAddress}'),
                    (myCases[i].offAddress!="")?Text('????????????${myCases[i].offAddress}'):Container(),
                    // (myCases[i].memo!="")?Text('?????????${myCases[i].memo}'):Container(),
                    const SizedBox(height: 10,),
                    CustomElevatedButton(
                        onPressed: (){
                          var userModel = context.read<UserModel>();
                          _putCaseConfirm(userModel.token!, myCases[i]);
                          myCases.removeAt(i);
                          // ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????~~')));
                        },
                        title: '??????'),
                    CustomElevatedButton(
                        onPressed: (){
                          var userModel = context.read<UserModel>();
                          _putCaseRefuse(userModel.token!, myCases[i]);
                          myCases.removeAt(i);
                        },
                        title: '??????',
                        color: AppColor.red)
                  ],),);
            });
  }

  String _getExpectTimeString(int seconds){
    int integer = seconds ~/ 60;
    int remainder = seconds % 60;
    if (integer == 0){
      return '???????????? $remainder ???';
    }else{
      return '???????????? $integer ??? $remainder ???';
    }
  }

  String getDistance(Case theCase, Position currentPosition){
    double distance = Geolocator.distanceBetween(currentPosition.latitude, currentPosition.longitude, double.parse(theCase.onLat!), double.parse(theCase.onLng!));
    if(distance > 1000){
      distance = distance / 1000;
      return distance.toStringAsFixed(2) + " ??????";
    }else{
      return distance.toStringAsFixed(0) + " ??????";
    }
  }

  offlineScene(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            Column(
              children: const [
                Icon(Icons.bolt_outlined,size: 40,),
                Text('??????????????????~'),
              ],),
            const SizedBox(height: 50),

          ],
        ),
      ),
    );
  }

  Future<AudioPlayer> _playLocalAsset() async {
    AudioCache cache = AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("ding_dong.mp3");
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }
    return true;
  }

  Future<Position> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      // return;
    }

    print('getting position');
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    print(position);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: 'zh-TW');
    if(placemarks.isNotEmpty){
      String output = placemarks[0].subAdministrativeArea.toString() + placemarks[0].locality.toString() + placemarks[0].street.toString();
      print(output);
    }else{
      print('empty place mark');
    }

    return position;

  }

  Future _fetchUpdateLatLng(String token, double lat, double lng) async {
    String path = ServerApi.PATH_UPDATE_LAT_LNG;
    final queryParameters = {
      'lat': lat.toString(),
      'lng': lng.toString(),
    };

    try {
      final response = await http.get(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      print(response.body);

      // List body = json.decode(utf8.decode(response.body.runes.toList()));
      // print(body);

    } catch (e) {
      print(e);
    }
  }

  Future _fetchCases(String token) async {
    String path = ServerApi.PATH_GET_CASES;
    print(token);
    try {
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      // print(response.body);
      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      List body = map["cases"];

      var userModel = context.read<UserModel>();
      userModel.user!.leftMoney = map["left_money"];

      // ?????? left money < -100, ????????????
      if(map["left_money"]<= -100){
        actionOffline();
      }else{
        List<Case> cases = body.map((value) => Case.fromJson(value)).toList();
        if(myCases.isEmpty && cases.isNotEmpty){
          _playLocalAsset();
        }

        myCases = cases;

        if(myCases.isNotEmpty && _taskTimer==null){
          int currentTime = myCases.first.countdownSecond!;
          if(currentTime==16){
            currentTime = 15;
          }
          _startTaskTimer(currentTime);
        }
      }

      setState(() {});

    } catch (e) {
      print(e);
    }
  }

  Future _putCaseConfirm(String token, Case theCase) async {
    print("case confirm");

    String path = ServerApi.PATH_CASE_CONFIREM;

    try {
      final queryParameters = {
        'case_id': theCase.id!.toString(),
      };

      final response = await http.put(
          ServerApi.standard(path: path, queryParameters: queryParameters),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      if(map['message']=='ok'){
        if(_timer!=null){
          print('cancel timer');
          _timer!.cancel();
          _timer = null;
        }
        if(_taskTimer!=null) {
          print('cancel task timer');
          _taskTimer!.cancel();
          _taskTimer=null;
        }

        var taskModel = context.read<TaskModel>();
        taskModel.cases.add(theCase);
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const CurrentTask()));

        var userModel = context.read<UserModel>();
        if (userModel.isOnline && _timer == null){
          print('start timer');
          _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
            _fetchCases(userModel.token!);
          });
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????????????????????????????')));
      }

      setState(() {});
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????????????????????????????')));
      // return "error";
    }
  }

  Future _putCaseRefuse(String token, Case theCase) async {
    print("case confirm");

    String path = ServerApi.PATH_CASE_REFUSE;

    try {
      final queryParameters = {
        'case_id': theCase.id!.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      if(map['message']=='ok'){
        if(_taskTimer!=null) {
          print('cancel task timer');
          _taskTimer!.cancel();
          _taskTimer=null;
        }
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('???????????????????????????')));
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????????????????????????????')));
      }

      setState(() {});
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('?????????????????????????????????')));
      // return "error";
    }
  }

  Future _putUpdateOnlineState(String token, bool isOnline) async{
    String path = ServerApi.PATH_UPDATE_ONLINE_STATE;

    try {

      Map bodyParameters = {
        'is_online': isOnline.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
          body: jsonEncode(bodyParameters)
      );

      _isOnlining = false;

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        print("success update online state!");
        if(isOnline){
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('????????????')));
          var userModel = context.read<UserModel>();
          setState(() {
            userModel.isOnline = true;
          });
          return "ok";
        }else{
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('????????????')));
          var userModel = context.read<UserModel>();
          setState(() {
            userModel.isOnline = false;
          });
          return "ok";
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('???????????????????????????')));
        return "error";
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future _getDeviceInfo() async {
    var userModel = context.read<UserModel>();
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) { // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      String deviceID = iosDeviceInfo.identifierForVendor!;
      print(deviceID);
      userModel.deviceId = deviceID;
      userModel.platformType = 'ios';
      // setState(() {});
      _httpPostFCMDevice();
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      String deviceID =  androidDeviceInfo.device;
      print(deviceID);
      userModel.deviceId = deviceID;
      userModel.platformType = 'android';
      // setState(() {});
      _httpPostFCMDevice();
    }
  }

  Future<void> _initPackageInfo() async {
    //???????????? app ??????
    var userModel = context.read<UserModel>();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    userModel.setCurrentAppVersion(packageInfo.version);
    userModel.setCurrentAppVersionNumber(int.parse(packageInfo.buildNumber));
    print('----------');
    print(userModel.currentAppVersion);
    print(userModel.currentAppVersionNumber);
    print('----------');
  }

  Future<void> _httpPostFCMDevice() async {
    print("postFCMDevice");
    String path = ServerApi.PATH_REGISTER_DEVICE;
    var userModel = context.read<UserModel>();

    try {
      Map queryParameters = {
        'registration_id': userModel.fcmToken,
        'device_id': userModel.deviceId,
        'type': userModel.platformType,
      };

      print(userModel.fcmToken);
      print(userModel.deviceId);
      print(userModel.platformType);
      print(userModel.token);

      final response = await http.post(ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token ${userModel.token!}',
        },
        body: jsonEncode(queryParameters),
      );

      print(response.body);

    }catch(e){
      print(e);
    }
  }

  Future _getLatestAppVersion () async {
    String path = ServerApi.PATH_GET_CURRENT_VERSION;
    try {
      final response = await http.get(ServerApi.standard(path: path));
      if (response.statusCode == 200){
        Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

        var userModel = context.read<UserModel>();
        if(userModel.platformType!=null && userModel.currentAppVersion != null){
          if(userModel.platformType=='ios' && userModel.currentAppVersionNumber! < int.parse(map['ios'])){
            return showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => AlertDialog(
                contentPadding: const EdgeInsets.all(20),
                content: const Text('????????? App ????????????????????????'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    child: const Text('????????????'),
                    onPressed: ()async{
                      String app= 'appStore url';
                      Uri url = Uri.parse(app);
                      if (!await launchUrl(url)) {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                ],
              ),
            );
          }else if (userModel.platformType=='android' && userModel.currentAppVersionNumber! < int.parse(map['android'])){
            return showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => AlertDialog(
                contentPadding: const EdgeInsets.all(20),
                content: const Text('????????? App ????????????????????????'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    child: const Text('????????????'),
                    onPressed: ()async{
                      String app= 'google play url';
                      Uri url = Uri.parse(app);
                      if (!await launchUrl(url)) {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }

}



