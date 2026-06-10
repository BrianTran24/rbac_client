import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_client/rbac.dart';
import 'package:rbac_client/widgets.dart';

import 'core/auth.dart';
import 'core/permissions.dart';
import 'features/access/access_page.dart';
import 'features/contact/data/contact_repository_impl.dart';
import 'features/contact/domain/contact_repository.dart';
import 'features/contact/presentation/contact_cubit.dart';
import 'features/contact/presentation/contact_page.dart';
import 'features/todo/data/todo_repository_impl.dart';
import 'features/todo/domain/todo_repository.dart';
import 'features/todo/presentation/todo_cubit.dart';
import 'features/todo/presentation/todo_page.dart';

void main() {
  final sessionStore = DemoSessionStore();
  final resolver = DemoUserContextResolver();
  final authRepo = MockAuthRepository();
  final authController = DemoAuthController(sessionStore, authRepo);

  // Generated guards – wrap in-memory impl with RBAC checks.
  final todoRepository = TodoRepositoryGuarded(
    InMemoryTodoRepository(),
    sessionStore,
    resolver,
  );
  final contactRepository = ContactRepositoryGuarded(
    InMemoryContactRepository(),
    sessionStore,
    resolver,
  );

  runApp(
    DemoApp(
      authController: authController,
      todoCubit: TodoCubit(todoRepository),
      contactCubit: ContactCubit(contactRepository),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Root app
// ─────────────────────────────────────────────────────────
class DemoApp extends StatelessWidget {
  const DemoApp({
    super.key,
    required this.authController,
    required this.todoCubit,
    required this.contactCubit,
  });

  final DemoAuthController authController;
  final TodoCubit todoCubit;
  final ContactCubit contactCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TodoCubit>.value(value: todoCubit),
        BlocProvider<ContactCubit>.value(value: contactCubit),
      ],
      child: MaterialApp(
        title: 'RBAC Demo',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: RootPage(authController: authController),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Root: switches between Login and Home based on auth state
// ─────────────────────────────────────────────────────────
class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.authController});
  final DemoAuthController authController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authController,
      builder: (context, _) {
        if (authController.isLoading) {
          return const _LoadingScreen();
        }
        if (!authController.isLoggedIn) {
          return LoginPage(authController: authController);
        }
        // Expose the current user's permissions to the subtree so any
        // PermissionGate below can show/hide itself. Rebuilds on login change.
        return PermissionScope(
          permissions: Set<PermissionKey>.from(
            authController.current!.granted,
          ),
          child: HomePage(authController: authController),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Login page – pick a user, backend assigns random permissions
// ─────────────────────────────────────────────────────────
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.authController});
  final DemoAuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'RBAC Demo Login',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Each login returns random permissions.\n'
                  '"admin" always gets all permissions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ...MockAuthRepository.mockUsers.map(
                  (user) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_outline),
                        label: Text('Login as $user'),
                        onPressed: () async {
                          // Capture cubits before the async gap.
                          final todoCubit = context.read<TodoCubit>();
                          final contactCubit = context.read<ContactCubit>();
                          await authController.login(user);
                          await todoCubit.load();
                          await contactCubit.load();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Loading screen shown while mock login is in progress
// ─────────────────────────────────────────────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Logging in…'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Home page with TODO / Contact tabs
// ─────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authController});
  final DemoAuthController authController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final login = widget.authController.current!;
    final tabs = const [TodoPage(), ContactPage()];
    final titles = const ['TODO List', 'Contacts'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${titles[_tabIndex]} · ${login.username}'),
        actions: [
          // Permissions badge → tap to see full list
          TextButton.icon(
            icon: const Icon(Icons.verified_user_outlined),
            label: Text('${login.granted.length}/${DemoPermission.values.length}'),
            onPressed: () => _showPermissionsSheet(context, login),
          ),
          // Capabilities / access screen
          IconButton(
            tooltip: 'Access & capabilities',
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccessPage(
                    username: login.username,
                    grantedPermissions: Set<PermissionKey>.from(login.granted),
                  ),
                ),
              );
            },
          ),
          // Shuffle permissions for same user
          IconButton(
            tooltip: 'Shuffle permissions',
            icon: const Icon(Icons.shuffle),
            onPressed: () async {
              // Capture cubits before the async gap.
              final todoCubit = context.read<TodoCubit>();
              final contactCubit = context.read<ContactCubit>();
              await widget.authController.shufflePermissions();
              await todoCubit.load();
              await contactCubit.load();
            },
          ),
          // Logout
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              widget.authController.logout();
            },
          ),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'TODO'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contact'),
        ],
      ),
    );
  }

  void _showPermissionsSheet(BuildContext context, MockLoginResult login) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissions for "${login.username}"',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...DemoPermission.values.map((p) {
                final granted = login.granted.contains(p);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    granted ? Icons.check_circle : Icons.cancel_outlined,
                    color: granted ? Colors.green : Colors.red,
                  ),
                  title: Text(p.label),
                  subtitle: Text(p.code,
                      style: const TextStyle(fontSize: 11)),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
