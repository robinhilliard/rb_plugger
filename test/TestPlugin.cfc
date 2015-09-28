component extends="mxunit.framework.TestCase" {

	import mockbox.system.testing.MockBox;
	import rb_plugger.Plugin;



	function setup() {
		mb = new MockBox();
		manager = mb.createEmptyMock("rb_plugger.PluginManager");
		instance = new Plugin(manager,
					"/rb_plugger/test/plugins/shopping_list/plugin.cfm");
	}



	function tearDown() {
		mb = "";
		plugin = "";
		manager = "";
		instance = "";
	}



	function testInstance() {
		assert(isInstanceOf(instance, "rb_plugger.Plugin"));
	}



	function testMapping() {
		assertEquals("/rb_plugger/test/plugins/shopping_list/",
					instance.getMapping());
	}



	function testPackage() {
		assertEquals("rb_plugger.test.plugins.shopping_list",
					instance.getPackage());
	}



	function testPath() {
		assertEquals(expandPath("/rb_plugger/test/plugins/shopping_list/"),
					instance.getPath());
	}



	function testVersion() {
		assertEquals("1.2.3", instance.getVersion());
		assertEquals(1, instance.getMajorVersion());
		assertEquals(2, instance.getMinorVersion());
		assertEquals(3, instance.getPatchVersion());
	}



	function testDependencyOrder() {
		instance.setDependencyOrder(384);
		assertEquals(384, instance.getDependencyOrder());
	}



	function testName() {
		assertEquals("Shopping List", instance.getName());
	}



	function testToStruct() {

		// Tokenise description to really ignore white space in comparison
		var description = listToArray("<p>The Shopping List plugin appends an HTML shopping list"
			& " to a response. It extends plugger.application and allows specific types"
			& " of shop to contribute to the list by extending the shopping_list.shops"
			& " extension point. The quantities of each item in the shopping list are"
			& " listed in multiple units. Unit types are added by extending the"
			& " shopping_list.units extension point.</p>", chr(10) & chr(13) & "    ");

		var result = instance.toStruct();

		result.description = listToArray(result.description, chr(10) & chr(13) & "    ");

		assertEquals({
			name="Shopping List",
			description=description,
			package="rb_plugger.test.plugins.shopping_list",
			mapping="/rb_plugger/test/plugins/shopping_list/",
			path=expandPath("/rb_plugger/test/plugins/shopping_list/"),
			dependencyOrder=0,
			package="rb_plugger.test.plugins.shopping_list",
			version=[1, 2, 3],
			requires = {},
			extends = {
				"plugger.application" = "rb_plugger.test.plugins.shopping_list.ShoppingListApplication"
			},
			provides = {
				"shopping_list.shops" = "rb_plugger.test.plugins.shopping_list.IShop",
				"shopping_list.units" = "rb_plugger.test.plugins.shopping_list.IUnit"
			}
		},
		result);
	}



	function testRegisterExtensionPoints() {
		var register = {
			"plugger.application" = mb.createEmptyMock("rb_plugger.ExtensionPoint").$("extend")
		};

		instance.registerExtensionPoints(register);

		// We called extend on the plugger.application extension point

		assertSame(instance,
					register["plugger.application"].$callLog().extend[1][1]);

		assertEquals("rb_plugger.test.plugins.shopping_list.ShoppingListApplication",
					register["plugger.application"].$callLog().extend[1][2]);

		// We added our own extensions to the register
		assert(register.keyExists("shopping_list.shops"));

		assert(isInstanceOf(register["shopping_list.shops"],
					"rb_plugger.ExtensionPoint"));

		assertEquals("shopping_list.shops",
					register["shopping_list.shops"].getName());

		assertEquals("rb_plugger.test.plugins.shopping_list.IShop",
					register["shopping_list.shops"].getClass());

		assert(register.keyExists("shopping_list.units"));

		assert(isInstanceOf(register["shopping_list.units"], "rb_plugger.ExtensionPoint"));

		assertEquals("shopping_list.units",
					register["shopping_list.units"].getName());

		assertEquals("rb_plugger.test.plugins.shopping_list.IUnit",
					register["shopping_list.units"].getClass());
	}



	function testNoSuchExtensionPoint() {
		try {
			instance.registerExtensionPoints({});
			fail("registerExtensionPoints did not throw exception extending non-existent extension point");
		} catch (exception) {
			assertEquals("NO_SUCH_EXTENSION_POINT", exception.errorcode);
		}
	}

}