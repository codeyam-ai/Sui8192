# Sui 8192

A fully on-chain, extra challenging version of the popular 2048 game. Built on [Sui](https://sui.io) by [Ethos](https://ethoswallet.xyz).

You can play Sui 8192 at [https://ethoswallet.github.io/Sui8192](https://ethoswallet.github.io/Sui8192)

Sui 8192 consists of a smart contract that allows the player to mint a game that is playable on chain.

The front-end submits transaction to the Sui blockchain that calculates the next state of the game board. That next state is returned to the front end to display the next state. Most of the logic in the front-end involves diffing and animating the game board states to create an interesting and enjoyable user experience.

## Sui

This project is built on the [Sui blockchain](https://sui.io), which provides the performance necessary for a great game experience. Every move is a transaction that is recorded on-chain, making the gameplay verifiable, shareable, and transferable. Each game is an NFT that can be sent to anyone and will display in a web3 wallet (such as the [Ethos Wallet](https://chrome.google.com/webstore/detail/ethos-wallet/mcbigmjiafegjnnogedioegffbooigli)).

## Ethos

This project uses the [Ethos APIs](https://ethoswallet.xyz/developers) to make the Sui 8192 game accessible to people who do not yet have a web3 wallet. It allows them to start playing the game right away without having to figure out a wallet first.

As far as the game is concerned every player has a wallet because the [Ethos APIs](https://ethoswallet.xyz/developers) provide a unified interface for both players with and without wallets.

The primary methods that this game uses to do this are:

`<EthosConnectProvider>`, `SignInButton`, and `ethos.transact()`

Each of these can be found by searching in `js/game.js`

- The Ethos APIs currently require `react` and `react-dom` which is why they are included.

## The Smart Contract

The Sui 8192 smart contract is written Sui Move for deployment on the Sui blockchain. It consists of three parts:

1. **Game:** Primarily entry functions for making moves and recording the overall game state.

2. **Game Board:** Most of the game logic.

3. **Leaderboard:** A shared object that accepts games, sorting them into order based on top tile and score.

The code for the smart contract is in the "move" folder.

If you deploy the smart contract and want to use the new deployment in the game you'll need to edit `js/constants.js` and set the contract address and leaderboard address.

You wil see output like this:

```
Created Objects:
  - ID: 0x6d86e967767b3d736447bc5f29c74e8b6b9c5dd7 , Owner: Immutable
  - ID: 0xf9803ad429fe9083a6c26f52c4f1ffa981d5ccbf , Owner: Shared
```

The immutable object is the contract address and the shared object is the leaderboard address.

### Working With The Smart Contract

From the `move` folder:

#### Build

`sui move build`

#### Test

`sui move test`

or

`sui move test --filter SUBSTRING`

#### Deploy

`sui client publish --gas-budget 10000`

## The Front-End

The front end is written in plain javascript, html, and css. It has minimal dependencies and is statically hosted on GitHub, using the blockchain for all persistent state.

It has react as a dependency to work properly with the Ethos apis which provide wallet connecting capabilities as well as an easy pathway for people who do not yet have a wallet to play the game via email or social authentication.

### Working With The Front-End

#### Initialization

`yarn`

#### Running

`yarn start`

(Note: the site can also be built using `yarn build` and `index.html` can be opened, but some aspects of the game require it be run via a server - it still works as a statically hosted website, though)
