const React = require("react");
const ReactDOM = require("react-dom/client");
const { EthosConnectProvider, SignInButton, TransactionBlock, ethos } = require("ethos-connect");

const leaderboard = require("./leaderboard");
const { 
  devnetContractAddress,
  devnetLeaderboardAddress,
  testnetContractAddress,
  testnetLeaderboardAddress,
} = require("./constants");
const {
  eById,
  eByClass,
  addClass,
  removeClass,
  truncateMiddle,
  formatBalance,
  setOnClick,
} = require("./utils");
const modal = require("./modal");
const queue = require("./queue");
const board = require("./board");
const moves = require("./moves");
const confetti = require("./confetti");

const DASHBOARD_LINK = "https://ethoswallet.xyz/dashboard";
const LOCALNET = "http://127.0.0.1:9000";
const DEVNET = "https://fullnode.devnet.sui.io/"
const TESTNET = "https://fullnode.testnet.sui.io/"
const LOCALNET_NETWORK_NAME = 'local';
const DEVNET_NETWORK_NAME = 'devNet';
const TESTNET_NETWORK_NAME = 'testNet';
const LOCALNET_CHAIN = "sui:local";
const DEVNET_CHAIN = "sui:devnet";
const TESTNET_CHAIN = "sui:testnet";

let contractAddress = testnetContractAddress;
let leaderboardAddress = testnetLeaderboardAddress;
let networkName = TESTNET_NETWORK_NAME;
let chain = TESTNET_CHAIN;
let walletSigner;
let games;
let activeGameAddress;
let walletContents = null;
let topTile = 2;
let contentsInterval;
let faucetUsed = false;
let network = TESTNET;
let root;

const int = (intString = "-1") => parseInt(intString);

const setActiveGameAddress = () => {
  const queryParams = new URLSearchParams(window.location.search);
  if (queryParams.get('objectId')) {
    activeGameAddress = queryParams.get('objectId');
  }
}

const setNetwork = (newNetworkName) => {
  if (newNetworkName === networkName) return;

  const queryParams = new URLSearchParams(window.location.search);
  if (queryParams.get('network') !== newNetworkName) {
    window.history.pushState(
      {},
      '',
      `?network=${newNetworkName}`
    );
    window.location.reload();  
  }

  if (newNetworkName === LOCALNET_CHAIN) {
    networkName = LOCALNET_NETWORK_NAME;
    network = LOCALNET;
    chain = LOCALNET_CHAIN;
    contrcontractAddressact = devnetContractAddress;
    leaderboardAddress = devnetLeaderboardAddress;
  } else if (newNetworkName === TESTNET_NETWORK_NAME) {
    networkName = TESTNET_NETWORK_NAME;
    network = TESTNET;
    chain = TESTNET_CHAIN;
    contractAddress = testnetContractAddress
    leaderboardAddress = testnetLeaderboardAddress;
  } else {
    networkName = DEVNET_NETWORK_NAME;
    network = DEVNET;
    chain = DEVNET_CHAIN;
    contractAddress = devnetContractAddress;
    leaderboardAddress = devnetLeaderboardAddress;
  }

  removeClass(eByClass('network-button'), 'selected');
  addClass(eByClass(newNetworkName), 'selected');
  
  init();
}

const initializeNetwork = () => {
  const queryParams = new URLSearchParams(window.location.search);
  const initialNetwork = queryParams.get('network') ?? TESTNET_NETWORK_NAME;
  
  setNetwork(initialNetwork, true);

  setOnClick(eByClass(DEVNET_NETWORK_NAME), () => setNetwork(DEVNET_NETWORK_NAME));
  setOnClick(eByClass(TESTNET_NETWORK_NAME), () => setNetwork(TESTNET_NETWORK_NAME));
}

const initializeKeyListener = () => {
  window.onkeydown = (e) => {
    let direction;
    switch (e.keyCode) {
      case 37:
        direction = "left";
        break;
      case 38:
        direction = "up";
        break;
      case 39:
        direction = "right";
        break;
      case 40:
        direction = "down";
        break;
    }
    if (!direction) return;

    e.preventDefault();

    moves.execute(
      chain,
      contractAddress,
      direction,
      activeGameAddress,
      walletSigner,
      (newBoard, direction) => {
        handleResult(newBoard, direction);
        loadWalletContents();
      },
      ({ error, gameOver }) => {
        if (gameOver) {
          showGameOver();
        } else if (error) {
          showUnknownError(error);
        } else {
          showGasError();
        }
      }
    );
  };
};

