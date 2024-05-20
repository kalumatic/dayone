import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const LatLng _MATF =
      LatLng(44.820048144999575, 20.458771869031093); // just for start position

  LatLng? _currentP = null;
  LatLng? _lastP = null;
  LatLng? _startP = null;

  double _distanceCovered = 0.0;
  final _stopwatch = Stopwatch(); // measuring time elapsed

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  double _pinPill = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
              child: _currentP == null
                  ? const Center(child: Text("Loading..."))
                  : GoogleMap(
                      onMapCreated: ((GoogleMapController controller) =>
                          _mapController.complete(controller)),
                      initialCameraPosition: CameraPosition(
                        target: _MATF,
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                            markerId: MarkerId("_currentLocation"),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure),
                            position: _currentP!),
                        Marker(
                            markerId: MarkerId("_startLocation"),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange),
                            position: _startP!)
                      },
                      onTap: (cordinate) {
                        setState(() {
                          _pinPill = 0;
                        });
                      },
                    )),
          Container(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  setState(() {
                    _pinPill = 1;
                  });
                },
                child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.fastOutSlowIn,
                    width: MediaQuery.of(context).size.width,
                    height: _pinPill == 0
                        ? MediaQuery.of(context).size.height / 6
                        : MediaQuery.of(context).size.height / 3.2,
                    decoration: BoxDecoration(
                        color: const Color(0xFF00246B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              blurRadius: 20,
                              offset: Offset.zero,
                              color: Colors.grey.withOpacity(0.5))
                        ]),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            child: Text(
                              " Duration: ${(_printDuration(Duration(milliseconds: _stopwatch.elapsedMilliseconds)))}"
                              "\n Distance: ${_distanceCovered.toStringAsFixed(2)} (km)"
                              "\n Pace: ${(_printPace(Duration(milliseconds: _distanceCovered == 0.0 ? 0 : (_stopwatch.elapsedMilliseconds / _distanceCovered).toInt())))} (min/km)",
                              textScaler: TextScaler.linear(2.0),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFCADCFC)),
                            ),
                          )
                        ])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 15);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          if (_currentP == null) {
            // set the start position
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _startP = _currentP;
            cameraToPosition(_currentP!);
            _stopwatch.start();
          } else {
            _lastP = _currentP;
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _distanceCovered += calculateDistance();
            cameraToPosition(_currentP!);
          }
        });
      }
    });
  }

  double calculateDistance() {
    FlutterMapMath flutterMapMath = FlutterMapMath();
    return flutterMapMath.distanceBetween(_lastP!.latitude, _lastP!.longitude,
        _currentP!.latitude, _currentP!.longitude, "kilometers");
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _printPace(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
