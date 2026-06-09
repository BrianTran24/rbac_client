import '../domain/contact_item.dart';
import '../domain/contact_repository.dart';

/// In-memory implementation – pure business logic, no RBAC awareness.
/// Wrap this with the generated [ContactRepositoryGuarded] to enforce permissions.
class InMemoryContactRepository implements ContactRepository {
  final List<ContactItem> _items = [
    const ContactItem(id: 'c1', name: 'Alice', phone: '0901234567'),
    const ContactItem(id: 'c2', name: 'Bob', phone: '0912345678'),
  ];

  int _counter = 3;

  @override
  Future<void> addContact({required String name, required String phone}) async {
    _items.add(ContactItem(id: 'c${_counter++}', name: name, phone: phone));
  }

  @override
  Future<void> deleteContact(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<ContactItem>> fetchContacts() async {
    return List<ContactItem>.from(_items);
  }
}
