import 'dart:async';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

/// Mints readable tokens like DNR-20260420-001 / RCV-... / REQ-...
/// Sequence counters live in the session box so they survive restarts.
///
/// All mints are serialized through a single lock chain so concurrent callers
/// (e.g. fast double-taps, seed loop) can't read-then-write the same counter
/// and produce duplicate IDs.
class IdGenerator {
  IdGenerator._();

  static const _sessionBox = 'session';
  static const _prefixDonor = 'DNR';
  static const _prefixReceiver = 'RCV';
  static const _prefixRequest = 'REQ';

  static Future<void> _lock = Future.value();

  static Future<String> donor() => _mint(_prefixDonor);
  static Future<String> receiver() => _mint(_prefixReceiver);
  static Future<String> request() => _mint(_prefixRequest);

  static Future<String> _mint(String prefix) {
    final completer = Completer<String>();
    _lock = _lock.then((_) async {
      try {
        final today = DateFormat('yyyyMMdd').format(DateTime.now());
        final key = 'seq_${prefix}_$today';
        final box = Hive.box(_sessionBox);
        final next = ((box.get(key) as int?) ?? 0) + 1;
        await box.put(key, next);
        final seq = next.toString().padLeft(3, '0');
        completer.complete('$prefix-$today-$seq');
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}
