# Description:
#   Steam Web API w/ Dota 2
#
# Configuration:
#   STEAM_API_KEY
#   DOTA_MAX_RESULTS
#
# Commands:
#   hubot steam id [me] <custom URL> - Returns the Steam ID for the user under http://steamcommunity.com/id/<custom URL>
#   hubot steam status <Steam ID|custom URL> - Returns <Steam ID> or <custom URL> community status
#   hubot dota history <Steam ID|custom URL> - Returns metadata for the latest DOTA_MAX_RESULTS (or 5) game lobbies with <Steam ID> or <custom URL>
#   hubot dota match <match ID> [<Steam ID|custom URL>] - Returns information about a particular <match ID>. Optionally, if <Steam ID> or <custom URL> is included, its match information will also be returned
#
# Author:
#   MrSaints
#
# Notes:
#   * Refactor persistence
#   * Community name? (Alias)

fs = require "fs"
path = require "path"

moment = require "moment"
require "ref"

#
# Config
#
STEAM_API_KEY = process.env.STEAM_API_KEY
STEAM_API_URL = "https://api.steampowered.com"
DOTA_MAX_RESULTS = process.env.DOTA_MAX_RESULTS or 5

#
# Definitions
#
STEAM_USER_STATES = [
    "Offline"
    "Online"
    "Busy"
    "Away"
    "Snooze"
    "Looking to trade"
    "Looking to play"
]
DOTA_LOBBIES =
    "-1": "Invalid"
    0: "Public matchmaking"
    1: "Practice"
    2: "Tournament"
    3: "Tutorial"
    4: "Co-op with bots"
    5: "Team match"
    6: "Solo queue"
    7: "Ranked match"
DOTA_TOWERS = [
    "Ancient top"
    "Ancient bottom"
    "Bottom tier 3"
    "Bottom tier 2"
    "Bottom tier 1"
    "Middle tier 3"
    "Middle tier 2"
    "Middle tier 1"
    "Top tier 3"
    "Top tier 2"
    "Top tier 1"
]
DOTA_HEROES = {}

#
# Brain / Persistence
#
_brain = null
_GetSteamData = ->
    _brain.data.steam or= {}

#
# Steam API
#
GetSteamResult = (msg, endpoint, params = {}, handler, version = 1) ->
    params.key = STEAM_API_KEY

    msg.http("#{STEAM_API_URL}/#{endpoint}/v#{version}/")
        .query(params)
        .get() (err, res, body) ->
            if err or res.statusCode isnt 200
                err = "Bad request (invalid Steam web API key)" if res.statusCode is 400
                msg.reply "An error occurred while attempting to process your request. Please try again later."
                log = if msg.logger? then msg.logger else msg.robot.logger
                return log.error err
            handler JSON.parse(body)

#
# User API
#
GetSteamID = (msg, customURL, callback) ->
    # Retrieve from cache
    return callback steamID for steamID, user of _GetSteamData() when user.url is customURL

    # Retrieve from API
    GetSteamResult msg, "ISteamUser/ResolveVanityURL", vanityurl: customURL, (object) ->
        if object.response.success is 42
            msg.reply "The custom URL you have entered (\"#{customURL}\") does not exist."
            return

        # Cache results
        _GetSteamData()[object.response.steamid] or= {}
        _GetSteamData()[object.response.steamid].url = customURL
        callback object.response.steamid

_GetCommunityID = (steamID) ->
    # Retrieve from cache
    if _GetSteamData()[steamID]?.cID?
        return _GetSteamData()[steamID].cID

    # Retrieve through calculating
    buffer = new Buffer 8
    buffer.writeUInt64LE steamID, 0
    communityID = buffer.readUInt32LE 0

    # Cache results
    _GetSteamData()[steamID] or= {}
    _GetSteamData()[steamID].cID = communityID
    communityID

GetPlayerSummaries = (msg, genericID, callback) ->
    summary = (steamID) ->
        GetSteamResult msg, "ISteamUser/GetPlayerSummaries", steamids: steamID, (object) ->
            callback object.response.players[0]
        , 2

    # Steam ID
    if _IsSteamID genericID
        summary genericID
    # Custom URL -> Steam ID
    else
        GetSteamID msg, genericID, (steamID) ->
            summary steamID

_GetStatus = (status = 0, invisible = 0) ->
    if invisible then "Unavailable (Private)" else STEAM_USER_STATES[status]

_IsSteamID = (steamID) ->
    steamID.match /\d{17}/

#
# Dota API
#
GetHeroes = (msg, callback) ->
    GetSteamResult msg, "IEconDOTA2_570/GetHeroes", language: "en", (object) ->
        mappedHeroes = {}
        for hero in object.result.heroes
            mappedHeroes[hero.id] = hero.localized_name
        callback mappedHeroes

GetMatchDetails = (msg, matchID, callback) ->
    GetSteamResult msg, "IDOTA2Match_570/GetMatchDetails", match_id: matchID, (object) ->
        callback object.result

