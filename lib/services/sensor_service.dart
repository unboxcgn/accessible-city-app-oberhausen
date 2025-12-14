import '../logger.dart';
import '../model/running_ride.dart';
import '../model/location.dart';
import 'dart:async';
import 'package:location/location.dart' as ls;

class SensorService {

  static final SensorService _service = SensorService._internal();

  factory SensorService() {
    return _service;
  }

  SensorService._internal() {
    logInfo("SensorService internal");
  }

  final ls.Location  _location = ls.Location();
  StreamSubscription<ls.LocationData>? _locationStreamSubscription;

  Future<bool> checkPermissions() async {
    //make sure service is running
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        logInfo("location services are not enabled");
        return false;
      }
    }
    //make sure we have user permission
    ls.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == ls.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != ls.PermissionStatus.granted) {
        logErr("location permissions denied");
        return false;
      }
    }
    logInfo("location service enabled and permission granted");
    return true;
  }


  Future<bool> startRecording(RunningRide ride) async {
    if (_locationStreamSubscription != null) {
      logErr("could not start recording, already running!");
      return false;
    }
    await _location.changeSettings(accuracy: ls.LocationAccuracy.high, interval: 1000, distanceFilter: 0);

    bool bgModeEnabled = await _location.isBackgroundModeEnabled();
    if (!bgModeEnabled) {
      try {
        await _location.enableBackgroundMode();
      } catch (e) {
        logInfo("ignoring ${e.toString()}");
      }
      try {
        bgModeEnabled = await _location.enableBackgroundMode();
      } catch (e) {
        logInfo("ignoring again ${e.toString()}");
      }
    }
    if (!bgModeEnabled) {
      logErr("Could not activate location background mode");
      return false;
    }
    _locationStreamSubscription = _location.onLocationChanged.listen((ls.LocationData ld) {
      final loc = Location(
          timestamp: (ld.time != null) ? DateTime.fromMillisecondsSinceEpoch(ld.time!.toInt()) : DateTime.now(),
          latitude: ld.latitude ?? 0,
          longitude: ld.longitude ?? 0,
          accuracy: ld.accuracy ?? 0,
          altitude: ld.altitude ?? 0,
          altitudeAccuracy: ld.accuracy ?? 0,
          heading: ld.heading ?? 0,
          headingAccuracy: ld.headingAccuracy ?? 0,
          speed: ld.speed ?? 0,
          speedAccuracy: ld.speedAccuracy ?? 0);
      ride.addLocation(loc);
    });
    return true;
   }


  void stopRecording() {
    if (_locationStreamSubscription != null) {
      _location.enableBackgroundMode(enable: false);
      _locationStreamSubscription!.cancel().then((_) {
        _locationStreamSubscription = null;
      });
    }
  }
}

