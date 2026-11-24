import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/tracking/tracking_cubit.dart';
import 'package:tracker/ui/tracking_page.dart';

class DriverTrackerApp extends StatelessWidget {
  const DriverTrackerApp({super.key, required this.cubit});

  final TrackingCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        title: 'Driver tracking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF146C43)),
          useMaterial3: true,
        ),
        home: const TrackingPage(),
      ),
    );
  }
}
