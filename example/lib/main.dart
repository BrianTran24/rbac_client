import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth.dart';
import 'core/permissions.dart';
import 'features/contact/data/contact_repository_impl.dart';
import 'features/contact/presentation/contact_cubit.dart';
import 'features/contact/presentation/contact_page.dart';
import 'features/todo/data/todo_repository_impl.dart';
import 'features/todo/presentation/todo_cubit.dart';
import 'features/todo/presentation/todo_page.dart';

void main() {
  final sessionStore = DemoSessionStore();
  final resolver = DemoUserContextResolver();
  final authController = DemoAuthController(sessionStore);

  final todoRepository = GuardedTodoRepository(
    InMemoryTodoRepository(),
    sessionStore,
    resolver,
  );

  final contactRepository = GuardedContactRepository(
    InMemoryContactRepository(),
    sessionStore,
    resolver,
  );

  runApp(
    DemoApp(
      authController: authController,
      todoCubit: TodoCubit(todoRepository)..load(),
      contactCubit: ContactCubit(contactRepository)..load(),
    ),
  );
}

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
        title: 'RBAC TODO + Contact Demo',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: HomePage(authController: authController),
      ),
    );
  }
}

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
    final pages = const [TodoPage(), ContactPage()];
    final titles = const ['TODO List', 'Contacts'];

    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${titles[_tabIndex]} - ${widget.authController.role.name}',
            ),
            actions: [
              DropdownButtonHideUnderline(
                child: DropdownButton<DemoRole>(
                  value: widget.authController.role,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (role) async {
                    if (role == null) return;
                    widget.authController.setRole(role);
                    await context.read<TodoCubit>().load();
                    await context.read<ContactCubit>().load();
                  },
                  items: DemoRole.values
                      .map(
                        (role) => DropdownMenuItem<DemoRole>(
                          value: role,
                          child: Text(role.name),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: pages[_tabIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _tabIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.checklist), label: 'TODO'),
              NavigationDestination(
                icon: Icon(Icons.contacts),
                label: 'Contact',
              ),
            ],
          ),
        );
      },
    );
  }
}
