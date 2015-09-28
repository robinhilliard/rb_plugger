# Plugger
> This vast similitude spans them, and always has spann’d, and shall forever span them, and compactly hold them, and enclose them - Walt Whitman 1819-1892



Plugger is a CFML (Railo 4, possibly ColdFusion 10 but not tested) framework that allows discreet "plugin" modules of code to be automatically discovered and combined to form larger applications. 

The modules interact via "extension points" - named points in the publishing module's process at which other modules can contribute additional behaviour. It is similar idea to the Observer pattern in that multiple modules extend a single extension point, but no concept of events is involved, and it is left to the publisher to establish a protocol with which to communicate with its subscribers, typically by asking them to implement a common interface. 

Plugger includes the following features:

- Autodiscovery of modules via a per-module `plugin.cfm` file, which allows the module to declare:
 - Its name and version
 - Dependencies on other plugins
 - Published extension points
 - Extension points of other plugins to which it subscribes, and
 - The classes to which the publisher should delegate extension point implementations to.  
- Dependencies, versions and extension points are fully validated when the application starts, and configuration errors are clearly reported.
- Classes implementing extension points can implement an interface that allows context information to be injected into instances, allowing access to extension points  and a scope shared between implementation instances in the same plugin
- Plugger provided powerful support for publishers to iterate over extensions with closures and high-order functions like `each`, `map`, `fold`, `partition` and more, greatly streamlining the implementation of extension point behaviours.
- Application.cfc can extend a Plugger class to automatically discover and register plugins, using settings specified in the "this" scope alongside normal application settings.
- Plugger provides a default application extension point, which allows modules to respond to application events like `onApplicationStart`. These extension points try to let all extending modules contribute to the behaviour, for instance polling them all to determine the true/false return value of `onRequestStart`.
- Plugins do not need to publish or subscribe to extension points - they may simply provide libraries of classes, templates and other resources required by other modules.
- Automatically generated documentation. If preferred the `plugin.cfm` file can be written cfwheels-style with the declarations in-line in the text, and this text will be included in the documentation.
- A full suite of unit tests.

## Quick Start Tutorial
This tutorial walks through the creation of part of the application included with the plugger test suite. The full sample application can be found in the `rb_plugger/test/plugins` directory included in the distribution. Note that the directory naming convention with underscores and 'I' prefix for interfaces are not required for plugger, but the `rb_plugger` mapping is required for plugger to find its own components. The tutorial also recognises that some CFML developers may be unfamiliar with component interfaces and includes some additional explanation when they are introduced.

Our sample, very contrived application is a shopping list. The developers charge double-time-and-a-half danger money to refactor existing code so once we write some code, we want to avoid changing it at all costs. However the (somewhat paranoid) business analyst can see changes in the future and we need to cater for these changes.

> Open for extension, closed for modification - Head First Design Patterns

The shops we visit will change and grow over time, so we'll want to isolate each shop into a separate module so that the shopping list application can easily be extended without modifications to its code.

The quantities of various items on the list will be represented in metric units, but to appeal to backward countries still using imperial units a century after the introduction of the metric system we will list the quantities in multiple units. Since other measuring systems may emerge over time we will isolate each measurement system into a separate module which will then extend the core shopping list application.

### Bootstraping Plugger
For convenience we will use the `Application.cfc` behaviour built into the `PluginManager` class to handle the bootstrapping of our collection of modules:


				component extends="rb_plugger.PluginManager" {
					this.name = "plugger_sample";
					this.applicationtimeout = createTimespan(2, 0, 0 ,0);
					this.pluginMappingPath = "mapping.to.plugins,another.mapping";
				}

After the usual variables set `this.pluginMappingPath` to a comma-separated list of CFML mappings that will be recursively searched for plugin modules to register. Like any CFML mapping these do not have to be under the web root. Use `.` not `/` to separate mapping directories, as you might for component names. You can also specify mappings to skip using `this.excludedPluginMappings`.

