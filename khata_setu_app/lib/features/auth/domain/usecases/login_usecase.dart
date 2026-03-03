import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String phone;
  final String password;

  const LoginParams({
    required this.phone,
    required this.password,
  });
}

class LoginUseCase implements UseCase<AuthResponse, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(LoginParams params) {
    return repository.login(
      phone: params.phone,
      password: params.password,
    );
  }
}
