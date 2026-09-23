import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({
    super.key,
    required this.initialization,
    required this.child,
  });

  final Future<void> initialization;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return child;
        }
        return MaterialApp(
          title: 'Music Pocket',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/icons/launch_mark.png',
                    width: 120,
                    height: 120,
                    semanticLabel: 'Music Pocket',
                  ),
                ),
                if (snapshot.hasError)
                  const SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          '音频服务启动失败，请关闭应用后重试。',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
