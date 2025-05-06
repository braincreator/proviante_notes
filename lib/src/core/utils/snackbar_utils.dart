import 'package:flutter/material.dart';

/// Global key to access the ScaffoldMessengerState.
///
/// This allows showing SnackBars from anywhere in the app without needing direct
/// access to the BuildContext of a Scaffold ancestor.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Optional: Helper function can be added later here.