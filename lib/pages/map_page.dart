import 'package:flutter/material.dart';
import "package:google_maps_flutter/google_maps_flutter.dart";

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _MATF = LatLng(44.820048144999575, 20.458771869031093);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _MATF,
            zoom: 18,
          ),
          markers:  {
            Marker(
                markerId: MarkerId("_currentLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: _MATF)
          }),
    );
  }
}
