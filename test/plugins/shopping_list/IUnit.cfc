interface {

	/**
		@returns    Human-readable name of unit e.g. "Metric"
	 **/
	string function name() {}



	/**
		@returns    Human-readable weight description, performing
					necessary conversion from grams eg "12 oz"
	 **/
	string function weight(numeric quantity) {}



	/**
		@returns    Human-readable volume description, performing
					necessary conversion from millilitres e.g "2 gal"
	 **/
	string function volume(numeric quantity) {}



	/**
		@returns    Human-readable length description, performing
					necessary conversion from metres, e.g. "2 ft"
	 **/
	string function length(numeric quantity) {}

}