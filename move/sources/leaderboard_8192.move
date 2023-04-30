module ethos::leaderboard_8192 {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;

    use ethos::game_8192::{Self, Game8192};

    const ENotALeader: u64 = 0;
    const ELowTile: u64 = 1;
    const ELowScore: u64 = 2;

    struct Leaderboard8192 has key, store {
        id: UID,
        max_leaderboard_game_count: u64,
        top_games: Table<u64, TopGame8192>,
        min_tile: u64,
        min_score: u64
    }

    struct TopGame8192 has store, copy, drop {
        game_id: ID,
        leader_address: address,
        top_tile: u64,
        score: u64
    }

    fun init(ctx: &mut TxContext) {
        create(ctx);
    }

    // ENTRY FUNCTIONS //

    public entry fun create(ctx: &mut TxContext) {
        let leaderboard = Leaderboard8192 {
            id: object::new(ctx),
            max_leaderboard_game_count: 200,
            top_games: table::new<u64, TopGame8192>(ctx),
            min_tile: 0,
            min_score: 0
        };

        transfer::share_object(leaderboard);
    }

    public entry fun submit_game(game: &mut Game8192, leaderboard: &mut Leaderboard8192) {
        let top_tile = *game_8192::top_tile(game);
        let score = *game_8192::score(game);

        assert!(top_tile >= leaderboard.min_tile, ELowTile);
        assert!(score >= leaderboard.min_score, ELowScore);

        let leader_address = *game_8192::player(game);
        let game_id = game_8192::id(game);

        let top_game = TopGame8192 {
            game_id,
            leader_address,
            score: *game_8192::score(game),
            top_tile: *game_8192::top_tile(game)
        };

        if (table::length(&leaderboard.top_games) == 0) {
            table::add<u64, TopGame8192>(&mut leaderboard.top_games, 0, top_game);
            return
        };

        let leader_index = table::length(&leaderboard.top_games) - 1;
        let bottom_game = top_game_at(leaderboard, leader_index);

        let add_at = leader_index + 1;
        while (bottom_game.top_tile <= top_game.top_tile && bottom_game.score < top_game.score) {
            let move_game = table::remove<u64, TopGame8192>(&mut leaderboard.top_games, leader_index);
            table::add<u64, TopGame8192>(&mut leaderboard.top_games, leader_index + 1, move_game);
            add_at = leader_index;

            if (leader_index == 0) break;

            leader_index = leader_index - 1;
            bottom_game = top_game_at(leaderboard, leader_index);
        };

        table::add<u64, TopGame8192>(&mut leaderboard.top_games, add_at, top_game);

        let max_game_count = leaderboard.max_leaderboard_game_count;
        if (table::length(&leaderboard.top_games) > max_game_count) {
            table::remove<u64, TopGame8192>(&mut leaderboard.top_games, leaderboard.max_leaderboard_game_count);
            let bottom_game = table::borrow<u64, TopGame8192>(&mut leaderboard.top_games, max_game_count - 1);
            leaderboard.min_tile = bottom_game.top_tile;
            leaderboard.min_score = bottom_game.score;
        };
    }

    // PUBLIC ACCESSOR FUNCTIONS //

    public fun game_count(leaderboard: &Leaderboard8192): u64 {
        table::length(&leaderboard.top_games)
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

    public fun top_game_game_id(top_game: &TopGame8192): ID {
        top_game.game_id
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
            max_leaderboard_game_count: max_leaderboard_game_count,
            top_games: table::new<u64, TopGame8192>(ctx),
            min_tile: min_tile,
            min_score: min_score
        };

        transfer::share_object(leaderboard)
    }
}