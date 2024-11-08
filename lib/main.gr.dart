// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:flutter/material.dart' as _i7;
import 'package:prescore_flutter/util/user_util/extensions/user_status.dart'
    as _i8;
import 'package:prescore_flutter/widget/errorbook/errorbook_page.dart' as _i1;
import 'package:prescore_flutter/widget/exam/exam_page.dart' as _i2;
import 'package:prescore_flutter/widget/home/home_page.dart' as _i3;
import 'package:prescore_flutter/widget/paper/paper_page.dart' as _i4;
import 'package:prescore_flutter/widget/settings/settings.dart' as _i5;

abstract class $AppRouter extends _i6.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    ErrorBookRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.ErrorBookPage(),
      );
    },
    ExamRoute.name: (routeData) {
      final args = routeData.argsAs<ExamRouteArgs>();
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.ExamPage(
          key: args.key,
          uuid: args.uuid,
          user: args.user,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.HomePage(),
      );
    },
    PaperRoute.name: (routeData) {
      final args = routeData.argsAs<PaperRouteArgs>();
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.PaperPage(
          key: args.key,
          user: args.user,
          examId: args.examId,
          paperId: args.paperId,
          preview: args.preview,
          userScore: args.userScore,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.SettingsPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.ErrorBookPage]
class ErrorBookRoute extends _i6.PageRouteInfo<void> {
  const ErrorBookRoute({List<_i6.PageRouteInfo>? children})
      : super(
          ErrorBookRoute.name,
          initialChildren: children,
        );

  static const String name = 'ErrorBookRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i2.ExamPage]
class ExamRoute extends _i6.PageRouteInfo<ExamRouteArgs> {
  ExamRoute({
    _i7.Key? key,
    required String uuid,
    required _i8.User user,
    List<_i6.PageRouteInfo>? children,
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

  static const _i6.PageInfo<ExamRouteArgs> page =
      _i6.PageInfo<ExamRouteArgs>(name);
}

class ExamRouteArgs {
  const ExamRouteArgs({
    this.key,
    required this.uuid,
    required this.user,
  });

  final _i7.Key? key;

  final String uuid;

  final _i8.User user;

  @override
  String toString() {
    return 'ExamRouteArgs{key: $key, uuid: $uuid, user: $user}';
  }
}

/// generated route for
/// [_i3.HomePage]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i4.PaperPage]
class PaperRoute extends _i6.PageRouteInfo<PaperRouteArgs> {
  PaperRoute({
    _i7.Key? key,
    required _i8.User user,
    required String examId,
    required String paperId,
    required bool preview,
    required double? userScore,
    List<_i6.PageRouteInfo>? children,
  }) : super(
          PaperRoute.name,
          args: PaperRouteArgs(
            key: key,
            user: user,
            examId: examId,
            paperId: paperId,
            preview: preview,
            userScore: userScore,
          ),
          initialChildren: children,
        );

  static const String name = 'PaperRoute';

  static const _i6.PageInfo<PaperRouteArgs> page =
      _i6.PageInfo<PaperRouteArgs>(name);
}

class PaperRouteArgs {
  const PaperRouteArgs({
    this.key,
    required this.user,
    required this.examId,
    required this.paperId,
    required this.preview,
    required this.userScore,
  });

  final _i7.Key? key;

  final _i8.User user;

  final String examId;

  final String paperId;

  final bool preview;

  final double? userScore;

  @override
  String toString() {
    return 'PaperRouteArgs{key: $key, user: $user, examId: $examId, paperId: $paperId, preview: $preview, userScore: $userScore}';
  }
}

/// generated route for
/// [_i5.SettingsPage]
class SettingsRoute extends _i6.PageRouteInfo<void> {
  const SettingsRoute({List<_i6.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}
