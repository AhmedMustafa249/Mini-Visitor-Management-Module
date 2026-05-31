import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String token;
  final String username;

  const User({required this.token, required this.username});

  factory User.fromJson(Map<String, dynamic> json) => User(
        token: json['token'] as String,
        username: json['username'] as String,
      );

  @override
  List<Object?> get props => [token, username];
}
