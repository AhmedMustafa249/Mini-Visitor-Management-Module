import 'package:dio/dio.dart';
import 'visitor.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class VisitorRepository {
  final String token;

  VisitorRepository({required this.token});

  Dio get _dio => createDioClient(token: token);

  Future<List<Visitor>> getVisitors() async {
    final response = await _dio.get(ApiEndpoints.visitors);
    final list = response.data as List<dynamic>;
    return list.map((e) => Visitor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Visitor> getVisitorById(String id) async {
    final response = await _dio.get(ApiEndpoints.visitorById(id));
    return Visitor.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Visitor> addVisitor({
    required String name,
    required String mobile,
    required String visitDate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.visitors,
      data: {'name': name, 'mobile': mobile, 'visitDate': visitDate},
    );
    return Visitor.fromJson(response.data as Map<String, dynamic>);
  }
}
