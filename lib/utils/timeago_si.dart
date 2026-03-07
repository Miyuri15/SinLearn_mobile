import 'package:timeago/timeago.dart' as timeago;

class SiMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String suffixAgo() => '';

  @override
  String prefixFromNow() => '';
  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'මේ දැන්';

  @override
  String aboutAMinute(int minutes) => 'මිනිත්තුවකට පමණ පෙර';

  @override
  String minutes(int minutes) => 'මිනිත්තු $minutesකට පෙර';

  @override
  String aboutAnHour(int minutes) => 'පැයකට පමණ පෙර';

  @override
  String hours(int hours) => 'පැය $hoursකට පෙර';

  @override
  String aDay(int hours) => 'ඊයේ';

  @override
  String days(int days) => 'දින $daysකට පෙර';

  @override
  String aboutAMonth(int days) => 'මාසයකට පමණ පෙර';

  @override
  String months(int months) => 'මාස $monthsකට පෙර';

  @override
  String aboutAYear(int year) => 'වසරකට පමණ පෙර';

  @override
  String years(int years) => 'වසර $yearsකට පෙර';

  @override
  String wordSeparator() => ' ';
}
