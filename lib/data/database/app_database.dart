import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Tables
class Products extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
  RealColumn get rating => real()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get stock => integer().nullable()();
  TextColumn get brand => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Fields extends Table {
  TextColumn get id => text()();
  TextColumn get crop => text()();
  RealColumn get area => real()();
  TextColumn get waterSource => text()();
  TextColumn get location => text().nullable()();
  TextColumn get coordinates => text().nullable()(); // JSON string
  DateTimeColumn get plantingDate => dateTime().nullable()();
  DateTimeColumn get harvestDate => dateTime().nullable()();
  TextColumn get status => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get crop => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text()(); // HH:mm format
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get farmDetails => text().nullable()(); // JSON string
  BoolColumn get isKycVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // 'expense' or 'income'
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products, Fields, Tasks, Users, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(transactions);
        }
      },
    );
  }


  // Product methods
  Future<List<Product>> getAllProducts() => select(products).get();
  Future<Product?> getProductById(int id) => (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<void> insertProduct(ProductsCompanion product) => into(products).insert(product, mode: InsertMode.replace);
  Future<void> insertProducts(List<ProductsCompanion> productList) => batch((batch) {
    batch.insertAll(products, productList, mode: InsertMode.replace);
  });
  Future<void> deleteProduct(int id) => (delete(products)..where((p) => p.id.equals(id))).go();
  Future<void> clearProducts() => delete(products).go();

  // Field methods
  Future<List<Field>> getAllFields() => select(fields).get();
  Future<Field?> getFieldById(String id) => (select(fields)..where((f) => f.id.equals(id))).getSingleOrNull();
  Future<void> insertField(FieldsCompanion field) => into(fields).insert(field, mode: InsertMode.replace);
  Future<void> insertFields(List<FieldsCompanion> fieldList) => batch((batch) {
    batch.insertAll(fields, fieldList, mode: InsertMode.replace);
  });
  Future<void> deleteField(String id) => (delete(fields)..where((f) => f.id.equals(id))).go();
  Future<void> clearFields() => delete(fields).go();

  // Task methods
  Future<List<Task>> getTasksByCropAndDate(String crop, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(tasks)
      ..where((t) => t.crop.equals(crop))
      ..where((t) => t.date.isBiggerOrEqualValue(startOfDay))
      ..where((t) => t.date.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm(expression: t.time)]))
        .get();
  }
  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task, mode: InsertMode.replace);
  Future<void> insertTasks(List<TasksCompanion> taskList) => batch((batch) {
    batch.insertAll(tasks, taskList, mode: InsertMode.replace);
  });
  Future<void> updateTaskCompletion(String id, bool isCompleted) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<void> deleteTask(String id) => (delete(tasks)..where((t) => t.id.equals(id))).go();
  Future<void> clearTasks() => delete(tasks).go();

  // User methods
  Future<User?> getCurrentUser() => (select(users)..limit(1)).getSingleOrNull();
  Future<void> insertUser(UsersCompanion user) => into(users).insert(user, mode: InsertMode.replace);
  Future<void> updateUser(UsersCompanion user) {
    return (update(users)..where((u) => u.id.equals(user.id.value))).write(user);
  }
  Future<void> deleteUser(String id) => (delete(users)..where((u) => u.id.equals(id))).go();
  Future<void> clearUsers() => delete(users).go();

  // Transaction methods
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<void> insertTransaction(TransactionsCompanion transaction) => into(transactions).insert(transaction, mode: InsertMode.replace);
  Future<void> deleteTransaction(String id) => (delete(transactions)..where((t) => t.id.equals(id))).go();
  Future<void> clearTransactions() => delete(transactions).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'krishipradhan.db'));
    return NativeDatabase(file);
  });
}
