import 'package:equatable/equatable.dart';

import '../../model/article.dart';

class NewsListState extends Equatable {
  const NewsListState();

  @override
  List<Object?> get props => [];
}

class NewsListInitial extends NewsListState {
  const NewsListInitial();
}

class NewsListLoading extends NewsListState {
  const NewsListLoading();
}

class NewsListLoaded extends NewsListState {
  final List<Article> articles;
  final bool hasReachedMax;
  final String searchQuery;
  final String? selectedNewsSite;
  final bool isPaginating;
  final bool paginationError;
  final int offset;

  const NewsListLoaded({
    required this.articles,
    this.hasReachedMax = false,
    this.searchQuery = '',
    this.selectedNewsSite,
    this.isPaginating = false,
    this.paginationError = false,
    this.offset = 0,
  });

  List<String> get newsSites {
    final sites = articles.map((a) => a.newsSite).toSet().toList();
    sites.sort();
    return sites;
  }

  List<Article> get filteredArticles {
    if (selectedNewsSite == null || selectedNewsSite!.isEmpty) {
      return articles;
    }
    return articles.where((a) => a.newsSite == selectedNewsSite).toList();
  }

  NewsListLoaded copyWith({
    List<Article>? articles,
    bool? hasReachedMax,
    String? searchQuery,
    String? selectedNewsSite,
    bool? isPaginating,
    bool? paginationError,
    int? offset,
    bool clearNewsSite = false,
  }) {
    return NewsListLoaded(
      articles: articles ?? this.articles,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedNewsSite:
          clearNewsSite ? null : (selectedNewsSite ?? this.selectedNewsSite),
      isPaginating: isPaginating ?? this.isPaginating,
      paginationError: paginationError ?? this.paginationError,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [
        articles,
        hasReachedMax,
        searchQuery,
        selectedNewsSite,
        isPaginating,
        paginationError,
        offset,
      ];
}

class NewsListError extends NewsListState {
  final String message;

  const NewsListError(this.message);

  @override
  List<Object?> get props => [message];
}
