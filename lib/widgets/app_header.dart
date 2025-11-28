import 'package:flutter/material.dart';
import 'package:kstudio/gen/fonts.gen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kstudio/gen/assets.gen.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: isMobile ? 40 : 60,
                      width: isMobile ? 40 : 60,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Assets.images.logo.image(fit: BoxFit.contain),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KStudio',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: isMobile ? 24 : 36,
                                  fontFamily: FontFamily.pixels,
                                ),
                          ),
                          Text(
                            'DIY, IoT, 3D designs with ❤️+🤑',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMobile)
                    OutlinedButton.icon(
                      onPressed: () => _sendEmail(),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Contact me'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (isMobile)
                    IconButton(
                      onPressed: () => _sendEmail(),
                      icon: const Icon(Icons.email_outlined),
                      tooltip: 'Contact me',
                    ),
                  const SizedBox(width: 16),
                  // Theme Toggle
                  // BlocBuilder<ThemeCubit, ThemeState>(
                  //   builder: (context, state) {
                  //     return IconButton(
                  //       onPressed: () {
                  //         context.read<ThemeCubit>().toggleTheme();
                  //       },
                  //       icon: Icon(
                  //         state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  //       ),
                  //       tooltip: state.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  //     );
                  //   },
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'thuongpt.kstudio@gmail.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
