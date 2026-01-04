// lib/core/utils/json_cast.dart

// Utilities for safely converting dynamic/decoded JSON-like structures
// into strongly typed Dart Maps.
//
// This helps avoid runtime errors like:
// `LinkedMap<dynamic, dynamic> is not a subtype of Map<String, dynamic>`.

Map<String, dynamic> asStringKeyedMap(dynamic value) {
  if (value == null) return <String, dynamic>{};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _deepConvert(val)),
    );
  }
  throw ArgumentError('Expected a Map but got ${value.runtimeType}');
}

dynamic _deepConvert(dynamic value) {
  if (value is Map) {
    return asStringKeyedMap(value);
  }
  if (value is List) {
    return value.map(_deepConvert).toList();
  }
  return value;
}
