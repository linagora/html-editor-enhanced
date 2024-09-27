import 'package:equatable/equatable.dart';

class TransferMethod with EquatableMixin {
  final String value;

  TransferMethod(this.value);

  @override
  List<Object?> get props => [value];
}