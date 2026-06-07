import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(MaterialApp(home: GPS()));

class GPS extends StatefulWidget {
  const GPS({super.key});

  @override
  State<GPS> createState() => _GPSState();
}

class _GPSState extends State<GPS> {
  String status = "Checking...";
  double? lat;
  double? lng;

  // Aya
  String movement = "Waiting...";
  // Aya

  List<LatLng> routePoints = [];
  bool isTracking = false;

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() => status = "Please turn on GPS");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() => status = "Permission Denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => status = "Permission denied forever");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      lat = position.latitude;
      lng = position.longitude;
      status = "GPS Ready";
    });
  }

  void liveLocation() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        return;
      }

      setState(() {
        lat = position.latitude;
        lng = position.longitude;

        // Aya
        if (isTracking) {
          double currentSpeed = position.speed * 3.6;

          if (currentSpeed < 2) {
            movement = "Standing";
          } else if (currentSpeed < 7) {
            movement = "Walking";
          } else if (currentSpeed < 15) {
            movement = "Running";
          } else {
            movement = "Driving";
          }
        }
        // Aya

        if (isTracking) {
          routePoints.add(
            LatLng(position.latitude, position.longitude),
          );
        }

        status = "Live Tracking";
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _determinePosition().then((_) => liveLocation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //Aya
          if (isTracking)
            Text(
              movement,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          //Aya
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(29.3099, 30.8418),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  tileProvider: AssetTileProvider(),
                  urlTemplate: 'assets/tiles/{z}/{x}/{y}.png',
                  errorTileCallback: (tile, error, stackTrace) {},
                ),

                if (lat != null && lng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat!, lng!),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),

                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            if (isTracking) {
              isTracking = false;
              routePoints.clear();
            } else {
              isTracking = true;
              routePoints.clear();
            }
          });
        },

        backgroundColor: isTracking ? Colors.red : Colors.green,

        label: Text(isTracking ? 'Stop' : 'Start'),

        icon: Icon(
          isTracking ? Icons.stop : Icons.play_arrow,
        ),
      ),
    );
  }
}
