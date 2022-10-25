const React = require('react');
const ReactDOM = require('react-dom/client');
const { JsonRpcProvider } = require("@mysten/sui.js");
const { EthosWrapper, SignInButton, ethos } = require('ethos-wallet-beta');

const leaderboard = require('./leaderboard');
const { contractAddress } = require('./constants');
const { 
  eById, 
  eByClass, 
  addClass, 
  removeClass,
  truncateMiddle,
  setOnClick
} = require('./utils');
const modal = require('./modal');
const queue = require('./queue');
const board = require('./board');
const moves = require('./moves');
const confetti = require('./confetti');

const DASHBOARD_LINK = 'https://ethoswallet.xyz/dashboard';

let walletSigner;
let games;
let activeGameAddress;
let walletContents = {};
let topTile = 2;
let contentsInterval;
let faucetUsed = false;

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
      direction, 
      activeGameAddress, 
      walletSigner,
      (newBoard, direction) => {
        handleResult(newBoard, direction);
        loadWalletContents();
      },
      (error) => {
        if (error) {
          showUnknownError(error)
        } else {
          showGasError();
        }
      }
    );
  } 
};

function init() {
  // test();

  leaderboard.load();
  
  const ethosConfiguration = {
    appId: 'sui-8192',
  };

  const start = eById('ethos-start');
  const button = React.createElement(
    SignInButton,
    {
      key: 'sign-in-button',
      className: 'start-button',
      children: "Sign In"
    }
  )

  const wrapper = React.createElement(
    EthosWrapper,
    {
      ethosConfiguration,
      onWalletConnected,
      children: [button]
    }
  )

  const root = ReactDOM.createRoot(start);
  root.render(wrapper);
  
  initializeClicks();
}

function handleResult(newBoard, direction) { 
  if (newBoard.topTile > topTile) {
    topTile = newBoard.topTile;
    const topTiles = eByClass('top-tile-display');
    for (const topTile of topTiles) {
      topTile.innerHTML = `<img src='${newBoard.url}' />`;
    }
    confetti.run();

    setTimeout(() => {
      if (topTile >= leaderboard.minTile() && newBoard.score > leaderboard.minScore()) {
        modal.open('high-score', 'container')
      } else {
        modal.open('top-tile', 'container')
      }
    }, 1000)
  }
  
  const tiles = eByClass('tile');
  const resultDiff = board.diff(board.active().spaces, newBoard.spaces, direction);
 
  const scoreDiff = parseInt(newBoard.score) - parseInt(board.active().score)
  if (scoreDiff > 0) {
    const scoreDiffElement = eById('score-diff');
    scoreDiffElement.innerHTML = `+${scoreDiff}`;
    addClass(scoreDiffElement, 'floating');
    setTimeout(() => {
      removeClass(scoreDiffElement, 'floating');
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
        }, 500)
      }, 80);
    }
  }

  setTimeout(() => {
    board.display(newBoard)
  }, 150)
}

function showGasError() {
  queue.removeAll()
  removeClass(eById("error-gas"), 'hidden');
}

function showUnknownError(error) {
  queue.removeAll()
  eById('error-unknown-message').innerHTML = error;
  removeClass(eById("error-unknown"), 'hidden');
}

async function syncAccountState() {
  if (!walletSigner) return;
  try {
    const address =  await walletSigner.getAddress();
    const provider = new JsonRpcProvider('https://fullnode.devnet.sui.io/', true, '0.11.0');
    await provider.syncAccountState(address);
  } catch (e) {}
}

async function tryDrip(address, suiBalance) {
  if (!walletSigner || faucetUsed) return;

  faucetUsed = true;

  let success;
  try {
    success = await ethos.dripSui({ address });
  } catch (e) {
    console.log("Error with drip", e);
    faucetUsed = false;
    return;
  }

  try {
    await syncAccountState();
  } catch (e) {
    console.log("Error with syncing account state", e);
  }

  if (!success) {
    const { suiBalance: balanceCheck } = await ethos.getWalletContents(address, 'sui')
    if (suiBalance !== balanceCheck) {
      success = true;      
    }
  }

  if (success) {
    removeClass(eById('faucet'), 'hidden');
    faucetUsed = true;
    loadWalletContents();
  }
}

async function loadWalletContents() {
  if (!walletSigner) return;
  const address = await walletSigner.getAddress();
  eById('wallet-address').innerHTML = truncateMiddle(address, 4);

  walletContents = await ethos.getWalletContents(address, 'sui');
  const suiBalance = walletContents.suiBalance;

  if (suiBalance < 5000000) {
    tryDrip(address, suiBalance);
  }

  const balanceSting = (suiBalance || "").toString();
  eById('balance').innerHTML = balanceSting.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' SUI';
}

