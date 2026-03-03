import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String name;
  final String phone;
  final String password;

  const RegisterParams({
    required this.name,
    required this.phone,
    required this.password,
  });
}

class RegisterUseCase implements UseCase<AuthResponse, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(RegisterParams params) {
    return repository.register(
      name: params.name,
      phone: params.phone,
      password: params.password,
    );
  }
}
