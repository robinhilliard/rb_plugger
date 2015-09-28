<cfoutput>
<p>The #plugin("Shopping List", "1.2.3")# plugin appends an HTML shopping list to a response. It extends
#extends("plugger.application", "rb_plugger.test.plugins.shopping_list.ShoppingListApplication")#
and allows specific types of shop to contribute to the list by extending the
#provides("shopping_list.shops", "rb_plugger.test.plugins.shopping_list.IShop")# extension point.
The quantities of each item in the shopping list are listed in multiple units. Unit types are added by
extending the #provides("shopping_list.units", "rb_plugger.test.plugins.shopping_list.IUnit")#
extension point.</p>
</cfoutput>