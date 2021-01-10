import 'package:flutter/material.dart';
import 'package:nephrolog/authentication/authentication_provider.dart';
import 'package:nephrolog/constants.dart';
import 'package:nephrolog/l10n/localizations.dart';
import 'package:nephrolog/routes.dart';
import 'package:nephrolog/ui/general/app_future_builder.dart';
import 'package:nephrolog/ui/general/app_network_image.dart';
import 'package:nephrolog/ui/general/components.dart';
import 'package:nephrolog/ui/user_profile_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTab extends StatelessWidget {
  static const anonymousPhotoPath = "assets/anonymous_avatar.jpg";

  final _authenticationProvider = AuthenticationProvider();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return ListView(
      children: [
        BasicSection(
          children: [_buildUserProfileTile(context)],
        ),
        BasicSection(
          children: [
            AppListTile(
              title: Text(appLocalizations.userProfileScreenTitle),
              leading: Icon(Icons.person),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.ROUTE_USER_PROFILE,
                  arguments: UserProfileScreenNavigationType.close,
                );
              },
            ),
          ],
        ),
        BasicSection(
          children: [
            AppListTile(
              title: Text(appLocalizations.faqTitle),
              leading: Icon(Icons.help),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.ROUTE_FAQ,
                );
              },
            ),
          ],
        ),
        BasicSection(
          children: [
            AppListTile(
              title: Text(appLocalizations.privacyPolicy),
              leading: Icon(Icons.lock),
              onTap: () {
                _launchURL(Constants.privacyPolicyUrl);
              },
            ),
            AppListTile(
              title: Text(appLocalizations.usageRules),
              leading: Icon(Icons.description),
              onTap: () {
                _launchURL(Constants.rulesUrl);
              },
            ),
          ],
        ),
        BasicSection(
          children: [
            AppListTile(
              title: Text(appLocalizations.logout),
              leading: Icon(Icons.logout),
              onTap: () => _signOut(context),
            ),
          ],
        ),
        AppFutureBuilder<String>(
          future: _getVersionString(),
          builder: (context, version) {
            return Center(child: Text(version));
          },
        )
      ],
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future _signOut(BuildContext context) async {
    await _authenticationProvider.signOut();

    await Navigator.pushReplacementNamed(
      context,
      Routes.ROUTE_LOGIN,
    );
  }

  Widget getUserProfilePhoto() {
    final photoURL = _authenticationProvider.currentUserPhotoURL;
    if (photoURL == null) {
      return Image.asset(anonymousPhotoPath);
    }

    return AppNetworkImage(
      url: photoURL,
      fallbackAssetImage: anonymousPhotoPath,
    );
  }

  Future<String> _getVersionString() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return "${packageInfo.version} (${packageInfo.buildNumber})";
  }

  Widget _buildUserProfileTile(BuildContext context) {
    final user = _authenticationProvider.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AppListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 64,
            height: 64,
            child: getUserProfilePhoto(),
          ),
        ),
        title: Text(
          user.displayName ?? user.email,
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: user.displayName != null ? Text(user.email) : null,
      ),
    );
  }
}
