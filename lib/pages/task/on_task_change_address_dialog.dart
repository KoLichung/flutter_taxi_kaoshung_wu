import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/color.dart';




class OnTaskChangeAddressDialog extends StatefulWidget {


  const OnTaskChangeAddressDialog({Key? key});

  @override
  _OnTaskChangeAddressDialogState createState() => new _OnTaskChangeAddressDialogState();
}

class _OnTaskChangeAddressDialogState extends State<OnTaskChangeAddressDialog> {

  TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 360,
        padding: const EdgeInsets.all(10),
        color: AppColor.yellow,
        child: const Text(
          '修改地址',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 30),
        child: TextField(
          controller: addressController,
          maxLines: 1,
          decoration:  const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              hintText: "輸入修改的地址",
          ),
        ),
      ),
      backgroundColor: AppColor.yellow,
      actions: <Widget>[
        OutlinedButton(
            child:const  Text('確定', style: TextStyle(color: Colors.white),),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              String address = addressController.text;
              print(address);
              Navigator.pop(context,address);
            }
        ),
      ],
    );
  }



}

