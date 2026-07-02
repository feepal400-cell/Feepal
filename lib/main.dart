import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Added dotenv import
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_service.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'super_admin_dashboard.dart';
import 'subscription_screen.dart';
import 'parent_alerts_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pending_subscription_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_screen.dart';
import 'parent_admin_chat_screen.dart';
import 'alerts_screen.dart';

void main() async {
  // Ensure Flutter bindings are ready for async initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Set System UI Overlay Style (Navigation Bar and Status Bar)
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize .env variables before app runs
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint("✅ FeePal Env: Loaded Successfully");
  } catch (e) {
    print(
      "❌ FeePal Env: Initialization Error (Check if .env exists in assets): $e",
    );
  }

  // Initialize Firebase with the options from your CLI setup
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ FeePal Firebase: Connected Successfully");
    debugPrint(
      "📍 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}",
    );
    debugPrint("📍 API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey}");

    // Initialize FCM Notifications
    await NotificationService.initialize();

    // 🕒 Global Server Time Sync (Secure Reference)
    await FirebaseService().initializeTimeSync();
  } catch (e) {
    print("❌ FeePal Firebase: Initialization Error: $e");
  }

  runApp(const FeePalApp());
}

class FeePalApp extends StatelessWidget {
  const FeePalApp({super.key});

  // Global Navigator Key for context-less navigation (FCM Routing)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FeePal',
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2168F8),
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2168F8).withValues(alpha: 0.1),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/Feepal Logo.png')],
        ),
      ),
    );
  }
}
// --- AUTO LOGIN LOGIC ---

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitializing = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkPersistence();
  }

  Future<void> _checkPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? role = prefs.getString('userRole');

      // 1. Check for Parent Session (SharedPreferences)
      if (isLoggedIn && role == 'parent') {
        final String? parentEmail = prefs.getString('parentEmail');
        if (parentEmail != null) {
          // Verify that this is NOT an admin using Parent role
          final User? authUser = FirebaseAuth.instance.currentUser;
          if (authUser != null && !authUser.isAnonymous) {
            // Found a real Auth session while in Parent mode - Conflict!
            await FirebaseAuth.instance.signOut();
          }

          final error = await _firebaseService.restoreParentSession(
            parentEmail,
          );
          if (error == null) {
            _firebaseService.updateParentFcmToken(parentEmail);
            setState(() {
              _initialScreen = const ParentDashboardScreen();
              _isInitializing = false;
            });
            return;
          } else {
            // Invalid parent session, clear it
            await prefs.clear();
          }
        }
      }

      // 2. Fallback to Admin Session (FirebaseAuth)
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final adminData = await _firebaseService.getAdminData(user.uid);
        if (adminData != null) {
          String role = adminData['role'] ?? 'admin';
          String? subStatus = adminData['subscriptionStatus'];
          String? accountStatus =
              adminData['accountStatus'] ?? adminData['status'];

          // --- HIGH PRIORITY SUSPENSION CHECK ---
          bool isDisabled =
              (accountStatus == 'suspended' || accountStatus == 'disabled');
          bool isExpired =
              role != 'super_admin' &&
              _firebaseService.isSubscriptionExpired(adminData);

          if (isDisabled || isExpired) {
            setState(() {
              _initialScreen = SubscriptionScreen(
                adminData: adminData,
                isLockedMode: true,
              );
              _isInitializing = false;
            });
            return;
          }

          setState(() {
            bool isEmailVerified = adminData['isEmailVerified'] ?? false;

            if (role == 'super_admin') {
              _initialScreen = const SuperAdminDashboard();
            } else if (!isEmailVerified) {
              // Forced OTP Verification Persistence
              _initialScreen = OTPScreen(
                email: adminData['email'] ?? '',
                uid: user.uid,
                adminData: adminData,
              );
            } else if (subStatus == 'approved' || subStatus == 'active') {
              _initialScreen = const AdminDashboardScreen();
            } else if (subStatus == 'pending' ||
                subStatus == 'pending_subscription') {
              _initialScreen = PendingSubscriptionScreen(adminData: adminData);
            } else {
              _initialScreen = SubscriptionScreen(adminData: adminData);
            }
            _isInitializing = false;
          });
          return;
        } else {
          // User is authenticated but no Admin doc found - Role Mismatch!
          await FirebaseAuth.instance.signOut();
        }
      }

      // 3. No Valid Session Found - Clean Slate
      await prefs.clear();
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }

      setState(() {
        _initialScreen = const WelcomeScreen();
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint("❌ AuthWrapper Error: $e");
      setState(() {
        _initialScreen = const WelcomeScreen();
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2168F8)),
        ),
      );
    }
    return _initialScreen ?? const WelcomeScreen();
  }
}

// --- NOTIFICATION SERVICE ---

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    try {
      // 1. Request Permission (Android 13+ & iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM: User granted permission');
      }

      // 2. Setup Android Notification Channel for Foreground
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // 3. Initialize Local Notifications
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationTap(null);
        },
      );

      // 4. Get Token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('\n🚀 FCM_TOKEN: $token\n');
      }

      // 5. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('📩 [FCM Foreground] Message Received!');

        // --- NOTIFICATION GUARD ---
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.isAnonymous) {
          // It's an Admin, check their preference
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();
          final bool isEnabled =
              adminDoc.data()?['isNotificationsEnabled'] ?? true;
          if (!isEnabled) {
            debugPrint(
              "🔕 FCM: Admin has disabled notifications. Suppressing...",
            );
            return;
          }
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android.smallIcon,
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 6. Handle Background Message click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 7. Check for Initial Message
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('🚨 FCM Initialization Error: $e');
    }
  }

  // Routing Logic: The Traffic Cop
  static void _handleNotificationTap(RemoteMessage? message) {
    final route = message?.data['route'];
    final type = message?.data['type'];
    debugPrint("🎯 FCM Tap: Routing to $route with type $type");

    Widget destination;

    // 1. Role-aware routing for 'alerts_screen'
    if (route == 'alerts_screen') {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        destination = const AlertsScreen();
      } else {
        destination = const ParentAlertsScreen();
      }
    } else if (route == 'parent_chat') {
      final parentId = message?.data['parentId'] ?? '';
      final adminId = message?.data['adminId'] ?? '';
      final parentName = message?.data['parentName'] ?? 'Parent';

      final User? user = FirebaseAuth.instance.currentUser;
      final bool isAdmin = user != null && !user.isAnonymous;

      if (isAdmin && parentId.isNotEmpty) {
        destination = ParentAdminChatScreen(
          parentId: parentId,
          adminId: user.uid,
          parentName: parentName,
          role: 'admin',
        );
      } else if (!isAdmin && parentId.isNotEmpty && adminId.isNotEmpty) {
        destination = ParentAdminChatScreen(
          parentId: parentId,
          adminId: adminId,
          parentName: parentName,
          role: 'parent',
        );
      } else {
        destination = isAdmin
            ? const AlertsScreen()
            : const ParentAlertsScreen(); // Fallback
      }
    } else if (type == 'resubscription_request') {
      destination = const SuperAdminDashboard();
    } else {
      // Default fallback
      destination = const ParentAlertsScreen();
    }

    FeePalApp.navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}
