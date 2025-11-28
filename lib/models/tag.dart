import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final String name;
  final int count;
  final int index;

  const Tag({required this.name, this.count = 0, required this.index});

  factory Tag.fromMap(Map<String, dynamic> data) {
    return Tag(
      name: data['name'] ?? '',
      count: data['count'] ?? 0,
      index: data['index'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [name, count, index];
}
