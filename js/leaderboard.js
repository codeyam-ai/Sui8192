const { BCS, getSuiMoveConfig } = require('@mysten/bcs');
const { Connection, JsonRpcProvider } = require("@mysten/sui.js");
const { ethos } = require("ethos-connect");
const {
    contractAddress,
    leaderboardAddress,
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

const PAGE_COUNT = 25;

let leaderboardObject;
let _topGames;
let leaderboardTimestamp;
let loadingNextPage = 0;
let page = 1;
let perPage = 25;

const topGames = async (network, force) => {
  const connection = new Connection({ fullnode: network })
  const provider = new JsonRpcProvider(connection);

  if (_topGames && !force) return _topGames;
  const topGamesId = leaderboardObject.top_games.fields.id.id;
  const gameInfos = await provider.getDynamicFields({ parentId: topGamesId })
  const gameDetails = await provider.multiGetObjects({
    ids: gameInfos.data.map((info) => info.objectId),
    options: {
      showContent: true
    }
  })
  _topGames = gameDetails.sort(
    (a,b) => a.details.content.fields.name - b.details.content.fields.name
  ).map(
    (details) => details.details.content.fields.value
  ).filter(
    (game) => !!game
  )
  return _topGames;
}

const getObject = async (network, objectId) => {
    const connection = new Connection({ fullnode: network })
    const provider = new JsonRpcProvider(connection);
    return provider.getObject({ id: objectId, options: { showContent: true } });
};

const get = async (network) => {
    const {
        details: {
            content: { fields: leaderboard },
        },
    } = await getObject(network, leaderboardAddress);
    leaderboardObject = leaderboard;
    return leaderboard;
};

const getLeaderboardGame = async (network, gameObjectId) => {
    const gameObject = await getObject(network, gameObjectId);
    let {
        details: {
            content: {
                fields: { boards: boardsTable, move_count: moveCount, game_over: gameOver },
            },
        },
    } = gameObject;

    const connection = new Connection({ fullnode: network })
    const provider = new JsonRpcProvider(connection);
  
    const history = await provider.devInspectTransaction(
      "0x0000000000000000000000000000000000000002",
      {
        kind: "moveCall",
        data: {
          packageObjectId: contractAddress,
          module: "game_8192",
          function: "all_moves",
          typeArguments: [],
          arguments: [gameObjectId]
        },
      }
    );

  if ('Ok' in history.results) {
      const enums = {}
      enums['Option<u64>'] = {
        none: null,
        some: 'u64'
      };
    
      const bcsConfig = {
        vectorType: 'vector',
        addressLength: 20,
        addressEncoding: 'hex',
        types: { enums },
        withPrimitives: true
      };
      
      const bcs = new BCS(bcsConfig);
      // const bcs = new BCS(getSuiMoveConfig());

      bcs.registerAddressType('SuiAddress', 20, 'hex');
      
      bcs.registerStructType('GameHistory8192', {
          move_count: 'u64',
          direction: 'u64',
          board_spaces: 'vector<vector<Option<u64>>>',
          top_tile: 'u64',
          url: 'string',
          score: 'u64',
          game_over: 'bool',
          last_tile: 'vector<u64>',
          epoch: 'u64',
          player: 'SuiAddress'
      });

      const dataNumberArray =
          history.results.Ok[0][1].returnValues?.[0]?.[0];
      if (!dataNumberArray) return;

      const data = Uint8Array.from(dataNumberArray);
      const histories = bcs.de('vector<GameHistory8192>', data);

      gameOver = histories[histories.length - 1].game_over;
      return { id: gameObjectId, gameOver, moveCount, histories };
  }
};

const historyHTML = (moveIndex, totalMoves, histories) => {
    const history = histories[moveIndex];
    const rows = [];
    for (const row of history.board_spaces) {
        const rowHTML = [];
        rowHTML.push("<div class='leaderboard-board-row'>");
        for (const columnInfo of row) {
            const column = columnInfo.none ? null : parseInt(BigInt(columnInfo.some).toString());
            rowHTML.push(`
            <div class='leaderboard-board-tile color${column === null ? "-none" : column + 1} '>
              <div>
                ${column === null ? "&nbsp;" : Math.pow(2, column + 1)}
              </div>
              <div class='leaderboard-board-tile-name'>
                ${column === null ? "&nbsp;" : tileNames[column + 1]}
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
          <div>Move</div>
          <div class='game-highlighted'>
            ${moveIndex} of ${totalMoves}
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

const load = async (network, force = false) => {
    const loadingLeaderboard = eById("loading-leaderboard");
    if (!loadingLeaderboard) return;

    if (!force && leaderboardTimestamp && Date.now() - leaderboardTimestamp < 1000 * 60) {
        return;
    }

    leaderboardTimestamp = Date.now();

    removeClass(loadingLeaderboard, "hidden");
    addClass(eById("more-leaderboard"), "hidden");

    page = 1;
    leaderboardObject = await get(network);

    addClass(eById("loading-leaderboard"), "hidden");

    const leaderboardList = eById("leaderboard-list");
    leaderboardList.innerHTML = "";

    const games = await topGames(network, true);
    const best = eById("best");
    if (best) {
      best.innerHTML = games[0]?.fields?.score || 0;
    }
    setOnClick(eById("more-leaderboard"), () => loadNextPage(network));

    await loadNextPage(network);
};

const loadNextPage = async (network) => {
    if (loadingNextPage) return;

    loadingNextPage = true;

    const leaderboardList = eById("leaderboard-list");
    const currentMax = page * perPage;
    const games = await topGames(network);
    const pageMax = Math.min(games.length, currentMax);
    for (let i = (page - 1) * perPage; i < pageMax; ++i) {
        const {
            fields: {
                score,
                top_tile: topTileString,
                leader_address: leaderAddress,
                game_id: gameId,
            },
        } = games[i];
    
        const topTile = parseInt(topTileString);
        const name = leaderAddress
        // const name = await ethos.getSuiName(leaderAddress);

        const leaderElement = document.createElement("DIV");
        addClass(leaderElement, "leader");

        const listing = document.createElement("DIV");
        addClass(listing, "leader-listing");
        listing.innerHTML = `
      <div class='leader-stats flex-1'> 
        <div>${i + 1}</div>
        <div class='leader-tile subsubtitle color${topTile + 1}'>
          ${Math.pow(2, topTile + 1)}
        </div>
        <div class='leader-score'>
          Score <span>${score}</span>
        </div>
      </div>
      
      <div class='leaderboard-name flex-1 '>
        <div title='${leaderAddress}'>
          ${name === leaderAddress ? truncateMiddle(leaderAddress) : name}
        </div>
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

            let currentIndex = game.histories.length - 1;
            details.onmousewheel = (e) => {
                currentIndex += Math.round(e.deltaY / 2);
                if (currentIndex > game.histories.length - 1) {
                    currentIndex = game.histories.length - 1;
                } else if (currentIndex < 0) {
                    currentIndex = 0;
                }
                indexDetails(currentIndex);
                return false;
            };

            details.onmouseenter = () => {
                window.onkeydown = (e) => {
                    e.preventDefault();
                    switch (e.keyCode) {
                        case 38:
                            currentIndex += 1;
                            break;
                        case 40:
                            currentIndex -= 1;
                            break;
                    }
                    indexDetails(currentIndex);
                };
            };

            details.addEventListener('touchstart', handleTouchStart, false);        
            details.addEventListener('touchmove', handleTouchMove, false);

            let xDown = null;                                                        
            let yDown = null;

            function getTouches(evt) {
              return evt.touches ||
                    evt.originalEvent.touches; 
            }                                                     
                                                                                    
            function handleTouchStart(evt) {
                evt.stopPropagation();
                evt.preventDefault();
                const firstTouch = getTouches(evt)[0];                                      
                xDown = firstTouch.clientX;                                      
                yDown = firstTouch.clientY;                                      
            };                                                
                                                                                    
            function handleTouchMove(evt) {
                if ( ! xDown || ! yDown ) {
                    return;
                }

                evt.stopPropagation();
                evt.preventDefault();

                var xUp = evt.touches[0].clientX;                                    
                var yUp = evt.touches[0].clientY;

                var xDiff = xDown - xUp;
                var yDiff = yDown - yUp;
                                                                                    
                if ( Math.abs( xDiff ) > Math.abs( yDiff ) ) {
                    if ( xDiff > 0 ) {
                        /* right swipe */ 
                    } else {
                        /* left swipe */
                    }                       
                } else {
                    currentIndex += Math.round(yDiff / -1);
                    if (currentIndex > game.histories.length - 1) {
                        currentIndex = game.histories.length - 1;
                    } else if (currentIndex < 0) {
                        currentIndex = 0;
                    }
                    indexDetails(currentIndex);
                    return false;                                                                 
                }
                xDown = null;
                yDown = null;                                             
            };

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
              ${historyHTML(index, game.histories.length - 1, game.histories)}
            </div>
            <div class='desktop game-instructions'>
              <div>
                <div>Go forward in time:</div>
                <div class='game-highlighted'>hover over game & scroll up</div>
                <div>or</div>
                <div class='game-highlighted'>↑ key</div>
              </div>
              <div>
                <div>Go backward in time:</div>
                <div class='game-highlighted'>hover over game & scroll down</div>
                <div>or</div>
                <div class='game-highlighted'>↓ key</div>
              </div>
            </div>
          </div>
          <div class='desktop game-info'>
            <div>
              <div class='game-info-header'>Game ID</div>
              <div class='game-highlighted'>${game.id}</div>
            </div>
            <div>
              <div class='game-info-header'>Player</div>
              <div class='game-highlighted'>${leaderAddress}</div>
            </div>
          </div>
        `;
            };

            indexDetails(currentIndex);
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

const submit = async (network, gameAddress, walletSigner, onComplete) => {
    const signableTransaction = {
        kind: "moveCall",
        data: {
            packageObjectId: contractAddress,
            module: "leaderboard_8192",
            function: "submit_game",
            typeArguments: [],
            arguments: [gameAddress, leaderboardAddress],
            gasBudget: 100000,
        },
    };

    const response = await ethos.transact({
        signer: walletSigner,
        signableTransaction,
    });

    await load(network, true);
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
};
