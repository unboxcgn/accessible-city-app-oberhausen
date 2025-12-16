import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import '../logger.dart';
import '../model/map_data.dart';
import '../model/location.dart';

class MapSnapshotService {
  //our shared instance
  static final MapSnapshotService _service = MapSnapshotService._internal();

  //shared instance accessor
  factory MapSnapshotService() {
    return _service;
  }

  //internal constructor
  MapSnapshotService._internal() {
    _loadTheme();
  }

  //actual instance members
  final MapData _mapData = MapData();
  Completer<vtr.Theme> _theme = new Completer();

  //load theme data
  Future<void> _loadTheme() async {
    logInfo("style path is ${_mapData.styleJsonPath}");
    final file = File(_mapData.styleJsonPath);
    final str = await file.readAsString();
    final map = json.decode(str);
    _theme.complete(vtr.ThemeReader().read(map));
  }

  Future<Uint8List> makeSnapshot(
      List<Location> path, int width, int height, int padding) async {

    vtr.Theme theme = await _theme.future;

    //assemble tile providers for all loaded maps
    Map<String, VectorTileProvider> tileProviders = {};
    for (final name in _mapData.loadedMaps) {
      final mbtiles =
          MbTiles(mbtilesPath: _mapData.filePathForMap(name), gzip: false);
      final provider = MbTilesVectorTileProvider(mbtiles: mbtiles);
      tileProviders[name] = provider;
    }

    // Calculate logicalSize and imageSize
    final logicalSize = Size(width.toDouble(), height.toDouble());
    final imageSize = logicalSize;

    // generate path layer
    List<LatLng> latLngPath = [];
    for (Location loc in path) {
      latLngPath.add(LatLng(loc.latitude, loc.longitude));
    }
    final userRoute = PolylineLayer(
      polylines: [
        Polyline(
          points: latLngPath,
          color: Colors.red,
          strokeWidth: 5.0,
        ),
      ],
    );

    // Check if path is ok. Need a path with some extent
    bool boundsOk = true;
    if (latLngPath.length < 2) boundsOk = false;
    if (boundsOk) {
      LatLngBounds bounds = LatLngBounds.fromPoints(latLngPath);
      if (bounds.west == bounds.east) boundsOk = false;
      if (bounds.north == bounds.south) boundsOk = false;
    }
    if (!boundsOk) {
      final ByteData bytes = await rootBundle.load('assets/images/no_preview.png');
      return bytes.buffer.asUint8List();
    }

    // Set up map widget
    MapController controller = new MapController();
    MediaQueryData mediaQueryData = MediaQueryData(size: logicalSize, devicePixelRatio: 1.0);
    mediaQueryData.removePadding(
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
        removeTop: true);
    mediaQueryData.removeViewInsets(
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
        removeTop: true);
    mediaQueryData.removeViewPadding(
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
        removeTop: true);
    Widget map = MediaQuery(
      data: mediaQueryData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // Removes the debug banner in the corner
        home: Expanded(
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(coordinates: latLngPath,padding: EdgeInsets.all(padding.toDouble())),
            ),
            children: [
              VectorTileLayer(
                theme: theme,
                tileProviders: TileProviders(tileProviders),
              ),
              userRoute
            ],
          ),
        ),
      ),
    );

    // Generate offscreen rendering context, take image
    final repaintBoundary = RenderRepaintBoundary();
    // Create the render tree for capturing the widget as an image
    final renderView = RenderView(
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints(
            minWidth: logicalSize.width,
            maxWidth: logicalSize.width,
            minHeight: logicalSize.height,
            maxHeight: logicalSize.height),
        physicalConstraints: BoxConstraints(
            minWidth: imageSize.width,
            maxWidth: imageSize.width,
            minHeight: imageSize.height,
            maxHeight: imageSize.height),
        devicePixelRatio: 1.0,
      ),
      view: PlatformDispatcher.instance.views.first,
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();
    // Attach the widget's render object to the render tree
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: map,
        )).attachToRenderTree(buildOwner);
    buildOwner.buildScope(rootElement);
    // Delay if specified
    final redraw = () {
      // Build and finalize the render tree
      buildOwner
        ..buildScope(rootElement)
        ..finalizeTree();
      // Flush layout, compositing, and painting operations
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    };
    redraw();
    int numRedraws = 5;
    Duration wait = Duration(milliseconds: 100);
    for (int i = 0; i < numRedraws; i++) {
      await Future.delayed(wait);
      redraw();
    }

    // Capture the image and convert it to byte data
    final image = await repaintBoundary.toImage(
        pixelRatio: imageSize.width / logicalSize.width);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    // Return the image data as Uint8List
    if (byteData != null) return byteData!.buffer.asUint8List();
    return Uint8List(0);
  }
}
