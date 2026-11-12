import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foodstore/bloc/auth/auth_bloc.dart';
import 'package:flutter_foodstore/bloc/order/order_cubit.dart';
import 'package:flutter_foodstore/bloc/profile/profile_bloc.dart';
import 'package:flutter_foodstore/bloc/review_product/review_product_cubit.dart';
import 'package:flutter_foodstore/page/auth/login_page.dart';
import 'package:flutter_foodstore/page/auth/register_page.dart';
import 'package:flutter_foodstore/page/dashboard/cart_page.dart';
import 'package:flutter_foodstore/page/dashboard/dashboard_page.dart';
import 'package:flutter_foodstore/page/dashboard/home_page.dart';
import 'package:flutter_foodstore/page/dashboard/order_page.dart';
import 'package:flutter_foodstore/page/dashboard/profile_page.dart';
import 'package:flutter_foodstore/page/midtrans/midtrans_payment_page.dart';
import 'package:flutter_foodstore/page/order/order_detail_page.dart';
import 'package:flutter_foodstore/resource/remote/order_remote_resource.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthBloc authBloc;
  final OrderRemoteResource orderRemoteResource;

  AppRouter({required this.authBloc, required this.orderRemoteResource});

  late final GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: '/dashboard/home',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is Authenticated;

      final protectedRoutes = [
        '/dashboard/order',
        '/dashboard/profile',
        '/dashboard/cart',
        '/order',
        '/checkout',
      ];

      final isProtected = protectedRoutes
          .any((route) => state.matchedLocation.startsWith(route));

      if (!isLoggedIn && isProtected) return '/login';

      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/dashboard/home';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (_, __, child) => DashboardPage(child: child),
        routes: [
          GoRoute(
            path: '/dashboard/home',
            builder: (_, __) {
              return HomePage();
            },
          ),
          GoRoute(
            path: '/dashboard/order',
            builder: (context, state) {
              context.read<OrderCubit>().fetchOrders(isRefresh: true);
              return OrderPage();
            },
          ),
          GoRoute(
            path: '/dashboard/cart',
            builder: (context, state) {
              return CartPage();
            },
          ),
          GoRoute(
            path: '/dashboard/profile',
            builder: (context, state) {
              context.read<ProfileBloc>().add(const ProfileEvent.loadProfile());
              return ProfilePage();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => RegisterPage(),
      ),
      GoRoute(
        path: '/orderDetail/:snapToken',
        builder: (context, state) {
          final snapToken = state.pathParameters['snapToken'] ?? '';
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    OrderCubit(orderRemoteResource)..detailOrder(snapToken),
              ),
              BlocProvider(
                create: (context) => ReviewProductCubit(
                  orderRemoteResource,
                ),
              ),
            ],
            child: const OrderDetailPage(),
          );
        },
      ),
      GoRoute(
        path: '/midtransPayment/:snapToken',
        builder: (context, state) {
          return MidtransPaymentPage(
            snapToken: state.pathParameters['snapToken'] ?? '',
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}
