import 'package:json_annotation/json_annotation.dart';

import 'article.dart';

part 'article_response.g.dart';

@JsonSerializable()
class ArticlesResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Article> results;

  const ArticlesResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;

  factory ArticlesResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticlesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArticlesResponseToJson(this);
}
