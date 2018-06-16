open Bootstrap4

con r = _
val fl = _

val css = (bless "https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css",
           bless "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css",
           bless "/style.css")

val icon = Some (bless "https://www.eecs.mit.edu/sites/all/themes/adaptivetheme/miteecs_adaptive_production/favicon.ico")

fun wrap x = x
val navclasses = CLASS "navbar navbar-expand-md navbar-dark fixed-top bg-dark"
val titleInNavbar = True
