// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;
import 'package:prescore_flutter/main.dart' as _i2;
import 'package:prescore_flutter/util/user_util.dart' as _i7;
import 'package:prescore_flutter/widget/exam/exam.dart' as _i1;
import 'package:prescore_flutter/widget/paper/paper_page.dart' as _i3;
import 'package:prescore_flutter/widget/settings.dart' as _i4;

abstract class $AppRouter extends _i5.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i5.PageFactory> pagesMap = {
    ExamRoute.name: (routeData) {
      final args = routeData.argsAs<ExamRouteArgs>();
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.ExamPage(
          key: args.key,
          uuid: args.uuid,
          user: args.user,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.HomePage(),
      );
    },
    PaperRoute.name: (routeData) {
      final args = routeData.argsAs<PaperRouteArgs>();
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.PaperPage(
          key: args.key,
          user: args.user,
          examId: args.examId,
          paperId: args.paperId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.SettingsPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.ExamPage]
class ExamRoute extends _i5.PageRouteInfo<ExamRouteArgs> {
  ExamRoute({
    _i6.Key? key,
    required String uuid,
    required _i7.User user,
    List<_i5.PageRouteInfo>? children,
  }) : super(
          ExamRoute.name,
          args: ExamRouteArgs(
            key: key,
            uuid: uuid,
            user: user,
          ),
          initialChildren: children,
        );

  static const String name = 'ExamRoute';

  static const _i5.PageInfo<ExamRouteArgs> page =
      _i5.PageInfo<ExamRouteArgs>(name);
}

class ExamRouteArgs {
  const ExamRouteArgs({
    this.key,
    required this.uuid,
    required this.user,
  });

  final _i6.Key? key;

  final String uuid;

  final _i7.User user;

  @override
  String toString() {
    return 'ExamRouteArgs{key: $key, uuid: $uuid, user: $user}';
  }
}

/// generated route for
/// [_i2.HomePage]
class HomeRoute extends _i5.PageRouteInfo<void> {
  const HomeRoute({List<_i5.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i5.PageInfo<void> page = _i5.PageInfo<void>(name);
}

/// generated route for
/// [_i3.PaperPage]
class PaperRoute extends _i5.PageRouteInfo<PaperRouteArgs> {
  PaperRoute({
    _i6.Key? key,
    required _i7.User user,
    required String examId,
    required String paperId,
    List<_i5.PageRouteInfo>? children,
  }) : super(
          PaperRoute.name,
          args: PaperRouteArgs(
            key: key,
            user: user,
            examId: examId,
            paperId: paperId,
          ),
          initialChildren: children,
        );

  static const String name = 'PaperRoute';

  static const _i5.PageInfo<PaperRouteArgs> page =
      _i5.PageInfo<PaperRouteArgs>(name);
}

class PaperRouteArgs {
  const PaperRouteArgs({
    this.key,
    required this.user,
    required this.examId,
    required this.paperId,
  });

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
  const SettingsRoute({List<_i5.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i5.PageInfo<void> page = _i5.PageInfo<void>(name);
}
