/**
	Implemented by plugin CFCs that would like a reference to the plugin manager instance
	and a private plugin context when they are created

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

interface {

	/**
		Implement to receive context when a plugin implementation CFC is instanciated

		@param pluginManager    The application plugin manager instance
		@param pluginContext    Plugin instance shared within the plugin
	 **/
	void function setContext(PluginManager pluginManager, Plugin pluginContext) {}

	// TODO: pluginsComplete() to indicate that all plugins have finished wiring, called
	// in dependency order - check is that necessary or already happening with setcontext?
}