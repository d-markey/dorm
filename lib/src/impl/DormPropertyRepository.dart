import 'package:dorm/dorm_interface.dart';

import 'DormRepository.dart';
import 'DormProperty.dart';

class DormPropertyRepository extends DormRepository<String, DormProperty> {
  DormPropertyRepository(IDormDataContext dataContext) : super(dataContext);

  @override
  DormPropertyRepository create() => DormPropertyRepository(dataContext);

  static void configure(IDormRepositoryFactory factory, IDormDatabase db) {
    factory.register<String, DormProperty>((dataContext) => DormPropertyRepository(dataContext));
    DormPropertyModel.configure(db);
  }
}
