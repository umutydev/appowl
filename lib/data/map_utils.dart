import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapUtils {
  static Future<void> openMap(double latitude, double longitude) async {
    final String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final String appleUrl = 'https://maps.apple.com/?q=$latitude,$longitude';

    if (Platform.isIOS) {
      if (await canLaunchUrl(Uri.parse(appleUrl))) {
        await launchUrl(
          Uri.parse(appleUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } else {
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(
          Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
