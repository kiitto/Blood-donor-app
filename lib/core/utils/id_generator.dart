import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

/// Mints readable tokens like DNR-20260420-001 / RCV-... / REQ-...
/// Sequence counters live in the session box so they survive restarts.
class IdGenerator {
  IdGenerator._();

  static const _sessionBox = 'session';
  static const _prefixDonor = 'DNR';
  static const _prefixReceiver = 'RCV';
  static const _prefixRequest = 'REQ';

  static String donor() => _mint(_prefixDonor);
  static String receiver() => _mint(_prefixReceiver);
  static String request() => _mint(_prefixRequest);

  static String _mint(String prefix) {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final key = 'seq_${prefix}_$today';
    final box = Hive.box(_sessionBox);
    final next = ((box.get(key) as int?) ?? 0) + 1;
    box.put(key, next);
    final seq = next.toString().padLeft(3, '0');
    return '$prefix-$today-$seq';
  }
}
