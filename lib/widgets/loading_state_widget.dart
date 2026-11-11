import 'package:flutter/material.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: blackColor.withValues(alpha: 0.5),
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: LoadingAnimationWidget.inkDrop(
                color: primaryColor,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
