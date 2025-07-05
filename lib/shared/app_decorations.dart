import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration uberInputDecoration(BuildContext context,
    {required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle:
        GoogleFonts.roboto(color: Theme.of(context).colorScheme.secondary),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).dividerColor),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Theme.of(context).primaryColor),
    ),
    errorStyle: GoogleFonts.roboto(color: Theme.of(context).colorScheme.error),
  );
}