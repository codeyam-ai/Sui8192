const { JsonRpcProvider } = require("@mysten/sui.js");
const { ethos } = require("ethos-wallet-beta");
const { contractAddress, leaderboardAddress } = require("./constants");
const { eById, addClass, truncateMiddle } = require("./utils");

let leaderboardObject;

const topGames = () => leaderboardObject.top_games;

const get = async () => {
  const provider = new JsonRpcProvider('https://fullnode.devnet.sui.io/', true, '0.11.0');
  const { details: { data: { fields: leaderboard } } } = await provider.getObject(leaderboardAddress);
  leaderboardObject = leaderboard;
  return leaderboard;
};

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
      leader_address: leaderAddress 
    } } = leaderboardObject.top_games[i];
    // const { value: { fields: { vec: leaderName } } } = leaders.find(
    //   ({ fields: { key: address } }) => leaderAddress === address
    // ).fields;
    const leaderElement = document.createElement("DIV")
    addClass(leaderElement, 'leader');
    leaderElement.innerHTML = `
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
  const details = {
    network: 'sui',
    address: contractAddress,
    moduleName: 'leaderboard_8192',
    functionName: 'submit_game',
    inputValues: [
      gameAddress,
      leaderboardAddress
    ],
    gasBudget: 100000
  };

  await ethos.transact({
    id: "leaderboard",
    signer: walletSigner, 
    details,
    onCompleted: async () => {
      load();
      ethos.hideWallet();
      onComplete(); //loadGames();
    }
  })
} 

module.exports = {
  topGames,
  minTile,
  minScore,
  get,
  load,
  submit
};