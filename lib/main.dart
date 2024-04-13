import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cronet_http_embedded/cronet_http.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:http/http.dart' hide Response;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:prescore_flutter/service.dart';
import 'package:prescore_flutter/util/cronet_adapter.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:prescore_flutter/widget/main/exams.dart';
import 'package:prescore_flutter/widget/main/login.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'constants.dart';
import 'model/login_model.dart';

@pragma('vm:entry-point')
serviceEntry() async {
  if (sentryAnalyseEnable) {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://baab724bcf3cc8b40759a031edd478eb@o4506218740776960.ingest.sentry.io/4506218743857152';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    }, appRunner: () => serviceMain());
  } else {
    serviceMain();
  }
}

bool firebaseAnalyseEnable = kReleaseMode;
bool sentryAnalyseEnable = kReleaseMode;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseSingleton.singleton.init();
  var clientFactory = Client.new; // Constructs the default
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      Future<CronetEngine>? engine;
      clientFactory = () {
        engine ??= CronetEngine.build(
            cacheMode: CacheMode.memory, userAgent: userAgent);
        return CronetClient.fromCronetEngineFuture(engine!);
      };
    } else if (Platform.isIOS) {
      clientFactory = () {
        return IOClient(HttpClient());
      };
    }
  }
  if (firebaseAnalyseEnable) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (sentryAnalyseEnable) {
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://dea0fae8a2ec43f788c16534b902b4c4@o1288716.ingest.sentry.io/6506171';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runWithClient(
          () => runApp(ChangeNotifierProvider(
              create: (_) => LoginModel(), child: MyApp())),
          clientFactory),
    );
  } else {
    runApp(ChangeNotifierProvider(create: (_) => LoginModel(), child: MyApp()));
  }
}

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
)
class AppRouter extends $AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();
  @override
  final List<AutoRoute> routes = [
    AutoRoute(page: HomeRoute.page, path: '/'),
    AutoRoute(page: ExamRoute.page),
    AutoRoute(page: PaperRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: ErrorBookRoute.page)
  ];
}

