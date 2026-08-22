import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svinobook/views/call_screen.dart';

void main() {
  testWidgets('renders incoming video call controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingCallScreen(
          callId: 'call-1',
          callerName: 'Alex',
          video: true,
          onAccepted: () {},
        ),
      ),
    );

    expect(find.text('Alex is calling'), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    expect(find.byIcon(Icons.call_end), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  testWidgets('renders audio call mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingCallScreen(
          callId: 'call-2',
          callerName: 'Sam',
          video: false,
          onAccepted: () {},
        ),
      ),
    );

    expect(find.text('Sam is calling'), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsNothing);
  });
}
