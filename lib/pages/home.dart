import 'package:iett_where_is_my_bus/services/iett.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? currentLocation;

  TextEditingController busCodeController = TextEditingController();
  TextEditingController directionController = TextEditingController();

  Future<List<List<dynamic>>>? busStopsFuture;
  Future<List<List<dynamic>>>? busLocationsFuture;

  IETT iett = IETT();

  String? selectedBusStop;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void openBusSelectionBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: busCodeController,
                      decoration: const InputDecoration(
                          labelText: "Bus", hintText: "e.g. 50D")),
                  TextField(
                      controller: directionController,
                      decoration: const InputDecoration(
                          labelText: "Direction", hintText: "e.g. G or D"))
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        busStopsFuture = iett.getLineStops(
                            busCodeController.text, directionController.text);

                        busLocationsFuture = iett.getBusLocations(
                            busCodeController.text, directionController.text);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Select"))
              ],
            ));
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();

      final location = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocation = LatLng(location.latitude, location.longitude);
      });
    } catch (e) {
      if (e is PermissionDeniedException) {
        print('Permission denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      return Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: currentLocation!,
            initialZoom: 12.6,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            if (selectedBusStop != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Stop Line: $selectedBusStop',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            FutureBuilder<List<List<dynamic>>>(
              future: busStopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MarkerLayer(markers: []);
                } else if (snapshot.hasError) {
                  return const MarkerLayer(markers: []);
                } else {
                  var busStops = snapshot.data;

                  List<Marker> markers = [];

                  if (busStops != null) {
                    for (var location in busStops) {
                      markers.add(
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: LatLng(
                            double.parse(location[1]),
                            double.parse(location[2]),
                          ),
                          child: GestureDetector(
                            child: const Icon(Icons.location_on,
                                color: Colors.red),
                            onTap: () {
                              setState(() {
                                selectedBusStop = location[0];
                              });
                            },
                          ),
                        ),
                      );
                    }
                  }

                  return MarkerLayer(markers: markers);
                }
              },
            ),
            FutureBuilder<List<List<dynamic>>>(
              future: busLocationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MarkerLayer(markers: []);
                } else if (snapshot.hasError) {
                  return const MarkerLayer(markers: []);
                } else {
                  var busLocations = snapshot.data;

                  List<Marker> markers = [];

                  if (busLocations != null) {
                    for (var location in busLocations) {
                      markers.add(
                        Marker(
                          width: 120.0,
                          height: 120.0,
                          point: LatLng(
                            double.parse(location[1]),
                            double.parse(location[2]),
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.blue),
                        ),
                      );
                    }
                  }

                  return MarkerLayer(markers: markers);
                }
              },
            ),
          ],
        ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: Colors.blue,
          overlayColor: Colors.black,
          overlayOpacity: 0.4,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.directions_bus),
              label: 'Select Bus Line',
              onTap: openBusSelectionBox,
            ),
            SpeedDialChild(
              child: const Icon(Icons.refresh),
              label: 'Refresh Bus Locations',
              onTap: () {
                setState(() {
                  busLocationsFuture = iett.getBusLocations(
                      busCodeController.text, directionController.text);
                });
              },
            ),
          ],
        ),
      );
    }
  }
}
