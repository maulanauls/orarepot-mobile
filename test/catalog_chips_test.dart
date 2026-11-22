import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/common_widgets/category_icon.dart';
import 'package:orarepot/src/data/models/biller_models.dart';
import 'package:orarepot/src/features/home/beranda/category_section.dart';

void main() {
  test('buildHomeChips uses catalog API labels and kinds as-is', () {
    final categories = [
      const CatalogCategory(
        id: '1',
        key: 'pulsa',
        label: 'PULSA',
        kind: 'pulsa',
        brands: [
          CatalogBrand(name: 'Telkomsel'),
          CatalogBrand(name: 'XL'),
          CatalogBrand(name: 'Indosat'),
        ],
      ),
      const CatalogCategory(
        id: '2',
        key: 'data',
        label: 'DATA',
        kind: 'data',
        brands: [],
      ),
      const CatalogCategory(
        id: '3',
        key: 'pln',
        label: 'PLN TOKEN',
        kind: 'pln',
        brands: [],
      ),
      const CatalogCategory(
        id: '4',
        key: 'game',
        label: 'GAME KEY',
        kind: 'game',
        brands: [CatalogBrand(name: 'Mobile Legends'), CatalogBrand(name: 'Free Fire')],
      ),
      const CatalogCategory(
        id: '5',
        key: 'emoney',
        label: 'E-MONEY',
        kind: 'emoney',
        brands: [CatalogBrand(name: 'GoPay')],
      ),
    ];

    final chips = buildHomeChips(categories);

    expect(chips.first.label, 'Semua produk');
    expect(chips.first.hint, '6+ ITEMS');
    expect(chips.first.icon, CategoryIconName.semua);

    // Empty DATA / PLN TOKEN (brands: []) are omitted from Kategori pilihan.
    expect(chips.map((c) => c.kind).toList(), [
      'semua',
      'pulsa',
      'game',
      'emoney',
    ]);

    expect(chips[1].label, 'PULSA');
    expect(chips[1].hint, '3 PROVIDER');
    expect(chips[2].label, 'GAME KEY');
    expect(chips[2].hint, '2 PROVIDER');
    expect(chips[3].label, 'E-MONEY');
    expect(chips[3].hint, '1 PROVIDER');
  });

  test('CatalogCategory.fromJson reads /biller/catalog payload rows', () {
    final row = CatalogCategory.fromJson({
      'id': 'mod-1',
      'key': 'pulsa',
      'label': 'Pulsa',
      'kind': 'PULSA',
      'brands': [
        {'name': 'Telkomsel', 'logo_url': null, 'types': ['reguler']},
        {'name': '', 'logo_url': null, 'types': []},
      ],
    });

    expect(row.id, 'mod-1');
    expect(row.kind, 'pulsa');
    expect(row.brands.length, 1);
    expect(row.brands.first.name, 'Telkomsel');
  });
}
