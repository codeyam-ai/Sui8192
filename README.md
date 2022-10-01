# Sui8192

A fully on-chain, extra challenging version of the popular 2048 game. Built on Sui by Ethos.

Sui8192 consists of a smart contract that allows the player to mint a game that is playable on chain.

The front-end submits transaction to the Sui blockchain that calculates the next state of the game board. That next state is returned to the front end to display the next state. Most of the logic in the front-end involves diffing and animating the game board states to create an interesting and enjoyable user experience.

## The Smart Contract

The Sui8192 smart contract is written Sui Move for deployment on the Sui blockchain. It consists of three parts:

1. **Game:** Primarily entry functions for making moves and recording the overall game state.

2. **Game Board:** Most of the game logic.

3. **Leaderboard:** A shared object that accepts games, sorting them into order based on top tile and score.

The code for the smart contract is in the "move" folder.

### Working With The Smart Contract

#### Build

`sui move build`

#### Test

`sui move test`

or

`sui move test --filter SUBSTRING`

#### Deploy

`sui client publish --path move/ --gas-budget 3000`

## The Front-End

The front end is written in plain javascript, html, and css. It has minimal dependencies and is statically hosted on GitHub, using the blockchain for all persistent state.

It has react as a dependency to work properly with the Ethos apis which provide wallet connecting capabilities as well as an easy pathway for people who do not yet have a wallet to play the game via email or social authentication.

### Working With The Front-End

#### Initialization

`yarn`

#### Running

`yarn build && npx browser-sync start --server`
