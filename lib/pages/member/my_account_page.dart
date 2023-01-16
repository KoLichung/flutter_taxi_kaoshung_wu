import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_taxi_chinghsien/config/constant.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_member_button.dart';
import '../register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {

  @override
  Widget build(BuildContext context) {
    var userModel = context.read<UserModel>();

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(FontAwesomeIcons.taxi),
              Text(' 聯合派車'),
            ],
          ),
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(0,10,10,10),
          //     child: IconButton(
          //         onPressed: (){},
          //         icon: const Icon(Icons.notifications_outlined)),)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20,20,15,0),
                child:
                Row(
                  children: [
                    const Text('姓名：', style: TextStyle(fontSize: 18),),
                    Text(userModel.user.name!, style: TextStyle(fontSize: 18),),
                ],),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20,0,15,10),
                child: Row(
                  children: [
                    Text('狀態：', style: TextStyle(fontSize: 18),),
                    (userModel.user.isPassed!)?
                    Text('登入中', style: TextStyle(fontSize: 18))
                    :
                    Text('登入中(尚未通過審核)', style: TextStyle(fontSize: 18)),
                  ]
                ),
              ),
              const Divider(
                color: Colors.black54,
                thickness: 1,
              ),
              CustomMemberPageButton(
                title: '基本資料',
                onPressed: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Register(isEdit: true, lineId: ""))
                  );
                },
              ),
              CustomMemberPageButton(
                title: '儲值紀錄',
                onPressed: (){
                  Navigator.pushNamed(context, '/money_record');
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30,vertical: 20),
                child: CustomElevatedButton(
                  title: '登出',
                  onPressed: () async {
                    // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyHomePage()), (Route<dynamic> route) => false, );
                    print('here');
                    _lineLogOut();
                    _putUpdateOnlineState(userModel.token!, false);
                    userModel.token = null;
                    userModel.removeUser(context);
                    userModel.resetPositionParams();
                    if(userModel.positionStreamSubscription!=null){
                      print("not null positionStreamSubscription");
                      userModel.positionStreamSubscription!.pause();
                      userModel.positionStreamSubscription!.cancel();
                      userModel.positionStreamSubscription = null;
                    }
                    Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                  },
                ),
              ),
              const SizedBox(height: 20,)
            ],
          ),
        ));
  }

  Future<void> _lineLogOut() async {
    try {
      await LineSDK.instance.logout();
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  Future _putUpdateOnlineState(String token, bool isOnline) async{
    String path = Constant.PATH_UPDATE_ONLINE_STATE;

    try {

      Map bodyParameters = {
        'is_online': isOnline.toString(),
      };

      final response = await http.put(
          Constant.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
          body: jsonEncode(bodyParameters)
      );

      print(response.body);
      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        print("success update online state!");
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }


}

