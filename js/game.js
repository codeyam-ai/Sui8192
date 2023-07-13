const React = require("react");
const { createClient } = require('@supabase/supabase-js');
const ReactDOM = require("react-dom/client");
const { EthosConnectProvider, SignInButton, TransactionBlock, ethos } = require("ethos-connect");

const leaderboard = require("./leaderboard");
const {
  originalMainnetContractAddress,
  mainnetContractAddress,
  mainnetLeaderboardAddress,
  mainnetMaintainerAddress,
  testnetContractAddress,
  testnetLeaderboardAddress,
  testnetMaintainerAddress,
  supabaseProject,
  supabaseAnonKey
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
const { default: BigNumber } = require("bignumber.js");
const contest = require('./contest');

const DASHBOARD_LINK = "https://ethoswallet.xyz/dashboard";
const LOCALNET = "http://127.0.0.1:9000";
const TESTNET = "https://fullnode.testnet.sui.io/"
// const MAINNET = "https://fullnode.mainnet.sui.io/"
const MAINNET = "https://sui.ethoswallet.xyz/sui"
const LOCALNET_NETWORK_NAME = 'local';
const TESTNET_NETWORK_NAME = 'testNet';
const MAINNET_NETWORK_NAME = 'mainNet';
const LOCALNET_CHAIN = "sui:local";
const TESTNET_CHAIN = "sui:testnet";
const MAINNET_CHAIN = "sui:mainnet";

const PAUSE_AT = 1000 * 60 * 60 * 2; // 2 hours

let originalContractAddress = originalMainnetContractAddress;
let contractAddress = mainnetContractAddress;
let leaderboardAddress = mainnetLeaderboardAddress;
let maintainerAddress = mainnetMaintainerAddress;
let networkName = MAINNET_NETWORK_NAME;
let chain = MAINNET_CHAIN;
let walletSigner;
let games;
let activeGameAddress;
let walletContents = null;
let topTile = 2;
let contentsInterval;
let faucetUsed = false;
let network = MAINNET;
let root;
let leaderboardType = (countdown.days <= 0 && countdown.hours <= 0 && countdown.minutes <= 0 && countdown.seconds <= 0) ? "contest" : "normal"
let countdownTimeout;
let lastPauseAt = new Date().getTime();

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
    originalContractAddress = testnetContractAddress;
    contractAddress = testnetContractAddress;
    leaderboardAddress = testnetLeaderboardAddress;
    maintainerAddress = testnetMaintainerAddress;
  } else if (newNetworkName === TESTNET_NETWORK_NAME) {
    networkName = TESTNET_NETWORK_NAME;
    network = TESTNET;
    chain = TESTNET_CHAIN;
    originalContractAddress = testnetContractAddress;
    contractAddress = testnetContractAddress
    leaderboardAddress = testnetLeaderboardAddress;
    maintainerAddress = testnetMaintainerAddress;
  } else {
    networkName = MAINNET_NETWORK_NAME;
    network = MAINNET;
    chain = MAINNET_CHAIN;
    originalContractAddress = originalMainnetContractAddress;
    contractAddress = mainnetContractAddress;
    leaderboardAddress = mainnetLeaderboardAddress;
    maintainerAddress = mainnetMaintainerAddress;
  }

  removeClass(eByClass('network-button'), 'selected');
  addClass(eByClass(newNetworkName), 'selected');
  
  init();
}

const initializeNetwork = () => {
  const queryParams = new URLSearchParams(window.location.search);
  const initialNetwork = queryParams.get('network') ?? MAINNET_NETWORK_NAME;
  
  setNetwork(initialNetwork, true);

  setOnClick(eByClass(MAINNET_NETWORK_NAME), () => setNetwork(MAINNET_NETWORK_NAME));
  setOnClick(eByClass(TESTNET_NETWORK_NAME), () => setNetwork(TESTNET_NETWORK_NAME));
}

let xDown = null;                                                        
let yDown = null;

