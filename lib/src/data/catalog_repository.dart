import 'api_client.dart';
import 'models/biller_models.dart';

/// Mirrors orappob `lib/catalog.ts`.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<CatalogCategory>> fetchCatalog() async {
    final body = await _api.getJson('/biller/catalog');
    final rows = body['categories'] as List? ?? const [];
    return rows
        .whereType<Map>()
        .map((e) => CatalogCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CatalogProduct>> fetchProducts({
    required String moduleId,
    required String brand,
    String type = '',
  }) async {
    final query = <String, String>{
      'module': moduleId,
      'brand': brand,
      if (type.isNotEmpty) 'type': type,
    };
    final body = await _api.getJson('/biller/catalog/products', query: query);
    final rows = body['products'] as List? ?? const [];
    return rows
        .whereType<Map>()
        .map((e) => CatalogProduct.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.lookupIdf.isNotEmpty)
        .toList();
  }
}
