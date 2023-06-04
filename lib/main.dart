import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_tools/app.dart';

void main() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  if (defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.windows) {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const MyApp());
}
