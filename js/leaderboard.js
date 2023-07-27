const { Connection, JsonRpcProvider } = require("@mysten/sui.js");
const { ethos, TransactionBlock } = require("ethos-connect");
const {
   tileNames,
} = require("./constants");
const {
    eById,
    eByClass,
    addClass,
    removeClass,
    truncateMiddle,
    setOnClick,
} = require("./utils");
const {
  ROWS,
  COLUMNS,
  spaceAt
} = require('./board');
const contest = require('./contest');
const { add } = require("./queue");

let cachedLeaderboardAddress;
let leaderboardObject;
let _topGames;
let leaderboardTimestamp;
let loadingNextPage = 0;
let page = 1;
let perPage = 25;

const topGames = async (network, force) => {
  if (_topGames && !force) return _topGames;

  if (!leaderboardObject) {
    await get(network);
  }

  const gameIds = leaderboardObject.top_games.map((topGame) => topGame.fields.game_id)
  _topGames = (await getObjects(network, gameIds)).map(
    (gameObject, index) => {
      if (!gameObject.data) {
        return {
          gameId: leaderboardObject.top_games[index].fields.game_id,
          topTile: parseInt(leaderboardObject.top_games[index].fields.top_tile),
          score: parseInt(leaderboardObject.top_games[index].fields.score),
          leaderAddress: leaderboardObject.top_games[index].fields.leader_address
        }
      } else {
        const packedSpaces = gameObject.data.content.fields.active_board.fields.packed_spaces;
        let topTile = 0;
        for (let i=0; i<ROWS; ++i) {
          for (let j=0; j<COLUMNS; ++j) {
            const tile = spaceAt(packedSpaces, i, j);
            if (topTile < tile) {
              topTile = tile;
            }
          }
        }

        return {
          gameId: gameObject.data.objectId,
          topTile,
          score: parseInt(gameObject.data.content.fields.score),
          leaderAddress: gameObject.data.content.fields.player
        }
      }
    }
  ).sort(
    (a, b) => {
      if (a.top_tile === b.top_tile) {
        return parseInt(b.score) - parseInt(a.score)
      } else {
        return parseInt(b.top_tile) - parseInt(a.top_tile)
      }
    }
  )
  
  return _topGames;
}

const getObjects = async (network, ids) => {
    const connection = new Connection({ fullnode: network })
    const provider = new JsonRpcProvider(connection);
    if (!Array.isArray(ids)) ids = [ids ?? cachedLeaderboardAddress];
    const objects = await provider.multiGetObjects({ 
      ids, 
      options: { showContent: true } 
    });
    return objects;
};

const get = async (network) => {
    const objects = await getObjects(network);
    const {
        data: {
            content: { fields: leaderboard },
        },
    } = objects[0];
    leaderboardObject = leaderboard;
    return leaderboard;
};

const getLeaderboardGame = async (network, gameObjectId) => {
    const gameObjects = await getObjects(network, gameObjectId);
    let {
        data: {
            content: {
                fields: { active_board: activeBoard, move_count: moveCount, game_over: gameOver },
            },
        },
    } = gameObjects[0];

    // const connection = new Connection({ fullnode: network })
    // const provider = new JsonRpcProvider(connection);

    // const query = new TransactionBlock();
    // query.moveCall({
    //     target: `${contractAddress}::game_8192::all_moves`,
    //     arguments: [
    //       query.object(gameObjectId)
    //     ]
    // })
    // const history = await provider.devInspectTransactionBlock({
    //   transactionBlock: query,
    //   sender: "0x000000000000000000000000000000000000000000000000000000000000000"
    // });

    // const results = history.results[0]
    // if (results) {
    //     const enums = {}
    //     enums['Option<u64>'] = {
    //       none: null,
    //       some: 'u64'
    //     };
      
    //     const bcsConfig = {
    //       vectorType: 'vector',
    //       addressLength: 32,
    //       addressEncoding: 'hex',
    //       types: { enums },
    //       withPrimitives: true
    //     };
        
    //     const bcs = new BCS(bcsConfig);
    //     // const bcs = new BCS(getSuiMoveConfig());

    //     bcs.registerAddressType('SuiAddress', 32, 'hex');
        
    //     bcs.registerStructType('GameHistory8192', {
    //         move_count: 'u64',
    //         direction: 'u64',
    //         board_spaces: 'vector<vector<Option<u64>>>',
    //         top_tile: 'u64',
    //         url: 'string',
    //         score: 'u64',
    //         game_over: 'bool',
    //         last_tile: 'vector<u64>',
    //         epoch: 'u64',
    //         player: 'SuiAddress'
    //     });

    //     const dataNumberArray = results.returnValues?.[0]?.[0];
    //     if (!dataNumberArray) return;

    //     const data = Uint8Array.from(dataNumberArray);
    //     const histories = bcs.de('vector<GameHistory8192>', data);

    //     console.log("HISTORIES", histories)
    //     gameOver = histories[histories.length - 1].game_over;
    //     return { id: gameObjectId, gameOver, moveCount, histories };
    // }

    return { id: gameObjectId, activeBoard, gameOver, moveCount };
};