const getTouches = (evt) => {
  return evt.touches
}                                                     
                                                                         
const handleTouchStart = (evt) => {
  const firstTouch = getTouches(evt)[0];                                      
  xDown = firstTouch.clientX;                                      
  yDown = firstTouch.clientY;                                      
};                                                
                                                                         
const handleTouchMove = (evt) => {
    if ( ! xDown || ! yDown ) {
        return;
    }

    var xUp = evt.touches[0].clientX;                                    
    var yUp = evt.touches[0].clientY;

    var xDiff = xDown - xUp;
    var yDiff = yDown - yUp;
                                                                         
    if ( Math.abs( xDiff ) > Math.abs( yDiff ) ) {/*most significant*/
        if ( xDiff > 0 ) {
          executeMove("left");
        } else {
          executeMove("right");
        }                       
    } else {
        if ( yDiff > 0 ) {
          executeMove("up");
        } else { 
          executeMove("down");
        }                                                                 
    }
    /* reset values */
    xDown = null;
    yDown = null;                                             
};

const initializeKeyListener = () => {
  const board = eById("board");
  board.addEventListener('touchstart', handleTouchStart, false);        
  board.addEventListener('touchmove', handleTouchMove, false);

  window.onkeydown = (e) => {
    switch (e.keyCode) {
      case 37:
      case 65:
        e.preventDefault();    
        executeMove("left");
        break;
      case 38:
      case 87:
        e.preventDefault();    
        executeMove("up");
        break;
      case 39:
      case 68:
        e.preventDefault();    
        executeMove("right");
        break;
      case 40:
      case 83:
        e.preventDefault();    
        executeMove("down");
        break;
    }
  };
}

const executeMove = (direction) => {
  if (!lastPauseAt) {
    return;
  }

  if (new Date().getTime() - lastPauseAt > PAUSE_AT) {
    lastPauseAt = null;
    showPauseModal();
  }

  moves.execute(
    chain,
    originalContractAddress,
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
      } else if (error.indexOf('Identifier("game_board_8192") }, function: 5, instruction: 43, function_name: Some("move_direction") }, 4') > -1) {
        return;
      } else if (error === "Insufficient gas") {
        showGasError();
      } else if (error) {
        showUnknownError(error);
      } else {
        showUnknownError("Sorry an unknown error occurred. Please try again in a moment.");
      }
    }
  );
}

const showPauseModal = () => {
  modal.open("pause", "container");
  eByClass('modal')[0].style.top = (100 + (Math.random() * 150)) + "px"
  eByClass('modal')[0].style.left = Math.random() * 50 + "px"
  setOnClick(eById("unpause"), () => {
    modal.close()
    eByClass('modal')[0].style.top = null;
    eByClass('modal')[0].style.left = null;
    lastPauseAt = new Date().getTime();
  });
}

