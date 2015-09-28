/**
	rb_plugger.ExtensionPoint

	Represent an extension point for other plugins to extend - basically an array of callbacks.

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
	_owner = 0;
	_name = "";
	_class = "";
	_extensions = [];



	/********************
		Public methods
	 ********************/



	/**
		Constructor

		@param pluginManager    Singleton passed through via Plugin
		@param owner            The Plugin the extension point belongs to
		@param name             The name of the extension point
		@param class            The type of component that must be used to implement the extension point
	 **/
	public void function init(PluginManager pluginManager, Plugin owner, string name, string class) {
		_manager = pluginManager;
		_owner = owner;
		_name = name;
		_class = class;
	}



	/**
		Add an implementation to an extension point.

		@param plugin   The plugin that owns the implementing class
		@param class    The name of the implementation class
		@throws PLUGIN_TYPE_MISMATCH
	 **/
	public void function extend(Plugin owner, string class) {
		var instance = createObject("component", class);

		if (isInstanceOf(instance, _class)) {

			// If the implementation implements IPluginContextInject, we promise to
			// inject plugin manager and plugin

			if (isInstanceOf(instance, "rb_plugger.IPluginContext")) {
				instance.setContext(_manager, owner);
			}

			_extensions.append(instance);

		} else {
			throw(errorcode="PLUGIN_TYPE_MISMATCH",
				detail="Plugin #owner.getPackage()# extension point #_name# can only be extended by instances of #_class#. #class# does not meet this requirement.");
		}
	}



	/**
		Get extension point name

		@returns name
	 **/
	public string function getName() {
		return _name;
	}



	/**
		Get extension point class

		@returns class
	 **/
	public string function getClass() {
		return _class;
	}



	/**
		Get a raw array of extensions

		@returns array of extension point implementation instances
	 **/
	public array function getArray() {
		return _extensions;
	}



	/**
		Get extensions wrapped in a collection object with useful
		high-level function accessors

		@returns ExtensionCollection instance
	 **/
	public Collection function getCollection() {
		return new Collection(_extensions);
	}

}