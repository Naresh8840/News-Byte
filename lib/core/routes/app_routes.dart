import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_byte/features/news/news_details/view/screens/news_detail_screen.dart';
import 'package:news_byte/features/news/news_details/view_model/news_detail_cubit.dart';
import 'package:news_byte/features/news/news_list/view/screens/news_list_screen.dart';
import 'package:news_byte/features/news/news_list/view_model/news_list_cubit.dart';
import 'package:news_byte/features/splash/splash_screen.dart';


final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String newsList = '/news-list';
  static const String newsDetail = '/news-detail';
}



Route<dynamic>? getRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(
        settings: const RouteSettings(name: 'Splash'),
        builder: (_) => PageBuilder.splashPage(),
      );

    case AppRoutes.newsList:
      return PageRouteBuilder(
        settings: const RouteSettings(name: 'News List'),
        pageBuilder: (context, animation1, animation2) =>
            PageBuilder.newsListPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );

    case AppRoutes.newsDetail:
      final args = settings.arguments as NewsDetailArgs;
      return MaterialPageRoute(
        settings: const RouteSettings(name: 'News Detail'),
        builder: (context) => PageBuilder.newsDetailPage(context, args),
      );

    default:
      return null;
  }
}


class PageBuilder {
  const PageBuilder._();

  static Widget splashPage() {
    return const SplashScreen();
  }

  static Widget newsListPage() {
    return const NewsListScreen();
  }

  static Widget newsDetailPage(
    BuildContext context,
    NewsDetailArgs args,
  ) {
    return BlocProvider(
      create: (BuildContext context) {
        final newsListCubit = context.read<NewsListCubit>();
        return NewsDetailCubit(
          onLoadMore: () => newsListCubit.loadMore(),
        )..init(args.articles);
      },
      child: NewsDetailScreen(initialIndex: args.initialIndex),
    );
  }
}