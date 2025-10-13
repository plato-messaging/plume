import 'package:flutter/widgets.dart';
import 'plume_localizations.g.dart';
import 'plume_localizations_en.g.dart';

extension BuildContextLocalizationsExtension on BuildContext {
  PlumeLocalizations get l =>
      PlumeLocalizations.of(this) ?? PlumeLocalizationsEn();
}
