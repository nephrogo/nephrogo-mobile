import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/ui/general/dialogs.dart';
import 'package:nephrogo/ui/general/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> launchURL(String url) async {
  if (await canLaunch(url)) {
    return launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

Future<bool> launchPdf(String url) {
  final queryParameters = {'url': url, 'embedded': 'true'};
  final uri = Uri.https('docs.google.com', 'gview', queryParameters);

  return launchURL(uri.toString());
}

Future<bool> launchPhone(String phoneNumber) {
  final phoneUrl = 'tel:$phoneNumber';

  return launchURL(phoneUrl);
}

Future<bool> launchEmail(String email) {
  final emailUrl = 'mailto:$email';

  return launchURL(emailUrl);
}

class ApiUtils {
  ApiUtils._();

  static Future<bool> saveToApi({
    required BuildContext context,
    required Future Function() futureBuilder,
    String Function(String data)? onServerValidationError,
    Future<void> Function()? onSuccess,
  }) async {
    final future = futureBuilder().catchError(
      (e, stackTrace) async {
        FirebaseCrashlytics.instance.recordError(e, stackTrace as StackTrace);

        String? message;
        if (onServerValidationError != null &&
            e is DioError &&
            e.response?.statusCode == 400) {
          final data = e.response?.toString() ?? '';

          message = onServerValidationError(data);
        }

        await showAppErrorDialog(
          context: context,
          message: message ?? context.appLocalizations.serverErrorDescription,
        );

        return null;
      },
    );

    final res = await AppProgressDialog(context).showForFuture(future);

    if (res != null) {
      if (onSuccess != null) {
        await onSuccess();
      } else {
        Navigator.of(context).pop();
      }

      return true;
    }
    return false;
  }
}
