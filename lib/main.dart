import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:thesis/Compass.dart';
import 'package:thesis/Sensors.dart' as sens;
import 'package:thesis/Settings.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:thesis/Login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thesis/Theme_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:thesis/User.dart';
import 'package:thesis/Navigation.dart';
import 'dart:io';
import 'package:thesis/SqlDatabase.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' as foundation;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'dart:math';

String? saved_mail, saved_pass;
var box;
void main() async {
  //Hive commands for initializing and opening a box to store data
  await Hive.initFlutter();

  // Hive.registerAdapter(UserAdapter());

  box = await Hive.openBox('user');

  //FlutterNativeSplash.removeAfter(check_session);

  check_session();

  runApp(const MyApp());
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

void check_session() async {
  saved_mail = await box.get('email');
  saved_pass = await box.get('pass');
}

bool isDarkMode = false; //check if dark mode is enabled

// The callback function should always be a top-level function.
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    // print('customData: $customData');
  }

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // FlutterForegroundTask.updateService(
    //     notificationTitle: 'MyTaskHandler',
    //     notificationText: 'eventCount: $_eventCount'
    // );

    // Send data to the main isolate.
    sendPort?.send(_eventCount);

    _eventCount++;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Insert here repeated task logic

    // for now we be sending the current timestamp back to the main isolate as an example to avoid 'Missing concrete implementation of 'TaskHandler.onRepeatEvent' errors
    sendPort?.send(timestamp.toString());
  }

  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    // print('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);

        if (themeProvider.themeMode == MyThemes.darkTheme) {
          isDarkMode = true;
        } else {
          isDarkMode = false;
        }

        return MaterialApp(
            title: 'Sodasense',
            themeMode: themeProvider.themeMode,
            theme: MyThemes.lightTheme,
            darkTheme: MyThemes.darkTheme,
            debugShowCheckedModeBanner: false,
            home: WithForegroundTask(
                child: (saved_mail != null && saved_pass != null)
                    ? const MyHomePage()
                    : const Login()));
      });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => StartScreen();
}

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class StartScreen extends State<MyHomePage> with WidgetsBindingObserver {
  final stepController = TextEditingController(),
      heightController =
      TextEditingController(); //stepController for getting steps target, heightController for getting height
  //steps_count for getting the value of stepController, steps_target for getting the value of textfield, height _count for getting the value of height Controller
  //height for getting the value from heightController Textfield
  int steps_count = 0, steps_target = 0, height_count = 0, height = 0;
  double steps_length = 0,
      dist =
      0; //steps_length for finding the exact meters per user height,dist for distance in km
  late Stream<StepCount> _stepCountStream;
  String steps = '0';
  int numsteps = 0, sum_steps = 0;
  bool hasPermissions = false,
      height_check =
      false; //hasPermissions for knowing if the device has permissions for activity sensor,height_check to know if height Textfield contains something
  bool height_validate = true; // height_validate for height validate textfield
  late List<bool> isSelected = [
    true,
    false
  ]; //isSelected for gender toggle buttons
  User user = User();

  // String date = DateFormat('dd-MM-yyyy-HH-mm-ss').format(DateTime.now());
  //Date for using date in the database
  int date = 0;

  int maxYAxisValue = 100;

  String date_once = DateFormat('dd-MM-yyyy').format(DateTime.now());

  ConnectivityResult connectionStatus = ConnectivityResult.none;
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> connectivitySubscription;
  bool hasInternet =
  false; //for checking if the device is connected to the internet

  //var box = Hive.box('user').add(user);

  ReceivePort? _receivePort;

  //Sensors variables
  int srt = 10,
      ttl_stps =
      0; //srt for sampling rate time of sensors, ttl_stps for getting the sum of the daily steps
  double ax = 0,
      ay = 0,
      az = 0,
      gx = 0,
      gy = 0,
      gz = 0,
      mx = 0,
      my = 0,
      mz = 0,
      pressure =
      0; //a for user accelerometer, g for gyroscope, m  for magnetometer, pressure for getting the value of pressure
  String amsg = '',
      gmsg = '',
      mmsg = '',
      nmsg = "'No'",
      pmsg =
          'Pressure not available'; //a for user accelerometer, g for gyroscope, m for magnetometer,n for proximity,p for pressure
  bool _isNear = false; //for proximity sensor
  late StreamSubscription<dynamic> _streamSubscription; //for proximity sensor
  //press_check for checking if the device has pressure sensor,prox_check for checking if the device has proximity sensor,acc_check for checking if
  //the device has accelerometer,gyro_check for checking if the device has gyroscope,magn_check for checking if the device has magnetometer
  bool press_check = false,
      prox_check = false,
      acc_check = false,
      gyro_check = false,
      magn_check = false;

  Timer? timer, timer_acc, timer_gyro, timer_magn, timer_press, timer_prox;

  static const press_channel = MethodChannel('pressure_sensor');
  static const prox_channel = MethodChannel('proximity_channel');
  static const acc_channel = MethodChannel('accelerometer_channel');
  static const gyro_channel = MethodChannel('gyroscope_channel');
  static const magn_channel = MethodChannel('magnetometer_channel');

  static const pressure_channel =
  EventChannel('pressure_channel'); //Channel for communicating with android
  StreamSubscription? pressureSubscription;

  //Location variables
  bool hasPermissionsGPS = false,
      serviceEnabled =
      false; //hasPermissions if the gps permissions are given, serviceEnabled if the gps is enabled
  double lat = 0,
      lng = 0; //lat for getting the latitude, lng for getting the longitude

  geo.Position? currentPosition;
  loc.LocationData? currentLocation;
  loc.Location location = loc.Location();
  //steps_dp for keeping temporary the steps for saving on Hive db
  int steps_db = 0;
  //Each day for the daily steps chart
  int Monday = 0,
      Tuesday = 0,
      Wednesday = 0,
      Thursday = 0,
      Friday = 0,
      Saturday = 0,
      Sunday = 0;

  //data for keeping the data of the chart
  late List<ChartData> data;
  late TooltipBehavior _tooltip;

  void initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
        'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions:
      const IOSNotificationOptions(showNotification: true, playSound: true),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    bool reqResult;
    if (await FlutterForegroundTask.isRunningService) {
      reqResult = await FlutterForegroundTask.restartService();
    } else {
      reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'App is running on the background',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    ReceivePort? receivePort;
    if (reqResult) {
      receivePort = FlutterForegroundTask.receivePort;
    }

    return _registerReceivePort(receivePort);
  }

  Future<bool> stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? receivePort) {
    closeReceivePort();

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is int) {
          // print('eventCount: $message');
        } else if (message is String) {
          if (message == 'onNotificationPressed') {
            Navigator.of(context).pushNamed('/resume-route');
          }
        } else if (message is DateTime) {
          print('timestamp: ${message.toString()}');
        }
      });

      return true;
    }

    return false;
  }

  void closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }


  //For getting steps from stepController
  int stepscount() {
    return steps_count;
  }

  //For getting height from heightController
  int heightcount() {
    return height_count;
  }

  void setupLocationListener() {
    if (box.get('GPS') == true) {
      location.onLocationChanged.listen((loc.LocationData cLoc) {
        // Check if widget is still in the tree
        if (!mounted) return;

        setState(() {
          currentLocation = cLoc;
          setpoint(cLoc.latitude, cLoc.longitude);
        });

        // Check if speed is more than 1.5 km/h (converting speed from m/s to km/h by multiplying by 3.6)
        if (cLoc.speed != null && (cLoc.speed! * 3.6) > 1.5) {
          insert_toDb_GPS();
          print('GPS data recorded: ${cLoc.latitude}, ${cLoc.longitude}, Speed: ${cLoc.speed! * 3.6} km/h');
        } else {
          print('Speed is below 1.5 km/h, current speed: ${cLoc.speed! * 3.6} km/h');
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setupLocationListener(); // Initialize location listener
    initForegroundTask();
    startForegroundTask();
    FlutterForegroundTask.requestIgnoreBatteryOptimization();

    if ((box.get('date') != date_once) && (box.get('date') != null)) {
      insert_toDb();
      box.put('today_steps', 0);
    }
    initPlatformState();
    fetchPermissionStatus();

    // Start listening to values with listeners
    stepController.addListener(stepscount);
    heightController.addListener(heightcount);

    if (box.get('today_steps') != null) {
      if (box.get('today_steps') > 0) {
        box.put('today_steps', box.get('today_steps') - 1);
      }
    }

    // box.get('');

    initConnectivity();
    connectivitySubscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);

    // Sensors
    check_pressure_availability();
    check_proximity_availability();
    check_acc_availability();
    check_gyro_availability();
    check_magn_availability();

    // Fetch weekly steps data
    fetchWeeklyStepsData();

    //accelerometer initialization event
    userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (acc_check == true) {
        ax = event.x;
        ay = event.y;
        az = event.z;
        amsg =
        'x:${ax.toStringAsFixed(2)} y:${ay.toStringAsFixed(2)} z:${az.toStringAsFixed(2)}';
        //timer_acc = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_acc_toDb());
      } else {
        amsg = 'Accelerometer not available';
      }
    });

    //gyroscope initialization event
    gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (gyro_check == true) {
        gx = event.x;
        gy = event.y;
        gz = event.z;
        gmsg =
        'x:${gx.toStringAsFixed(2)} y:${gy.toStringAsFixed(2)} z:${gz.toStringAsFixed(2)}';
        //timer_gyro = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_gyro_toDb());
      } else {
        gmsg = 'Gyroscope not available';
      }
    });

    //magnetometer initialization event
    magnetometerEventStream().listen((MagnetometerEvent event) {
      if (magn_check == true) {
        mx = event.x;
        my = event.y;
        mz = event.z;
        mmsg =
        'x:${mx.toStringAsFixed(2)} y:${my.toStringAsFixed(2)} z:${mz.toStringAsFixed(2)}';
        //timer_magn = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_magn_toDb());
      } else {
        mmsg = 'Magnetometer not available';
      }
    });

    //proximity sensor initialization
    listenSensor();

    //pressure initialization event
    StartScreen().pressureSubscription =
        StartScreen.pressure_channel.receiveBroadcastStream().listen((event) {
          if (press_check == true) {
            pressure = event;
            pmsg = '${pressure.toStringAsFixed(2)} mbar';
            if (press_check == false) {
              pmsg = 'Pressure not available';
            }
            //timer_press = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_pressure_toDb());
          } else {
            pmsg = 'Pressure not available';
          }
        });

    if (box.get('sensors_sr') != null) {
      srt = box.get('sensors_sr');
    }
    timer = Timer.periodic(Duration(seconds: srt), (Timer t) {
      // print('Oi aisthitires einai $amsg, $gmsg, $mmsg, $pmsg, $nmsg');

      if (acc_check == true) {
        insert_acc_toDb();
      } else {
        ax = 0;
        ay = 0;
        az = 0;
      }
      if (gyro_check == true) {
        insert_gyro_toDb();
      } else {
        gx = 0;
        gy = 0;
        gz = 0;
      }
      if (magn_check == true) {
        insert_magn_toDb();
      } else {
        mx = 0;
        my = 0;
        mz = 0;
      }
      if (press_check == true) {
        insert_pressure_toDb();
      } else {
        pressure = 0;
      }
      if (prox_check == true) {
        insert_prox_toDb();
      }
      insert_sensors_toDb();
      //check();
      // print('I ekxorisi egine sosta!');
    });

    //Coordinates

    // fetchPermissionStatusGPS();

    // getsensors();
    setState(() {
      getStepsByDay();
      // generateData();
    });

    _tooltip = TooltipBehavior(enable: true);
    fetchWeeklyStepsData();
  }

  // Method to fetch weekly steps data
  void fetchWeeklyStepsData() async {
    List<Map<String, dynamic>> stepsData = await SqlDatabase.instance.select_steps_for_current_week();

    // Process the fetched data to get step counts for each day of the current week
    Map<String, int> weeklySteps = {};
    stepsData.forEach((data) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(data['date'] as int, isUtc: true).toLocal();
      String dayOfWeek = DateFormat('EEE').format(date); // Three-letter day abbreviation
      int steps = data['steps'] as int;
      weeklySteps[dayOfWeek] = steps;
      print("Fetched data - Date: ${date.toString()}, Day: $dayOfWeek, Steps: $steps"); // Logging
    });

    // Update the state to reflect the new data
    setState(() {
      generateData(weeklySteps);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stepController.dispose();
    heightController.dispose();
    closeReceivePort();
    _streamSubscription.cancel();
    //Hive.close(); den xreiazetai aparaitita
    super.dispose();
  }

  void refreshData() async {
    // Refresh the steps data by day
    await getStepsByDay();

    // Fetch other necessary data
    fetchWeeklyStepsData();

    // Update the state to refresh the UI
    setState(() {
      // Here we can update other state variables if needed, check if it is, well, needed. Further testing required.
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) return;

    final isBackground = state == AppLifecycleState.paused;

    if (state == AppLifecycleState.resumed) {
      // App has come to the foreground, refresh data here
      refreshData();
      NavigationState().location.enableBackgroundMode(enable: false);
      print('Seen by the user');
    } else if (isBackground) {
      NavigationState().location.enableBackgroundMode(enable: true);
      print('Got to background');
    }
    if (state == AppLifecycleState.detached) {
      print('Closing app');
      stopForegroundTask();
      exit(0);
    }
  }

  //fetchPermissionStatus for Android  and Ios activity permission
  void fetchPermissionStatus() {
    if (Platform.isAndroid) {
      Permission.activityRecognition.status.then((status) {
        if (mounted) {
          setState(() => hasPermissions = status == PermissionStatus.granted);
        }
      });
    } else if (Platform.isIOS) {
      Permission.sensors.status.then((status) {
        if (mounted) {
          setState(() => hasPermissions = status == PermissionStatus.granted);
        }
      });
    }
  }

  void onStepCount(StepCount event) {
    print(event);
    steps_db = event.steps;
    setState(() {
      if (box.get('today_steps') == null) {
        box.put('today_steps', 0);
      } else {
        box.put('today_steps', box.get('today_steps') + 1);
        dist = double.parse(((box.get('today_steps') * box.get('steps_length')) / 1000).toStringAsFixed(3));
      }
    });

    box.put('date', date_once);

    // Insert steps into the database and refresh the chart data
    insert_toDb().then((_) {
      fetchWeeklyStepsData();
    });
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
  String? Height_Textfield_check() {
    String height_msg = '';
    if (heightController.text.isEmpty == true) {
      height_msg = 'Height can\'t be empty';
      print(height_msg);
      height_check = false;
      return height_msg;
    } else if (int.parse(heightController.text) > 250) {
      height_msg = 'Height must be less than 250cm';
      print(height_msg);
      height_check = false;
      return height_msg;
    } else if (int.parse(heightController.text) <= 250) {
      height_check = true;
      height_msg = 'Valid height';
      print(height_msg);
    }
    return null;
  }

  //Function for testing if height textfield is changed for the first time
  bool height_error_msg() {
    if (Height_Textfield_check()?.isNotEmpty == true) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> insert_toDb() async {
    int stp = box.get('today_steps');
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_daily_steps(date, stp, 0);
    List<Map> lista = await SqlDatabase.instance.select_daily_steps();
    print(lista);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException {
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

      if ((connectionStatus == ConnectivityResult.mobile || connectionStatus == ConnectivityResult.wifi) && hasInternet == true) {
        print('Exei sundesi sto internet');

        update_altitude();
        update_daily_steps();
        update_coor();
        update_sensors();
        // update_pressure();
        // update_acc();
        // update_gyro();
        // update_magn();
        // update_prox();
      } else {
        print('Den exei sundesi sto internet');
      }
    });
  }

  //update_altitude for updating the ununpdated altitude field from the local db
  update_altitude() async {
    //load altitude from local db to a list map and then to a list of objects
    List<Map> alt = await SqlDatabase.instance.select_altitude_unupdated();
    List<Object> arr = List<Map>.from(alt);

    var response = await http.post(
        Uri.parse('https://api.sodasense.uop.gr/v1/altitudeData'),
        headers: {
          'Authorization': 'Bearer ' + box.get('access_token'),
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({
          "userId": box.get('userid'),
          "altitude": arr,
          "email": box.get('email')
        }));
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Reason phrase: ${response.reasonPhrase}, altitude is uploaded');
    // if(response.statusCode == 200){
    //   print('OK');
    // }
  }

  // //update_pressure for updating the ununpdated pressure fields from the local db
  // update_pressure() async{
  //   //load pressure from local db to a list map and then to a list of objects
  //   List<Map> press = await SqlDatabase.instance.select_pressure_unupdated();
  //   List<Object> arr = List<Map>.from(press);
  //
  //   var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/environmentalData'),
  //       headers:{
  //         'Authorization':'Bearer ' + box.get('access_token'),
  //         HttpHeaders.acceptHeader: 'application/json',
  //         HttpHeaders.contentTypeHeader: 'application/json'
  //       },
  //       body: jsonEncode({
  //         "userId": box.get('userid'),
  //         "pressure": arr
  //       }));
  //   print('Status code: ${response.statusCode}');
  //   print('Response body: ${response.body}');
  //   print('Reason phrase: ${response.reasonPhrase}, pressure is uploaded');
  //   // if(response.statusCode == 200){
  //   //   print('OK');
  //   // }
  // }

  // //update_acc for updating the ununpdated accelaration fields from the local db
  // update_acc() async{
  //   //load accelaration from local db to a list map and then to a list of objects
  //   List<Map> acc = await SqlDatabase.instance.select_acc_unupdated();
  //   List<Object> arr = List<Map>.from(acc);
  //
  //   var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/accelerationData'),
  //       headers:{
  //         'Authorization':'Bearer ' + box.get('access_token'),
  //         HttpHeaders.acceptHeader: 'application/json',
  //         HttpHeaders.contentTypeHeader: 'application/json'
  //       },
  //       body: jsonEncode({
  //         "userId": box.get('userid'),
  //         "accelaration": arr
  //       }));
  //   print('Status code: ${response.statusCode}');
  //   print('Response body: ${response.body}');
  //   print('Reason phrase: ${response.reasonPhrase}, acceleration is uploaded');
  //   // if(response.statusCode == 200){
  //   //   print('OK');
  //   // }
  // }

  // //update_gyro for updating the ununpdated gyroscope fields from the local db
  // update_gyro() async{
  //   //load gyroscope from local db to a list map and then to a list of objects
  //   List<Map> gyro = await SqlDatabase.instance.select_gyro_unupdated();
  //   List<Object> arr = List<Map>.from(gyro);
  //
  //   var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/gyroscopeData'),
  //       headers:{
  //         'Authorization':'Bearer ' + box.get('access_token'),
  //         HttpHeaders.acceptHeader: 'application/json',
  //         HttpHeaders.contentTypeHeader: 'application/json'
  //       },
  //       body: jsonEncode({
  //         "userId": box.get('userid'),
  //         "gyroscope": arr
  //       }));
  //   print('Status code: ${response.statusCode}');
  //   print('Response body: ${response.body}');
  //   print('Reason phrase: ${response.reasonPhrase}, gyroscope is uploaded');
  //   // if(response.statusCode == 200){
  //   //   print('OK');
  //   // }
  // }

  // //update_magn for updating the ununpdated magnometer fields from the local db
  // update_magn() async{
  //   //load magnetometer from local db to a list map and then to a list of objects
  //   List<Map> magn = await SqlDatabase.instance.select_magn_unupdated();
  //   List<Object> arr = List<Map>.from(magn);
  //
  //   var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/magnetometerData'),
  //       headers:{
  //         'Authorization':'Bearer ' + box.get('access_token'),
  //         HttpHeaders.acceptHeader: 'application/json',
  //         HttpHeaders.contentTypeHeader: 'application/json'
  //       },
  //       body: jsonEncode({
  //         "userId": box.get('userid'),
  //         "magnetometer": arr
  //       }));
  //   print('Status code: ${response.statusCode}');
  //   print('Response body: ${response.body}');
  //   print('Reason phrase: ${response.reasonPhrase}, magnetometer is uploaded');
  //   // if(response.statusCode == 200){
  //   //   print('OK');
  //   // }
  // }

  // //update_prox for updating the ununpdated proximity fields from the local db
  // update_prox() async{
  //   //load proximity from local db to a list map and then to a list of objects
  //   List<Map> prox = await SqlDatabase.instance.select_prox_unupdated();
  //   List<Object> arr = List<Map>.from(prox);
  //
  //   var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/proximityData'),
  //       headers:{
  //         'Authorization':'Bearer ' + box.get('access_token'),
  //         HttpHeaders.acceptHeader: 'application/json',
  //         HttpHeaders.contentTypeHeader: 'application/json'
  //       },
  //       body: jsonEncode({
  //         "userId": box.get('userid'),
  //         "proximity": arr
  //       }));
  //   print('Status code: ${response.statusCode}');
  //   print('Response body: ${response.body}');
  //   print('Reason phrase: ${response.reasonPhrase}, proximity is uploaded');
  //   // if(response.statusCode == 200){
  //   //   print('OK');
  //   // }
  // }

  //update_daily_steps for updating the ununpdated daily_steps fields from the local db
  update_daily_steps() async {
    //load daily_steps from local db to a list map and then to a list of objects
    List<Map> dsteps = await SqlDatabase.instance.select_daily_steps_unupdated();
    List<Object> arr = List<Map>.from(dsteps);

    var response = await http.post(
        Uri.parse('https://api.sodasense.uop.gr/v1/dailystepsData'),
        headers: {
          'Authorization': 'Bearer ' + box.get('access_token'),
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({
          "userId": box.get('userid'),
          "dailysteps": arr,
          "email": box.get('email')
        }));
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Reason phrase: ${response.reasonPhrase}, daily steps is uploaded');
    // if(response.statusCode == 200){
    //   print('OK');
    // }
  }

  //update_coor for updating the ununpdated coordinates fields from the local db
  update_coor() async {
    //load coordinates from local db to a list map and then to a list of objects
    List<Map> coor = await SqlDatabase.instance.select_coor_unupdated();
    List<Object> arr = List<Map>.from(coor);

    var response = await http.post(
        Uri.parse('https://api.sodasense.uop.gr/v1/userTrackingData'),
        headers: {
          'Authorization': 'Bearer ' + box.get('access_token'),
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({
          "userId": box.get('userid'),
          "coordinates": arr,
          "email": box.get('email')
        }));
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Reason phrase: ${response.reasonPhrase}, coordinates is uploaded');
    // if(response.statusCode == 200){
    //   print('OK');
    // }
  }

  //update_sensors for updating the ununpdated sensors fields from the local db
  update_sensors() async {
    //load sensors from local db to a list map and then to a list of objects
    List<Map> sensors = await SqlDatabase.instance.select_sensors_unupdated();
    List<Object> arr = List<Map>.from(sensors);

    var response = await http.post(
        Uri.parse('https://api.sodasense.uop.gr/v1/sensorsData'),
        headers: {
          'Authorization': 'Bearer ' + box.get('access_token'),
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: jsonEncode({
          "userId": box.get('userid'),
          "sensors": arr,
          "email": box.get('email')
        }));
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Reason phrase: ${response.reasonPhrase}, sensors is uploaded');
    // if(response.statusCode == 200){
    //   print('OK');
    // }
  }

  //Future for gettind data from proximity sensor
  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (foundation.kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    _streamSubscription = ProximitySensor.events.listen((int event) {
      if (prox_check == true) {
        _isNear = (event > 0) ? true : false;
        if (_isNear == true) {
          nmsg = "'Yes'";
        } else {
          nmsg = "'No'";
        }
        //timer_prox = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_prox_toDb());
      } else {
        nmsg = 'Proximity not available';
      }
      print(nmsg);
    });
  }

  //Future for checking the availability of pressure sensor
  Future<void> check_pressure_availability() async {
    try {
      var available =
      await StartScreen.press_channel.invokeMethod('isSensorAvailable');
      press_check = available;
    } on PlatformException catch (e) {
      print(e);
    }
  }

  //Future for checking the availability of proximity sensor
  Future<void> check_proximity_availability() async {
    if (Platform.isIOS) {
      prox_check = true;
    } else {
      try {
        var available =
        await StartScreen.prox_channel.invokeMethod('isSensorAvailable');
        prox_check = available;
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  //Future for checking the availability of accelerometer sensor
  Future<void> check_acc_availability() async {
    if (Platform.isIOS) {
      acc_check = true;
    } else {
      try {
        var available =
        await StartScreen.acc_channel.invokeMethod('isSensorAvailable');
        acc_check = available;
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  //Future for checking the availability of gyroscope sensor
  Future<void> check_gyro_availability() async {
    if (Platform.isIOS) {
      gyro_check = true;
    } else {
      try {
        var available =
        await StartScreen.gyro_channel.invokeMethod('isSensorAvailable');
        gyro_check = available;
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  //Future for checking the availability of magnetometer
  Future<void> check_magn_availability() async {
    if (Platform.isIOS) {
      magn_check = true;
    } else {
      try {
        var available =
        await StartScreen.magn_channel.invokeMethod('isSensorAvailable');
        magn_check = available;
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  //function for inserting to the database the pressure data
  void insert_pressure_toDb() async {
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_pressure(date, pressure, 0);
    //print('KOMPLE TO PRESS');
  }

  //function for inserting to the database the acceleration data
  void insert_acc_toDb() async {
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_acc(date, ax, ay, az, 0);
    //print('KOMPLE TO ACC');
  }

  //function for inserting to the database the gyroscope data
  void insert_gyro_toDb() async {
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_gyro(date, gx, gy, gz, 0);
    //print('KOMPLE TO GYRO');
  }

  //function for inserting to the database the magnetometer data
  void insert_magn_toDb() async {
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_magn(date, mx, my, mz, 0);
    //print('KOMPLE TO MAGN');
  }

  //function for inserting to the database the proximity data
  void insert_prox_toDb() async {
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_prox(date, nmsg, 0);
    //print('KOMPLE TO PROX');
  }

  //function for inserting to the database the sensors data
  void insert_sensors_toDb() async {
    int steps = 0;

    if (steps_db == 0) {
      steps = 0;
    } else if (steps_db > 0) {
      steps = box.get('today_steps');
    }
    // print('Ta vimata einai $steps');
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_sensors(
        date, pressure, ax, ay, az, gx, gy, gz, mx, my, mz, nmsg, steps, 0);
    //print('KOMPLE TO PROX');
  }

  //Function for checking if the app has the location permission
  void fetchPermissionStatusGPS() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => hasPermissionsGPS = status == PermissionStatus.granted);
      }
    });
  }

  //Function for getting the status of Gps
  Future<geo.Position> getGeoLocationPosition() async {
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.best);
  }

  //setpoint for saving the coordinatesas lat and lng
  void setpoint(latitude, longitude) async {
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    lat = latitude;
    lng = longitude;
  }

  //Function for inserting GPS coodinates to sql db
  void insert_toDb_GPS() async {
    if (lat != 0.0 && lng != 0.0) {
      date = DateTime.now().millisecondsSinceEpoch;
      await SqlDatabase.instance.insert_coor(date, lat, lng, 0);
    }
    // print('has inserted somethinggggggggggggggggg');
  }

  //getCoordinates for getting the coordinates points from the first date picker
  getsensors() async {
    List<Map> lista = await SqlDatabase.instance.select_sensors();

    for (int i = 0; i < lista.length; i++) {
      print('To sensors $i periexei ${lista[i]}');
    }
  }

  //totalStepsPerDay to retrieve the maximum steps per day
  getStepsByDay() async {
    List<Map> sensors = await SqlDatabase.instance.select_total_steps_per_day();
    var arr = <String, int>{};
    String tmp = '';

    for (int i = 0; i < sensors.length; i++) {
      tmp = DateFormat.yMMMMEEEEd()
          .add_Hms()
          .format(DateTime.fromMillisecondsSinceEpoch(sensors[i]['date']));
      arr[tmp] = sensors[i]['steps'];
    }

    // arr.forEach((k, v) => print("Key : $k, Value : $v"));
    arr.forEach((key, value) {
      if (key.contains('Monday')) {
        Monday > value ? Monday : Monday = value;
      } else if (key.contains('Tuesday')) {
        Tuesday > value ? Tuesday : Tuesday = value;
      } else if (key.contains('Wednesday')) {
        Wednesday > value ? Wednesday : Wednesday = value;
      } else if (key.contains('Thursday')) {
        Thursday > value ? Thursday : Thursday = value;
      } else if (key.contains('Friday')) {
        Friday > value ? Friday : Friday = value;
      } else if (key.contains('Saturday')) {
        Saturday > value ? Saturday : Saturday = value;
      } else if (key.contains('Sunday')) {
        Sunday > value ? Sunday : Sunday = value;
      }
    });

    generateData(arr);
  }

  // Method to correctly determine the step count for each day
  void generateData(Map<String, int> weeklySteps) {
    DateTime currentDate = DateTime.now();
    DateTime startOfWeek = currentDate.subtract(Duration(days: currentDate.weekday - 1));

    List<ChartData> generatedData = [];
    int maxSteps = 0;

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      String dayOfWeek = DateFormat('EEE').format(date); // Three-letter day abbreviation
      String formattedDate = DateFormat('dd/MM').format(date); // dd/mm format

      // Check if the date falls within the current week
      if (date.isAfter(startOfWeek.subtract(Duration(days: 1))) && date.isBefore(startOfWeek.add(Duration(days: 7)))) {
        int stepsForDay = weeklySteps[dayOfWeek] ?? 0; // Use 0 if no data for the day
        maxSteps = max(maxSteps, stepsForDay); // Update maxSteps
        generatedData.add(ChartData('$dayOfWeek\n$formattedDate', stepsForDay));
        print("Processed data - Day: $dayOfWeek, Formatted Date: $formattedDate, Steps: $stepsForDay"); // Logging
      } else {
        print("Date out of range - Day: $dayOfWeek, Formatted Date: $formattedDate"); // Logging
      }
    }

    setState(() {
      data = generatedData;
      updateGraphMaxValue(maxSteps + 100);
    });
  }

  // Helper method to validate if a date is within the current week
  bool isDateInCurrentWeek(DateTime date) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(Duration(days: 1))) && date.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  // New method to update the maximum value on the graph
  void updateGraphMaxValue(int newMaxValue) {
    setState(() {
      maxYAxisValue = newMaxValue;
    });
  }

  Future<int> getStepCountForDate(DateTime date) async {
    // Convert the date to the start of the day in milliseconds
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

    // Fetch step count from the database for the specific date
    List<Map<String, dynamic>> stepsData = await SqlDatabase.instance.select_steps_for_date_range(startOfDay, endOfDay);

    if (stepsData.isNotEmpty && stepsData[0]['steps'] != null) {
      return stepsData[0]['steps'] ?? 0;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    //WillPopScope is a method for handling back button
    return WillPopScope(
      onWillPop: () async {
        bool popup = false;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              ElevatedButton(
                  onPressed: () => {popup = false, Navigator.pop(context)},
                  child: const Text('No')),
              ElevatedButton(
                  onPressed: () async {
                    await StartScreen().stopForegroundTask();
                    //await LoginState().db.close();
                    var box = Hive.box('user');
                    box.delete('email');
                    box.delete('pass');
                    popup = true;
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  },
                  child: const Text('Yes'))
            ],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
          barrierDismissible: false,
        );

        return popup;
      },
      child: Scaffold(
        drawer: const Sidemenu(),
        appBar: AppBar(title: const Text("Main screen")),
        body: SafeArea(
          child: SingleChildScrollView(
            child: (Column(
              children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                //     children:[
                //       Text('Welcome back!', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold))
                //     ]
                // ),

                SizedBox(height: size.height * 0.03),

                Builder(builder: (context) {
                  if (hasPermissions) {
                    return SizedBox(
                      height: 320,
                      child: Card(
                        shadowColor: Colors.grey,
                        elevation: 10,
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: CarouselSlider(
                          carouselController: CarouselController(),
                          options: CarouselOptions(
                            reverse: true,
                            height: MediaQuery.of(context).size.height * 0.4,
                            scrollDirection: Axis.horizontal,
                            enlargeCenterPage: true,
                            enlargeStrategy: CenterPageEnlargeStrategy.height,
                            enableInfiniteScroll: false,
                            initialPage: 1,
                            enlargeFactor: 1.5,
                            viewportFraction: 1.0,
                            disableCenter: true,
                          ),
                          items: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Center(
                                    child: SfCartesianChart(
                                      primaryXAxis: const CategoryAxis(
                                        majorGridLines: MajorGridLines(
                                            color: Colors.transparent),
                                        labelIntersectAction: AxisLabelIntersectAction.rotate45,
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      primaryYAxis: NumericAxis(
                                        minimum: 0,
                                        maximum: maxYAxisValue.toDouble(),
                                        interval: maxYAxisValue / 10,
                                        majorGridLines: const MajorGridLines(
                                            color: Colors
                                                .transparent), // Hide minor tick lines
                                        labelIntersectAction: AxisLabelIntersectAction.rotate45,
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                        ),
                                      ),
                                      tooltipBehavior: _tooltip,
                                      series: <ColumnSeries<ChartData, String>>[
                                        ColumnSeries<ChartData, String>(
                                          dataSource: data,
                                          xValueMapper: (ChartData data, _) => data.x,
                                          yValueMapper: (ChartData data, _) => data.y,
                                          name: 'Steps',
                                          color: Colors.cyan,
                                        ),
                                      ],
                                    ))
                              ],
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.white],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      // crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            RichText(
                                              text: const TextSpan(children: [
                                                TextSpan(
                                                    text: 'Today',
                                                    style: TextStyle(
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color: Colors.black,
                                                        fontSize: 26)),
                                              ]),
                                            ),
                                            // const Positioned(
                                            //   top: 16, // Adjust as necessary
                                            //   right: 16, // Adjust as necessary
                                            //   child: Row(
                                            //     mainAxisSize: MainAxisSize.min, // To keep the row as big as its children
                                            //     // children: [
                                            //     //   Padding(
                                            //     //     padding: EdgeInsets.only(right: 8.0), // Adjust the padding if needed
                                            //     //     child: Text(
                                            //     //       'Swipe for chart',
                                            //     //       style: TextStyle(
                                            //     //         color: Colors.black,
                                            //     //         fontSize: 16,
                                            //     //       ),
                                            //     //     ),
                                            //     //   ),
                                            //     //   Icon(
                                            //     //     Icons.arrow_forward_ios,
                                            //     //     size: 24, // Arrow pointing right
                                            //     //   ),
                                            //     // ],
                                            //   ),
                                            // )],
                                        ]),
                                        Column(
                                          children: [
                                            IconButton(
                                              onPressed: () => {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      StatefulBuilder(builder:
                                                          (BuildContext context,
                                                          StateSetter
                                                          setState) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'Set your daily target\nor change your height',
                                                              textAlign:
                                                              TextAlign.justify),
                                                          content: SizedBox(
                                                            child: Column(
                                                              mainAxisSize:
                                                              MainAxisSize.min,
                                                              children: [
                                                                TextField(
                                                                  maxLength: 5,
                                                                  controller:
                                                                  stepController,
                                                                  keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                                  decoration: InputDecoration(
                                                                      labelText:
                                                                      "Steps Target",
                                                                      counterText: '',
                                                                      hintText: box.get(
                                                                          'target_steps') ==
                                                                          null
                                                                          ? ""
                                                                          : "${box.get('target_steps')}"),
                                                                ),
                                                                TextField(
                                                                  maxLength: 3,
                                                                  controller:
                                                                  heightController,
                                                                  decoration: InputDecoration(
                                                                      labelText:
                                                                      "Height in cm",
                                                                      errorText:
                                                                      height_validate
                                                                          ? null
                                                                          : Height_Textfield_check(),
                                                                      counterText: '',
                                                                      hintText: box.get(
                                                                          'height') ==
                                                                          null
                                                                          ? ""
                                                                          : "${box.get('height')}"),
                                                                  keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                                  onChanged: (text) =>
                                                                      setState(() {
                                                                        height_validate =
                                                                            height_error_msg();
                                                                      }),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          actions: [
                                                            ElevatedButton(
                                                                onPressed: () => {
                                                                  if (stepController.text.isEmpty == false &&
                                                                      heightController
                                                                          .text
                                                                          .isEmpty ==
                                                                          false &&
                                                                      int.parse(heightController
                                                                          .text) <=
                                                                          250)
                                                                    {
                                                                      if (isSelected[
                                                                      0] ==
                                                                          true)
                                                                        {
                                                                          height =
                                                                              int.parse(heightController.text),
                                                                          steps_length =
                                                                              (height * 0.415) /
                                                                                  100, // /100 to make it in meters
                                                                          print(
                                                                              'male')
                                                                        }
                                                                      else
                                                                        {
                                                                          height =
                                                                              int.parse(heightController.text),
                                                                          steps_length =
                                                                              (height * 0.413) /
                                                                                  100, // /100 to make it in meters
                                                                          print(
                                                                              'female')
                                                                        },
                                                                      steps_target =
                                                                          int.parse(
                                                                              stepController.text),
                                                                      user.steps_length =
                                                                          steps_length,
                                                                      user.height =
                                                                          height,
                                                                      user.target_steps =
                                                                          steps_target,
                                                                      box.put(
                                                                          'height',
                                                                          user.height),
                                                                      box.put(
                                                                          'steps_length',
                                                                          user.steps_length),
                                                                      box.put(
                                                                          'target_steps',
                                                                          user.target_steps),
                                                                      // user?.save(),
                                                                      stepController
                                                                          .clear(),
                                                                      heightController
                                                                          .clear(),
                                                                      Navigator.pop(
                                                                          context,
                                                                          steps_target),
                                                                    }
                                                                },
                                                                child: const Text('Ok')),
                                                          ],
                                                          shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                  10.0)),
                                                        );
                                                      }),
                                                )
                                              },
                                              icon: const FaIcon(
                                                  FontAwesomeIcons.bullseye),
                                              color: isDarkMode == true
                                                  ? Colors.black
                                                  : Colors.black,
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
                                          child: SizedBox(
                                              height: 130,
                                              width: 160,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  FittedBox(
                                                    fit: BoxFit.fitWidth, // This ensures that the child scales down its width to fit into the parent
                                                    child: LiquidCircularProgressIndicator(
                                                      value: (steps == '0' && box.get('today_steps') != null)
                                                          ? box.get('today_steps') / box.get('target_steps')
                                                          : 0,
                                                      backgroundColor: const Color(0xfff8f9f9),
                                                      direction: Axis.vertical,
                                                    ),
                                                  ),
                                                  Center(
                                                    child: RichText(
                                                      text: TextSpan(children: [
                                                        TextSpan(
                                                            text: steps == '0' &&
                                                                box.get('today_steps') !=
                                                                    null
                                                                ? '${box.get('today_steps')}/${box.get('target_steps')}'
                                                                : '$steps/${box.get('target_steps')}',
                                                            style: const TextStyle(
                                                              color: Colors.black,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                            )),
                                                        WidgetSpan(
                                                            child: RotatedBox(
                                                                quarterTurns: 3,
                                                                child: FaIcon(
                                                                  FontAwesomeIcons
                                                                      .shoePrints,
                                                                  size: 12,
                                                                  color: isDarkMode ==
                                                                      true
                                                                      ? Colors
                                                                      .black
                                                                      : Colors
                                                                      .black,
                                                                )))
                                                      ]),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: size.height * 0.03),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dist',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Km by steps',
                                            style: TextStyle(
                                              //fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 14))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )],
                        ),
                      ),
                    );
                  } else {
                    return buildPermissionSheet();
                  }
                }),

                SizedBox(height: size.height * 0.03),

                Builder(builder: (context) {
                  if (box.get('GPS') == true) {
                    return Container();
                  } else {
                    return buildPermissionSheetGPS();
                  }
                }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                              maximumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                            ),
                            onPressed: () => {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Navigation()))
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Route'),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 24.0,
                                ),
                              ],
                            ),
                            // style: ElevatedButton.styleFrom(
                            //   minimumSize: ,
                            //   maximumSize: ,
                            // ),
                          ),
                        ]),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                              maximumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                            ),
                            onPressed: () => {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Compass()))
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible( // Wrap the text with Flexible
                                  child: Text(
                                    'Compass',
                                    overflow: TextOverflow.ellipsis, // Using ellipsis to handle overflow
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.explore_outlined, size: 24.0),
                              ],
                            )
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
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                                maximumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                              ),
                              onPressed: () => {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                        const sens.Sensors()))
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible( // Using Flexible here to allow the text to adjust its size to the available space
                                    child: Text(
                                      'Sensors',
                                      overflow: TextOverflow.ellipsis, // Using ellipsis to handle overflow
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.sensors_outlined,
                                    size: 24.0,
                                  ),
                                ],
                              )),
                        ]),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                              maximumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                            ),
                            onPressed: () => {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Settings()))
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Settings',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.settings,
                                  size: 24.0,
                                ),
                              ],
                            )),
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
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                              maximumSize: Size(MediaQuery.of(context).size.width * 0.4, 50),
                            ),
                            onPressed: () => {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content:
                                  const Text('Are you sure you want to exit?'),
                                  actions: [
                                    ElevatedButton(
                                        onPressed: () =>
                                        {Navigator.pop(context)},
                                        child: const Text('No')),
                                    ElevatedButton(
                                        onPressed: () async {
                                          await StartScreen()
                                              .stopForegroundTask();
                                          //await LoginState().db.close();
                                          var box = Hive.box('user');
                                          box.delete('email');
                                          box.delete('pass');
                                          box.delete('access_token');
                                          box.delete('userid');
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                  const Login()));
                                        },
                                        child: const Text('Yes'))
                                  ],
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10.0)),
                                ),
                                barrierDismissible: false,
                              ),
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Logout',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.logout,
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ]),
                  ],
                ),
              ],
            )),
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
          const Text('Activity Permission Required'),
          ElevatedButton(
            child: const Text('Request Permissions'),
            onPressed: () {
              if (Platform.isAndroid) {
                Permission.activityRecognition.request().then((ignored) {
                  fetchPermissionStatus();
                });
              } else if (Platform.isIOS) {
                Permission.sensors.request().then((ignored) {
                  fetchPermissionStatus();
                });
              }
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return AlertDialog(
                        title: const Text(
                            'Set your daily steps target, your gender and your height',
                            textAlign: TextAlign.justify),
                        content: SizedBox(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'You can change the daily target of steps anytime or the height by pressing the settings icon on top right corner.',
                                  style: TextStyle(fontSize: 14),
                                  textAlign: TextAlign.justify,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  maxLength: 5,
                                  controller: stepController,
                                  decoration: const InputDecoration(
                                      labelText: "Steps Target", counterText: ''),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  maxLength: 3,
                                  controller: heightController,
                                  decoration: InputDecoration(
                                      labelText: "Height in cm",
                                      errorText: height_validate
                                          ? null
                                          : Height_Textfield_check(),
                                      counterText: ''),
                                  keyboardType: TextInputType.number,
                                  onChanged: (text) => setState(() {
                                    height_validate = height_error_msg();
                                  }),
                                ),
                                const SizedBox(height: 16),
                                ToggleButtons(
                                  isSelected: isSelected,
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.black,
                                  children: const <Widget>[Text('Male'), Text('Female')],
                                  onPressed: (int index) {
                                    setState(() {
                                      //final box = Boxes.getUser();
                                      //box.add(user);
                                      for (int i = 0; i < 2; i++) {
                                        if (i == index) {
                                          isSelected[i] = true;
                                          user.gender = 'male';
                                          box.put('gender', user.gender);
                                          print(box.get('gender'));
                                        } else {
                                          isSelected[i] = false;
                                          user.gender = 'female';
                                          box.put('gender', user.gender);
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
                          ElevatedButton(
                              onPressed: () => {
                                if (stepController.text.isEmpty == false &&
                                    heightController.text.isEmpty == false &&
                                    int.parse(heightController.text) <= 250)
                                  {
                                    if (isSelected[0] == true)
                                      {
                                        height =
                                            int.parse(heightController.text),
                                        steps_length = (height * 0.415) /
                                            100, // /100 to make it in meters
                                        print('male'),
                                      }
                                    else
                                      {
                                        height =
                                            int.parse(heightController.text),
                                        steps_length = (height * 0.413) /
                                            100, // /100 to make it in meters
                                        print('female')
                                      },
                                    steps_target =
                                        int.parse(stepController.text),
                                    user.height = height,
                                    user.steps_length = steps_length,
                                    user.target_steps = steps_target,
                                    box.put('height', user.height),
                                    box.put('steps_length', user.steps_length),
                                    box.put('target_steps', user.target_steps),
                                    // user.save(),
                                    stepController.clear(),
                                    heightController.clear(),
                                    Navigator.pop(context, steps_target),
                                  }
                              },
                              child: const Text('Ok')),
                        ],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                      );
                    }),
                barrierDismissible: false,
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {});
            },
          )
        ],
      ),
    );
  }

  //Widget for showing location permissions menu
  Widget buildPermissionSheetGPS() {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: size.height * 0.03),
          const Text('Location Permission Required'),
          ElevatedButton(
            child: const Text('Request Permissions'),
            onPressed: () async {
              Permission.locationWhenInUse.request().then((ignored) {
                fetchPermissionStatusGPS();
              });
              await box.put('GPS', hasPermissionsGPS);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Open App Settings'),
            onPressed: () async {
              openAppSettings().then((opened) {
                if (Permission.locationAlways.isGranted == true) {
                  hasPermissionsGPS = true;
                }
              });
              await box.put('GPS', hasPermissionsGPS);
              print(box.get('GPS'));
            },
          ),
          SizedBox(height: size.height * 0.03)
        ],
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final int y;
}