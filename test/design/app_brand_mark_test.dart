import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_brand_mark.dart';

void main() {
  testWidgets('paints at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppBrandMark(size: 72))),
      ),
    );
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final size = tester.getSize(find.byType(AppBrandMark));
    expect(size, const Size(72, 72));
  });
}
