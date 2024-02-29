import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' as foundation;
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:thesis/SqlDatabase.dart';
import 'package:thesis/main.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors_plus;

class StepsChart extends StatelessWidget {
  final int maxStepsThisWeek;
  final List<int> weeklySteps;

  StepsChart({required this.maxStepsThisWeek, required this.weeklySteps});

  @override
  Widget build(BuildContext context) {
    // Convert weeklySteps into a list of FlSpot
    List<FlSpot> spots = [];
    for (int i = 0; i < weeklySteps.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklySteps[i].toDouble()));
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          maxY: maxStepsThisWeek.toDouble(),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots, // Use the dynamically created spots
              isCurved: true,
              color: Colors.blue,
              barWidth: 5,
              belowBarData: BarAreaData(show: false),
              aboveBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class Sensors extends StatefulWidget {
  const Sensors({Key? key}) : super(key: key);

  @override
  State<Sensors> createState() => _SensorsState();
}

class _SensorsState extends State<Sensors> {
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
      nmsg = '',
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
  var box = Hive.box('user');
  var color; //color for setting the color of the icons on dark and light theme
  //Date for using date in the database
  // int date = 0;

  // static const press_channel = MethodChannel('pressure_sensor');
  // static const prox_channel = MethodChannel('proximity_channel');
  // static const acc_channel = MethodChannel('accelerometer_channel');
  // static const gyro_channel = MethodChannel('gyroscope_channel');
  // static const magn_channel = MethodChannel('magnetometer_channel');
  //
  // static const pressure_channel = EventChannel('pressure_channel');//Channel for comunicating with android
  // StreamSubscription? pressureSubscription;

  // Timer ?timer,timer_acc,timer_gyro,timer_magn,timer_press,timer_prox;

  Timer? _stepUpdateTimer;

  int todaySteps = 0; // Variable for today's steps

  int maxStepsThisWeek = 0;

  late Future<void> _stepsFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    check_pressure_availability();
    check_proximity_availability();
    check_acc_availability();
    check_gyro_availability();
    check_magn_availability();

