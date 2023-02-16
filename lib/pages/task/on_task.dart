import 'dart:async';
import 'dart:convert';

import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/home_page.dart';
import 'package:flutter_taxi_chinghsien/pages/task/on_task_change_address_dialog.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../fake_customer_model.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_small_elevated_button.dart';
import '../../widgets/custom_small_oulined_text.dart';
import 'on_task_passenger_off_dialog.dart';


class OnTask extends StatefulWidget {

  final Case theCase;

  const OnTask({Key? key, required this.theCase}) : super(key: key);

  @override
  _OnTaskState createState() => _OnTaskState();
}

class _OnTaskState extends State<OnTask> {

  bool isPassengerOnBoard = false;

  String taskStatus = '接客中';

  bool isStartCounting = false;

  bool isNextTaskVisible = false;

  TextEditingController priceController = TextEditingController();
  Timer? _taskTimer;

  String offAddress = "下車地址";

  String? userToken;

  bool isTimerButtonEnable = false;
  Timer? _buttonTimer;
  Duration _buttonTimerDuration = const Duration(minutes: 5);

  void startButtonTimer(){
    _buttonTimer = Timer.periodic(const Duration(seconds: 1), (_) => setButtonCountDown());
  }

  void stopButtonTimer() {
    setState((){
      _buttonTimer!.cancel();
      _buttonTimer = null;
    });
  }

  void resetButtonTimer() {
    stopButtonTimer();
    setState((){
      _buttonTimerDuration = const Duration(minutes: 5);
      isTimerButtonEnable = false;
    });
  }

