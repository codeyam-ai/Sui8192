module ethos::leaderboard_8192 {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{String};
    use sui::table::{Self, Table};
    use sui::transfer;
    use std::option::{Self, Option};

    use ethos::game_8192::{Self, Game8192};

    const ENotALeader: u64 = 0;
    const ELowTile: u64 = 1;
    const ELowScore: u64 = 2;

    struct Leaderboard8192 has key, store {
        id: UID,
        game_count: u64,
        max_leaderboard_game_count: u64,
        top_games: Table<u64, TopGame8192>,
        leaders: Table<address, Option<String>>,
        min_tile: u64,
        min_score: u64
    }

    struct TopGame8192 has store, copy, drop {
        game_id: ID,
        leader_address: address,
        top_tile: u64,
        score: u64,
        epoch: u64
    }

    fun init(ctx: &mut TxContext) {
        create(ctx);
    }

    // ENTRY FUNCTIONS //

    public entry fun create(ctx: &mut TxContext) {
        let leaderboard = Leaderboard8192 {
            id: object::new(ctx),
            game_count: 0,
            max_leaderboard_game_count: 200,
            top_games: table::new<u64, TopGame8192>(ctx),
            leaders: table::new<address, Option<String>>(ctx),
            min_tile: 0,
            min_score: 0
        };

        transfer::share_object(leaderboard);
    }

    public entry fun submit_game(game: &mut Game8192, leaderboard: &mut Leaderboard8192, ctx: &mut TxContext) {
        let top_tile = *game_8192::top_tile(game);
        let score = *game_8192::score(game);
        assert!(top_tile >= leaderboard.min_tile, ELowTile);
        assert!(score >= leaderboard.min_score, ELowScore);

        let top_game_count = leaderboard.game_count;
        
        if (top_tile == leaderboard.min_tile && score == leaderboard.min_score) {
            assert!(top_game_count < leaderboard.max_leaderboard_game_count, ENotALeader);
        };

        let leader_address = *game_8192::player(game);

        if (!table::contains<address, Option<String>>(&leaderboard.leaders, leader_address)) {
            table::add(&mut leaderboard.leaders, leader_address, option::none());
        };

        let game_id = object::uid_to_inner(game_8192::id(game));
        let leaderboard_id = object::uid_to_inner(&leaderboard.id);
        let epoch = tx_context::epoch(ctx);
        
        let new_top_game = TopGame8192 {
            game_id,
            leader_address,
            score: *game_8192::score(game),
            top_tile: *game_8192::top_tile(game),
            epoch
        };
        
        let index = 0;
        let top_game_found = false;
        while (index < top_game_count) {
            if (top_game_found) {
                let swap = table::remove<u64, TopGame8192>(&mut leaderboard.top_games, index);
                table::add<u64, TopGame8192>(&mut leaderboard.top_games, index - 1, swap);
            } else {
                top_game_found = top_game_at_has_id(leaderboard, index, game_id);
                
                if (top_game_found) {
                    table::remove<u64, TopGame8192>(&mut leaderboard.top_games, index);
                };
            };

            index = index + 1;
        };

        if (top_game_found) {
            top_game_count = top_game_count - 1;
        };

        table::add<u64, TopGame8192>(&mut leaderboard.top_games, top_game_count, new_top_game);
          
        if (top_game_count == 0) {
            leaderboard.game_count = 1;
            game_8192::record_leaderboard_game(game, leaderboard_id, 0, epoch);
            return
        };

        index = 0;
        let slot_found = false;

        let top_top_game = top_game_at(leaderboard, 0);
        let min_tile = top_top_game.top_tile;
        let min_score = top_top_game.score;
        while (index < top_game_count) {
            let top_game = top_game_at(leaderboard, index);
            
            if (!slot_found && top_tile >= top_game.top_tile) {
                if (top_tile > top_game.top_tile || score > top_game.score) {
                    game_8192::record_leaderboard_game(game, leaderboard_id, index, epoch);
                    slot_found = true;
                }
            };

            if (top_game.top_tile < min_tile ) {
                min_tile = top_game.top_tile;
            };

            if (top_game.score < min_score) {
                min_score = top_game.score;
            };

            if (slot_found) {
                let top_game_1 = table::remove<u64, TopGame8192>(&mut leaderboard.top_games, top_game_count);
                let top_game_2 = table::remove<u64, TopGame8192>(&mut leaderboard.top_games, index);
                table::add<u64, TopGame8192>(&mut leaderboard.top_games, index, top_game_1);
                table::add<u64, TopGame8192>(&mut leaderboard.top_games, top_game_count, top_game_2);
            };

            index = index + 1;
        };

        if (!slot_found) {
            let position = table::length(&leaderboard.top_games) - 1;
            game_8192::record_leaderboard_game(game, leaderboard_id, position, epoch);
        };
        
        let game_count = table::length(&leaderboard.top_games);
        if (game_count >= leaderboard.max_leaderboard_game_count) {
            leaderboard.min_tile = min_tile;
            leaderboard.min_score = min_score;

            while (game_count > leaderboard.max_leaderboard_game_count) {
                table::remove<u64, TopGame8192>(&mut leaderboard.top_games, game_count - 1);
                game_count = game_count - 1;
            };
        };

        leaderboard.game_count = table::length(&leaderboard.top_games);
    }

    // PUBLIC ACCESSOR FUNCTIONS //

    public fun game_count(leaderboard: &Leaderboard8192): &u64 {
        &leaderboard.game_count
    }

    public fun top_games(leaderboard: &Leaderboard8192): &Table<u64, TopGame8192> {
        &leaderboard.top_games
    }

    public fun top_game_at(leaderboard: &Leaderboard8192, index: u64): &TopGame8192 {
        table::borrow(&leaderboard.top_games, index)
    }

    public fun top_game_at_has_id(leaderboard: &Leaderboard8192, index: u64, game_id: ID): bool {
        let top_game = top_game_at(leaderboard, index);
        top_game.game_id == game_id
    }

    public fun top_game_game_id(top_game: &TopGame8192): &ID {
        &top_game.game_id
    }

    public fun top_game_top_tile(top_game: &TopGame8192): &u64 {
        &top_game.top_tile
    }

    public fun top_game_score(top_game: &TopGame8192): &u64 {
        &top_game.score
    }

    public fun min_tile(leaderboard: &Leaderboard8192): &u64 {
        &leaderboard.min_tile
    }

    public fun min_score(leaderboard: &Leaderboard8192): &u64 {
        &leaderboard.min_score
    }

    

    // TEST FUNCTIONS //

    #[test_only]
    use sui::test_scenario::{Self, Scenario};

    #[test_only]
    public fun blank_leaderboard(scenario: &mut Scenario, max_leaderboard_game_count: u64, min_tile: u64, min_score: u64) {
        let ctx = test_scenario::ctx(scenario);
        let leaderboard = Leaderboard8192 {
            id: object::new(ctx),
            game_count: 0,
            max_leaderboard_game_count: max_leaderboard_game_count,
            top_games: table::new<u64, TopGame8192>(ctx),
            leaders: table::new<address, Option<String>>(ctx),
            min_tile: min_tile,
            min_score: min_score
        };

        transfer::share_object(leaderboard)
    }
}