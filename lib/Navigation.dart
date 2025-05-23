import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:thesis/SqlDatabase.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:thesis/Theme_provider.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider({customCacheManager});
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coords, options),
      //Now you can set options that determine how the image gets cached via whichever plugin you use.
    );
  }
}

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  NavigationState createState() => NavigationState();


}


class NavigationState extends State<Navigation> {

  bool hasPermissions = false, serviceEnabled = false;//hasPermissions if the gps permissions are given, serviceEnabled if the gps is enabled
  double lat=0, lng=0, coor_points=1000;//lat for getting the latitude, lng for getting the longitude, coor_points for setting the coordinate points on slider
  double speed=0, distance=0 ;//speed for getting the speed, distance for calculating the distance of the route

  geo.Position ?currentPosition;

  AlignOnUpdate follow_on_location_update = AlignOnUpdate.never;
  StreamController<double> follow_current_location_StreamController = StreamController<double>();

  Completer<MapController> controllerMap = Completer();
  MapController newMapController = MapController();
  List<LatLng> polylineCoordinates =[]; //for saving the coordinates temporary from db to be displayed on map
  // Polyline polylinePoints = new PolylinePoints();
  loc.Location location = new loc.Location();
  loc.LocationData ?currentLocation;
  loc.LocationData ?destinationLocation;
  //Date for using date in the database
  int date = 0;

  //Date for showing in the map
  String date_show = DateFormat('HH-mm,dd-MMMM-yyyy').format(DateTime.now());

  Map<String,List<LatLng>> polylines ={};

  Timer ?timer;//for setting the timer

  var box = Hive.box('user');

  DateTimeRange? _dateRange;

  String date_end='';
  int sl_date=0, prsd_btn_first=0, prsd_btn_second=0;

  DateTime? selected_date,selected_date_second;

  List<List> faw = [];

  //panelController for managing what happens inside the SlidingUpPanel
  final PanelController panelController = PanelController();

  late StreamSubscription<Activity> _activityStreamSubscription;
  final activityRecognition = FlutterActivityRecognition.instance;
  String currentActivity = 'UNKNOWN';

  static final customCacheManager = CacheManager(
    Config(
        'customCacheKey',
        stalePeriod: Duration(days:30),
        maxNrOfCacheObjects: 200
    ),
  );

  // Helper method to format activity type
  String formatActivityType(String activityType) {
    switch (activityType) {
      case 'IN_VEHICLE':
        return 'In Vehicle';
      case 'ON_BICYCLE':
        return 'On Bicycle';
      case 'RUNNING':
        return 'Running';
      case 'STILL':
        return 'Still';
      case 'WALKING':
        return 'Walking';
      case 'UNKNOWN':
      default:
        return 'Unknown';
    }
  }

  // Method for images path
  String getActivityImage(String activityType) {
    switch (activityType) {
      case 'In Vehicle':
        return 'assets/driving.png';
      case 'On Bicycle':
        return 'assets/cycling.png';
      case 'Running':
        return 'assets/running.png';
      case 'Still':
        return 'assets/standing.png';
      case 'Walking':
        return 'assets/walking.png';
      case 'Unknown':
      default:
        return 'assets/unknown.png';
    }
  }