function init() {
  // test();
  initializeNetwork();
  setActiveGameAddress();

  leaderboard.load(network, leaderboardAddress);

  const ethosConfiguration = {
    apiKey: "8b6347aa-c5fb-460a-8fcc-efeb277f76fc",
    chain,
    network,
    preferredWallets: ['Ethos Wallet']
  };

  const start = eById("ethos-start");
  const button = React.createElement(SignInButton, {
    key: "sign-in-button",
    className: "start-button",
    children: "Sign In",
  });

  const wrapper = React.createElement(EthosConnectProvider, {
    ethosConfiguration,
    onWalletConnected,
    children: [button],
  });

  if (!root) {
    root = ReactDOM.createRoot(start);
  }
  root.render(wrapper);

  initializeClicks();
}

function handleResult(newBoard, direction) {
  if (newBoard.topTile > topTile) {
    topTile = newBoard.topTile;
    const topTiles = eByClass("top-tile-display");
    for (const topTile of topTiles) {
      topTile.innerHTML = `<img src='https://sui8192.s3.amazonaws.com/${newBoard.topTile}.png' />`;
    }
    confetti.run();

    setTimeout(() => {
      if (
        topTile >= leaderboard.minTile() &&
        newBoard.score > leaderboard.minScore()
      ) {
        modal.open("high-score", "container");
      } else {
        modal.open("top-tile", "container");
      }
    }, 1000);
  }

  const tiles = eByClass("tile");
  const resultDiff = board.diff(
    board.active().packedSpaces,
    newBoard.packedSpaces,
    direction
  );

  const scoreDiff = parseInt(newBoard.score) - parseInt(board.active().score);
  if (scoreDiff > 0) {
    const scoreDiffElement = eById("score-diff");
    scoreDiffElement.innerHTML = `+${scoreDiff}`;
    addClass(scoreDiffElement, "floating");
    setTimeout(() => {
      removeClass(scoreDiffElement, "floating");
    }, 2000);
  }

  for (const key of Object.keys(resultDiff)) {
    const resultItem = resultDiff[key];
    const tile = tiles[parseInt(key)];

    if (resultItem[direction]) {
      const className = `${direction}${resultItem[direction]}`;
      addClass(tile, className);
      setTimeout(() => {
        removeClass(tile, className);
      }, 500);
    }

    if (resultItem.merge) {
      setTimeout(() => {
        addClass(tile, "merge");
        setTimeout(() => {
          removeClass(tile, "merge");
        }, 500);
      }, 80);
    }
  }

  setTimeout(() => {
    board.display(newBoard);
  }, 150);
}

function showGasError() {
  queue.removeAll();
  addClass(eByClass("error"), "hidden");
  removeClass(eById("error-gas"), "hidden");
}

function showGameOver() {
  queue.removeAll();
  addClass(eByClass("error"), "hidden");
  removeClass(eById("error-game-over"), "hidden");
}

function showUnknownError(error) {
  queue.removeAll();
  addClass(eByClass("error"), "hidden");
  eById("error-unknown-message").innerHTML = error;
  removeClass(eById("error-unknown"), "hidden");
}

async function tryDrip(address, suiBalance) {
  if (!walletSigner || faucetUsed) return;
  const dripNetwork = LOCALNET
  faucetUsed = true;

  let success;
  
  try {
    success = await ethos.dripSui({ address, network: dripNetwork });
  } catch (e) {
    console.log("Error with drip", e);
    faucetUsed = false;
    return;
  }

  if (!success) {
    const contents = await ethos.getWalletContents({ 
      address,
      network,
      existingContents: walletContents
    });

    const { suiBalance: balanceCheck } = contents || walletContents;

    if (suiBalance !== balanceCheck) {
      success = true;
    }
  }

  if (success) {
    removeClass(eById("faucet"), "hidden");
    faucetUsed = true;
    loadWalletContents();
  }
}

async function loadWalletContents() {
  if (!walletSigner?.currentAccount) return;
  const address = walletSigner.currentAccount.address
  const addressElement = eById("wallet-address")
  if (addressElement) {
    addressElement.innerHTML = truncateMiddle(address, 4);
  }

  const contents = await ethos.getWalletContents({ 
    address, 
    network,
    existingContents: walletContents 
  });

  if (contents) walletContents = contents;
  
  const { suiBalance } = walletContents;

  if (suiBalance < 5000000) {
    tryDrip(address, suiBalance);
  }

  const balance = eById("balance")
  if (balance) {
    balance.innerHTML = formatBalance(suiBalance, 9) + " SUI";
  }
}

