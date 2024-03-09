import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thesis/EditProfile.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:provider/provider.dart';
import 'package:thesis/Theme_provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final stepController = TextEditingController(),
      heightController =
          TextEditingController(); //stepController for getting steps target, heightController for getting height
  final sensors_contr = TextEditingController(),
      alt_contr =
          TextEditingController(); //sensors_contr for getting sampling rate of sensors, alt_contr for getting sampling rate of altitude
  int sensors_count = 0,
      alt_count =
          0; //sensors_count for getting the value of sensors_contr, alt_count for getting the value of alt_contr
  //steps_count for getting the value of stepController, steps_target for getting the value of textfield, height _count for getting the value of height Controller
  //height for getting the value from heightController Textfield
  int steps_count = 0, steps_target = 0, height_count = 0, height = 0;
  double steps_length = 0,
      dist =
          0; //steps_length for finding the exact meters per user height,dist for distance in km
  String sensors_value = '',
      alt_value =
          ''; //sensors_value for getting value from sensors listener,alt_value for getting value from altitude listener
  bool height_validate = true,
      height_check =
          false; // height_validate for height validate textfield, height_check to know if height Textfield contains something
  late List<bool> isSelected = [
    true,
    false
  ]; //isSelected for gender toggle buttons
  var box = Hive.box('user');

  @override
  void initState() {
    super.initState();

    //Start listening to changes with listeners
    sensors_contr.addListener(sensorsvalue);
    alt_contr.addListener(altvalue);

    //Start listening to values with listener
    stepController.addListener(stepscount);
    heightController.addListener(heightcount);
  }

  @override
  void dispose() {
    //Clean controllers when the widget is removed from the widget tree
    //and removes the values of both listeners
    sensors_contr.dispose();
    alt_contr.dispose();
    stepController.dispose();
    heightController.dispose();
    super.dispose();
  }

  //Function for getting string from sensors controller
  String sensorsvalue() {
    return sensors_value;
  }

  //Function for getting string from altitude controller
  String altvalue() {
    return alt_value;
  }

  //For getting steps from stepController
  int stepscount() {
    return steps_count;
  }

  //For getting height from heightController
  int heightcount() {
    return height_count;
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: Sidemenu(),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: SwitchListTile.adaptive(
                  title: const Text('Toggle between light and dark theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    final provider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    provider.toggleTheme(value);
                  }),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                  title: const Text('Edit profile'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const EditProfile()))),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                title: const Text('Change sampling rate of sensors'),
                onTap: () => showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: const Text(
                                'Set the sampling rate in seconds of all the sensors on the Sensors screen (the default is 10 seconds)',
                                textAlign: TextAlign.justify),
                            content: SizedBox(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      maxLength: 5,
                                      controller: sensors_contr,
                                      decoration: InputDecoration(
                                          labelText: "Sampling rate in seconds",
                                          counterText: '',
                                          hintText:
                                              box.get('sensors_sr') == null
                                                  ? ""
                                                  : "${box.get('sensors_sr')}"),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: () => {
                                        box.put('sensors_sr',
                                            int.parse(sensors_contr.text)),
                                        sensors_contr.clear(),
                                        Navigator.pop(
                                            context, box.get('sensors_sr')),
                                      },
                                  child: const Text('Ok')),
                            ],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                          );
                        })),
              ),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                title: const Text('Change sampling rate of altitude'),
                onTap: () => showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: const Text(
                                'Set the sampling rate in seconds of altitude (the default is 5 seconds)',
                                textAlign: TextAlign.justify),
                            content: SizedBox(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      maxLength: 5,
                                      controller: alt_contr,
                                      decoration: InputDecoration(
                                          labelText: "Sampling rate in seconds",
                                          counterText: '',
                                          hintText: box.get('altitude_sr') ==
                                                  null
                                              ? ""
                                              : "${box.get('altitude_sr')}"),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: () => {
                                        box.put('altitude_sr',
                                            int.parse(alt_contr.text)),
                                        alt_contr.clear(),
                                        Navigator.pop(
                                            context, box.get('altitude_sr')),
                                      },
                                  child: const Text('Ok')),
                            ],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                          );
                        })),
              ),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
              child: ListTile(
                  title: const Text('Change steps, height and gender'),
                  onTap: () => showDialog(
                        context: context,
                        builder: (context) => StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
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
                                    TextField(
                                      maxLength: 5,
                                      controller: stepController,
                                      decoration: InputDecoration(
                                          labelText: "Steps Target",
                                          counterText: '',
                                          hintText: box.get('target_steps') ==
                                                  null
                                              ? ""
                                              : "${box.get('target_steps')}"),
                                      keyboardType: TextInputType.number,
                                    ),
                                    TextField(
                                      maxLength: 3,
                                      controller: heightController,
                                      decoration: InputDecoration(
                                          labelText: "Height in cm",
                                          errorText: height_validate
                                              ? null
                                              : Height_Textfield_check(),
                                          counterText: '',
                                          hintText: box.get('height') == null
                                              ? ""
                                              : "${box.get('height')}"),
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
                                      children: const <Widget>[
                                        Text('Male'),
                                        Text('Female')
                                      ],
                                      onPressed: (int index) {
                                        setState(() {
                                          //final box = Boxes.getUser();
                                          //box.add(user);
                                          for (int i = 0; i < 2; i++) {
                                            if (i == index) {
                                              isSelected[i] = true;
                                              box.put('gender', 'male');
                                              print(box.get('gender'));
                                            } else {
                                              isSelected[i] = false;
                                              box.put('gender', 'female');
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
                                        if (stepController.text.isEmpty ==
                                                false &&
                                            heightController.text.isEmpty ==
                                                false &&
                                            int.parse(heightController.text) <=
                                                250)
                                          {
                                            if (isSelected[0] == true)
                                              {
                                                height = int.parse(
                                                    heightController.text),
                                                steps_length = (height *
                                                        0.415) /
                                                    100, // /100 to make it in meters
                                                print('male'),
                                              }
                                            else
                                              {
                                                height = int.parse(
                                                    heightController.text),
                                                steps_length = (height *
                                                        0.413) /
                                                    100, // /100 to make it in meters
                                                print('female')
                                              },
                                            steps_target =
                                                int.parse(stepController.text),
                                            box.put('height', height),
                                            box.put(
                                                'steps_length', steps_length),
                                            box.put(
                                                'target_steps', steps_target),
                                            // user.save(),
                                            stepController.clear(),
                                            heightController.clear(),
                                            Navigator.pop(
                                                context, steps_target),
                                          }
                                      },
                                  child: const Text('Ok')),
                            ],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                          );
                        }),
                        barrierDismissible: false,
                      )),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                title: const Text('Save DB to downloads'),
                onTap: () async {
                  final dbFolder = await getDatabasesPath();
                  File source1 = File('$dbFolder/db.db');

                  Directory copyTo =
                      Directory("/storage/self/primary/Download");
                  if ((await copyTo.exists())) {
                    // print("Path exist");
                    // var status = await Permission.storage.status;
                    // if (!status.isGranted) {
                    //   await Permission.storage.request();
                    // }
                  } else {
                    print("not exist");
                    // if (await Permission.storage.request().isGranted) {
                    // Either the permission was already granted before or the user just granted it.
                    await copyTo.create();
                    // } else {
                    //   print('Please give permission');
                    // }
                  }

                  String newPath = "${copyTo.path}/db.db";
                  await source1.copy(newPath);

                  Fluttertoast.showToast(
                      msg: 'Successfully Copied DB',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
