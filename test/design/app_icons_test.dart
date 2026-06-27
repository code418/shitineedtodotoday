// test/design/app_icons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';

void main() {
  test('curated glyphs map to Material Symbols Rounded', () {
    expect(AppIcons.checklist, Symbols.checklist_rounded);
    expect(AppIcons.add, Symbols.add_rounded);
    expect(AppIcons.eventRepeat, Symbols.event_repeat_rounded);
    expect(AppIcons.cloudOff, Symbols.cloud_off_rounded);
  });
}
