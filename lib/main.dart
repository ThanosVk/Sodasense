import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:thesis/Compass.dart';
import 'package:thesis/Sensors.dart';
import 'package:thesis/Settings.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:thesis/Login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thesis/Theme_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:thesis/User.dart';
import 'package:thesis/Navigation.dart';
import 'dart:io';
import 'package:thesis/SqlDatabase.dart';
import 'package:intl/intl.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

String? saved_mail,saved_pass;
var box;
void main() async{

  //Hive commands for initializing and opening a box to store data
  await Hive.initFlutter();

  // Hive.registerAdapter(UserAdapter());

  box = await Hive.openBox('user');

  //FlutterNativeSplash.removeAfter(check_session);

  check_session();

  runApp(MyApp());
}

// Future check_session(BuildContext? context) async {
//   String? mail = await SecureStorage.get_email();
//   String? pass = await SecureStorage.get_pass();
//   screen = Login();
//   if(mail != null && pass!=null) {
//     screen = MyHomePage();
//   }
//   await Future.delayed(Duration(seconds: 2));
// }

void check_session() async{
  saved_mail = await box.get('email');
  saved_pass = await box.get('pass');
}

bool isDarkMode = false;//check if dark mode is enabled

// The callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  int updateCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // You can use the getData function to get the data you saved.
    final customData = await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(notificationTitle: 'FirstTaskHandler',notificationText: timestamp.toString(),callback: updateCount >= 10 ? updateCallback : null);
    // Send data to the main isolate.
    sendPort?.send(timestamp);
    sendPort?.send(updateCount);

    updateCount++;
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    print('onButtonPressed >> $id');
  }
}

void updateCallback() {
  FlutterForegroundTask.setTaskHandler(SecondTaskHandler());
}

class SecondTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {

  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(notificationTitle: 'SecondTaskHandler', notificationText: timestamp.toString());
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {

  }
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      builder: (context, _) {

      final themeProvider = Provider.of<ThemeProvider>(context);

      if(themeProvider.themeMode == MyThemes.darkTheme){
        isDarkMode = true;
      }
      else{
        isDarkMode = false;
      }

      return MaterialApp(
        title: 'Sodasense',
        themeMode: themeProvider.themeMode,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home:WithForegroundTask(
            child: (saved_mail !=null && saved_pass!=null)? MyHomePage() : Login()
        )
      );
    }
  );
}

class MyHomePage extends StatefulWidget {

