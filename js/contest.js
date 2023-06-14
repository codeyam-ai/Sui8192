const { Connection, JsonRpcProvider } = require("@mysten/sui.js");

const {
    mainnetContractAddress,
  } = require("./constants");
  
const contest = {
    getLeaders: async (provider) => {
        try {      
            const gameMoveEvents = await provider.queryEvents({
                query: {
                    MoveEventType: `${mainnetContractAddress}::game_8192::GameMoveEvent8192`
                },
                order: "descending"
            })
           
            const games = {}
            for (const event of gameMoveEvents.data) {
                if (games[event.parsedJson.game_id]) continue;
                games[event.parsedJson.game_id] = event.parsedJson;
            }
    
            return Object.values(games).sort((a, b) => {
                if (b.top_tile > a.top_tile) return 1;
                if (b.top_tile < a.top_tile) return -1;
                return b.score - a.score
            });
        } catch (e) {
            console.error(e);
        }
    }
}

module.exports = contest;