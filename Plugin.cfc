/**
	rb_plugger.Plugin

	Wrap plugin.cfm with accessor, helper and validation methods.

	(c) 2014 RocketBoots Pty Limited

	Plugger is a CFML framework that allows discreet 'plugin'
	modules of code to be automatically discovered and combined to
	form larger applications.  See the README for usage.

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

	_manager = 0;
	_name = "";
	_package = "";
	_path = "";
	_version = "0.0.0";
	_requires = {};
	_provides = {};
	_extends = {};
	_description = "";
	_dependencyOrder = 0;


	/********************
		Public methods
	 ********************/



	/**
		Read plugin properties from a plugin.cfm

		@param 	pluginTemplateMapping
	 **/
	public Plugin function init(PluginManager pluginManager, string pluginTemplateMappingPath = "", string package = "", string version = "") {
		_mapping = getDirectoryFromPath(pluginTemplateMappingPath);
		_manager = pluginManager;
		_name = "";
		_requires = {};
		_provides = {};
		_extends = {};
		_path = expandPath(_mapping);
		_dependencyOrder = 0;

		if (package neq "")
			_package = package;
		else
			_package = replace(mid(_mapping, 2, len(_mapping) - 2), "/", ".", "all");

		if (version neq "")
			_version = version;
		else
			_version = "0.0.0";

		// Load the plugin template inline, saving the generated string
		if (pluginTemplateMappingPath neq "") {
			savecontent variable="_description" {include "#pluginTemplateMappingPath#";}
		}

		return this;
	}



	/**
		Register extension points we provide, then try to extend
		other plugin's extension points with our extensions. Relies on
		PluginManager doing this in dependency order.

		@param register struct keyed by extension point name, containing
						ExtensionPoint instances, for us to append to and
						look in for other plugin's extension points
		@throws NO_SUCH_EXTENSION_POINT
		@throws PLUGIN_TYPE_MISMATCH
	 **/
	public void function registerExtensionPoints(struct register) {
		_provides.keyArray().each(
			function (key) {
				register[key] = new ExtensionPoint(_manager, this, key, _provides[key]);
			});

		_extends.keyArray().each(
			function (key) {
				if (not register.keyExists(key))
					throw(errorcode="NO_SUCH_EXTENSION_POINT",
						detail="Plugin '#_name#' tried to extend non-existent extension point '#key#'")
				else
					register[key].extend(this, _extends[key]);
			});
	}



	public struct function toStruct() {
		return {
			name = _name,
			package = _package,
			path = _path,
			mapping = _mapping,
			dependencyOrder = _dependencyOrder,
			version = listToArray(_version, "."),
			requires = new Collection(listToArray(_requires.keyList())).fold(
				function(key, output) {
					output[key] = _requires[key].toStruct();
					return output;
				},
				{}),
			provides = _provides.copy(),
			extends = _extends.copy(),
			description = _description
		};
	}



	public void function setDependencyOrder(numeric order) {
		_dependencyOrder = order;
	}



	public numeric function getDependencyOrder() {
		return _dependencyOrder;
	}



	public struct function getRequiredPlugins() {
		return _requires.copy();
	}



	public string function getName() {
		return _name;
	}



	public string function getMapping() {
		return _mapping;
	}



	public string function getPackage() {
		return _package;
	}



	public string function getPath() {
		return _path;
	}



	public numeric function getMajorVersion() {
		return listToArray(_version, ".")[1];
	}



	public numeric function getMinorVersion() {
		return listToArray(_version, ".")[2];
	}



	public numeric function getPatchVersion() {
		return listToArray(_version, ".")[3];
	}



	public void function setVersion(string version) {
		_version = version;
	}


	public string function getVersion() {
		return _version;
	}



	/**
		Private helper methods called from plugin template when included by init()
	 **/


	private string function plugin(string name, string version = "0.0.0") {
		if (not reFind("[0-9]+\.[0-9]+\.[0-9]+$", version) eq 1) {
			throw(errorcode="INVALID_VERSION",
					detail="Plugin '#name#' version string '#version#' is invalid.");
		}

		_name = name;
		_version = version;
		return name;
	}



	private string function requires(string plugin, string version = "0.0.0") {
		if (not reFind("[0-9]+\.[0-9]+\.[0-9]+$", version) eq 1) {
			throw errorcode="INVALID_VERSION"
					detail="Plugin '#name#' version string '#version#' is invalid.";
		}
		_requires[plugin] = new Plugin(_manager, "", plugin, version);
		return plugin;
	}



	private string function provides(string extensionPoint, class="") {
		_provides[extensionPoint] = class;
		return extensionPoint;
	}



	private string function extends(string extensionPoint, class="") {
		_extends[extensionPoint] = class;
		return extensionPoint;
	}

}