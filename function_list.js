function compare (current, historical) {
	if(current < historical * 0.6) return 1;
	if (current < historical * 0.8) return 2; 
	if (current < historical) return 3;
	if (current < historical * 1.2) return 4;
	if (current < historical * 1.4) return 5;
	else return 6;
}
function per36Historical(historical) {
	for(var i = 7; i < historical.length; i++)
		historical[i] = historical[i]/historical[6];
	return historical;
}

function per36Current(current) {
	var current36Factors = [false, false, false, true, true, false, true, true, false, true, true, false, true, true, true, true, true, true, true]; 
	for (var i = 3; i < current.length; i++)
		current[i] = current[i]/current[2];
}
var sampleData= ["Varejao A.", "F", 32:30, 5, 8, .625, 3, 4, .75, 0, 1, 0, 2, 4, 6, 3, 5, 8];
var header = ["PLAYER_ID","PLAYER_NAME","GP","W","L","W_PCT","MIN","FGM","FGA","FG_PCT","FG3M","FG3A","FG3_PCT","FTM","FTA","FT_PCT","OREB","DREB","REB","AST","TOV","STL","BLK","BLKA","PF","PFD","PTS","PLUS_MINUS","DD2","TD3"]
var sampleHistorical = [2760,"Anderson Varejao",49,38,11,0.776,9.6,1.0,2.4,0.432,0.0,0.0,0.0,0.6,0.9,0.682,0.7,1.9,2.6,0.7,0.4,0.3,0.2,0.1,1.3,1.2,2.7,0.6,0,0]]
function recolor(divId, current, historical) {
	const RED = "red";
	const LIGHT_RED = "orange";
	const NEUTRAL = "black";
	const LIGHT_GREEN = "purple";
	const GREEN = "green";
	const MEGA_GREEN = "blue";

	var value = compare(current, historical);
	var element = document.getElementById(divId);
	if (value = 1)
		element.style.color = RED;
	if (value = 2)
		element.style.color = LIGHT_RED;
	if (value = 3)
		element.style.color = NEUTRAL;
	if (value = 4)
		element.style.color = LIGHT_GREEN;
	if (value = 5)
		element.style.color = GREEN;
	if (value = 6)
		element.style.color = MEGA_GREEN;
}

function per36(statValue, minutes) {
	return (statValue / minutes) * 36;
}

function getHistorical(playerLast, playerFirst, teamId) {
	for (player in playerList) {
		if(teamId === player.team) {
			if(playerLast = player.lastName) {
				if (playerFirst === player.firstName[0]) {
					return parsePlayer(player.playerId);
				}
			}
		}
	}
}

function getTeamId(teamName) {
	for (team in teamList) {
		if(team.simpleName === teamName) return team.teamId;
	}
}

function parseScoreboard (scoreboard) {
	document.getElementById("scoreboard").innerHtml+="<table>";
	for (score in score.resultSets.rowSet) {
		var gameUrl= "http://http://www.nba.com/games/" + score[5] +"/gameinfo.html";
		alert(score[6]);
		var homeTeam = getTeamName(score[6]);
		var awayTeam = getTeamName(score[7]);
		var timeLeft = "";
		if (score[3] === 3) var timeLeft = score[10];
		document.getElementById("scoreboard").innerHtml += "<tr><td>" + homeTeam + " vs " + awayTeam + "</td></tr>";   
	}
	document.getElementById("scoreboard").innerHtml+="</table>";
}

function parseScoreLine (score) {
	score
}
function getTeamName (teamID) {
	alert(teamID);
	for (team in teamList) {
		if (team.teamId === teamID) return team.simpleName;
	}
}

function requestTest() {
	document.getElementById("change").innerHtml = "Not Empty";
	var url = "http://stats.nba.com/stats/scoreboardv2/?GameDate=3/29/16&LeagueID=00&DayOffset=0";
	var request = new XMLHttpRequest();
	request.open('GET', url, true);
	request.setRequestHeader("referer", "http://stats.nba.com/scores/");
	request.setRequestHeader("user-agent", "('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) '                           'AppleWebKit/537.36 (KHTML, like Gecko) '                           'Chrome/45.0.2454.101 Safari/537.36')");
	request.onreadystatechange = function() {
		if (xhttp.readyState == 4 && xhttp.status == 200) {
		document.getElementById("change").innerHtml = request.ResponseText;
		}
	}
	request.send();
}
function postPlayerCurls() {
	for(player in players) {

	}
}

function playerUpdate(playerId, historical) {
	for(player in playerList) {
		if player.playerId = playerId {
			player.stats = historical.resultSets[0].rowSet[0][0];
		}
	}
}

function getPlayerCurl() {
	var xhttp = new XMLHttpRequest();
	xhttp.onLoad = function() {
		var result = JSON.parse(xhttp.responseText);
		playerUpdate(result.parameters.PlayerID, result);
	}
 }
