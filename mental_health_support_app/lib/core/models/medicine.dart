class Medicine {

  final String name;
  final String dose;
  final bool beforeMeal;
  final bool afterMeal;    
  final int tabletCount; 
  final bool morning;
  final bool afternoon;
  final bool night;

  const Medicine ( {

    required this.name,
    required this.dose,
    this.beforeMeal = false,
    this.afterMeal = false,
    this.tabletCount = 1, 
    this.morning = false,
    this.afternoon = false,
    this.night = false,
  
  } );

  factory Medicine.fromMap( Map<String , dynamic> m ) => Medicine (

    name : m[ 'name' ] ?? '',
    dose : m[ 'dose' ] ?? '',
    beforeMeal : m[ 'beforeMeal' ] ?? false,
    afterMeal : m[ 'afterMeal' ] ?? false, 
    tabletCount : m[ 'tabletCount' ] ?? 1, 
    morning : m[ 'morning' ] ?? false,
    afternoon : m[ 'afternoon' ] ?? false,
    night : m[ 'night' ] ?? false,
  
  );

  Map<String, dynamic> toMap( ) => {

    'name' : name,
    'dose' : dose,
    'beforeMeal' : beforeMeal,
    'afterMeal' : afterMeal,
    'tabletCount' : tabletCount, 
    'morning' : morning,
    'afternoon' : afternoon,
    'night' : night,

  };

}
