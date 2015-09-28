/**
	An extensible plugger plugin that writes an HTML shopping list in response
	to any request.

	The list of shopping items is built from contributions made by other plugins extending
	the shopping_list.shops extension point. Each item's quantity is then converted into
	multiple units, the translation and formatting carried out by plugins extending
	shopping_list.units.

 **/
component implements="rb_plugger.IApplication,rb_plugger.IPluginContext" {

	import rb_plugger.Collection;



	/**
		IPluginContextInject implementation to get references to plugin manager
		and plugin

		@param pluginManager    The application plugin manager instance
		@param pluginContext    Plugin instance shared within the plugin
	 **/
	public void function setContext(PluginManager pluginManager, Plugin pluginContext) {
		writeLog("ShoppingListApplication.setContext()");
		manager = pluginManager;
		plugin = pluginContext;
	}



	/*********************************
		IApplication implementation
	 *********************************/



	public boolean function onApplicationStart() {
		writeLog("ShoppingListApplication.onApplicationStart()");
		request.shoppingListOnApplicationStart = true; // For tests
		return true;
	}



	/**
		Build a shopping list model using contributions from plugins extending
		our extension points:

		-   request.shoppingList

			[
				{
					name = "Butcher",
					items = [
						{
							name = "Lean Mince",
							quantity = ["250g", "4oz"]
						},
						...
					]
				},
				...
			]

		-   request.shoppingListUnitNames

			["Metric", "Imperial"]
	 **/
	public boolean function onRequestStart() {
		writeLog("ShoppingListApplication.onRequestStart()");
		request.shoppingListOnRequestStart = true; // For tests
		// Build Model
		request.shoppingList = manager.getExtensionPoint("shopping_list.shops").map(
			function(IShop shop) {
				return {
					name = shop.name(),
					items = new Collection(shop.itemQuantities()).map(
						function (struct item) {
							return {
								name = item.name,
								quantity = manager.getExtensionPoint("shopping_list.units").map(
									function (IUnit unit) {
										switch(item.by) {
											case "weight":
												return unit.weight(item.quantity);
											case "volume":
												return unit.volume(item.quantity);
											case "length":
												return unit.length(item.quantity);
											default:
												return item.quantity;
										}
									}
								) // quantity
							};
						}
					) // items
				};
			}
		);

		request.shoppingListUnitNames = manager.getExtensionPoint("shopping_list.units").map(
			function (IUnit unit) {
				return unit.name();
			}
		);

		return true;
	}



	public void function onRequest(string targetPage) {
		writeLog("ShoppingListApplication.onRequest(#targetPage#)");
		request.shoppingListOnRequest = true;
	}



	public void function onRequestEnd(string targetPage) {
		writeLog("ShoppingListApplication.onRequestEnd(#targetPage#)");
		request.shoppingListOnRequestEnd = true;    // For tests
		module template="#plugin.getMapping()#/view/page.cfm" {
			request.shoppingList.each(
				function(struct shop) {
					savecontent variable="unitHeaders" {
						request.shoppingListUnitNames.each(function(unit) {writeOutput("<th width='100'>#unit#</th>")});
					}
					module template="#plugin.getMapping()#/view/shop.cfm" shop="#shop#" unitHeaders="#unitHeaders#" {
						shop.items.each(
							function(struct item) {
								module template="#plugin.getMapping()#/view/item.cfm" item="#item#" {
									item.quantity.each(
										function(string quantity) {
											writeOutput("<td>#quantity#</td>");
										}
									)
								}
							}
						);
					}
				}
			);

		}
	}



	public boolean function onMissingTemplate(string targetPage) {
		writeLog("ShoppingListApplication.onMissingTemplate(#targetPage#)");
		request.shoppingListOnMissingTemplate = true; // For tests
		return true;   // This plugin is ok with missing templates
	}


	// TODO: Make a DefaultApplication class to save us from implementing entire interface

	public void function onSessionStart() {}

	public void function onCFCRequest(string cfcname, string method, struct args) {}

	public void function onError(struct exception, string eventName) {}

	public void function onSessionEnd(struct sessionScope, struct applicationScope) {}

	public void function onApplicationEnd(struct applicationScope) {}
}