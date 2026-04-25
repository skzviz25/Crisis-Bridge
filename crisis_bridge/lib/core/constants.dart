class AppConstants {
  // Firestore collections
  static const String mapsCollection = 'floor_maps';
  static const String areasCollection = 'areas';
  static const String sosCollection = 'sos_reports';
  static const String respondersCollection = 'responders';
  static const String dangerCollection = 'danger_states';

  // Area types
  static const String typeRoom = 'room';
  static const String typeHall = 'hall';
  static const String typeStair = 'stair';
  static const String typeExit = 'exit';
  static const String typeDanger = 'danger';

  // QR payload key
  static const String qrMapKey = 'mapId';
  static const String qrPropertyKey = 'propertyId';
  static const String qrFloorKey = 'floor';
  static const String qrVersion = 'v';
}