async function loadGames() {
  const loadGamesElement = eById("loading-games");
  if (!loadGamesElement) return;

  if (!walletSigner || !leaderboard) {
    setTimeout(loadGames, 500);
    return;
  }
  removeClass(loadGamesElement, "hidden");

  const gamesElement = eById("games-list");
  gamesElement.innerHTML = "";

  await loadWalletContents();

  addClass(loadGamesElement, "hidden");

  games = walletContents.nfts
    .filter((nft) => nft.package === contractAddress)
    .map((nft) => ({
      address: nft.address,
      board: nft.extraFields.active_board,
      topTile: nft.extraFields.top_tile,
      score: nft.extraFields.score,
      imageUri: nft.imageUri,
      gameOver: nft.extraFields.game_over,
    }))
    .sort((a, b) => {
      const scoreDiff = b.score - a.score;
      if (b.gameOver && a.gameOver) return scoreDiff;
      if (a.gameOver) return 1;
      if (b.gameOver) return -1;
      return scoreDiff;
    });
  
  if (activeGameAddress) {
    const activeGame = games.find((game) => game.address === activeGameAddress);
    if (activeGame) {
      setActiveGame(activeGame);
      return; 
    }
  }

  if (!games || games.length === 0) {
    const newGameArea = document.createElement("DIV");
    newGameArea.classList.add("text-center");
    newGameArea.classList.add("padded");
    newGameArea.innerHTML = `
      <p>
        You don't have any games yet.
      </p>
    `;
    gamesElement.append(newGameArea);
  }

  let highScore = 0;
  for (const game of games) {
    if (highScore < parseInt(game.score)) {
      highScore = parseInt(game.score);
    }

    const gameElement = document.createElement("DIV");
    let topGames = await leaderboard.topGames(network, leaderboardAddress);
    if (topGames.length === 0) topGames = [];
    const leaderboardItemIndex = topGames.findIndex(
      (top_game) => top_game.fields.game_id === game.address
    );
    const leaderboardItem = topGames[leaderboardItemIndex];
    const leaderboardItemUpToDate =
      int(leaderboardItem?.fields.score) === int(game.score) || (
        int(game.topTile) <= int(leaderboard.minTile()) && 
        int(game.score) <= int(leaderboard.minScore())
      );
    addClass(gameElement, "game-preview");
    setOnClick(gameElement, () => {
      addClass(eById("leaderboard"), "hidden");
      removeClass(eById("game"), "hidden");
      setActiveGame(game);
    });

    const topTile = parseInt(game.topTile)
    gameElement.innerHTML = `
      <div class='leader-stats flex-1'> 
        <div class='leader-tile subsubtitle color${topTile}'>
          ${Math.pow(2, topTile)}
        </div>
        <div class='leader-score'>
          Score <span>${game.score}</span>
        </div>
        <div class='game-over'>${game.gameOver ? "Ended" : ""}</div>
      </div>
      <div class='game-preview-right'> 
        <div class="${
          leaderboardItem && leaderboardItemUpToDate ? "" : "hidden"
        }">
          <span class="light">Leaderboard:</span> <span class='bold'>${
            leaderboardItemIndex + 1
          }</span>
        </div>
        <button class='potential-leaderboard-game ${
          leaderboardItemUpToDate ? "hidden" : ""
        }' data-address='${game.address}'>
          ${leaderboardItem ? "Update" : "Add To"} Leaderboard
        </button>
      </div>
    `;

    gamesElement.append(gameElement);
  }

  setOnClick(eByClass("potential-leaderboard-game"), (e) => {
    const {
      dataset: { address },
    } = e.target;
    e.stopPropagation();
    leaderboard.submit(network, chain, contractAddress, address, walletSigner, () => {
      loadGames();
    });
  });

  const personalHighScore = eById('personal-high-score')
  if (personalHighScore) {
    personalHighScore.innerHTML = highScore;
  }
}

async function setActiveGame(game) {
  if (!game) {
    activeGameAddress = null;
  }
  
  addClass(eByClass("error"), "hidden");
  initializeKeyListener();
  activeGameAddress = game.address;

  const transactionsList = eById("transactions-list");
  if (!transactionsList) return;
  
  transactionsList.innerHTML = "";
  moves.reset();
  moves.checkPreapprovals(chain, contractAddress, activeGameAddress, walletSigner);

  const activeBoard = board.convertInfo(game.board);
  topTile = activeBoard.topTile || 2;
  board.display(activeBoard);

  modal.close();
  addClass(eById("leaderboard"), "hidden");
  removeClass(eByClass("leaderboard-button"), "selected");
  removeClass(eById("game"), "hidden");
  addClass(eByClass("play-button"), "selected");

  setOnClick(eById("submit-game-to-leaderboard"), () => {
    showLeaderboard();
    leaderboard.submit(network, chain, contractAddress, activeGameAddress, walletSigner, () => {
      loadGames();
    });
  });
}

