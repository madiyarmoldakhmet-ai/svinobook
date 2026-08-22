import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:svinobook/widgets/chat_bubble.dart';

void main() {
  testWidgets('renders a received text message and sender', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatBubble(
        text: 'Hello',
        senderName: 'Alice',
        timestamp: DateTime(2026, 8, 22, 10, 30),
        isMe: false,
      ),
    ));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('renders a sent code block without sender label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatBubble(
        text: '```dart\nfinal answer = 42;\n```',
        senderName: 'Alice',
        timestamp: DateTime(2026, 8, 22, 22, 5),
        isMe: true,
      ),
    ));

    expect(find.text('dart\nfinal answer = 42;'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('renders an image attachment loading state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChatBubble(
        text: '',
        senderName: 'Alice',
        timestamp: DateTime(2026, 8, 22),
        isMe: true,
        type: 'image',
        imageUrl: 'https://example.test/photo.jpg',
      ),
    ));

    await tester.pump();
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}