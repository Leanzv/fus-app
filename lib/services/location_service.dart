import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) throw Exception('GPS tidak aktif.');
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) throw Exception('Izin ditolak.');
    }
    if (perm == LocationPermission.deniedForever) throw Exception('Izin ditolak permanen.');
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  double calculateDistance({required double startLat, required double startLon,
      required double endLat, required double endLon}) =>
      Geolocator.distanceBetween(startLat, startLon, endLat, endLon) / 1000;

  String formatDistance(double? km) {
    if (km == null) return 'Jarak tidak diketahui';
    return km < 1 ? '${(km * 1000).toStringAsFixed(0)} m' : '${km.toStringAsFixed(1)} km';
  }
}
