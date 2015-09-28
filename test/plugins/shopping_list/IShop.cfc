interface {

	/**
		@returns human-readable name of the shop
	 **/
	string function name() {}



	/**
		@returns    An array of structs representing items and quantities to purchase in
					SI units where applicable (grams, ml, m - doesn't apply for count).

					[
						{name= "Bacon", quantity= 500, by="count|weight|volume|length"},
						...
					]
	 **/
	array function itemQuantities() {}
}