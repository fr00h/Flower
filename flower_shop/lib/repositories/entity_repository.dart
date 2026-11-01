import '../models/list_query.dart';
import '../models/page_result.dart';

abstract interface class EntityRepository<T> {
  Future<PageResult<T>> find(ListQuery query);
  Future<List<T>> findAll({String filter = ''});
  Future<T?> findById(String id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);
}
