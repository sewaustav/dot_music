import 'package:flutter/material.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Короткий доступ к локализации из любого виджета.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
