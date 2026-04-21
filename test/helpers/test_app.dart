import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:blood_donor_receiver/data/local/hive_boxes.dart';
import 'package:blood_donor_receiver/state/auth_provider.dart';
import 'package:blood_donor_receiver/state/donor_provider.dart';
import 'package:blood_donor_receiver/state/receiver_provider.dart';
import 'package:blood_donor_receiver/state/request_provider.dart';

/// Sets up an isolated Hive directory for a single test and tears it down
/// after. Use from setUp / tearDown in every test that touches Hive.
class HiveTestHarness {
  late Directory tempDir;

  Future<void> setUp() async {
    tempDir = await Directory.systemTemp.createTemp('hive_blood_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.openAll();
  }

  Future<void> tearDown() async {
    await Hive.close();
    // Best-effort cleanup — Hive may still hold handles on Windows.
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Ignore transient cleanup failures.
    }
  }
}

/// Wraps [child] in a [MaterialApp] with all 4 app-level providers.
/// Caller must have initialised Hive first via [HiveTestHarness].
Widget wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider()..init(),
      ),
      ChangeNotifierProvider<DonorProvider>(
        create: (_) => DonorProvider()..init(),
      ),
      ChangeNotifierProvider<ReceiverProvider>(
        create: (_) => ReceiverProvider()..init(),
      ),
      ChangeNotifierProvider<RequestProvider>(
        create: (_) => RequestProvider()..init(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: child,
    ),
  );
}

/// Convenience: pump [child] inside providers + MaterialApp and settle.
Future<void> pumpWithProviders(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(wrapWithProviders(child));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}
