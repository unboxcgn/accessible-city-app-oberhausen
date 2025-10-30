enum VehicleType {
  unknown(label: "Keine Angabe", value: 0),
  manual(label: "Handrollstuhl", value: 50),
  electric(label: "Elektrorollstuhl", value: 51),
  electricAttached(label: "Rollstuhl mit Zuggerät", value: 52),
  sport(label: "Sportrollstuhl", value: 53),
  manualAssited(label: "Rollstuhl geschoben", value: 54),
  other(label: "Anderes", value: 9999);

  const VehicleType({
    required this.label,
    required this.value
  });

  final String label;
  final int value;
}

enum RideType {
  unknown(label:"Keine Angabe", value:0),
  commute(label:"Arbeitsweg", value:1),
  common(label:"Regelmäßiger Weg", value:2),
  recreational(label:"Freizeit", value:3),
  sport(label:"Sport / Training", value:4),
  other(label:"Anderes", value:9999);

  const RideType({
    required this.label,
    required this.value
  });

  final String label;
  final int value;
}

enum MountType {
  unknown(label: "Keine Angabe", value: 0),
  jacket(label: "Jackentasche", value: 1),
  pants(label: "Hosentasche", value: 2),
  vehicle(label: "Am Rollstuhl", value: 3),
  assistant(label: "Betreuungsperson", value: 4),
  other(label: "Anderes", value: 9999);

  const MountType({
    required this.label,
    required this.value
  });

  final String label;
  final int value;
}

enum AnnotationTag {
  obstruction(label: "Weg versperrt", value: "#obstruction"),
  narrow(label: "Engstelle", value: "#narrow"),
  damage(label: "Straßenschäden", value: "#damage"),
  dirt(label: "Schnee/Laub/Scherben", value: "#dirt"),
  noramp(label: "Kante / keine Rampe", value: "#noramp"),
  wait(label: "Wartezeit", value: "#wait"),
  elevator(label: "Aufzug defekt", value: "#elevator"),
  other(label: "Anderes", value: "#other");

  const AnnotationTag({
    required this.label,
    required this.value
  });

  final String label;
  final String value;
}

VehicleType vehicleTypeByValue(int value) {
  for (VehicleType t in VehicleType.values) {
    if (t.value == value) {
      return t;
    }
  }
  return VehicleType.unknown;
}

RideType rideTypeByValue(int value) {
  for (RideType t in RideType.values) {
    if (t.value == value) {
      return t;
    }
  }
  return RideType.unknown;
}

MountType mountTypeByValue(int value) {
  for (MountType t in MountType.values) {
    if (t.value == value) {
      return t;
    }
  }
  return MountType.unknown;
}

AnnotationTag annotationTagByValue(String value) {
  for (AnnotationTag t in AnnotationTag.values) {
    if (t.value == value) {
      return t;
    }
  }
  return AnnotationTag.other;
}


