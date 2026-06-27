import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Curated Material Symbols (Rounded) used across the product. Centralised so
/// product code references intent (`AppIcons.add`) not the icon font directly.
abstract final class AppIcons {
  static const IconData checklist = Symbols.checklist_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData addCircle = Symbols.add_circle_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData sun = Symbols.wb_sunny_rounded;
  static const IconData eventRepeat = Symbols.event_repeat_rounded;
  static const IconData cloudOff = Symbols.cloud_off_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData mood = Symbols.sentiment_very_satisfied_rounded;
  static const IconData expandMore = Symbols.expand_more_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData favorite = Symbols.favorite_rounded;
  static const IconData error = Symbols.error_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData delete = Symbols.delete_rounded;
  static const IconData notifications = Symbols.notifications_rounded;
  static const IconData bedtime = Symbols.bedtime_rounded;

  // Category / themed-day glyphs.
  static const IconData countertops = Symbols.countertops_rounded;
  static const IconData laundry = Symbols.local_laundry_service_rounded;
  static const IconData skillet = Symbols.skillet_rounded;
  static const IconData bathtub = Symbols.bathtub_rounded;
  static const IconData weekend = Symbols.weekend_rounded;
  static const IconData cart = Symbols.shopping_cart_rounded;
}