Logger logger = Logger(
    printer: PrettyPrinter(
        methodCount: 5,
        // number of method calls to be displayed
        errorMethodCount: 8,
        // number of method calls if stacktrace is provided
        lineLength: 120 * 10,
        // width of the output
        colors: true,
        // Colorful log messages
        printEmojis: true,
        // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ));

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> defaultSetting = {
      "keepLogin": true,
      "localSessionExist": false,
      "allowTelemetry": false,
      "classCount": 45,
      "useExperimentalDraw": true,
      "defaultShowAllSubject": true,
      "enableWearService": false,
      "useWakeLock": false,
      "checkUpdate": true,
      "checkExams": false,
      "checkExamsInterval": 15,
      "brandColor": "天蓝色",
      "useDynamicColor": true,
      "showMarkingRecords": false,
      "showMoreSubject": false,
      "tryPreviewScore": false,
      "developMode": false,
    };
    defaultSetting.forEach((key, value) {
      if (value.runtimeType == int) {
        if (BaseSingleton.singleton.sharedPreferences.getInt(key) == null) {
          BaseSingleton.singleton.sharedPreferences.setInt(key, value);
        }
      } else if (value.runtimeType == bool) {
        if (BaseSingleton.singleton.sharedPreferences.getBool(key) == null) {
          BaseSingleton.singleton.sharedPreferences.setBool(key, value);
        }
      } else if (value.runtimeType == String) {
        if (BaseSingleton.singleton.sharedPreferences.getString(key) == null) {
          BaseSingleton.singleton.sharedPreferences.setString(key, value);
        }
      }
    });
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
      ColorScheme? lightColorScheme;
      ColorScheme? darkColorScheme;
      Color brandColor = brandColorMap[BaseSingleton.singleton.sharedPreferences
              .getString("brandColor")] ??
          Colors.blue;
      if (lightDynamic != null &&
          darkDynamic != null &&
          BaseSingleton.singleton.sharedPreferences
                  .getBool("useDynamicColor") ==
              true) {
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.light,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.dark,
        );
      }
      return MaterialApp.router(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CH'),
          ],
          locale: const Locale('zh'),
          routeInformationParser: _appRouter.defaultRouteParser(),
          routerDelegate: _appRouter.delegate(
            navigatorObservers: firebaseAnalyseEnable
                ? (() => [
                      FirebaseAnalyticsObserver(
                          analytics: FirebaseAnalytics.instance),
                    ])
                : (() => []),
          ),
          title: '出分啦',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            platform: TargetPlatform.android,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            platform: TargetPlatform.android,
          ),
          themeMode: ThemeMode.system);
    });
  }
}

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key}) : super();
  bool isLoggedIn = false;
  bool prevLoginState = false;
  bool isUpgradeDialogShown = false;
  bool isRequestDialogShown = false;

  void setLoggedIn(bool value) {
    setState(() => isLoggedIn = value);
  }

  Future<void> showUpgradeAlert(BuildContext context) async {
    if (BaseSingleton.singleton.sharedPreferences.getBool('checkUpdate') ==
        false) {
      return;
    }
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final appcast = Appcast();
    await appcast.parseAppcastItemsFromUri(appcastURL);
    AppcastItem? item = appcast.bestItem();
    if (item != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (context.mounted) {
        String? versionString = item.versionString;
        if (versionString != null) {
          if (Version.parse(packageInfo.version) <
              Version.parse(versionString)) {
            logger.i("got update: ${item.fileURL!}");
            if (isUpgradeDialogShown) {
              return;
            }
            isUpgradeDialogShown = true;
            await showDialog<String>(
              context: context,
              builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('现在要更新吗？'),
                content: Text(
                    '获取到最新版本$versionString，然而当前版本是${packageInfo.version}\n\n你需要更新吗？\n\n更新日志：\n${item.itemDescription}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, '但是我拒绝');
                    },
                    child: const Text('但是我拒绝'),
                  ),
                  TextButton(
                    onPressed: () async {
                      int? update = await RUpgrade.upgrade(item.fileURL!,
                          fileName: 'app-release.apk',
                          installType: RUpgradeInstallType.normal);
                      if (update != null) {
                        bool? isSuccess = await RUpgrade.install(update);
                        if (isSuccess != true) {
                          if (mounted) {
                            await showDialog<String>(
                                context: context,
                                builder: (BuildContext dialogContext) =>
                                    AlertDialog(
                                      title: const Text('更新失败'),
                                      content: const Text('新版本更新失败，或许可以再试一次？'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(dialogContext, '好哦');
                                          },
                                          child: const Text('好哦'),
                                        ),
                                      ],
                                    ));
                          }
                        }
                      } else {
                        if (mounted) {
                          await showDialog<String>(
                              context: context,
                              builder: (BuildContext dialogContext) =>
                                  AlertDialog(
                                    title: const Text('更新失败'),
                                    content: const Text('新版本更新失败，或许可以再试一次？'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext, '好哦');
                                        },
                                        child: const Text('好哦'),
                                      ),
                                    ],
                                  ));
                        }
                      }
                      if (mounted) {
                        Navigator.pop(dialogContext, '当然是更新啦');
                      }
                    },
                    child: const Text('当然是更新啦'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  Future<void> showRequestDialog(BuildContext context) async {
    SharedPreferences? shared = BaseSingleton.singleton.sharedPreferences;
    bool? allowed = shared.getBool("allowTelemetry");
    bool? requested = shared.getBool("telemetryRequested");
    logger.d("allowed: $allowed, requested: $requested");
    allowed ??= false;
    requested ??= false;
    if (!allowed && !requested) {
      shared.setBool("telemetryRequested", true);
      logger.d("show request dialog");
      if (isRequestDialogShown) {
        return;
      }
      isRequestDialogShown = true;
      await showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('授权向服务器上传数据'),
                content: const Text(
                    '点击确定\n即为您自愿授权将已获取的分数自动同步到本软件服务器\n同意本软件在境外服务器存储您的成绩信息\n点击取消仍可使用本App基本功能。\n\n选项可在设置中进行修改。'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      SnackBar snackBar = const SnackBar(
                          content: Text('拒绝之后小部分功能可能无法使用哦，在侧边栏设置中可以手动授权！'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      Navigator.pop(dialogContext, '不要');
                    },
                    child: const Text('不要'),
                  ),
                  TextButton(
                    onPressed: () async {
                      shared.setBool("allowTelemetry", true);
                      Navigator.pop(dialogContext, '同意');
                    },
                    child: const Text('同意'),
                  ),
                ],
              ));
    }
  }

  void onNavigatingForum() {
    launchUrl(Uri.parse("https://bjbybbs.com/t/Revealer"));
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() {
      showRequestDialog(context);
      showUpgradeAlert(context);
    });
    return Consumer<LoginModel>(builder: (context, model, child) {
      return Scaffold(
          /*appBar: AppBar(
                title: const Text('出分啦'),
                actions: [
                  IconButton(
                      onPressed: onNavigatingForum,
                      icon: const Icon(Icons.insert_comment))
                ],
              ),*/
          body: Builder(builder: (BuildContext context) {
            if (!(model.isLoggedIn && !prevLoginState)) {
              return const Center(child: LoginWidget());
            } else {
              List<Widget> slivers = [];
              EasyRefreshController controller = EasyRefreshController(
                controlFinishRefresh: true,
                controlFinishLoad: true,
              );
              //slivers.add(const SliverHeader());
              slivers.add(SliverAppBar(
                //title: Text("考试列表"),
                forceElevated: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("考试列表",
                      style: Theme.of(context).textTheme.titleLarge),
                  titlePadding:
                      const EdgeInsetsDirectional.only(start: 56, bottom: 14),
                  expandedTitleScale: 1.8,
                ),
                actions: [
                  IconButton(
                      onPressed: onNavigatingForum,
                      icon: const Icon(Icons.insert_comment))
                ],
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                snap: false,
              ));
              slivers.add(const HeaderLocator.sliver());
              GlobalKey<ExamsState> key = GlobalKey();
              Exams exams = Exams(key: key, controller: controller);
              slivers.add(exams);
              slivers.add(const FooterLocator.sliver());

              return EasyRefresh.builder(
                  controller: controller,
                  header: const ClassicHeader(
                    position: IndicatorPosition.locator,
                    dragText: '下滑刷新 (´ρ`)',
                    armedText: '松开刷新 (´ρ`)',
                    readyText: '获取数据中... (›´ω`‹)',
                    processingText: '获取数据中... (›´ω`‹)',
                    processedText: '成功！(`ヮ´)',
                    noMoreText: '太多啦 TwT',
                    failedText: '失败了 TwT',
                    messageText: '上次更新于 %T',
                  ),
                  footer: const ClassicFooter(
                    infiniteOffset: 0,
                    position: IndicatorPosition.locator,
                    dragText: '下滑刷新 (´ρ`)',
                    armedText: '松开刷新 (´ρ`)',
                    readyText: '获取数据中... (›´ω`‹)',
                    processingText: '获取数据中... (›´ω`‹)',
                    processedText: '成功！(`ヮ´)',
                    noMoreText: '我一点都没有了... TwT',
                    failedText: '失败了 TwT',
                    messageText: '上次更新于 %T',
                  ),
                  onRefresh: (model.isLoggedIn && !prevLoginState)
                      ? () async {
                          await key.currentState?.refresh();
                        }
                      : null,
                  onLoad: (model.isLoggedIn && !prevLoginState)
                      ? () async {
                          await key.currentState?.load();
                        }
                      : null,
                  childBuilder: (BuildContext ct, ScrollPhysics sp) =>
                      CustomScrollView(
                        physics: sp,
                        slivers: slivers,
                      ));
            }
          }),
          drawer: model.isLoggedIn ? const MainDrawer() : null);
    });
  }
}

