component extends="mxunit.framework.TestCase" {

	import mockbox.system.testing.MockBox;
	import rb_plugger.PluginManager;



	function setup() {
		instance = new PluginManager("/rb_plugger/test/plugins",
			"rb_plugger.test.plugins.excluded");
	}



	function teardown() {
		instance = "";
	}



	function testInstance() {
		assert(isInstanceOf(instance, "rb_plugger.PluginManager"));
	}



	function testNoSuchPackage() {
		try {
			instance = new PluginManager("/here/be/dragons");
			fail("Did not throw exception");

		} catch(e) {
			if (not e.errorcode eq "MISSING_PLUGIN_MAPPING")
				fail("Exception thrown #e.errorcode# was not MISSING_PLUGIN_MAPPING: #e.detail#");
		}
	}



	function testMajorVersionWrong() {
		try {
			// Leave only major_version_wrong and shopping_list
			instance = new PluginManager("/rb_plugger/test/plugins", arrayToList([
				"rb_plugger.test.plugins.excluded.minor_version_wrong",
				"rb_plugger.test.plugins.excluded.patch_version_wrong",
				"rb_plugger.test.plugins.excluded.missing_dependency",
				"rb_plugger.test.plugins.bakery_shop",
				"rb_plugger.test.plugins.butcher_shop",
				"rb_plugger.test.plugins.hardware_shop",
				"rb_plugger.test.plugins.imperial_units",
				"rb_plugger.test.plugins.metric_units",
				"rb_plugger.test.plugins.old_dependencies"
			]));

			fail("Did not throw exception");

		} catch (e) {
			if (not e.errorcode eq "MISSING_PLUGIN_DEPENDENCIES")
				fail("Exception thrown #e.errorcode# was not MISSING_PLUGIN_DEPENDENCIES: #e.detail#");
		}

	}



	function testMinorVersionWrong() {
		try {
			// Leave only minor_version_wrong and shopping_list
			instance = new PluginManager("/rb_plugger/test/plugins", arrayToList([
				"rb_plugger.test.plugins.excluded.major_version_wrong",
				"rb_plugger.test.plugins.excluded.patch_version_wrong",
				"rb_plugger.test.plugins.excluded.missing_dependency",
				"rb_plugger.test.plugins.bakery_shop",
				"rb_plugger.test.plugins.butcher_shop",
				"rb_plugger.test.plugins.hardware_shop",
				"rb_plugger.test.plugins.imperial_units",
				"rb_plugger.test.plugins.metric_units",
				"rb_plugger.test.plugins.old_dependencies"
			]));

			fail("Did not throw exception");

		} catch (e) {
			if (not e.errorcode eq "MISSING_PLUGIN_DEPENDENCIES")
				fail("Exception thrown #e.errorcode# was not MISSING_PLUGIN_DEPENDENCIES: #e.detail#");
		}

	}



	function testPatchVersionWrong() {
		try {
			// Leave only patch_version_wrong and shopping_list
			instance = new PluginManager("/rb_plugger/test/plugins", arrayToList([
				"rb_plugger.test.plugins.excluded.minor_version_wrong",
				"rb_plugger.test.plugins.excluded.major_version_wrong",
				"rb_plugger.test.plugins.excluded.missing_dependency",
				"rb_plugger.test.plugins.bakery_shop",
				"rb_plugger.test.plugins.butcher_shop",
				"rb_plugger.test.plugins.hardware_shop",
				"rb_plugger.test.plugins.imperial_units",
				"rb_plugger.test.plugins.metric_units",
				"rb_plugger.test.plugins.old_dependencies"
			]));

			fail("Did not throw exception");

		} catch (e) {
			if (not e.errorcode eq "MISSING_PLUGIN_DEPENDENCIES")
				fail("Exception thrown #e.errorcode# was not MISSING_PLUGIN_DEPENDENCIES: #e.detail#");
		}

	}



	function testIncompatiblePluginVersion() {
		try {
			// Leave only major_version_wrong, one other plugin requiring
			// shopping_list 1.0.0, and shopping_list
			instance = new PluginManager("/rb_plugger/test/plugins", arrayToList([
				"rb_plugger.test.plugins.excluded.minor_version_wrong",
				"rb_plugger.test.plugins.excluded.patch_version_wrong",
				"rb_plugger.test.plugins.excluded.missing_dependency",
				"rb_plugger.test.plugins.bakery_shop",
				"rb_plugger.test.plugins.butcher_shop",
				"rb_plugger.test.plugins.hardware_shop",
				"rb_plugger.test.plugins.imperial_units",
				"rb_plugger.test.plugins.old_dependencies"
			]));

			fail("Did not throw exception");

		} catch (e) {
			if (not e.errorcode eq "INCOMPATIBLE_PLUGIN_VERSION")
				fail("Exception throw was not INCOMPATIBLE_PLUGIN_VERSION: #e.detail#");
		}
	}



	function testMissingDependency() {
		try {
			// Leave only missing_dependency and shopping_list
			instance = new PluginManager("/rb_plugger/test/plugins", arrayToList([
				"rb_plugger.test.plugins.excluded.minor_version_wrong",
				"rb_plugger.test.plugins.excluded.major_version_wrong",
				"rb_plugger.test.plugins.excluded.patch_version_wrong",
				"rb_plugger.test.plugins.bakery_shop",
				"rb_plugger.test.plugins.butcher_shop",
				"rb_plugger.test.plugins.hardware_shop",
				"rb_plugger.test.plugins.imperial_units",
				"rb_plugger.test.plugins.metric_units",
				"rb_plugger.test.plugins.old_dependencies"
			]));

			fail("Did not throw exception");

		} catch (e) {
			if (not e.errorcode eq "MISSING_PLUGIN_DEPENDENCIES")
				fail("Exception thrown #e.errorcode# was not MISSING_PLUGIN_DEPENDENCIES: #e.detail#");
		}

	}



	function testGetExtensionPoint() {
		var shops = instance.getExtensionPoint("shopping_list.shops");

		assert(isInstanceOf(shops, "rb_plugger.Collection"));
		assertEquals(3, shops.len());
		assert(shops.all(
			function(shop) {
				return isInstanceOf(shop, "rb_plugger.test.plugins.shopping_list.IShop");
			}
		));
	}



	function testNonExistentExtensionPoint() {
		try {
			var shops = instance.getExtensionPoint("shopping_list.boutiques");
			fail("Did not throw exception");
		} catch(e) {
			if (not e.errorcode eq "NO_SUCH_EXTENSION_POINT")
				fail("Exception thrown #e.errorcode# was not NO_SUCH_EXTENSION_POINT: #e.detail#");
		}
	}



	function testWasExtended() {
		assert(instance.wasExtended("shopping_list.shops"));
	}



	function testNonExistentWasExtended() {
		try {
			var shops = instance.wasExtended("shopping_list.boutiques");
			fail("Did not throw exception");
		} catch(e) {
			if (not e.errorcode eq "NO_SUCH_EXTENSION_POINT")
				fail("Exception thrown #e.errorcode# was not NO_SUCH_EXTENSION_POINT: #e.detail#");
		}
	}



	function testOnApplicationStart() {
		instance = new PluginManager("rb_plugger");
		instance.pluginMappingPath = arrayToList([
			"rb_plugger.test.plugins.shopping_list",
			"rb_plugger.test.plugins.hardware_shop",
			"rb_plugger.test.plugins.metric_units",
			"rb_plugger.test.plugins.excluded"
		]);
		instance.excludedPluginMappings = "rb_plugger.test.plugins.excluded";

		request.shoppingListOnApplicationStart = false;
		assert(instance.onApplicationStart());
		assert(request.shoppingListOnApplicationStart);

	}



	function testOnRequestStart() {
		request.shoppingListOnRequestStart = false;
		instance.onRequestStart();
		assert(request.shoppingListOnRequestStart);
	}



	function testOnRequestStartReload() {
		request.shoppingListOnApplicationStart = false;
		request.shoppingListOnRequestStart = false;
		instance.pluginMappingPath = "rb_plugger.test.plugins";
		instance.excludedPluginMappings = "rb_plugger.test.plugins.excluded";
		instance.reloadKey="testReload";
		url.testReload = true;
		instance.onRequestStart();
		assert(request.shoppingListOnRequestStart);
		assert(request.shoppingListOnApplicationStart);
	}



	function testOnMissingTemplate() {
		request.shoppingListOnMissingTemplate = false;
		instance.onMissingTemplate("notthere.cfm");
		assert(request.shoppingListOnMissingTemplate);
	}



	function testOnRequest() {
		request.shoppingListOnRequest = false;
		instance.onRequest("template.cfm");
		assert(request.shoppingListOnRequest);
	}



	function testOnRequestEnd() {
		request.shoppingListOnRequestEnd = false;
		instance.onRequestEnd("template.cfm");
		assert(request.shoppingListOnRequestEnd);
	}

}