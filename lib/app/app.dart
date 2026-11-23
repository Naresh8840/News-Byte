import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/routes/app_routes.dart';
import '../features/news/news_list/view_model/news_list_cubit.dart';
import 'theme/app_theme.dart';

class NewsByte extends StatelessWidget {
  const NewsByte({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsListCubit(),
      child: MaterialApp(
        title: 'News Byte',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: getRoute,
        navigatorObservers: [appRouteObserver],
      ),
    );
  }
}
