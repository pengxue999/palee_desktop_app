import 'dart:io';

Future<void> revealFileLocationImpl(String path) async {
  final normalizedPath = path.replaceAll('/', Platform.pathSeparator);

  if (Platform.isWindows) {
    await Process.run('explorer', ['/select,$normalizedPath']);
    return;
  }

  if (Platform.isMacOS) {
    await Process.run('open', ['-R', normalizedPath]);
    return;
  }

  if (Platform.isLinux) {
    final directory = File(normalizedPath).parent.path;
    await Process.run('xdg-open', [directory]);
  }
}