async function loadGames() {
  if (!walletSigner || !leaderboard) {
    setTimeout(loadGames, 500);
    return;
  }
  removeClass(eById('loading-games'), 'hidden');

  const gamesElement = eById('games-list');
  gamesElement.innerHTML = "";
  
  await loadWalletContents();

  addClass(eById('loading-games'), 'hidden');
 
  games = walletContents.nfts.filter(
    (nft) => nft.package === contractAddress
  ).map(
    (nft) => ({
      address: nft.address,
      boards: nft.extraFields.boards,
      topTile: nft.extraFields.top_tile,
      score: nft.extraFields.score,
      imageUri: nft.imageUri
    })
  ).sort((a, b) => b.score - a.score);
 
  if (!games || games.length === 0) {
    const newGameArea = document.createElement('DIV');
    newGameArea.classList.add('text-center');
    newGameArea.classList.add('padded');
    newGameArea.innerHTML = `
      <p>
        You don't have any games yet.
      </p>
    `;
    gamesElement.append(newGameArea);
  }

  for (const game of games) {
    const gameElement = document.createElement('DIV');
    let topGames = leaderboard.topGames();
    if (topGames.length === 0) topGames = [];
    const leaderboardItemIndex = topGames.findIndex(
      (top_game) => top_game.fields.game_id === game.address
    );
    const leaderboardItem = topGames[leaderboardItemIndex];
    const leaderboardItemUpToDate = leaderboardItem?.fields.score === game.score
    addClass(gameElement, 'game-preview');
    setOnClick(
      gameElement,
      () => {
        addClass(eById('leaderboard'), 'hidden');
        removeClass(eById('game'), 'hidden');
        setActiveGame(game);
      }
    );

    gameElement.innerHTML = `
      <div class='leader-stats flex-1'> 
        <div class='leader-tile subsubtitle color${game.topTile + 1}'>
          ${Math.pow(2, game.topTile + 1)}
        </div>
        <div class='leader-score'>
          Score <span>${game.score}</span>
        </div>
      </div>
      <div class='game-preview-right'> 
        <div class="${leaderboardItem && leaderboardItemUpToDate ? '' : 'hidden'}">
          <span class="light">Leaderboard:</span> <span class='bold'>${leaderboardItemIndex + 1}</span>
        </div>
        <button class='potential-leaderboard-game ${leaderboardItemUpToDate ? 'hidden' : ''}' data-address='${game.address}'>
          ${leaderboardItem ? 'Update' : 'Add To'} Leaderboard
        </button>
      </div>
    `

    gamesElement.append(gameElement);
  }

  setOnClick(
    eByClass('potential-leaderboard-game'),
    (e) => {
      const { dataset: { address } } = e.target;
      e.stopPropagation();
      leaderboard.submit(
        address, 
        walletSigner, 
        () => {
          loadGames();
        }
      )
    }
  )
}

async function setActiveGame(game) {
  initializeKeyListener();
  activeGameAddress = game.address;

  eById('transactions-list').innerHTML = "";
  moves.reset();
  moves.checkPreapprovals(activeGameAddress, walletSigner);
  
  moves.load(
    walletSigner,
    activeGameAddress,
    (newBoard, direction) => {
      handleResult(newBoard, direction);
      loadWalletContents();
    },
    (error) => {
      if (error) {
        showUnknownError(error)
      } else {
        showGasError();
      }
    }
  );

  const boards = game.boards;
  const activeBoard = board.convertInfo(boards[boards.length - 1]);
  topTile = activeBoard.topTile || 2;
  board.display(activeBoard);

  modal.close();
  addClass(eById("leaderboard"), 'hidden');
  removeClass(eByClass('leaderboard-button'), 'selected')
  removeClass(eById("game"), 'hidden');
  addClass(eByClass('play-button'), 'selected')

  setOnClick(
    eById('submit-game-to-leaderboard'), 
    () => {
      showLeaderboard();
      leaderboard.submit(
        activeGameAddress, 
        walletSigner, 
        () => {
          loadGames();
        }
      )
    }
  );
}

function showLeaderboard() {
  leaderboard.load();
  loadGames();
  addClass(eById('game'), 'hidden');
  removeClass(eByClass('play-button'), 'selected');
  removeClass(eById('leaderboard'), 'hidden');
  addClass(eByClass('leaderboard-button'), 'selected');
}

