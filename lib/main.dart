import 'package:flutter/services.dart';

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
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 56, fontWeight: FontWeight.w700, height: 1.1),
            displayMedium: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 45, fontWeight: FontWeight.w700, height: 1.1),
            displaySmall: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 36, fontWeight: FontWeight.w700, height: 1.1),
            headlineLarge: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 32, fontWeight: FontWeight.w700, height: 1.1),
            headlineMedium: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
            headlineSmall: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 24, fontWeight: FontWeight.w700, height: 1.1),
            titleLarge: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 22, fontWeight: FontWeight.w700, height: 1.1),
            titleMedium: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 18, fontWeight: FontWeight.w700, height: 1.1),
            titleSmall: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 16, fontWeight: FontWeight.w700, height: 1.1),
            labelLarge: TextStyle(fontFamily: 'InclusiveSans', fontSize: 18, fontWeight: FontWeight.w400, height: 1.1),
            labelMedium: TextStyle(fontFamily: 'InclusiveSans', fontSize: 16, fontWeight: FontWeight.w400, height: 1.1),
            labelSmall: TextStyle(fontFamily: 'InclusiveSans', fontSize: 14, fontWeight: FontWeight.w400, height: 1.1),
            bodyLarge: TextStyle(fontFamily: 'InclusiveSans', fontSize: 18, fontWeight: FontWeight.w400, height: 1.2),
            bodyMedium: TextStyle(fontFamily: 'InclusiveSans', fontSize: 16, fontWeight: FontWeight.w400, height: 1.2),
            bodySmall: TextStyle(fontFamily: 'InclusiveSans', fontSize: 14, fontWeight: FontWeight.w400, height: 1.2),
          ),
          colorScheme:
            const ColorScheme(brightness: Brightness.light,
                primary: Color(0xffB4AAEF),
                primaryContainer: Color(0xffE6DEFF),
                onPrimary: Color(0xff000000),
                secondary: Color(0xff46DA67),
                onSecondary: Color(0xff000000),
                error: Color(0xffBA1A1A),
                onError: Color(0xffffffff),
                surface: Color(0xffFEF7FF),
                onSurface: Color(0xff000000)
            ),
          chipTheme: const ChipThemeData(
            backgroundColor: Colors.white,
            selectedColor: Color(0xff46DA67),
            padding: EdgeInsets.all(0),
            side: BorderSide(
              color: Colors.black, // Border color
              width: 2, // Border width
            )
          ),
          cardTheme: const CardThemeData(
            color: Color.fromARGB(255,179,157,219),
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              side:BorderSide(color: Colors.black, width: 2),
              borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
            )
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.transparent,
              backgroundColor: const Color(0xff46DA67),
              side: const BorderSide(
                color: Colors.black, // Border color
                width: 3, // Border width
              ),
            ),
          ),
          textButtonTheme: const TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Colors.black)
            ),
          ),
          appBarTheme: const AppBarThemeData(
            centerTitle: true,
          ),
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Colors.transparent,
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

