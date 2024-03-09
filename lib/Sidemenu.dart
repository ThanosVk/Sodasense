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
  const Sidemenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('user');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('', style: TextStyle(color: Colors.white)),
            accountEmail: Text('${box.get('email')}',
                style: const TextStyle(color: Colors.white)),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: box.get('imagePath') != null
                    ? Image(
                        image: FileImage(
                                File(box.get('imagePath', defaultValue: null))),
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/user.png',
                        width: 65, height: 65, fit: BoxFit.cover),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              image: DecorationImage(
                  fit: BoxFit.fill, image: AssetImage('assets/background.png')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Main screen'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const MyHomePage())),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Route'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const Navigation())),
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Compass'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const Compass())),
          ),
          ListTile(
            leading: const Icon(
              Icons.sensors_outlined,
            ),
            title: const Text('Sensors'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const Sensors())),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings,
            ),
            title: const Text('Settings'),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const Settings())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to exit?'),
                  actions: [
                    ElevatedButton(
                        onPressed: () => {Navigator.pop(context)},
                        child: const Text('No')),
                    ElevatedButton(
                        onPressed: () async {
                          await StartScreen().stopForegroundTask();
                          //await LoginState().db.close();
                          var box = Hive.box('user');
                          box.delete('email');
                          box.delete('pass');
                          box.delete('access_token');
                          box.delete('userid');
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const Login()));
                        },
                        child: const Text('Yes'))
                  ],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
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
