<cfif thistag.executionmode eq "end">
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
	<title>Installed Plugins</title>
	<link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.0.2/css/bootstrap.min.css">
</head>
<body>
<nav class="navbar navbar-inverse" role="navigation">
<p class="navbar-brand">Installed Plugins</p>
</nav>
<div class="col-md-6 col-md-offset-3">
#thistag.generatedcontent#
</div>
</body>
</html>
</cfoutput>
</cfif>
<cfset thistag.generatedcontent = "">