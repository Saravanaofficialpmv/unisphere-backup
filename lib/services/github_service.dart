import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubRepoItem {
  final String name;
  final String description;
  final String language;
  final int stars;
  final int forks;
  final String htmlUrl;
  final String updatedAt;

  const GitHubRepoItem({
    required this.name,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
    required this.htmlUrl,
    required this.updatedAt,
  });

  factory GitHubRepoItem.fromJson(Map<String, dynamic> json) {
    String desc = json['description']?.toString() ?? '';
    if (desc.isEmpty) {
      final nameLower = (json['name'] ?? '').toString().toLowerCase();
      if (nameLower.contains('unisphere')) {
        desc = 'Cross-platform Smart Campus ERP built with Flutter & Supabase.';
      } else if (nameLower.contains('portfolio-v2')) {
        desc = 'Modern Developer Portfolio v2 built with TypeScript & React.';
      } else if (nameLower.contains('helpdesk')) {
        desc = 'AI-powered Helpdesk Support & Ticket Management System.';
      } else if (nameLower.contains('college')) {
        desc = 'College Management & Academic Information Portal.';
      } else if (nameLower.contains('crypto') || nameLower.contains('recommendation')) {
        desc = 'Sentimental analysis & recommendation engine for Gold and Crypto assets.';
      } else if (nameLower.contains('agency')) {
        desc = 'Agency & Corporate landing web project.';
      } else if (nameLower.contains('traffic')) {
        desc = 'Smart Traffic Light Management & Control System.';
      } else {
        desc = 'Open source software repository by @Saravanaofficialpmv';
      }
    }

    return GitHubRepoItem(
      name: json['name'] ?? 'repository',
      description: desc,
      language: json['language'] ?? 'Dart',
      stars: json['stargazers_count'] ?? 0,
      forks: json['forks_count'] ?? 0,
      htmlUrl: json['html_url'] ?? 'https://github.com/Saravanaofficialpmv',
      updatedAt: json['updated_at'] != null
          ? json['updated_at'].toString().split('T').first
          : 'Recently',
    );
  }
}

class GitHubUserStats {
  final String username;
  final String name;
  final String avatarUrl;
  final String bio;
  final int publicRepos;
  final int followers;
  final int following;
  final int starsEarned;
  final int commitsThisYear;
  final List<String> topLanguages;
  final Map<String, double> languageBreakdown;
  final List<GitHubRepoItem> featuredRepos;
  final String lastSyncedAt;
  final bool isFetched;

  const GitHubUserStats({
    required this.username,
    this.name = '',
    this.avatarUrl = '',
    this.bio = '',
    this.publicRepos = 0,
    this.followers = 0,
    this.following = 0,
    this.starsEarned = 0,
    this.commitsThisYear = 0,
    this.topLanguages = const [],
    this.languageBreakdown = const {},
    this.featuredRepos = const [],
    this.lastSyncedAt = 'Never',
    this.isFetched = false,
  });

  factory GitHubUserStats.empty([String username = '']) {
    return GitHubUserStats(
      username: username,
      name: username.isEmpty ? 'Not linked' : username,
      avatarUrl: '',
      bio: '',
      publicRepos: 0,
      followers: 0,
      following: 0,
      starsEarned: 0,
      commitsThisYear: 0,
      topLanguages: const [],
      languageBreakdown: const {},
      featuredRepos: const [],
      lastSyncedAt: 'Never',
      isFetched: false,
    );
  }
}

class GitHubService {
  static const String _baseUrl = 'https://api.github.com/users';

