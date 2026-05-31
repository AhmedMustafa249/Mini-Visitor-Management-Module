import 'package:equatable/equatable.dart';
import '../data/visitor.dart';

abstract class VisitorState extends Equatable {
  const VisitorState();
  @override
  List<Object?> get props => [];
}

class VisitorInitial extends VisitorState {}

class VisitorLoading extends VisitorState {}

class VisitorLoaded extends VisitorState {
  final List<Visitor> visitors;
  const VisitorLoaded(this.visitors);
  @override
  List<Object?> get props => [visitors];
}

class VisitorDetailLoaded extends VisitorState {
  final Visitor visitor;
  const VisitorDetailLoaded(this.visitor);
  @override
  List<Object?> get props => [visitor];
}

class VisitorFailure extends VisitorState {
  final String message;
  const VisitorFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class VisitorAdding extends VisitorState {}

class VisitorAdded extends VisitorState {}
