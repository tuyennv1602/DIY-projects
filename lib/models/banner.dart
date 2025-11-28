import 'package:equatable/equatable.dart';

class Banner extends Equatable {
  final String id;
  final String imageUrl;
  final String link;

  const Banner({required this.id, required this.imageUrl, required this.link});

  factory Banner.fromFirestore(Map<String, dynamic> data, String id) {
    return Banner(
      id: id,
      imageUrl: data['image_url'] ?? '',
      link: data['link'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'image_url': imageUrl, 'link': link};
  }

  @override
  List<Object?> get props => [id, imageUrl, link];
}
