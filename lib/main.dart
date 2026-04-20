import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/hive_boxes.dart';
import 'data/local/seed_data.dart';
import 'state/auth_provider.dart';
import 'state/donor_provider.dart';
import 'state/receiver_provider.dart';
import 'state/request_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await HiveBoxes.openAll();
  await SeedData.ensureSeeded();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DonorProvider()..init()),
        ChangeNotifierProvider(create: (_) => ReceiverProvider()..init()),
        ChangeNotifierProvider(create: (_) => RequestProvider()..init()),
      ],
      child: const BloodDonorApp(),
    ),
  );
}
