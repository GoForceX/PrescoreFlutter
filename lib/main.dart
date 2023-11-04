import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cronet_http_embedded/cronet_http.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prescore_flutter/util/cronet_adapter.dart';
import 'package:prescore_flutter/util/user_util.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:auto_route/auto_route.dart';
import 'package:prescore_flutter/widget/main/exams.dart';
import 'package:prescore_flutter/widget/main/main_header.dart';
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

import 'constants.dart';
import 'model/login_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseSingleton.singleton.init();
  var clientFactory = Client.new; // Constructs the default client.
  if (Platform.isAndroid) {
    Future<CronetEngine>? engine;
    clientFactory = () {
      engine ??= CronetEngine.build(
          cacheMode: CacheMode.memory, userAgent: userAgent);
      return CronetClient.fromCronetEngineFuture(engine!);
    };
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://dea0fae8a2ec43f788c16534b902b4c4@o1288716.ingest.sentry.io/6506171';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runWithClient(() => runApp(MyApp()), clientFactory),
  );
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
    AutoRoute(page: SkillRoute.page),
  ];
}

Logger logger = Logger(
    printer: PrettyPrinter(
        methodCount: 5,
        // number of method calls to be displayed
        errorMethodCount: 8,
        // number of method calls if stacktrace is provided
        lineLength: 120,
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
    if (BaseSingleton.singleton.sharedPreferences.getInt("classCount") ==
        null) {
      BaseSingleton.singleton.sharedPreferences.setInt("classCount", 45);
    }

    if (BaseSingleton.singleton.sharedPreferences
            .getBool("useExperimentalDraw") ==
        null) {
      BaseSingleton.singleton.sharedPreferences
          .setBool("useExperimentalDraw", true);
    }

    return MaterialApp.router(
        routeInformationParser: _appRouter.defaultRouteParser(),
        routerDelegate: _appRouter.delegate(
          navigatorObservers: () => [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
        ),
        title: '出分啦',
        theme: ThemeData(
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlueAccent, brightness: Brightness.dark),
            useMaterial3: true),
        themeMode: ThemeMode.system);
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
                    '获取到最新版本${versionString}，然而当前版本是${packageInfo.version}\n\n你需要更新吗？\n\n更新日志：\n${item.itemDescription}'),
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
                          fileName: 'app-release.apk', installType: RUpgradeInstallType.normal);
                      if (update != null) {
                        bool? isSuccess= await RUpgrade.install(update);
                        if (isSuccess != true) {
                          if (mounted) {
                            await showDialog<String>(
                                context: context,
                                builder: (BuildContext dialogContext) => AlertDialog(
                                  title: const Text('更新失败'),
                                  content: const Text(
                                      '新版本更新失败，或许可以再试一次？'),
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
                              builder: (BuildContext dialogContext) => AlertDialog(
                                title: const Text('更新失败'),
                                content: const Text(
                                    '新版本更新失败，或许可以再试一次？'),
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
                      SnackBar snackBar = SnackBar(
                          content:
                              const Text('拒绝之后小部分功能可能无法使用哦，在侧边栏设置中可以手动授权！'),
                          backgroundColor: Colors.grey.withOpacity(0.5));
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
    return ChangeNotifierProvider(
        create: (_) => LoginModel(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('出分啦'),
            actions: [
              IconButton(
                  onPressed: onNavigatingForum,
                  icon: const Icon(Icons.insert_comment))
            ],
          ),
          body: FutureBuilder(
              future: Future.delayed(Duration.zero, () {
                showRequestDialog(context);
                showUpgradeAlert(context);
              }),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                return Consumer<LoginModel>(builder: (context, model, child) {
                  List<Widget> slivers = [];

                  EasyRefreshController controller = EasyRefreshController(
                    controlFinishRefresh: true,
                    controlFinishLoad: true,
                  );

                  slivers.add(const SliverHeader());

                  slivers.add(const HeaderLocator.sliver());

                  GlobalKey<ExamsState> key = GlobalKey();
                  Exams exams = Exams(key: key, controller: controller);

                  if (model.isLoggedIn && !prevLoginState) {
                    slivers.add(exams);
                  } else {
                    slivers.add(const SliverFillRemaining(
                      hasScrollBody: false,
                    ));
                  }

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
                            shrinkWrap: true,
                            slivers: slivers,
                          ));
                });
              }),
          drawer: const MainDrawer(),
        ));
  }
}

class BaseSingleton {
  BaseSingleton._();

  static final BaseSingleton _singleton = BaseSingleton._();
  final Dio dio = Dio();
  late final CookieJar cookieJar;
  late final SharedPreferences sharedPreferences;
  late final PackageInfo packageInfo;
  User? currentUser;

  static BaseSingleton get singleton => _singleton;

  init() async {
    // private constructor that creates the singleton instance
    dio.options.responseType = ResponseType.plain;

    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          logger.d(response.headers.map.entries.toList());
          String? c = response.headers.value('set-cookie');
          if (c != null) {
            if (c.contains('SameSite=Nonetlsysapp')) {
              response.headers.remove('set-cookie', c);
            }
          }
          return handler.next(response);
        },
      ),
    );

    if (kIsWeb) {
      cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));
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

    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      dio.httpClientAdapter = CronetAdapter(null);
    }

    sharedPreferences = await SharedPreferences.getInstance();
    // SharedPreferences.getInstance().then((value) => sharedPreferences = value);
    PackageInfo.fromPlatform().then((value) => packageInfo = value);
  }
}
