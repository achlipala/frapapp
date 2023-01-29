open Bootstrap

con r = _
val fl = _

val css =
    {Bootstrap = bless "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css",
     FontAwesome = bless "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/fontawesome.min.css",
     FontAwesomeSolid = bless "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/solid.min.css",
     FontAwesomeRegular = bless "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/regular.min.css",
     DateTimePicker = bless "https://cdn.jsdelivr.net/npm/jquery-datetimepicker@2.5.21/jquery.datetimepicker.css",
     Upo = bless "/style.css"}

val icon = Some (bless "https://www.eecs.mit.edu/sites/all/themes/adaptivetheme/miteecs_adaptive_production/favicon.ico")

fun wrap x = x
val navclasses = CLASS "navbar navbar-expand-md navbar-dark fixed-top bg-dark"
val titleInNavbar = True
