import 'package:app/app.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkWidget extends StatelessWidget {
  final String link;
  final String linkTitle;

  LinkWidget({this.link, this.linkTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: getCardDecoration(context, roundedCard: true),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final l = resolveSkylink(
              link,
              trusted: true,
            );
            if (await canLaunch(l)) {
              launch(l);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  UniconsLine.link,
                  color: SkyColors.darkGrey,
                  size: 16,
                ),
                SizedBox(
                  width: 8,
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${linkTitle ?? Uri.tryParse(link)?.host}',
                        style: TextStyle(
                          color: SkyColors.red,
                          fontSize: 15,
                        ),
                      ),
                      if (linkTitle != null)
                        Text(
                          '${Uri.tryParse(link)?.host}',
                          style: TextStyle(
                            color: SkyColors.darkGrey,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
