import 'package:backdrop/backdrop.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_tools/data/options.dart';
import 'package:hive_tools/home.dart';
import 'package:hive_tools/layout/adaptive.dart';
import 'package:hive_tools/routes.dart';
import 'package:hive_tools/settings/settings.dart';
import 'package:hive_tools/themes/theme_data.dart';

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:hive_tools/tools/splash.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialRoute,
  });

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return ModelBinding(
        initialModel: HiveOptions(
          themeMode: ThemeMode.system,
          timeDilation: timeDilation,
          platform: defaultTargetPlatform,
        ),
        child: Builder(builder: (context) {
          final options = HiveOptions.of(context);
          final hasHinge = MediaQuery.of(context).hinge?.bounds != null;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Providing a restorationScopeId allows the Navigator built by the
            // MaterialApp to restore the navigation stack when a user leaves and
            // returns to the app after it has been killed while running in the
            // background.
            restorationScopeId: 'app',

            // Provide the generated AppLocalizations to the MaterialApp. This
            // allows descendant Widgets to display the correct translations
            // depending on the user's locale.
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh'),
            ],

            // Use AppLocalizations to configure the correct application title
            // depending on the user's locale.
            //
            // The appTitle is defined in .arb files found in the localization
            // directory.
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,

            // Define a light and dark color theme. Then, read the user's
            // preferred ThemeMode (light, dark, or system default) from the
            // SettingsController to display the correct theme.
            theme: HiveThemeData.lightThemeData.copyWith(
              platform: options.platform,
            ),
            darkTheme: HiveThemeData.darkThemeData.copyWith(
              platform: options.platform,
            ),
            themeMode: options.themeMode,

            initialRoute: initialRoute,
            onGenerateRoute: (settings) =>
                RouteConfiguration.onGenerateRoute(settings, hasHinge),
          );
        }));
  }
}

class RootPage extends StatelessWidget {
  const RootPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SplashPage(
      child: Builder(builder: (context) {
        final isDesktop = isDisplayDesktop(context);
        final colorScheme = Theme.of(context).colorScheme;
        if (isDesktop) {
          return const Scaffold();
        } else {
          return BackdropScaffold(
            appBar: BackdropAppBar(
                title: const Text("工具箱"),
                leading: BackdropToggleButton(
                    icon: AnimatedIcons.menu_close,
                    color: colorScheme.onPrimaryContainer)),
            backLayer: const HomePage(),
            frontLayer: const SettingsPage(),
            headerHeight: 0,
          );
        }
      }),
    );
  }
}