It is also possible to create your own `PluginManager` instance, passing plugin paths to the constructor. There is no restriction on the number of `PluginManager` instances you can create, but if you are using the `Application.cfc` methods an `application.pm` variable will be created, holding a reference to the `PluginManager` used by the application.

From this point on everything we create will be part of a plugin module, starting with our core shopping_list module.

### The Shopping List Module

Under one of the directories listed in your pluginMappingPath create a folder called shopping_list, and in it a file named plugin.cfm:

				<cfoutput>
				<p>The #plugin("Shopping List", "1.2.3")# plugin appends an HTML shopping list to a response. It extends
				#extends("plugger.application", "shopping_list.ShoppingListApplication")#
				and allows specific types of shop to contribute to the list by extending the
				#provides("shopping_list.shops", "shopping_list.IShop")# extension point.
				The quantities of each item in the shopping list are listed in multiple units. Unit types are added by
				extending the #provides("shopping_list.units", "shopping_list.IUnit")#
				extension point.</p>
				</cfoutput>

We're using the cf-wheels inline `#function()#` style to describe our plugin module - you could just call the functions one-after-another in a `<cfscript>` block, but this is better for an introduction, and the resulting text is included in the generated documentation, which can help to prevent the documentation getting out of sync regarding extension point names and such. Remember if you're using this style to include the `<cfoutput>` tags or the functions won't run and your plugin won't work.

You can use the following functions in `plugin.cfm`:

#### plugin(pluginName, version)

Declare the human-readable name of the plugin and the version in `major.minor.patch` format. When validating dependencies Plugger assumes that to be compatible the major version must match the required version, and that minor/patch versions are backwards-compatible. So in the case above if another plugin required shopping list `1.0.0`, `1.2.3` would be acceptable, but `0.9.1` or `2.0.0` would not. However If the other plugin required shopping list `1.2.4`, `1.2.3` would not be considered compatible.

#### extends(extensionPointName, componentName )

Our plugin extends the uniquely named extension point with the CFC named by the second argument. The extension point namespace is independent of mappings and full-stops have no special significance, but it's a good idea to use a prefix unique to each module to prevent collisions.

The component needs to meet any type constraints specified by the extension point declaration or an error will be thrown.

#### provides(extensionPointName, optionalType)

Our plugin is declaring the existence of the named extension point, and optinally the name of the required type for components provided by other plugins to implement the extension point. Normally this would be an interface or abstract base class belonging to the current plugin module.

There is one remaining function that we will discuss when we use it in the next plugin module.

Back to our `plugin.cfm`. We want to respond to application events, which we can do by extending the special built-in extension point `plugger.application` with a new component. Components extending this extension point need to implement the `rb_plugger.IApplication` interface which will look familiar to CFML developers:
				
				interface {
					boolean function onApplicationStart() {}
					void function onSessionStart() {}
					boolean function onRequestStart() {}
					void function onRequest(string targetPage) {}
					void function onCFCRequest(string cfcname, string method, struct args) {}
					boolean function onMissingTemplate(string targetPage) {}
					void function onError(struct exception, string eventName) {}
					void function onRequestEnd(string targetPage) {}
					void function onSessionEnd(struct sessionScope, struct applicationScope) {}
					void function onApplicationEnd(struct applicationScope) {}
				}

We will write a component implementing this interface shortly.

We then declare two extension points of our own, `shopping_list.IShop` for shops and `shopping_list.IUnit` for measurement systems that will be extended by other plugin modules. These are CFML interface names so in our `shopping_list` folder next to `plugin.cfm` we'll need to create `IShop.cfc`:

				interface {
				
					/**
						@returns human-readable name of the shop
					 **/
					string function name() {}
				
				
				
					/**
						@returns    An array of structs representing items and quantities to purchase in
									SI units where applicable (grams, ml, m - doesn't apply for count).
				
									[
										{name= "Bacon", quantity= 500, by="count|weight|volume|length"},
										...
									]
					 **/
					array function itemQuantities() {}
				}