  void setButtonCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = _buttonTimerDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        _buttonTimer!.cancel();
        isTimerButtonEnable = true;
      } else {
        _buttonTimerDuration = Duration(seconds: seconds);
      }
    });
  }


  @override
  void initState() {
    // TODO: implement initState
    // fetchNewTask();
    super.initState();
    var userModel = context.read<UserModel>();
    userToken = userModel.token!;

    _taskTimer = Timer.periodic(const Duration(seconds:10), (timer){
      if(isStartCounting) {
        // 10秒計算一次時間
        var taskModel = context.read<TaskModel>();
        taskModel.secondTotal = taskModel.secondTotal + 10;
        taskModel.setCurrentTaskPrice();

        if (taskModel.routePositions.isNotEmpty) {
          taskModel.lastFiveSecondPosition = taskModel.routePositions.last;
        }
      }
    });

    offAddress = widget.theCase.offAddress!;

    startButtonTimer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if(_taskTimer!=null){
      print('cancel onTask timer');
      _taskTimer!.cancel();
      _taskTimer = null;
    }

  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = strDigits(_buttonTimerDuration.inMinutes.remainder(60));
    String seconds = strDigits(_buttonTimerDuration.inSeconds.remainder(60));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            const Text('24h派車'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child:Consumer<TaskModel>(builder: (context, taskModel, child){
          return Column(
            children: [
              Consumer<TaskModel>(builder: (context, taskModel, child){
                if (taskModel.routePositions.isNotEmpty) {
                  return Text('目前的位置:${taskModel.routePositions.last.latitude.toStringAsFixed(3)}, ${taskModel.routePositions.last.longitude.toStringAsFixed(3)}');
                }else{
                  return const Text("尚未 update 位置");
                }
              }),
              Consumer<TaskModel>(builder: (context, taskModel, child){
                return Text('目前的 公里數:${taskModel.totalDistance.toStringAsFixed(3)}km, 所有秒數：${taskModel.secondTotal}秒');
              }),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary, width: 1),
                    borderRadius: BorderRadius.circular(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: '目前任務：',
                        style: const TextStyle(color: AppColor.primary, fontSize: 22,),
                        children: <TextSpan>[
                          TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                    //   child: Text('${widget.theCase.customerName}   ${widget.theCase.customerPhone}'),
                    // ),
                    const SizedBox(height: 10,),
                    RichText(
                      text: TextSpan(
                        text: '上車地：',
                        style: const TextStyle(color: AppColor.primary, fontSize: 20,),
                        children: <TextSpan>[
                          TextSpan(text: widget.theCase.onAddress,style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),//上車
                    Row(
                      children: [
                        const Text("下車地：", style:  TextStyle(color: AppColor.primary, fontSize: 20,)),
                        const SizedBox(width: 10,),
                        CustomSmallElevatedButton(
                            icon: const Icon(Icons.near_me_outlined,size: 16,),
                            title: '導航',
                            color: AppColor.primary,
                            onPressed: (){
                              // _launchMap(offAddress);
                              MapsLauncher.launchQuery(offAddress);
                            })
                      ],
                    ),
                    Text(offAddress, style: const TextStyle(color: Colors.black87,fontSize: 20)),
                    Row(
                      children: [
                        CustomSmallElevatedButton(
                            icon: const Icon(Icons.edit_outlined),
                            title: '修改下車地址',
                            color: AppColor.primary,
                            onPressed: ()async{
                              var data = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return OnTaskChangeAddressDialog();
                                  });
                              if(data!=null && data.toString()!=""){
                                setState(() {
                                  offAddress = data.toString();
                                });
                              }else{
                                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('下車地址不可為空白！')));
                              }
                            })
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            margin: const EdgeInsets.fromLTRB(0,10,10,10),
                            height: 40,
                            width: 82,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 1,),
                              borderRadius: BorderRadius.circular(4),),
                            child:
                            Consumer<TaskModel>(builder: (context, taskModel, child){
                              priceController.text = taskModel.currentTaskPrice.toString();
                              return TextFormField(
                                validator: (String? value) {
                                  return (value != null ) ? '此為必填欄位' : null;
                                },
                                controller: priceController,
                                onTap: (){
                                  if(_taskTimer!=null) {
                                    print('cancel onTask timer');
                                    _taskTimer!.cancel();
                                    _taskTimer = null;
                                  }
                                },
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  prefixIconConstraints: BoxConstraints(minWidth: 10, maxHeight: 20),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.fromLTRB(4,2,2,0),
                                    child: Icon(
                                      Icons.attach_money_rounded,
                                      color: Colors.black,
                                    ),
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              );
                            })),
                      ],
                    ),
                    const Text('(僅供參考，請依實際車資輸入)',style: TextStyle(color: AppColor.red),),
                    const SizedBox(height: 20),

                    // (isStartCounting) ?
                    // CustomElevatedButton(
                    //     onPressed: (){
                    //       var userModel = context.read<UserModel>();
                    //       _putCaseFinish(userModel.token!, widget.theCase.id!, offAddress, int.parse(priceController.text));
                    //     },
                    //     title: '乘客下車')
                    // :
                    // CustomElevatedButton(
                    //     onPressed: (){
                    //       isStartCounting = true;
                    //       setState(() {});
                    //     },
                    //     title: '開始跳錶計費'
                    // ),

                    !isPassengerOnBoard ?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomElevatedButton(
                            onPressed: (){
                              setState(() {
                                taskStatus = '載客中';
                                isPassengerOnBoard = true;
                                stopButtonTimer();
                                // _putCaseCatched(userToken!, taskModel.cases.first);
                              });
                            },
                            title: '乘客已上車'),
                        ElevatedButton(
                            onPressed: isTimerButtonEnable
                                ? () {
                                    resetButtonTimer();
                                    startButtonTimer();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isTimerButtonEnable ? AppColor.primary : Colors.grey,
                                elevation: 0
                            ),
                            child: SizedBox(
                              height: 46,
                              width: 185,
                              child: Align(
                                child:
                                isTimerButtonEnable
                                    ? const Text('乘客未上車 05:00',style: TextStyle(fontSize: 20),)
                                    : Row(
                                        children: [
                                          const Text('乘客未上車 ',style: TextStyle(fontSize: 20),),
                                          Text('$minutes:$seconds',style: const TextStyle(fontSize: 20),),
                                        ],
                                      ),
                                alignment: Alignment.center,
                              ),
                            )
                        ),
                      ],
                    )
                        :
                    CustomElevatedButton(
                        onPressed: (){
                          var userModel = context.read<UserModel>();
                          // _putCaseFinish(userModel.token!, widget.theCase.id!, offAddress, int.parse(priceController.text));
                          showDialog<String>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                return OnTaskPassengerOffDialog();
                              });
                        },
                        title: '乘客下車'
                    ),
                  ],
                ),
              )
            ],
          );
        })
      ),
    );
  }

  //乘客上車了
  Future _putCaseCatched(String token, Case theCase) async {
    String path = ServerApi.PATH_CASE_CATCHED;

    try {
      // Map queryParameters = {
      //   'phone': user.phone,
      // };

      final queryParameters = {
        'case_id': theCase.id.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        // body: jsonEncode(queryParameters)
      );

      print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        var taskModel = context.read<TaskModel>();
        taskModel.isOnTask = true;
        Navigator.push(context, MaterialPageRoute(builder: (context) => OnTask(theCase: theCase)));
        setState(() {});
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }

    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future _putCaseFinish(String token, int caseId, String offAddress, int caseMoney) async {
    String path = ServerApi.PATH_CASE_FINISH;

    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      Map bodyParams = {
        'off_address': offAddress,
        'case_money': caseMoney,
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(bodyParams)
      );

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        var taskModel = context.read<TaskModel>();
        taskModel.resetTask();
        print('here on task finish');
        print(taskModel.cases);
        if(_taskTimer!=null){
          print('cancel onTask timer');
          _taskTimer!.cancel();
          _taskTimer = null;
        }
        if(taskModel.cases.isEmpty) {
          Navigator.popUntil(context, ModalRoute.withName('/main'));
        }else{
          Navigator.pop(context);
        }

      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }

    } catch (e) {
      print(e);
      return "error";
    }
  }

  // void _launchMap(String address) async {
  //   String query = Uri.encodeComponent(address);
  //   String googleUrl = "https://www.google.com/maps/search/?api=1&query=$query";
  //   Uri googleUri = Uri.parse(googleUrl);
  //
  //   if (await canLaunchUrl(googleUri)) {
  //     await launchUrl(googleUri);
  //   }
  // }

}




