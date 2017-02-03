open Bootstrap3

con r = _
val fl = _

val css = (bless "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css",
           bless "/style.css")

val icon = Some (bless "https://www.eecs.mit.edu/sites/all/themes/adaptivetheme/miteecs_adaptive_production/favicon.ico")

fun wrap x = x
val navclasses = CLASS "navbar navbar-inverse navbar-fixed-top"
val titleInNavbar = True
