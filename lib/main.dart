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
import 'package:flutter_bugly/flutter_bugly.dart';

import 'model/login_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /*
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
  FlutterBugly.init(
    androidAppId: "e841898baf",
  );
   */
  FlutterBugly.postCatchedException(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(MyApp());
    FlutterBugly.init(
      androidAppId: "e841898baf",
    );
  });
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
    FlutterBugly.checkUpgrade();
    FlutterBugly.onCheckUpgrade.listen((_upgradeInfo) {
      logger.i("${_upgradeInfo.newFeature}\n${_upgradeInfo.apkUrl}");
    });
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
                slivers: slivers,
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
