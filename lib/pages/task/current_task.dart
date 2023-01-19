import 'dart:convert';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/current_task_report_dialog.dart';
import 'package:http/http.dart' as http;


import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../fake_customer_model.dart';
import '../../color.dart';
import 'package:provider/provider.dart';

import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_small_elevated_button.dart';
import '../../widgets/custom_small_oulined_text.dart';
import 'new_passenger_dialog.dart';
import 'on_task.dart';

class CurrentTask extends StatefulWidget {

  const CurrentTask({Key? key}) : super(key: key);

  @override
  _CurrentTaskState createState() => _CurrentTaskState();
}

class _CurrentTaskState extends State<CurrentTask> {


  String buttonText = '抵達乘客上車地點';
  bool isPassengerOnBoard = false;

  String taskStatus = '接客中';

  bool isNextTaskVisible = false;

  String? userToken;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchNewTask();
    var userModel = context.read<UserModel>();
    userToken = userModel.token!;
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
        child:Consumer<TaskModel>(builder: (context, taskModel, child){
          return Column(
            children: [
              // current task
              Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColor.primary, width: 1),
                      borderRadius: BorderRadius.circular(3)),
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: '目前任務：',
                              style: const TextStyle(color: Colors.black87, fontSize: 18,),
                              children: <TextSpan>[
                                TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            child: const CustomSmallOutlinedText(
                                title: '問題回報',
                                color: AppColor.primary),
                            onTap: () async {
                              var data = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CurrentTaskReportDialog();
                                  });
                              if(data.toString()!=""){
                                print(userToken!);
                                print(data.toString());
                                _putCaseCanceled(userToken!, data.toString(), taskModel.cases.first.id!);
                              }else{
                                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('問題回報不可為空白！')));
                              }

                            },),
                        ],
                      ),
                      // Container(
                      //   margin: const EdgeInsets.fromLTRB(0,15,0,10),
                      //   child: Row(
                      //     children: [
                      //       Text('上車地：${widget.theCase.onAddress}'),
                      //       const SizedBox(width: 10),
                      //       CustomSmallElevatedButton(
                      //           icon: const Icon(Icons.near_me_outlined,size: 16,),
                      //           title: '導航',
                      //           color: AppColor.primary,
                      //           onPressed: (){
                      //             _launchMap(widget.theCase.onAddress!);
                      //           })
                      //     ],
                      //   ),
                      // ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,10,0,0),
                        child: Row(
                          children: [
                            Text('上車地：'),
                            CustomSmallElevatedButton(
                                icon: const Icon(Icons.near_me_outlined,size: 16,),
                                title: '導航',
                                color: AppColor.primary,
                                onPressed: (){
                                  // _launchMap(widget.theCase.onAddress!);
                                  MapsLauncher.launchQuery(taskModel.cases.first.onAddress!);
                                })
                          ],
                        ),
                      ),
                      // Container(
                      //   margin: const EdgeInsets.fromLTRB(0,15,0,0),
                      //   child: Text('上車地：'),
                      // ),
                      Container(
                        child: Text('${taskModel.cases.first.onAddress}'),
                      ),

                      // Container(
                      //   margin: const EdgeInsets.fromLTRB(0,10,0,0),
                      //   child: const Text('乘客：'),
                      //   ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,10,0,0),
                        child: Row(
                          children: [
                            const Text('乘客：'),
                            const SizedBox(width: 10),
                            CustomSmallElevatedButton(
                                icon: const Icon(Icons.call_outlined,size: 16,),
                                title: '電話',
                                color: AppColor.primary,
                                onPressed: (){
                                  Uri uri = Uri.parse("tel://${taskModel.cases.first.customerPhone}");
                                  launchUrl(uri);
                                })
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,0,0,10),
                        child: Row(
                          children: [
                            Text(taskModel.cases.first.customerName!),
                            const SizedBox(width: 10),
                            Text('${taskModel.cases.first.customerPhone}'),
                          ],
                        ),
                      ),
                      (taskModel.cases.first.memo!="")?Text('備註：${taskModel.cases.first.memo}'):Container(),
                      CustomElevatedButton(
                          onPressed: (){
                            if(buttonText=='抵達乘客上車地點'){
                              buttonText='乘客已上車';
                              _putCaseArrived(userToken!, taskModel.cases.first.id!);
                            }else{
                              buttonText='抵達乘客上車地點';
                              _putCaseCatched(userToken!, taskModel.cases.first);
                            }
                          },
                          title: buttonText)
                    ],
                  )
              ),
              // next task
              (taskModel.cases.length>1)?
              Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColor.primary, width: 1),
                      borderRadius: BorderRadius.circular(3)),
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: '下個任務：',
                              style: const TextStyle(color: Colors.black87, fontSize: 18,),
                              children: <TextSpan>[
                                TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,10,0,0),
                        child: Row(
                          children: [
                            Text('上車地：'),
                            CustomSmallElevatedButton(
                                icon: const Icon(Icons.near_me_outlined,size: 16,),
                                title: '導航',
                                color: AppColor.primary,
                                onPressed: (){
                                  // _launchMap(widget.theCase.onAddress!);
                                  MapsLauncher.launchQuery(taskModel.cases[1].onAddress!);
                                })
                          ],
                        ),
                      ),
                      Container(
                        child: Text('${taskModel.cases[1].onAddress}'),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,10,0,0),
                        child: Row(
                          children: [
                            const Text('乘客：'),
                            const SizedBox(width: 10),
                            CustomSmallElevatedButton(
                                icon: const Icon(Icons.call_outlined,size: 16,),
                                title: '電話',
                                color: AppColor.primary,
                                onPressed: (){
                                  Uri uri = Uri.parse("tel://${taskModel.cases[1].customerPhone}");
                                  launchUrl(uri);
                                })
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0,0,0,10),
                        child: Row(
                          children: [
                            Text(taskModel.cases[1].customerName!),
                            const SizedBox(width: 10),
                            Text('${taskModel.cases[1].customerPhone}'),
                          ],
                        ),
                      ),
                      (taskModel.cases[1].memo!="")?Text('備註：${taskModel.cases[1].memo}'):Container(),
                    ],
                  )
              )
                  :
              Container()
            ],
          );
        }),
      ),
    );

  }

  Future _putCaseArrived(String token, int caseId) async {
    String path = ServerApi.PATH_CASE_ARRIVE;

    try {
      // Map queryParameters = {
      //   'phone': user.phone,
      // };

      final queryParameters = {
        'case_id': caseId.toString(),
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
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => OnTask(theCase: widget.theCase)));
        setState(() {});
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }

    } catch (e) {
      print(e);
      return "error";
    }
  }

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

  Future _putCaseCanceled(String token, String memo, int caseId) async {
    String path = ServerApi.PATH_CASE_CANCEL;

    try {
      final bodyParams = {
        'memo': memo,
      };

      final queryParameters = {
        'case_id': caseId.toString(),
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
        if(taskModel.cases.isEmpty) {
          Navigator.popUntil(context, ModalRoute.withName('/main'));
        }else{
          setState(() {});
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }

    } catch (e) {
      print(e);
      return "error";
    }
  }

  void _launchMap(String address) async {
    String query = Uri.encodeComponent(address);
    String googleUrl = "https://www.google.com/maps/search/?api=1&query=$query";
    Uri googleUri = Uri.parse(googleUrl);

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri);
    }
  }

}




