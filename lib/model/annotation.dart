import 'package:accessiblecity/enums.dart';
import 'location.dart';

class Annotation {
  final int _severity;
  final Set<AnnotationTag> _tags;
  final String _comment;
  //we will not store the location directly but store date and location
  //this is easier to store in db and does not store direction and speed which
  //is not useful here.
  final DateTime _timestamp;
  final double _latitude;
  final double _longitude;
  final double _accuracy;
  final double _altitude;
  final double _altitudeAccuracy;

  Annotation ({required Location location,
    required int severity,
    required Set<AnnotationTag> tags,
    required String comment}) :
        _severity = severity,
        _tags = tags,
        _comment = comment,
        _timestamp = location.timestamp,
        _latitude = location.latitude,
        _longitude = location.longitude,
        _accuracy = location.accuracy,
        _altitude = location.altitude,
        _altitudeAccuracy = location.altitudeAccuracy;


  int get severity => _severity;
  Set<AnnotationTag> get tags => _tags;
  String get comment => _comment;
  DateTime get timestamp => _timestamp;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get accuracy => _accuracy;
  double get altitude => _altitude;
  double get altitudeAccuracy => _altitudeAccuracy;

  static Set<AnnotationTag> _tagsFromListString(String s) {
    final list = s.split(" ");
    Set<AnnotationTag> tags = {};
    for (final val in list) {
      if (val is String) {
        tags.add(annotationTagByValue(val));
      }
    }
    return tags;
  }

  String _tagsToListString() {
    List<String> list = [];
    for (final tag in _tags) {
      list.add(tag.value);
    }
    return list.join(" ");
  }

  Annotation.fromMap(Map<String, dynamic> map) :
        _severity = map['severity'] as int,
        _comment = map['comment'] as String,
        _tags = _tagsFromListString(map['tags'] as String),
        _timestamp = DateTime.fromMicrosecondsSinceEpoch(((map['timestamp'] as double) * 1000000).round()),
        _latitude = map['latitude'] as double,
        _longitude = map['longitude'] as double,
        _accuracy = map['longitude'] as double,
        _altitude = map['altitude'] as double,
        _altitudeAccuracy = map['altitudeAccuracy'] as double;

  Map<String, dynamic> toMap({double timeDelta = 0}) {
    return {
      'severity': _severity,
      'tags': _tagsToListString(),
      'comment' : _comment,
      'timestamp': _timestamp.microsecondsSinceEpoch.toDouble()/1000000 + timeDelta,
      'latitude': _latitude,
      'longitude': _longitude,
      'accuracy': _accuracy,
      'altitude': _altitude,
      'altitudeAccuracy': _altitudeAccuracy
    };
  }

}