component implements="rb_plugger.test.plugins.shopping_list.IUnit"{

	/**
		@returns    Human-readable name of unit e.g. "Metric"
	 **/
	string function name() {
		return "Imperial";
	}



	/**
		@returns    Human-readable weight description, performing
					necessary conversion from grams eg "12 oz"
	 **/
	string function weight(numeric quantity) {
		return "#round(quantity * 0.035274)#oz";
	}



	/**
		@returns    Human-readable volume description, performing
					necessary conversion from millilitres e.g "2 gal"
	 **/
	string function volume(numeric quantity) {
		return "#round(quantity * 0.033814)# fl oz";
	}



	/**
		@returns    Human-readable length description, performing
					necessary conversion from metres, e.g. "2 ft"
	 **/
	string function length(numeric quantity) {
		return "#round(quantity * 3.28083)#ft";
	}

}