  @override
  void initState() {

    super.initState();
    fetchPermissionStatus();
    SqlDatabase.instance.database;
    startActivityRecognition();

    //location.changeSettings(distanceFilter: 0,interval: 500);
    // location.changeSettings(accuracy: loc.LocationAccuracy.navigation);
    if(mounted){
      setState(() {

        follow_on_location_update = AlignOnUpdate.always;
        follow_current_location_StreamController = StreamController<double>();


        location.onLocationChanged.listen((loc.LocationData cLoc) {
          if (!mounted) return;
          currentLocation = cLoc;

          setState(() {
            setpoint(cLoc.latitude, cLoc.longitude);
            speed = cLoc.speed! * 3.6;
          });

        });

      });
    }
    // print(date);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    follow_current_location_StreamController.close();
    //timer?.cancel();
    _activityStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> startActivityRecognition() async {
    final isGranted = await isPermissionGranted();
    if (isGranted) {
      _activityStreamSubscription = activityRecognition.activityStream.handleError((error) {
        // Handle error here
        print('Activity stream error: $error');
      }).listen((activity) {
        setState(() {
          currentActivity = formatActivityType(activity.type.toString().split('.').last);
        });
        // Perform actions based on the detected activity. In this case, log the current activity
        print('Current activity: $currentActivity');
      });
    }
  }

  Future<bool> isPermissionGranted() async {
    var reqResult = await activityRecognition.checkPermission();
    if (reqResult == ActivityPermission.PERMANENTLY_DENIED) {
      print('Permission is permanently denied.');
      return false;
    } else if (reqResult == ActivityPermission.DENIED) {
      reqResult = await activityRecognition.requestPermission();
      if (reqResult != ActivityPermission.GRANTED) {
        print('Permission is denied.');
        return false;
      }
    }
    return true;
  }

  void setpoint(latitude,longitude) async{
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    lat=latitude;
    lng=longitude;
  }

  //Function for checking if the app has the location permission
  void fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  void SetLat(double Lat){
    lat=Lat;
  }

  void SetLng(double Lng){
    lng=Lng;
  }

  //Function for getting the status of Gps
  Future<geo.Position> getGeoLocationPosition() async {

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    return await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.bestForNavigation);
  }



  //Function for setting location
  void getData() async {
    geo.Position position = await getGeoLocationPosition();

    lat = position.latitude;
    lng = position.longitude;
    print('$lat,$lng');
  }

  //getCoordinates for getting the coordinates points from the first date picker
  getCoordinates(int x, int dt_st,) async{
    List<Map> lista = await SqlDatabase.instance.select_coor_first(x,dt_st);
    //int ff = await SqlDatabase.instance.select_coor();
    polylineCoordinates = [];
    //print('I lista einai $polylineCoordinates');
    for(int i=0;i<lista.length;i++){
      polylineCoordinates.add(LatLng(lista[i]['lat'], lista[i]['lng']));
    }
  }

  //getCoordinatesSecond for getting the cordinates points from the second date picker
  getCoordinatesSecond(int x, int dt_st,) async{
    List<Map> lista = await SqlDatabase.instance.select_coor_second(x,dt_st);
    //int ff = await SqlDatabase.instance.select_coor();
    polylineCoordinates = [];
    //print('I lista einai $polylineCoordinates');
    for(int i=0;i<lista.length;i++){
      polylineCoordinates.add(LatLng(lista[i]['lat'], lista[i]['lng']));
    }
  }

  void insert_toDb() async{
    if(lat!=0.0 && lng!=0.0){
      date = DateTime.now().millisecondsSinceEpoch;
      await SqlDatabase.instance.insert_coor(date,lat,lng,0);
    }
    // print('has inserted somethinggggggggggggggggg');
  }

