
#[test_only]
module ethos::leaderboard_8192_tests {
    use std::option;
    use std::vector;

    use sui::object::ID;
    use sui::sui::SUI;
    use sui::coin::{Self};
    use sui::tx_context::{TxContext};
    use sui::test_scenario::{Self, Scenario};

    use ethos::game_board_8192::{packed_spaces, move_spaces, left, up, right, down};

    use ethos::leaderboard_8192::{Self, Leaderboard8192};
    use ethos::game_8192::{Self, Game8192, Game8192Maintainer};
    
    const PLAYER: address = @0xCAFE;

    fun create_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);

        let maintainer = game_8192::create_maintainer(ctx);

        let coins = vector[
            coin::mint_for_testing<SUI>(150_000_000, ctx),
            coin::mint_for_testing<SUI>(30_000_000, ctx),
            coin::mint_for_testing<SUI>(40_000_000, ctx)
        ];

        game_8192::create(&mut maintainer, coins, ctx);

        sui::test_utils::destroy<Game8192Maintainer>(maintainer);
    }

    fun make_move_if_valid(game: &mut Game8192, direction: u64, ctx: &mut TxContext) {
        let board = game_8192::active_board(game);
        let spaces = *packed_spaces(board);
        let (new_spaces, _, _) = move_spaces(spaces, direction);

        if (spaces != new_spaces) {
            game_8192::make_move(game, direction, ctx);
        };
    }

    fun achieve_score(scenario: &mut Scenario, score: u64) {
        test_scenario::next_tx(scenario, PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(scenario);
            let game = test_scenario::take_from_sender<Game8192>(scenario);            
        
            let ctx = test_scenario::ctx(scenario);
            while (*game_8192::score(&game) < score) {
                make_move_if_valid(&mut game, left(), ctx);
                make_move_if_valid(&mut game, up(), ctx);
                make_move_if_valid(&mut game, right(), ctx);
                make_move_if_valid(&mut game, down(), ctx);
            };

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(scenario, game);
            test_scenario::return_shared(leaderboard);
        };
    }

    fun achieve_score_game(scenario: &mut Scenario, game_id: ID, score: u64) {
        test_scenario::next_tx(scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(scenario);
            let game = test_scenario::take_from_sender_by_id<Game8192>(scenario, game_id);
        
            let ctx = test_scenario::ctx(scenario);
            while (*game_8192::score(&game) < score) {
                game_8192::make_move(&mut game, left(), ctx);
                game_8192::make_move(&mut game, up(), ctx);
                game_8192::make_move(&mut game, right(), ctx);
                game_8192::make_move(&mut game, down(), ctx);
            };

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(scenario, game);
            test_scenario::return_shared(leaderboard);
        };
    }

    fun check_scores(scenario: &mut Scenario, scores: vector<u64>) {
        test_scenario::next_tx(scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(scenario);
            check_scores_for_leaderboard(&leaderboard, scores);
            test_scenario::return_shared(leaderboard);
        };
    }

    fun check_scores_for_leaderboard(leaderboard: &Leaderboard8192, scores: vector<u64>) {
        let index = 0;
        while (index < vector::length(&scores)) {
            let top_game = leaderboard_8192::top_game_at(leaderboard, index);
            assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
            index = index + 1;
        };
        let top_games_length = vector::length(leaderboard_8192::top_games(leaderboard));
        assert!(top_games_length == vector::length(&scores), top_games_length);
    }

    #[test]
    fun test_submit_game() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::create(test_scenario::ctx(&mut scenario)); 

        achieve_score(&mut scenario, 8);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == game_8192::id(&game), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__inserts_game_at_correct_location_in_top_list() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::create(test_scenario::ctx(&mut scenario)); 

        achieve_score(&mut scenario, 88);
        check_scores(&mut scenario, vector<u64>[88]);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let scores = vector<u64>[88];
            let index = 0;
            while (index < vector::length(&scores)) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            test_scenario::return_shared(leaderboard);
        };

        achieve_score(&mut scenario, 192);
        check_scores(&mut scenario, vector<u64>[192, 88]);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == game_8192::id(&game), 0);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        achieve_score(&mut scenario, 108);
        check_scores(&mut scenario, vector<u64>[192, 108, 88]);
        
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 1);
            assert!(leaderboard_8192::top_game_game_id(top_game) == game_8192::id(&game), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        achieve_score(&mut scenario, 36);
        check_scores(&mut scenario, vector<u64>[192, 108, 88, 36]);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 3);
            assert!(leaderboard_8192::top_game_game_id(top_game) == game_8192::id(&game), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        achieve_score(&mut scenario, 68);
        check_scores(&mut scenario, vector<u64>[192, 108, 88, 68, 36]);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 3);
            assert!(leaderboard_8192::top_game_game_id(top_game) == game_8192::id(&game), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__only_one_entry_per_game() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::create(test_scenario::ctx(&mut scenario)); 

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };
        
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let leaderboard_game_count = vector::length(leaderboard_8192::top_games(&leaderboard));
            assert!(leaderboard_game_count == 1, leaderboard_game_count);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__only_one_entry_per_game_with_multiple_games() {
        use sui::object::{ID};

        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::create(test_scenario::ctx(&mut scenario)); 

        let game1_id: ID;
        let game2_id: ID;

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game1_id = game_8192::id(&game);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };
        
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1_id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1_id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1_id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let leaderboard_game_count = vector::length(leaderboard_8192::top_games(&leaderboard));
            assert!(leaderboard_game_count == 1, leaderboard_game_count);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game2_id = game_8192::id(&game);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game2_id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1_id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let leaderboard_game_count = vector::length(leaderboard_8192::top_games(&leaderboard));
            assert!(leaderboard_game_count == 2, leaderboard_game_count);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = leaderboard_8192::ELowScore)]
    fun test_submit_game__aborts_if_not_a_leader() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 2, 0, 0);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__stores_min_tile_and_min_score() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 2, 0, 0);
        
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);
          
            assert!(leaderboard_8192::min_tile(&leaderboard) == &0, (*leaderboard_8192::min_tile(&leaderboard) as u64));
            assert!(leaderboard_8192::min_score(&leaderboard) == &0, *leaderboard_8192::min_score(&leaderboard));

            assert!(game_8192::score(&game) == &4, *game_8192::score(&game));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);
            
            assert!(leaderboard_8192::min_tile(&leaderboard) == &2, (*leaderboard_8192::min_tile(&leaderboard) as u64));
            assert!(leaderboard_8192::min_score(&leaderboard) == &4, *leaderboard_8192::min_score(&leaderboard));
            
            assert!(game_8192::score(&game) == &16, *game_8192::score(&game));
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = leaderboard_8192::ELowTile)]
    fun test_submit_game__aborts_if_not_above_min_tile() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 2, 3, 30);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);

            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = leaderboard_8192::ELowScore)]
    fun test_submit_game__aborts_if_not_above_min_score() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 2, 0, 30);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__accepts_game_if_above_min_score_even_if_leaderboard_full_removes_last_entry() {
        use sui::object::{ID};

        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 2, 0, 0);

        let game2_id: ID;
        let game3_id: ID;
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game2_id = game_8192::id(&game);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game3_id = game_8192::id(&game);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let top_games = leaderboard_8192::top_games(&leaderboard);
            let leaderboard_game_count = vector::length(top_games);
            assert!(leaderboard_game_count == 2, leaderboard_game_count);
            
            let top_game0 = vector::borrow(top_games, 0);
            assert!(game3_id == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = vector::borrow(top_games, 1);
            assert!(game2_id == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__top_game_removes_bottom() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 3, 0, 0);

        achieve_score(&mut scenario, 5);
        achieve_score(&mut scenario, 30);
        achieve_score(&mut scenario, 60);
        achieve_score(&mut scenario, 90);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game4 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game3 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game2 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game1 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let top_games = leaderboard_8192::top_games(&leaderboard);
            let leaderboard_game_count = vector::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = vector::borrow(top_games, 0);
            assert!(game_8192::id(&game4) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = vector::borrow(top_games, 1);
            assert!(game_8192::id(&game3) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = vector::borrow(top_games, 2);
            assert!(game_8192::id(&game2) == leaderboard_8192::top_game_game_id(top_game2), 2);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game1);
            test_scenario::return_to_sender(&mut scenario, game2);
            test_scenario::return_to_sender(&mut scenario, game3);
            test_scenario::return_to_sender(&mut scenario, game4);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__middle_game_removes_bottom() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 3, 0, 0);

        achieve_score(&mut scenario, 60);
        achieve_score(&mut scenario, 5);
        achieve_score(&mut scenario, 90);
        achieve_score(&mut scenario, 30);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game4 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game3 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game2 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game1 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let top_games = leaderboard_8192::top_games(&leaderboard);
            let leaderboard_game_count = vector::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = vector::borrow(top_games, 0);
            assert!(game_8192::id(&game3) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = vector::borrow(top_games, 1);
            assert!(game_8192::id(&game1) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = vector::borrow(top_games, 2);
            assert!(game_8192::id(&game4) == leaderboard_8192::top_game_game_id(top_game2), 2);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game1);
            test_scenario::return_to_sender(&mut scenario, game2);
            test_scenario::return_to_sender(&mut scenario, game3);
            test_scenario::return_to_sender(&mut scenario, game4);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__bottom_game_removes_bottom() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 3, 0, 0);

        achieve_score(&mut scenario, 90);
        achieve_score(&mut scenario, 30);
        achieve_score(&mut scenario, 5);
        achieve_score(&mut scenario, 60);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game4 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game3 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game2 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            let game1 = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let top_games = leaderboard_8192::top_games(&leaderboard);
            let leaderboard_game_count = vector::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = vector::borrow(top_games, 0);
            assert!(game_8192::id(&game1) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = vector::borrow(top_games, 1);
            assert!(game_8192::id(&game4) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = vector::borrow(top_games, 2);
            assert!(game_8192::id(&game2) == leaderboard_8192::top_game_game_id(top_game2), 2);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game1);
            test_scenario::return_to_sender(&mut scenario, game2);
            test_scenario::return_to_sender(&mut scenario, game3);
            test_scenario::return_to_sender(&mut scenario, game4);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_lots_of_games() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 9, 0, 0);

        achieve_score(&mut scenario, 88);
        check_scores(&mut scenario, vector<u64>[88]);

        achieve_score(&mut scenario, 104);
        check_scores(&mut scenario, vector<u64>[104, 88]);

        achieve_score(&mut scenario, 588);
        check_scores(&mut scenario, vector<u64>[588, 104, 88]);

        achieve_score(&mut scenario, 452);
        check_scores(&mut scenario, vector<u64>[588, 452, 104, 88]);

        achieve_score(&mut scenario, 72);
        check_scores(&mut scenario, vector<u64>[588, 452, 104, 88, 72]);

        achieve_score(&mut scenario, 136);
        check_scores(&mut scenario, vector<u64>[588, 452, 136, 104, 88, 72]);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_move_one_game_around() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 5, 0, 0);

        achieve_score(&mut scenario, 88);
        check_scores(&mut scenario, vector<u64>[88]);
        let game_id = test_scenario::most_recent_id_for_address<Game8192>(PLAYER);

        achieve_score(&mut scenario, 104);
        check_scores(&mut scenario, vector<u64>[104, 88]);

        achieve_score(&mut scenario, 252);
        check_scores(&mut scenario, vector<u64>[252, 104, 88]);

        achieve_score(&mut scenario, 196);
        check_scores(&mut scenario, vector<u64>[252, 196, 104, 88]);

        achieve_score(&mut scenario, 180);
        check_scores(&mut scenario, vector<u64>[252, 196, 180, 104, 88]);
        let game5_id = test_scenario::most_recent_id_for_address<Game8192>(PLAYER);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            game_8192::make_move(&mut game, left(), ctx);

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[252, 196, 180, 112, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[252, 196, 180, 116, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, up(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[252, 196, 192, 180, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };


        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game5_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[252, 196, 192, 188, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game5_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, up(), ctx);
            game_8192::make_move(&mut game, down(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, down(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, down(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[252, 248, 196, 192, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game5_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, down(), ctx);
            game_8192::make_move(&mut game, left(), ctx);

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[364, 252, 196, 192, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            let game = test_scenario::take_from_address_by_id<Game8192>(&mut scenario, PLAYER, option::destroy_some(game5_id));
        
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);

            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            check_scores_for_leaderboard(&leaderboard, vector<u64>[372, 252, 196, 192, 104]);

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_lots_of_players() {
        let scenario = test_scenario::begin(PLAYER);
        leaderboard_8192::blank_leaderboard(&mut scenario, 3, 0, 0);

        achieve_score(&mut scenario, 88);
        check_scores(&mut scenario, vector<u64>[88]);
        let game_1_id = test_scenario::most_recent_id_for_address<Game8192>(PLAYER);

        achieve_score(&mut scenario, 104);
        check_scores(&mut scenario, vector<u64>[104, 88]);

        achieve_score(&mut scenario, 132);
        check_scores(&mut scenario, vector<u64>[132, 104, 88]);

        achieve_score_game(&mut scenario, option::destroy_some(game_1_id), 104);
        check_scores(&mut scenario, vector<u64>[132, 112, 104]);

        achieve_score(&mut scenario, 136);
        check_scores(&mut scenario, vector<u64>[136, 132, 112]);
        let game_2_id = test_scenario::most_recent_id_for_address<Game8192>(PLAYER);

        achieve_score_game(&mut scenario, option::destroy_some(game_1_id), 188);
        check_scores(&mut scenario, vector<u64>[188, 136, 132]);

        achieve_score(&mut scenario, 168);
        check_scores(&mut scenario, vector<u64>[188, 168, 136]);

        achieve_score_game(&mut scenario, option::destroy_some(game_2_id), 196);
        check_scores(&mut scenario, vector<u64>[196, 188, 168]);

        achieve_score(&mut scenario, 220);
        check_scores(&mut scenario, vector<u64>[220, 196, 188]);
        let game_3_id = test_scenario::most_recent_id_for_address<Game8192>(PLAYER);

        achieve_score_game(&mut scenario, option::destroy_some(game_2_id), 236);
        check_scores(&mut scenario, vector<u64>[236, 220, 188]);

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let top_games = leaderboard_8192::top_games(&leaderboard);
            let leaderboard_game_count = vector::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = vector::borrow(top_games, 0);
            assert!(option::destroy_some(game_2_id) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = vector::borrow(top_games, 1);
            assert!(option::destroy_some(game_3_id) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = vector::borrow(top_games, 2);
            assert!(option::destroy_some(game_1_id) == leaderboard_8192::top_game_game_id(top_game2), 2);

            test_scenario::return_shared(leaderboard);
        };

        test_scenario::end(scenario);
    }

    fun assert_sort(top_games: vector<leaderboard_8192::TopGame8192>, expected: vector<vector<u64>>) {
        let sorted = leaderboard_8192::merge_sort_top_games(top_games);
        assert_sorted(sorted, expected);
    }

    fun assert_merge(left: vector<leaderboard_8192::TopGame8192>, right: vector<leaderboard_8192::TopGame8192>, expected: vector<vector<u64>>) {
        let merged = leaderboard_8192::merge(left, right);
        assert_sorted(merged, expected);
    }

    fun assert_sorted(sorted: vector<leaderboard_8192::TopGame8192>, expected: vector<vector<u64>>) {
        let sorted_length = vector::length(&sorted);
        let expected_length = vector::length(&expected);
        assert!(sorted_length == expected_length, sorted_length);

        while (!vector::is_empty(&sorted)) {
            let top_game = vector::pop_back(&mut sorted);
            let expected_values = vector::pop_back(&mut expected);
            let score = vector::pop_back(&mut expected_values);
            let tile = vector::pop_back(&mut expected_values);
            assert!(score == *leaderboard_8192::top_game_score(&top_game), score);
            assert!(tile == *leaderboard_8192::top_game_top_tile(&top_game), tile);
        }
    }

    #[test]
    fun test_sort() {
        let scenario = test_scenario::begin(PLAYER);

        let top_games = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
        ];
        assert_sort(top_games, vector[
            vector[2, 500], 
            vector[2, 200], 
        ]);

        let top_games = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 400),
        ];
        assert_sort(top_games, vector[
            vector[2, 500], 
            vector[2, 400], 
            vector[2, 200], 
        ]);

        let top_games = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 400),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 300),
        ];
        assert_sort(top_games, vector[
            vector[2, 500], 
            vector[2, 400], 
            vector[2, 300], 
            vector[2, 200], 
        ]);

        let top_games = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 1, 200),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 4, 300),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 400),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 3, 500),
        ];
        assert_sort(top_games, vector[
            vector[4, 300], 
            vector[3, 500], 
            vector[2, 400], 
            vector[1, 200], 
        ]);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_merge() {
        let scenario = test_scenario::begin(PLAYER);

        let left = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
        ];
        let right = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
        ];
        assert_merge(left, right, vector[
            vector[2, 500], 
            vector[2, 200], 
        ]);

        let left = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
        ];
        let right = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 400),
        ];
        assert_merge(left, right, vector[
            vector[2, 500], 
            vector[2, 400], 
            vector[2, 200], 
        ]);

        let left = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 500),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 200),
        ];
        let right = vector<leaderboard_8192::TopGame8192>[
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 400),
            leaderboard_8192::top_game(&mut scenario, PLAYER, 2, 300),
        ];
        assert_merge(left, right, vector[
            vector[2, 500], 
            vector[2, 400], 
            vector[2, 300], 
            vector[2, 200], 
        ]);

        test_scenario::end(scenario);
    }

}