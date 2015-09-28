component implements="rb_plugger.test.plugins.shopping_list.IUnit"{

	/**
		@returns    Human-readable name of unit e.g. "Metric"
	 **/
	string function name() {
		return "Metric"
	}



	/**
		@returns    Human-readable weight description, performing
					necessary conversion from grams eg "12 oz"
	 **/
	string function weight(numeric quantity) {
		return "#quantity#g";
	}



	/**
		@returns    Human-readable volume description, performing
					necessary conversion from millilitres e.g "2 gal"
	 **/
	string function volume(numeric quantity) {
		if (quantity < 1000)
			return "#quantity#ml";
		else
			return "#quantity/1000#L";
	}



	/**
		@returns    Human-readable length description, performing
					necessary conversion from metres, e.g. "2 ft"
	 **/
	string function length(numeric quantity) {
		if (quantity < 1)
			return "#quantity * 1000#mm";
		else
			return "#quantity#m";
	}

}