and `IUnit.cfc`:

				interface {
				
					/**
						@returns    Human-readable name of unit e.g. "Metric"
					 **/
					string function name() {}
				
				
				
					/**
						@returns    Human-readable weight description, performing
									necessary conversion from grams eg "12 oz"
					 **/
					string function weight(numeric quantity) {}
				
				
				
					/**
						@returns    Human-readable volume description, performing
									necessary conversion from millilitres e.g "2 gal"
					 **/
					string function volume(numeric quantity) {}
				
				
				
					/**
						@returns    Human-readable length description, performing
									necessary conversion from metres, e.g. "2 ft"
					 **/
					string function length(numeric quantity) {}
				
				}

Note that they are interfaces, not components. Interfaces specify a list of methods that implementing components must match when they are compiled. It is important that the interface 'belongs' to shopping_list and the implementations 'belong' to the other plugin modules - `shopping_list` is saying "you can extend this extension point, but you have to promise to implement these methods as written in my specification because I will expect them to be there when I call you".

We now turn to the implementation of `ShoppingListApplication`, starting with the component header and first method:

				component implements="rb_plugger.IApplication,rb_plugger.IPluginContext" {
				
					/**
						IPluginContextInject implementation to get references to plugin manager
						and plugin
				
						@param pluginManager    The application plugin manager instance
						@param pluginContext    Plugin instance shared within the plugin
					 **/
					public void function setContext(PluginManager pluginManager, Plugin pluginContext) {
						manager = pluginManager;
						plugin = pluginContext;
					}

To indicate that a component is implementing a list of interfaces use the `implements="…"` attribute in the component header. Note that this is different to the `extends="…"` attribute which can only reference a single superclass. Also note that interfaces never add behaviour to a component themselves, they just specify that the component is responsible for providing the behaviour.

This component implements `rb_plugger.IApplication` as required by the `plugger.application` extension point, but it also implements `rb_plugger.IPluginContext`. This interface specifies a single `setContext(pluginManager, pluginContext)` method, which Plugger will check for and call when your component instance is created. 

Most components will want to implement `IPluginContext` because the `PluginManager` and `Plugin` components are useful.

#### PluginManager

This is the instance of PluginManager that you used to bootstrap Plugger. If you used the `Application.cfc` methods, this also happens to be the instance stored in `application.pm`, but you should never refer to it directly, in fact plugin modules should avoid the application scope altogether to preserve their encapsulation, which is the whole point of using Plugger in the first place.

PluginManager provides the `getExtensionPoint(extensionPointName)` method, used by all plugins which publish an extension point. This method returns a `Collection` of component instances that extend the extension point. 

#### Plugin

Each plugin module registered by Plugger has a a single `Plugin` instance shared between all the component instances in that plugin module created to extend extension points. This instance can be used as an alternative to the application scope to share plugin settings and resources, and also has accessor methods to gain access to `plugin.cfm` metadata, including:

					getName()
					getPackage()
					getMapping()
					getPath()
					getVersion()
					getMajorVersion()
					getMinorVersion()
					getPatchVersion()
					toStruct()

That wraps up the implementation of `IPluginContext`. To start with the implementation of `IApplication` we can copy all the method signatures from the interface into `ShoppingListApplication.cfc` and prefix each with a `public` access modifier.

When the request arrives we want to create a model in the request scope representing our shopping list. The shopping list will be composed of contributions from plugin modules extending the `shopping_list.shop` extension point. Then for each item on the list we need to convert the quantity into various measuring systems implemented by plugin modules extending the `shopping_list.unit` extension point. We will also need the names of the measurement systems for the column headers.

Here is an `onRequestStart()` method to do this:

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

This code makes use of the `Collection.map()` method to iterate over the shop and unit plugin modules and build their contributions into the model. `map()` iterates over the items in a collection, in this case instances of `shopping_list.IShop` and `shoppingList.IUnit`, and creates a new collection out of the return values of the closure passed to the method.

The `onRequestEnd()` method can be modified to render this model to HTML, but we won't cover that in this tutorial as it doesn't use any features of Plugger - you can dump the request scope for now if you like. You can see a finished example in `rb_plugger/test/plugins/shopping_list/ShoppingListApplication.cfc` and `rb_plugger/test/plugins/shopping_list/view`.

You will need to reload Plugger to register your new plugin. In your Application.cfc add `this.reloadKey=reset`  and `this.docKey=doc` (pick your own obsfucated keys for security, especially in production). If you add a reset key to your URL it will now cause Plugger to reload its plugins. If you add a doc key to your URL Plugger will list the details of the loaded plugin modules for your debugging pleasure.

### The Hardware Shop Module

Next to the `shopping_list` folder create a `hardware_shop` folder containing the following `plugin.cfm`:

				<cfoutput>
				<p>The #plugin("Hardware Shop", "1.0.0")# plugin extends
				#extends("shopping_list.shops", "hardware_shop.HardwareShop")#
				to add shopping list items from a hardware shop. It requires the
				#requires("shopping_list", "1.0.0")# plugin.</p>
				</cfoutput>

You can see that this plugin extends the `shopping_list.shops` extension point with a `hardware_shop.HardwareShop` component that we will need to create. You can also see a new function `requires(pluginName, version)`, used to create dependencies between plugin modules. Dependencies are independent of extension points because modules can depend on others for components, interfaces, templates and other resources, regardless of whether or not they extend their extension points.

Note that the required version of the shopping list plugin module is `1.0.0`, but in the `plugin.cfm` for shopping list we said the version was `1.2.3`. Because the major version number is the same, and the required minor/patch versions are lower than the installed plugin module, this is considered backwards-compatible for the requirement.

We can now implement the `shopping_list.shop` extension point:

				component implements="shopping_list.IShop" {
				
					/**
						@returns human-readable name of the shop
					 **/
					string function name() {
						return "Hardware";
					}
				
				
				
					/**
						@returns    An array of structs representing items and quantities to purchase
					 **/
					array function itemQuantities() {
						return [
							{name="9mm Marine Ply 1200&times;2400", quantity=5, by="count"},
							{name="2&times;4 Radiata Pine", quantity=20, by="length"},
							{name="Decking Oil", quantity=3000, by="volume"}
						];
					}
				
				}

This is pretty straightforward. We implement `shopping_list.IShop` as required by the extension point and provide a shop name and list of items to add to the shopping list.

The application should now render the hardware store items the the HTML response, but the quantities will be missing because we have not implemented any extensions to `shopping_list.units`.

### The Imperial Units Module

To finish off the tutorial, next to the two existing plugin module folders create an `imperial_units` folder containing the following `plugin.cfm`:

				<cfoutput>
				<p>The #plugin("Imperial Units", "1.0.0")# plugin extends
				#extends("shopping_list.units", "imperial_units.ImperialUnits")#
				to display quantities in imperial units. It requires the
				#requires("shopping_list", "1.0.0")# plugin.</p>
				</cfoutput>

This is just like the hardware store, except that we're extending the `shopping_list.units` extension point. Our implementation component `ImperialUnits.cfc` looks like this:

				component implements="shopping_list.IUnit"{
				
					/**
						@returns    Human-readable name of unit e.g. "Metric"
					 **/
					string function name() {
						return "Imperial";
					}
				
				
				
					/**
						@returns    Human-readable weight description, performing
									necessary conversion from grams eg "12 oz"
					 **/
					string function weight(numeric quantity) {
						return "#round(quantity * 0.035274)#oz";
					}
				
				
				
					/**
						@returns    Human-readable volume description, performing
									necessary conversion from millilitres e.g "2 gal"
					 **/
					string function volume(numeric quantity) {
						return "#round(quantity * 0.033814)# fl oz";
					}
				
				
				
					/**
						@returns    Human-readable length description, performing
									necessary conversion from metres, e.g. "2 ft"
					 **/
					string function length(numeric quantity) {
						return "#round(quantity * 3.28083)#ft";
					}
				
				}

You will now see that the decking oil and radiata pine quantities are given in fluid ounces and feet respectively. This wraps up the tutorial. You can add your own shops and units indefinitely, without changing any existing code.

# More About Collections

To ensure that working with extension points is at least as easy as working without extension points (and hopefully easier) the Collection class provides high-level functions for manipulating collections of things, similar to those found in functional programming languages and frameworks like Underscore. Here is a quick summary of the available methods - refer to `rb_plugger/test/TestCollection.cfc` for running examples:

### new Collection(items, separator or type)

`items` is an array, list, query or struct to be wrapped by the Collection. Query rows are converted to structs, and struct entries are converted to `{key = ..., value = ...}` structs. If `items` is a list, the second argument contains the list separator character(s), defaulting to ','. If `items` is not a list and a second argument is specified, it is the name of a type which all the items must match. The options are:

- simple
- numeric
- array
- struct
- query
- _class or interface name_

It the type of one of the items does not match a `TYPE_MISMATCH` error is thrown. Collection elements can be accessed using `[]` notation, but remember that Collections are immutable, that is the elements cannot be changed once the Collection has been created.

### map(fn, asCollection = true)
`fn` is a closure taking a single item from the collection as an argument, and returning a derived value. The return value of `map()` is a new Collection containing the closure return values corresponding to the original Collection items.  If `asCollection` is false the result the same as `map(…).toArray()`. 

### fold(fn, initialResult)
`fn` is a closure taking two arguments, an item from the collection and a result value returned from the previous call to `fn` . The second argument passed to `fold()`, `initialResult` is the value passed to the first call to `fn` as result. The return value from `fold()` is the value returned from the final call to `fn`.

### each(fn)
This is the same as Railo's built-in `each()` member method.

### toArray()
Return the items in the collection as an array. Performant as an array is the representation used for the items in the Collection class.

### toList(separator = ",")
Return the items in the collection as a list. Will fail if the Collection contains non-simple items.

### len()
This is the same as Railo's built-in `len()` member method.

### filter(fn)
Return a new Collection of items for which the closure `fn` returned true when the item was passed to it.

### count(fn)
Return a count of how many items, when passed to the closure `fn`, caused it to return true.

### none(fn)
Return true if none of the items in the Collection caused `fn` to return true when passed to the closure.

### any(fn)
Return true if any of the items in the Collection caused `fn` to return true when passed to the closure.

### all(fn)
Return true if all of the items in the Collection caused `fn` to return true when passed to the closure.

### partition(fn)
The closure `fn`, when passed an item from the Collection, must return a simple key for that item that
could be used in a struct (note that this includes booleans). The `partition()` function returns a structure
grouping items in Collections under the keys returned by the closure when called with each item. You can
use this instead of `filter()` to return a `{true = ..., false = ...}` pair of Collections, or group items
by date ranges, hashes or other useful keys.

# Roadmap

The following features are planned for Plugger:

- pom.xml parsing - plugin properties default to pom versions and names if one is present.
- Supporting plugin modules for prioritised responses to the `plugger.application` extension point.

# How to Test
Plugger has been tested with MXUnit 2.1.3 on Railo 4.1.1.009. To test:

- Install MXUnit by placing the `mxunit` folder under your web root.
- Ensure that the `/rb_plugger` mapping points to the root Plugger folder
- Browse to the MXUnit test runner and click Run Tests with the directory set to `/rb_plugger/test` and component path set to `rb_plugger.test`.

# How to Build

The modules follows the build standard adopted by RocketBoots and thus can be packaged and deployed in the standard fashion. Please follow this standard for packaging and deploying the module to a central repository.

# Dependency Management

To use this module include the following dependency in your application/module pom.xml file:


	<dependency>
		<groupId>com.rocketboots</groupId>
		<artifactId>rb-plugger</artifactId>
		<version>{version}</version>
		<packaging>zip</packaging>
	</dependency>


# Module Structure
