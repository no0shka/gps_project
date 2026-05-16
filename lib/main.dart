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
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!position.latitude.isFinite || !position.longitude.isFinite) return;
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        if (isTracking) {
          routePoints.add(LatLng(position.latitude, position.longitude));
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
      appBar: AppBar(
        title: Text('GPS', style: TextStyle(color: Colors.amberAccent)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
      ),
      body: FlutterMap(
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
            if (lat != null && lng != null && lat!.isFinite && lng!.isFinite)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat!, lng!),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
          if (routePoints.length >= 2)
            if (routePoints.length >= 2)
              Builder(
                builder: (context) {
                  try {
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      ],
                    );
                  } catch (e) {
                    return SizedBox.shrink();
                  }
                },
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
        icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}