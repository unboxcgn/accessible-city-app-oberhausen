import 'running_ride.dart';
import 'finished_ride.dart';
import '../logger.dart';
import '../services/sensor_service.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

const dbVersion = 3;

class Rides extends ChangeNotifier {

  static Rides? _sharedRides;

  factory Rides() {
    _sharedRides ??= Rides._internal();
    return _sharedRides!;
  }

  Rides._internal();

  RunningRide? _currentRide;
  final List<FinishedRide> _pastRides = [];
  late Database _database;

  RunningRide? get currentRide => _currentRide;
  List<FinishedRide> get pastRides => _pastRides;

  Future<void> initialize() async {
//    final dbPath = await getDatabasesPath();
    _database = await openDatabase('rides.db', version:dbVersion, onCreate: _dbCreateTables);
    await _dbLoadRides();
  }

  Future<bool> startRide() async {
    if (_currentRide != null) return false;
    final permissionsOk = await SensorService().checkPermissions();
    if (!permissionsOk) return false;
    _currentRide = RunningRide();
    final startOk = await SensorService().startRecording(_currentRide!);
    if (!startOk) {
      _currentRide = null;
      return false;
    }
    logInfo("started ride");
    notifyListeners();
    return true;
  }

  Future<void> finishCurrentRide() async {
    logInfo("ride: finishCurrentRide");
    if (_currentRide != null) {
      logInfo("ride: have current ride");
      SensorService().stopRecording();
      RunningRide ride = _currentRide as RunningRide;
      ride.finish();
      FinishedRide finishedRide = FinishedRide.fromRunningRide(ride, _database);
      _pastRides.add(finishedRide);
      logInfo("ride: added ride to past rides, now ${_pastRides.length}");
      _currentRide = null;
      notifyListeners();
    }
  }

  Future<void> deleteRide(FinishedRide ride) async {
    logInfo("DATABASE: deleting ride ${ride.uuid}");
    //TODO: Make sure we're out of syncing service
    _pastRides.remove(ride);
    await _database.delete('location', where: 'rideId = ?', whereArgs: [ride.dbId]);
    await _database.delete('ride', where: 'uuid = ?', whereArgs: [ride.uuid]);
    notifyListeners();
  }

  Future<void> _dbCreateTables(db, version) async {
    await db.execute('CREATE TABLE IF NOT EXISTS ride('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'uuid TEXT,'
        'name TEXT,'
        'startDate REAL,'
        'endDate REAL,'
        'dist REAL,'
        'motionDist REAL,'
        'duration REAL,'
        'motionDuration REAL,'
        'maxSpeed REAL,'
        'privateKey TEXT,'
        'publicKey TEXT,'
        'rideType INTEGER,'
        'vehicleType INTEGER,'
        'mountType INTEGER,'
        'flags INTEGER,'
        'comment TEXT,'
        'pseudonymSeed INTEGER,'
        'syncAllowed INTEGER,'
        'editRevision INTEGER,'
        'syncRevision INTEGER'
        ')');
    await db.execute('CREATE TABLE IF NOT EXISTS location('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'rideId INTEGER,'
        'timestamp REAL,'
        'latitude REAL,'
        'longitude REAL,'
        'accuracy REAL,'
        'altitude REAL,'
        'altitudeAccuracy REAL,'
        'heading REAL,'
        'headingAccuracy REAL,'
        'speed REAL,'
        'speedAccuracy REAL'
        ')');
    await db.execute('CREATE TABLE IF NOT EXISTS annotation ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'rideId INTEGER,'
        'severity INTEGER,'
        'tags TEXT,'
        'comment TEXT,'
        'timestamp REAL,'
        'latitude REAL,'
        'longitude REAL,'
        'accuracy REAL,'
        'altitude REAL,'
        'altitudeAccuracy REAL'
        ')');
  }

  Future<void> _dbLoadRides() async {
    final rides = await _database.query('ride', orderBy: 'startDate');
//    logInfo("DATABASE: Loading rides $rides");
    for (final rideMap in rides) {
      _pastRides.add(FinishedRide.fromDbEntry(_database, rideMap));
    }
    notifyListeners();
  }

}
