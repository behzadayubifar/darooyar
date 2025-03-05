import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_form_provider.g.dart';

class RegisterFormData {
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  RegisterFormData({
    this.username = '',
    this.email = '',
    this.password = '',
    this.firstName = '',
    this.lastName = '',
  });

  RegisterFormData copyWith({
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
  }) {
    return RegisterFormData(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

class LoginFormData {
  final String email;
  final String password;

  LoginFormData({
    this.email = '',
    this.password = '',
  });

  LoginFormData copyWith({
    String? email,
    String? password,
  }) {
    return LoginFormData(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}

@Riverpod(keepAlive: true)
class RegisterForm extends _$RegisterForm {
  @override
  RegisterFormData build() => RegisterFormData();

  void updateForm({
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
  }) {
    state = state.copyWith(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  void clear() {
    state = RegisterFormData();
  }
}

@Riverpod(keepAlive: true)
class LoginForm extends _$LoginForm {
  @override
  LoginFormData build() => LoginFormData();

  void updateForm({
    String? email,
    String? password,
  }) {
    state = state.copyWith(
      email: email,
      password: password,
    );
  }

  void clear() {
    state = LoginFormData();
  }
}
