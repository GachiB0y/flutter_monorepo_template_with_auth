import 'package:flutter/material.dart';
import 'package:navigator_api/home_navigator.dart';
import 'package:take_short/src/navigation/router.dart';
import 'package:take_short/src/navigation/routes/pages.dart';

final class HomeNavigatorRouter implements HomeNavigator {
  const HomeNavigatorRouter();

  @override
  void goToHome(BuildContext context) {
    return AppNavigator.change(
      context,
      (pages) => [
        ...pages,
        AppPages.home.page(),
      ],
    );
  }
}