function showLeaderboard() {
  setActiveGame(null);
  leaderboard.load(network, leaderboardAddress);
  loadGames();
  addClass(eById("game"), "hidden");
  removeClass(eByClass("play-button"), "selected");
  removeClass(eById("leaderboard"), "hidden");
  addClass(eByClass("leaderboard-button"), "selected");
}

const initializeClicks = () => {
  setOnClick(eByClass("close-error"), () => {
    addClass(eByClass("error"), "hidden");
  });
  setOnClick(eById("sign-in"), ethos.showSignInModal);
  setOnClick(eByClass("leaderboard-button"), showLeaderboard);
  setOnClick(eByClass("title"), () => ethos.showWallet(walletSigner));

  setOnClick(eById("balance"), () => window.open(DASHBOARD_LINK));
  setOnClick(eById("wallet-address"), () => window.open(DASHBOARD_LINK));

  setOnClick(eById("logout"), async (e) => {
    e.stopPropagation();
    await ethos.logout(walletSigner);
    walletSigner = null;
    games = null;
    activeGameAddress = null;
    walletContents = null;

    addClass(document.body, "signed-out");
    removeClass(document.body, "signed-in");
    addClass(eById("leaderboard"), "hidden");
    removeClass(eById("game"), "hidden");
    addClass(eById("loading-games"), "hidden");

    board.clear();

    modal.open("get-started", "board", true);
  });

  setOnClick(eById("close-modal"), () => modal.close(true));

  setOnClick(eByClass("play-button"), () => {
    if (games && games.length > 0) {
      addClass(eById("leaderboard"), "hidden");
      removeClass(eById("game"), "hidden");
      setActiveGame(games[0]);
    } else if (walletSigner) {
      eByClass("new-game")[0].onclick();
    } else {
      ethos.showSignInModal();
    }
  });

  setOnClick(eById("modal-submit-to-leaderboard"), () => {
    modal.close();
    showLeaderboard();
    leaderboard.submit(network, chain, contractAddress, activeGameAddress, walletSigner, () => {
      loadGames();
    });
  });

  setOnClick(eByClass("keep-playing"), modal.close);

  setOnClick(eById("close-faucet"), () => {
    addClass(eById("faucet"), "hidden");
  });

  setOnClick(eById("close-preapproval"), () => {
    addClass(eById("preapproval"), "hidden");
  });

  setOnClick(eById("close-hosted"), () => {
    addClass(eById("hosted"), "hidden");
  });
};

const onWalletConnected = async ({ signer }) => {
  walletSigner = signer;
  if (signer) {
    modal.close();

    addClass(document.body, "signed-in");

    if (walletSigner.type === "hosted") {
      removeClass(eById("hosted"), "hidden");
    }

    const prepMint = async () => {
      const mint = eById("mint-game");
      if (!mint) return;

      const mintButtonTitle = "Mint New Game";
      if (mint.innerHTML.indexOf(mintButtonTitle) === -1) {
        const mintButton = document.createElement("BUTTON");
        setOnClick(mintButton, async () => {
          modal.open("loading", "container");

          const transactionBlock = new TransactionBlock();
          transactionBlock.moveCall({
            target: `${contractAddress}::game_8192::create`,
            typeArguments: [],
            arguments: []
          })

          try {
            const data = await ethos.transact({
              signer: walletSigner,
              transactionInput: {
                transactionBlock,
                options: {
                  showEvents: true
                },
                requestType: 'WaitForLocalExecution'
              }
            });

            if (!data || data.error) {
              eById("create-error-error-message").innerHTML = data.error;
              modal.open("create-error", "container");
              return;
            }

            const { events } = data;
            const gameData = events.find((e) => e.type === `${contractAddress}::game_8192::NewGameEvent8192`)
            const { game_id, packed_spaces, score } = gameData.parsedJson;
            const game = {
              address: game_id,
              board: {
                score,
                packed_spaces,
                game_over: false,
              },
            };
            setActiveGame(game);
            ethos.hideWallet(walletSigner);
          } catch (e) {
            eById("create-error-error-message").innerHTML = e;
            modal.open("create-error", "container");
            return;
          }
        });
        mintButton.innerHTML = mintButtonTitle;
        mint.appendChild(mintButton);
      }
    };

    prepMint();
    modal.open("loading", "container");

    setOnClick(eByClass("new-game"), async () => {
      modal.open("mint", "container");
    });

    await loadGames();

    if (!contentsInterval) {
      contentsInterval = setInterval(loadWalletContents, 3000);
    }

    if (games.length === 0) {
      modal.open("mint", "board", true);
    } else {
      modal.close();

      if (games.length === 1) {
        setActiveGame(games[0]);
      } else {
        showLeaderboard();
      }
    }

    removeClass(document.body, "signed-out");

    const address = signer.currentAccount.address;

    setOnClick(eById("copy-address"), () => {
      const innerHTML = eById("copy-address").innerHTML;
      eById("copy-address").innerHTML = "Copied!";
      navigator.clipboard.writeText(address);
      setTimeout(() => {
        eById("copy-address").innerHTML = innerHTML;
      }, 1000);
    });
  } else {
    modal.open("get-started", "board", true);
    setOnClick(eByClass("new-game"), ethos.showSignInModal);
    addClass(document.body, "signed-out");
    removeClass(document.body, "signed-in");
    addClass(eById("loading-games"), "hidden");
  }
};

