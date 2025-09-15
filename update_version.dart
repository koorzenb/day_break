import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

void main(List<String> args) {
  print('Running Flutter tests...');
  final testResult = Process.runSync('flutter', ['test'], runInShell: true);

  if (testResult.exitCode != 0) {
    print('Error: Tests failed. Aborting version update.');
    print(testResult.stdout);
    print(testResult.stderr);
    return;
  }

  final changelogFile = File('CHANGELOG.md');

  if (!changelogFile.existsSync()) {
    print('Error: CHANGELOG.md not found!');
    return;
  }

  // Prompt user for commit message
  String? commitMessage;
  if (args.isNotEmpty) {
    commitMessage = args.join(' ');
  } else {
    commitMessage = _promptForCommitMessage();
  }

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

  final nextVersion = _updatePubspecVersion(
    commitType == 'fix' ||
        commitType == 'bug' ||
        commitType == 'ref' ||
        commitType == 'chore' ||
        commitType == 'docs' ||
        commitType == 'test' ||
        commitType == 'enh',
  );
  _updateChangelog(nextVersion, commitType, commitDescription, changelogFile);
  _commitChanges(commitMessage);
}

void _updateChangelog(String? nextVersion, String commitType, String commitDescription, File changelogFile) {
  // Update CHANGELOG.md
  var ct = _capitalize(commitType == 'ref' ? 'refactor' : commitType);
  ct = _capitalize(ct == 'Feat' ? 'feature' : ct);
  ct = _capitalize(ct == 'Enh' ? 'enhancement' : ct);
  final changelogEntry =
      '''
## $nextVersion
  
### $ct
  
- $commitDescription

''';
  changelogFile.writeAsStringSync(changelogEntry + changelogFile.readAsStringSync());
}

String? _updatePubspecVersion(bool isNextPatch) {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found!');
    return null;
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

  // Determine next version based on commit type
  Version nextVersion;
  String nextBuildNumber;
  if (isNextPatch) {
    nextVersion = currentVersion.nextPatch;
    nextBuildNumber = '${currentBuildNumber + 1}';
    print('Incrementing patch version: $nextVersion, build number: $nextBuildNumber');
  } else {
    nextVersion = Version(currentVersion.major, currentVersion.minor + 1, 0);
    nextBuildNumber = '00${((currentBuildNumber ~/ 100) + 1) * 100}'; // manually update this for major releases
    print('Incrementing patch version: $nextVersion, build number: $nextBuildNumber');
  }

  // Update pubspec.yaml with new version and build number
  final updatedPubspecContent = pubspecContent.replaceFirst(RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'), 'version: $nextVersion+$nextBuildNumber');
  pubspecFile.writeAsStringSync(updatedPubspecContent);
  print('Updated pubspec.yaml to version: $nextVersion+$nextBuildNumber');

  _updateBuildEnv(int.parse(nextBuildNumber), nextVersion);
  return nextVersion.toString();
}

void _updateBuildEnv(int nextBuildNumber, Version nextVersion) {
  final buildEnvFile = File('set-build-env.bat');

  if (!buildEnvFile.existsSync()) {
    print('Warning: set-build-env.bat not found, skipping batch file update');
    return;
  }

  // .. test

  final buildEnvContent = buildEnvFile.readAsStringSync();
  final formattedBuildNumber = nextBuildNumber.toString().padLeft(5, '0');

  final buildVersion = '$nextVersion.$nextBuildNumber';

  var updatedBuildEnvContent = buildEnvContent
      .replaceFirst(RegExp(r'set VERSION_NUMBER=.*'), 'set VERSION_NUMBER=$nextVersion')
      .replaceFirst(RegExp(r'set BUILD_VERSION=.*'), 'set BUILD_VERSION=$buildVersion')
      .replaceFirst(RegExp(r'set BUILD_NUMBER=.*'), 'set BUILD_NUMBER=$formattedBuildNumber');

  buildEnvFile.writeAsStringSync(updatedBuildEnvContent);
  print('Updated set-build-env.bat with:');
  print('  VERSION_NUMBER=$nextVersion');
  print('  BUILD_VERSION=$buildVersion');
  print('  BUILD_NUMBER=$formattedBuildNumber');
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
  final gitAddResult = Process.runSync('git', ['add', 'pubspec.yaml', 'CHANGELOG.md', 'set-build-env.bat']);
  if (gitAddResult.exitCode != 0) {
    print('Error: Failed to stage files. ${gitAddResult.stderr}');
    return;
  }

  final gitCommitResult = Process.runSync('git', ['commit', '-m', commitMessage]);
  if (gitCommitResult.exitCode != 0) {
    print('Error: Failed to commit changes. ${gitCommitResult.stderr}');
    return;
  }
  print('Changes committed successfully');
}
