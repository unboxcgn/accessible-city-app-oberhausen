class Constants {
  static const String unnamedRide = "Weg";
  static const String morningRide = "Weg am Morgen";
  static const String lateMorningRide = "Weg am Vormittag";
  static const String noonRide = "Weg am Mittag";
  static const String afternoonRide = "Weg am Nachmittag";
  static const String eveningRide = "Weg am Abend";
  static const String nightRide = "Weg in der Nacht";
  static const String longRide = "Langer Weg";
  static const String startRecording = "Weg aufzeichnen";
  static const String endRecording = "Weg beenden";
  static const String recording = "Wegeaufzeichnung";
  static const String annotation = "Annotation";
  static const String trackLocation = "Zentrieren";
  static const String mapAttribution = "OpenStreetMap 2024, 2025";

  static const double minMotionMperS = 0.8;
  static const int locationDistanceFilterM = 2;

  static const double minSyncDistanceM = 200.0;
  static const double minSyncDurationS = 30.0;

  static const double syncCutoffM = 70.0;
  static const double syncRandomizeS = 1200.0;
  static const int minSyncIntervalMS = 200; //minimum interval (200ms) for network activities
  static const int maxSyncIntervalMS = 600000; //maximum interval (10 min) after exponential backup
}
