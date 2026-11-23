import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../model/article.dart';
import '../../repository/news_repository.dart';
import 'news_list_state.dart';

class NewsListCubit extends Cubit<NewsListState> {
  final NewsRepository _repository;
  CancelToken? _searchCancelToken;
  CancelToken? _filterCancelToken;
  Timer? _debounce;
  String _searchQuery = '';
  String? _selectedNewsSite;

  NewsListCubit({NewsRepository? repository})
      : _repository = repository ?? NewsRepository(),
        super(const NewsListInitial());

  Future<void> loadArticles() async {
    if (state is NewsListLoading) return;
    emit(const NewsListLoading());

    try {
      final response = await _repository.getArticles();
      final newsSites = _extractNewsSites(response.results);
      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        newsSites: newsSites,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      emit(NewsListError(_extractError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NewsListLoaded) return;
    if (current.isPaginating || current.hasReachedMax || current.isFilterLoading) return;

    emit(current.copyWith(isPaginating: true, paginationError: false));

    try {
      final response = _searchQuery.isEmpty
          ? await _repository.getArticles(
              offset: current.offset,
              newsSite: _selectedNewsSite,
            )
          : await _repository.searchArticles(
              query: _searchQuery,
              offset: current.offset,
              newsSite: _selectedNewsSite,
            );

      final existingIds = current.articles.map((a) => a.id).toSet();
      final newArticles =
          response.results.where((a) => !existingIds.contains(a.id)).toList();
      final allArticles = [...current.articles, ...newArticles];

      final newsSites = _selectedNewsSite == null
          ? _mergeNewsSites(current.newsSites, newArticles)
          : current.newsSites;

      emit(current.copyWith(
        articles: allArticles,
        hasReachedMax: !response.hasMore,
        offset: allArticles.length,
        newsSites: newsSites,
        isPaginating: false,
      ));
    } on DioException catch (_) {
      emit(current.copyWith(isPaginating: false, paginationError: true));
    }
  }

  Future<void> refresh() async {
    final currentNewsSites = state is NewsListLoaded
        ? (state as NewsListLoaded).newsSites
        : <String>[];

    try {
      final response = _searchQuery.isEmpty
          ? await _repository.getArticles(newsSite: _selectedNewsSite)
          : await _repository.searchArticles(
              query: _searchQuery,
              newsSite: _selectedNewsSite,
            );

      final newsSites = _selectedNewsSite == null
          ? _extractNewsSites(response.results)
          : currentNewsSites;

      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        searchQuery: _searchQuery,
        selectedNewsSite: _selectedNewsSite,
        newsSites: newsSites,
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

    final currentNewsSites = state is NewsListLoaded
        ? (state as NewsListLoaded).newsSites
        : <String>[];

    emit(const NewsListLoading());

    try {
      final response = trimmed.isEmpty
          ? await _repository.getArticles(newsSite: _selectedNewsSite)
          : await _repository.searchArticles(
              query: trimmed,
              newsSite: _selectedNewsSite,
              cancelToken: _searchCancelToken,
            );

      if (isClosed) return;

      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        searchQuery: _searchQuery,
        selectedNewsSite: _selectedNewsSite,
        newsSites: currentNewsSites,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (isClosed) return;
      emit(NewsListError(_extractError(e)));
    }
  }

  Future<void> filterByNewsSite(String? newsSite) async {
    final current = state;
    if (current is! NewsListLoaded) return;
    if (newsSite == current.selectedNewsSite) return;

    _filterCancelToken?.cancel();
    _filterCancelToken = CancelToken();
    _selectedNewsSite = newsSite;

    emit(current.copyWith(
      selectedNewsSite: newsSite,
      clearNewsSite: newsSite == null,
      isFilterLoading: true,
    ));

    try {
      final response = _searchQuery.isEmpty
          ? await _repository.getArticles(
              newsSite: newsSite,
              cancelToken: _filterCancelToken,
            )
          : await _repository.searchArticles(
              query: _searchQuery,
              newsSite: newsSite,
              cancelToken: _filterCancelToken,
            );

      if (isClosed) return;

      final newsSites = newsSite == null
          ? _mergeNewsSites(current.newsSites, response.results)
          : current.newsSites;

      emit(NewsListLoaded(
        articles: response.results,
        hasReachedMax: !response.hasMore,
        searchQuery: _searchQuery,
        selectedNewsSite: newsSite,
        newsSites: newsSites,
        offset: response.results.length,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (isClosed) return;
      emit(current.copyWith(isFilterLoading: false));
    }
  }

  List<String> _extractNewsSites(List<Article> articles) {
    return articles.map((a) => a.newsSite).toSet().toList()..sort();
  }

  List<String> _mergeNewsSites(List<String> existing, List<Article> articles) {
    return {...existing, ...articles.map((a) => a.newsSite)}.toList()..sort();
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
    _filterCancelToken?.cancel();
    _debounce?.cancel();
    return super.close();
  }
}
