import 'file_location_revealer_stub.dart'
    if (dart.library.io) 'file_location_revealer_io.dart';

Future<void> revealFileLocation(String path) => revealFileLocationImpl(path);
