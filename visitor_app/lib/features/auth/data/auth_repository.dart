import '../../auth/data/user.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AuthRepository {
  Future<User> login(String username, String password) async {
    final dio = createDioClient();
    final response = await dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
