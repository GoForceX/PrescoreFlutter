import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
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
import 'package:version/version.dart';
import 'package:r_upgrade/r_upgrade.dart';

import 'model/login_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp.router(
        routeInformationParser: _appRouter.defaultRouteParser(),
        routerDelegate: _appRouter.delegate(),
        title: '出分啦',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
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

  void setLoggedIn(bool value) {
    setState(() => {isLoggedIn = value});
  }

  Future<void> showUpgradeAlert() async {
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final appcast = Appcast();
    await appcast.parseAppcastItemsFromUri(appcastURL);
    AppcastItem? item = appcast.bestItem();
    if (item != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (Version.parse(packageInfo.version) <
          Version.parse(item.versionString)) {
        logger.i("got update: ${item.fileURL!}");
        showDialog<String>(
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

  @override
  Widget build(BuildContext context) {
    showUpgradeAlert();

    return ChangeNotifierProvider(
        create: (_) => LoginModel(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('出分啦'),
          ),
          body: Consumer<LoginModel>(
            builder: (context, model, child) {
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
            },
          ),
          drawer: const MainDrawer(),
        ));
  }
}

class BaseSingleton {
  static final BaseSingleton _singleton = BaseSingleton._internal();
  final Dio dio = Dio();
  late final PersistCookieJar cookieJar;
  late final SharedPreferences sharedPreferences;
  late final PackageInfo packageInfo;

  factory BaseSingleton() => _singleton;

  BaseSingleton._internal() {
    // private constructor that creates the singleton instance
    dio.options.responseType = ResponseType.plain;
    dio.options.headers["User-Agent"] =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41";
    getTemporaryDirectory().then((value) {
      String dataPath = value.path;
      cookieJar = PersistCookieJar(
          storage: FileStorage(
            dataPath,
          ),
          ignoreExpires: true);
      dio.interceptors.add(CookieManager(cookieJar));
    });

    SharedPreferences.getInstance().then((value) => sharedPreferences = value);
    PackageInfo.fromPlatform().then((value) => packageInfo = value);
  }
}