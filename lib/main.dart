import 'package:cookie_jar/cookie_jar.dart';
import 'package:cronet/cronet.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prescore_flutter/widget/drawer.dart';
import 'package:prescore_flutter/widget/exam/exam.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:auto_route/annotations.dart';
import 'package:prescore_flutter/widget/main/exams.dart';
import 'package:prescore_flutter/widget/main/main_header.dart';
import 'package:prescore_flutter/widget/paper/paper_page.dart';
import 'package:prescore_flutter/widget/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:r_upgrade/r_upgrade.dart';

import 'constants.dart';
import 'model/login_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaseSingleton.singleton.init();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://dea0fae8a2ec43f788c16534b902b4c4@o1288716.ingest.sentry.io/6506171';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(MyApp()),
  );
}

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(page: ExamPage),
    AutoRoute(page: PaperPage),
    AutoRoute(page: SettingsPage),
  ],
)
class $AppRouter {}

Logger logger = Logger(
    printer: PrettyPrinter(
        methodCount: 5, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
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
        routerDelegate: _appRouter.delegate(),
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
    setState(() => {isLoggedIn = value});
  }

  Future<void> showUpgradeAlert(BuildContext context) async {
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final appcast = Appcast();
    await appcast.parseAppcastItemsFromUri(appcastURL);
    AppcastItem? item = appcast.bestItem();
    if (item != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (Version.parse(packageInfo.version) <
          Version.parse(item.versionString)) {
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
                '获取到最新版本${item.versionString}，然而当前版本是${packageInfo.version}\n\n你需要更新吗？\n\n更新日志：\n${item.itemDescription}'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, '但是我拒绝');
                },
                child: const Text('但是我拒绝'),
              ),
              TextButton(
                onPressed: () async {
                  RUpgrade.upgrade(item.fileURL!,
                      fileName: 'app-release.apk', isAutoRequestInstall: true);
                  Navigator.pop(dialogContext, '当然是更新啦');
                },
                child: const Text('当然是更新啦'),
              ),
            ],
          ),
        );
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
                        content: const Text('拒绝之后小部分功能可能无法使用哦，在侧边栏设置中可以手动授权！'),
                        backgroundColor: Colors.grey.withOpacity(0.5)
                      );
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

                  slivers.add(const SliverHeader());

                  if (model.isLoggedIn && !prevLoginState) {
                    slivers.add(const Exams());
                  } else {
                    slivers.add(const SliverFillRemaining(
                      hasScrollBody: false,
                    ));
                  }

                  return CustomScrollView(
                    shrinkWrap: true,
                    slivers: slivers,
                  );
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
  final cronetClient = HttpClient(userAgent: userAgent);

  static BaseSingleton get singleton => _singleton;

  init() async {
    // private constructor that creates the singleton instance
    dio.options.responseType = ResponseType.plain;
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

    SharedPreferences.getInstance().then((value) => sharedPreferences = value);
    PackageInfo.fromPlatform().then((value) => packageInfo = value);
  }
}
