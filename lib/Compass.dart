import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:thesis/SqlDatabase.dart';
import 'package:thesis/Navigation.dart';
import 'dart:async';

class Compass extends StatefulWidget {
  const Compass({Key? key}) : super(key: key);

  @override
  _CompassState createState() => _CompassState();
}

class _CompassState extends State<Compass> {

  bool hasPermissions = false, serviceEnabled = false;//hasPermissions if the gps permissions are given, serviceEnabled if the gps is enabled
  double angle = 0,Altitude =0;//angle for getting the angles, Altitude for getting the altitude value from plugin
  String Address = '-',adr = '-';//Address for getting the value from plugin, adr for printing the address
  String location ='-', loc = '-';//location for getting the value from plugin, loc for printing the location
  String alt = '-';//alt for printing the altitude
  Timer ?timer;
  var box = Hive.box('user'),lat, lng;
  int art = 5;//art for altitude sampling rate
  //Date for using date in the database
  int date = 0;



  @override
  void initState() {
    super.initState();
    fetchPermissionStatus();
    FlutterCompass.events?.listen(get_angle);

    SqlDatabase.instance.database;

    setState(() {
      getData();
    });

    if(box.get('altitude_sr')!=null){
      art = box.get('altitude_sr');
    }

    timer = Timer.periodic(Duration(seconds: art), (Timer t) => insert_altitude_toDb());
    //check();
  }

  //Function for checking if the app has the location permission
  void fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  //Function for getting the angles of compass
  void get_angle(event) {
    setState(() {
      if(event.heading>0){
        angle = event.heading;
      }
      else{
        angle = event.heading + 360;
      }
    });
  }

  //Function for getting the status of Gps
  Future<Position> getGeoLocationPosition() async {

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  //Function for getting lat lng and
  Future<void> GetAddressFromLatLong(Position position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    double alt_placemarks = await position.altitude;
    print(placemarks);
    Placemark place = placemarks[0];
    setState(()  {
      Address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
    });
  }

  //Function for setting address and location
  void getData() async {
    Position position = await getGeoLocationPosition();
    lat=position.latitude.toStringAsFixed(4);
    lng=position.longitude.toStringAsFixed(4);
    //location ='Lat: ${(position.latitude).toStringAsFixed(4)} , Long: ${(position.longitude).toStringAsFixed(4)}';
    Altitude = position.altitude;

    print('$location');
    GetAddressFromLatLong(position);
  }

  void insert_altitude_toDb() async{
    date = DateTime.now().millisecondsSinceEpoch;
    await SqlDatabase.instance.insert_altitude(date,Altitude,0);
    print('KOMPLE TO ALT');
  }

  void check() async{
    List<Map> lista = await SqlDatabase.instance.select_altitude();
    print(lista);
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: Sidemenu(),
      appBar: AppBar(
        title:Text("Compass"),
        actions: <Widget>[
          IconButton(
              alignment: Alignment.center,
              icon: Icon(Icons.location_on_outlined),
              onPressed: ()  =>
              {
                getData(),
                if(serviceEnabled == true){
                  setState(() {
                    // loc = location;
                    adr = Address;
                    alt = '$Altitude';
                  }),
                }
                else{
                  print(serviceEnabled),
                  setState(() {
                    loc ='Enable gps to get coordinates';
                    adr ='Connect to internet to get Adrress';
                    alt = 'Enable gps to get altitude';
                  }),
                }
              }
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Builder(builder: (context) {
            if(hasPermissions){
              if(serviceEnabled){
                loc = location;
                adr = Address;
                alt = '$Altitude';
              }
              else{
                loc = 'Enable gps to get Location';
                adr = 'Connect to internet to get Adrress';
                alt = 'Enable gps to get altitude';
              }
              return Column(
                children: <Widget>[
                  SizedBox(height: size.height * 0.05),
                  buildCompass(),
                  Text('\n\n${angle.toStringAsFixed(0)}°'),
                  Text.rich(
                    TextSpan(
                        // style: const TextStyle(
                        //   color: Colors.black,
                        // ),
                      children: <TextSpan>[
                        TextSpan(text: 'Adrress: ',style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '$adr'),
                      ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text.rich(
                    TextSpan(
                        // style: const TextStyle(
                        //   color: Colors.black,
                        // ),
                        children: serviceEnabled==true  ? [
                          TextSpan(text: 'Lat: ',style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '${lat},'),
                          TextSpan(text: ' Lon: ',style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '${lng}'),
                        ]
                        : [
                          TextSpan(text: '$loc')
                        ]
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                        // style: const TextStyle(
                        //   color: Colors.black,
                        // ),
                        children: <TextSpan>[
                          TextSpan(text: 'Altitude: ',style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$alt'),
                        ]
                    ),
                  ),
                  //Build_Adrress(),
                ],
              );
            }
            else {
              return buildPermissionSheet();
            }
          }),
        ),
      ),
    );
  }

  //Widget for Compass
  Widget buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null)
          return Center(
            child: Text("Device does not have sensors !"),
          );

        return Material(
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            padding: EdgeInsets.all(16.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (direction * (math.pi / 180) * -1),
              child: Image.asset('assets/compass.png'),
            ),
          ),
        );
      },
    );
  }

  //Widget for showing permissions menu
  Widget buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Location Permission Required'),
          ElevatedButton(
            child: Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                fetchPermissionStatus();
              });
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
