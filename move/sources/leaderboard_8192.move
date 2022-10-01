module ethos::leaderboard_8192 {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use std::ascii::{Self, String};
    use std::vector;
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use std::option::{Self, Option};

    use ethos::game_8192::{Self, Game8192};

    const ENotALeader: u64 = 0;
    const ETileNotAboveMin: u64 = 1;
    const EScoreNotAboveMin: u64 = 2;

    struct Leaderboard8192 has key, store {
        id: UID,
        game_count: u64,
        max_leaderboard_game_count: u64,
        top_games: vector<TopGame8192>,
        leaders: VecMap<address, Option<String>>,
        min_tile: u8,
        min_score: u64
    }

    struct TopGame8192 has store, drop {
        game_id: ID,
        leader_address: address,
        top_tile: u8,
        score: u64,
        epoch: u64
    }

    fun init(ctx: &mut TxContext) {
        create(ctx);
    }

    public entry fun create(ctx: &mut TxContext) {
        let leaderboard = Leaderboard8192 {
            id: object::new(ctx),
            game_count: 0,
            max_leaderboard_game_count: 500,
            top_games: vector[],
            leaders: vec_map::empty<address, Option<String>>(),
            min_tile: 0,
            min_score: 0
        };

        transfer::share_object(leaderboard);
    }

    public fun game_count(leaderboard: &Leaderboard8192): &u64 {
        &leaderboard.game_count
    }

    public fun top_games(leaderboard: &Leaderboard8192): &vector<TopGame8192> {
        &leaderboard.top_games
    }

    public fun top_game_at(leaderboard: &Leaderboard8192, index: u64): &TopGame8192 {
        vector::borrow(&leaderboard.top_games, index)
    }

    public fun top_game_game_id(top_game: &TopGame8192): &ID {
        &top_game.game_id
    }

    public fun top_game_top_tile(top_game: &TopGame8192): &u8 {
        &top_game.top_tile
    }

    public fun top_game_score(top_game: &TopGame8192): &u64 {
        &top_game.score
    }

    public fun min_tile(leaderboard: &Leaderboard8192): &u8 {
        &leaderboard.min_tile
    }

    public fun min_score(leaderboard: &Leaderboard8192): &u64 {
        &leaderboard.min_score
    }

    // public entry fun create_game(leaderboard: &mut Leaderboard8192, ctx: &mut TxContext) {
    //     game_8192::create(object::uid_to_inner(&leaderboard.id), ctx);
    //     leaderboard.game_count = leaderboard.game_count + 1;
    // }

    // public entry fun make_move(game: &mut Game8192, direction: u8, leaderboard: &mut Leaderboard8192, ctx: &mut TxContext) {
    //     game_8192::make_move(game, direction, ctx);
    //     let top_tile = *game_8192::top_tile(game);
    //     let score = *game_8192::score(game);
    //     if (top_tile >= leaderboard.min_tile || score >= leaderboard.min_score) {
    //         submit_game(game, leaderboard);
    //     }
    // }

    public entry fun submit_game(game: &mut Game8192, leaderboard: &mut Leaderboard8192, ctx: &mut TxContext) {
        let top_tile = *game_8192::top_tile(game);
        let score = *game_8192::score(game);
        assert!(top_tile >= leaderboard.min_tile, 1);
        assert!(score >= leaderboard.min_score, 2);
        if (top_tile < leaderboard.min_tile && score < leaderboard.min_score) {
            return
        };

        let top_game_count = vector::length(&leaderboard.top_games);
        
        if (top_tile == leaderboard.min_tile && score == leaderboard.min_score) {
            assert!(top_game_count < leaderboard.max_leaderboard_game_count, ENotALeader);
            return
        };

        let leader_address = *game_8192::player(game);

        if (!vec_map::contains(&leaderboard.leaders, &leader_address)) {
            vec_map::insert(&mut leaderboard.leaders, leader_address, option::none());
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
        while (index < top_game_count) {
          let top_game = top_game_at(leaderboard, index);
          if (top_game.game_id == game_id) {
              vector::remove(&mut leaderboard.top_games, index);
              top_game_count = top_game_count - 1;
          };
          index = index + 1;
        };

        vector::push_back(&mut leaderboard.top_games, new_top_game);
          
        if (top_game_count == 0) {
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
                vector::swap(&mut leaderboard.top_games, index, top_game_count);
            };

            index = index + 1;
        };

        if (!slot_found) {
            let position = vector::length(&leaderboard.top_games) - 1;
            game_8192::record_leaderboard_game(game, leaderboard_id, position, epoch);
        };
        
        if (top_game_count + 1 >= leaderboard.max_leaderboard_game_count) {
            leaderboard.min_tile = min_tile;
            leaderboard.min_score = min_score;
        };
    }

    public entry fun set_name(leaderboard: &mut Leaderboard8192, name: vector<u8>, ctx: &mut TxContext) {
        let address = tx_context::sender(ctx);
        assert!(vec_map::contains(&leaderboard.leaders, &address), ENotALeader);        
        let leader_option = vec_map::get_mut(&mut leaderboard.leaders, &address);

        let name_string = ascii::string(name);
        if (option::is_none(leader_option)) {
            option::fill(leader_option, name_string);
        } else {
            option::swap(leader_option, name_string);
        }
    }

    #[test_only]
    use sui::test_scenario::{Self, Scenario};

    #[test_only]
    public fun init_leaderboard(scenario: &mut Scenario) {
        init(test_scenario::ctx(scenario));
    }

    #[test_only]
    public fun blank_leaderboard(scenario: &mut Scenario, max_leaderboard_game_count: u64, min_tile: u8, min_score: u64) {
        let leaderboard = Leaderboard8192 {
            id: object::new(test_scenario::ctx(scenario)),
            game_count: 0,
            max_leaderboard_game_count: max_leaderboard_game_count,
            top_games: vector[],
            leaders: vec_map::empty<address, Option<String>>(),
            min_tile: min_tile,
            min_score: min_score
        };

        transfer::share_object(leaderboard)
    }
}