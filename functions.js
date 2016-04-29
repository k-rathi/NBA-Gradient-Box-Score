function parseScoreboard(scoreboard, date) {

    var primaryScoreboard = scoreboard.resultSets[0].rowSet;
    var secondaryScoreboard = scoreboard.resultSets[1].rowSet;

    var resultString = "";

    for (var i = 0; i < primaryScoreboard.length; i++) {

        var score = primaryScoreboard[i];

        var scoreAwayTeam = secondaryScoreboard[2 * i];
        var scoreHomeTeam = secondaryScoreboard[2 * i + 1];


        var homeTeamScore = scoreHomeTeam[21];
        var awayTeamScore = scoreAwayTeam[21];

        var homeRecord = scoreHomeTeam[6];
        var awayRecord = scoreAwayTeam[6];



        

        var gameStatus = score[4];

        var homeTeam = getTeamName(score[6]);
        var awayTeam = getTeamName(score[7]);

        var gameUrl = "http://http://www.nba.com/games/" + date + "/" + awayTeam + homeTeam + "/gameinfo.html";

        var vs = homeTeamScore + "-" + awayTeamScore;

        var timeLeft = score[10] + " " + score[4];

        if (homeTeamScore === null) {
            gameScore = gameStatus;
            vs = "vs";
        }

        resultString += "<div class = 'gameScores' id = 'indGameScore" + i + "' onclick = 'parseBoxScore(celticsClippers)'><table><tr><td>" + homeTeam + "</td><td>" + vs + "</td><td>" + awayTeam + "</td></tr><tr class = 'smaller'><td>" + homeRecord + "</td><td>" + timeLeft + "</td><td>" + awayRecord + "</td></tr></table></div>";
    }

    document.getElementById("scoreboard").innerHTML = resultString;

}

function getTeamId(teamName) {

    for (team in teamList) {

        if (team.simpleName === teamName) return team.teamId;
    }
}

function getTeamColorOne(teamName) {
    for (var i = 0; i < teamList.length; i++) {
        team = teamList[i];

        if (team.simpleName === teamName) return(team.color);
    }
}

function getTeamColorBold(teamName) {
    for (var i = 0; i < teamList.length; i++) {
        team = teamList[i];

        if (team.simpleName === teamName) return(team["bold-color"]);
    }
}

function getTeamName(teamID) {

    for (var i = 0; i < teamList.length; i++) {

        var team = teamList[i];

        if (teamList[i].teamId === teamID) return team.abbreviation;
    }
}
function changeDate() {
    var change = scoreboardV2;
    scoreboardV2 = newScoreboard;
    newScoreboard = change;
    parseScoreboard(scoreboardV2);
}



function parseBoxScore(boxscore) {
    var home = boxscore.Game.HomeTeam;
    var away = boxscore.Game.AwayTeam;
    document.getElementById("homeTeam").innerHTML = parseTeam(home, "home");
    setColorOne(home.NameKey, "home");
    document.getElementById("awayTeam").innerHTML = parseTeam(away, "away");
    setColorOne(away.NameKey, "away");
}

function setColorOne(team, homeAway) {
    var teamColorOne = getTeamColorOne(team);
    var teamColorBold = getTeamColorBold(team);
    var teamHeader = "header" + homeAway;
    teamHeader = document.getElementById(teamHeader)
    teamHeader.style.backgroundColor = teamColorBold; 
    teamHeader.style["font-size"] = "1.1em";

    var className = homeAway + "primary";
    var rows = document.getElementsByClassName(className);
    for(var i = 0; i < rows.length; i++) 
        rows[i].style.backgroundColor = teamColorOne;
}

function parseTeam(team, homeAway) {
    var resultString = "<div class = 'box'><table id='box-score2'><tr id = 'header" + homeAway + "'><td colspan = 3>";
    resultString += team.NameKey + "</td><td>Pos</td><td colspan = 2>Min</td><td colspan = 2>FG</td><td colspan = 2>3PG</td><td colspan=2>FTS</td><td>OR</td><td>DR</td><td>TR</td><td>AST</td><td>TO</td><td>STL</td><td>BS</td><td>BA</td><td>PF</td><td>+/-</td><td>PTS</td></tr>";
    var primaryColor = false;
    for (var i = 0; i < team.PlayerStatsList.length; i ++) {
        var player = team.PlayerStatsList[i];

        resultString += "<tr class ='" + homeAway;
        if (primaryColor === true) {
            resultString += "primary";
            primaryColor = false;
        }
        else {
            resultString += "secondary";
            primaryColor = true;
        }
        if(player.position === "X") {
         
            player.position = "";
            resultString += " inactive'>";
        }
        else resultString += " active'>";
        
        

        resultString += "<td colspan = 3>" + player.name + "</td><td>" + player.position + "</td><td colspan= 2>" + player.min_sec + "</td><td colspan = 2>" + player.fg_m + "-" + player.fg_a + "</td><td colspan = 2>" + player.pt3_m + "-" + player.pt3_a + "</td><td colspan = 2>" +  player.ft_m + "-" + player.ft_a + "</td><td>" + player.reb_off + "</td><td>" + player.reb_def + "</td><td>" + player.reb_tot + "</td><td>" + player.assists + "</td><td>" + player.turnovers + "</td><td>" + player.steals  + "</td><td>" + player.block_shots +  "</td><td>" + player.block_against +  "</td><td>" + player.pfouls +  "</td><td>" + player.plus_minus +  "</td><td>" + player.points + "</td></tr>";
    }
    resultString += "</table></div>";
    return resultString;
}