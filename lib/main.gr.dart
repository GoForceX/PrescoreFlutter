// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;

import 'main.dart' as _i1;
import 'util/login.dart' as _i5;
import 'widget/exam/exam.dart' as _i2;

class AppRouter extends _i3.RootStackRouter {
  AppRouter([_i4.GlobalKey<_i4.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i3.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.HomePage());
    },
    ExamRoute.name: (routeData) {
      final args = routeData.argsAs<ExamRouteArgs>();
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.ExamPage(key: args.key, uuid: args.uuid, user: args.user));
    }
  };

  @override
  List<_i3.RouteConfig> get routes => [
        _i3.RouteConfig(HomeRoute.name, path: '/'),
        _i3.RouteConfig(ExamRoute.name, path: '/exam-page')
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i3.PageRouteInfo<void> {
  const HomeRoute() : super(HomeRoute.name, path: '/');

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i2.ExamPage]
class ExamRoute extends _i3.PageRouteInfo<ExamRouteArgs> {
  ExamRoute({_i4.Key? key, required String uuid, required _i5.User user})
      : super(ExamRoute.name,
            path: '/exam-page',
            args: ExamRouteArgs(key: key, uuid: uuid, user: user));

  static const String name = 'ExamRoute';
}

class ExamRouteArgs {
  const ExamRouteArgs({this.key, required this.uuid, required this.user});

  final _i4.Key? key;

  final String uuid;

  final _i5.User user;

  @override
  String toString() {
    return 'ExamRouteArgs{key: $key, uuid: $uuid, user: $user}';
  }
}
