import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../repository/news_repository.dart';
import 'news_list_state.dart';

class NewsListCubit extends Cubit<NewsListState> {
  final NewsRepository _repository;
  CancelToken? _searchCancelToken;
  Timer? _debounce;
  String _searchQuery = '';

  NewsListCubit({NewsRepository? repository})
      : _repository = repository ?? NewsRepository(),
        super(const NewsListInitial());

  Future<void> loadArticles() async {
    if (state is NewsListLoading) return;
    emit(const NewsListLoading());

    try {
      final response = await _repository.getArticles();
      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      emit(NewsListError(_extractError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NewsListLoaded) return;
    if (current.isPaginating || current.hasReachedMax) return;

    emit(current.copyWith(isPaginating: true, paginationError: false));

    try {
      final response = _searchQuery.isEmpty
          ? await _repository.getArticles(offset: current.offset)
          : await _repository.searchArticles(
              query: _searchQuery,
              offset: current.offset,
            );

      final existingIds = current.articles.map((a) => a.id).toSet();
      final newArticles =
          response.results.where((a) => !existingIds.contains(a.id)).toList();
      final allArticles = [...current.articles, ...newArticles];

      emit(current.copyWith(
        articles: allArticles,
        hasReachedMax: !response.hasMore,
        offset: allArticles.length,
        isPaginating: false,
      ));
    } on DioException catch (_) {
      emit(current.copyWith(isPaginating: false, paginationError: true));
    }
  }

  Future<void> refresh() async {
    try {
      final response = _searchQuery.isEmpty
          ? await _repository.getArticles()
          : await _repository.searchArticles(query: _searchQuery);

      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        searchQuery: _searchQuery,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      emit(NewsListError(_extractError(e)));
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => search(value),
    );
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;

    _searchCancelToken?.cancel();
    _searchCancelToken = CancelToken();
    _searchQuery = trimmed;

    emit(const NewsListLoading());

    try {
      final response = trimmed.isEmpty
          ? await _repository.getArticles()
          : await _repository.searchArticles(
              query: trimmed,
              cancelToken: _searchCancelToken,
            );

      if (isClosed) return;

      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        searchQuery: _searchQuery,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (isClosed) return;
      emit(NewsListError(_extractError(e)));
    }
  }

  void filterByNewsSite(String? newsSite) {
    final current = state;
    if (current is! NewsListLoaded) return;
    if (newsSite == current.selectedNewsSite) return;
    emit(current.copyWith(
      selectedNewsSite: newsSite,
      clearNewsSite: newsSite == null,
    ));
  }

  String _extractError(DioException e) {
    if (e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    return 'Something went wrong.';
  }

  @override
  Future<void> close() {
    _searchCancelToken?.cancel();
    _debounce?.cancel();
    return super.close();
  }
}