  @override
  State<MyHomePage> createState() => StartScreen();
}

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class StartScreen extends State<MyHomePage> with WidgetsBindingObserver{

  final stepController = TextEditingController(),heightController = TextEditingController();//stepController for getting steps target, heightController for getting height
  //steps_count for getting the value of stepController, steps_target for getting the value of textfield, height _count for getting the value of height Controller
  //height for getting the value from heightController Textfield
  int steps_count=0 ,steps_target=0, height_count=0,height=0;
  //steps_length for finding the exact meters per user height,dist for distance in km
  double steps_length=0,dist=0;
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '', steps = 'ok';
  int numsteps=0, sum_steps=0;
  bool hasPermissions = false,height_check=false;//hasPermissions for knowing if the device has permissions for activity sensor,height_check to know if height Textfield contains something
  bool height_validate=true;// height_validate for height validate textfield
  late List<bool> isSelected = [true, false];//isSelected for gender toggle buttons
  User user = new User();
  String date = DateFormat('dd-MM-yyyy-HH-mm-ss').format(DateTime.now());
  String date_once = DateFormat('dd-MM-yyyy').format(DateTime.now());

  ConnectivityResult connectionStatus = ConnectivityResult.none;
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> connectivitySubscription;
  bool hasInternet =false;//for checking if the device is connected to the internet

  //var box = Hive.box('user').add(user);



  ReceivePort? _receivePort;

  Future<void> initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
      printDevLog: true,


    );
  }

  Future<bool> startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'App is running on the background',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is DateTime) {
          print('receive timestamp: $message');
        } else if (message is int) {
          print('receive updateCount: $message');
        }
      });

      return true;
    }

    return false;
  }

  Future<bool> stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  //For getting steps from stepController
  int stepscount(){
    return steps_count;
  }

  //For getting height from heightController
  int heightcount(){
    return height_count;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addObserver(this);

    initForegroundTask();
    startForegroundTask();
    FlutterForegroundTask.requestIgnoreBatteryOptimization();

    if((box.get('date') != date_once) && (box.get('date') != null)){
      insert_toDb();
      box.put('today_steps',0);
    }
    initPlatformState();
    fetchPermissionStatus();

    //Start listening to values with listener
    stepController.addListener(stepscount);
    heightController.addListener(heightcount);

    box.get('');

    initConnectivity();

    connectivitySubscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    WidgetsBinding.instance?.removeObserver(this);

    stepController.dispose();
    heightController.dispose();
    _receivePort?.close();

    //Hive.close(); den xreiazetai aparaitita

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) return;

    final isBackground= state == AppLifecycleState.paused;


    if(state == AppLifecycleState.resumed){
      NavigationState().location.enableBackgroundMode(enable:false);
      print('fainetai ston xristi');
    }
    else if (isBackground) {
      NavigationState().location.enableBackgroundMode(enable: true);
      print('μπηκε στο μπαγκραουντ');
    }
    if(state == AppLifecycleState.detached) {
      print('feygo');
      stopForegroundTask();
      exit(0);
    }
  }


  void fetchPermissionStatus() {
    Permission.activityRecognition.status.then((status) {
      if (mounted) {
        setState(() => hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      if(box.get('today_steps')==null){
        box.put('today_steps',0);
      }
      else{
        //numsteps++;
        //sum_steps = box.get('today_steps') + numsteps;
        box.put('today_steps',box.get('today_steps') + 1);
        dist = (box.get('today_steps') * box.get('steps_length'))/ 1000;
      }
    });

    box.put('date',date_once);
  }


  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      steps = 'Pedometer not\navailable';
    });
  }

  void initPlatformState() {
    // _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    // _pedestrianStatusStream.listen(onPedestrianStatusChanged).onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  //Function for displaying the correct error message on height textfield
  String? Height_Textfield_check(){
    String height_msg='';
    if(heightController.text.isEmpty==true){
      height_msg='Height can\'t be empty';
      print(height_msg);
      height_check=false;
      return height_msg;
    }
    else if(int.parse(heightController.text) > 250){
      height_msg='Height must be less than 250cm';
      print(height_msg);
      height_check=false;
      return height_msg;
    }
    else if(int.parse(heightController.text) <= 250){
      height_check =true;
      height_msg='Valid height';
      print(height_msg);
    }
  }

  //Function for testing if height textfield is changed for the first time
  bool height_error_msg(){
    if(Height_Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }

  insert_toDb() async{
    int stp = box.get('today_steps');
    await SqlDatabase.instance.insert_daily_steps("'$date'",stp,0);
    List<Map> lista = await SqlDatabase.instance.select_daily_steps();
    print(lista);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      //developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return updateConnectionStatus(result);
  }

  //Function for checking the availability of the internet
  Future<void> updateConnectionStatus(ConnectivityResult result) async {
    hasInternet = await InternetConnectionChecker().hasConnection;
    setState(() {
      connectionStatus = result;

      if((connectionStatus == ConnectivityResult.mobile || connectionStatus == ConnectivityResult.wifi) && hasInternet == true){
        print('Exei sundesi sto internet');
      }
      else{
        print('Den exei sundesi sto internet');
      }
    });
  }


  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Sidemenu(),
        appBar: AppBar(
          title: const Text("Main screen")
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: (
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:[
                      Text('Welcome back!', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold))
                    ]
                ),

                SizedBox(height: size.height * 0.05),

                Builder(builder: (context){
                  if(hasPermissions){
                    return Card(
                      shadowColor: Colors.grey,
                      elevation: 10,
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.only(left: 10, right: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                          children: [
                                            TextSpan(
                                                text: 'Today',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                    fontSize: 26
                                                )
                                            ),
                                          ]
                                      ),
                                    )
                                  ],
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () => {
                                        showDialog(context: context, builder: (context) => StatefulBuilder(
                                            builder: (BuildContext context, StateSetter setState) {
                                            return AlertDialog(
                                              title: Text('Set your daily target\nor change your height',
                                                  textAlign: TextAlign.justify
                                              ),
                                              content: SizedBox(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      maxLength: 5,
                                                      controller: stepController,
                                                      keyboardType: TextInputType.number,
                                                      decoration: InputDecoration(
                                                        labelText: "Steps Target",
                                                        counterText: ''
                                                      ),
                                                    ),
                                                    TextField(
                                                      maxLength: 3,
                                                      controller: heightController,
                                                      decoration: InputDecoration(
                                                          labelText: "Height in cm",
                                                          errorText: height_validate ? null: Height_Textfield_check(),
                                                          counterText: ''
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (text) => setState(() {
                                                        height_validate = height_error_msg();
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                ElevatedButton(onPressed: () => {
                                                  if(stepController.text.isEmpty == false && heightController.text.isEmpty == false && int.parse(heightController.text) <= 250){
                                                    if(isSelected[0]==true){
                                                      height = int.parse(heightController.text),
                                                      steps_length = (height * 0.415) / 100,// /100 to make it in meters
                                                      print('male')
                                                    }
                                                    else{
                                                      height = int.parse(heightController.text),
                                                      steps_length = (height * 0.413) / 100,// /100 to make it in meters
                                                      print('female')
                                                    },
                                                    steps_target = int.parse(stepController.text),
                                                    user.steps_length = steps_length,
                                                    user.height = height,
                                                    user.target_steps = steps_target,
                                                    box.put('height',user.height),
                                                    box.put('steps_length',user.steps_length),
                                                    box.put('target_steps',user.target_steps),
                                                    // user?.save(),
                                                    stepController.clear(),
                                                    heightController.clear(),
                                                    Navigator.pop(context,steps_target),
                                                  }
                                                },child: Text('Ok')),
                                              ],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                                            );
                                          }
                                        ),
                                        )
                                      },
                                      icon: FaIcon(FontAwesomeIcons.bullseye),
                                      color: isDarkMode == true ? Colors.black: Colors.black,
                                    )
                                  ],
                                )
                              ],
                            ),

                            SizedBox(height: size.height * 0.03),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Center(
                                  child: Container(
                                      height: 160,
                                      width: 160,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CircularProgressIndicator(
                                            value:steps=='ok' && box.get('today_steps') != null ? box.get('today_steps')/box.get('target_steps') : 0,
                                            strokeWidth: 16,
                                            backgroundColor: Color(0xfff8f9f9),
                                          ),
                                          Center(
                                            child: RichText(
                                              text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                        text: steps=='ok' && box.get('today_steps') != null ? '${box.get('today_steps')}/${box.get('target_steps')}' : '${steps}/${box.get('target_steps')}',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                        )
                                                    ),
                                                    WidgetSpan(
                                                        child: RotatedBox(
                                                            quarterTurns: 3,
                                                            child: FaIcon(FontAwesomeIcons.shoePrints, size: 12,color: isDarkMode == true ? Colors.black: Colors.black,)
                                                        )
                                                    )
                                                  ]
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: size.height * 0.03),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$dist',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Km by steps',
                                    style: TextStyle(
                                      //fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 14
                                    )
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  else{
                    return buildPermissionSheet();
                  }
                }),

                SizedBox(height: size.height * 0.03),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed:() => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => Navigation()))
                            },
                            child: Text('Navigation Screen')
                        ),
                      ]

                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed:() => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => Compass()))
                            },
                            child: Text('Compass Screen')
                        ),
                      ],
                    ),



                  ],
                ),

                SizedBox(height: size.height * 0.03),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed:() => {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Sensors()))
                              },
                              child: Text('Sensors Screen')
                          ),
                        ]

                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed:() => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()))
                            },
                            child: Text('Settings Screen')
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          ),
        ),
      ),
    );
  }

  //Widget for displaying permission for activity
  Widget buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Activity Permission Required'),
          ElevatedButton(
            child: Text('Request Permissions'),
            onPressed: () {
              Permission.activityRecognition.request().then((ignored) {
                fetchPermissionStatus();
              });
              showDialog(context: context, builder: (context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    title: Text('Set your daily steps target, your gender and your height',
                      textAlign: TextAlign.justify
                    ),
                    content: SizedBox(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('You can change the daily target of steps anytime or the height by pressing the settings icon on top right corner.',
                              style: TextStyle(
                                  fontSize: 14
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            TextField(
                              maxLength: 5,
                              controller: stepController,
                              decoration: InputDecoration(
                                labelText: "Steps Target",
                                counterText: ''
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            TextField(
                              maxLength: 3,
                              controller: heightController,
                              decoration: InputDecoration(
                                  labelText: "Height in cm",
                                  errorText: height_validate ? null: Height_Textfield_check(),
                                  counterText: ''
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (text) => setState(() {
                                height_validate = height_error_msg();
                              }),
                            ),
                            SizedBox(height: 16),
                            ToggleButtons(
                              isSelected: isSelected,
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.black,
                              children: <Widget>[
                                Text('Male'),
                                Text('Female')
                              ],
                              onPressed: (int index) {
                                setState(() {
                                  //final box = Boxes.getUser();
                                  //box.add(user);
                                  for (int i = 0; i < 2; i++) {
                                    if(i == index){
                                      isSelected[i] = true;
                                      user.gender = 'male';
                                      box.put('gender',user.gender);
                                      print(box.get('gender'));
                                    }
                                    else{
                                      isSelected[i] = false;
                                      user.gender = 'female';
                                      box.put('gender',user.gender);
                                      print(box.get('gender'));
                                    }
                                    //user.save();

                                    //user.save();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      ElevatedButton(onPressed: () => {
                        if(stepController.text.isEmpty == false && heightController.text.isEmpty == false && int.parse(heightController.text) <= 250){
                          if(isSelected[0]==true){
                            height = int.parse(heightController.text),
                            steps_length = (height * 0.415) / 100,// /100 to make it in meters
                            print('male'),
                          }
                          else{
                            height = int.parse(heightController.text),
                            steps_length = (height * 0.413) / 100,// /100 to make it in meters
                            print('female')
                          },
                          steps_target = int.parse(stepController.text),
                          user.height = height,
                          user.steps_length = steps_length,
                          user.target_steps = steps_target,
                          box.put('height',user.height),
                          box.put('steps_length',user.steps_length),
                          box.put('target_steps',user.target_steps),
                          // user.save(),
                          stepController.clear(),
                          heightController.clear(),
                          Navigator.pop(context,steps_target),
                        }
                      },child: Text('Ok')),
                    ],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                  );
                }
              ),
                barrierDismissible: false,
              );
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
              });
            },
          )
        ],
      ),
    );
  }

}