  /// Fetches public profile stats and repositories from GitHub REST API
  static Future<GitHubUserStats> fetchUserStats(String rawUsername) async {
    final username = rawUsername.trim().replaceAll('@', '');
    if (username.isEmpty) {
      return GitHubUserStats.empty();
    }

    try {
      // 1. Fetch User Profile
      final profileUri = Uri.parse('$_baseUrl/$username');
      final profileResp = await http.get(profileUri, headers: {
        'User-Agent': 'UNISPHERE-App',
      }).timeout(const Duration(seconds: 8));

      if (profileResp.statusCode != 200) {
        return _getFallbackStats(username);
      }

      final profileJson = jsonDecode(profileResp.body) as Map<String, dynamic>;

      // 2. Fetch User Repositories
      final reposUri = Uri.parse('$_baseUrl/$username/repos?sort=updated&per_page=30');
      final reposResp = await http.get(reposUri, headers: {
        'User-Agent': 'UNISPHERE-App',
      }).timeout(const Duration(seconds: 8));

      List<GitHubRepoItem> repoItems = [];
      int totalStars = 0;
      Map<String, int> langCounts = {};

      if (reposResp.statusCode == 200) {
        final reposList = jsonDecode(reposResp.body) as List;
        for (var item in reposList) {
          if (item is Map<String, dynamic>) {
            final repo = GitHubRepoItem.fromJson(item);
            repoItems.add(repo);

            totalStars += repo.stars;
            if (item['language'] != null && item['language'].toString().isNotEmpty) {
              final lang = item['language'].toString();
              langCounts[lang] = (langCounts[lang] ?? 0) + 1;
            }
          }
        }
      }

      // 3. Fetch User Public Events (to count total commits)
      int totalCommitsCount = 0;
      try {
        final eventsUri = Uri.parse('$_baseUrl/$username/events?per_page=100');
        final eventsResp = await http.get(eventsUri, headers: {
          'User-Agent': 'UNISPHERE-App',
        }).timeout(const Duration(seconds: 5));

        if (eventsResp.statusCode == 200) {
          final eventsList = jsonDecode(eventsResp.body) as List;
          for (var ev in eventsList) {
            if (ev is Map<String, dynamic> && ev['type'] == 'PushEvent') {
              final payload = ev['payload'];
              if (payload != null && payload['size'] != null) {
                totalCommitsCount += (payload['size'] as num).toInt();
              } else if (payload != null && payload['commits'] is List) {
                totalCommitsCount += (payload['commits'] as List).length;
              } else {
                totalCommitsCount += 1;
              }
            }
          }
        }
      } catch (_) {}

      // Calculate Language Breakdown
      final int totalLangRepos = langCounts.values.fold(0, (sum, count) => sum + count);
      Map<String, double> languageBreakdown = {};
      List<String> topLanguages = [];

      if (totalLangRepos > 0) {
        final sortedLangs = langCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (var entry in sortedLangs) {
          topLanguages.add(entry.key);
          languageBreakdown[entry.key] = double.parse(
            ((entry.value / totalLangRepos) * 100).toStringAsFixed(1),
          );
        }
      }

      // Format Last Synced Timestamp
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
      final lastSyncedAt = 'Today at $formattedHour:$minute $period';

      final publicReposCount = profileJson['public_repos'] as int? ?? repoItems.length;
      final followers = profileJson['followers'] as int? ?? 0;
      final following = profileJson['following'] as int? ?? 0;
      final rawBio = profileJson['bio'] as String?;
      final bio = (rawBio != null && rawBio.isNotEmpty) ? rawBio : 'GitHub Developer';
      final rawName = profileJson['name'] as String?;
      final name = (rawName != null && rawName.isNotEmpty) ? rawName : username;
      final avatarUrl = profileJson['avatar_url'] as String? ?? '';

      return GitHubUserStats(
        username: username,
        name: name,
        avatarUrl: avatarUrl,
        bio: bio,
        publicRepos: publicReposCount,
        followers: followers,
        following: following,
        starsEarned: totalStars,
        commitsThisYear: totalCommitsCount,
        topLanguages: topLanguages,
        languageBreakdown: languageBreakdown,
        featuredRepos: repoItems.take(6).toList(),
        lastSyncedAt: lastSyncedAt,
        isFetched: true,
      );
    } catch (_) {
      return _getFallbackStats(username);
    }
  }

  static GitHubUserStats _getFallbackStats(String username) {
    return GitHubUserStats.empty(username);
  }
}
