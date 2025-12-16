import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:accessiblecity/enums.dart';
import 'package:accessiblecity/model/running_ride.dart';
import 'package:accessiblecity/services/map_snapshot_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../logger.dart';
import '../constants.dart';
import '../services/sensor_service.dart';
import '../model/rides.dart';
import '../model/map_data.dart';
import '../model/location.dart';
import '../model/annotation.dart' as ride_annotation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';

// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:mbtiles/mbtiles.dart';
import "package:latlong2/latlong.dart";

class RecordScreenFM extends StatefulWidget {
  const RecordScreenFM({super.key});

  @override
  State<RecordScreenFM> createState() => RecordScreenStateFM();
}

class RecordScreenStateFM extends State<RecordScreenFM> {
  final MapData _mapData = MapData();
  bool _trackUserLocation = true;
  static GlobalKey _mapContainer = GlobalKey();
  final MapController _controller = MapController();
  vtr.Theme? _theme = null;

  @override
  void initState() {
    super.initState();
    SensorService().checkPermissions();
    _readTheme();
  }

  Future<void> _readTheme() async {
    logInfo("style path is ${_mapData.styleJsonPath}");
    final file = File(_mapData.styleJsonPath);
    final str = await file.readAsString();
    final map = json.decode(str);
    setState(() {
      _theme = vtr.ThemeReader().read(map);
    });
  }


  void _finishRide(context) async {
    /* This is actually a workaround: flutter_maplibe_gl does not expose offscreen
    rendering functions in its current form. We want some form of raster image
    of the ride for the rides list view. So when finishing a ride, the map will
    zoom out and take a screenshot when finishing.

    This does not work for iOS. Need to find another way. All commented out but
    RepaintBoundary left in for future experiments. If this approach does not
    turn out successfully, the RepaintBoundary and all this code may go.
*/
    final mapContext = _mapContainer.currentContext;
    Uint8List pngBytes = Uint8List(0);

    if (mapContext != null) {
      final boundary = mapContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
        pngBytes = byteData!.buffer.asUint8List();
      }
    }
    Rides rides = Provider.of<Rides>(context, listen: false);
    RunningRide ride = rides.currentRide!;
    List<Location> locations = ride.locations!;
    locations = [
      Location(latitude: 50.9365, longitude: 6.9398, accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime(2025)),
//      Location(latitude: 50.9375, longitude: 6.9398, accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime(2025)),
//      Location(latitude: 50.9365, longitude: 6.941, accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime(2025)),
//      Location(latitude: 50.935, longitude: 6.936, accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime(2025)),
    ];
    MapSnapshotService service = MapSnapshotService();
    Uint8List? preview = await service.makeSnapshot(locations, 600, 300, 20);
    if (preview != null) {
      pngBytes = preview;
    } else {
      final ByteData bytes = await rootBundle.load('assets/images/no_preview.png');
      pngBytes = bytes.buffer.asUint8List();
    }
    logInfo("PNG size: ${pngBytes.length}");
    await showAdaptiveDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          children: [
            Expanded(
              child: Image.memory(pngBytes),
            ),
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
          ]
        )
      );
    });

    rides.finishCurrentRide();
  }


  @override
  Widget build(BuildContext context) {

    //assemble tile providers for all loaded maps
    Map<String, VectorTileProvider> tileProviders = {};
    for (final name in _mapData.loadedMaps) {
      final mbtiles = MbTiles(mbtilesPath: _mapData.filePathForMap(name), gzip: false);
      final provider = MbTilesVectorTileProvider(mbtiles: mbtiles);
      tileProviders[name] = provider;
    }

/*    styleString: _mapData.styleJsonPath,
    onMapCreated: _mapCreated,
    onUserLocationUpdated: _userLocationUpdated,
    onStyleLoadedCallback: _styleLoaded,
    initialCameraPosition: const CameraPosition(target: LatLng(50.9365, 6.9398), zoom: 16.0),
    trackCameraPosition: false,
    zoomGesturesEnabled: true,
    rotateGesturesEnabled: true,
    dragEnabled: false,
    myLocationEnabled: true,
    compassEnabled: true,
    myLocationTrackingMode: MyLocationTrackingMode.none,
    myLocationRenderMode: MyLocationRenderMode.normal,
    doubleClickZoomEnabled: false,
    scrollGesturesEnabled: !_trackUserLocation,
    minMaxZoomPreference: const MinMaxZoomPreference(10,20),
*/
    Widget map = (_theme == null) ?  CircularProgressIndicator() :
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: LatLng(50.9365, 6.9398),
          initialZoom: 16.0,
        ),
        children: [
          VectorTileLayer(
            theme: _theme!,
            tileProviders: TileProviders(tileProviders),
          ),
        ],
      );


    return Scaffold(
        appBar: AppBar(
          title: const Text(Constants.recording),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
              Expanded(
                child: RepaintBoundary (
                  key: _mapContainer,
                  child: map,
                ),
              ),
              // disable the file cache when you change the PMTiles source
              // fileCacheTtl: Duration.zero,
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  child: Text(
                      Constants.mapAttribution,
                      style: Theme.of(context).textTheme.bodySmall),
                  onDoubleTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'))
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom:20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextButton(
                          onPressed: () { _finishRide(context); },
                          child: const Column(
                            children: [
                              Icon(Icons.stop_circle),
                              Text(Constants.endRecording),
                            ]
                          )
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
  }

}
