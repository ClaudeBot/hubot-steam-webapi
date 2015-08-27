# hubot-steam-webapi

[![Build Status](https://travis-ci.org/ClaudeBot/hubot-steam-webapi.svg)](https://travis-ci.org/ClaudeBot/hubot-steam-webapi)
[![Dependency Status](https://david-dm.org/ClaudeBot/hubot-steam-webapi.svg)](https://david-dm.org/ClaudeBot/hubot-steam-webapi)

A Hubot script for interacting with Steam Web API (primarily for Dota 2).

See [`src/steam.coffee`](src/steam.coffee) for full documentation.


## Installation via NPM

1. Install the __hubot-steam-webapi__ module as a Hubot dependency by running:

    ```
    npm install --save hubot-steam-webapi
    ```

2. Enable the module by adding the __hubot-steam-webapi__ entry to your `external-scripts.json` file:

    ```json
    [
        "hubot-steam-webapi"
    ]
    ```

3. Run your bot and see below for available config / commands


## Configuration

Variable | Default | Description
--- | --- | ---
`STEAM_API_KEY` | N/A | A unique developer [API key](http://steamcommunity.com/dev/apikey) is required to use Steam's Web API
`DOTA_MAX_RESULTS` | 5 | The maximum number of result(s) to return (for matches)


## Commands

Command | Listener ID | Description
--- | --- | ---
hubot steam id `[me] custom URL` | `steam.profile.id` | Returns the Steam ID for the user under http://steamcommunity.com/id/ `custom URL`
hubot steam status `Steam ID or custom URL` | `steam.profile.status` | Returns `Steam ID` or `custom URL` community status
hubot dota history `Steam ID or custom URL` | `steam.dota.history` | Returns metadata for the latest `DOTA_MAX_RESULTS` (or 5) game lobbies with `Steam ID` or `custom URL`
hubot dota match `match ID [Steam ID or custom URL]` | `steam.dota.match` | Returns information about a particular `match ID`. Optionally, if `Steam ID` or `custom URL` is included, its match information will also be returned


## Sample Interaction

```
user1>> hubot dota history MrSaints
hubot>> Match ID: 1588262704 | Lobby: Ranked match | Hero: Winter Wyvern | 7 hours ago
```
