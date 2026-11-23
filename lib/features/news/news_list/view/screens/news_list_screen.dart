import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/routes/news_detail_args.dart';
import '../../../../../core/utils/string_resource.dart';
import '../../../../../core/widgets/custom_text.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/shimmer_loading.dart';
import '../../../model/article.dart';
import '../../view_model/news_list_cubit.dart';
import '../../view_model/news_list_state.dart';
import '../widgets/article_card.dart';
import '../widgets/news_site_chips.dart';
import '../widgets/search_bar_widget.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<NewsListCubit>().loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NewsSearchBar(controller: _searchController),
              ),
              const SizedBox(height: 12),
              BlocBuilder<NewsListCubit, NewsListState>(
                buildWhen: (prev, curr) {
                  if (prev is NewsListLoaded && curr is NewsListLoaded) {
                    return prev.newsSites != curr.newsSites ||
                        prev.selectedNewsSite != curr.selectedNewsSite;
                  }
                  return prev.runtimeType != curr.runtimeType;
                },
                builder: (context, state) {
                  if (state is! NewsListLoaded) return const SizedBox.shrink();
                  return NewsSiteChips(
                    sites: state.newsSites,
                    selected: state.selectedNewsSite,
                    onSelected: (site) {
                      context.read<NewsListCubit>().filterByNewsSite(site);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<NewsListCubit, NewsListState>(
                  builder: (context, state) {
                    if (state is NewsListInitial || state is NewsListLoading) {
                      return const ShimmerListLoader();
                    }
      
                    if (state is NewsListError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () {
                          context.read<NewsListCubit>().loadArticles();
                        },
                      );
                    }
      
                    if (state is NewsListLoaded) {
                      final articles = state.filteredArticles;
                      if (articles.isEmpty) {
                        return EmptyView(
                          message: state.searchQuery.isNotEmpty
                              ? StringResource.noResultsFor(state.searchQuery)
                              : StringResource.noArticlesFound,
                        );
                      }
                      final width = MediaQuery.sizeOf(context).width;
                      final crossAxisCount =
                          width >= 900 ? 3 : width >= 600 ? 2 : 1;
                      return _ArticleListView(
                        articles: articles,
                        isPaginating: state.isPaginating,
                        crossAxisCount: crossAxisCount,
                        onRefresh: () =>
                            context.read<NewsListCubit>().refresh(),
                        onArticleTap: (index) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.newsDetail,
                            arguments: NewsDetailArgs(
                              articles: articles,
                              initialIndex: index,
                            ),
                          );
                        },
                      );
                    }
      
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(StringResource.discover,
              style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          CustomText(
            StringResource.newsFromWorld,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ArticleListView extends StatelessWidget {
  final List<Article> articles;
  final bool isPaginating;
  final int crossAxisCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onArticleTap;

  const _ArticleListView({
    required this.articles,
    this.isPaginating = false,
    this.crossAxisCount = 1,
    required this.onRefresh,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = articles.length + (isPaginating ? 1 : 0);

    if (crossAxisCount > 1) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 120,
                ),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  if (index == articles.length - 1) {
                    _triggerLoadMore(context);
                  }
                  return ArticleCard(
                    article: articles[index],
                    onTap: () => onArticleTap(index),
                  );
                },
              ),
            ),
            if (isPaginating)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (index == articles.length - 1) {
            _triggerLoadMore(context);
          }
          return ArticleCard(
            article: articles[index],
            onTap: () => onArticleTap(index),
          );
        },
      ),
    );
  }

  void _triggerLoadMore(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsListCubit>().loadMore();
    });
  }
}
