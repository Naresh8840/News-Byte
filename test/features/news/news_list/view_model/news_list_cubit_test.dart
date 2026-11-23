import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_byte/core/network/api_exception.dart';
import 'package:news_byte/features/news/model/article.dart';
import 'package:news_byte/features/news/model/article_response.dart';
import 'package:news_byte/features/news/news_list/view_model/news_list_cubit.dart';
import 'package:news_byte/features/news/news_list/view_model/news_list_state.dart';
import 'package:news_byte/features/news/repository/news_repository.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

Article _testArticle({int id = 1, String newsSite = 'SpaceNews'}) {
  return Article(
    id: id,
    title: 'Article $id',
    url: 'https://example.com/$id',
    imageUrl: 'https://example.com/img/$id.jpg',
    newsSite: newsSite,
    summary: 'Summary of article $id',
    publishedAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  );
}

void main() {
  late MockNewsRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsRepository();
  });

  group('NewsListCubit', () {
    group('loadArticles', () {
      final articles = [_testArticle(id: 1), _testArticle(id: 2)];
      final response = ArticlesResponse(
        count: 20,
        next: 'https://api.example.com?offset=10',
        results: articles,
      );

      blocTest<NewsListCubit, NewsListState>(
        'emits [loading, loaded] on success',
        build: () {
          when(() => mockRepository.getArticles(
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => response);
          return NewsListCubit(repository: mockRepository);
        },
        act: (cubit) => cubit.loadArticles(),
        expect: () => [
          isA<NewsListLoading>(),
          isA<NewsListLoaded>()
              .having((s) => s.articles.length, 'articles count', 2)
              .having((s) => s.hasReachedMax, 'hasReachedMax', false)
              .having((s) => s.offset, 'offset', 2),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'emits [loading, error] on DioException',
        build: () {
          when(() => mockRepository.getArticles(
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              )).thenThrow(DioException(
            requestOptions: RequestOptions(),
            error: const ApiException('Server error'),
          ));
          return NewsListCubit(repository: mockRepository);
        },
        act: (cubit) => cubit.loadArticles(),
        expect: () => [
          isA<NewsListLoading>(),
          isA<NewsListError>()
              .having((s) => s.message, 'message', 'Server error'),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'does not emit if already loading',
        build: () => NewsListCubit(repository: mockRepository),
        seed: () => const NewsListLoading(),
        act: (cubit) => cubit.loadArticles(),
        expect: () => <NewsListState>[],
      );
    });

    group('loadMore', () {
      final existingArticles = [_testArticle(id: 1)];
      final newArticles = [_testArticle(id: 2), _testArticle(id: 3)];
      final moreResponse = ArticlesResponse(
        count: 20,
        next: 'https://api.example.com?offset=20',
        results: newArticles,
      );

      blocTest<NewsListCubit, NewsListState>(
        'appends new articles and deduplicates',
        build: () {
          when(() => mockRepository.getArticles(
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => moreResponse);
          return NewsListCubit(repository: mockRepository);
        },
        seed: () => NewsListLoaded(
          articles: existingArticles,
          offset: 1,
        ),
        act: (cubit) => cubit.loadMore(),
        expect: () => [
          isA<NewsListLoaded>()
              .having((s) => s.isPaginating, 'isPaginating', true),
          isA<NewsListLoaded>()
              .having((s) => s.articles.length, 'articles count', 3)
              .having((s) => s.isPaginating, 'isPaginating', false),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'does nothing if already paginating',
        build: () => NewsListCubit(repository: mockRepository),
        seed: () => const NewsListLoaded(
          articles: [],
          isPaginating: true,
        ),
        act: (cubit) => cubit.loadMore(),
        expect: () => <NewsListState>[],
      );

      blocTest<NewsListCubit, NewsListState>(
        'does nothing if reached max',
        build: () => NewsListCubit(repository: mockRepository),
        seed: () => const NewsListLoaded(
          articles: [],
          hasReachedMax: true,
        ),
        act: (cubit) => cubit.loadMore(),
        expect: () => <NewsListState>[],
      );
    });

    group('refresh', () {
      final refreshedArticles = [_testArticle(id: 10)];
      final refreshResponse = ArticlesResponse(
        count: 1,
        results: refreshedArticles,
      );

      blocTest<NewsListCubit, NewsListState>(
        'emits loaded with fresh data',
        build: () {
          when(() => mockRepository.getArticles(
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => refreshResponse);
          return NewsListCubit(repository: mockRepository);
        },
        seed: () => NewsListLoaded(
          articles: [_testArticle(id: 1)],
          offset: 1,
        ),
        act: (cubit) => cubit.refresh(),
        expect: () => [
          isA<NewsListLoaded>()
              .having((s) => s.articles.length, 'articles count', 1)
              .having((s) => s.articles.first.id, 'first id', 10),
        ],
      );
    });

    group('search', () {
      final searchResults = [_testArticle(id: 5)];
      final searchResponse = ArticlesResponse(
        count: 1,
        results: searchResults,
      );

      blocTest<NewsListCubit, NewsListState>(
        'emits [loading, loaded] with search results',
        build: () {
          when(() => mockRepository.searchArticles(
                query: any(named: 'query'),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
                cancelToken: any(named: 'cancelToken'),
              )).thenAnswer((_) async => searchResponse);
          return NewsListCubit(repository: mockRepository);
        },
        act: (cubit) => cubit.search('nasa'),
        expect: () => [
          isA<NewsListLoading>(),
          isA<NewsListLoaded>()
              .having((s) => s.articles.length, 'results count', 1)
              .having((s) => s.searchQuery, 'searchQuery', 'nasa'),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'skips duplicate search query',
        build: () {
          when(() => mockRepository.searchArticles(
                query: any(named: 'query'),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
                cancelToken: any(named: 'cancelToken'),
              )).thenAnswer((_) async => searchResponse);
          return NewsListCubit(repository: mockRepository);
        },
        act: (cubit) async {
          await cubit.search('nasa');
          await cubit.search('nasa');
        },
        verify: (cubit) {
          verify(() => mockRepository.searchArticles(
                query: any(named: 'query'),
                offset: any(named: 'offset'),
                limit: any(named: 'limit'),
                cancelToken: any(named: 'cancelToken'),
              )).called(1);
        },
        expect: () => [
          isA<NewsListLoading>(),
          isA<NewsListLoaded>(),
        ],
      );
    });

    group('filterByNewsSite', () {
      blocTest<NewsListCubit, NewsListState>(
        'updates selectedNewsSite on loaded state',
        build: () => NewsListCubit(repository: mockRepository),
        seed: () => NewsListLoaded(
          articles: [
            _testArticle(id: 1, newsSite: 'SpaceNews'),
            _testArticle(id: 2, newsSite: 'NASA'),
          ],
          offset: 2,
        ),
        act: (cubit) => cubit.filterByNewsSite('NASA'),
        expect: () => [
          isA<NewsListLoaded>()
              .having((s) => s.selectedNewsSite, 'selectedNewsSite', 'NASA')
              .having((s) => s.filteredArticles.length, 'filtered count', 1),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'clears filter when null passed',
        build: () => NewsListCubit(repository: mockRepository),
        seed: () => NewsListLoaded(
          articles: [
            _testArticle(id: 1, newsSite: 'SpaceNews'),
            _testArticle(id: 2, newsSite: 'NASA'),
          ],
          selectedNewsSite: 'NASA',
          offset: 2,
        ),
        act: (cubit) => cubit.filterByNewsSite(null),
        expect: () => [
          isA<NewsListLoaded>()
              .having((s) => s.selectedNewsSite, 'selectedNewsSite', null)
              .having((s) => s.filteredArticles.length, 'filtered count', 2),
        ],
      );

      blocTest<NewsListCubit, NewsListState>(
        'does nothing if state is not loaded',
        build: () => NewsListCubit(repository: mockRepository),
        act: (cubit) => cubit.filterByNewsSite('NASA'),
        expect: () => <NewsListState>[],
      );
    });
  });
}
