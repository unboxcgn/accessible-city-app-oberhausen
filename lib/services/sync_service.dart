import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants.dart';
import '../logger.dart';
import '../server.dart';
import '../model/finished_ride.dart';
import '../keys.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SyncService {

  static final SyncService _service = SyncService._internal();

  final _rides = Queue<FinishedRide>();
  Timer? _timer;
  int _interval = Constants.minSyncIntervalMS;

  factory SyncService() {
    return _service;
  }

  SyncService._internal();

  void addRide(FinishedRide ride) {
    _getAppInfoString().then((s) {logInfo("build info: $s");});
    logInfo("SyncService addRide");
    if (_dirty(ride)) {
      logInfo("adding ride");
      _rides.add(ride);
      _restartTimerIfNeeded();
    } else {
      logInfo("no need to add ride");
    }
  }

  Future<String> _getAppInfoString() async {
    String s = "";
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      s = s + packageInfo.appName;
      s = "$s version ${packageInfo.version} build ${packageInfo.buildNumber}";
      if (Platform.isAndroid) {
        s = "$s Android";
      } else if (Platform.isIOS) {
        s = "$s ios";
      } else {
        s = "$s other";
      }
      final json = await rootBundle.loadString('assets/buildinfo.json');
      final entries = jsonDecode(json);
      final buildDateString = entries['build_date'] as String?;
      if (buildDateString != null) s = "$s date $buildDateString";
      final buildHeadString = entries['build_head'] as String?;
      if (buildHeadString != null) s = "$s head $buildHeadString";
      final commitHashString = entries['commit_hash'] as String?;
      if (commitHashString != null) s = "$s hash $commitHashString";
    } catch (e) {
      logErr("Could not get build info: $e");
    }
    return s;
  }

  void _restartTimerIfNeeded() {
    if ((_timer == null) && (_rides.isNotEmpty)) {
      logInfo("SyncService restarting timer interval: $_interval");
      _timer = Timer(Duration(milliseconds: _interval), _sync);
    }
  }

  /// a network action succeeded. Clear exponential backoff
  void _syncActivitySucceeded() {
    _interval = Constants.minSyncIntervalMS;
  }

  /// a network action failed. Do exponential backoff
  void _syncActivityFailed() {
    _interval = (((_interval * 3) / 2) + 0.5).floor();
    if (_interval > Constants.maxSyncIntervalMS) {
      _interval = Constants.maxSyncIntervalMS;
    }
  }

  bool _needCreate(FinishedRide ride) {
    final shouldSync = ride.syncable && ride.syncAllowed;
    final isSynced = (ride.syncRevision > 0);
    return (shouldSync && !isSynced);
  }

  bool _needUpdate(FinishedRide ride) {
    final shouldSync = ride.syncable && ride.syncAllowed;
    final isSynced = (ride.syncRevision > 0);
    final syncMismatch = (ride.syncRevision < ride.editRevision);
    return (shouldSync && isSynced && syncMismatch);
  }

  bool _needDelete(FinishedRide ride) {
    final shouldSync = ride.syncable && ride.syncAllowed;
    final isSynced = (ride.syncRevision > 0);
    return (!shouldSync && isSynced);
  }
  bool _dirty(FinishedRide ride) {
    return _needCreate(ride) || _needUpdate(ride) || _needDelete(ride);
  }

  void _sync() async {
    _timer = null;
    logInfo("SyncService syncing");
    if (_rides.isNotEmpty) {
      FinishedRide ride = _rides.first;
      //note: needXYZ are mutually exclusive
      bool needCreate = _needCreate(ride);
      bool needUpdate = _needUpdate(ride);
      bool needDelete = _needDelete(ride);
      int lastRevision = ride.editRevision;
      if (needCreate) {
        bool ok = await _createRide(ride);
        if (ok) {
          ride.syncRevision = lastRevision;
          _rides.removeFirst();
          _syncActivitySucceeded();
        } else {
          _syncActivityFailed();
        }
        _restartTimerIfNeeded();
      } else if (needUpdate) {
        bool ok = await _updateRide(ride);
        if (ok) {
          ride.syncRevision = lastRevision;
          _rides.removeFirst();
          _syncActivitySucceeded();
        } else {
          _syncActivityFailed();
        }
        _restartTimerIfNeeded();
      } else if (needDelete) {
        bool ok = await _deleteRide(ride);
        if (ok) {
          ride.syncRevision = 0;
          _rides.removeFirst();
          _syncActivitySucceeded();
        } else {
          _syncActivityFailed();
        }
        _restartTimerIfNeeded();
      } else {
        logInfo("need nothing");
        //there was nothing to do with this entry
        _rides.removeFirst();
        _syncActivitySucceeded(); //well...
        _restartTimerIfNeeded();
      }
    }
    _restartTimerIfNeeded();
  }

  Future<bool> _createRide(FinishedRide ride) async {
    logInfo("performing create");
    final ridedata = ride.toAnonymousJson(withLocations: true, withAnnotations: true);
    ridedata['clientinfo'] = await _getAppInfoString();
    final ridedataJson = jsonEncode(ridedata);
    final signature = ride.sign(ridedataJson);
    final request = {
      'apikey'    : Keys.apiKey,
      'uuid'      : ridedata['uuid'],
      'data'      : ridedataJson,
      'signature' : signature
    };
    return await _apiRequest(request);
  }

  Future<bool> _updateRide(FinishedRide ride) async {
    logInfo("performing update");
    final ridedata = ride.toAnonymousJson(withLocations: false, withAnnotations: true);
    final ridedataJson = jsonEncode(ridedata);
    final signature = ride.sign(ridedataJson);
    final request = {
      'apikey'    : Keys.apiKey,
      'uuid'      : ridedata['uuid'],
      'data'      : ridedataJson,
      'signature' : signature
    };
    return await _apiRequest(request);
  }

  Future<bool> _deleteRide(FinishedRide ride) async {
    logInfo("performing delete");
    final ridedata = ride.toAnonymousJson(withLocations: false, withAnnotations: false);
    ridedata['action'] = "DELETE";
    final ridedataJson = jsonEncode(ridedata);
    final signature = ride.sign(ridedataJson);
    final request = {
      'apikey'    : Keys.apiKey,
      'uuid'      : ridedata['uuid'],
      'data'      : ridedataJson,
      'signature' : signature
    };
    return await _apiRequest(request);
  }

  Future<bool> _apiRequest(Map<String, dynamic> request) async {
    try {
      final url = Uri(
        scheme: Server.protocol,
        host: Server.name,
        port: Server.port,
        path: Server.apiPath
      );
      final json = jsonEncode(request);
      logInfo("request is $json");
      final response = await http.post(url, headers: {HttpHeaders.contentTypeHeader: "application/json"}, body: json);
      logInfo('Response status: ${response.statusCode}');
      logInfo('Response body: ${response.body}');
      return (response.statusCode == 200);
    } catch (e) {
      logInfo("_apiRequest exception $e");
      return false;
    }
  }


  }