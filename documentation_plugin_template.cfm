<cfoutput>
<h3>#attributes.plugin.name#</h3>
#attributes.plugin.description#
<table class="table table-hover">
<tr><th>Version</th><td>#arrayToList(attributes.plugin.version, ".")#</td></tr>
<tr><th>Package</th><td>#attributes.plugin.package#</td></tr>
<tr><th>Mapping</th><td>#attributes.plugin.mapping#</td></tr>
<tr><th>Path</th><td>#attributes.plugin.path#</td></tr>
<cfif attributes.requires neq "">
<tr><th><br/>Requires</th><td><br/>
	<table class="table table-condensed">
		<tr><th>Plugin</th><th>Version</th></tr>
		#attributes.requires#
	</table>
</td></tr>
</cfif>
<cfif attributes.extends neq "">
<tr><th><br/>Extends</th><td><br/>
	<table class="table table-condensed">
		<tr><th>Extension Point</th><th>Implementation</th></tr>
		#attributes.extends#
	</table>
</td></tr>
</cfif>
<cfif attributes.provides neq "">
<tr><th><br/>Provides</th><td></br>
	<table class="table table-condensed">
		<tr><th>Extension Point</th><th>Type</th></tr>
		#attributes.provides#
	</table>
</td></tr>
</cfif>
</table>
</cfoutput>