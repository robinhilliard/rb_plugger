/**
	Implemented by plugins that would like to directly respond to application events at the
	rb_plugger.Application extension point.

	There is no guarantee what order plugins will be called in:
	-   In the case of onApplication[Start|Stop] plugger should use plugin
		dependencies to make sure things are available as required
	-   In the case of on[Request|Session][Start|End] you may want to extend a plugin
		like rb_http_filter instead, which takes priorities into account.

	@see Adobe Application.cfc documentation http://adobe.ly/8L79rV

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

	// Have deliberately left out onServer[Start|End] for now

}