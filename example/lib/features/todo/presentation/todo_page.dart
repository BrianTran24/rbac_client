import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'todo_cubit.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoCubit, TodoState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'New TODO',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<TodoCubit>().add(_controller.text);
                      _controller.clear();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return ListTile(
                          leading: Checkbox(
                            value: item.isDone,
                            onChanged: (_) =>
                                context.read<TodoCubit>().toggle(item.id),
                          ),
                          title: Text(item.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                context.read<TodoCubit>().remove(item.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
