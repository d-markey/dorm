import 'IDormField.dart';
import 'IDormEntityLink.dart';

abstract class IDormEntity<K> {
  K? get key;
  set key(K? k);
  
  List<IDormEntityLink> getLinks();

  dynamic getValue(IDormField column);
  IDormEntityLink getLink(IDormField column);
}
