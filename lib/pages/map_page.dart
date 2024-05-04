import 'dart:async';

import 'package:flutter/material.dart';
import "package:google_maps_flutter/google_maps_flutter.dart";
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const LatLng _MATF = LatLng(44.820048144999575, 20.458771869031093);

  LatLng? _currentP = null;
  LatLng? _startP = null;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(child: Text("Loading..."))
          : GoogleMap(
              onMapCreated: ((GoogleMapController controller) =>
                  _mapController.complete(controller)),
              initialCameraPosition: CameraPosition(
                target: _MATF,
                zoom: 18,
              ),
              markers: {
                  Marker(
                      markerId: MarkerId("_currentLocation"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                      position: _currentP!),
                  Marker(
                      markerId: MarkerId("_destinationLocation"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      position: _startP!)
                }),
    );
  }

  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 18);
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
          if (_currentP == null) { // set the start position
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _startP = _currentP;
            cameraToPosition(_currentP!);
          } else {
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            cameraToPosition(_currentP!);
          }
        });
      }
    });
  }
}
