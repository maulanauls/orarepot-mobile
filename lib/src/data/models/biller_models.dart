class CatalogBrand {
  const CatalogBrand({
    required this.name,
    this.logoUrl,
    this.types = const [],
  });

  final String name;
  final String? logoUrl;
  final List<String> types;

  factory CatalogBrand.fromJson(Map<String, dynamic> json) {
    return CatalogBrand(
      name: (json['name'] as String?)?.trim() ?? '',
      logoUrl: json['logo_url'] as String?,
      types: (json['types'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.key,
    required this.label,
    required this.kind,
    this.brands = const [],
  });

  final String id;
  final String key;
  final String label;
  final String kind;
  final List<CatalogBrand> brands;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    final brandsJson = json['brands'] as List? ?? const [];
    return CatalogCategory(
      id: '${json['id'] ?? ''}',
      key: '${json['key'] ?? ''}',
      label: '${json['label'] ?? ''}',
      kind: '${json['kind'] ?? ''}'.toLowerCase(),
      brands: brandsJson
          .whereType<Map>()
          .map((e) => CatalogBrand.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.name.isNotEmpty)
          .toList(),
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.lookupIdf,
    required this.name,
    required this.price,
    this.code,
    this.popular = false,
  });

  final String lookupIdf;
  final String name;
  final String? code;
  final int price;
  final bool popular;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price'];
    final price = priceRaw is num ? priceRaw.round() : int.tryParse('$priceRaw') ?? 0;
    return CatalogProduct(
      lookupIdf: '${json['lookup_idf'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: json['code'] as String?,
      price: price,
      popular: json['popular'] == true,
    );
  }
}

enum OrderStage { unpaid, waiting, processing, success, failed, expired }

OrderStage parseOrderStage(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'waiting' => OrderStage.waiting,
    'processing' => OrderStage.processing,
    'success' => OrderStage.success,
    'failed' => OrderStage.failed,
    'expired' => OrderStage.expired,
    _ => OrderStage.unpaid,
  };
}

String orderStageLabel(OrderStage stage) {
  return switch (stage) {
    OrderStage.unpaid => 'Belum dibayar',
    OrderStage.waiting => 'Menunggu pembayaran',
    OrderStage.processing => 'Diproses',
    OrderStage.success => 'Berhasil',
    OrderStage.failed => 'Gagal',
    OrderStage.expired => 'Kedaluwarsa',
  };
}

class PayOption {
  const PayOption({
    required this.method,
    required this.title,
    required this.label,
    required this.koin,
    required this.qris,
    required this.available,
  });

  final String method;
  final String title;
  final String label;
  final int koin;
  final int qris;
  final bool available;

  factory PayOption.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
    return PayOption(
      method: '${json['method'] ?? ''}',
      title: '${json['title'] ?? ''}',
      label: '${json['label'] ?? ''}',
      koin: asInt(json['koin']),
      qris: asInt(json['qris']),
      available: json['available'] == true,
    );
  }
}

class BillerOrder {
  const BillerOrder({
    required this.billingCode,
    required this.stage,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.walletBalance,
    this.productName,
    this.brand,
    this.moduleName,
    this.lookupIdf,
    this.target,
    this.paymentMethod,
    this.koinUsed = 0,
    this.qrisAmount,
    this.qrUrl,
    this.qrString,
    this.expiresAt,
    this.sn,
    this.message,
    this.paymentOptions = const [],
  });

  final String billingCode;
  final OrderStage stage;
  final String status;
  final String? productName;
  final String? brand;
  final String? moduleName;
  final String? lookupIdf;
  final String? target;
  final int total;
  final String? paymentMethod;
  final int koinUsed;
  final int? qrisAmount;
  final String? qrUrl;
  final String? qrString;
  final String? expiresAt;
  final String createdAt;
  final String? sn;
  final String? message;
  final int walletBalance;
  final List<PayOption> paymentOptions;

