import 'package:flutter/material.dart';

import '../../app_config.dart';
import '../debug/alice_inspector.dart';
import '../theme/theme_controller.dart';
import 'api_client.dart';
import 'auth_repository.dart';
import 'auth_store.dart';
import 'catalog_repository.dart';
import 'orders_repository.dart';

class AppServices {
  AppServices._({
    required this.config,
    required this.authStore,
    required this.theme,
    required this.api,
    required this.catalog,
    required this.orders,
    required this.auth,
    this.alice,
  });

  factory AppServices.create(AppConfig config) {
    final store = AuthStore();
    final theme = ThemeController();
    final alice = AliceInspector.create(config);
    final api = ApiClient(
      config: config,
      authStore: store,
      aliceAdapter: alice?.httpAdapter,
    );
    return AppServices._(
      config: config,
      authStore: store,
      theme: theme,
      api: api,
      catalog: CatalogRepository(api),
      orders: OrdersRepository(api),
      auth: AuthRepository(api, store),
      alice: alice,
    );
  }

  final AppConfig config;
  final AuthStore authStore;
  final ThemeController theme;
  final ApiClient api;
  final CatalogRepository catalog;
  final OrdersRepository orders;
  final AuthRepository auth;
  final AliceInspector? alice;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.services;
  }

  static AppServices read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
