import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/common_widgets/category_icon.dart';
import 'package:orarepot/src/data/models/biller_models.dart';
import 'package:orarepot/src/features/home/beranda/category_section.dart';

void main() {
  test('buildHomeChips mirrors web inventory chips from catalog API shape', () {
    final categories = [
      const CatalogCategory(
        id: '1',
        key: 'pulsa',
        label: 'Pulsa',
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
        label: 'Data',
        kind: 'data',
        brands: [CatalogBrand(name: 'Telkomsel'), CatalogBrand(name: 'XL')],
      ),
      const CatalogCategory(
        id: '3',
        key: 'pln',
        label: 'PLN',
        kind: 'pln',
        brands: [CatalogBrand(name: 'PLN')],
      ),
      const CatalogCategory(
        id: '4',
        key: 'game',
        label: 'Game',
        kind: 'game',
        brands: [CatalogBrand(name: 'Mobile Legends'), CatalogBrand(name: 'Free Fire')],
      ),
      const CatalogCategory(
        id: '5',
        key: 'emoney',
        label: 'E-Money',
        kind: 'emoney',
        brands: [CatalogBrand(name: 'GoPay')],
      ),
      const CatalogCategory(
        id: '6',
        key: 'other',
        label: 'Empty Other',
        kind: 'other',
        brands: [],
      ),
    ];

    final chips = buildHomeChips(categories);

    expect(chips.first.label, 'Semua produk');
    expect(chips.first.hint, '9+ ITEMS');
    expect(chips.first.icon, CategoryIconName.semua);

    expect(chips.map((c) => c.kind).toList(), [
      'semua',
      'pulsa',
      'data',
      'pln',
      'game',
      'emoney',
    ]);

    expect(chips[1].label, 'Pulsa');
    expect(chips[1].hint, 'SEMUA OPERATOR');
    expect(chips[2].label, 'Data');
    expect(chips[2].hint, '2 PROVIDER');
    expect(chips[3].label, 'PLN & Tagihan');
    expect(chips[3].hint, 'LISTRIK RESMI');
    expect(chips[4].label, 'Game');
    expect(chips[4].hint, 'TOPUP & TOKEN');
    expect(chips[5].label, 'Digital');
    expect(chips[5].hint, '1 PROVIDER');
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
