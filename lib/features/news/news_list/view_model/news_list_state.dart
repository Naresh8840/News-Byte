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
  final List<String> newsSites;
  final bool isPaginating;
  final bool isFilterLoading;
  final bool paginationError;
  final int offset;

  const NewsListLoaded({
    required this.articles,
    this.hasReachedMax = false,
    this.searchQuery = '',
    this.selectedNewsSite,
    this.newsSites = const [],
    this.isPaginating = false,
    this.isFilterLoading = false,
    this.paginationError = false,
    this.offset = 0,
  });

  NewsListLoaded copyWith({
    List<Article>? articles,
    bool? hasReachedMax,
    String? searchQuery,
    String? selectedNewsSite,
    List<String>? newsSites,
    bool? isPaginating,
    bool? isFilterLoading,
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
      newsSites: newsSites ?? this.newsSites,
      isPaginating: isPaginating ?? this.isPaginating,
      isFilterLoading: isFilterLoading ?? this.isFilterLoading,
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
        newsSites,
        isPaginating,
        isFilterLoading,
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