GetMatchHistory = (msg, genericID, callback) ->
    history = (steamID, type = "Steam ID") ->
        params =
            account_id: steamID
            matches_requested: DOTA_MAX_RESULTS
        GetSteamResult msg, "IDOTA2Match_570/GetMatchHistory", params, (object) ->
            if object.result.status is 15
                msg.reply "The user has disabled the \"Expose Public Match Data\" option."
                return
            else if object.result.num_results is 0
                msg.reply "No game matches were found for the #{type}: #{genericID}."
            callback steamID, object.result

    # Steam ID
    if _IsSteamID genericID
        history genericID
    # Custom URL -> Steam ID
    else
        GetSteamID msg, genericID, (steamID) ->
            history steamID, "profile URL"

_GetTowers = (dec) ->
    for status, tower in "00000000000#{(+dec).toString(2)}".slice(-11).split("")
        if parseInt(status) then DOTA_TOWERS[tower] else continue

_GetFaction = (position) ->
    if position > 4 then "Dire" else "Radiant"

_GetPlayer = (communityID, playersPool) ->
    return player for player in playersPool when player.account_id is communityID
    false

#
# Common
#
Init = (robot) ->
    if not STEAM_API_KEY?
        return robot.logger.error "Missing STEAM_API_KEY in environment. Please set and try again."

    GetHeroes robot, (heroes) ->
        DOTA_HEROES = heroes

    # TODO: Cleaner dependency
    robot.brain.resetSaveInterval 1800
    _brain = robot.brain

_PossessionModifier = (noun) ->
    noun += if noun.slice(-1) is "s" then "'" else "'s"

#
# Hubot commands
#
module.exports = (robot) ->
    Init robot

    # GET 32-bit Steam ID
    robot.respond /steam id( me)? (.+)/i, (msg) ->
        customURL = msg.match[2]
        GetSteamID msg, customURL, (steamID) ->
            msg.reply "#{_PossessionModifier(customURL)} Steam ID is: #{steamID}"

    # GET Steam profile status
    robot.respond /steam status (.+)/i, (msg) ->
        genericID = msg.match[1]
        GetPlayerSummaries msg, genericID, (player) ->
            status = _GetStatus player.personastate, player.communityvisibilitystate
            lastOnline = moment.unix(player.lastlogoff).fromNow()
            msg.reply "#{genericID} belongs to #{player.personaname} who is currently #{status} and was last online #{lastOnline}."

    # GET Player Dota 2 match history (overview)
    robot.respond /dota history (.+)/i, (msg) ->
        genericID = msg.match[1]
        GetMatchHistory msg, genericID, (steamID, history) ->
            communityID = _GetCommunityID steamID

            for match in history.matches
                date = moment.unix(match.start_time).fromNow()
                target = _GetPlayer communityID, match.players
                hero = DOTA_HEROES[target.hero_id] or "No hero"
                # TODO: W / L TBA
                msg.send "Match ID: #{match.match_id} | Lobby: #{DOTA_LOBBIES[match.lobby_type]} | Hero: #{hero} | #{date}"

    # GET Player Dota 2 match details
    robot.respond /dota match (\d+)\s*(.+)?/i, (msg) ->
        matchID = msg.match[1]
        genericID = msg.match[2]
        GetMatchDetails msg, matchID, (match) ->
            date = moment.unix(match.start_time).fromNow()
            duration = moment.duration(match.duration, "seconds").minutes()
            firstBlood = moment.duration(match.first_blood_time, "seconds").humanize()
            victor = if match.radiant_win then "Radiant" else "Dire"
            radiantTowers = _GetTowers(match.tower_status_radiant).join(", ") or "None"
            direTowers = _GetTowers(match.tower_status_dire).join(", ") or "None"

            msg.send "Match ID #{match.match_id} is a #{DOTA_LOBBIES[match.lobby_type].toLowerCase()} game that took place #{date}. The #{victor} won the game in #{duration} minutes. First blood was drawn #{firstBlood} into the game."

            # Generate map image and graphs?
            msg.send "Radiant towers remaining: #{radiantTowers} | Dire towers remaining: #{direTowers}"
            msg.send "Dotabuff: http://www.dotabuff.com/matches/#{match.match_id}"

            additionalInfo = (steamID, type = "Steam ID") ->
                communityID = _GetCommunityID steamID
                target = _GetPlayer communityID, match.players
                unless target
                    msg.reply "The #{type} you have entered (\"#{genericID}\") was not found in Match ID #{match.match_id}."
                    return
                faction = _GetFaction target.player_slot
                hero = DOTA_HEROES[target.hero_id] or "No hero"
                msg.reply "#{faction} - #{hero} (Lvl #{target.level}) | KDA: #{target.kills}/#{target.deaths}/#{target.assists} | LH: #{target.last_hits} | GPM: #{target.gold_per_min} | XPM: #{target.xp_per_min} | HD: #{target.hero_damage} | TD: #{target.tower_damage} | TGE: #{target.gold_per_min*duration}"
                # Future (TODO): Team fight contribution? Overall contribution algo.

            if genericID?
                if _IsSteamID genericID
                    additionalInfo steamID
                else
                    GetSteamID msg, genericID, (steamID) ->
                        additionalInfo steamID, "profile URL"