  factory BillerOrder.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
    final options = (json['payment_options'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => PayOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return BillerOrder(
      billingCode: '${json['billing_code'] ?? ''}',
      stage: parseOrderStage(json['stage'] as String?),
      status: '${json['status'] ?? ''}',
      productName: json['product_name'] as String?,
      brand: json['brand'] as String?,
      moduleName: json['module_name'] as String?,
      lookupIdf: json['lookup_idf'] as String?,
      target: json['target'] as String?,
      total: asInt(json['total']),
      paymentMethod: json['payment_method'] as String?,
      koinUsed: asInt(json['koin_used']),
      qrisAmount: json['qris_amount'] == null ? null : asInt(json['qris_amount']),
      qrUrl: json['qr_url'] as String?,
      qrString: json['qr_string'] as String?,
      expiresAt: json['expires_at'] as String?,
      createdAt: '${json['created_at'] ?? ''}',
      sn: json['sn'] as String?,
      message: json['message'] as String?,
      walletBalance: asInt(json['wallet_balance']),
      paymentOptions: options,
    );
  }
}

class OrderListPage {
  const OrderListPage({
    required this.orders,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  final List<BillerOrder> orders;
  final int offset;
  final int limit;
  final bool hasMore;

  factory OrderListPage.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as List? ?? const [])
        .map((e) {
          if (e is Map<String, dynamic>) return BillerOrder.fromJson(e);
          if (e is Map) return BillerOrder.fromJson(Map<String, dynamic>.from(e));
          return null;
        })
        .whereType<BillerOrder>()
        .toList();
    return OrderListPage(
      orders: orders,
      offset: json['offset'] is num ? (json['offset'] as num).toInt() : 0,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : orders.length,
      hasMore: json['has_more'] == true,
    );
  }
}

class BillerUser {
  const BillerUser({
    required this.usersIdf,
    this.usersName,
    this.usersEmail,
    this.userPhonenumber,
  });

  final String usersIdf;
  final String? usersName;
  final String? usersEmail;
  final String? userPhonenumber;

  factory BillerUser.fromJson(Map<String, dynamic> json) {
    return BillerUser(
      usersIdf: _stringField(json['users_idf']) ?? '',
      usersName: _stringField(json['users_fullname']),
      usersEmail: _stringField(json['users_email']),
      userPhonenumber: _stringField(json['user_phonenumber']),
    );
  }

  static String? _stringField(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() => {
        'users_idf': usersIdf,
        'users_fullname': usersName,
        'users_email': usersEmail,
        'user_phonenumber': userPhonenumber,
      };
}

class StoreAuth {
  const StoreAuth({required this.token, required this.user});

  final String token;
  final BillerUser user;

  factory StoreAuth.fromJson(Map<String, dynamic> json) {
    return StoreAuth(
      token: '${json['token'] ?? ''}',
      user: BillerUser.fromJson(Map<String, dynamic>.from(json['user'] as Map? ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
      };
}

/// WhatsApp OTP challenge from `POST /biller/auth/enter` when `otp_required`.
class OtpChallenge {
  const OtpChallenge({
    required this.challenge,
    this.expiresIn = 300,
    this.resendIn = 60,
    this.pending,
    this.phone,
  });

  final String challenge;
  final int expiresIn;
  final int resendIn;
  final String? pending;
  final String? phone;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is num ? v.round() : int.tryParse('$v') ?? fallback;
    final pending = '${json['pending'] ?? ''}'.trim();
    final phone = '${json['phone'] ?? ''}'.trim();
    return OtpChallenge(
      challenge: '${json['challenge'] ?? ''}'.trim(),
      expiresIn: asInt(json['expires_in'], 300),
      resendIn: asInt(json['resend_in'], 60),
      pending: pending.isEmpty ? null : pending,
      phone: phone.isEmpty ? null : phone,
    );
  }
}

class OtpRequiredException implements Exception {
  OtpRequiredException(this.challenge);
  final OtpChallenge challenge;

  @override
  String toString() => 'OTP verification required';
}

/// Google account has no WhatsApp number — collect phone then OTP.
class GooglePhoneRequired {
  const GooglePhoneRequired({
    required this.pending,
    this.email,
    this.expiresIn = 900,
  });

  final String pending;
  final String? email;
  final int expiresIn;

  factory GooglePhoneRequired.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is num ? v.round() : int.tryParse('$v') ?? fallback;
    return GooglePhoneRequired(
      pending: '${json['pending'] ?? ''}'.trim(),
      email: _stringField(json['email']),
      expiresIn: asInt(json['expires_in'], 900),
    );
  }
}

class GooglePhoneRequiredException implements Exception {
  GooglePhoneRequiredException(this.required);
  final GooglePhoneRequired required;

  @override
  String toString() => 'Google phone required';
}
