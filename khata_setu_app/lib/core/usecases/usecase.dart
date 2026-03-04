import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base use case with parameters
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case without parameters
abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

/// Use case parameter for no params
class NoParams {
  const NoParams();
}

/// Use case parameter for pagination
class PaginationParams {
  final int page;
  final int limit;
  final String? search;
  final Map<String, dynamic>? filters;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.filters,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'page': page,
      'limit': limit,
      if (search != null && search!.isNotEmpty) 'search': search,
      ...?filters,
    };
  }
}

/// Use case parameter for ID-based operations
class IdParams {
  final String id;

  const IdParams(this.id);
}