window.requestAnimationFrame(init);

/// FOR TESTING ///

// function print(board) {
//   const rows = board.length;

//   const printRows = []
//   for (let i=0; i<rows; ++i) {
//     printRows.push(board[i].join(','));
//   }
//   console.log(printRows.join('\n'));
// }

// function test() {
//   const boardStart = [
//     [0,  0,  null, null],
//     [null, null, 1,  null],
//     [0,  0,  1,  null],
//     [1,  null, 1,  null]
//   ]

//   const boardLeft = [
//     [1,  null, null, null],
//     [1,  null, null, null],
//     [1,  1,  null, null],
//     [2,  null, null, null]
//   ]

//   const boardRight = [
//     [null, null, null, 1],
//     [null, null, null, 1],
//     [null, null, 1,  1],
//     [null, null, null, 2]
//   ]

//   const boardUp = [
//     [1,  1,  2,  null],
//     [1,  null, 1,  null],
//     [null, null, null, null],
//     [null, null, null, null]
//   ]

//   const boardDown = [
//     [null, null, null, null],
//     [null, null, null, null],
//     [1,  null, 1,  null],
//     [1,  1,  2,  null]
//   ]

//   const tests = [{
//     direction: "left",
//     board1: boardStart,
//     board2: boardLeft,
//     result: {"0":{"merge":true},"1":{"left":1},"6":{"left":2},"8":{"merge":true},"9":{"left":1},"10":{"left":1},"12":{"merge":true},"14":{"left":2}}
//   }, {
//     direction: "right",
//     board1: boardStart,
//     board2: boardRight,
//     result: {"0":{"right":3},"1":{"right":2},"3":{"merge":true},"6":{"right":1},"8":{"right":2},"9":{"right":1},"10":{"merge":true},"12":{"right":3},"14":{"right":1},"15":{"merge":true}}
//   },{
//     direction: "up",
//     board1: boardStart,
//     board2: boardUp,
//     result: {"0":{"merge":true},"1":{"merge":true},"2":{"merge":true},"6":{"up":1},"8":{"up":2},"9":{"up":2},"10":{"up":2},"12":{"up":2},"14":{"up":2}}
//   }, {
//     direction: "down",
//     board1: boardStart,
//     board2: boardDown,
//     result: {"0":{"down":2},"1":{"down":3},"6":{"down":1},"8":{"merge":true},"9":{"down":1},"10":{"down":1},"13":{"merge":true},"14":{"merge":true}}
//   }, {
//     direction: "down",
//     board1: [
//       [1, 1, null,null],
//       [null,null,null,null],
//       [1, null,null,null],
//       [null,null,null,null]
//     ],
//     board2: [
//       [null,null,null,null],
//       [null,null,null,null],
//       [1, null,null,null],
//       [2, 1, null,null]
//     ],
//     result: {"0":{"down":3},"1":{"down":3},"8":{"down":1},"12":{"merge":true}}
//   }]

//   for (const t of tests) {
//     const { direction, board1: rawBoard1, board2, result } = t;
//     const board1 = rawBoard1.map(c => [...c])
//     const actualResult = board.diff(board1, board2, direction)
//     for (const key of Object.keys(result)) {
//       if (actualResult[key].merge !== result[key].merge || actualResult[key][direction] !== result[key][direction]) {
//         console.log("TEST FAILED!", key)
//       }
//     }
//   }
// }
