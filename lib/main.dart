import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' hide Response;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:prescore_flutter/service.dart';
import 'package:prescore_flutter/util/cronet_adapter.dart';
import 'package:prescore_flutter/main.gr.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'constants.dart';
import 'model/login_model.dart';

@pragma('vm:entry-point')
serviceEntry() async {
  if (sentryAnalyseEnable) {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://dea0fae8a2ec43f788c16534b902b4c4@o1288716.ingest.sentry.io/6506171';
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
      late CronetEngine engine;
      clientFactory = () {
        engine = CronetEngine.build(
            cacheMode: CacheMode.memory,
            enableBrotli: true,
            enableHttp2: true,
            enableQuic: true,
            userAgent: userAgent);
        return CronetClient.fromCronetEngine(engine);
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
      "secondClassesCount": "{}",
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
      "telemetryBaseUrl": "https://matrix.npcstation.com/api",
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
            fontFamily: GoogleFonts.poppins().fontFamily
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            platform: TargetPlatform.android,
            fontFamily: GoogleFonts.poppins().fontFamily
          ),
          themeMode: ThemeMode.system);
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
        onRequest: (options, handler) { //TODO
          options.headers["user-agent"] = commonHeaders["user-agent"];
          return handler.next(options);
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
