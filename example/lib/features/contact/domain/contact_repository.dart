import 'contact_item.dart';

abstract interface class ContactRepository {
  Future<List<ContactItem>> fetchContacts();
  Future<void> addContact({required String name, required String phone});
  Future<void> deleteContact(String id);
}
