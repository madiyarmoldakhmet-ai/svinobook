import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/utils/app_theme.dart';

void main() {
  test('darkTheme exposes the configured light color scheme', () {
    final theme = AppTheme.darkTheme;

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.neonCyan);
    expect(theme.scaffoldBackgroundColor, AppColors.bgDarkest);
    expect(theme.bottomNavigationBarTheme.type, BottomNavigationBarType.fixed);
  });

  testWidgets('GlassCard renders its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GlassCard(child: Text('Panel'))));

    expect(find.text('Panel'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GradientAvatar renders an initial and respects its radius', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GradientAvatar(name: 'alice', radius: 30)));

    expect(find.text('A'), findsOneWidget);
    final avatar = tester.widget<Container>(find.byType(Container).first);
    expect(avatar.constraints?.maxWidth, 60);
  });

  testWidgets('GradientAvatar renders question mark for an empty name', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GradientAvatar(name: '')));

    expect(find.text('?'), findsOneWidget);
  });
}
