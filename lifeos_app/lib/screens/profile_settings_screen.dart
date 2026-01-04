import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          FCard(
            child: Column(
              children: [
                FTile(
                  prefixIcon: FIcon(FAssets.icons.user),
                  title: const Text('Account Information'),
                  onPress: () {},
                ),
                FTile(
                  prefixIcon: FIcon(FAssets.icons.bell),
                  title: const Text('Notifications'),
                  onPress: () {},
                ),
                FTile(
                  prefixIcon: FIcon(FAssets.icons.shieldCheck),
                  title: const Text('Privacy & Security'),
                  onPress: () {},
                ),
                FTile(
                  prefixIcon: FIcon(FAssets.icons.logOut),
                  title: const Text('Log Out'),
                  onPress: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
