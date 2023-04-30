
#[test_only]
module ethos::leaderboard_8192_tests {
    use sui::test_scenario::{Self, Scenario};
    use ethos::game_board_8192::{left, up, right, down};
    use std::vector;
    use sui::table;

    use ethos::leaderboard_8192::{Self, Leaderboard8192};
    use ethos::game_8192::{Self, Game8192};
    
    const PLAYER: address = @0xCAFE;

    fun create_game(scenario: &mut Scenario) {
        game_8192::create(test_scenario::ctx(scenario))
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
                game_8192::make_move(&mut game, left(), ctx);
                game_8192::make_move(&mut game, up(), ctx);
                game_8192::make_move(&mut game, right(), ctx);
                game_8192::make_move(&mut game, down(), ctx);
            };
            sui::test_utils::print(b"");
            sui::test_utils::print(b"SUBMIT");
            std::debug::print(game_8192::score(&game));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_to_sender(scenario, game);
            test_scenario::return_shared(leaderboard);
        };
    }

    fun check_scores(scenario: &mut Scenario, scores: vector<u64>) {
        test_scenario::next_tx(scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(scenario);
            let index = 0;
            while (index < vector::length(&scores)) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };
            let top_games_length = table::length(leaderboard_8192::top_games(&leaderboard));
            assert!(top_games_length == vector::length(&scores), top_games_length);
            test_scenario::return_shared(leaderboard);
        };
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

        achieve_score(&mut scenario, 64);
        check_scores(&mut scenario, vector<u64>[192, 108, 88, 64, 36]);

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
            
            let leaderboard_game_count = table::length(leaderboard_8192::top_games(&leaderboard));
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
            
            let leaderboard_game_count = table::length(leaderboard_8192::top_games(&leaderboard));
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
            
            let leaderboard_game_count = table::length(leaderboard_8192::top_games(&leaderboard));
            assert!(leaderboard_game_count == 2, leaderboard_game_count);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = leaderboard_8192::ENotALeader)]
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
            let leaderboard_game_count = table::length(top_games);
            assert!(leaderboard_game_count == 2, leaderboard_game_count);
            
            let top_game0 = table::borrow(top_games, 0);
            assert!(game3_id == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = table::borrow(top_games, 1);
            assert!(game2_id == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_records_leaderboard_game_on_game() {
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
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &0, *position);

            test_scenario::return_to_sender(&mut scenario, game);
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

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &1, *position);

            test_scenario::return_to_sender(&mut scenario, game);
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
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &0, *position);

            test_scenario::return_to_sender(&mut scenario, game);
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
            let leaderboard_game_count = table::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = table::borrow(top_games, 0);
            assert!(game_8192::id(&game4) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = table::borrow(top_games, 1);
            assert!(game_8192::id(&game3) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = table::borrow(top_games, 2);
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
            let leaderboard_game_count = table::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = table::borrow(top_games, 0);
            assert!(game_8192::id(&game3) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = table::borrow(top_games, 1);
            assert!(game_8192::id(&game1) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = table::borrow(top_games, 2);
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
            let leaderboard_game_count = table::length(top_games);
            assert!(leaderboard_game_count == 3, leaderboard_game_count);
            
            let top_game0 = table::borrow(top_games, 0);
            assert!(game_8192::id(&game1) == leaderboard_8192::top_game_game_id(top_game0), 0);

            let top_game1 = table::borrow(top_games, 1);
            assert!(game_8192::id(&game4) == leaderboard_8192::top_game_game_id(top_game1), 1);
          
            let top_game2 = table::borrow(top_games, 2);
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

        achieve_score(&mut scenario, 616);
        check_scores(&mut scenario, vector<u64>[616, 104, 88]);

        achieve_score(&mut scenario, 432);
        check_scores(&mut scenario, vector<u64>[616, 432, 104, 88]);

        achieve_score(&mut scenario, 72);
        check_scores(&mut scenario, vector<u64>[616, 432, 104, 88, 72]);

        achieve_score(&mut scenario, 568);
        check_scores(&mut scenario, vector<u64>[616, 568, 432, 104, 88, 72]);

        achieve_score(&mut scenario, 320);
        check_scores(&mut scenario, vector<u64>[616, 568, 432, 320, 104, 88, 72]);

        achieve_score(&mut scenario, 200);
        check_scores(&mut scenario, vector<u64>[616, 568, 432, 320, 200, 104, 88, 72]);

        achieve_score(&mut scenario, 8);
        check_scores(&mut scenario, vector<u64>[616, 568, 432, 320, 200, 104, 88, 72, 8]);

        achieve_score(&mut scenario, 16);
        check_scores(&mut scenario, vector<u64>[616, 568, 432, 320, 200, 104, 88, 72, 16]);

        test_scenario::end(scenario);
    }
}