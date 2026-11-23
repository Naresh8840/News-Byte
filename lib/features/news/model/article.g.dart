// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map<String, dynamic> json) => Article(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  url: json['url'] as String,
  imageUrl: json['image_url'] as String,
  newsSite: json['news_site'] as String,
  summary: json['summary'] as String,
  publishedAt: json['published_at'] as String,
  updatedAt: json['updated_at'] as String,
  featured: json['featured'] as bool? ?? false,
  authors:
      (json['authors'] as List<dynamic>?)
          ?.map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'url': instance.url,
  'image_url': instance.imageUrl,
  'news_site': instance.newsSite,
  'summary': instance.summary,
  'published_at': instance.publishedAt,
  'updated_at': instance.updatedAt,
  'featured': instance.featured,
  'authors': instance.authors,
};
