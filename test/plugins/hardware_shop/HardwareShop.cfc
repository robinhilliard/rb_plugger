component implements="rb_plugger.test.plugins.shopping_list.IShop" {

	/**
		@returns human-readable name of the shop
	 **/
	string function name() {
		return "Hardware";
	}



	/**
		@returns    An array of structs representing items and quantities to purchase
	 **/
	array function itemQuantities() {
		return [
			{name="9mm Marine Ply 1200&times;2400", quantity=5, by="count"},
			{name="2&times;4 Radiata Pine", quantity=20, by="length"},
			{name="Decking Oil", quantity=3000, by="volume"}
		];
	}

}