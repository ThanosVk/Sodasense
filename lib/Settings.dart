import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:provider/provider.dart';
import 'package:thesis/Theme_provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  final sensors_contr = TextEditingController(),alt_contr = TextEditingController();//sensors_contr for getting sampling rate of sensors, alt_contr for getting sampling rate of altitude
  int sensors_count=0 ,alt_count=0;//sensors_count for getting the value of sensors_contr, alt_count for getting the value of alt_contr
  String sensors_value = '',alt_value = '';//sensors_value for getting value from sensors listener,alt_value for getting value from altitude listener
  var box = Hive.box('user');


  @override
  void initState(){
    super.initState();

    //Start listening to changes with listeners
    sensors_contr.addListener(sensorsvalue);
    alt_contr.addListener(altvalue);
  }

  @override
  void dispose(){
    //Clean controllers when the widget is removed from the widget tree
    //and removes the values of both listeners
    sensors_contr.dispose();
    alt_contr.dispose();
    super.dispose();
  }

  //Function for getting string from sensors controller
  String sensorsvalue(){
    return sensors_value;
  }

  //Function for getting string from altitude controller
  String altvalue(){
    return alt_value;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      drawer: Sidemenu(),
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.only(left: 10, right: 10,bottom: 10,top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: SwitchListTile.adaptive(
                title: Text('Toggle between light and dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value){
                  final provider = Provider.of<ThemeProvider>(context,listen: false);
                  provider.toggleTheme(value);
                }
              ),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.only(left: 10, right: 10,bottom: 10,top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                title: Text('Change sampling rate of sensors'),
                onTap: () => showDialog(context: context, builder: (context) =>
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          title: Text('Set the sampling rate in seconds of all the sensors on the Sensors screen (the default is 10 seconds)',
                              textAlign: TextAlign.justify
                          ),
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
                                        counterText: ''
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            ElevatedButton(onPressed: () => {
                              box.put('sensors_sr',int.parse(sensors_contr.text)),
                              sensors_contr.clear(),
                              Navigator.pop(context,box.get('sensors_sr')),
                            },child: Text('Ok')),
                          ],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        );
                      }
                    )
                ),
              ),
            ),
            Card(
              shadowColor: Colors.grey,
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.only(left: 10, right: 10,bottom: 10,top: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              child: ListTile(
                title: Text('Change sampling rate of altitude'),
                onTap: () => showDialog(context: context, builder: (context) =>
                    StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return AlertDialog(
                            title: Text('Set the sampling rate in seconds of altitude (the default is 5 seconds)',
                                textAlign: TextAlign.justify
                            ),
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
                                          counterText: ''
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              ElevatedButton(onPressed: () => {
                                box.put('altitude_sr',int.parse(alt_contr.text)),
                                alt_contr.clear(),
                                Navigator.pop(context,box.get('altitude_sr')),
                              },child: Text('Ok')),
                            ],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          );
                        }
                    )
                ),
              ),
            ),
        Card(
          shadowColor: Colors.grey,
          elevation: 10,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.only(left: 10, right: 10,bottom: 10,top: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          child: ListTile(
            title: Text('Copy DB'),
            onTap: () async {
              final dbFolder = await getDatabasesPath();
              File source1 = File('$dbFolder/db.db');

              Directory copyTo = Directory("/storage/self/primary/Download");
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

              Fluttertoast.showToast(msg: 'Successfully Copied DB', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
            },
          ),
        )
          ],
        ),
      ),
    );
  }



}
