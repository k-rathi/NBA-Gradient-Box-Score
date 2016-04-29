============================ Yahoo NBA to get Scoreboard =================================
# Scoreboard for specific date (live/final/schedule)
    curl http://sports.yahoo.com/nba/scoreboard/?date=2016-03-28

# Today's Scoreboard (based on East Coast Time) for specific date (live/final/schedule)
    curl http://sports.yahoo.com/nba/scoreboard/

# Tomorrow's Schedule Scoreboard (based on East Coast Time) for specific date
    curl http://sports.yahoo.com/nba/scoreboard/?date=2016-03-30

============================ NBA.com to get Live Game stats =================================
DATE/<AWAY><HOME>/gameinfo.html:
Already finished game:
    http://www.nba.com/games/20160328/BOSLAC/gameinfo.html?ls=iref:nba:scoreboard

Currently Ongoing game:
    http://www.nba.com/games/20160329/HOUCLE/gameinfo.html?ls=iref:nba:scoreboard

Files Needed:
  DTUtil.pm
  Game.pm
  genCalendarDataHTML.pl
  JSONHelper.pm
  NBAGameInfo.pm
  parseNBAYahooHTML.pl
  PlayerStat.pm
  Team.pm
  YahooScorecard.pm
  README.txt
