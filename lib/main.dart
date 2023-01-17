import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_taxi_chinghsien/pages/log_in.dart';
import 'package:flutter_taxi_chinghsien/pages/member/money_record.dart';
import 'package:flutter_taxi_chinghsien/pages/member/my_account_page.dart';
import 'package:flutter_taxi_chinghsien/pages/register.dart';
import 'package:flutter_taxi_chinghsien/pages/task/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'color.dart';
import 'firebase_options.dart';
import 'notifier_models/task_model.dart';
import 'notifier_models/user_model.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  LineSDK.instance.setup('1657014064').then((_) {
    print('LineSDK Prepared');
  });
  // await initializeService();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => UserModel(),
      ),
      ChangeNotifierProvider(
        create: (context) => TaskModel(),
      ),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black54,
        textTheme: const TextTheme(
          button: TextStyle(fontSize: 16),
          //headline6: AppBar title
          headline6: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          //subtitle1: dropDownButton Text
          //subtitle2: body title
          subtitle2: TextStyle(color: AppColor.yellow, fontSize: 20,fontWeight: FontWeight.bold, ),
          //bodyText2: default body text
          bodyText2: TextStyle(color: Colors.black, fontSize: 16,height: 1.6),
          //bodyText1: body text big and bold
          bodyText1: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(AppColor.yellow),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        appBarTheme: const AppBarTheme(
            color: Colors.black87,
            elevation: 0
        ),
      ),
      debugShowCheckedModeBanner: false,
      // home: const MyHomePage(),
      home: const LogIn(),

      routes:  {
        '/main': (context) => const MyHomePage(),
        '/log_in': (context) => const LogIn(),
        '/money_record': (context) => const MoneyRecord(),
      },
      builder: (context, child){
        return MediaQuery(data: MediaQuery.of(context).copyWith(textScaleFactor: 1.1), child: Container(child: child)
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: pageCaller(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black87, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          // onTap: _onItemTapped,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.taxi), label: '派車首頁'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: '會員中心'),
          ],
        ),
      ),
    );
  }
  pageCaller(int index){
    switch (index){
      case 0 : { return const HomePage();}
      case 1 : { return const MyAccountPage();}
    }

  }
}
