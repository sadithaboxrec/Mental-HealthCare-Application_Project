class Medicine {

  final String name;
  final String dose;
  final bool   beforeMeal;
  final bool   afterMeal;   //    for dr patient medicine output
  final int    tabletCount; //    for dr patient medicine output
  final bool   morning;
  final bool   afternoon;
  final bool   night;

  const Medicine({

    required this.name,
    required this.dose,
    this.beforeMeal  = false,
    this.afterMeal   = false, //    for dr patient medicine output
    this.tabletCount = 1,     //    for dr patient medicine output
    this.morning     = false,
    this.afternoon   = false,
    this.night       = false,

  });

  factory Medicine.fromMap(Map<String, dynamic> m) => Medicine(

    name:        m['name']        ?? '',
    dose:        m['dose']        ?? '',
    beforeMeal:  m['beforeMeal']  ?? false,
    afterMeal:   m['afterMeal']   ?? false, //    for dr patient medicine output
    tabletCount: m['tabletCount'] ?? 1,     //    for dr patient medicine output
    morning:     m['morning']     ?? false,
    afternoon:   m['afternoon']   ?? false,
    night:       m['night']       ?? false,
  );

  Map<String, dynamic> toMap() => {

    'name':        name,
    'dose':        dose,
    'beforeMeal':  beforeMeal,
    'afterMeal':   afterMeal,   //    for dr patient medicine output
    'tabletCount': tabletCount, //    for dr patient medicine output
    'morning':     morning,
    'afternoon':   afternoon,
    'night':       night,
  };
}