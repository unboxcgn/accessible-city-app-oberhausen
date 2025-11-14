
import 'package:accessiblecity/model/annotation.dart';

import 'location.dart';
import '../constants.dart';
import 'package:flutter/foundation.dart';

class RunningRide extends ChangeNotifier {
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<Location> _locations = [];
  final List<Annotation> _annotations = [];
  bool _statsValid = false;
  double _distM = 0.0;
  double _motionDistM = 0.0;
  double _durationS = 0.0;
  double _motionDurationS = 0.0;
  double _maxSpeedMS = 0.0;

  DateTime get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<Location> get locations => _locations;
  List<Annotation> get annotations => _annotations;

  RunningRide();

  bool get running {
    return (_endDate == null);
  }

  void addLocation(Location l) {
    _locations.add(l);
    _statsValid = false;
    notifyListeners();
  }

  Location? getLastLocation() {
    if (_locations.isEmpty) return null;
    return _locations.last;
  }

  void addAnnotation(Annotation annotation) {
    _annotations.add(annotation);
  }

  void finish() {
    if (_endDate == null) {
      _endDate = DateTime.now();
      _validateStats();
      notifyListeners();
    }
  }

  Duration get recordingDuration {
    if (_endDate != null) {
      return _endDate!.difference(_startDate);
    } else if (_locations.isNotEmpty) {
      return _locations.last.timestamp.difference(_startDate);
    } else {
      return DateTime.now().difference(_startDate);
    }
  }

  double get totalDistanceM {
    _validateStats();
    return _distM;
  }

  double get motionDistanceM {
    _validateStats();
    return _motionDistM;
  }

  double get durationS {
    _validateStats();
    return _durationS;
  }

  double get motionDurationS {
    _validateStats();
    return _motionDurationS;
  }

  double get maxSpeedMS {
    _validateStats();
    return _maxSpeedMS;
  }

  double get averageSpeedKmh {
    _validateStats();
    return (_motionDurationS > 0)
        ? (_motionDistM / _motionDurationS) / 3.6
        : 0.0;
  }

  void _validateStats() {
    if (!_statsValid) {
      Location? lastLoc;
      var dist = 0.0;
      var motionDist = 0.0;
      var time = 0.0;
      var motionTime = 0.0;
      var maxMS = 0.0;
      for (Location loc in _locations) {
        if (lastLoc != null) {
          final s = loc.timestamp
              .difference(lastLoc.timestamp)
              .inMicroseconds
              .toDouble() /
              1000000;
          final m = loc.distance(lastLoc);
          final mpers = (s > 0) ? m / s : 0;
          if (mpers >= Constants.minMotionMperS) {
            motionDist += m;
            motionTime += s;
          }
          if (s > 0) {
            if (m / s > maxMS) {
              maxMS = m / s;
            }
          }
          dist += m;
          time += s;
        }
        lastLoc = loc;
      }
      _distM = dist;
      _motionDistM = motionDist;
      _durationS = time;
      _motionDurationS = motionTime;
      _maxSpeedMS = maxMS;
      _statsValid = true;
    }
  }
}

