import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/features/home/beranda/category_section.dart';
import 'package:orarepot/src/theme/app_theme.dart';

void main() {
  testWidgets('category skeleton stays visible when the catalog request fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CategorySection(
              chips: [],
              loading: false,
              error: 'Kategori belum bisa dimuat.',
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('category-skeleton')), findsOneWidget);
    expect(find.text('Kategori belum bisa dimuat.'), findsOneWidget);
    expect(find.text('Semua produk'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CategorySection(
              chips: [],
              loading: false,
              error: 'Kategori belum bisa dimuat.',
              onTap: _noop,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('category-skeleton')), findsOneWidget);
  });
}

void _noop(HomeCategoryChip _) {}
