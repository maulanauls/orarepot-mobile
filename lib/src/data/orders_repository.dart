import 'api_client.dart';
import 'models/biller_models.dart';

/// Mirrors orappob `lib/orders.ts`.
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<BillerOrder> createOrder({
    required String lookupIdf,
    required String target,
  }) async {
    final body = await _api.postJson(
      '/biller/orders',
      body: {'lookup_idf': lookupIdf, 'target': target},
      auth: true,
    );
    return BillerOrder.fromJson(body);
  }

  Future<BillerOrder> getOrder(String code) async {
    final body = await _api.getJson('/biller/orders/${Uri.encodeComponent(code)}', auth: true);
    return BillerOrder.fromJson(body);
  }

  Future<BillerOrder> payOrder({
    required String code,
    required String method,
  }) async {
    final normalized = method.trim().toUpperCase();
    final body = await _api.postJson(
      '/biller/orders/${Uri.encodeComponent(code)}/pay',
      body: {'method': normalized},
      auth: true,
    );
    return BillerOrder.fromJson(body);
  }

  Future<OrderListPage> listOrders({int offset = 0, int limit = 10}) async {
    final body = await _api.getJson(
      '/biller/orders',
      query: {
        'offset': '${offset < 0 ? 0 : offset}',
        'limit': '${limit.clamp(1, 50)}',
      },
      auth: true,
    );
    return OrderListPage.fromJson(body);
  }

  Future<int> fetchWallet() async {
    final body = await _api.getJson('/biller/wallet', auth: true);
    final balance = body['balance'];
    if (balance is num) return balance.round();
    return int.tryParse('$balance') ?? 0;
  }
}
