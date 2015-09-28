/**
	rb_plugger.Collection

	Immutable array wrapper with more useful fp-style methods than
	Railo 4 arrays. Can still access array elements using [] notation.

	TODO: Move to rb_util

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

	_items = [];

	/**
		Constructor

		@param items            Array, list, query or struct to wrap. Structs are converted
								to an array of {key, value} structs. Query rows are
								converted to structs with column keys.
		@param separatorOrType  If items is a list, list separator(s), default ","
								If items is an array or struct and this argument is
								provided, it will check the type of each item
								and throw an error if it doesn't match.

								Supported values:
								- simple
								- numeric
								- array
								- struct
								- query
								- <<class or interface name>>
		@throws TYPE_MISMATCH
	 **/
	public Collection function init(items, string separatorOrType = ",") {
		var i = 1;
		var row = 0;
		var bCheckType = not isSimpleValue(items) and separatorOrType neq ",";
		var newItems = [];

		if (isSimpleValue(items)) {
			// List
			newItems = listToArray(items, separatorOrType);

		} else if (isStruct(items)) {
			// Struct
			items.each(
				function(key) {
					newItems.append({key = key, value = items[key]});
				}
			);
			items = newItems;
		} else if (isQuery(items)) {
			for (row in items)
				newItems.append(row);
		} else {
			newItems = items;
		}

		newItems.each(function(item) {this[i] = newItems[i++]});
		_items = newItems;

		if (bCheckType and any(
			function(item) {
				var ok = true;

				switch(separatorOrType) {
					case "simple":
						return not isSimpleValue(item);
					case "numeric":
						return not isNumeric(item);
					case "array":
						return not isArray(item);
					case "struct":
						return not isStruct(item);
					case "query":
						return not isQuery(item);
					default:
						return not isInstanceOf(item, separatorOrType);
				}
			}
		)) {
			throw(errorcode="TYPE_MISMATCH",
				detail="All items in Collection must be of type '#separatorOrType#'");
		}

		return this;
	}



	/**
		Map a function over an array of items, returning an array of results

		@param  fn              Function taking a single item argument and returning
								mapped value
		@param asCollection     If false return a plain array
		@returns array of fn return values
	 **/
	public any function map(fn, asCollection = true) {
		var output = [];

		_items.each(function(item) {arrayAppend(output, fn(item))});

		if (asCollection)
			return new Collection(output);
		else
			return output;
	}



	/**
		Reduce an array of items to a single return value using a function

		@param fn       Function with the signature:
							fn(item, output)
		@param result  initial output value
		@returns Last output value
	 **/
	public any function fold(fn, result) {
		_items.each(function(item) {result = fn(item, result)});
		return result;
	}



	/**
		Wrap array each

		@param fn function to call
	 **/
	public void function each(fn) {
		_items.each(fn);
	}



	/**
		Convert to array

		@returns items in an array
	 **/
	public array function toArray() {
		return _items;
	}



	/**
		Convert to list

		@param separator default ","
		@returns items in a list
	 **/
	public string function toList(separator = ",") {
		return _items.toList(separator)
	}



	/**
		Get length

		@returns number of items in collection
	 **/
	public numeric function len() {
		return _items.len();
	}



	/**
		Filter

		@param fn   boolean function (item) { return true if item to be included in result}
		@returns Collection containing items for which fn returned true
	 **/
	public Collection function filter(fn) {
		return new Collection(
			this.fold(
				function (item, output) {
					if (fn(item))
						output.append(item);
					return output;
				},
				[]
			)
		);
	}



	/**
		Count

		@param fn boolean function (item) {return true if criteria met}
		@returns count of items meeting criteria
	 **/
	public boolean function count(fn) {
		return filter(fn).len();
	}



	/**
		None

		@param fn boolean function (item) {return true if criteria met}
		@returns true if fn returned false for all items
	 **/
	public boolean function none(fn) {
		return count(fn) eq 0;
	}



	/**
		Any

		@param fn boolean function (item) {return true if criteria met}
		@returns true if fn returned true at least once
	 **/
	public boolean function any(fn) {
		return count(fn) gt 0;
	}



	/**
		All

		@param fn boolean function (item) {return true if criteria met}
		@returns true if fn returned true for all items
	 **/
	public boolean function all(fn) {
		return count(fn) eq this.len();
	}



	/**
		Partition

		@param fn   any function (item) {
						return simple value item partition key
					}
		@returns    struct containing collections of items keyed
					by the return value from fn() for those items
	 **/
	public struct function partition(fn) {
		var result = fold(
			function (item, output) {
				key = fn(item);

				if (not output.keyExists(key))
					output[key] = [];

				output[key].append(item);
				return output;
			},
			{}
		);
		new Collection(result.keyArray()).each(
			function (key) {
				result[key] = new Collection(result[key]);
			}
		);
		return result;
	}



	/**
		Sort

		@param fn   numeric function (a, b) {
						a < b => -1
						a > b => 1
						a = b => 0
					}
	 **/
	public Collection function sort(fn) {
		return new Collection(_items.sort(fn));
	}


	/**
		Merge

		@param items    Collection to merge
	 **/
	public Collection function merge(Collection items) {
		return new Collection(arrayMerge(_items, items.toArray()));
	}



	/**
		Comp - list comprehension
		@param fn   any function(a, b, c, ...) {
						optionally return resulting collection item
					}
		@param a    Collection (param name to match fn argument)
		@param b    " "
		@param c    " "
		@param ...
		@returns    Collection of fn() results after calling with
						a[1], b[1], c[1]
						a[1], b[1], c[2]
						...
						a[1], b[1], c[n]
						a[1], b[2], c[1-n]
						...
						a[1], b[m], c[1-n]
						a[2], b[1-m], c[1-n]
						...
						a[l], b[1-m], c[1-n]
	 **/
	public Collection function comp(fn) {
		// TODO: Implement
	}



	/* TODO: sort, eachi,filteri? */

}