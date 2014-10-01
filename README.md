# Hubot: Steam Web API

A Hubot script for interacting with Steam Web API (primarily for Dota 2).


## Installation via NPM

1. Install the __hubot-steam__ module as a Hubot dependency by adding it to your `package.json` file:

    ```
    npm install --save hubot-steam
    ```

2. Enable the script by adding the __hubot-steam__ entry to your `external-scripts.json` file:

    ```json
    ["hubot-steam"]
    ```

3. Run `npm install`


## Config

- `STEAM_API_KEY`
- `HUBOT_DOTA_MAX_RESULTS` _(TBA)_


## Commands

Command | Description
--- | ---
hubot steam __id__ `[me] custom URL` | Returns the Steam ID for the user under http://steamcommunity.com/id/`custom URL`
hubot steam __status__ `Steam ID|custom URL` | Returns `Steam ID` or `custom URL` community status
hubot dota __history__ `Steam ID|custom URL` | Returns metadata for the latest 5 game lobbies with <Steam ID> or <custom URL>
hubot dota __match__ `match ID` `[Steam ID|custom URL]` | Returns information about a particular `match ID`. Optionally, if `Steam ID` or `custom URL` is included, its match information will also be returned
