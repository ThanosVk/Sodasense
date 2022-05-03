import 'package:flutter/material.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:provider/provider.dart';
import 'package:thesis/Theme_provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {



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
            SwitchListTile.adaptive(
              title: Text('Toggle between light and dark theme'),
              value: themeProvider.isDarkMode,
              onChanged: (value){
                final provider = Provider.of<ThemeProvider>(context,listen: false);
                provider.toggleTheme(value);
              }
            )
          ],
        ),
      ),
    );
  }



}
