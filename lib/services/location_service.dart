import 'package:geolocator/geolocator.dart';

class LocationService {
  // Minta izin dan dapatkan lokasi user
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Layanan GPS tidak aktif. Aktifkan GPS di pengaturan perangkat.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Izin lokasi ditolak permanen. Aktifkan di pengaturan aplikasi.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Hitung jarak antara dua koordinat (dalam km)
  double calculateDistance({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon) /
        1000;
  }

  // Format jarak untuk tampilan
  String formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Jarak tidak diketahui';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
