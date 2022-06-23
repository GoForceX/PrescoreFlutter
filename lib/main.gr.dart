// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;

import 'main.dart' as _i1;
import 'util/login.dart' as _i7;
import 'widget/exam/exam.dart' as _i2;
import 'widget/paper/paper_page.dart' as _i3;
import 'widget/settings.dart' as _i4;

class AppRouter extends _i5.RootStackRouter {
  AppRouter([_i6.GlobalKey<_i6.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i5.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i1.HomePage());
    },
    ExamRoute.name: (routeData) {
      final args = routeData.argsAs<ExamRouteArgs>();
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i2.ExamPage(key: args.key, uuid: args.uuid, user: args.user));
    },
    PaperRoute.name: (routeData) {
      final args = routeData.argsAs<PaperRouteArgs>();
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i3.PaperPage(
              key: args.key,
              user: args.user,
              examId: args.examId,
              paperId: args.paperId));
    },
    SettingsRoute.name: (routeData) {
      return _i5.MaterialPageX<dynamic>(
          routeData: routeData, child: const _i4.SettingsPage());
    }
  };

  @override
  List<_i5.RouteConfig> get routes => [
        _i5.RouteConfig(HomeRoute.name, path: '/'),
        _i5.RouteConfig(ExamRoute.name, path: '/exam-page'),
        _i5.RouteConfig(PaperRoute.name, path: '/paper-page'),
        _i5.RouteConfig(SettingsRoute.name, path: '/settings-page')
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i5.PageRouteInfo<void> {
  const HomeRoute() : super(HomeRoute.name, path: '/');

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i2.ExamPage]
class ExamRoute extends _i5.PageRouteInfo<ExamRouteArgs> {
  ExamRoute({_i6.Key? key, required String uuid, required _i7.User user})
      : super(ExamRoute.name,
            path: '/exam-page',
            args: ExamRouteArgs(key: key, uuid: uuid, user: user));

  static const String name = 'ExamRoute';
}

class ExamRouteArgs {
  const ExamRouteArgs({this.key, required this.uuid, required this.user});

  final _i6.Key? key;

  final String uuid;

  final _i7.User user;

  @override
  String toString() {
    return 'ExamRouteArgs{key: $key, uuid: $uuid, user: $user}';
  }
}

/// generated route for
/// [_i3.PaperPage]
class PaperRoute extends _i5.PageRouteInfo<PaperRouteArgs> {
  PaperRoute(
      {_i6.Key? key,
      required _i7.User user,
      required String examId,
      required String paperId})
      : super(PaperRoute.name,
            path: '/paper-page',
            args: PaperRouteArgs(
                key: key, user: user, examId: examId, paperId: paperId));

  static const String name = 'PaperRoute';
}

class PaperRouteArgs {
  const PaperRouteArgs(
      {this.key,
      required this.user,
      required this.examId,
      required this.paperId});

  final _i6.Key? key;

  final _i7.User user;

  final String examId;

  final String paperId;

  @override
  String toString() {
    return 'PaperRouteArgs{key: $key, user: $user, examId: $examId, paperId: $paperId}';
  }
}

/// generated route for
/// [_i4.SettingsPage]
class SettingsRoute extends _i5.PageRouteInfo<void> {
  const SettingsRoute() : super(SettingsRoute.name, path: '/settings-page');

  static const String name = 'SettingsRoute';
}
