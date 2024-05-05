import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapView extends StatefulWidget {
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController mapController = MapController();
  late Position? _currentPosition = null;
  List<LatLng> parkingLocations = [];

 

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchParkingLocations(); // Call function to fetch parking locations
  }

  _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

   bool _isLoading = true; // Add a boolean flag to track loading state

 _fetchParkingLocations() async {
  if (!_isLoading) return; // If already loading, exit function
  _isLoading = true; // Set loading flag to true
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/parking/parkings'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        parkingLocations = data
            .where((parking) => parking['location'] != null && parking['location'].toString().isNotEmpty) // Filter out null or empty locations
            .map((parking) {
              final locationParts = parking['location'].split(',');
              if (locationParts.length == 2) {
                return LatLng(
                  double.tryParse(locationParts[1].trim()) ?? 0.0, // Latitude comes first in the backend
                  double.tryParse(locationParts[0].trim()) ?? 0.0, // Longitude comes second in the backend
                );
              } else {
                throw Exception('Invalid location format: ${parking['location']}');
              }
            })
            .toList();
        _isLoading = false; // Set loading flag to false after successful loading
      });
    } else {
      throw Exception('Failed to load parking locations');
    }
  } catch (error) {
    print('Error fetching parking locations: $error');
    _isLoading = false; // Set loading flag to false on error
  }
}

 @override
Widget build(BuildContext context) {
  List<LatLng> currentLocation = [
    LatLng(
      _currentPosition?.latitude ?? 36.844657774297985,
      _currentPosition?.longitude ?? 10.269209487777578,
    )
  ];

  return FutureBuilder<void>(
    future: _fetchParkingLocations(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // While fetching data, show a loading indicator
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      } else if (snapshot.hasError) {
        // If there's an error while fetching data, show an error message
        return Scaffold(
          body: Center(
            child: Text('Error loading data: ${snapshot.error}'),
          ),
        );
      } else {
        // If data is fetched successfully, display the map with parking locations
        return Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(36.8416, 10.2752),
                    zoom: 12.0,
                  ),
                  mapController: mapController,
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: parkingLocations
                          .map(
                            (location) => Marker(
                              width: 60.0,
                              height: 60.0,
                              point: location,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.car_detailed,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    MarkerLayer(
                      markers: currentLocation
                          .map(
                            (location) => Marker(
                              width: 60.0,
                              height: 60.0,
                              point: location,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        mapController.move(
                            mapController.center, mapController.zoom + 1.0);
                      },
                      child: Icon(Icons.add),
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: () {
                        mapController.move(
                            mapController.center, mapController.zoom - 1.0);
                      },
                      child: Icon(Icons.remove),
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: () {
                        mapController.move(
                            LatLng(
                              _currentPosition?.latitude ?? 36.844657774297985,
                              _currentPosition?.longitude ?? 10.269209487777578,
                            ),
                            20.0);
                      },
                      child: Icon(Icons.center_focus_strong),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    },
  );
}
}