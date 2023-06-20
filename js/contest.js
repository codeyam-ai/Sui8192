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
  
const contestApi = "https://collection.ethoswallet.xyz/api/v1/sui8192"
const startDate = new Date("2023-06-20T16:00:00.000Z");
const endDate = new Date("2023-06-27T15:59:59.000Z");
const cachedLeaders = {
    timestamp: 0,
    leaders: []
}

const contest = {
    getLeaders: async (network, timestamp) => {
        if (cachedLeaders.timestamp === timestamp || cachedLeaders.timestamp > Date.now() - 1000 * 30) {
            return cachedLeaders;
        }

        const connection = new Connection({ fullnode: network })
        const provider = new JsonRpcProvider(connection);
        
        const response = await fetch(
            `${contestApi}/${contestLeaderboardId}/leaderboard`
        )
        
        const leaderboard = await response.json();
        const ids = leaderboard.games.map(g => g.gameId);

        const suiObjects = [];
        while(ids.length) {
          const batch = ids.splice(0, 50);
          const batchObjects = await provider.multiGetObjects({ 
            ids: batch, 
            options: { showContent: true } 
          });
          suiObjects.push(...batchObjects);
        }
        
        const leaderboardItems = suiObjects.map(
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
            if (a.topTile === b.topTile) {
              return parseInt(b.score) - parseInt(a.score)
            } else {
              return parseInt(b.topTile) - parseInt(a.topTile)
            }
          }
        )
 
        cachedLeaders.timestamp = Date.now();
        cachedLeaders.leaders = leaderboardItems;

        return cachedLeaders;
    },

    validIds: async (address) => {
        const response = await fetch(
            `${contestApi}/games?address=${address}`,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        )

        const validGames = await response.json();

        return validGames.filter((game) => new Date(game.start) >= startDate).map((game) => game.gameId);
    },

    timeUntilStart: () => {  
        const _second = 1000;
        const _minute = _second * 60;
        const _hour = _minute * 60;
        const _day = _hour * 24;

        const now = new Date();
        const distance = startDate - now;
        
        return {
            days: Math.floor(distance / _day),
            hours: Math.floor((distance % _day) / _hour),
            minutes: Math.floor((distance % _hour) / _minute),
            seconds: Math.floor((distance % _minute) / _second)
        }
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