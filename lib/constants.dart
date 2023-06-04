// Height of the 'Gallery' header
import 'package:flutter/foundation.dart';
import 'package:transparent_image/transparent_image.dart' as transparent_image;

const double galleryHeaderHeight = 64;

// The desktop top padding for a page's first header (e.g. Gallery, Settings)
const double firstHeaderDesktopTopPadding = 5.0;

// The font size delta for headline4 font.
const double desktopDisplay1FontDelta = 16;

// The width of the settingsDesktop.
const double desktopSettingsWidth = 520;

// Duration for home page elements to fade in.
const Duration entranceAnimationDuration = Duration(milliseconds: 200);

// The splash page animation duration.
const Duration splashPageAnimationDuration = Duration(milliseconds: 300);

// Half the splash page animation duration.
const Duration halfSplashPageAnimationDuration = Duration(milliseconds: 150);

// A transparent image used to avoid loading images when they are not needed.
final Uint8List kTransparentImage = transparent_image.kTransparentImage;
