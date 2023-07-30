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
const { eById, eByClass, addClass, removeClass } = require("./utils");
  
const contestApi = "https://dev-collection.ethoswallet.xyz/api/v1/sui8192"
const cachedLeaders = {
    day: 0,
    timestamp: 0,
    leaders: []
}
let leaderboards;
let startDate;
let endDate;

const contest = {
    getLeaders: async (day, network, timestamp) => {
        if (cachedLeaders.day === day && (cachedLeaders.timestamp === timestamp || cachedLeaders.timestamp > Date.now() - 1000 * 30)) {
            return cachedLeaders;
        }

        const connection = new Connection({ fullnode: network })
        const provider = new JsonRpcProvider(connection);
        
        if (!leaderboards || new Date(leaderboards[0].end) < Date.now()) {
          const leaderboardResponse = await fetch(
            `${contestApi}/leaderboards?limit=10`
          )

          leaderboards = await leaderboardResponse.json();
        }
        const selectedLeaderboard = leaderboards[day - 1];
        const leaderboardId = selectedLeaderboard.id;
        startDate = new Date(selectedLeaderboard.start);
        endDate = new Date(selectedLeaderboard.end);

        if (endDate.getTime() < Date.now()) {
          addClass(eByClass('during-contest'), 'hidden');
          removeClass(eByClass('after-contest'), 'hidden');
        } else {
          removeClass(eByClass('during-contest'), 'hidden');
          addClass(eByClass('after-contest'), 'hidden');
        }

        const response = await fetch(
            `${contestApi}/${leaderboardId}/leaderboard`
        )
        
        const leaderboard = await response.json();
        console.log("leaderboard", leaderboard)
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
            if (!gameObject.data) return null;
            //   return {
            //     gameId: leaderboardObject.top_games[index].fields.game_id,
            //     topTile: parseInt(leaderboardObject.top_games[index].fields.top_tile),
            //     score: parseInt(leaderboardObject.top_games[index].fields.score),
            //     leaderAddress: leaderboardObject.top_games[index].fields.leader_address
            //   }
            // } else {
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
          // }
        ).filter(
        (item) => !!item
        ).sort(
          (a, b) => {
            if (a.topTile === b.topTile) {
              return parseInt(b.score) - parseInt(a.score)
            } else {
              return parseInt(b.topTile) - parseInt(a.topTile)
            }
          }
        )
 
        cachedLeaders.day = day;
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

    timeUntilEnd: () => {  
        if (!leaderboards?.[0]?.end) return;
        const _second = 1000;
        const _minute = _second * 60;
        const _hour = _minute * 60;
        const _day = _hour * 24;

        const now = new Date();
        const distance = new Date(leaderboards[0].end) - now;
        
        return {
            days: Math.floor(distance / _day),
            hours: Math.floor((distance % _day) / _hour),
            minutes: Math.floor((distance % _hour) / _minute),
            seconds: Math.floor((distance % _minute) / _second)
        }
    },

    countdown: () => {
      const remaining = contest.timeUntilEnd();
      if (remaining) {
        eById("countdown-time-days").innerHTML = `${remaining.days < 10 ? 0 : ''}${remaining.days}`;
        eById("countdown-time-hours").innerHTML = `${remaining.hours < 10 ? 0 : ''}${remaining.hours}`;
        eById("countdown-time-minutes").innerHTML = `${remaining.minutes < 10 ? 0 : ''}${remaining.minutes}`;
        eById("countdown-time-seconds").innerHTML = `${remaining.seconds < 10 ? 0 : ''}${remaining.seconds}`;      
      }
      setTimeout(contest.countdown, 1000)  
    },

    ended: () => {
        return Date.now() > endDate;
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