import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/blocked_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/official_login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/registration_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/citizen/ai_result_screen.dart';
import '../features/citizen/citizen_profile_screen.dart';
import '../features/citizen/citizen_home_screen.dart';
import '../features/citizen/confirmation_screen.dart';
import '../features/citizen/my_complaints_screen.dart';
import '../features/citizen/citizen_ticket_detail_screen.dart';
import '../features/citizen/report_damage_screen.dart';
import '../features/contractor/contractor_home_screen.dart';
import '../features/contractor/contractor_inprogress_screen.dart';
import '../features/contractor/contractor_issue_screen.dart';
import '../features/contractor/contractor_job_screen.dart';
import '../features/contractor/contractor_profile_screen.dart';
import '../features/contractor/contractor_submitted_screen.dart';
import '../features/handoff/web_handoff_screen.dart';
import '../features/je/je_assign_screen.dart';
import '../features/je/je_checkin_screen.dart';
import '../features/je/je_home_screen.dart';
import '../features/je/je_measure_screen.dart';
import '../features/je/je_profile_screen.dart';
import '../features/je/je_ticket_detail_screen.dart';
import '../features/mukadam/mukadam_home_screen.dart';
import '../features/mukadam/mukadam_inprogress_screen.dart';
import '../features/mukadam/mukadam_issue_screen.dart';
import '../features/mukadam/mukadam_job_screen.dart';
import '../features/mukadam/mukadam_profile_screen.dart';
import '../features/mukadam/mukadam_submitted_screen.dart';
import '../features/shared/execution_proof_screen.dart';
import '../core/widgets/role_shell_scaffold.dart';
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
        if (path == '/login' ||
            path == '/official-login' ||
            path == '/register' ||
            path == '/otp' ||
            path == '/splash') {
          return null;
        }
        return '/login';
      }
      if (path == '/login' || path == '/official-login') {
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
        path: '/official-login',
        builder: (_, __) => const OfficialLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegistrationScreen(),
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
        path: '/citizen/ai-result',
        builder: (_, state) => AiResultScreen(
          args: state.extra! as AiResultArgs,
        ),
      ),
      GoRoute(
        path: '/citizen/confirmation',
        builder: (_, state) => ConfirmationScreen(
          args: state.extra! as ConfirmationArgs,
        ),
      ),
      GoRoute(
        path: '/citizen/tracker',
        builder: (_, state) {
          final id = state.uri.queryParameters['ticketId'];
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Missing ticketId')),
            );
          }
          return CitizenTicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/citizen/my-complaints',
        redirect: (_, __) => '/citizen/track',
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
        redirect: (_, __) => '/citizen/home',
      ),
      GoRoute(
        path: '/je',
        redirect: (_, __) => '/je/tasks',
      ),
      GoRoute(
        path: '/je/home',
        redirect: (_, __) => '/je/tasks',
      ),
      GoRoute(
        path: '/mukadam',
        redirect: (_, __) => '/mukadam/work-orders',
      ),
      GoRoute(
        path: '/mukadam/home',
        redirect: (_, __) => '/mukadam/work-orders',
      ),
      GoRoute(
        path: '/contractor',
        redirect: (_, __) => '/contractor/work-orders',
      ),
      GoRoute(
        path: '/contractor/home',
        redirect: (_, __) => '/contractor/work-orders',
      ),
      ShellRoute(
        builder: (context, state, child) => RoleShellScaffold(
          activeLocationPrefix: '/citizen',
          items: const [
            ShellNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              location: '/citizen/home',
            ),
            ShellNavItem(
              label: 'Report',
              icon: Icons.add_circle_outline_rounded,
              activeIcon: Icons.add_circle_rounded,
              location: '/citizen/report',
            ),
            ShellNavItem(
              label: 'Track',
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              location: '/citizen/track',
            ),
            ShellNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              location: '/citizen/profile',
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/citizen/home',
            builder: (_, __) => const CitizenHomeScreen(),
          ),
          GoRoute(
            path: '/citizen/report',
            builder: (_, __) => const ReportDamageScreen(),
          ),
          GoRoute(
            path: '/citizen/track',
            builder: (_, __) => const MyComplaintsScreen(),
          ),
          GoRoute(
            path: '/citizen/profile',
            builder: (_, __) => const CitizenProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/citizen/tickets/:ticketId',
        builder: (_, state) => CitizenTicketDetailScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => RoleShellScaffold(
          activeLocationPrefix: '/je',
          items: const [
            ShellNavItem(
              label: 'Tasks',
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              location: '/je/tasks',
            ),
            ShellNavItem(
              label: 'Map',
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              location: '/je/map',
            ),
            ShellNavItem(
              label: 'Routes',
              icon: Icons.route_outlined,
              activeIcon: Icons.route_rounded,
              location: '/je/routes',
            ),
            ShellNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              location: '/je/profile',
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/je/tasks',
            builder: (_, __) => const JeHomeScreen(),
          ),
          GoRoute(
            path: '/je/map',
            builder: (_, __) => const JeHomeScreen(initialMapOnly: true),
          ),
          GoRoute(
            path: '/je/routes',
            builder: (_, __) => const JeHomeScreen(initialRoutesOnly: true),
          ),
          GoRoute(
            path: '/je/profile',
            builder: (_, __) => const JeProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/je/tickets/:ticketId',
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
      GoRoute(
        path: '/je/ticket/:ticketId',
        redirect: (_, state) => '/je/tickets/${state.pathParameters['ticketId']!}',
      ),
      GoRoute(
        path: '/je/checkin/:ticketId',
        redirect: (_, state) =>
            '/je/tickets/${state.pathParameters['ticketId']!}/checkin',
      ),
      GoRoute(
        path: '/je/measure/:ticketId',
        redirect: (_, state) =>
            '/je/tickets/${state.pathParameters['ticketId']!}/measure',
      ),
      GoRoute(
        path: '/je/assign/:ticketId',
        redirect: (_, state) =>
            '/je/tickets/${state.pathParameters['ticketId']!}/assign',
      ),
      ShellRoute(
        builder: (context, state, child) => RoleShellScaffold(
          activeLocationPrefix: '/mukadam',
          items: const [
            ShellNavItem(
              label: 'Work',
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              location: '/mukadam/work-orders',
            ),
            ShellNavItem(
              label: 'Tasks',
              icon: Icons.task_alt_outlined,
              activeIcon: Icons.task_alt_rounded,
              location: '/mukadam/tasks',
            ),
            ShellNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              location: '/mukadam/profile',
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/mukadam/work-orders',
            builder: (_, __) => const MukadamHomeScreen(),
          ),
          GoRoute(
            path: '/mukadam/tasks',
            builder: (_, __) => const MukadamHomeScreen(initialTasksOnly: true),
          ),
          GoRoute(
            path: '/mukadam/profile',
            builder: (_, __) => const MukadamProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/mukadam/detail/:ticketId',
        redirect: (_, state) => '/mukadam/jobs/${state.pathParameters['ticketId']!}',
      ),
      GoRoute(
        path: '/mukadam/jobs/:ticketId',
        builder: (_, state) => MukadamJobScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/mukadam/inprogress/:ticketId',
        builder: (_, state) => MukadamInProgressScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/mukadam/camera/:ticketId',
        builder: (_, state) => ExecutionProofScreen(
          args: ExecutionProofArgs(
            ticketId: state.pathParameters['ticketId']!,
            roleLabel: 'Mukadam',
          ),
        ),
      ),
      GoRoute(
        path: '/mukadam/issue/:ticketId',
        builder: (_, state) => MukadamIssueScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/mukadam/submitted',
        builder: (_, __) => const MukadamSubmittedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => RoleShellScaffold(
          activeLocationPrefix: '/contractor',
          items: const [
            ShellNavItem(
              label: 'Orders',
              icon: Icons.construction_outlined,
              activeIcon: Icons.construction_rounded,
              location: '/contractor/work-orders',
            ),
            ShellNavItem(
              label: 'Bills',
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              location: '/contractor/bills',
            ),
            ShellNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              location: '/contractor/profile',
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/contractor/work-orders',
            builder: (_, __) => const ContractorHomeScreen(),
          ),
          GoRoute(
            path: '/contractor/bills',
            builder: (_, __) => const ContractorHomeScreen(initialBillsOnly: true),
          ),
          GoRoute(
            path: '/contractor/profile',
            builder: (_, __) => const ContractorProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/contractor/detail/:ticketId',
        redirect: (_, state) =>
            '/contractor/jobs/${state.pathParameters['ticketId']!}',
      ),
      GoRoute(
        path: '/contractor/jobs/:ticketId',
        builder: (_, state) => ContractorJobScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/contractor/inprogress/:ticketId',
        builder: (_, state) => ContractorInProgressScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/contractor/camera/:ticketId',
        builder: (_, state) => ExecutionProofScreen(
          args: ExecutionProofArgs(
            ticketId: state.pathParameters['ticketId']!,
            roleLabel: 'Contractor',
          ),
        ),
      ),
      GoRoute(
        path: '/contractor/issue/:ticketId',
        builder: (_, state) => ContractorIssueScreen(
          ticketId: state.pathParameters['ticketId']!,
        ),
      ),
      GoRoute(
        path: '/contractor/submitted',
        builder: (_, state) => ContractorSubmittedScreen(
          data: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
});