    //accelerometer initialization event
    sensors_plus.userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      setState(() {
        if (acc_check == true) {
          ax = event.x;
          ay = event.y;
          az = event.z;
          amsg =
          'x:${ax.toStringAsFixed(2)} y:${ay.toStringAsFixed(2)} z:${az
              .toStringAsFixed(2)}';
          //timer_acc = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_acc_toDb());
        } else {
          amsg = 'Accelerometer not available';
        }
      });
    });

    //gyroscope initialization event
    sensors_plus.gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        if (gyro_check == true) {
          gx = event.x;
          gy = event.y;
          gz = event.z;
          gmsg =
          'x:${gx.toStringAsFixed(2)} y:${gy.toStringAsFixed(2)} z:${gz
              .toStringAsFixed(2)}';
          //timer_gyro = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_gyro_toDb());
        } else {
          gmsg = 'Gyroscope not available';
        }
      });
    });

    //magnetometer initialization event
    sensors_plus.magnetometerEventStream().listen((MagnetometerEvent event) {
      setState(() {
        if (magn_check == true) {
          mx = event.x;
          my = event.y;
          mz = event.z;
          mmsg =
          'x:${mx.toStringAsFixed(2)} y:${my.toStringAsFixed(2)} z:${mz
              .toStringAsFixed(2)}';
          //timer_magn = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_magn_toDb());
        } else {
          mmsg = 'Magnetometer not available';
        }
      });
    });

    //proximity sensor initialization
    listenSensor();

    //pressure initialization event
    StartScreen().pressureSubscription =
        StartScreen.pressure_channel.receiveBroadcastStream().listen((event) {
          // print('Mpike stin sun');
          setState(() {
            if (press_check == true) {
              pressure = event;
              pmsg = '${pressure.toStringAsFixed(2)} mbar';
              // print('Mpike sto if');
              if (press_check == false) {
                pmsg = 'Pressure not available';
              }
              //timer_press = Timer.periodic(Duration(seconds: 5), (Timer t) => insert_pressure_toDb());
            } else {
              // print('Mpike sto else');
              pmsg = 'Pressure not available';
            }
          });
        });

    // if(box.get('sensors_sr')!=null){
    //   srt = box.get('sensors_sr');
    // }
    // timer = Timer.periodic(Duration(seconds: srt), (Timer t) {
    //
    //   if(acc_check == true){
    //     insert_acc_toDb();
    //   }
    //   if(gyro_check == true){
    //     insert_gyro_toDb();
    //   }
    //   if(magn_check == true){
    //     insert_magn_toDb();
    //   }
    //   if(press_check == true){
    //     insert_pressure_toDb();
    //   }
    //   if(prox_check == true){
    //     insert_prox_toDb();
    //   }
    //   //check();
    //
    // });
    // Fetch and update the weekly steps data
    fetchAndUpdateSteps();

    // Fetch and update today's steps data
    updateTodaySteps();

    // Set up a timer to periodically update today's steps (e.g., every minute)
    _stepUpdateTimer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      updateTodaySteps();
    });

    fetchMaxStepsForChart();
  }

  void fetchMaxStepsForChart() async {
    int maxSteps = await SqlDatabase.instance.fetchMaxStepsInWeek();
    setState(() {
      maxStepsThisWeek = maxSteps + 100;
    });
  }

  // Function to fetch and update today's steps
  void updateTodaySteps() async {
    int steps = await SqlDatabase.instance.fetchTodaySteps();
    setState(() {
      todaySteps = steps;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stepUpdateTimer?.cancel(); // Cancel the timer when disposing
    _streamSubscription.cancel();
  }

  // Function to fetch and update today's steps
  void fetchAndUpdateTodaySteps() async {
    int steps = await SqlDatabase.instance.fetchTodaySteps();
    setState(() {
      todaySteps = steps;
    });
  }

  //Future for gettind data from proximity sensor
  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (foundation.kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    _streamSubscription = ProximitySensor.events.listen((int event) {
      setState(() {
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
    });
  }

  //Future for checking the availability of pressure sensor
  Future<void> check_pressure_availability() async {
    try {
      var available =
      await StartScreen.press_channel.invokeMethod('isSensorAvailable');
      setState(() {
        press_check = available;
      });
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
        setState(() {
          prox_check = available;
        });
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
        setState(() {
          acc_check = available;
        });
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
        setState(() {
          gyro_check = available;
        });
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
        setState(() {
          magn_check = available;
        });
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  // //function for inserting to the database the pressure data
  // void insert_pressure_toDb() async{
  //   date = DateTime.now().millisecondsSinceEpoch;
  //   await SqlDatabase.instance.insert_pressure(date,pressure,0);
  //   //print('KOMPLE TO PRESS');
  // }
  //
  // //function for inserting to the database the acceleration data
  // void insert_acc_toDb() async{
  //   date = DateTime.now().millisecondsSinceEpoch;
  //   await SqlDatabase.instance.insert_acc(date, ax, ay, az, 0);
  //   //print('KOMPLE TO ACC');
  // }
  //
  // //function for inserting to the database the gyroscope data
  // void insert_gyro_toDb() async{
  //   date = DateTime.now().millisecondsSinceEpoch;
  //   await SqlDatabase.instance.insert_gyro(date, gx, gy, gz, 0);
  //   //print('KOMPLE TO GYRO');
  // }
  //
  // //function for inserting to the database the magnetometer data
  // void insert_magn_toDb() async{
  //   date = DateTime.now().millisecondsSinceEpoch;
  //   await SqlDatabase.instance.insert_magn(date,mx,my,mz,0);
  //   //print('KOMPLE TO MAGN');
  // }
  //
  // //function for inserting to the database the proximity data
  // void insert_prox_toDb() async{
  //   date = DateTime.now().millisecondsSinceEpoch;
  //   await SqlDatabase.instance.insert_prox(date, "$nmsg", 0);
  //   //print('KOMPLE TO PROX');
  // }

  void check() async {
    List<Map> lista = await SqlDatabase.instance.select_acc();
    print(lista);
  }

  List<int> weeklySteps = [];

  Future<void> fetchAndUpdateSteps() async {
    List<Map<String, dynamic>> stepsData = await SqlDatabase.instance
        .fetchWeeklyStepData();
    weeklySteps = stepsData.map((item) => item['steps'] as int).toList();
    // This is important: set state only if the widget is still mounted.
    if (mounted) {
      setState(() {
        ttl_stps = weeklySteps.fold(0, (sum, item) => sum + item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidemenu(),
      appBar: AppBar(
        title: Text("Sensors"),
      ),
      body: FutureBuilder(
        // Call the fetchAndUpdateSteps function which fetches the data and updates the state
        future: _stepsFuture,
        builder: (context, snapshot) {
          // Show loading spinner while waiting for the data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If we run into an error, display it here
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Data is loaded, build the ListView
            return ListView(
              children: [
                ListTile(
                  leading: RotatedBox(
                      quarterTurns: 3,
                      child: FaIcon(FontAwesomeIcons.shoePrints)),
                  title: Text('Total count of steps',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: ttl_stps == 0 ? Text('-') : Text('$ttl_stps'),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.gaugeHigh),
                  title: Text('Pressure',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text(pmsg),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.upDownLeftRight),
                  title: Text('Accelerometer',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text(amsg),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.arrow_2_circlepath),
                  title: Text('Gyroscope',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text(gmsg),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.compass),
                  title: Text('Magnetometer',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text(mmsg),
                ),
                ListTile(
                  leading: Icon(Icons.sensors_outlined),
                  title: Text('Proximity',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text('${nmsg.replaceAll("'", "")}'),
                ),
                ListTile(
                  leading: Icon(Icons.directions_walk),
                  title: Text('Today\'s Steps',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                  trailing: Text('$todaySteps'),
                ),
                // Make sure to use the 'weeklySteps' which is now updated
                StepsChart(maxStepsThisWeek: maxStepsThisWeek,
                    weeklySteps: weeklySteps),
              ],
            );
          }
        },
      ),
    );
  }
// child: Column(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       // ListView(
//       //   children: [
//       //     Container(
//       //       width: 30,
//       //       height: 25,
//       //       child: Text('Total count of steps', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//       //     ),
//       //     Container(
//       //       width: 30,
//       //       height: 25,
//       //       child: ttl_stps == 0 ? Text('-') : Text('$ttl_stps'),
//       //     )
//       //   ],
//       // ),
//       // Row(
//       //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //     children: [
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             Text('Total count of steps', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//       //           ]
//       //       ),
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             ttl_stps == 0 ? Text('-') : Text('$ttl_stps')
//       //           ]
//       //       )
//       //     ]
//       // ),
//       // Row(
//       //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //     children: [
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             Text('Pressure', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//       //           ]
//       //       ),
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             Text(pmsg)
//       //           ]
//       //       )
//       //     ]
//       // ),
//       // Row(
//       //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //     children: [
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             Text('Total count of steps', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//       //           ]
//       //       ),
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             ttl_stps == 0 ? Text('-') : Text('$ttl_stps')
//       //           ]
//       //       )
//       //     ]
//       // ),
//       // Row(
//       //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //     children: [
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             Text('Total count of steps', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//       //           ]
//       //       ),
//       //       Column(
//       //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       //           children: [
//       //             ttl_stps == 0 ? Text('-') : Text('$ttl_stps')
//       //           ]
//       //       )
//       //     ]
//       // ),
//       Row(
//          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//          children: [
//            Column(
//                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                children: [
//                  Text('Total count of steps', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                  ttl_stps == 0 ? Text('-') : Text('$ttl_stps')
//                ]
//            ),
//            Column(
//                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                children: [
//                  Text('Pressure', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                  Text(pmsg)
//                ]
//            )
//          ]
//        ),
//       Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Text('Accelerometer', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                   Text(amsg)
//                 ]
//             ),
//             Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Text('Gyroscope', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                   Text(gmsg)
//                 ]
//             )
//           ]
//       ),
//       Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Text('Magnetometer', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                   Text(mmsg)
//                 ]
//             ),
//             Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Text('Is anything near?', style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)),
//                   Text('${nmsg.replaceAll("'","")}')
//                 ]
//             )
//           ]
//       ),
//     ],
//   )
    }