const initializeClicks = () => {
  setOnClick(eByClass('close-error'), () => {
    addClass(eByClass('error'), 'hidden');
  })
  setOnClick(eById('sign-in'), ethos.showSignInModal);
  setOnClick(eByClass('leaderboard-button'), showLeaderboard)
  setOnClick(eByClass('title'), ethos.showWallet)
  
  setOnClick(
    eById('balance'), 
    () => window.open(DASHBOARD_LINK)
  )
  setOnClick(
    eById('wallet-address'), 
    () => window.open(DASHBOARD_LINK)
  )

  setOnClick(
    eById('logout'),
    async (e) => {
      e.stopPropagation();
      await ethos.logout(walletSigner);
      walletSigner = null;
      games = null;
      activeGameAddress = null;
      walletContents = {};

      addClass(document.body, 'signed-out');
      removeClass(document.body, 'signed-in');
      addClass(eById('leaderboard'), 'hidden');
      removeClass(eById('game'), 'hidden');
      addClass(eById('loading-games'), 'hidden');

      board.clear();
      
      modal.open('get-started', 'board', true);
    }
  );

  setOnClick(eById('close-modal'), () => modal.close(true));

  setOnClick(
    eByClass('play-button'), 
    () => {
      if (games && games.length > 0) {
        addClass(eById('leaderboard'), 'hidden');
        removeClass(eById('game'), 'hidden');
        setActiveGame(games[0]);
      } else if (walletSigner) {
        eByClass('new-game')[0].onclick();
      } else {
        ethos.showSignInModal();
      }
    }
  );

  setOnClick(
    eById('modal-submit-to-leaderboard'),
    () => {
      modal.close();
      showLeaderboard();
      leaderboard.submit(
        activeGameAddress, 
        walletSigner, 
        () => {
          loadGames();
        }
      )
    }
  );

  setOnClick(eByClass('keep-playing'), modal.close);

  setOnClick(eById('close-faucet'), () => {
    addClass(eById('faucet'), 'hidden')
  })

  setOnClick(eById('close-preapproval'), () => {
    addClass(eById('preapproval'), 'hidden')
  })
}

const onWalletConnected = async ({ signer }) => {
  walletSigner = signer;
  if (signer) {
    syncAccountState();

    modal.close();
  
    addClass(document.body, 'signed-in');

    // const response = await ethos.sign({ signer: walletSigner, signData: "YO" });
    // console.log("SIGN", response);
    
    const prepMint = async () => {
      const mint = eById('mint-game');
      const mintButtonTitle = "Mint New Game";
      if (mint.innerHTML.indexOf(mintButtonTitle) === -1) {
        const mintButton = document.createElement("BUTTON");
        setOnClick(
          mintButton,
          async () => {
            modal.open('loading', 'container');

            const signableTransaction = {
              kind: "moveCall",
              data: {
                packageObjectId: contractAddress,
                module: 'game_8192',
                function: 'create',
                typeArguments: [],
                arguments: [],
                gasBudget: 5000
              }
            };

            try {
              const data = await ethos.transact({
                signer: walletSigner, 
                signableTransaction
              })

              if (!data) {
                modal.open('create-error', 'container');
                return;
              }

              const { effects } = data.EffectsCert?.effects || data;
              const gameData = effects.events.find(
                e => e.moveEvent
              ).moveEvent.fields;
              const { board_spaces, score } = gameData;
              const game = {
                address: effects.created[0].reference.objectId,
                boards: [
                  {
                    score,
                    board_spaces,
                    game_over: false
                  }
                ]
              }
              setActiveGame(game);
              ethos.hideWallet();
            } catch (e) {
              console.log("Error minting game", e)
              modal.open('create-error', 'container');
              return;
            }
          }
        );
        mintButton.innerHTML = mintButtonTitle;
        mint.appendChild(mintButton);
      }
    }

    prepMint();
    modal.open('loading', 'container');

    setOnClick(
      eByClass('new-game'),
      async () => {
        modal.open('mint', 'container');
      }
    );
    
    await loadGames();

    if (!contentsInterval) {
      contentsInterval = setInterval(loadWalletContents, 3000)
    }

    if (games.length === 0) {
      modal.open('mint', 'board', true);  
    } else {
      modal.close();

      if (games.length === 1) {
        setActiveGame(games[0]);
      } else {
        showLeaderboard();
      }
    }
    
    removeClass(document.body, 'signed-out');

    const address = await signer.getAddress();

    setOnClick(
      eById('copy-address'),
      () => {
        const innerHTML = eById('copy-address').innerHTML;
        eById('copy-address').innerHTML = "Copied!"
        navigator.clipboard.writeText(address)
        setTimeout(() => {
          eById('copy-address').innerHTML = innerHTML;
        }, 1000);
      }
    );
  } else {
    modal.open('get-started', 'board', true);
    setOnClick(eByClass('new-game'), ethos.showSignInModal)
    addClass(document.body, 'signed-out');
    removeClass(document.body, 'signed-in');
    addClass(eById('loading-games'), 'hidden');
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