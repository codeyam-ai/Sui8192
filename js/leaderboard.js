const { JsonRpcProvider } = require("@mysten/sui.js");
const { ethos } = require("ethos-wallet-beta");
const { contractAddress, leaderboardAddress, tileNames } = require("./constants");
const { eById, eByClass, addClass, removeClass, truncateMiddle } = require("./utils");

let leaderboardObject;

const topGames = () => leaderboardObject.top_games;

const getObject = async (objectId) => {
  const provider = new JsonRpcProvider('https://fullnode.devnet.sui.io/'); 
  return provider.getObject(objectId);;
}

const get = async () => {
  const { details: { data: { fields: leaderboard } } } = await getObject(leaderboardAddress)
  leaderboardObject = leaderboard;
  return leaderboard;
};

const getLeaderboardGame = async (gameObjectId) => {
  const gameObject = await getObject(gameObjectId);
  let { details: { data: { fields: { boards, moves, game_over: gameOver } } } } = gameObject;
  gameOver = boards[boards.length - 1].fields.game_over;
  return { id: gameObjectId, gameOver, moveCount: moves.length, boards }
}

const boardHTML = (moveIndex, boards) => { 
  const board = boards[moveIndex];
  const rows = [];
  for (const row of board.fields.spaces) {
    const rowHTML = [];
    rowHTML.push("<div class='leaderboard-board-row'>")
    for (const column of row) {
      rowHTML.push(`
        <div class='leaderboard-board-tile color${column === null ? '-none' : column + 1} '>
          <div>
            ${column === null ? '&nbsp;' : Math.pow(2, column + 1)}
          </div>
          <div class='leaderboard-board-tile-name'>
            ${column === null ? '&nbsp;' : tileNames[column + 1]}
          </div>
        </div>
      `);
    }
    rowHTML.push("</div>")
    rows.push(rowHTML.join(""));
  }

  const completeHTML = `
    <div class='leaderboard-board'>
      <div class='leaderboard-board-title'>
        Move: ${moveIndex}, Score: ${board.fields.score}
      </div>
      ${rows.join("")}
    </div>
  `
  return completeHTML
}

const load = async () => {
  leaderboardObject = await get();
  // const { fields: { contents: leaders } } = leaderboardObject.leaders;

  const leaderboardList = eById('leaderboard-list');
  leaderboardList.innerHTML = "";

  eById('best').innerHTML = leaderboardObject.top_games[0]?.fields?.score || 0;

  for (let i=0; i<leaderboardObject.top_games.length; ++i) {
    const { fields: { 
      score, 
      top_tile: topTile, 
      leader_address: leaderAddress,
      game_id: gameId
    } } = leaderboardObject.top_games[i];
    const leaderElement = document.createElement("DIV")
    addClass(leaderElement, 'leader');

    const listing = document.createElement("DIV");
    addClass(listing, 'leader-listing');
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
          ${truncateMiddle(leaderAddress)}
        </div>
      </div>     
    `;

    leaderElement.append(listing);

    leaderElement.onclick = async () => {
      removeClass(eByClass('leader'), 'selected');
      addClass(leaderElement, 'selected');

      const details = document.createElement("DIV");
      
      leaderElement.onclick = () => {
        if (leaderElement.classList.contains('selected')) {
          removeClass(leaderElement, 'selected');
        } else {
          removeClass(eByClass('leader'), 'selected');
          addClass(leaderElement, 'selected');
        }
      }

      addClass(details, 'leader-details');
      details.innerHTML = "<div class='text-center'>Loading game...</div>";
      leaderElement.append(details);

      const game = await getLeaderboardGame(gameId);

      let currentIndex = game.boards.length - 1;
      details.onmousewheel = (e) => {
        currentIndex += Math.round(e.deltaY / 2);
        if (currentIndex > game.boards.length - 1) {
          currentIndex = game.boards.length - 1; 
        } else if (currentIndex < 0) {
          currentIndex = 0;
        }
        indexDetails(currentIndex)
        return false;
      }

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
        }
      }

      const indexDetails = (index) => {
        details.innerHTML = `
          <div class='game-status'>
            <div>
              <div>Status</div>
              <div class='game-status-${game.gameOver ? 'over' : 'active'}'>
                ${game.gameOver ? 'Game Over' : 'Active'}
              </div>
            </div>
          </div>
          <div class='leader-boards'>
            <div class='leader-board'>
              ${boardHTML(index, game.boards)}
            </div>
            <div class='game-instructions'>
              <div>
                <div>Go forward in time:</div>
                <div class='game-highlighted'>scroll up over game</div>
                <div>or</div>
                <div class='game-highlighted'>↑ key</div>
              </div>
              <div>
                <div>Go backward in time:</div>
                <div class='game-highlighted'>scroll down over game</div>
                <div>or</div>
                <div class='game-highlighted'>↓ key</div>
              </div>
            </div>
          </div>
          <div class='game-info'>
            <div>
              <div class='game-info-header'>Total Moves</div>
              <div class='game-highlighted'>${game.moveCount}</div>
            </div>
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
      }

      indexDetails(currentIndex);
    };
    
    leaderboardList.append(leaderElement);
  }
}

const minScore = () => {
  return leaderboardObject.min_score;
}

const minTile = () => {
  return leaderboardObject.min_tile;
}

const submit = async (gameAddress, walletSigner, onComplete) => {
  const signableTransaction = {
    kind: "moveCall",
    data: {
      packageObjectId: contractAddress,
      module: 'leaderboard_8192',
      function: 'submit_game',
      typeArguments: [],
      arguments: [
        gameAddress,
        leaderboardAddress
      ],
      gasBudget: 100000
    }
  };

  await ethos.transact({
    signer: walletSigner, 
    signableTransaction
  })

  load();
  ethos.hideWallet();
  onComplete();
} 

module.exports = {
  topGames,
  minTile,
  minScore,
  get,
  load,
  submit
};