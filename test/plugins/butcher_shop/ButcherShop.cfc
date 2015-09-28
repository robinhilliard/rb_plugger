component implements="rb_plugger.test.plugins.shopping_list.IShop" {

	/**
		@returns human-readable name of the shop
	 **/
	string function name() {
		return "Butcher";
	}



	/**
		@returns    An array of structs representing items and quantities to purchase
	 **/
	array function itemQuantities() {
		return [
			{name="Lean Mince", quantity=500, by="weight"},
			{name="Pork Sausages", quantity=20, by="count"}
		];
	}

}