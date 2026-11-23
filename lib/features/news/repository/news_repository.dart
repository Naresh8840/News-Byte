import '../../../core/constants/constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/http_urls.dart';
import '../model/article.dart';
import '../model/article_response.dart';

class NewsRepository {
  Future<ArticlesResponse> getArticles({
    int offset = 0,
    int limit = AppConstants.pageSize,
  }) async {
    final response = await dio.get(
      HttpUrls.articles,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return ArticlesResponse.fromJson(response.data);
  }

  Future<ArticlesResponse> searchArticles({
    required String query,
    int offset = 0,
    int limit = AppConstants.pageSize,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get(
      HttpUrls.articles,
      queryParameters: {
        'title_contains': query,
        'limit': limit,
        'offset': offset,
      },
      cancelToken: cancelToken,
    );
    return ArticlesResponse.fromJson(response.data);
  }

  Future<Article> getArticleById(int id) async {
    final response = await dio.get(HttpUrls.articleById(id));
    return Article.fromJson(response.data);
  }
}
