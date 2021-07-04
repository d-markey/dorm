import 'IDormTransaction.dart';

abstract class IDormMigration {
  int get version;
  Future up(IDormTransaction transaction);
  Future down(IDormTransaction transaction);
}
