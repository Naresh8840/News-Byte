import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_byte/features/news/news_details/view/widgets/app_bar_widget.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/string_resource.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text.dart';
import '../../../model/article.dart';
import '../../../news_list/view_model/news_list_cubit.dart';
import '../../../news_list/view_model/news_list_state.dart';
import '../../view_model/news_detail_cubit.dart';
import '../../view_model/news_state.dart';

class NewsDetailScreen extends StatefulWidget {
  final int initialIndex;

  const NewsDetailScreen({super.key, required this.initialIndex});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Scaffold(
          body: BlocListener<NewsListCubit, NewsListState>(
            listener: (context, state) {
              if (state is NewsListLoaded) {
                context.read<NewsDetailCubit>().updateArticles(
                  state.articles,
                  isPaginating: state.isPaginating,
                  paginationError: state.paginationError,
                );
              }
            },
            child: BlocBuilder<NewsDetailCubit, NewsDetailState>(
              builder: (context, state) {
                if (state is! NewsDetailLoaded) {
                  return const SizedBox.shrink();
                }
                final cubit = context.read<NewsDetailCubit>();

                return PageView.builder(
                  controller: _pageController,
                  onPageChanged: cubit.onPageChanged,
                  itemCount: state.pageCount,
                  itemBuilder: (context, index) {
                    if (index >= state.articles.length) {
                      return _PaginationPage(
                        isPaginating: state.isPaginating,
                        onRetry: cubit.onLoadMore,
                      );
                    }
                    final article = state.articles[index];
                    return _ArticleDetailPage(
                      article: article,
                      isFavourite: state.isFavourite(article.id),
                      onToggleFavourite: () =>
                          cubit.toggleFavourite(article.id),
                      onReadFullArticle: () =>
                          cubit.openArticleUrl(article.url),
                      onShare: () =>
                          cubit.shareArticle(article.title, article.url),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationPage extends StatelessWidget {
  final bool isPaginating;
  final VoidCallback? onRetry;

  const _PaginationPage({required this.isPaginating, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (isPaginating) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            StringResource.failedToLoadMore,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: StringResource.retry,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ArticleDetailPage extends StatelessWidget {
  final Article article;
  final bool isFavourite;
  final VoidCallback onToggleFavourite;
  final VoidCallback onReadFullArticle;
  final VoidCallback onShare;

  const _ArticleDetailPage({
    required this.article,
    required this.isFavourite,
    required this.onToggleFavourite,
    required this.onReadFullArticle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              DetailAppBar(
                article: article,
                isFavourite: isFavourite,
                onToggleFavourite: onToggleFavourite,
                onShare: onShare,
              ),
              SliverToBoxAdapter(child: _DetailBody(article: article)),
            ],
          ),
        ),
        _BottomReadBar(
          onPressed: article.url.isNotEmpty ? onReadFullArticle : null,
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Article article;

  const _DetailBody({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      transform: Matrix4.translationValues(0, -14, 0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: CustomText(
                  article.authorName.isNotEmpty
                      ? article.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      article.authorName,
                      style: theme.textTheme.titleMedium,
                    ),
                    CustomText(
                      DateFormatter.format(article.publishedAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomText(article.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BottomReadBar extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BottomReadBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: CustomButton(
          text: StringResource.readFullArticle,
          onPressed: onPressed,
          isExpanded: true,
        ),
      ),
    );
  }
}
