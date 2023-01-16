import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_taxi_chinghsien/pages/register.dart';
import 'package:flutter_taxi_chinghsien/pages/task/new_passenger_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../color.dart';
import 'package:http/http.dart' as http;

import '../config/constant.dart';
import '../main.dart';
import '../models/user.dart';
import '../notifier_models/user_model.dart';

class LogIn extends StatefulWidget {
  const LogIn({Key? key}) : super(key: key);

  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> {

  Future<void> getAPNSToken() async {
    FirebaseMessaging.instance.requestPermission(
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      alert: true,
      badge: true,
      sound: true,
    );
    print('FlutterFire Messaging Example: Getting APNs token...');
    String? token = await FirebaseMessaging.instance.getAPNSToken();
    print('Got APNs token: $token');
    FirebaseMessaging.instance.getToken().then((token){
      print('the token: ' + token.toString());
      var userModel = context.read<UserModel>();
      userModel.fcmToken = token.toString();
    });
  }

  @override
  void initState() {
    super.initState();

    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      getAPNSToken();
    }else{
      FirebaseMessaging.instance.getToken().then((token){
        print('the token: ' + token.toString());
        var userModel = context.read<UserModel>();
        userModel.fcmToken = token.toString();
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      print(event.notification!.body);
      _playLocalAsset();
      showDialog(context: context, builder: (_) {
        return NewPassengerDialog();
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
      //here need to check again if the task still available
      showDialog(context: context, builder: (_) {
        return NewPassengerDialog();
      });
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: AppColor.yellow,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:[
          Column(
            children: const [
              Icon(FontAwesomeIcons.taxi, color: Colors.white,size: 50,),
              Text('聯合派車',style: TextStyle(color: Colors.white,fontSize: 40,fontWeight: FontWeight.bold),),
            ],
          ),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: const Color(0xFF00B900),
                      elevation: 0),
                  onPressed: (){
                    _lineSignIn(context);
                  },
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex:1, child:Container(
                          margin: const EdgeInsets.only(left: 10),
                          alignment: Alignment.centerLeft,
                          width: 40,
                          child: const Icon(FontAwesomeIcons.line),
                        )),
                        Expanded(flex:3, child:Container(child: const Text('使用 LINE 登入',textAlign: TextAlign.center,),)),
                        Expanded(flex:1, child:Container()),
                      ],
                    ),
                  ),
                ),
              ),
              const Text('免註冊，用 LINE 登入',style: TextStyle(color: Colors.white),),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _lineSignIn(BuildContext context) async {
    try {
      final result = await LineSDK.instance.login();
      String lineId = result.userProfile!.userId;

      //for test
      // String lineId = 'U695107477916e4f50d84d224ca6e4763';
      String token = await _getUserToken(lineId);

      // String displayName = result.userProfile!.displayName;
      // String email = '${lineId}@line.com';

      // String token = await _getUserToken("test");

      if(token != 'error'){
        User user = await _getUserData(token);

        if(user.phone!=null){
          var userModel = context.read<UserModel>();
          userModel.token = token;
          userModel.setUser(user);

          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('轉到首頁！')));

          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const MyHomePage()));
          Navigator.of(context).pushNamed('/main');
        }else{
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('搜索不到該使用者！')));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  Register(isEdit: false, lineId: lineId))
          );
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('轉到註冊頁！')));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  Register(isEdit: false, lineId: lineId))
        );
      }
    } on PlatformException catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('未成功取得 LINE 授權！')));
    }
  }

  Future<String> _getUserToken(String line_id) async {
    String path = Constant.PATH_USER_TOKEN;
    try {
      Map queryParameters = {
        'phone': '0000000000',
        'password': '00000',
        'line_id': line_id,
      };

      final response = await http.post(
          Constant.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(queryParameters)
      );

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['token']!=null){
        String token = map['token'];
        return token;
      }else{
        print(response.body);
        return "error";
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future<User> _getUserData(String token) async {
    String path = Constant.PATH_USER_DATA;
    try {
      final response = await http.get(
        Constant.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token ${token}',
        },
      );

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      // String phone = map['email'];
      // String name = map['name'];

      User theUser = User.fromJson(map);

      return theUser;
    } catch (e) {
      print(e);
      return User();
    }
  }

  Future<AudioPlayer> _playLocalAsset() async {
    AudioCache cache = AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("ding_dong.mp3");
  }

}
