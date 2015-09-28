<cfif thistag.executionmode eq "end">
<cfoutput>
<tr><td>#attributes.item.name#</td>#thistag.generatedContent#</tr>
</cfoutput>
</cfif>
<cfset thistag.generatedcontent = "">