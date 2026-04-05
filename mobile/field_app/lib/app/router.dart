import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/blocked_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/citizen/citizen_home_screen.dart';
import '../features/citizen/citizen_ticket_detail_screen.dart';
import '../features/citizen/report_damage_screen.dart';
import '../features/contractor/contractor_home_screen.dart';
import '../features/contractor/contractor_job_screen.dart';
import '../features/handoff/web_handoff_screen.dart';
import '../features/je/je_assign_screen.dart';
import '../features/je/je_checkin_screen.dart';
import '../features/je/je_home_screen.dart';
import '../features/je/je_measure_screen.dart';
import '../features/je/je_ticket_detail_screen.dart';
import '../features/mukadam/mukadam_home_screen.dart';
import '../features/mukadam/mukadam_job_screen.dart';
import '../features/shared/execution_proof_screen.dart';
import 'router_refresh.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefresh(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final path = state.uri.path;
      if (session == null) {
        if (path == '/login' || path == '/otp' || path == '/splash') {
          return null;
        }
        return '/login';
      }
      if (path == '/login') {
        return '/splash';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String?;
          if (phone == null || phone.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Missing phone — go back to login.')),
            );
          }
          return OtpScreen(phoneE164: phone);
        },
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) =>
            BlockedScreen(message: state.extra as String?),
      ),
      GoRoute(
        path: '/handoff',
        builder: (_, __) => const WebHandoffScreen(),
      ),
      GoRoute(
        path: '/citizen',
        builder: (_, __) => const CitizenHomeScreen(),
        routes: [
          GoRoute(
            path: 'report',
            builder: (_, __) => const ReportDamageScreen(),
          ),
          GoRoute(
            path: 'tickets/:ticketId',
            builder: (_, state) => CitizenTicketDetailScreen(
              ticketId: state.pathParameters['ticketId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/je',
        builder: (_, __) => const JeHomeScreen(),
        routes: [
          GoRoute(
            path: 'tickets/:ticketId',
            builder: (_, state) => JeTicketDetailScreen(
              ticketId: state.pathParameters['ticketId']!,
            ),
            routes: [
              GoRoute(
                path: 'checkin',
                builder: (_, state) => JeCheckInScreen(
                  ticketId: state.pathParameters['ticketId']!,
                ),
              ),
              GoRoute(
                path: 'measure',
                builder: (_, state) => JeMeasureScreen(
                  ticketId: state.pathParameters['ticketId']!,
                ),
              ),
              GoRoute(
                path: 'assign',
                builder: (_, state) => JeAssignScreen(
                  ticketId: state.pathParameters['ticketId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/mukadam',
        builder: (_, __) => const MukadamHomeScreen(),
        routes: [
          GoRoute(
            path: 'jobs/:ticketId',
            builder: (_, state) => MukadamJobScreen(
              ticketId: state.pathParameters['ticketId']!,
            ),
            routes: [
              GoRoute(
                path: 'proof',
                builder: (_, state) => ExecutionProofScreen(
                  args: ExecutionProofArgs(
                    ticketId: state.pathParameters['ticketId']!,
                    roleLabel: 'Mukadam',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/contractor',
        builder: (_, __) => const ContractorHomeScreen(),
        routes: [
          GoRoute(
            path: 'jobs/:ticketId',
            builder: (_, state) => ContractorJobScreen(
              ticketId: state.pathParameters['ticketId']!,
            ),
            routes: [
              GoRoute(
                path: 'proof',
                builder: (_, state) => ExecutionProofScreen(
                  args: ExecutionProofArgs(
                    ticketId: state.pathParameters['ticketId']!,
                    roleLabel: 'Contractor',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
