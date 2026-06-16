import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hotspot.dart';
import '../services/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng baseLocation = const LatLng(56.1333, 86.1167);
  List<Hotspot> hotspots = [];
  LatLng? currentLocation;
  final MapController _mapController = MapController();

  final List<LatLng> optimizedRoute = [
    const LatLng(56.1333, 86.1167),
    const LatLng(56.1500, 86.1000),
    const LatLng(56.1800, 86.1500),
    const LatLng(56.1200, 86.2000),
    const LatLng(56.1333, 86.1167),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initLocationTracking();
  }

  Future<void> _loadData() async {
    var loadedHotspots = await DatabaseHelper.instance.getAllHotspots();
    if (loadedHotspots.isEmpty) {
      loadedHotspots = [
        Hotspot(id: "T-01", location: const LatLng(56.1500, 86.1000)),
        Hotspot(id: "T-02", location: const LatLng(56.1800, 86.1500)),
        Hotspot(id: "T-03", location: const LatLng(56.1200, 86.2000)),
      ];
      for (var h in loadedHotspots) {
        await DatabaseHelper.instance.insertHotspot(h);
      }
    }
    setState(() {
      hotspots = loadedHotspots;
    });
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
      ).listen((Position position) {
        setState(() { currentLocation = LatLng(position.latitude, position.longitude); });
      });
    }
  }

  void _updateHotspotStatus(Hotspot hotspot, String newStatus) async {
    await DatabaseHelper.instance.updateStatus(hotspot.id, newStatus);
    setState(() { hotspot.status = newStatus; });
    Navigator.pop(context);
  }

  void _showActionDialog(Hotspot hotspot) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Термоточка ${hotspot.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _updateHotspotStatus(hotspot, 'confirmed'), child: const Text('Пожар', style: TextStyle(color: Colors.white))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _updateHotspotStatus(hotspot, 'false_alarm'), child: const Text('Ложное', style: TextStyle(color: Colors.white))),
                ],
              )
            ],
          ),
        );
      }
    );
  }

  Color _getMarkerColor(String status) {
    if (status == 'confirmed') return Colors.red;
    if (status == 'false_alarm') return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Патруль: Красный Яр'), backgroundColor: Colors.blueGrey),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: baseLocation, initialZoom: 11.5),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.firescout.arm'),
          PolylineLayer(polylines: [Polyline(points: optimizedRoute, strokeWidth: 4.0, color: Colors.blueAccent.withOpacity(0.8))]),
          MarkerLayer(
            markers: [
              Marker(point: baseLocation, width: 50, height: 50, child: const Icon(Icons.security, color: Colors.blue, size: 40)),
              ...hotspots.map((h) => Marker(
                point: h.location, width: 50, height: 50,
                child: GestureDetector(onTap: () => _showActionDialog(h), child: Icon(Icons.local_fire_department, color: _getMarkerColor(h.status), size: 40)),
              )),
              if (currentLocation != null)
                Marker(point: currentLocation!, width: 30, height: 30, child: const Icon(Icons.navigation, color: Colors.purple, size: 30)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { if (currentLocation != null) _mapController.move(currentLocation!, 13); },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
