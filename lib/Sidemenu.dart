import 'package:flutter/material.dart';
import 'package:thesis/main.dart';
import 'package:thesis/Sensors.dart';
import 'package:thesis/Navigation.dart';
import 'package:thesis/Compass.dart';
import 'package:thesis/Login.dart';
import 'package:thesis/Settings.dart';
import 'package:hive/hive.dart';
import 'dart:io';


class Sidemenu extends StatelessWidget {


  @override
  Widget build(BuildContext context) {

    var box = Hive.box('user');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
              accountName: Text('',style: TextStyle(color: Colors.white)),
              accountEmail: Text('${box.get('email')}',style: TextStyle(color: Colors.white)),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: box.get('imagePath') != null
                  ?
                    Image(
                      image: FileImage(File(box.get('imagePath', defaultValue: null))) as ImageProvider<Object>,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                    )
                  :
                    Image.asset('assets/user.png',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover
                    ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.cyan,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage('assets/background.png')
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home_outlined),
            title: Text('Main screen'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage())),
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Route'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Navigation())),
          ),
          ListTile(
            leading: Icon(Icons.explore_outlined),
            title: Text('Compass'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Compass())),
          ),
          ListTile(
            leading: Icon(Icons.sensors_outlined,
            ),
            title: Text('Sensors'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Sensors())),
          ),
          ListTile(
            leading: Icon(Icons.settings,
            ),
            title: Text('Settings'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Settings())),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => {
              showDialog(context: context, builder: (context) => AlertDialog(
                title: Text('Logout'),
                content: Text('Are you sure you want to exit?'),
                actions: [
                  ElevatedButton(onPressed: () => {Navigator.pop(context)},
                      child: Text('No')),
                  ElevatedButton(onPressed: () async {
                    await StartScreen().stopForegroundTask();
                    //await LoginState().db.close();
                    var box = Hive.box('user');
                    box.delete('email');
                    box.delete('pass');
                    box.delete('access_token');
                    box.delete('userid');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                  }, child: Text('Yes'))
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              barrierDismissible: false,
              ),
            },
          )
        ],
      ),
    );
  }
}
