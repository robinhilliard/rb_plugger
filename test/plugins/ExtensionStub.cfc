component implements="rb_plugger.IPluginContext" {

	void function setContext(PluginManager pluginManager, Plugin pluginContext) {
		this.pluginManager = pluginManager;
		this.pluginContext = pluginContext;
	}

}