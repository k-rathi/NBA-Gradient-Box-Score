var parsePlayByPlay = function(data) {
	//Take the json output of play-by-play and print to console
	var lines = data.split(']');
	
	var first_line = 0;
	
	if(last_line !== null) {
		first_line = last_line;
	}
	
	for (var i = first_line; i<lines.length; i++) {
			parseLine(lines[i]);
	}

	last_line = lines.length;
}

function parseLine(line) {
	console.log(line);
}