import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_byte/features/news/model/article.dart';
import 'package:news_byte/features/news/news_details/view_model/news_detail_cubit.dart';
import 'package:news_byte/features/news/news_details/view_model/news_state.dart';

const _article = Article(
  id: 1,
  title: 'Test Article',
  url: 'https://example.com/1',
  imageUrl: 'https://example.com/img/1.jpg',
  newsSite: 'SpaceNews',
  summary: 'Test summary',
  publishedAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
);

const _article2 = Article(
  id: 2,
  title: 'Second Article',
  url: 'https://example.com/2',
  imageUrl: 'https://example.com/img/2.jpg',
  newsSite: 'NASA',
  summary: 'Second summary',
  publishedAt: '2024-01-02T00:00:00Z',
  updatedAt: '2024-01-02T00:00:00Z',
);

void main() {
  group('NewsDetailCubit', () {
    group('init', () {
      blocTest<NewsDetailCubit, NewsDetailState>(
        'emits loaded with articles',
        build: () => NewsDetailCubit(),
        act: (cubit) => cubit.init([_article]),
        expect: () => [
          isA<NewsDetailLoaded>()
              .having((s) => s.articles.length, 'articles count', 1)
              .having((s) => s.articles.first.id, 'first article id', 1),
        ],
      );
    });

    group('toggleFavourite', () {
      blocTest<NewsDetailCubit, NewsDetailState>(
        'adds article to favourites',
        build: () => NewsDetailCubit(),
        seed: () => const NewsDetailLoaded(articles: [_article]),
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => [
          isA<NewsDetailLoaded>()
              .having((s) => s.isFavourite(1), 'is favourite', true),
        ],
      );

      blocTest<NewsDetailCubit, NewsDetailState>(
        'removes article from favourites on second toggle',
        build: () => NewsDetailCubit(),
        seed: () => const NewsDetailLoaded(
          articles: [_article],
          favouriteIds: {1},
        ),
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => [
          isA<NewsDetailLoaded>()
              .having((s) => s.isFavourite(1), 'is favourite', false),
        ],
      );
    });

    group('updateArticles', () {
      blocTest<NewsDetailCubit, NewsDetailState>(
        'updates articles when new list is longer',
        build: () => NewsDetailCubit(),
        seed: () => const NewsDetailLoaded(articles: [_article]),
        act: (cubit) => cubit.updateArticles(
          [_article, _article2],
          isPaginating: false,
          paginationError: false,
        ),
        expect: () => [
          isA<NewsDetailLoaded>()
              .having((s) => s.articles.length, 'articles count', 2),
        ],
      );

      blocTest<NewsDetailCubit, NewsDetailState>(
        'updates pagination state without replacing articles',
        build: () => NewsDetailCubit(),
        seed: () => const NewsDetailLoaded(articles: [_article]),
        act: (cubit) => cubit.updateArticles(
          [_article],
          isPaginating: true,
          paginationError: false,
        ),
        expect: () => [
          isA<NewsDetailLoaded>()
              .having((s) => s.isPaginating, 'is paginating', true)
              .having((s) => s.articles.length, 'articles count', 1),
        ],
      );
    });

    group('onPageChanged', () {
      test('calls onLoadMore when near end of list', () {
        var loadMoreCalled = false;
        final cubit =
            NewsDetailCubit(onLoadMore: () => loadMoreCalled = true);
        cubit.init(List.generate(
          5,
          (i) => Article(
            id: i,
            title: 'Article $i',
            url: 'https://example.com/$i',
            imageUrl: 'https://example.com/img/$i.jpg',
            newsSite: 'SpaceNews',
            summary: 'Summary $i',
            publishedAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-01T00:00:00Z',
          ),
        ));

        cubit.onPageChanged(3);
        expect(loadMoreCalled, isTrue);
      });

      test('does not call onLoadMore when far from end', () {
        var loadMoreCalled = false;
        final cubit =
            NewsDetailCubit(onLoadMore: () => loadMoreCalled = true);
        cubit.init(List.generate(
          10,
          (i) => Article(
            id: i,
            title: 'Article $i',
            url: 'https://example.com/$i',
            imageUrl: 'https://example.com/img/$i.jpg',
            newsSite: 'SpaceNews',
            summary: 'Summary $i',
            publishedAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-01T00:00:00Z',
          ),
        ));

        cubit.onPageChanged(2);
        expect(loadMoreCalled, isFalse);
      });
    });

    group('pageCount', () {
      test('returns articles length when not paginating', () {
        final cubit = NewsDetailCubit();
        cubit.init([_article, _article2]);
        final state = cubit.state as NewsDetailLoaded;
        expect(state.pageCount, 2);
      });

      test('returns articles length + 1 when paginating', () {
        final cubit = NewsDetailCubit();
        cubit.init([_article]);
        cubit.updateArticles(
          [_article],
          isPaginating: true,
          paginationError: false,
        );
        final state = cubit.state as NewsDetailLoaded;
        expect(state.pageCount, 2);
      });
    });
  });
}
