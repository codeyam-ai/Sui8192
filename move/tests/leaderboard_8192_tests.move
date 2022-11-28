
#[test_only]
module ethos::leaderboard_8192_tests {
    use sui::test_scenario::{Self, Scenario};
    use ethos::game_board_8192::{left, up};
    use sui::object::{Self};
    use std::vector;
    use sui::table;

    use ethos::leaderboard_8192::{Self, Leaderboard8192};
    use ethos::game_8192::{Self, Game8192};
    
    const PLAYER: address = @0xCAFE;

    fun create_game(scenario: &mut Scenario) {
      game_8192::create(test_scenario::ctx(scenario))
    }

    #[test]
    fun test_submit_game() {
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

            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            let top_game = leaderboard_8192::top_game_at(&leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_submit_game__inserts_game_at_correct_location_in_top_list() {
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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            let scores = vector<u64>[4];
            let index = 0;
            while (index < 1) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            let scores = vector<u64>[24, 4];
            let index = 0;
            while (index < 2) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            let top_game = leaderboard_8192::top_game_at(&leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 0);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
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
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            let scores = vector<u64>[24, 8, 4];
            let index = 0;
            while (index < 3) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), *leaderboard_8192::top_game_score(top_game));
                index = index + 1;
            };
            
            let top_game = leaderboard_8192::top_game_at(&leaderboard, 1);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 1);

            test_scenario::return_shared(leaderboard);
            test_scenario::return_to_sender(&mut scenario, game)
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
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            let scores = vector<u64>[24, 12, 8, 4];
            let index = 0;
            while (index < 4) {
                let top_game = leaderboard_8192::top_game_at(&leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            let top_game = leaderboard_8192::top_game_at(&leaderboard, 1);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 0);

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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

        let game1Id: ID;
        let game2Id: ID;

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            game1Id = *object::uid_as_inner(game_8192::id(&game));
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };
        
        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1Id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1Id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1Id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            game2Id = *object::uid_as_inner(game_8192::id(&game));
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game2Id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared(leaderboard)
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let leaderboard = test_scenario::take_shared<Leaderboard8192>(&mut scenario);
            
            let game = test_scenario::take_from_sender_by_id<Game8192>(&mut scenario, game1Id);
            
            let ctx = test_scenario::ctx(&mut scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
    #[expected_failure(abort_code = 0)]
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
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));
          
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
            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));
            
            assert!(leaderboard_8192::min_tile(&leaderboard) == &1, (*leaderboard_8192::min_tile(&leaderboard) as u64));
            assert!(leaderboard_8192::min_score(&leaderboard) == &4, *leaderboard_8192::min_score(&leaderboard));
            
            assert!(game_8192::score(&game) == &16, *game_8192::score(&game));
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&mut scenario, game);
            test_scenario::return_shared<Leaderboard8192>(leaderboard)
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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
            leaderboard_8192::submit_game(&mut game, &mut leaderboard, test_scenario::ctx(&mut scenario));

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
}