
#[test_only]
module ethos::game_8192_tests {
    use sui::url::{Self};
    use ethos::game_board_8192::{Self};
    use sui::test_scenario::{Self, Scenario};
    use std::option;
    use std::ascii;

    use ethos::game_8192::{Self, Game8192};
    use ethos::game_board_8192::{left, up};

    const PLAYER: address = @0xCAFE;
    const OTHER: address = @0xA1C05;

    fun create_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        game_8192::create(ctx);
    }

    fun test_game_create() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            assert!(game_8192::player(&game) == &PLAYER, 0);
            assert!(game_8192::move_count(&game) == 0, 1);

            let game_board = game_8192::board_at(&game, 0);
            let empty_space_count = game_board_8192::empty_space_count(game_board);
            assert!(empty_space_count == 14, empty_space_count);

            test_scenario::return_to_sender(&mut scenario, game)
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_make_move() {
        let scenario = test_scenario::begin(PLAYER);
        {
            create_game(&mut scenario);
        };

        test_scenario::next_tx(&mut scenario, PLAYER);
        {
            let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
            
            let board = game_8192::board_at(&game, 0);
            let space_value = option::borrow(game_board_8192::space_at(board, 0, 1));
            assert!(space_value == &(0 as u64), (*space_value as u64));
            assert!(option::is_none(game_board_8192::space_at(board, 0, 0)), 1);

            game_8192::make_move(&mut game, left(), test_scenario::ctx(&mut scenario));
            game_8192::make_move(&mut game, up(), test_scenario::ctx(&mut scenario));
            
            assert!(game_8192::move_count(&game) == 2, game_8192::move_count(&game));
            let (moveDirection0, _) = game_8192::move_at(&game, 0);
            assert!(moveDirection0 == &left(), 1);
            
            let (moveDirection1, _) = game_8192::move_at(&game, 1);
            assert!(moveDirection1 == &up(), 2);
            assert!(game_8192::score(&game) == &4, *game_8192::score(&game));
            assert!(game_8192::top_tile(&game) == &1, (*game_8192::top_tile(&game) as u64));
            assert!(game_8192::url(&game) == &game_8192::image_url_for_tile(1), 3);

            board = game_8192::board_at(&game, 0);

            // Original board is unchanged
            let space_value = option::borrow(game_board_8192::space_at(board, 0, 1));
            assert!(space_value == &(0 as u64), (*space_value as u64));
            assert!(option::is_none(game_board_8192::space_at(board, 0, 0)), 1);

            board = game_8192::board_at(&game, 1);
            let space_value = option::borrow(game_board_8192::space_at(board, 0, 0));
            assert!(space_value == &(0 as u64), (*space_value as u64));

            assert!(option::is_none(game_board_8192::space_at(board, 0, 1)), 1);
            
            test_scenario::return_to_sender(&mut scenario, game);
        };

        test_scenario::end(scenario);
    }

    // #[test]
    // #[expected_failure(abort_code = 0)]
    // fun test_only_player_can_make_move() {        
    //     let scenario = test_scenario::begin(PLAYER);
    //     {
    //         create_game(&mut scenario);
    //     };

    //     test_scenario::next_tx(&mut scenario, PLAYER);
    //     {
    //         let game = test_scenario::take_from_sender<Game8192>(&mut scenario);
        
    //         test_scenario::next_tx(&mut scenario, &OTHER);
    //         let direction = left();
    //         game_8192::make_move(&mut game, direction, test_scenario::ctx(&mut scenario));  

    //         test_scenario::next_tx(&mut scenario, PLAYER);
    //         test_scenario::return_to_sender(&mut scenario, game)
    //     }  
    // } 

    #[test_only] 
    fun tile_image_to_bytes(index: u64): vector<u8> {
        let image_url = game_8192::image_url_for_tile(index);
        let image_string = url::inner_url(&image_url);
        ascii::into_bytes(image_string)
    }

    #[test]
    fun test_image_url_for_tile() {
        assert!(tile_image_to_bytes(1) == b"https://arweave.net/QAGpz9cEBMyP_YuTJfafAwNSTVsNFUp_p0_sAVHfjnE", 1);
        assert!(tile_image_to_bytes(7) == b"https://arweave.net/VXSJTlTh6mvV9DVKlrxn52BvrABX8baXI1c9EO6-BI8", 7);
        assert!(tile_image_to_bytes(12) == b"https://arweave.net/WeTxyQ8q7bzV883_pqu42EC7cb5Shg-glZaq6bBUUBE", 12);

        let default = b"https://arweave.net/eQkMD04T4tjZZZpXPa1x5_KPUK_Pk1FA_cSOlJCir98";
        assert!(tile_image_to_bytes(0) == default, 0);
        assert!(tile_image_to_bytes(99) == default, 99);
    }
}