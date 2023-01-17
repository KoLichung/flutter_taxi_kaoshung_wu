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


class OnTask extends StatefulWidget {

  final Case theCase;

  const OnTask({Key? key, required this.theCase}) : super(key: key);

  @override
  _OnTaskState createState() => _OnTaskState();
}

class _OnTaskState extends State<OnTask> {

  String buttonText = '抵達乘客上車地點';
  bool isPassengerOnBoard = false;

  String taskStatus = '載客中';

  bool isNextTaskVisible = false;

  TextEditingController priceController = TextEditingController();
  Timer? _taskTimer;

  String offAddress = "下車地址";

  @override
  void initState() {
    // TODO: implement initState
    // fetchNewTask();
    super.initState();

    _taskTimer = Timer.periodic(const Duration(seconds:5), (timer){
      var taskModel = context.read<TaskModel>();
      // 2.5 m/s ~ 9km/hr
      if (
         taskModel.currentVelocity.isNaN ||
         (taskModel.currentVelocity <=2.5 && taskModel.currentVelocity >=0) ||
         (taskModel.lastFiveSecondPosition!=null && taskModel.lastFiveSecondPosition == taskModel.routePositions.last)
      ){
        taskModel.secondIdle = taskModel.secondIdle + 5;
      }
      taskModel.setCurrentTaskPrice();
      if(taskModel.routePositions.isNotEmpty) {
        taskModel.lastFiveSecondPosition = taskModel.routePositions.last;
      }
    });

    offAddress = widget.theCase.offAddress!;
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(FontAwesomeIcons.taxi),
            SizedBox(width: 10,),
            Text('24h派車'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<TaskModel>(builder: (context, taskModel, child){
              if (taskModel.routePositions.isNotEmpty) {
                return Text('目前的位置:${taskModel.routePositions.last.latitude.toStringAsFixed(3)}, ${taskModel.routePositions.last.longitude.toStringAsFixed(3)}');
              }else{
                return const Text("尚未 update 位置");
              }
            }),
            Consumer<TaskModel>(builder: (context, taskModel, child){
                    return Text('目前的 公里數:${taskModel.totalDistance.toStringAsFixed(3)}km, 怠速秒數：${taskModel.secondIdle}秒');
            }),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColor.yellow, width: 1),
                  borderRadius: BorderRadius.circular(3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '目前任務：',
                      style: const TextStyle(color: AppColor.yellow, fontSize: 22,),
                      children: <TextSpan>[
                        TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('${widget.theCase.customerName}   ${widget.theCase.customerPhone}'),
                  ),
                  RichText(
                    text: TextSpan(
                      text: '上車：',
                      style: const TextStyle(color: AppColor.yellow, fontSize: 20,),
                      children: <TextSpan>[
                        TextSpan(text: widget.theCase.onAddress,style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),//上車
                  Row(
                    // children: [
                    //   RichText(
                    //     text: TextSpan(
                    //       text: '下車：',
                    //       style: const TextStyle(color: AppColor.yellow, fontSize: 20,),
                    //       children: <TextSpan>[
                    //         TextSpan(text: offAddress,style: const TextStyle(color: Colors.black87,fontSize: 20)),
                    //       ],
                    //     ),
                    //   ),
                    children: [
                      const Text("下車：", style:  TextStyle(color: AppColor.yellow, fontSize: 20,)),
                      const SizedBox(width: 10,),
                      CustomSmallElevatedButton(
                          icon: const Icon(Icons.near_me_outlined,size: 16,),
                          title: '導航',
                          color: AppColor.yellow,
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
                          color: AppColor.yellow,
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
                  CustomElevatedButton(
                      onPressed: (){
                        var userModel = context.read<UserModel>();
                        _putCaseFinish(userModel.token!, widget.theCase.id!, offAddress, int.parse(priceController.text));
                      },
                      title: '乘客下車')
                ],
              ),
            )
          ],
        ),
      ),
    );
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