const historyHTML = (moveIndex, totalMoves, histories) => {
    const history = histories[moveIndex];
    
    const rows = [];
    for (let row = 0; row < ROWS; row++) {
        const rowHTML = [];
        rowHTML.push("<div class='leaderboard-board-row'>");
        for (let columnIndex = 0; columnIndex < COLUMNS; columnIndex++) {
            const column = spaceAt(history.packed_spaces, row, columnIndex)
            rowHTML.push(`
            <div class='leaderboard-board-tile color${column === null ? "-none" : column} '>
              <div>
                ${column === null ? "&nbsp;" : Math.pow(2, column)}
              </div>
              <div class='leaderboard-board-tile-name'>
                ${column === null ? "&nbsp;" : tileNames[column]}
              </div>
            </div>
          `);
        }
        rowHTML.push("</div>");
        rows.push(rowHTML.join(""));
    }

    const completeHTML = `
      <div class='leaderboard-board'>
        ${rows.join("")}
      </div>
      <div class='leaderboard-board-stats'>
        <div>
          <div>Moves</div>
          <div class='game-highlighted'>
            ${totalMoves}
          </div>
        </div>
        <div>
          <div>Score</div>
          <div class='game-highlighted'> 
            ${history.score}
          </div>
        </div>
      </div>
    `;
    return completeHTML;
};

const load = async (network, leaderboardAddress, force = false, contestDay = 1) => {
    cachedLeaderboardAddress = leaderboardAddress
    const loadingLeaderboard = eById("loading-leaderboard");
    if (!loadingLeaderboard) return;

    if (!force && leaderboardTimestamp && Date.now() - leaderboardTimestamp < 1000 * 60) {
        return;
    }

    leaderboardTimestamp = Date.now();

    removeClass(loadingLeaderboard, "hidden");
    addClass(eById("more-leaderboard"), "hidden");

    page = 1;
    addClass(eById("loading-leaderboard"), "hidden");

    const leaderboardList = eById("leaderboard-list");
    leaderboardList.innerHTML = "";

    let games, timestamp;
    if (contestDay) {
      const leaderboard = await contest.getLeaders(contestDay, network);
      games = leaderboard.leaders;
      timestamp = leaderboard.timestamp;
    } else {
      leaderboardObject = await get(network);
      games = await topGames(network, true);
    }

    const best = eById("best");
    if (best) {
      best.innerHTML = games[0]?.score || 0;
    }
    setOnClick(eById("more-leaderboard"), () => loadNextPage(network, !!contestDay, timestamp));

    await loadNextPage(network, contestDay, !!contestDay, timestamp);
};

