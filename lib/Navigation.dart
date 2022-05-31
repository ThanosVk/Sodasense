import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:thesis/Sidemenu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:thesis/SqlDatabase.dart';

class CachedTileProvider extends TileProvider {
  const CachedTileProvider({customCacheManager});
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
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
  double lat=0, lng=0;

  geo.Position ?currentPosition;

  late CenterOnLocationUpdate center_on_location_update;
  late StreamController<double> center_current_location_StreamController;

  Completer<MapController> controllerMap = Completer();
  MapController ?newMapController;
  // Set<Polyline> polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates =[];
  // Polyline polylinePoints = new PolylinePoints();

  loc.LocationData ?currentLocation;
  loc.LocationData ?destinationLocation;

  loc.Location location = new loc.Location();

  //Date for using is in the database
  String date = DateFormat('dd-MM-yyyy-HH-mm-ss').format(DateTime.now());

  //Date for showing in the map
  String date_show = DateFormat('HH-mm,dd-MMMM-yyyy').format(DateTime.now());

  Map<String,List<LatLng>> polylines ={};

  Timer ?timer;

  var box = Hive.box('user');

  static final customCacheManager = CacheManager(
    Config(
        'customCacheKey',
        stalePeriod: Duration(days:30),
        maxNrOfCacheObjects: 200
    ),
  );

  List<List> faw = [];


  @override
  void initState() {

    super.initState();

    fetchPermissionStatus();

    SqlDatabase.instance.database;

    // setState(() {
    //   getData();
    // });

    // setState(() {
    //   center_on_location_update = CenterOnLocationUpdate.always;
    //   center_current_location_StreamController = StreamController<double>();
    //   // getData();
    // });


    //location.changeSettings(distanceFilter: 0,interval: 500);
    // location.changeSettings(accuracy: loc.LocationAccuracy.navigation);
    if(mounted){
      setState(() {

        center_on_location_update = CenterOnLocationUpdate.always;
        center_current_location_StreamController = StreamController<double>();

        location.onLocationChanged.listen((loc.LocationData cLoc) {

          currentLocation = cLoc;

          setState(() {
            setpoint(cLoc.latitude, cLoc.longitude);

            //polylineCoordinates.add(LatLng(lat,lng));
            //faw.add(['$date,$lat,$lng,false']);
            //box.put('coordinates',faw);
            //if(polylineCoordinates[0] == LatLng(0,0)){
            //  polylineCoordinates.removeAt(0);
            //}

            //polylines[date] = polylineCoordinates;
            //polylines['ew'] = polylineCoordinates;
            //print(polylineCoordinates);
            // print(polylineCoordinates.length);

          });

          insert_toDb();
          getCoordinates();
        });
        //getCoordinates();

      });
    }



    print(date);
    // setState(() {
    //   getP();
    // });

    //timer = Timer.periodic(Duration(seconds: 5), (Timer t) => print(date));

  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    center_current_location_StreamController.close();
    //timer?.cancel();
    super.dispose();
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

    return await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.best);
  }



  //Function for setting location
  void getData() async {
    geo.Position position = await getGeoLocationPosition();

    lat = position.latitude;
    lng = position.longitude;
    print('$lat,$lng');


  }

  getP(){
    for(var key in polylines.keys){
      TaggedPolyline(
        tag: 'My Polyline',
        // An optional tag to distinguish polylines in callback
        points: polylines[key],
        color: Colors.red,
        strokeWidth: 9.0,
      );
    }
  }

  getCoordinates() async{
    List<Map> lista = await SqlDatabase.instance.select_coor();
    //int ff = await SqlDatabase.instance.select_coor();
    polylineCoordinates =[];
    //print('I lista einai $polylineCoordinates');
    for(int i=0;i<lista.length;i++){
      polylineCoordinates.add(LatLng(lista[i]['lat'], lista[i]['lng']));
    }
  }

  void insert_toDb() async{
    if(lat!=0.0 && lng!=0.0){
      await SqlDatabase.instance.insert_coor("'$date'",lat,lng,0);
    }
    // print('has inserted somethinggggggggggggggggg');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
          drawer: Sidemenu(),
          appBar: AppBar(
            title:Text("Navigation"),
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
                        options:  MapOptions(
                          minZoom: 4,
                          center: LatLng(lat,lng),
                          zoom: 12,
                          onMapCreated: (MapController controller){
                            controllerMap.complete(controller);
                            newMapController = controller;

                            // getData();
                          },
                          onPositionChanged: (MapPosition position, bool hasGesture){
                            if(hasGesture){
                              setState(() {
                                center_on_location_update = CenterOnLocationUpdate.never;
                              });
                            }
                          }
                        ),
                       children: [
                         TileLayerWidget(
                           options: TileLayerOptions(
                             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                             subdomains: ['a', 'b', 'c'],
                             maxZoom: 19,
                             tileProvider: CachedTileProvider(
                               customCacheManager: customCacheManager,
                             )
                           ),
                         ),
                         LocationMarkerLayerWidget(
                           plugin: LocationMarkerPlugin(
                             centerCurrentLocationStream:center_current_location_StreamController.stream,
                             centerOnLocationUpdate: center_on_location_update
                           ),
                           options: LocationMarkerLayerOptions(
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
                             markerAnimationDuration: Duration(milliseconds: Duration.millisecondsPerSecond),
                           ),
                         ),
                         TappablePolylineLayerWidget(
                           options: TappablePolylineLayerOptions(
                             polylineCulling: true,
                             pointerDistanceTolerance: 20,
                             polylines: [
                               // getP()
                               TaggedPolyline(
                                 tag: 'My Polyline',
                                 // An optional tag to distinguish polylines in callback
                                 points: polylineCoordinates,//getCoordinates()== null ? 0 : getCoordinates(),//getPoints(1)getPoints(0)
                                 color: Colors.red,
                                 strokeWidth: 9.0,
                               ),
                             ],
                             onTap: (polylines, tapPosition) => print('Tapped: ' + polylines.map((polyline) => polyline.tag).join(',') + 'at' + tapPosition.globalPosition.toString()),
                             onMiss: (tapPosition){
                               print('No polyline was tapped at position' + tapPosition.globalPosition.toString());
                             }
                           ),
                         ),

                       ],
                     ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: FloatingActionButton(
                        onPressed: (){
                          setState(() {
                            center_on_location_update = CenterOnLocationUpdate.always;
                          });
                          center_current_location_StreamController.add(18);
                        },
                        child: Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Positioned(
                    //   left: 20,
                    //   bottom: 20,
                    //   child: FloatingActionButton(
                    //     onPressed: () async {
                    //       List<Map> lista = await SqlDatabase.instance.select_coor();
                    //       //int ff = await SqlDatabase.instance.select_coor();
                    //       //print(lista.length);
                    //       for(int i=0;i<lista.length;i++){
                    //         // polylineCoordinates.add(LatLng(values[0],values[1]));
                    //         // print(polylineCoordinates);
                    //         //print(lista[i]['lat']);
                    //         //if(lista[i]['lat']!=0.0 && lista[i]['lng']!=0.0){
                    //         polylineCoordinates.add(LatLng(lista[i]['lat'], lista[i]['lng']));
                    //         print('Edom eimaim $i');
                    //         //}
                    //       }
                    //     },
                    //     child: FaIcon(
                    //       FontAwesomeIcons.route,
                    //       color: Colors.white
                    //     ),
                    //   ),
                    // ),
                    Positioned(
                      left:10,
                      top: 10,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$date_show\nX:${lat}, Y:${lng}'
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 34),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                        ],
                      ),
                    ),
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
