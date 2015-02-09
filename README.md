# Hubot: Steam Web API

[![Dependency Status](https://david-dm.org/ClaudeBot/hubot-steam-webapi.svg?style=flat-square)](https://david-dm.org/ClaudeBot/hubot-steam-webapi)

A Hubot script for interacting with Steam Web API (primarily for Dota 2).


## Installation via NPM

1. Install the __hubot-steam__ module as a Hubot dependency by running:

    ```
    npm install --save hubot-steam
    ```

2. Enable the script by adding the __hubot-steam__ entry to your `external-scripts.json` file:

    ```json
    [
        "hubot-steam"
    ]
    ```

3. Run `npm install`


## Configuration

Variable | Default | Description
--- | --- | ---
`STEAM_API_KEY` | N/A | A unique developer [API key](http://steamcommunity.com/dev/apikey) is required to use Steam's Web API
`DOTA_MAX_RESULTS` | 5 | The maximum number of result(s) to return (for matches)


## Commands

Command | Description
--- | ---
hubot steam id `[me] custom URL` | Returns the Steam ID for the user under http://steamcommunity.com/id/ `custom URL`
hubot steam status `Steam ID or custom URL` | Returns `Steam ID` or `custom URL` community status
hubot dota history `Steam ID or custom URL` | Returns metadata for the latest `DOTA_MAX_RESULTS` (or 5) game lobbies with `Steam ID` or `custom URL`
hubot dota match `match ID [Steam ID or custom URL]` | Returns information about a particular `match ID`. Optionally, if `Steam ID` or `custom URL` is included, its match information will also be returned
