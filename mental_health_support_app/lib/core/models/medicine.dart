class Medicine {

  final String name;
  final String dose;
  final bool   beforeMeal;
  final bool   afterMeal;   // ← NEW
  final int    tabletCount; // ← NEW
  final bool   morning;
  final bool   afternoon;
  final bool   night;

  const Medicine({

    required this.name,
    required this.dose,
    this.beforeMeal  = false,
    this.afterMeal   = false, // ← NEW
    this.tabletCount = 1,     // ← NEW
    this.morning     = false,
    this.afternoon   = false,
    this.night       = false,

  });

  factory Medicine.fromMap(Map<String, dynamic> m) => Medicine(

    name:        m['name']        ?? '',
    dose:        m['dose']        ?? '',
    beforeMeal:  m['beforeMeal']  ?? false,
    afterMeal:   m['afterMeal']   ?? false, // ← NEW
    tabletCount: m['tabletCount'] ?? 1,     // ← NEW
    morning:     m['morning']     ?? false,
    afternoon:   m['afternoon']   ?? false,
    night:       m['night']       ?? false,
  );

  Map<String, dynamic> toMap() => {

    'name':        name,
    'dose':        dose,
    'beforeMeal':  beforeMeal,
    'afterMeal':   afterMeal,   // ← NEW
    'tabletCount': tabletCount, // ← NEW
    'morning':     morning,
    'afternoon':   afternoon,
    'night':       night,
  };
}