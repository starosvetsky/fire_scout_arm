import 'package:latlong2/latlong.dart';

class Hotspot {
  final String id;
  final LatLng location;
  String status;

  Hotspot({required this.id, required this.location, this.status = 'pending'});

  Map<String, dynamic> toMap() => {
    'id': id, 
    'latitude': location.latitude, 
    'longitude': location.longitude, 
    'status': status
  };

  factory Hotspot.fromMap(Map<String, dynamic> map) => Hotspot(
    id: map['id'], 
    location: LatLng(map['latitude'], map['longitude']), 
    status: map['status']
  );
}
