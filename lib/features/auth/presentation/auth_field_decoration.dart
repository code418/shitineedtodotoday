import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// The auth forms' text-field look: a filled, borderless, rounded "sunken"
/// input with an optional [errorText]. Shared by the account-upgrade and
/// sign-in screens so they stay identical.
InputDecoration authFieldDecoration(
  BuildContext context,
  String hint,
  String? errorText,
) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: context.palette.surfaceSunken,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    errorText: errorText,
  );
}
