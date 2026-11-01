import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/api_exceptions.dart';
import 'models/app_user.dart';
import 'models/bouquet.dart';
import 'models/bouquet_item.dart';
import 'models/category.dart';
import 'models/customer_card.dart';
import 'models/flower.dart';
import 'models/order.dart';
import 'models/supplier.dart';
import 'models/supply.dart';
import 'repositories/auth_api.dart';
import 'repositories/entity_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/pb_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/cart_notifier.dart';
import 'state/entity_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  late final AuthNotifier auth;
  final dio = buildDio(tokenProvider: () => auth.token);
  final authApi = AuthApi(dio);
  auth = AuthNotifier(prefs, authApi);
  await auth.restore();
  final router = buildRouter(auth);
  final orders = OrderRepository(dio);

  final repositories = <Provider>[
    Provider<EntityRepository<Category>>.value(
      value: PbRepository<Category>(
        dio,
        'categories',
        Category.fromJson,
        (c) => c.toJson(),
        (c) => c.id,
        searchFields: ['name', 'description'],
      ),
    ),
    Provider<EntityRepository<Flower>>.value(
      value: PbRepository<Flower>(
        dio,
        'flowers',
        Flower.fromJson,
        (f) => f.toJson(),
        (f) => f.id,
        searchFields: ['name', 'color'],
      ),
    ),
    Provider<EntityRepository<Bouquet>>.value(
      value: PbRepository<Bouquet>(
        dio,
        'bouquets',
        Bouquet.fromJson,
        (b) => b.toJson(),
        (b) => b.id,
        searchFields: ['name', 'description'],
        expand: 'category',
        conditions: (q) => [
          if (q.filter('category').isNotEmpty)
            'category=${pbText(q.filter('category'))}',
          if (int.tryParse(q.filter('priceFrom')) != null)
            'price>=${int.parse(q.filter('priceFrom'))}',
          if (int.tryParse(q.filter('priceTo')) != null)
            'price<=${int.parse(q.filter('priceTo'))}',
          if (q.filter('available') == 'true') 'available=true',
        ],
      ),
    ),
    Provider<EntityRepository<BouquetItem>>.value(
      value: PbRepository<BouquetItem>(
        dio,
        'bouquet_items',
        BouquetItem.fromJson,
        (i) => i.toJson(),
        (i) => i.id,
        expand: 'flower',
      ),
    ),
    Provider<EntityRepository<Supplier>>.value(
      value: PbRepository<Supplier>(
        dio,
        'suppliers',
        Supplier.fromJson,
        (s) => s.toJson(),
        (s) => s.id,
        searchFields: ['name', 'city'],
      ),
    ),
    Provider<EntityRepository<Supply>>.value(
      value: PbRepository<Supply>(
        dio,
        'supplies',
        Supply.fromJson,
        (s) => s.toJson(),
        (s) => s.id,
        searchFields: ['supplier.name', 'flower.name'],
        expand: 'supplier,flower',
        conditions: (q) => [
          if (q.filter('supplier').isNotEmpty)
            'supplier=${pbText(q.filter('supplier'))}',
          if (q.filter('flower').isNotEmpty)
            'flower=${pbText(q.filter('flower'))}',
        ],
      ),
    ),
    Provider<EntityRepository<CustomerCard>>.value(
      value: PbRepository<CustomerCard>(
        dio,
        'cards',
        CustomerCard.fromJson,
        (c) => c.toJson(),
        (c) => c.id,
        searchFields: ['number'],
      ),
    ),
    Provider<EntityRepository<AppUser>>.value(
      value: PbRepository<AppUser>(
        dio,
        'users',
        AppUser.fromJson,
        (u) => u.toJson(),
        (u) => u.id,
        searchFields: ['name', 'email'],
        conditions: (q) => [
          if (q.filter('role').isNotEmpty) 'role=${pbText(q.filter('role'))}',
        ],
      ),
    ),
    Provider<EntityRepository<Order>>.value(value: orders.orders),
  ];

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<OrderRepository>.value(value: orders),
        ...repositories,
        ChangeNotifierProvider(create: (context) => CartNotifier(orders)),
        _list<Category>(),
        _list<Flower>(),
        _list<Bouquet>(),
        _list<BouquetItem>(),
        _list<Supplier>(),
        _list<Supply>(),
        _list<AppUser>(),
        _list<Order>(),
      ],
      child: FlowerShopApp(router: router),
    ),
  );
}

ChangeNotifierProvider<EntityListNotifier<T>> _list<T>() =>
    ChangeNotifierProvider(
      create: (context) =>
          EntityListNotifier<T>(context.read<EntityRepository<T>>()),
    );

class FlowerShopApp extends StatelessWidget {
  const FlowerShopApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Цветочный магазин',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
