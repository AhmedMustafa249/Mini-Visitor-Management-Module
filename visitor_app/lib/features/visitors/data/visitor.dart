import 'package:equatable/equatable.dart';

class Visitor extends Equatable {
  final String id;
  final String name;
  final String mobile;
  final String visitDate;
  final String createdAt;

  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.visitDate,
    required this.createdAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) => Visitor(
        id: json['id'] as String,
        name: json['name'] as String,
        mobile: json['mobile'] as String,
        visitDate: json['visitDate'] as String,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'visitDate': visitDate,
      };

  @override
  List<Object?> get props => [id, name, mobile, visitDate, createdAt];
}