function init() {
  // test();
  initializeNetwork();
  setActiveGameAddress();
  trackCountdown();

  leaderboard.load(network, leaderboardAddress, false, leaderboardType === "contest");

  const ethosConfiguration = {
    chain,
    network,
    preferredWallets: ['Ethos Wallet'],
    hideEmailSignIn: true,
    pollingInterval: 30000
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
      if (topTile < 9) return;
      if (        
        topTile >= leaderboard.minTile() &&
        newBoard.score > leaderboard.minScore()
      ) {
        // modal.open("climbing-leaderboard", "container");
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

// async function tryDrip(address, suiBalance) {
//   if (!walletSigner || faucetUsed && network !== MAINNET) return;
//   const dripNetwork = TESTNET
//   faucetUsed = true;

//   let success;
  
//   try {
//     success = await ethos.dripSui({ address, network: dripNetwork });
//   } catch (e) {
//     console.log("Error with drip", e);
//     faucetUsed = false;
//     return;
//   }

//   if (!success) {
//     const contents = await ethos.getWalletContents({ 
//       address,
//       network,
//       existingContents: walletContents
//     });

//     const { suiBalance: balanceCheck } = contents || walletContents;

//     if (suiBalance !== balanceCheck) {
//       success = true;
//     }
//   }

//   if (success) {
//     removeClass(eById("faucet"), "hidden");
//     faucetUsed = true;
//     loadWalletContents();
//   }
// }

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

  // const contents = await ethos.checkForAssetType({ 
  //   signer: walletSigner,
  //   type: `${originalContractAddress}::game_8192::Game8192`
  // });
  
  if (!contents) {
    setTimeout(loadWalletContents, 3000)
    return;
  }

  walletContents = contents;
  
  const { suiBalance } = walletContents;

  // if (suiBalance < 5000000) {
  //   tryDrip(address, suiBalance);
  // }

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

  let validIds;
  if (leaderboardType === "contest") {
    const { address } = walletSigner.currentAccount
     validIds = await contest.validIds(address);
  }

  games = walletContents.nfts
    .filter((nft) => {
      if (nft.packageObjectId !== originalContractAddress) {
        return false;
      }

      if (validIds && !validIds.includes(nft.objectId)) {
        return false;
      }

      return true;
    })
    // .map((nft) => ({
    //   address: nft.objectId,
    //   board: nft.content.fields.active_board,
    //   topTile: nft.content.fields.top_tile,
    //   score: nft.content.fields.score,
    //   imageUri: nft.display.data.image_url,
    //   gameOver: nft.content.fields.game_over,
    // }))
    .map((nft) => ({
      address: nft.address,
      board: nft.fields.active_board,
      topTile: nft.fields.top_tile,
      score: nft.fields.score,
      imageUri: nft.imageUrl,
      gameOver: nft.fields.game_over,
    }))
    .sort((a, b) => {
      const scoreDiff = b.score - a.score;
      if (b.gameOver && a.gameOver) return scoreDiff;
      if (a.gameOver) return 1;
      if (b.gameOver) return -1;
      return scoreDiff;
    });

  if (games.length > 0) {
    addClass(eByClass('no-games'), 'hidden')
    removeClass(eByClass('has-games'), "hidden");
  } else {
    removeClass(eByClass('no-games'), 'hidden')
    addClass(eByClass('has-games'), "hidden");
  }
  
  if (activeGameAddress) {
    const activeGame = games.find((game) => game.address === activeGameAddress);
    if (activeGame) {
      setActiveGame(activeGame);
      return; 
    }
  }

  let highScore = 0;

  for (const game of games) {    
    const gameElement = document.createElement("DIV");
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
      <div class='game-preview-right' id='game-${game.address}'>         
      </div>
    `;

    gamesElement.append(gameElement);
  }

  for (const game of games) {
    if (highScore < parseInt(game.score)) {
      highScore = parseInt(game.score);
    }

    const gameElementArea = document.getElementById(`game-${game.address}`);
    let topGames = leaderboardType === "contest" ? 
      (await contest.getLeaders(network)).leaders :
      await leaderboard.topGames(network, leaderboardAddress);
    if (topGames.length === 0) topGames = [];
    const leaderboardItemIndex = topGames.findIndex(
      (top_game) => top_game.gameId === game.address
    );
    const leaderboardItem = topGames[leaderboardItemIndex];
    const leaderboardItemUpToDate =
      int(leaderboardItem?.score) === int(game.score) || (
        int(game.topTile) <= int(leaderboard.minTile()) && 
        int(game.score) <= int(leaderboard.minScore())
      );
    
    const topTile = parseInt(game.topTile)
    gameElementArea.innerHTML = `
      <div class="${
        leaderboardItem && leaderboardItemUpToDate ? "" : "hidden"
      }">
        <span class="light">Leaderboard:</span> <span class='bold'>${
          leaderboardItemIndex + 1
        }</span>
      </div>
      <button class='hide-contest potential-leaderboard-game ${
        leaderboardItemUpToDate ? "hidden" : ""
      }' data-address='${game.address}'>
        ${leaderboardItem ? "Update" : "Add To"} Leaderboard
      </button>
    `;
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
    return;
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
  removeClass(eByClass("contest-button"), "selected");
  removeClass(eById("game"), "hidden");
  addClass(eByClass("play-button"), "selected");

  setOnClick(eById("submit-game-to-leaderboard"), () => {
    const gameAddress = activeGameAddress;
    showLeaderboard();
    leaderboard.submit(network, chain, contractAddress, gameAddress, walletSigner, () => {
      loadGames();
    });
  });
}

function showLeaderboard() {
  clearTimeout(countdownTimeout);
  setActiveGame(null);
  leaderboard.load(network, leaderboardAddress, true);
  loadGames();
  removeClass(eByClass("contest-game"), "hidden")
  addClass(eByClass("contest-pending"), "hidden")
  addClass(eById("countdown"), "hidden");
  removeClass(eById("leaderboard-panel"), "hidden");
  addClass(eById("game"), "hidden");
  removeClass(eByClass("play-button"), "selected");
  removeClass(eByClass("contest-button"), "selected");
  removeClass(eById("leaderboard"), "hidden");
  addClass(eByClass("leaderboard-button"), "selected");
  removeClass(eById("leaderboard"), 'contest')
  leaderboardType = "normal"
}

function trackCountdown() {
  clearTimeout(countdownTimeout);
  const countdown = contest.timeUntilStart();
  if (contest.ended()) {
    removeClass(eByClass("after-contest"), "hidden");
    addClass(eByClass("during-contest"), "hidden");
    addClass(eByClass("contest-pending"), "hidden")
    addClass(eById("countdown"), "hidden");
    removeClass(eById("leaderboard-panel"), "hidden");
    removeClass(eByClass("contest-game"), "hidden")
  } else if (countdown.days <= 0 && countdown.hours <= 0 && countdown.minutes <= 0 && countdown.seconds <= 0) {
    removeClass(eByClass("during-contest"), "hidden");
    addClass(eByClass("after-contest"), "hidden");
    addClass(eByClass("contest-pending"), "hidden")
    addClass(eById("countdown"), "hidden");
    removeClass(eById("leaderboard-panel"), "hidden");
    removeClass(eByClass("contest-game"), "hidden")
  } else {
    removeClass(eByClass("contest-pending"), "hidden")
    addClass(eByClass("during-contest"), "hidden");
    addClass(eByClass("after-contest"), "hidden");
    addClass(eByClass("contest-game"), "hidden")
    removeClass(eById("countdown"), "hidden");
    addClass(eById("leaderboard-panel"), "hidden");
    eById("countdown-time-days").innerHTML = `${countdown.days < 10 ? 0 : ''}${countdown.days}`;
    eById("countdown-time-hours").innerHTML = `${countdown.hours < 10 ? 0 : ''}${countdown.hours}`;
    eById("countdown-time-minutes").innerHTML = `${countdown.minutes < 10 ? 0 : ''}${countdown.minutes}`;
    eById("countdown-time-seconds").innerHTML = `${countdown.seconds < 10 ? 0 : ''}${countdown.seconds}`;    
  }

  countdownTimeout = setTimeout(trackCountdown, 1000);
}

function showContest() {
  setActiveGame(null);
  leaderboard.load(network, leaderboardAddress, true, true);
  loadGames();
  addClass(eById("game"), "hidden");
  removeClass(eByClass("play-button"), "selected");
  removeClass(eByClass("leaderboard-button"), "selected");
  removeClass(eById("leaderboard"), "hidden");
  addClass(eByClass("contest-button"), "selected");
  addClass(eById("leaderboard"), 'contest')
  leaderboardType = "contest"
  window.scrollTo(0, 0);
}

const initializeClicks = () => {
  setOnClick(eByClass("close-error"), () => {
    addClass(eByClass("error"), "hidden");
  });
  setOnClick(eByClass("sign-in"), ethos.showSignInModal);
  setOnClick(eByClass("leaderboard-button"), showLeaderboard);
  setOnClick(eByClass("contest-button"), showContest);
  setOnClick(eByClass("contest-leaderboard-button"), showContest);
  setOnClick(eById("contest-learn-more"), showContest);
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
  setOnClick(eByClass("close"), () => modal.close(true));

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
    const gameAddress = activeGameAddress;
    modal.close();
    showLeaderboard();
    leaderboard.submit(network, chain, contractAddress, gameAddress, walletSigner, () => {
      loadGames();
    });
  });

  setOnClick(eById("modal-view-leaderboard"), () => {
    modal.close();
    showLeaderboard();
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
    initializeEmailVerification(signer);
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

          const fee = new BigNumber(200000000);
          const payment = transactionBlock.splitCoins(
            transactionBlock.gas,
            [transactionBlock.pure(fee)]
          );
          const coinVec = transactionBlock.makeMoveVec({ objects: [payment] });
          transactionBlock.moveCall({
            target: `${contractAddress}::game_8192::create`,
            typeArguments: [],
            arguments: [transactionBlock.object(maintainerAddress), coinVec]
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
            const gameData = events.find((e) => e.type === `${originalContractAddress}::game_8192::NewGameEvent8192`)
            if (!gameData) {
              eById("create-error-error-message").innerHTML = `Unable to find create event in ${JSON.stringify(data, null, 2)}`;
              modal.open("create-error", "container");
              return;
            }
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
    addClass(eByClass('get-started-message'), 'hidden')
    modal.open("loading", "container");

    setOnClick(eByClass("new-game"), async () => {
      modal.open("mint", "container");
    });

    await loadGames();

    // if (!contentsInterval) {
    //   contentsInterval = setInterval(loadWalletContents, 30000);
    // }

    if (games.length === 0) {
      modal.close();
      showLeaderboard();
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

const initializeEmailVerification = async (signer) => {
  const supabase = createClient(`https://${supabaseProject}.supabase.co`, supabaseAnonKey)
  const user = await supabase.auth.getUser()
  
  removeClass(eById('verify-section'), 'hidden')  

  if (user?.data?.user) {
    const { email } = user.data.user;

    const verified = () => {
      removeClass(eById('verified-message'), 'hidden') 
      addClass(eById('verify-address-message'), 'hidden')
      setOnClick(eById('view-verification'), () => {
        if (eById('verification-review').classList.contains('hidden')) {
          eById('verification-review-address').innerHTML = signer.currentAccount.address;
          eById('verification-review-email').innerHTML = email;
          removeClass(eById('verification-review'), 'hidden')
        } else {
          addClass(eById('verification-review'), 'hidden')
        }
      })
    }
    const { data, error }= await supabase.from('contest').select('*').eq('email', email).maybeSingle();
    if (!error && !!data) {
      verified()
    } else {
      eById('verify-address-email').innerHTML = email;
      removeClass(eById('verify-address-message'), 'hidden') 
      setOnClick(eById('verify-address'), async () => {
        const address = signer.currentAccount.address;
        const signature = await ethos.signMessage({
          signer, 
          message: `I verify that this address is associated with the email ${email}`
        });
        await supabase.from('contest').insert(
          { email, address, signature }
        )
        verified()
      });
    }
  } else {  
    removeClass(eById('verify-email-message'), 'hidden')
    setOnClick(eById('verify-email'), () => {
      removeClass(eById('verify-email-form'), 'hidden')
      setOnClick(eById('verify-email-button'), async () => {
        const email = eById('verify-email-input').value;
        const { data, error } = await supabase.auth.signInWithOtp({
          email,
          options: {
            // emailRedirectTo: "http://localhost:3000",
            emailRedirectTo: 'https://sui8192.ethoswallet.xyz',
          }
        });
        removeClass(eById('verify-email-response'), 'hidden')
        if (error) {
          eById('verify-email-response').innerHTML = error.message
        } else {
          eById('verify-email-response').innerHTML = "Email verification sent!"
        }
      });
    });  
  }
}

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
