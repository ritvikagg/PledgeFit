import 'dart:math';

String generateId({String prefix = 'id'}) {
  // Stable enough for local MVP: prefix + timestamp + random suffix.
  final now = DateTime.now().microsecondsSinceEpoch.toString();
  final rand = Random.secure().nextInt(1 << 20).toString().padLeft(5, '0');
  return '${prefix}_${now}_$rand';
}

