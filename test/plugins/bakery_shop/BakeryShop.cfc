component implements="rb_plugger.test.plugins.shopping_list.IShop" {

	/**
		@returns human-readable name of the shop
	 **/
	string function name() {
		return "Bakery";
	}



	/**
		@returns    An array of structs representing items and quantities to purchase
	 **/
	array function itemQuantities() {
		return [
			{name="Wholemeal Sliced Loaf", quantity=2, by="count"},
			{name="Breadcrumbs", quantity=800, by="weight"}
		];
	}

}