  Future pickDate(BuildContext context) async{
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: selected_date ?? initialDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => {
      selected_date = newDate,
      sl_date = selected_date!.millisecondsSinceEpoch
    });
    print('I imerominia pou dialexes einai $sl_date');
  }

  Future pickDateSecond(BuildContext context) async{
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: selected_date_second ?? initialDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => {
      selected_date_second = newDate,
      sl_date = selected_date_second!.millisecondsSinceEpoch
    });
    print('I imerominia pou dialexes einai $sl_date');
  }

  // Future pickDateRange(BuildContext context) async {
  //   final initialDateRange = DateTimeRange(
  //     start: DateTime.now(),
  //     end: DateTime.now().add(Duration(hours: 24 * 2)),
  //   );
  //   final newDateRange = await showDateRangePicker(
  //     context: context,
  //     firstDate: DateTime(DateTime.now().year - 5),
  //     lastDate: DateTime(DateTime.now().year + 5),
  //     initialDateRange: _dateRange ?? initialDateRange,
  //   );
  //
  //   if (newDateRange == null) return;
  //
  //   setState(() =>{
  //     _dateRange = newDateRange,
  //     date_start = DateFormat('dd-MM-yyyy').format(_dateRange!.start),
  //     date_end = DateFormat('dd-MM-yyyy').format(_dateRange!.end),
  //     // print('ELAAAAAAAAAAAAA $date_start, $date_end'),
  //   });
  // }

  double getDistance() {
    double tmp_distance = 0;

    for(int i=0; i<polylineCoordinates.length - 1; i++){
      tmp_distance = tmp_distance + geo.Geolocator.distanceBetween(polylineCoordinates[i].latitude, polylineCoordinates[i].longitude,polylineCoordinates[i+1].latitude, polylineCoordinates[i].longitude);
    }

    return tmp_distance/1000;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
          drawer: Sidemenu(),
          appBar: AppBar(
            title:Text("Route"),
            systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.cyan)
          ),
          body: SafeArea(
            child: Builder(builder: (context){
              if(hasPermissions){
                // location.changeSettings(accuracy: loc.LocationAccuracy.navigation);
                // polylineCoordinates.add(LatLng(lat,lng));
                // if(polylineCoordinates[0] == LatLng(0,0)){
                //   polylineCoordinates.removeAt(0);
                // }
                //
                // polylines[date] = polylineCoordinates;
                // //polylines['ew'] = polylineCoordinates;
                // print(polylines);
                // print(polylineCoordinates.length);
                return Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    FlutterMap(
                      mapController: newMapController,
                        options:  MapOptions(
                          minZoom: 4,
                          initialCenter: LatLng(lat,lng),
                          initialZoom: 12,
                          // onMapCreated: (MapController controller){
                          //   controllerMap.complete(controller);
                          //   newMapController = controller;
                          //
                          //   // getData();
                          // },
                          onPositionChanged: (MapCamera position, bool hasGesture){
                            if(hasGesture){
                              setState(() {
                                follow_on_location_update = AlignOnUpdate.never;
                              });
                            }
                          }
                        ),
                       children: [
                         TileLayer(
                           urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                           maxZoom: 19,
                           tileProvider: CachedTileProvider(
                             customCacheManager: customCacheManager,
                           )
                         ),
                         CurrentLocationLayer(
                           // plugin: LocationMarkerPlugin(
                           //   centerCurrentLocationStream:center_current_location_StreamController.stream,
                           //   centerOnLocationUpdate: center_on_location_update
                           // ),
                           style: LocationMarkerStyle(
                             marker: DefaultLocationMarker(
                               color: Colors.green,
                               child: Icon(
                                 Icons.person,
                                 color: Colors.white,
                               ),
                             ),
                             markerSize: const Size(40, 40),
                             accuracyCircleColor: Colors.green.withOpacity(0.1),
                             headingSectorColor: Colors.green.withOpacity(0.8),
                             headingSectorRadius: 120,
                             // markerAnimationDuration: Duration(milliseconds: Duration.millisecondsPerSecond),
                           ),
                           alignPositionStream: follow_current_location_StreamController.stream,
                           alignPositionOnUpdate: follow_on_location_update,
                         ),

                         polylineCoordinates.isNotEmpty == true
                             ?
                         PolylineLayer(
                           polylines: [
                             Polyline(
                                 points: polylineCoordinates,
                                 color: Colors.red,
                                 strokeWidth: 9.0
                             )
                           ],
                           // simplificationTolerance: 0,
                         )
                             :
                         Container(),

                         MarkerLayer(
                           markers:
                             polylineCoordinates.isNotEmpty == true
                                 ?
                             [
                               Marker(
                                 width: 50,
                                 height: 32,
                                 point: polylineCoordinates.first,
                                 child: Image.asset('assets/marker_walking.png')
                               ),
                               Marker(
                                 width: 50,
                                 height: 32,
                                 point: polylineCoordinates.last,
                                 child: Image.asset('assets/marker_standing.png', scale: 15,)
                               )
                             ]
                                 :
                             [],
                           rotate: true,
                         ),
                       ],
                     ),
                    Positioned(
                      right: 20,
                      bottom: size.height * 0.06 +15,
                      child: InkWell(
                        onLongPress: (){
                          // print('MEGALLOOOOOO');
                          Clipboard.setData(ClipboardData(text: "${lat},${lng}"));
                          Fluttertoast.showToast(msg: 'The coordinates are: X:$lat, Y:$lng and copied to clipboard', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
                        },
                        onDoubleTap: (){
                          setState(()   {
                            newMapController.rotate(0);
                            follow_on_location_update = AlignOnUpdate.always;
                            follow_current_location_StreamController.add(18);
                          });
                        },
                        child: FloatingActionButton(
                          onPressed: (){
                            setState(() {
                              follow_on_location_update = AlignOnUpdate.always;
                            });
                            follow_current_location_StreamController.add(18);
                            // print('mikroooo');
                          },
                          child: Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: size.height * 0.06 + 15,
                      child: InkWell(
                        onLongPress: (){
                          polylineCoordinates = [];
                        },
                        child: FloatingActionButton(
                          onPressed: (){
                            showDialog(context: context, builder: (context) => StatefulBuilder(
                                builder: (BuildContext context, StateSetter setState) {
                                  return AlertDialog(
                                    title: Text('Set the number of coordinate points and the date you want to display on map.',
                                        textAlign: TextAlign.justify
                                    ),
                                    content: SizedBox(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Set the number of coordinate points'),
                                            Row(
                                              children: [
                                                Text('10'),
                                                Expanded(
                                                  child: Slider.adaptive(
                                                    value: coor_points,
                                                    min: 10,
                                                    max: 5000,
                                                    divisions: 5000,
                                                    label: coor_points.round().toString(),
                                                    onChanged: (coor_points) => setState(() => {
                                                      this.coor_points = coor_points,
                                                      // if(coor_points > 2000){
                                                      //   Fluttertoast.showToast(msg: 'Select more than 2000 points only if you have high-end device', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM)
                                                      // },
                                                      // print(coor_points)
                                                    }),
                                                  ),
                                                ),
                                                Text('5000')
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            Text('and the start date to show on map'),
                                            ElevatedButton(
                                              onPressed: () {
                                                pickDate(context);
                                                prsd_btn_first = 1;
                                              },
                                              child: selected_date == null ? Text('Select Date') : Text('${selected_date?.day}/${selected_date?.month}/${selected_date?.year}')
                                            ),
                                            // Row(
                                            //   children: [
                                            //     Expanded(
                                            //       child: ElevatedButton(
                                            //         onPressed: () => pickDateRange(context),
                                            //         child: _dateRange == null ? Text('From') : Text(DateFormat('dd-MM-yyyy').format(_dateRange!.start)),
                                            //       ),
                                            //     ),
                                            //     const SizedBox(width: 8),
                                            //     Icon(Icons.arrow_forward, color: Colors.white),
                                            //     const SizedBox(width: 8),
                                            //     Expanded(
                                            //       child: ElevatedButton(
                                            //         onPressed: () => pickDateRange(context),
                                            //         child: _dateRange == null ? Text('Until') : Text(DateFormat('dd-MM-yyyy').format(_dateRange!.end)),
                                            //       ),
                                            //     ),
                                            //   ],
                                            // ),
                                            Text('Or press the button below to select a specific day'),
                                            ElevatedButton(
                                              onPressed: () {
                                                pickDateSecond(context);
                                                selected_date_second = selected_date;
                                                prsd_btn_second = 1;
                                              },
                                              child: selected_date_second == null ? Text('Select Date') : Text('${selected_date_second?.day}/${selected_date_second?.month}/${selected_date_second?.year}'),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                                    actions: [
                                      ElevatedButton(
                                          onPressed: () {
                                            polylineCoordinates = [];
                                            Navigator.pop(context);
                                          },
                                          child: Text('Cancel')
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if((selected_date == '' || selected_date == null) && (selected_date_second == '' || selected_date_second == null)){
                                            Fluttertoast.showToast(msg: 'Please select a date', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                                          }
                                          else{
                                            if(prsd_btn_first == 1){
                                              if(coor_points > 2000){
                                                Fluttertoast.showToast(msg: 'Select more than 2000 points only if you have high-end device', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
                                              }
                                              await getCoordinates(coor_points.toInt(),sl_date);
                                              int total_count_points = await SqlDatabase.instance.select_coor_first_count(coor_points.toInt(),sl_date);
                                              if(total_count_points == 0){
                                                Fluttertoast.showToast(msg: 'Selected date does not have saved points', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
                                                return;
                                              }
                                              prsd_btn_first = 0;
                                              print('Patithike TO PROTO KOUMPI');
                                              print('O arithmos tis listas einai $total_count_points');
                                            }
                                            else if (prsd_btn_second == 1){
                                              await getCoordinatesSecond(coor_points.toInt(),sl_date);
                                              int total_count_points_second = await SqlDatabase.instance.select_coor_second_count(coor_points.toInt(),sl_date);
                                              if(total_count_points_second == 0){
                                                Fluttertoast.showToast(msg: 'Selected date does not have saved points', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
                                                return;
                                              }
                                              else if(total_count_points_second > 2000){
                                                Fluttertoast.showToast(msg: 'Showing only the first 2000 points', toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
                                              }
                                              prsd_btn_second = 0;
                                              print('Patithike TO DEYTERO KOUMPI');
                                              print('O arithmos tis listas einai $total_count_points_second');
                                            }
                                            if(polylineCoordinates.isNotEmpty){
                                              setState(() {
                                                distance = getDistance();
                                              });
                                            }
                                            //print('EDOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO $_dateRange'),
                                            //print('$date_start,$date_end'),
                                            Navigator.pop(context,coor_points);
                                          }
                                        },
                                        child: Text('Ok')
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),

                                  );
                                }
                            ),
                              barrierDismissible: false,
                            );
                          },
                          child: Icon(
                            FontAwesomeIcons.route,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SlidingUpPanel(
                      controller: panelController,
                      minHeight: size.height * 0.06,
                      maxHeight: size.height * 0.5,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
                      parallaxEnabled: true,
                      parallaxOffset: 0.5,
                      color: themeProvider.isDarkMode == true ? Colors.grey.shade900 : Colors.white,
                      panel: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: size.height * 0.03),
                            GestureDetector(
                              child: Center(
                                child: Container(
                                  width: 45,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                ),
                              ),
                              onTap: () => panelController.isPanelOpen ? panelController.close() : panelController.open(),
                            ),
                            SizedBox(height: size.height * 0.07),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text('Distance traveled in Km', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)),
                                        Text('${distance.toStringAsFixed(2)}', style: TextStyle(fontSize: 16.0))
                                      ]
                                  ),
                                  Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text('Moving speed in Km/h', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)),
                                        Text('${speed.toStringAsFixed(1)}', style: TextStyle(fontSize: 16.0))
                                      ]
                                  )
                                ]
                            ),
                            SizedBox(height: size.height * 0.03),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    getActivityImage(currentActivity),
                                    width: 40,
                                    height: 40,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                      children: [
                                        const AutoSizeText(
                                            'Current Activity',
                                            minFontSize: 8,
                                            maxFontSize: 14,
                                            style: TextStyle(fontWeight: FontWeight.bold)
                                        ),
                                        Text(
                                          currentActivity,
                                          style: const TextStyle(fontSize: 14.0),
                                        )
                                      ]
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }
              else{
                return buildPermissionSheet();
              }
            })
          )
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
