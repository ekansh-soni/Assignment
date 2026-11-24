/// One GPS reading. The sample generates these; a real app would
/// get them from the platform location API.
class GeoFix {
  const GeoFix(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
