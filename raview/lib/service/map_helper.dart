import 'package:url_launcher/url_launcher.dart';

class MapHelper {
  static Future<void> openMap(double latitude, double longitude, String placeName) async {
    final encodedPlaceName = Uri.encodeComponent(placeName);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedPlaceName'
    );
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
  
  static Future<void> openDirections(double latitude, double longitude) async {
    final googleMapsDirectionsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'
    );
    
    if (await canLaunchUrl(googleMapsDirectionsUrl)) {
      await launchUrl(googleMapsDirectionsUrl);
    } else {
      throw 'Could not launch $googleMapsDirectionsUrl';
    }
  }
}