const loadNextPage = async (network, contestDay, contestLeaderboard, timestamp) => {
    if (loadingNextPage) return;

    loadingNextPage = true;

    const leaderboardList = eById("leaderboard-list");
    const currentMax = page * perPage;

    let games;
    if (contestLeaderboard) {
      const leaderboard = await contest.getLeaders(contestDay, network, timestamp);
      games = leaderboard.leaders;
      if (games.length === 0) {
        removeClass(eById("no-contest-games"), 'hidden')
      } else {
        addClass(eById("no-contest-games"), 'hidden')
      }
    } else {
      games = await topGames(network, true);
    }

    const pageMax = Math.min(games.length, currentMax);
    for (let i = (page - 1) * perPage; i < pageMax; ++i) {
        const { gameId, topTile, score, leaderAddress } = games[i];  
    
        const name = leaderAddress
        // const name = await ethos.getSuiName(leaderAddress);

        const leaderElement = document.createElement("DIV");
        addClass(leaderElement, "leader");

        const listing = document.createElement("DIV");
        addClass(listing, "leader-listing");
        listing.innerHTML = `
      <div class='leader-stats flex-1'> 
        <div>${i + 1}</div>
        <div class='leader-tile subsubtitle color${topTile}'>
          ${Math.pow(2, topTile)}
        </div>
        <div class='leader-score'>
          Score <span>${score}</span>
        </div>
      </div>
      
      <div class='leaderboard-name flex-1 '>
        <div title='${leaderAddress}'>
          ${name === leaderAddress ? truncateMiddle(leaderAddress, 4) : name}
        </div>
        <div class='chevron'>⌄</div>
      </div>     
    `;

        leaderElement.append(listing);

        leaderElement.onclick = async () => {
            removeClass(eByClass("leader"), "selected");
            addClass(leaderElement, "selected");

            const details = document.createElement("DIV");

            leaderElement.onclick = () => {
                if (leaderElement.classList.contains("selected")) {
                    removeClass(leaderElement, "selected");
                } else {
                    removeClass(eByClass("leader"), "selected");
                    addClass(leaderElement, "selected");
                }
            };

            addClass(details, "leader-details");
            details.innerHTML = "<div class='text-center'>Loading game...</div>";
            leaderElement.append(details);

            const game = await getLeaderboardGame(network, gameId);

        //     let currentIndex = game.histories.length - 1;
        //     details.onmousewheel = (e) => {
        //         currentIndex += Math.round(e.deltaY / 2);
        //         if (currentIndex > game.histories.length - 1) {
        //             currentIndex = game.histories.length - 1;
        //         } else if (currentIndex < 0) {
        //             currentIndex = 0;
        //         }
        //         indexDetails(currentIndex);
        //         return false;
        //     };

        //     details.onmouseenter = () => {
        //         window.onkeydown = (e) => {
        //             e.preventDefault();
        //             switch (e.keyCode) {
        //                 case 38:
        //                     currentIndex += 1;
        //                     break;
        //                 case 40:
        //                     currentIndex -= 1;
        //                     break;
        //             }
        //             indexDetails(currentIndex);
        //         };
        //     };

        //     details.addEventListener('touchstart', handleTouchStart, false);        
        //     details.addEventListener('touchmove', handleTouchMove, false);

        //     let xDown = null;                                                        
        //     let yDown = null;

        //     function getTouches(evt) {
        //       return evt.touches ||
        //             evt.originalEvent.touches; 
        //     }                                                     
                                                                                    
        //     function handleTouchStart(evt) {
        //         evt.stopPropagation();
        //         evt.preventDefault();
        //         const firstTouch = getTouches(evt)[0];                                      
        //         xDown = firstTouch.clientX;                                      
        //         yDown = firstTouch.clientY;                                      
        //     };                                                
                                                                                    
        //     function handleTouchMove(evt) {
        //         if ( ! xDown || ! yDown ) {
        //             return;
        //         }

        //         evt.stopPropagation();
        //         evt.preventDefault();

        //         var xUp = evt.touches[0].clientX;                                    
        //         var yUp = evt.touches[0].clientY;

        //         var xDiff = xDown - xUp;
        //         var yDiff = yDown - yUp;
                                                                                    
        //         if ( Math.abs( xDiff ) > Math.abs( yDiff ) ) {
        //             if ( xDiff > 0 ) {
        //                 /* right swipe */ 
        //             } else {
        //                 /* left swipe */
        //             }                       
        //         } else {
        //             currentIndex += Math.round(yDiff / -1);
        //             if (currentIndex > game.histories.length - 1) {
        //                 currentIndex = game.histories.length - 1;
        //             } else if (currentIndex < 0) {
        //                 currentIndex = 0;
        //             }
        //             indexDetails(currentIndex);
        //             return false;                                                                 
        //         }
        //         xDown = null;
        //         yDown = null;                                             
        //     };

            const indexDetails = (index) => {
                details.innerHTML = `
          <div class='game-status'>
            <div>
              <div>Game Status</div>
              <div class='game-status-${game.gameOver ? "ended" : "active"}'>
                ${game.gameOver ? "Ended" : "Active"}
              </div>
            </div>
          </div>
          <div class='leader-boards'>
            <div class='leader-board'>
              ${historyHTML(0, game.moveCount, [game.activeBoard.fields])}
            </div>
          </div>
          <div class='desktop game-info'>
            <div>
              <div class='game-info-header'>Game ID</div>
              <div class='game-highlighted'>
                ${game.id.slice(0,33)}
                <br />
                ${game.id.slice(-33)}
              </div>
            </div>
            <div>
              <div class='game-info-header'>Player</div>
              <div class='game-highlighted'>
                ${leaderAddress.slice(0,33)}
                <br />
                ${leaderAddress.slice(-33)}
              </div>
            </div>
          </div>
        `;
            };

            indexDetails(0);
        };

        leaderboardList.append(leaderElement);
    }

    if (currentMax >= games.length - 1) {
        addClass(eById("more-leaderboard"), "hidden");
    } else {
        page += 1;
        removeClass(eById("more-leaderboard"), "hidden");
    }

    loadingNextPage = false;
};

