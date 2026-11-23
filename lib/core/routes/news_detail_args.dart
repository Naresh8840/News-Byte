import '../../features/news/model/article.dart';

class NewsDetailArgs {
  final List<Article> articles;
  final int initialIndex;

  const NewsDetailArgs({
    required this.articles,
    required this.initialIndex,
  });
}
