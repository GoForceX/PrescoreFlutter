import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prescore_flutter/widget/exam/exam.dart';
import 'package:prescore_flutter/main.gr.dart';
import 'package:auto_route/annotations.dart';
import 'package:prescore_flutter/widget/main/exams.dart';
import 'package:prescore_flutter/widget/main/main_header.dart';
import 'package:prescore_flutter/widget/paper/paper_page.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    String appcastURL = 'https://matrix.bjbybbs.com/appcast.xml';
    final cfg = AppcastConfiguration(url: appcastURL, supportedOS: ['android', 'windows']);

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

              return UpgradeAlert(
                upgrader: Upgrader(
                    appcastConfig: cfg,
                    countryCode: 'zh',
                    durationUntilAlertAgain: Duration.zero,
                    messages: ChineseMessages(),
                    onUpdate: () {
                      launchUrl(
                          Uri.parse("https://matrix.bjbybbs.com/docs/landing"),
                          mode: LaunchMode.externalApplication);
                      return false;
                    }),
                child: CustomScrollView(
                  slivers: slivers,
                ),
              );
            },
          ),
          // drawer: const MainDrawer(),
        ));
  }
}

class BaseDio {
  static final BaseDio _singleton = BaseDio._internal();
  final Dio dio = Dio();
  late final PersistCookieJar cookieJar;

  factory BaseDio() => _singleton;

  BaseDio._internal() {
    // private constructor that creates the singleton instance
    dio.options.responseType = ResponseType.plain;
    dio.options.headers["User-Agent"] =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41";
    getApplicationDocumentsDirectory().then((value) {
      String dataPath = value.path;
      cookieJar = PersistCookieJar(
          storage: FileStorage(
            dataPath,
          ),
          ignoreExpires: true);
      dio.interceptors.add(CookieManager(cookieJar));
    });
  }
}

class ChineseMessages extends UpgraderMessages {
  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return '应用程序 {{appName}} 有新的版本，最新版本是{{currentAppStoreVersion}}，当前版本是{{currentInstalledVersion}}';
      case UpgraderMessage.buttonTitleIgnore:
        return '忽略';
      case UpgraderMessage.buttonTitleLater:
        return '一会再说';
      case UpgraderMessage.buttonTitleUpdate:
        return '现在更新';
      case UpgraderMessage.prompt:
        return '要更新吗？';
      case UpgraderMessage.releaseNotes:
        return '更新日志';
      case UpgraderMessage.title:
        return '现在要更新吗？';
    }
    // Messages that are not provided above can still use the default values.
  }
}