const minScore = () => {
    return leaderboardObject.min_score;
};

const minTile = () => {
    return leaderboardObject.min_tile;
};

const submit = async (network, chain, contractAddress, gameAddress, walletSigner, onComplete) => {
    const transactionBlock = new TransactionBlock();
    transactionBlock.moveCall({
      target: `${contractAddress}::leaderboard_8192::submit_game`,
      arguments: [
        transactionBlock.object(gameAddress),
        transactionBlock.object(cachedLeaderboardAddress)
      ]
    })

    const { signature, transactionBlockBytes } = await ethos.signTransactionBlock({
        signer: walletSigner,
        transactionInput: {
          transactionBlock,
          chain,
        },
    });

    await ethos.executeTransactionBlock({
      signer: walletSigner, 
      transactionInput: {
        transactionBlock: transactionBlockBytes,
        signature,
        options: {
          showEvents: true,
          showEffects: true,
          showBalanceChanges: true,
          showObjectChanges: true
        },
        requestType: 'WaitForLocalExecution'
      }
    })

    await load(network, cachedLeaderboardAddress, true);
    ethos.hideWallet(walletSigner);
    onComplete();
};

const reset = async (network, chain, contractAddress, walletSigner, onComplete) => {
  const transactionBlock = new TransactionBlock();
  transactionBlock.moveCall({
    target: `${contractAddress}::leaderboard_8192::reset_leaderboard`,
    arguments: [
      transactionBlock.object(cachedLeaderboardAddress)
    ]
  })

  const { signature, transactionBlockBytes } = await ethos.signTransactionBlock({
      signer: walletSigner,
      transactionInput: {
        transactionBlock,
        chain,
      },
  });

  await ethos.executeTransactionBlock({
    signer: walletSigner, 
    transactionInput: {
      transactionBlock: transactionBlockBytes,
      signature,
      options: {
        showEvents: true,
        showEffects: true,
        showBalanceChanges: true,
        showObjectChanges: true
      },
      requestType: 'WaitForLocalExecution'
    }
  })

  await load(network, cachedLeaderboardAddress, true);
  ethos.hideWallet(walletSigner);
  onComplete();
};

module.exports = {
    topGames,
    minTile,
    minScore,
    get,
    load,
    submit,
    reset
};
