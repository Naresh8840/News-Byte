import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/article.dart';
import 'news_state.dart';

class NewsDetailCubit extends Cubit<NewsDetailState> {
  final void Function()? onLoadMore;

  NewsDetailCubit({this.onLoadMore}) : super(const NewsDetailInitial());

  void init(List<Article> articles) {
    emit(NewsDetailLoaded(articles: List.from(articles)));
  }

  void onPageChanged(int index) {
    final current = state;
    if (current is! NewsDetailLoaded) return;
    if (index >= current.articles.length - 3) {
      onLoadMore?.call();
    }
  }

  void updateArticles(
    List<Article> articles, {
    required bool isPaginating,
    required bool paginationError,
  }) {
    final current = state;
    if (current is! NewsDetailLoaded) return;
    emit(current.copyWith(
      articles:
          articles.length > current.articles.length ? List.from(articles) : null,
      isPaginating: isPaginating,
      paginationError: paginationError,
    ));
  }

  void toggleFavourite(int articleId) {
    final current = state;
    if (current is! NewsDetailLoaded) return;
    final updated = Set<int>.from(current.favouriteIds);
    updated.contains(articleId)
        ? updated.remove(articleId)
        : updated.add(articleId);
    emit(current.copyWith(favouriteIds: updated));
  }

  Future<void> openArticleUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void shareArticle(String title, String url) {
    Share.share('$title\n$url');
  }
}

class NewsDetailArgs {
  final List<Article> articles;
  final int initialIndex;

  const NewsDetailArgs({
    required this.articles,
    required this.initialIndex,
  });
}