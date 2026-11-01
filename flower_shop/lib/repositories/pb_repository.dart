import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

class PbRepository<T> implements EntityRepository<T> {
  final Dio dio;
  final String collection;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final String Function(T item) idOf;
  final List<String> searchFields;
  final String expand;
  final List<String> Function(ListQuery query)? conditions;

  PbRepository(
    this.dio,
    this.collection,
    this.fromJson,
    this.toJson,
    this.idOf, {
    this.searchFields = const ['name'],
    this.expand = '',
    this.conditions,
  });

  String get path => '/collections/$collection/records';

  PageResult<T> parsePage(dynamic body) {
    final data = body as Map<String, dynamic>;
    return PageResult(
      items: (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
      page: data['page'] as int? ?? 1,
      size: data['perPage'] as int? ?? 10,
      total: data['totalItems'] as int? ?? 0,
    );
  }

  String buildFilter(ListQuery q) {
    final search = q.search.trim();
    final variants = {
      search,
      search.toLowerCase(),
      if (search.isNotEmpty)
        search[0].toUpperCase() + search.substring(1).toLowerCase(),
    };
    return [
      if (search.isNotEmpty)
        '(${[for (final f in searchFields)
          for (final v in variants) '$f~${pbText(v)}'].join(' || ')})',
      ...?conditions?.call(q),
    ].join(' && ');
  }

  @override
  Future<PageResult<T>> find(ListQuery q) => guard(() async {
    final filter = buildFilter(q);
    final response = await dio.get(
      path,
      queryParameters: {
        'page': q.page,
        'perPage': q.size,
        'sort': q.pbSort,
        if (filter.isNotEmpty) 'filter': filter,
        if (expand.isNotEmpty) 'expand': expand,
      },
    );
    return parsePage(response.data);
  });

  @override
  Future<List<T>> findAll({String filter = ''}) => guard(() async {
    final response = await dio.get(
      path,
      queryParameters: {
        'perPage': 500,
        if (filter.isNotEmpty) 'filter': filter,
        if (expand.isNotEmpty) 'expand': expand,
      },
    );
    return parsePage(response.data).items;
  });

  @override
  Future<T?> findById(String id) async {
    try {
      return await guard(() async {
        final response = await dio.get(
          '$path/$id',
          queryParameters: {if (expand.isNotEmpty) 'expand': expand},
        );
        return fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<T> create(T item) => guard(() async {
    final response = await dio.post(path, data: toJson(item));
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<T> update(T item) => guard(() async {
    final response = await dio.patch('$path/${idOf(item)}', data: toJson(item));
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> delete(String id) => guard(() => dio.delete('$path/$id'));
}
