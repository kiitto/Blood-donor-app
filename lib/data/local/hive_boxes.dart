import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  HiveBoxes._();

  static const users = 'users';
  static const donors = 'donors';
  static const receivers = 'receivers';
  static const requests = 'requests';
  static const session = 'session';
  static const meta = 'meta';

  static Future<void> openAll() async {
    await Future.wait([
      Hive.openBox(users),
      Hive.openBox(donors),
      Hive.openBox(receivers),
      Hive.openBox(requests),
      Hive.openBox(session),
      Hive.openBox(meta),
    ]);
  }

  static Box usersBox() => Hive.box(users);
  static Box donorsBox() => Hive.box(donors);
  static Box receiversBox() => Hive.box(receivers);
  static Box requestsBox() => Hive.box(requests);
  static Box sessionBox() => Hive.box(session);
  static Box metaBox() => Hive.box(meta);

  /// Debug helper for wiping state during demo reset.
  static Future<void> clearAll() async {
    await Future.wait([
      usersBox().clear(),
      donorsBox().clear(),
      receiversBox().clear(),
      requestsBox().clear(),
      sessionBox().clear(),
      metaBox().clear(),
    ]);
  }
}
