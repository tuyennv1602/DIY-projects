import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  bool get isMobile {
    final width = MediaQuery.of(this).size.width;
    return width < 600;
  }
}
