const { Connection, JsonRpcProvider } = require("@mysten/sui.js");

const {
    ROWS,
    COLUMNS,
    spaceAt
  } = require('./board');

const {
    testnetContractAddress,
    mainnetContractAddress,
    contestLeaderboardId
  } = require("./constants");
  
const contest = {
    getLeaders: async (network) => {
        const leaderboard = await fetch(
            `https://dev-collection.ethoswallet.xyz/api/v1/sui8192/${contestLeaderboardId}/leaderboard`
        )
        console.log("leaderboard",  leaderboard)
    }
}

module.exports = contest;


// try {      
//     const connection = new Connection({ fullnode: network })
//     const provider = new JsonRpcProvider(connection);

//     const gameMoveEvents = await provider.queryEvents({
//         query: {
//             MoveEventType: `${testnetContractAddress}::game_8192::NewGameEvent8192`
//         },
//         order: "descending"
//     })
   
//     const ids = [];
//     for (const event of gameMoveEvents.data) {
//         ids.push(event.parsedJson.game_id);
//     }

//     const objects = await provider.multiGetObjects({ 
//         ids, 
//         options: { showContent: true } 
//     });

//     const leaderboardGames = objects.filter(o => !!o.data).map(
//         (gameObject) => {
//             if (!gameObject.data) return {};

//             const packedSpaces = gameObject.data.content.fields.active_board.fields.packed_spaces;
//             let topTile = 0;
//             for (let i=0; i<ROWS; ++i) {
//                 for (let j=0; j<COLUMNS; ++j) {
//                     const tile = spaceAt(packedSpaces, i, j);
//                     if (topTile < tile) {
//                     topTile = tile;
//                     }
//                 }
//             }

//             return {
//                 gameId: gameObject.data.objectId,
//                 topTile,
//                 score: parseInt(gameObject.data.content.fields.score),
//                 leaderAddress: gameObject.data.content.fields.player
//             }
//         }
//     )
     
//     return leaderboardGames.sort((a, b) => {
//         if (b.topTile > a.topTile) return 1;
//         if (b.topTile < a.topTile) return -1;
//         return b.score - a.score
//     });
// } catch (e) {
//     console.error(e);
// }