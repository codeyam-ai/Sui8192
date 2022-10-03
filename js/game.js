const React = require('react');
const ReactDOM = require('react-dom/client');
const { EthosWrapper, SignInButton, ethos } = require('ethos-wallet-beta');
const leaderboard = require('./leaderboard');
const { contractAddress } = require('./constants');
const { 
  eById, 
  eByClass, 
  addClass, 
  removeClass,
  truncateMiddle
} = require('./utils');
const modal = require('./modal');
const queue = require('./queue');
const board = require('./board');
const moves = require('./moves');
const confetti = require('./confetti');

let walletSigner;
let games;
let activeGameAddress;
let walletContents = {};
let topTile = 2;
let contentsInterval;

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
    () => {
      showGasError();
    }
  );
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
        modal.open('high-score')
      } else {
        modal.open('top-tile')
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
      }, 180);
    }
  }

  setTimeout(() => {
    board.display(newBoard)
  }, 250)
}

function showGasError() {
  queue.removeAll()
  removeClass(eById("error-gas"), 'hidden');
}

async function loadWalletContents() {
  if (!walletSigner) return;
  const address = await walletSigner.getAddress();
  eById('wallet-address').innerHTML = truncateMiddle(address, 4);
  walletContents = await ethos.getWalletContents(address, 'sui');
  // console.log("WALLET CONTENTS", walletContents)

  // const details = {
  //   network: 'sui',
  //   address: "0xb1cc5c85459ebfaddf49f70816ab65da6a412deb",
  //   moduleName: 'coin_merge',
  //   functionName: 'merge',
  //   inputValues: [walletContents.coins.map(c => c.address)],
  //   gasBudget: 10000
  // };

  // console.log("DETAILS", details)

  // const data = await ethos.transact({
  //   signer: walletSigner, 
  //   details
  // })

  // console.log("RESPONSE", response)

  // const walletContents2 = await ethos.getWalletContents(address, 'sui');
  // console.log("WALLET CONTENTS2", walletContents2)

  const balance = (walletContents.balance || "").toString();
  eById('balance').innerHTML = balance.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' SUI';
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
        To get started, mint a new game!
      </p>
      <p>
        Every game is an NFT that you can treat like any other NFT. 
        Try viewing it in your wallet or sending it to someone else!
      </p>
    `;
    const newGame = eByClass('new-game')[0];
    const newGameClone = newGame.cloneNode(true);
    newGameClone.onclick = newGame.onclick;
    newGameArea.append(newGameClone);
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
    gameElement.onclick = () => {
      addClass(eById('leaderboard'), 'hidden');
      removeClass(eById('game'), 'hidden');
      setActiveGame(game);
    }
    // gameElement.innerHTML = game.topTile;

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

    // <div class='leaderboard-name flex-1 '>
    //     <div title='${leaderAddress}'>
    //       ${truncateMiddle(leaderAddress)}
    //     </div>
    //   </div>
    //   <div class='game-preview-tile color${game.topTile + 1} title'>
    //     <img src='${game.imageUri}' height="30px", width="30px" />
    //   </div>
    //   <div class='text-center' style='padding: 6px 0;'>
    //     Score: ${game.score}
    //   </div>
    //   <div class='text-center'>
    
    //   </div>

    gamesElement.append(gameElement);

    for (const gameElement of eByClass('potential-leaderboard-game')) {
      gameElement.onclick = (e) => {
        e.stopPropagation();
        leaderboard.submit(
          gameElement.dataset.address, 
          walletSigner, 
          () => {
            loadGames();
          }
        )
      }
    }
  }
}

async function setActiveGame(game) {
  activeGameAddress = game.address;

  eById('transactions-list').innerHTML = "";
  moves.reset();
  
  moves.load(
    walletSigner,
    activeGameAddress,
    (newBoard, direction) => {
      handleResult(newBoard, direction);
      loadWalletContents();
    },
    () => {
      showGasError();
    }
  );

  const boards = game.boards;
  const activeBoard = board.convertInfo(boards[boards.length - 1]);
  topTile = activeBoard.topTile || 2;
  board.display(activeBoard);

  modal.close();
  addClass(eById("leaderboard"), 'hidden');
  removeClass(eById('leaderboard-button'), 'selected')
  removeClass(eById("game"), 'hidden');
  addClass(eById('play-button'), 'selected')
}

function init() {
  // test();

  leaderboard.load();
  
  const ethosConfiguration = {
     appId: 'sui-8192'
  };

  const start = eById('ethos-start');
  const mint = eById('mint-game');

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
      onWalletConnected: async ({ signer }) => {
        walletSigner = signer;
        if (signer) {
          addClass(document.body, 'signed-in');

          // const response = await ethos.sign({ signer: walletSigner, signData: "YO" });
          // console.log("SIGN", response);
          
          const prepMint = async () => {
            const mintButtonTitle = "Mint New Game";
            if (mint.innerHTML.indexOf(mintButtonTitle) === -1) {
              const mintButton = document.createElement("BUTTON");
              mintButton.onclick = async () => {
                modal.open('loading');

                const details = {
                  network: 'sui',
                  address: contractAddress,
                  moduleName: 'game_8192',
                  functionName: 'create',
                  inputValues: [],
                  gasBudget: 5000
                };
            
                try {
                  const data = await ethos.transact({
                    signer: walletSigner, 
                    details
                  })

                  if (!data) {
                    modal.open('create-error');
                    return;
                  }

                  const gameData = data.effects.events.find(
                    e => e.moveEvent
                  ).moveEvent.fields;
                  const { board_spaces, score } = gameData;
                  const game = {
                    address: data.effects.created[0].reference.objectId,
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
                  modal.open('create-error');
                  return;
                }
              }
              mintButton.innerHTML = mintButtonTitle;
              mint.appendChild(mintButton);
            }
          }

          prepMint();
          modal.open('loading');

          const newGameButtons = eByClass('new-game');
          for (const newGameButton of newGameButtons) {
            newGameButton.onclick = async () => {
              modal.open('mint');
            }
          }
          
          await loadGames();

          if (!contentsInterval) {
            contentsInterval = setInterval(loadWalletContents, 3000)
          }

          if (games.length === 0) {
            modal.open('mint', true);  
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
          eById('copy-address').onclick = () => {
            const innerHTML = eById('copy-address').innerHTML;
            eById('copy-address').innerHTML = "Copied!"
            navigator.clipboard.writeText(address)
            setTimeout(() => {
              eById('copy-address').innerHTML = innerHTML;
            }, 1000);
          }
        } else {
          modal.open('get-started', true);
          const newGameButtons = eByClass('new-game');
          for (const newGameButton of newGameButtons) {
            newGameButton.onclick = ethos.showSignInModal
          }
          addClass(document.body, 'signed-out');
          removeClass(document.body, 'signed-in');
          addClass(eById('loading-games'), 'hidden');
        }
      },
      children: [button]
    }
  )

  const root = ReactDOM.createRoot(start);
  root.render(wrapper);
  
  // modal.close();

  eById('sign-in').onclick = ethos.showSignInModal;

  const showLeaderboard = () => {
    leaderboard.load();
    loadGames();
    addClass(eById('game'), 'hidden');
    removeClass(eById('play-button'), 'selected');
    removeClass(eById('leaderboard'), 'hidden');
    addClass(eById('leaderboard-button'), 'selected');
  }

  eById('leaderboard-button').onclick = showLeaderboard;

  for (const titleElement of eByClass('title')) {
    titleElement.onclick = () => {
      ethos.showWallet();
    }
  }

  eById('balance').onclick = () => window.open('https://ethoswallet.xyz/dashboard');
  eById('wallet-address').onclick = () => window.open('https://ethoswallet.xyz/dashboard');

  // eById('sui-address').onmouseenter = () => {
  //   removeClass(eById('logout'), 'hidden');
  //   addClass(eById('sui-address'), 'hovering');
  // }
  // eById('sui-address').onmouseleave = () => {
  //   setTimeout(() => {
  //     addClass(eById('logout'), 'hidden');
  //     removeClass(eById('sui-address'), 'hovering')
  //   }, 5000)
  // }

  eById('logout').onclick = async (e) => {
    e.stopPropagation();
    await ethos.logout(walletSigner);
    walletSigner = null;
    games = null;
    activeGameAddress = null;
    walletContents = {};

    addClass(document.body, 'signed-out');
    removeClass(document.body, 'signed-in');
    addClass(eById('loading-games'), 'hidden');

    board.clear();
    
    modal.open('get-started', true);
  }

  eById('close-modal').onclick = () => modal.close(true);

  eById('play-button').onclick = () => {
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

  eById('modal-submit-to-leaderboard').onclick = () => {
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
//     [0,  0,  99, 99],
//     [99, 99, 1,  99],
//     [0,  0,  1,  99],
//     [1,  99, 1,  99]
//   ]
  
//   const boardLeft = [
//     [1,  99, 99, 99],
//     [1,  99, 99, 99],
//     [1,  1,  99, 99],
//     [2,  99, 99, 99]
//   ]
  
//   const boardRight = [
//     [99, 99, 99, 1],
//     [99, 99, 99, 1],
//     [99, 99, 1,  1],
//     [99, 99, 99, 2]
//   ]
  
//   const boardUp = [
//     [1,  1,  2,  99],
//     [1,  99, 1,  99],
//     [99, 99, 99, 99],
//     [99, 99, 99, 99]
//   ]
  
//   const boardDown = [
//     [99, 99, 99, 99],
//     [99, 99, 99, 99],
//     [1,  99, 1,  99],
//     [1,  1,  2,  99]
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
//       [1, 1, 99,99],
//       [99,99,99,99],
//       [1, 99,99,99],
//       [99,99,99,99]
//     ],
//     board2: [
//       [99,99,99,99],
//       [99,99,99,99],
//       [1, 99,99,99],
//       [2, 1, 99,99]
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