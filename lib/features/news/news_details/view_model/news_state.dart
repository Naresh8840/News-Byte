import 'package:equatable/equatable.dart';

import '../../model/article.dart';

class NewsDetailState extends Equatable {
  const NewsDetailState();

  @override
  List<Object?> get props => [];
}

class NewsDetailInitial extends NewsDetailState {
  const NewsDetailInitial();
}

class NewsDetailLoaded extends NewsDetailState {
  final List<Article> articles;
  final Set<int> favouriteIds;
  final bool isPaginating;
  final bool paginationError;

  const NewsDetailLoaded({
    required this.articles,
    this.favouriteIds = const {},
    this.isPaginating = false,
    this.paginationError = false,
  });

  int get pageCount {
    if (isPaginating || paginationError) return articles.length + 1;
    return articles.length;
  }

  bool isFavourite(int id) => favouriteIds.contains(id);

  NewsDetailLoaded copyWith({
    List<Article>? articles,
    Set<int>? favouriteIds,
    bool? isPaginating,
    bool? paginationError,
  }) {
    return NewsDetailLoaded(
      articles: articles ?? this.articles,
      favouriteIds: favouriteIds ?? this.favouriteIds,
      isPaginating: isPaginating ?? this.isPaginating,
      paginationError: paginationError ?? this.paginationError,
    );
  }

  @override
  List<Object?> get props =>
      [articles, favouriteIds, isPaginating, paginationError];
}
