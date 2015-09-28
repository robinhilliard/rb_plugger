<cfif thistag.executionmode eq "end">
<cfoutput>
<h3>#attributes.shop.name#</h3>
<table class="table table-hover">
<row><th>Description</th>#attributes.unitHeaders#</row>
#thistag.generatedcontent#
</table>
</cfoutput>
</cfif>
<cfset thistag.generatedcontent = "">