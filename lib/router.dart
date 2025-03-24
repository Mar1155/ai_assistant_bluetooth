import 'package:ai_assistent_bluetooth/cubit/chat/chat_cubit.dart';
import 'package:ai_assistent_bluetooth/screens/all_parameters_screen.dart';
import 'package:ai_assistent_bluetooth/screens/auth/login_screen.dart';
import 'package:ai_assistent_bluetooth/screens/chat_device_screen.dart';
import 'package:ai_assistent_bluetooth/screens/dashboard_screen.dart';
import 'package:ai_assistent_bluetooth/services/chat_gpt_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/all-parameters',
      builder: (context, state) => const AllParametersScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final errorCode =
            state.extra != null ? (state.extra as Map)['errorCode'] : '';
        final errorMessage =
            state.extra != null ? (state.extra as Map)['errorMessage'] : '';
        return BlocProvider(
          create:
              (context) => ChatCubit(
                chatGptService: ChatGptService(),
                errorCode: errorCode,
                errorMessage: errorMessage,
              ),
          child: DeviceChatView(
            errorCode: errorCode,
            errorMessage: errorMessage,
          ),
        );
      },
    ),
    GoRoute(
      path: '/user',
      builder: (context, state) => const UserHomeView(),
    ),
  ],
  redirect: (context, state) {
    // final isAuthenticated = AuthService().isLoggedIn();
    // final isGoingToLogin = state.subloc == '/login';

    // if (!isAuthenticated && !isGoingToLogin) {
    //   return '/login';
    // }
    // if (isAuthenticated && isGoingToLogin) {
    //   return '/home';
    // }
    // return null;
  },
);