class BaseSingleton {
  BaseSingleton._();

  static final BaseSingleton _singleton = BaseSingleton._();
  final Dio dio = Dio();
  late final CookieJar cookieJar;
  late final SharedPreferences sharedPreferences;
  late final PackageInfo packageInfo;

  static BaseSingleton get singleton => _singleton;

  init() async {
    // private constructor that creates the singleton instance
    dio.options.responseType = ResponseType.plain;

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          logger.d(response.headers.map.entries.toList());
          List<String>? cookies = response.headers[HttpHeaders.setCookieHeader];
          if (cookies != null) {
            for (String cookie in cookies) {
              if (cookie.contains('SameSite=Nonetlsysapp')) {
                response.headers.removeAll(HttpHeaders.setCookieHeader);
              }
            }
          }
          return handler.next(response);
        },
      ),
    );

    if (kIsWeb) {
      cookieJar = CookieJar();
      //dio.interceptors.add(CookieManager(cookieJar));
    } else {
      getApplicationSupportDirectory().then((value) {
        String dataPath = value.path;
        cookieJar = PersistCookieJar(
            storage: FileStorage(
              dataPath,
            ),
            ignoreExpires: true);
        dio.interceptors.add(CookieManager(cookieJar));
      });
    }

    dio.options.headers = commonHeaders;
    if (!kIsWeb) {
      if (Platform.isAndroid && kReleaseMode) {
        dio.httpClientAdapter = CronetAdapter(null);
      } else if (Platform.isIOS || !kReleaseMode) {
        dio.httpClientAdapter = IOHttpClientAdapter();
      }
    }

    sharedPreferences = await SharedPreferences.getInstance();
    // SharedPreferences.getInstance().then((value) => sharedPreferences = value);
    PackageInfo.fromPlatform().then((value) => packageInfo = value);
  }
}
