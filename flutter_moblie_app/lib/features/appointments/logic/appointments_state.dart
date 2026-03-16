import 'package:flutter/material.dart';

@immutable
abstract class AppointmentsState {
  const AppointmentsState();
}

class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

class AppointmentsLoaded extends AppointmentsState {
  final List<dynamic> appointments;
  final String? selectedFilter;

  const AppointmentsLoaded(this.appointments, {this.selectedFilter});
}

class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError(this.message);
}

class AppointmentCreating extends AppointmentsState {
  const AppointmentCreating();
}

class AppointmentCreated extends AppointmentsState {
  final dynamic appointment;

  const AppointmentCreated(this.appointment);
}

class AppointmentCreateError extends AppointmentsState {
  final String message;

  const AppointmentCreateError(this.message);
}
