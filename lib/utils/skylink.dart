import 'package:skynet/skynet.dart';

String resolveSkylink(String link, {bool trusted = false}) {
  // TODO Tests
  if (link.startsWith('sia://')) {
    final uri = Uri.tryParse(link);

    if (uri == null) return null;

    final host = uri.host;

    if (host.endsWith('.hns')) {
      return 'https://${host.split(".").first}.hns.${SkynetConfig.host}/${link.substring(6 + host.length + 1)}';
    } else {
      return 'https://${SkynetConfig.host}/' + link.substring(6);
    }
  }

  if (trusted) {
    return link;
  } else {
    return '';
  }

/*       msgText = msgText.replaceAllMapped('sia://', (match) {
          final str =
              msgText.substring(match.end).split(' ').first.split('/').first;

          if (str.length < 46) {
            return 'https://${SkynetConfig.host}/hns/';
          } else {
            return 'https://${SkynetConfig.host}/';
          }
        }); */
}
