/// Entry point for the Insurance Policy Manager application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  Logger.root.level = Level.OFF;
  runApp(const ProviderScope(child: InsurApp()));
}
