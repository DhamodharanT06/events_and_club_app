import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color danger = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Colors.black;
  static const Color onSurface = Colors.black;
  static const Color onError = Colors.white;
  static const Color grey = Color(0xFFBDBDBD);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF616161);
  static const Color dark = Color(0xFF1F1F1F);
}

class AppStrings {
  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Full Name';
  static const String phone = 'Phone Number';
  static const String selectRole = 'Select Role';
  static const String admin = 'Admin';
  static const String user = 'User';
  static const String loginSuccess = 'Login Successful';
  static const String signupSuccess = 'Signup Successful';
  
  // Navigation
  static const String home = 'Home';
  static const String events = 'Events';
  static const String clubs = 'Clubs';
  static const String activities = 'Activities';
  static const String profile = 'Profile';
  
  // Events & Clubs
  static const String createEvent = 'Create Event';
  static const String createClub = 'Create Club';
  static const String eventDetails = 'Event Details';
  static const String clubDetails = 'Club Details';
  static const String registerEvent = 'Register Event';
  static const String joinClub = 'Join Club';
  static const String search = 'Search...';
  
  // General
  static const String logout = 'Logout';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String noData = 'No Data Available';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
}

enum UserRole { admin, user }

extension UserRoleExtension on UserRole {
  String get value {
    return this == UserRole.admin ? 'admin' : 'user';
  }

  static UserRole fromString(String value) {
    return value.toLowerCase() == 'admin' ? UserRole.admin : UserRole.user;
  }
}
