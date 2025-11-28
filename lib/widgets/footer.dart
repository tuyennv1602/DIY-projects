import 'package:flutter/material.dart';
import 'package:kstudio/gen/assets.gen.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('© 2025 KStudio', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Assets.images.kstudioPixel.image(height: 16),
        ],
      ),
    );
  }
}
