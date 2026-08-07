import 'package:flutter/foundation.dart';

/// Global controller to hold the current search query.
/// Screens can listen to this to filter their content locally.
final ValueNotifier<String> searchQueryNotifier = ValueNotifier('');
