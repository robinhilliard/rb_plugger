component extends="mxunit.framework.TestCase" {

	import rb_plugger.Collection;
	import rb_plugger.test.plugins.ExtensionStub;



	function setup() {
		// wrap an array
		instance = new Collection([1, 2, 3]);
	}



	function tearDown() {
		instance = "";
	}



	function testInstance() {
		assert(isInstanceOf(instance, "rb_plugger.Collection"));
	}



	function testAccessor() {
		// should be able to access contents using [] operator
		assertEquals(1, instance[1]);
		assertEquals(2, instance[2]);
		assertEquals(3, instance[3]);
	}



	function testMap() {
		// create a new collection containing the original collection's
		// contents increased by one
		instance2 = instance.map(function(x) {return x + 1});
		assert(isInstanceOf(instance2, "rb_plugger.Collection"));
		assertEquals(2, instance2[1]);
		assertEquals(3, instance2[2]);
		assertEquals(4, instance2[3]);

		// check it can return an array if second optional argument is false
		a = instance.map(function(x) {return x + 1}, false);
		assert(isArray(a));
		assertEquals(2, a[1]);
		assertEquals(3, a[2]);
		assertEquals(4, a[3]);
	}



	function testFold() {
		// we can sum the elements of the original collection
		assertEquals(6, instance.fold(function(next, sum) { return next + sum}, 0));
	}



	function testEach() {
		savecontent variable="result" {instance.each(function(x){writeOutput(x)})};
		assertEquals("123", result);
	}



	function testToArray() {
		assertEquals([1, 2, 3], instance.toArray());
	}



	function testToList() {
		assertEquals("1,2,3", instance.toList());
	}



	function testLen() {
		assertEquals(3, instance.len());
	}



	function testFilter() {
		assertEquals([1,3], instance.filter(function(x) {return x neq 2}).toArray());
	}



	function testCount() {
		assertEquals(2, instance.count(function(x) {return x lt 3}));
	}



	function testNone() {
		assert(instance.none(function(x) {return x eq 4}));
		assertFalse(instance.none(function(x) {return x eq 1}));
	}



	function testAny() {
		assert(instance.any(function(x) {return x eq 1}));
		assertFalse(instance.any(function(x) {return x eq 4}));
	}



	function testAll() {
		assert(instance.all(function(x) {return x lt 4}));
		assertFalse(instance.all(function(x) {return x lt 3}));
	}



	function testPartition() {
		var result = instance.partition(function(x) {return (x mod 2) eq 0});

		assertEquals([2], result.true.toArray());
		assertEquals([1, 3], result.false.toArray());

		result = instance.partition(function(x) {return "key#x#"});

		assertEquals([1], result.key1.toArray());
		assertEquals([2], result.key2.toArray());
		assertEquals([3], result.key3.toArray());
	}



	function testSort() {
		assertEquals([1, 2, 3, 4, 5, 6], new Collection([4, 1, 6, 5, 3, 2]).sort(
			function(a, b) {
				if (a < b)
					return -1;
				if (a > b)
					return 1;
				return 0;
			}
		).toArray());
	}



	function testMerge() {
		a = new Collection([1, 2, 3]);
		b = new Collection([4, 5, 6]);
		assertEquals([1, 2, 3, 4, 5, 6], a.merge(b).toArray());
	}



	function testFromList() {
		instance = new Collection("1,2,3");
		assertEquals(1, instance[1]);
		assertEquals(2, instance[2]);
		assertEquals(3, instance[3]);
	}



	function testFromStruct() {
		instance = new Collection({key1 = 1, key2 = 2, key3 = 3});
		assertEquals(3, instance.len());
		assert(instance.any(function(item) { return item.key eq "key1" and item.value eq 1}));
		assert(instance.any(function(item) { return item.key eq "key2" and item.value eq 2}));
		assert(instance.any(function(item) { return item.key eq "key3" and item.value eq 3}));
	}



	function testFromQuery() {
		var q = Query(key = ["key1", "key2", "key3"], value = [1, 2, 3]);

		instance = new Collection(q);
		assertEquals({key = "key1", value = 1}, instance[1]);
		assertEquals({key = "key2", value = 2}, instance[2]);
		assertEquals({key = "key3", value = 3}, instance[3]);
	}



	function testTypeMismatchSimple() {
		assert(isInstanceOf(new Collection(["a", "b", "c"], "simple"), "Collection"));

		try {
			instance = new Collection([1, 2, []], "simple");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}



	function testTypeMismatchNumeric() {
		assert(isInstanceOf(new Collection([1, 2, 3], "numeric"), "Collection"));

		try {
			instance = new Collection([1, 2, "three"], "numeric");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}



	function testTypeMismatchArray() {
		assert(isInstanceOf(new Collection([["a"], ["b"], ["c"]], "array"), "Collection"));

		try {
			instance = new Collection([[], 2, []], "array");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}



	function testTypeMismatchStruct() {
		assert(isInstanceOf(new Collection([{key = 1}, {key = 2}, {key = 3}], "struct"), "Collection"));

		try {
			instance = new Collection([1, {}, 3], "struct");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}



	function testTypeMismatchQuery() {
		assert(isInstanceOf(new Collection([queryNew("key, value"), queryNew("key, value"), queryNew("key,value")], "query"), "Collection"));

		try {
			instance = new Collection([[], 2, queryNew("key, value")], "query");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}



	function testTypeMismatchObject() {
		assert(isInstanceOf(new Collection([new ExtensionStub(), new ExtensionStub(), new ExtensionStub()], "ExtensionStub"), "Collection"));

		try {
			instance = new Collection([[], 2, new ExtensionStub()], "ExtensionStub");
			fail("Did not throw error");
		} catch (e) {
			if (e.errorcode neq "TYPE_MISMATCH") {
				fail ("Threw error but errorcode not TYPE_MISMATCH");
			}
		}
	}

}