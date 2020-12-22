import 'package:app/app.dart';

ThemeData buildThemeData(BuildContext context, String theme) {
  bool dark = theme == 'dark';

  final textColor = dark ? Color(0xffd8d8d8) : Color(0xff272727);

  TextTheme newTextTheme = Theme.of(context).textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
        fontFamily: 'Roboto',
      );

  final fontFamilyFallback = <String>[
    'Noto Color Emoji',
  ]; // TODO Set

  newTextTheme = newTextTheme.copyWith(
    bodyText2: newTextTheme.bodyText2.copyWith(
      fontFamilyFallback: fontFamilyFallback,
    ),
    bodyText1: newTextTheme.bodyText1.copyWith(
      fontFamilyFallback: fontFamilyFallback,
    ),
    subtitle1: newTextTheme.subtitle1.copyWith(
      fontFamilyFallback: fontFamilyFallback,
    ),
    subtitle2: newTextTheme.subtitle2.copyWith(
      fontFamilyFallback: fontFamilyFallback,
    ),
    button: newTextTheme.button.copyWith(
      fontFamilyFallback: fontFamilyFallback,
    ),
  );
  return ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: dark ? Brightness.dark : Brightness.light,
      primaryColorBrightness: dark ? Brightness.dark : Brightness.light,
      // This is the theme of your application.
      //
      // Try running your application with "flutter run". You'll see the
      // application has a blue toolbar. Then, without quitting the app, try
      // changing the primarySwatch below to Colors.green and then invoke
      // "hot reload" (press "r" in the console where you ran "flutter run",
      // or simply save your changes to "hot reload" in a Flutter IDE).
      // Notice that the counter didn't reset back to zero; the application
      // is not restarted.
      hoverColor: dark ? null : Color(0xffEAFFE7), // TODO opacity

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        textStyle: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
      ),

      // !
      primaryColor: Color(0xff73BF71),
      dividerColor: dark ? Color(0xff303030) : Color(0xffB0F4BC),
      accentColor: SkyColors.follow,
      scaffoldBackgroundColor: dark ? Color(0xff191919) : Color(0xfff4f8f5),
      cardColor: dark ? Color(0xff202020) : Colors.white,
      dialogBackgroundColor: dark ? Color(0xff202020) : Colors.white,
      textTheme: newTextTheme,
      fontFamily: 'Roboto',
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      //hintColor: Colors.orange,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: TextStyle(
          height: 1.5,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: dark ? Color(0xff585858) : SkyColors.grey4,
          ),
        ),
      )

/*         #B0F4BC
        #A3E1A2
        #73BF71
        #19B417 */
      );
}

class ThemeModel with ChangeNotifier {
  final ThemeMode _mode;
  ThemeMode get mode => _mode;

  ThemeModel(this._mode);
}
