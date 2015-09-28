/**
	rb_plugger.PluginManager

	Add lightweight plugin capability to applications supporting plugin dependencies and
	extension points.

	Plugins should be thought of as static singletons whose extension points are
	accessed via the plugin manager. You cannot access the plugin instances themselves,
	which maintains encapsulation between plugins.

	Plugin classes implementing rb_plugger.IPluginContextInject will receive references to the
	plugin manager and the enclosing plugin instance, the latter being shared with the other
	classes belonging to the plugin.

	Application.cfc can optionally extend PluginManager to automatically register plugins
	and provide a base extension point rb_plugger.application, an instance of
	rb_plugger.IApplication

	Additional Application.cfc properties:

	this.pluginMappingPath	    List of root packages scanned for plugins
	this.excludedPluginMappings List of package prefixes skipped for plugins,
								default rb_plugger.test
	this.reloadKey				URL key to force call to onApplicationStart()
	this.docKey                 URL key to dump documentation page on installed plugins

	(c) RocketBoots Pty Limited 2014

	This file is part of Plugger.

    Plugger is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of
    the License, or (at your option) any later version.

    Plugger is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Plugger.  If not, see
    <http://www.gnu.org/licenses/>.
 **/

component {

	/********************************
		Private instance variables
	 ********************************/

	stPlugins = {};
	stExtensionPoints = {};



	/********************
		Public methods
	 ********************/



	/**
		Scan a list of packages for plugin.cfm files and build the list of
		plugins and extension points

		@param 	pluginMappingPath		    Optional comma separated list of packages to
											recursively search in for plugin.cfm
											Default behaviour is to expand "/" CF mapping.
		@param  excludedPluginMappings      Optional comma separates list of package prefixes
											to skip, default "rb_plugger.test"
		@thows	MISSING_PLUGIN_MAPPING		If it can't find a package in pluginMappings
		@thows	MISSING_PLUGIN_DEPENDENCIES	If a plugin required by another plugin is missing
		@throws INCOMPATIBLE_PLUGIN_VERSION If two plugins require incompatible versions of a
											third plugin
	 **/
	public PluginManager function init(string pluginMappingPath = "/",
								string excludedPluginMappings = "rb_plugger.test") {

		var aPluginTemplates = pluginTemplateList(pluginMappingPath, excludedPluginMappings);
		var missingPlugins = {};   // Set of dependencies missing when plugins were added
		var dependencyOrder = 1;
		var pluggerPlugin = new Plugin(this, "", "rb_plugger", "0.0.0");

		var aPluginsOrderedByDependency = fold(aPluginTemplates,

			function(pluginTemplateMapping, plugins) {
				var plugin = new Plugin(this, pluginTemplateMapping);
				var requiredPlugins = plugin.getRequiredPlugins();
				var nextPlugin = 0;
				var version = [];
				var i = 0;

				// Find an index after the plugin's dependencies to insert it
				while (i++ < plugins.len() and requiredPlugins.len() > 0) {
					nextExistingPlugin = plugins[i];

					// Only count the dependency as met if the version is ok, assuming backwards
					// compatibility for patches and minor versions but not major versions
					if (requiredPlugins.keyExists(nextExistingPlugin.getPackage())
							and nextExistingPlugin.getMajorVersion() eq requiredPlugins[nextExistingPlugin.getPackage()].getMajorVersion()
							and nextExistingPlugin.getMinorVersion() ge requiredPlugins[nextExistingPlugin.getPackage()].getMinorVersion()
							and nextExistingPlugin.getPatchVersion() ge requiredPlugins[nextExistingPlugin.getPackage()].getPatchVersion()) {

						requiredPlugins.delete(plugins[i].getPackage());
					}
				}

				plugins.insertAt(i, plugin);                // Insert new plugin

				// Add remaining required dependencies to overall missing list, checking
				// for incompatible plugin version dependency combinations

				new Collection(requiredPlugins).each(
					function (requiredPlugin) {
						var missingVersion = 0;
						var requiredVersion = 0;

						if (not missingPlugins.keyExists(requiredPlugin.key)) {
							// Inital insert, so no compatibility issues
							missingPlugins[requiredPlugin.key] = requiredPlugin.value;

						} else {

							if (missingPlugins[requiredPlugin.key].getMajorVersion() neq
								requiredPlugin.value.getMajorVersion()) {
								// Incompatible major versions
								throw(errorcode="INCOMPATIBLE_PLUGIN_VERSION",
									detail="Plugin #plugin.getPackage()# requires #requiredPlugin.value.getPackage()# #requiredPlugin.value.getVersion()# but incompatible version #missingPlugins[requiredPlugin.key].getVersion()# is required by another plugin.")

							} else {
								// If the required version has higher minor/patch version, update
								// the missing plugin version to match.
								if (
									(
										(missingPlugins[requiredPlugin.key].getMinorVersion() * 10000) +
										missingPlugins[requiredPlugin.key].getPatchVersion()
									) lt (
										(requiredPlugin.value.getMinorVersion() * 10000) +
										requiredPlugin.value.getPatchVersion()
									)
								) {
									missingPlugins[requiredPlugin.key].setVersion(requiredPlugin.value.getVersion());
								}
							}
						}
					}
				);

				// Remove new plugin from missing dependencies if it was there and version is compatible
				if (missingPlugins.keyExists(plugin.getPackage())
						and plugin.getMajorVersion() eq missingPlugins[plugin.getPackage()].getMajorVersion()
						and plugin.getMinorVersion() ge missingPlugins[plugin.getPackage()].getMinorVersion()
						and plugin.getPatchVersion() ge missingPlugins[plugin.getPackage()].getPatchVersion()) {

					missingPlugins.delete(plugin.getPackage());
				}

				return plugins;
			},

			[]);

		if (missingPlugins.len() > 0) {
			throw(errorcode="MISSING_PLUGIN_DEPENDENCIES",
				detail="Required plugin(s) #new Collection(listToArray(missingPlugins.keyList())).map(
						function(d) {
							return missingPlugins[d].getPackage() & " " & missingPlugins[d].getVersion()
						}).toList()# missing");
		}

		stPlugins = {};
		stExtensionPoints = {};

		// Add built-in plugin and extension point
		stExtensionPoints["plugger.application"] =
			new ExtensionPoint(this, pluggerPlugin, "plugger.application", "rb_plugger.IApplication");

		// With the plugins in dependency order we can safely register and validate extension points
		aPluginsOrderedByDependency.each(
			function(plugin) {
				plugin.registerExtensionPoints(stExtensionPoints);
				plugin.setDependencyOrder(dependencyOrder++);
				stPlugins[plugin.getPackage()] = plugin;
			}
		);

		application.pm = this;
		return this;
	}



	/**
		Return a collection of extensions for an extension point

		@param name Extension point name (package format)
		@returns Collection
		@throws NO_SUCH_EXTENSION_POINT
	 **/
	public Collection function getExtensionPoint(string name) {
		if (stExtensionPoints.keyExists(name))
			return stExtensionPoints[name].getCollection();
		else
			throw(errorcode="NO_SUCH_EXTENSION_POINT",
				detail="getExtensionPoint(): non-existent extension point '#name#'");
	}



	/**
		Check if anyone extended an extension point

		@param name Extension point name to check (package format)
		@returns true if there is at least one extension
		@throws NO_SUCH_EXTENSION_PONT
	 **/
	public boolean function wasExtended(string name) {
		if (stExtensionPoints.keyExists(name))
			return stExtensionPoints[name].getArray().len() gt 0;
		else
			throw(errorcode="NO_SUCH_EXTENSION_POINT",
				detail="getExtensionPoint(): non-existent extension point '#name#'");
	}


	/**
		@returns HTML string describing installed plugins
	 **/
	public string function getDocumentation() {
		module template="/rb_plugger/documentation_page_template.cfm" {
			stPlugins.keyArray().sort("text", "asc").each(
				function(key) {
					plugin = stPlugins[key].toStruct();

					savecontent variable="requires" {
						plugin.requires.each(
							function(key) {
								required = plugin.requires[key];
								writeOutput("<tr><td>#required.package#</td><td>#required.version.toList(".")#</td></tr>");
							}
						);
					}

					savecontent variable="extends" {
						plugin.extends.each(
							function(key) {
								writeOutput("<tr><td>#key#</td><td>#plugin.extends[key]#</td></tr>");
							}
						);
					}

					savecontent variable="provides" {
						plugin.provides.each(
							function(key) {
								writeOutput("<tr><td>#key#</td><td>#plugin.provides[key]#</td></tr>");
							}
						);
					}
					module template="/rb_plugger/documentation_plugin_template.cfm"
						plugin="#plugin#" requires="#requires#" extends="#extends#" provides="#provides#";
				}
			);
		};
		abort;
	}



	/*******************************************************************
		Application.cfc callbacks

		TODO: add following as we need them:
		void function onSessionStart() {}
		void function onCFCRequest(string cfcname, string method, struct args) {}
		void function onError(struct exception, string eventName) {}
		void function onSessionEnd(struct sessionScope, struct applicationScope) {}
		void function onApplicationEnd(struct applicationScope) {}

		@see Adobe Application.cfc documentation adobe.ly/8L79rV
	 *******************************************************************/



	/**
		Load plugins and tell them about the application starting.
		Continue processing if all the plugins return true to continue

		@returns boolean true to continue processing request
	 **/
	public boolean function onApplicationStart() {
		param name="this.pluginMappingPath" default="/";
		param name="this.excludedPluginMappings" default="";

		// load plugins
		init(this.pluginMappingPath, this.excludedPluginMappings);

		// Notify interested plugins of onApplicationStart event
		return application.pm.getExtensionPoint("plugger.application").fold(
			function(rb_plugger.IApplication impl, boolean bContinue = true) {
				return bContinue and impl.onApplicationStart();
			},
			true
		);
	}



	/**
		Check for special reload or documentation requests, tell interested plugins about the
		request starting and continue processing the request if they all return true

		@returns boolean true to continue processing the request
	 **/
	public boolean function onRequestStart() {
		param name="this.reloadKey" default="reload";
		param name="this.docKey" default="doc";

		if (structKeyExists(url, this.reloadKey)) {
			onApplicationStart();
		}

		if (structKeyExists(url, this.docKey)) {
			writeOutput(application.pm.getDocumentation());
		}

		// Notify interested plugins of onRequestStart event
		return application.pm.getExtensionPoint("plugger.application").fold(
			function(IApplication impl, boolean bContinue) {
				return bContinue and impl.onRequestStart();
			},
			true
		);
	}



	/**
		If no-one extended plugger.application then throw an error for a missing template.
		Otherwise check to see that all plugins agree that the request should be processed,
		and if they do carry out a normal request.

		@returns boolean false to throw an error
	 **/
	public boolean function onMissingTemplate(string targetPage) {
		if (application.pm.wasExtended("plugger.application")) {
			return application.pm.getExtensionPoint("plugger.application").fold(
				function(IApplication impl, boolean bContinue) {
					return bContinue and impl.onMissingTemplate(targetPage);
				},
				true
			);

		} else {
			// default is to throw error on a missing template
			return false;
		}
	}



	/**
		Let plugins react to onRequest
	 **/
	public void function onRequest(string targetPage) {

		// Plugins first
		application.pm.getExtensionPoint("plugger.application").each(
			function(IApplication impl) {
				impl.onRequest(targetPage);
			}
		);

		try {
			// Then originally requested page
			include "#targetPage#";

		} catch ("missinginclude") {
			// Handle missing template
			if (not onMissingTemplate(targetPage))
				rethrow;
		}

	}



	/**
		Let plugins react to onRequestEnd
	 **/
	public void function onRequestEnd(string targetPage) {
		application.pm.getExtensionPoint("plugger.application").each(
			function(IApplication impl) {
				impl.onRequestEnd(targetPage);
			}
		);
	}



	/**
		Private helper methods
	 **/



	/**
		Return an array of plugin.cfm mappings suitable for passing
		to cfinclude.

		@param pluginMappingPath		    List of packages to recursively search in for plugin.cfm
											specified in dot notation
		@param excludedPluginMappings       List of package prefixes to skip, default "rb_plugger.test"
											(because the test suite contains deliberately failing plugin
											configurations)
		@returns array of "/../../plugin.cfm" strings
		@throws MISSING_PLUGIN_MAPPING
	 **/
	private array function pluginTemplateList(string pluginMappingPath, string excludedPluginMappings) {
		var pluginTemplates = "";
		var rootMappingDir = expandPath("/");

		excludedPluginMappings = listToArray(replace(excludedPluginMappings, ".", "/", "all"));

		listToArray(pluginMappingPath).each(
			function (mapping) {

				// Convert to
				var path = expandPath("/#replace(mapping, ".", "/", "all")#");
				writeLog("PATH #path#");
				if (not directoryExists(path)) {
					throw(errorcode="MISSING_PLUGIN_MAPPING",
						detail="Mapping #mapping# does not resolve to a valid directory");
				}

				directory action="list" name="qPlugins" directory="#path#" recurse="true" filter="plugin.cfm";
				pluginTemplates = listAppend(pluginTemplates, valueList(qPlugins.directory));
			}
		);

		return map(listToArray(replaceNoCase(pluginTemplates, rootMappingDir, "", "all")).filter(
			function (mapping) {
				return fold(excludedPluginMappings,
					function(excludedMapping, flag) {
						return flag and not mapping contains excludedMapping
					},
					true);
			}
			),
			function(mapping) {
				return "/#mapping#/plugin.cfm";
			});
	}



	/**
		Map a function over an array of items, returning an array of results

		@param  input   array
		@param  fn      Function taking a single item argument and returning
						mapped value
		@returns array of fn return values
	 **/
	private array function map(array input, fn) {
		var output = [];

		input.each(function(item) {arrayAppend(output, fn(item))});
		return output;
	}



	/**
		Reduce an array of items to a single return value using a function

		@param input    array
		@param initial  initial output value
		@param fn       Function with the signature:
							fn(item, output)
		@returns Last output value
	 **/
	private any function fold(array input, fn, initial) {
		var result = initial;

		input.each(function(item) {result = fn(item, result)});
		return result;
	}

}