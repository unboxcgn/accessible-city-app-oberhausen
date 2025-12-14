import 'logger.dart';
import 'model/user.dart';
import 'model/map_data.dart';
import 'model/rides.dart';
import 'view/first_boot_screen.dart';
import 'view/main_screen.dart';
import 'view/info_screen.dart';
import 'view/settings_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLogger();
  runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => User()),
        ChangeNotifierProvider(create: (_) => Rides())
      ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {

  bool _initialized = false;
  String _subpage = "";

  void gotoPage(String page) {
    setState(() {
      _subpage = page;
    });
  }

  Future<void> initAppAsync() async {
    await Future.wait([
      User().initialize(),
      MapData().initialize(),
      Rides().initialize(),
    ]);
    setState(() {
      _initialized = true;
    });
  }

  @override initState () {
    super.initState();
    initAppAsync();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    List<MaterialPage> contents = [];
    if (!_initialized) {
      contents = [
        const MaterialPage(
          child: Scaffold(
            body: Center(
              child: CircularProgressIndicator()
            )
          )
        )
      ];
    } else if (Provider.of<User>(context).firstStart) {
      contents = [const MaterialPage(child : FirstBootScreen())];
    } else {
      contents = [
        MaterialPage(child : MainScreen(appState: this)),
        if (_subpage == "info") const MaterialPage(child : InfoScreen()),
        if (_subpage == "settings") const MaterialPage(child : SettingsScreen()),
      ];
    }

    return MaterialApp(
        title: 'Accessible City',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            surface: Colors.deepPurple.shade50,
          ),
          appBarTheme: AppBarThemeData(
            backgroundColor: Colors.deepPurple.shade200,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Colors.transparent,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.white,
            selectedColor: const Color.fromARGB(255,100,255,100),
            padding: EdgeInsets.all(0),
            side: const BorderSide(
              color: Colors.black, // Border color
              width: 2, // Border width
            )
          ),
          cardTheme: CardThemeData(
            color: Colors.deepPurple.shade200,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              side:BorderSide(color: Colors.black, width: 2),
              borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
            )
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color.fromARGB(255,100,255,100),
              side: const BorderSide(
                color: Colors.black, // Border color
                width: 3, // Border width
              ),
            ),
          ),
        ),
        home: Navigator(
            pages: contents,
            onDidRemovePage: _didRemovePage
        )
    );
  }

  void _didRemovePage(Page<dynamic> page) {
    gotoPage("");
  }

}

