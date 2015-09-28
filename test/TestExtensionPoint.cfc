component extends="mxunit.framework.TestCase" {

	import mockbox.system.testing.MockBox;
	import rb_plugger.ExtensionPoint;



	function setup() {
		mb = new MockBox();
		plugin = mb.createEmptyMock("rb_plugger.Plugin").$("getPackage");
		manager = mb.createEmptyMock("rb_plugger.PluginManager");
		instance = new ExtensionPoint(manager, plugin, "Hardware Shop", "rb_plugger.test.plugins.ExtensionStub");
		instance.extend(plugin, "rb_plugger.test.plugins.ExtensionStub");
	}



	function tearDown() {
		mb = "";
		plugin = "";
		manager = "";
		instance = "";
	}



	function testInstance() {
		assert(isInstanceOf(instance, "rb_plugger.ExtensionPoint"));
	}



	function testArray() {
		assert(isArray(instance.getArray()));
	}



	function testCollection() {
		assert(isInstanceOf(instance.getCollection(), "rb_plugger.Collection"));
	}



	function testExtend() {
		assert(instance.getArray().len() eq 1);
		assertSame(instance.getArray()[1].pluginManager, manager);
		assertSame(instance.getArray()[1].pluginContext, plugin);
	}



	function testPluginTypeMismatch() {
		try {
			instance.extend(plugin, "rb_plugger.test.plugins.butcher_shop.ButcherShop");
			fail("extend did not throw exception for a non-matching type");
		} catch (exception) {
			assertEquals("PLUGIN_TYPE_MISMATCH", exception.errorcode);
		}
	}

}