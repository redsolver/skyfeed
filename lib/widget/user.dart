import 'package:app/app.dart';

class UserWidget extends StatelessWidget {
  final String userId;
  final String details;
  final bool isLoading;

  final Function onAccept;
  final Function onReject;

  final Function onPressed;

  UserWidget({
    @required this.userId,
    this.onPressed,
    this.details,
    this.onAccept,
    this.onReject,
    this.isLoading = false,
    @required Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = rd.isMobile ? 48.0 : 32.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ),
          child: UserBuilder(
            userId: userId,
            callback: (user) {
              if (user == null)
                return SizedBox(
                  height: height,
                );

              return Row(
                children: [
                  ClipRRect(
                    borderRadius: borderRadius,
                    child: Image.network(
                      resolveSkylink(
                        user.picture,
                      ),
                      width: height,
                      height: height,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildUsernameWidget(user, context, bold: rd.isMobile),
                        if (details != null)
                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 12,
                              color: SkyColors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      height: height - 8,
                      width: height - 8,
                      child: CircularProgressIndicator(),
                    ),
                  if (!isLoading) ...[
                    if (onAccept != null)
                      IconButton(
                        tooltip: 'Add user to your followers',
                        icon: Icon(
                          UniconsLine.checkCircle,
                          color: SkyColors.follow,
                        ),
                        onPressed: onAccept,
                      ),
                    if (onReject != null)
                      IconButton(
                        tooltip: 'Ignore user',
                        icon: Icon(
                          UniconsLine.timesCircle,
                          color: SkyColors.grey,
                        ),
                        onPressed: onReject,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
