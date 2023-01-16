import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../config/constant.dart';
import '../models/user.dart';
import '../notifier_models/user_model.dart';
import '../widgets/custom_elevated_button.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {

  final String lineId;
  final bool isEdit;
  const Register({Key? key, required this.isEdit, required this.lineId}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

enum DriverGender { male, female }
enum CarType { car, suv, sport, van}
enum CarCategory { taxi, various, rental, white }


class _RegisterState extends State<Register> {

  final _formKey = GlobalKey<FormState>();

  TextEditingController driverNameController = TextEditingController();
  TextEditingController idLast5NumberController = TextEditingController();
  TextEditingController carPlateController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController idNumberController = TextEditingController();
  TextEditingController carModelController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  TextEditingController seatNumberController = TextEditingController();

  DriverGender? _driverGender = DriverGender.male;
  CarType? _carType = CarType.car;
  CarCategory? _carCategory = CarCategory.taxi;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.isEdit){
      var userModel = context.read<UserModel>();
      User user = userModel.user;

      driverNameController.text = user.name!;
      idLast5NumberController.text = user.userId!;
      carPlateController.text = user.vehicalLicence!;
      phoneNumberController.text  = user.phone!;
      idNumberController.text = user.idNumber!;
      carModelController.text = user.carModel!;
      carColorController.text = user.carColor!;
      seatNumberController.text = user.numberSites!.toString();

      if(user.gender == '女'){
        _driverGender = DriverGender.female;
      }
      if(user.type == 'suv'){
        _carType = CarType.suv;
      }else if(user.type == 'sports_car'){
        _carType = CarType.sport;
      }else if(user.type == 'van'){
        _carType = CarType.van;
      }
      if(user.category == 'diversity'){
        _carCategory = CarCategory.various;
      }else if(user.category == 'rental_car'){
        _carCategory = CarCategory.rental;
      }else if(user.category == 'x_card'){
        _carCategory = CarCategory.white;
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: (widget.isEdit)?true:false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(FontAwesomeIcons.taxi),
              Text('聯合派車-基本資料'),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20,),
                validatorTextFormField('*真實姓名','',driverNameController),
                validatorTextFormField('*手機號碼','',phoneNumberController),
                validatorTextFormField('*身份字號','',idNumberController),
                validatorTextFormField('*台號(身分證後五碼)','',idLast5NumberController),
                getDriverGender(),
                validatorTextFormField('*車號(ABC-123)','',carPlateController),
                getCarType(),
                getCarCategory(),
                registerTextField('車型','Toyota Wish',carModelController),
                registerTextField('顏色','白',carColorController),
                registerTextField('座位數','4',seatNumberController),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30,vertical: 20),
                  child: CustomElevatedButton(
                    title: '儲存回到首頁',
                    onPressed: (){
                        if (_formKey.currentState!.validate()) {
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //       backgroundColor: Colors.black26,
                          //       content: Text('資料填寫成功')),
                          // );
                          var userModel = context.read<UserModel>();
                          User user = userModel.user;
                          user.name = driverNameController.text;
                          user.phone = phoneNumberController.text;
                          user.userId = idLast5NumberController.text;
                          user.vehicalLicence = carPlateController.text;
                          user.idNumber = idNumberController.text;
                          if(_driverGender == DriverGender.male){
                            user.gender = '男';
                          }else{
                            user.gender = '女';
                          }
                          if(_carType == CarType.car){
                            user.type = 'car';
                          }else if(_carType == CarType.suv){
                            user.type = 'suv';
                          }else if(_carType == CarType.sport){
                            user.type = 'sports_car';
                          }else if(_carType == CarType.van){
                            user.type = 'van';
                          }
                          if(_carCategory == CarCategory.taxi){
                            user.category = 'taxi';
                          }else if(_carCategory == CarCategory.various){
                            user.category = 'diversity';
                          }else if(_carCategory == CarCategory.rental){
                            user.category = 'rental_car';
                          }else if(_carCategory == CarCategory.white){
                            user.category = 'x_card';
                          }
                          user.carModel = carModelController.text;
                          user.carColor = carColorController.text;
                          if(seatNumberController.text!='') {
                            user.numberSites = int.parse(seatNumberController.text);
                          }else{
                            user.numberSites = 4;
                          }

                          if(widget.isEdit) {
                            _putUpdateUserData(userModel.token!, user, user.isOnline!);
                          }else{
                            _postCreateUser(user, widget.lineId);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('註冊中，請稍待~')));
                          }
                          // Navigator.pushAndRemoveUntil(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => const MyHomePage()), (Route<dynamic> route) => false, );
                        }},
                  ),
                ),
                const SizedBox(height: 250)
              ],
            ),
          ),
        ));
  }

  validatorTextFormField(String title, String hintText, TextEditingController controller){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Container(
            margin: const  EdgeInsets.symmetric(vertical: 2),
            height: 62,
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '此欄必填';
                }
                return null;
              },
              style: const TextStyle(fontSize: 18),
              controller: controller,
              decoration: const InputDecoration(
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1.0),),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1.0),),
                errorStyle: TextStyle(
                  height: 1,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 13,vertical: 10),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54, width: 1,),),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54, width: 1,),)
            ),
          ),
          )
        ],),
    );
  }

  registerTextField(String title, String hintText, TextEditingController controller){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Container(
            margin: const  EdgeInsets.symmetric(vertical: 6),
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black54,
                width: 1,),
              borderRadius: BorderRadius.circular(4),),
            child: TextField(
              style: const TextStyle(fontSize: 18),
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 13,vertical: 10),
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],),
    );
  }

  getDriverGender(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('性別',style: TextStyle(height: 1.8),),
          Row(
            children: [
              Radio<DriverGender>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: DriverGender.male,
                groupValue: _driverGender,
                onChanged: (DriverGender? value){
                  setState(() {
                    _driverGender = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('男'),
              const SizedBox(width: 20,),
              Radio<DriverGender>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: DriverGender.female,
                groupValue: _driverGender,
                onChanged: (DriverGender? value){
                  setState(() {
                    _driverGender = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('女')
            ],
          ),
        ],
      ),
    );
  }

  getCarType(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('車種',style: TextStyle(height: 1.8),),
          Row(
            children: [
              Radio<CarType>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarType.car,
                groupValue: _carType,
                onChanged: (CarType? value){
                  setState(() {
                    _carType = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('轎車'),
              const SizedBox(width: 10,),
              Radio<CarType>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarType.suv,
                groupValue: _carType,
                onChanged: (CarType? value){
                  setState(() {
                    _carType = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('休旅車'),
              const SizedBox(width: 10,),
              Radio<CarType>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarType.sport,
                groupValue: _carType,
                onChanged: (CarType? value){
                  setState(() {
                    _carType = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('跑車'),
              const SizedBox(width: 10,),
              Radio<CarType>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarType.van,
                groupValue: _carType,
                onChanged: (CarType? value){
                  setState(() {
                    _carType = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('箱型車')
            ],
          ),
        ],),
    );
  }

  getCarCategory(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15,vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('類別',style: TextStyle(height: 1.8),),
          Row(
            children: [
              Radio<CarCategory>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarCategory.taxi,
                groupValue: _carCategory,
                onChanged: (CarCategory? value){
                  setState(() {
                    _carCategory = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('計程車'),
              const SizedBox(width: 10,),
              Radio<CarCategory>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarCategory.various,
                groupValue: _carCategory,
                onChanged: (CarCategory? value){
                  setState(() {
                    _carCategory = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('多元'),
              const SizedBox(width: 10,),
              Radio<CarCategory>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarCategory.rental,
                groupValue: _carCategory,
                onChanged: (CarCategory? value){
                  setState(() {
                    _carCategory = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('租賃車'),
              const SizedBox(width: 10,),
              Radio<CarCategory>(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                ),
                value: CarCategory.white,
                groupValue: _carCategory,
                onChanged: (CarCategory? value){
                  setState(() {
                    _carCategory = value;
                  });
                },
                activeColor: Colors.black54,
              ),
              const Text('X牌')
            ],
          ),
        ],
      ),
    );
  }

  Future _putUpdateUserData(String token, User user, bool isOnline) async {
    String path = Constant.PATH_USER_DATA;

    print(token);
    print(user.phone);

    try {
      Map queryParameters = {
        'phone': user.phone,
        'name': user.name,
        'vehicalLicence': user.vehicalLicence,
        'userId': user.userId,
        'idNumber': user.idNumber,
        'gender': user.gender,
        'type': user.type,
        'category': user.category,
        'car_model': user.carModel,
        'car_color': user.carColor,
        'number_sites': user.numberSites,
        'is_online': isOnline,
      };

      final response = await http.put(
          Constant.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
          body: jsonEncode(queryParameters)
      );

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      User theUser = User.fromJson(map);

      var userModel = context.read<UserModel>();
      userModel.setUser(theUser);

      Navigator.pop(context);
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future _postCreateUser(User user, String lineId) async{
    String path = Constant.PATH_CREATE_USER;

    // try {
      Map queryParameters = {
        'phone': user.phone,
        'name': user.name,
        'vehicalLicence': user.vehicalLicence,
        'userId': user.userId,
        'idNumber': user.idNumber,
        'gender': user.gender,
        'type': user.type,
        'category': user.category,
        'car_model': user.carModel,
        'car_color': user.carColor,
        'number_sites': user.numberSites,
        'line_id': lineId,
        'password': "00000",
      };

      final response = await http.post(
          Constant.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            // 'Authorization': 'Token $token',
          },
          body: jsonEncode(queryParameters)
      );

      print(response.statusCode);
      print(response.body);

      if(response.statusCode == 201) {
        Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
        User theUser = User.fromJson(map);

        String token = await _getUserToken(lineId);

        var userModel = context.read<UserModel>();
        userModel.setUser(theUser);
        userModel.token = token;

        Navigator.of(context).pushNamed('/main');
      }else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未成功註冊~')));
      }
    // } catch (e) {
    //   print(e);
    //   return "error";
    // }

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

}

