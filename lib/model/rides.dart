
import 'dart:typed_data';

import 'package:accessiblecity/services/map_snapshot_service.dart';

import 'running_ride.dart';
import 'finished_ride.dart';
import '../logger.dart';
import '../services/sensor_service.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

//version 1,2: unused
//version 3: initially used, with annotation and location. First with upgrade support
//version 4: snapshot added to ride

const dbVersion = 4;

class Rides extends ChangeNotifier {

  static Rides? _sharedRides;

  factory Rides() {
    _sharedRides ??= Rides._internal();
    return _sharedRides!;
  }

  Rides._internal();

  RunningRide? _currentRide;
  RunningRide? _finishingRide;  //recording is finished but not transferred to pastRides yet

  final List<FinishedRide> _pastRides = [];
  late Database _database;

  RunningRide? get currentRide => _currentRide;
  RunningRide? get finishingRide => _finishingRide;
  List<FinishedRide> get pastRides => _pastRides;

  Future<void> initialize() async {
//    final dbPath = await getDatabasesPath();
    _database = await openDatabase('rides.db', version:dbVersion, onCreate: _dbCreateTables, onUpgrade: _dbUpgrade);
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
      _finishingRide = ride;
      _currentRide = null;
      notifyListeners();
      Uint8List? snapshot = await MapSnapshotService().makeSnapshot(ride.locations, 600, 400, 20);
      FinishedRide finishedRide = await FinishedRide.createFromRunningRide(ride, _database, snapshot);
      _pastRides.add(finishedRide);
      _finishingRide = null;
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

  Future<void> _dbUpgrade(db, oldVersion, newVersion) async {
    if ((oldVersion <= 3) && (newVersion >=4)) {
      logInfo("upgrading database from v3 to v4");
      await db.execute('ALTER TABLE ride ADD COLUMN snapshot BLOB DEFAULT null');
      logInfo("finished upgrading database from v3 to v4");
    }
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
        'syncRevision INTEGER,'
        'snapshot BLOB'
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
