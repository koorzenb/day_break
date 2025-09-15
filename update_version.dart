import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

void main() {
  final changelogFile = File('CHANGELOG.md');

  if (!changelogFile.existsSync()) {
    print('Error: CHANGELOG.md not found!');
    return;
  }

  // Prompt user for commit message
  String? commitMessage = _promptForCommitMessage();

  if (commitMessage == null || commitMessage.isEmpty) {
    print('Error: No commit message provided. Aborting.');
    return;
  }

  // Extract commit type and description, with fallback if no type is present
  final commitParts = RegExp(r'^(.*?):\s*(.*)$').firstMatch(commitMessage);

  String commitType = 'Other'; // Default type if none is provided
  String commitDescription = commitMessage; // Use the entire message as description

  if (commitParts != null) {
    commitType = commitParts.group(1)!.trim().toLowerCase();
    commitDescription = commitParts.group(2)!.trim();
  }

  final nextVersion = _updatePubspecVersion(commitType == 'fix' || commitType == 'bug' || commitType == 'ref');
  _updateChangelog(nextVersion, commitType, commitDescription, changelogFile);
  _commitChanges(commitMessage);
}

void _updateChangelog(String? nextVersion, String commitType, String commitDescription, File changelogFile) {
  // Update CHANGELOG.md
  final changelogEntry = '''
## $nextVersion
  
  ### ${_capitalize(commitType == 'ref' ? 'refactor' : commitType)}
  
  - $commitDescription
  
  ''';
  changelogFile.writeAsStringSync(changelogEntry + changelogFile.readAsStringSync());

  print('Updated CHANGELOG.md with new entry: $changelogEntry');
  print('Added changelog entry for version: $nextVersion with type "$commitType" and message: "$commitDescription"');
}

String? _updatePubspecVersion(bool isNextPatch) {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found!');
    null;
  }

  // Read pubspec.yaml
  final pubspecContent = pubspecFile.readAsStringSync();
  final currentVersionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)\+(\d+)').firstMatch(pubspecContent);

  if (currentVersionMatch == null) {
    print('Error: Could not find version in pubspec.yaml!');
    return null;
  }

  // Extract version and build number
  final currentVersion = Version.parse(currentVersionMatch.group(1)!); // Semantic version (e.g., 0.3.0)
  final currentBuildNumber = int.parse(currentVersionMatch.group(2)!); // Build number (e.g., 03000)
  print('Extracted Current version: $currentVersion, Build number: $currentBuildNumber');

  // Determine next version based on commit type
  Version nextVersion;
  int nextBuildNumber;
  if (isNextPatch) {
    nextVersion = currentVersion.nextPatch; // Increment the patch version
    nextBuildNumber = currentBuildNumber + 1; // Increment the build number
  } else {
    nextVersion = Version(currentVersion.major, currentVersion.minor + 1, 0);
    nextBuildNumber = ((currentBuildNumber ~/ 100) + 1) * 100;
  }
  print('Next version: $nextVersion, Next build number: $nextBuildNumber');

  // Update pubspec.yaml with new version and build number
  final updatedPubspecContent = pubspecContent.replaceFirst(RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'), 'version: $nextVersion+$nextBuildNumber');
  pubspecFile.writeAsStringSync(updatedPubspecContent);
  print('Updated pubspec.yaml to version: $nextVersion+$nextBuildNumber');

  return nextVersion.toString();
}

// Utility function to capitalize the first letter of a string
String _capitalize(String input) {
  return input[0].toUpperCase() + input.substring(1);
}

String? _promptForCommitMessage() {
  print('\n📝 Enter your commit message:');
  print('Examples:');
  print('  fix: Resolve scheduler timing issue');
  print('  ref: Refactor status bar service');
  print('  chore: Updated build scripts');
  print('  feat: Add new notification system');
  print('  docs: Update README');
  print('');
  stdout.write('Commit message: ');

  final input = stdin.readLineSync()?.trim();
  return input;
}

void _commitChanges(String commitMessage) {
  // Stage the updated files
  final gitAddResult = Process.runSync('git', ['add', 'pubspec.yaml', 'CHANGELOG.md']);
  if (gitAddResult.exitCode != 0) {
    print('Error: Failed to stage files. ${gitAddResult.stderr}');
    return;
  }

  print('Staged pubspec.yaml and CHANGELOG.md for commit.');
  final gitCommitResult = Process.runSync('git', ['commit', '-m', commitMessage]);
  if (gitCommitResult.exitCode != 0) {
    print('Error: Failed to commit changes. ${gitCommitResult.stderr}');
    return;
  }
  print('Changes committed successfully');
}
