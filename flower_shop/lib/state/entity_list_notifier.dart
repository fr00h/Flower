import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../repositories/entity_repository.dart';

enum LoadStatus { idle, loading, success, error }

class EntityListNotifier<T> extends ChangeNotifier {
  final EntityRepository<T> _repository;

  EntityListNotifier(this._repository);

  ListQuery? _query;
  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;

  ListQuery? get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;

  Future<void> load() async {
    if (_query == null) return;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query!);
      _status = LoadStatus.success;
    } on ApiException catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ListQuery next) async {
    _query = next;
    await load();
  }

  Future<T?> findById(String id) => _repository.findById(id);

  Future<List<T>> findAll({String filter = ''}) =>
      _repository.findAll(filter: filter);

  Future<void> save(T item, {required bool isNew}) async {
    isNew ? await _repository.create(item) : await _repository.update(item);
    await load();
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
