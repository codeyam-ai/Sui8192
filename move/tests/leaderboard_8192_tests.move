
#[test_only]
module ethos::leaderboard_8192_tests {
    use sui::test_scenario::{Self, Scenario};
    use ethos::game_board_8192::{left, up};
    use sui::object::{Self};
    use std::vector;

    use ethos::leaderboard_8192::{Self, Leaderboard8192};
    use ethos::game_8192::{Self, Game8192};
    // use ethos::game_board_8192;
  
    const PLAYER: address = @0xCAFE;

    fun create_game(scenario: &mut Scenario) {
      game_8192::create(test_scenario::ctx(scenario))
    }

    // Game is currently created in the game itself
    // #[test]
    // fun test_create_game() {
    //     let scenario = &mut test_scenario::begin(&PLAYER);
    //     init_leaderboard(scenario);

    //     test_scenario::next_tx(scenario, &PLAYER);
    //     {
    //         let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
    //         let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

    //         assert!(game_count(leaderboard) == &0, *game_count(leaderboard));

    //         create_game(leaderboard, test_scenario::ctx(scenario));

    //         assert!(game_count(leaderboard) == &1, *game_count(leaderboard));
            
    //         test_scenario::return_shared(scenario, leaderboard_wrapper);
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER);
    //     {
    //         let game = test_scenario::take_owned<Game8192>(scenario);
    //         assert!(game_8192::player(&game) == &PLAYER, 0);
    //         test_scenario::return_owned(scenario, game)
    //     }
    // }

    #[test]
    fun test_submit_game() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::init_leaderboard(scenario); 

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_owned<Game8192>(scenario);
            
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));

            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            let top_game = leaderboard_8192::top_game_at(leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 1);

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game)
        } 
    }

    #[test]
    fun test_submit_game__inserts_game_at_correct_location_in_top_list() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::init_leaderboard(scenario); 

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            let scores = vector<u64>[4];
            let index = 0;
            while (index < 1) {
                let top_game = leaderboard_8192::top_game_at(leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            let scores = vector<u64>[24, 4];
            let index = 0;
            while (index < 2) {
                let top_game = leaderboard_8192::top_game_at(leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            let top_game = leaderboard_8192::top_game_at(leaderboard, 0);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 0);

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            let scores = vector<u64>[24, 12, 4];
            let index = 0;
            while (index < 3) {
                let top_game = leaderboard_8192::top_game_at(leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };
            
            let top_game = leaderboard_8192::top_game_at(leaderboard, 1);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 1);

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            let scores = vector<u64>[24, 20, 12, 4];
            let index = 0;
            while (index < 4) {
                let top_game = leaderboard_8192::top_game_at(leaderboard, index);
                assert!(leaderboard_8192::top_game_score(top_game) == vector::borrow(&scores, index), index);
                index = index + 1;
            };

            let top_game = leaderboard_8192::top_game_at(leaderboard, 1);
            assert!(leaderboard_8192::top_game_game_id(top_game) == &object::uid_to_inner(game_8192::id(&game)), 0);

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game)
        };
    }

    #[test]
    fun test_submit_game__only_one_entry_per_game() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::init_leaderboard(scenario); 

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let ctx = test_scenario::ctx(scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };
        
        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let ctx = test_scenario::ctx(scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let ctx = test_scenario::ctx(scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let ctx = test_scenario::ctx(scenario);
            game_8192::make_move(&mut game, left(), ctx);
            game_8192::make_move(&mut game, up(), ctx);
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
        let leaderboard_game_count = vector::length(leaderboard_8192::top_games(leaderboard));
            assert!(leaderboard_game_count == 1, leaderboard_game_count);
          
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_submit_game__aborts_if_not_a_leader() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::blank_leaderboard(scenario, 2, 0, 0);

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared(scenario, leaderboard_wrapper)
        };
    }

    #[test]
    fun test_submit_game__stores_min_tile_and_min_score() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::blank_leaderboard(scenario, 2, 0, 0);
        
        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboardWrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboardWrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));
          
            assert!(leaderboard_8192::min_tile(leaderboard) == &0, (*leaderboard_8192::min_tile(leaderboard) as u64));
            assert!(leaderboard_8192::min_score(leaderboard) == &0, *leaderboard_8192::min_score(leaderboard));

            assert!(game_8192::score(&game) == &4, *game_8192::score(&game));

            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared<Leaderboard8192>(scenario, leaderboardWrapper)
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboardWrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboardWrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));
            
            assert!(leaderboard_8192::min_tile(leaderboard) == &1, (*leaderboard_8192::min_tile(leaderboard) as u64));
            assert!(leaderboard_8192::min_score(leaderboard) == &4, *leaderboard_8192::min_score(leaderboard));
            
            assert!(game_8192::score(&game) == &8, *game_8192::score(&game));
            
            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared<Leaderboard8192>(scenario, leaderboardWrapper)
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_submit_game__aborts_if_not_above_min_tile() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::blank_leaderboard(scenario, 2, 3, 30);

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboardWrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboardWrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));
            
            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared<Leaderboard8192>(scenario, leaderboardWrapper)
        };
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_submit_game__aborts_if_not_above_min_score() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::blank_leaderboard(scenario, 2, 0, 30);

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboardWrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboardWrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));
            
            test_scenario::return_owned(scenario, game);
            test_scenario::return_shared<Leaderboard8192>(scenario, leaderboardWrapper)
        };
    }

    // #[test]
    // fun test_set_name_on_address() {
    //     let scenario = &mut test_scenario::begin(&PLAYER);
    //     leaderboard_8192::init_leaderboard(scenario); 

    //     test_scenario::next_tx(scenario, &PLAYER);
    //     {
    //         create_game(scenario);
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER);
    //     {
    //         let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
    //         let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);
            
    //         let game = test_scenario::take_owned<Game8192>(scenario);
    //         leaderboard_8192::submit_game(&game, leaderboard);

    //         test_scenario::return_shared(scenario, leaderboard_wrapper);
    //         test_scenario::return_owned(scenario, game)
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER);
    //     {
    //         let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
    //         let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

    //         let name = b"irrationaljared";
    //         leaderboard_8192::set_name(leaderboard, name, test_scenario::ctx(scenario));

    //         test_scenario::return_shared(scenario, leaderboard_wrapper);
    //     }
    // }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_set_name_on_address__not_if_you_are_not_a_leader() {
      let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::init_leaderboard(scenario); 

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let name = b"irrationaljared";
            leaderboard_8192::set_name(leaderboard, name, test_scenario::ctx(scenario));

            test_scenario::return_shared(scenario, leaderboard_wrapper);
        }
    }

    #[test]
    fun test_records_leaderboard_game_on_game() {
        let scenario = &mut test_scenario::begin(&PLAYER);
        leaderboard_8192::init_leaderboard(scenario); 

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &0, *position);

            test_scenario::return_owned(scenario, game);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &1, *position);

            test_scenario::return_owned(scenario, game);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            create_game(scenario);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let leaderboard_wrapper = test_scenario::take_shared<Leaderboard8192>(scenario);
            let leaderboard = test_scenario::borrow_mut(&mut leaderboard_wrapper);

            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, left(), test_scenario::ctx(scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(scenario));
            leaderboard_8192::submit_game(&mut game, leaderboard, test_scenario::ctx(scenario));

            test_scenario::return_shared(scenario, leaderboard_wrapper);
            test_scenario::return_owned(scenario, game);
        };

        test_scenario::next_tx(scenario, &PLAYER);
        {
            let game = test_scenario::take_last_created_owned<Game8192>(scenario);
            
            let leaderboard_games_count = game_8192::leaderboard_game_count(&game);
            assert!(leaderboard_games_count == 1, leaderboard_games_count);

            let leaderboard_game = game_8192::leaderboard_game_at(&game, 0);
            let position = game_8192::leaderboard_game_position(leaderboard_game);
            assert!(position == &0, *position);

            test_scenario::return_owned(scenario, game);
        };
    }
}