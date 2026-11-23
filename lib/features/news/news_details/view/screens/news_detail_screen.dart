import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/string_resource.dart';
import '../../../../../core/widgets/cached_image.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text.dart';
import '../../../model/article.dart';
import '../../../news_list/view_model/news_list_cubit.dart';
import '../../../news_list/view_model/news_list_state.dart';
import '../../view_model/news_detail_cubit.dart';
import '../../view_model/news_state.dart';

class NewsDetailScreen extends StatefulWidget {
  final int initialIndex;

  const NewsDetailScreen({
    super.key,
    required this.initialIndex,
  });

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: BlocListener<NewsListCubit, NewsListState>(
          listener: (context, state) {
            if (state is NewsListLoaded) {
              context.read<NewsDetailCubit>().updateArticles(
                    state.filteredArticles,
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
              _DetailAppBar(
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

class _DetailAppBar extends StatelessWidget {
  final Article article;
  final bool isFavourite;
  final VoidCallback onToggleFavourite;
  final VoidCallback onShare;

  const _DetailAppBar({
    required this.article,
    required this.isFavourite,
    required this.onToggleFavourite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: Icon(
                isFavourite ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onToggleFavourite,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: PopupMenuButton<String>(
              icon:
                  const Icon(Icons.more_horiz, color: Colors.white, size: 20),
              onSelected: (value) {
                if (value == 'share') onShare();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: const [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 10),
                      Text(StringResource.shareArticle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: article.imageUrl,
              borderRadius: BorderRadius.zero,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      article.newsSite,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomText(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    DateFormatter.timeAgo(article.publishedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
