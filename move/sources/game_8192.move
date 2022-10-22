module ethos::game_8192 {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::event;
    use sui::transfer;
    use std::vector;
    use std::option::Option;
    use ethos::game_board_8192::{Self, GameBoard8192};
    
    friend ethos::leaderboard_8192;

    #[test_only]
    friend ethos::game_8192_tests;

    const EInvalidPlayer: u64 = 0;

    struct Game8192 has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
        player: address,
        score: u64,
        top_tile: u8,      
        moves: vector<GameMove8192>,
        boards: vector<GameBoard8192>,
        leaderboard_games: vector<LeaderboardGame8192>
    }

    struct GameMove8192 has store {
        direction: u8,
        player: address,
        epoch: u64
    }

    struct LeaderboardGame8192 has store, copy, drop {
        leaderboard_id: ID,
        top_tile: u8,
        score: u64,
        position: u64,
        epoch: u64
    }

    struct NewGameEvent8192 has copy, drop {
        game_id: ID,
        player: address,
        board_spaces: vector<vector<Option<u8>>>,
        score: u64
    }

    struct GameMoveEvent8192 has copy, drop {
        game_id: ID,
        direction: u8,
        move_count: u64,
        board_spaces: vector<vector<Option<u8>>>,
        top_tile: u8,
        url: Url,
        score: u64,
        last_tile: vector<u64>,
        epoch: u64
    }

    struct GameTopTileEvent8192 has copy, drop {
        game_id: ID,
        top_tile: u8,
        url: Url,
        epoch: u64
    }

    struct GameOverEvent8192 has copy, drop {
        game_id: ID,
        top_tile: u8,
        score: u64,
        url: Url
    }

    // PUBLIC ENTRY FUNCTIONS //
    
    public entry fun create(ctx: &mut TxContext) {
        let player = tx_context::sender(ctx);
        let uid = object::new(ctx);
        let random = object::uid_to_bytes(&uid);
        let initial_game_board = game_board_8192::default(random);
        let board_spaces = *game_board_8192::spaces(&initial_game_board);

        let score = *game_board_8192::score(&initial_game_board);
        let top_tile = *game_board_8192::top_tile(&initial_game_board);

        let game = Game8192 {
            id: uid,
            name: string::utf8(b"Sui 8192"),
            description: string::utf8(b"Sui 8192 is a fun, 100% on-chain game. Combine the tiles to get a high score!"),
            // leaderboard_id,
            player,
            score,
            top_tile,
            moves: vector[],
            boards: vector[initial_game_board],
            url: image_url_for_tile(top_tile),
            leaderboard_games: vector[]
        };

        event::emit(NewGameEvent8192 {
            game_id: object::uid_to_inner(&game.id),
            // leaderboard_id,
            player,
            board_spaces,
            score
        });
        
        transfer::transfer(game, player);
    }

    public entry fun make_move(game: &mut Game8192, direction: u8, ctx: &mut TxContext)  {
        // assert!(player(game) == &tx_context::sender(ctx), EInvalidPlayer);
        
        let new_move = GameMove8192 {
          direction: direction,
          player: tx_context::sender(ctx),
          epoch: tx_context::epoch(ctx)
        };

        let last_board_index = vector::length(&game.boards) - 1;
        let current_board = vector::borrow_mut(&mut game.boards, last_board_index);
        let new_board = *current_board;

        let uid = object::new(ctx);
        let random = object::uid_to_bytes(&uid);
        object::delete(uid);
        game_board_8192::move_direction(&mut new_board, direction, random);

        let board_spaces = *game_board_8192::spaces(&new_board);
        let last_tile = *game_board_8192::last_tile(&new_board);
        let top_tile = *game_board_8192::top_tile(&new_board);
        let url = image_url_for_tile(top_tile);
        let score = *game_board_8192::score(&new_board);

        event::emit(GameMoveEvent8192 {
            game_id: object::uid_to_inner(&game.id),
            direction: direction,
            move_count: vector::length(&game.moves),
            board_spaces,
            top_tile,
            score,
            last_tile,
            epoch: tx_context::epoch(ctx),
            url
        });

        if (game_board_8192::top_tile(&new_board) != game_board_8192::top_tile(current_board)) {
            event::emit(GameTopTileEvent8192 {
                game_id: object::uid_to_inner(&game.id),
                top_tile: top_tile,
                epoch: tx_context::epoch(ctx),
                url
            });
        };

        if (*game_board_8192::game_over(&new_board)) {
            event::emit(GameOverEvent8192 {
                game_id: object::uid_to_inner(&game.id),
                top_tile,
                score,
                url
            });
        };

        vector::push_back(&mut game.moves, new_move);
        vector::push_back(&mut game.boards, new_board);
        game.score = score;
        game.top_tile = top_tile;
        game.url = url;
    }

    // FRIEND FUNCTIONS //

    public (friend) fun record_leaderboard_game(game: &mut Game8192, leaderboard_id: ID, position: u64, epoch: u64) {
        let leaderboard_game = LeaderboardGame8192 {
            leaderboard_id,
            score: game.score,
            top_tile: game.top_tile,
            position,
            epoch
        };

        vector::push_back(&mut game.leaderboard_games, leaderboard_game);
    }
 
    public (friend) fun image_url_for_tile(tile: u8): Url {
        let urlString;
        if (tile == 1) { urlString = b"https://arweave.net/QAGpz9cEBMyP_YuTJfafAwNSTVsNFUp_p0_sAVHfjnE"; }
        else if (tile == 2) { urlString = b"https://arweave.net/ZB4YHmbMQU3cEchiFfzBVfBgxy4TwOZJXCbSmJOHz2U"; }
        else if (tile == 3) { urlString = b"https://arweave.net/k_1VA41fq5QshFXtqNZS5-BnLyKdZJjFn3ieDVdCu2c"; }
        else if (tile == 4) { urlString = b"https://arweave.net/RymnU03PCQDdo8IKdO1HX23u_Wa3puaIiNQV2apSbuE"; }
        else if (tile == 5) { urlString = b"https://arweave.net/75BRb8nsaD1t3Bkj_oyN1L5VLlB5dLGb_VHjW2c1pcs"; }
        else if (tile == 6) { urlString = b"https://arweave.net/gfUCcNVorqKivGCYMoHaWijk4VTgwc1nraON-puXkb0"; }
        else if (tile == 7) { urlString = b"https://arweave.net/VXSJTlTh6mvV9DVKlrxn52BvrABX8baXI1c9EO6-BI8"; }
        else if (tile == 8) { urlString = b"https://arweave.net/rtPGI_DIxe4vkTDV8W7LLEwBDyTvBz0rgn4SZGndj-k"; }
        else if (tile == 9) { urlString = b"https://arweave.net/Cjetswxok4Z6-CQFwwtrzRBFjGxVXhk87BVtbRkgY8M"; }
        else if (tile == 10) { urlString = b"https://arweave.net/B5TWHnZpE-NfvgDO0yCdXbPFbadRRDtXu6_KE3qGffI"; }
        else if (tile == 11) { urlString = b"https://arweave.net/vNuKvQ9WB9dXLue_X9fGqfUlBtjuzUXcB8HDaaYFlas"; }
        else if (tile == 12) { urlString = b"https://arweave.net/WeTxyQ8q7bzV883_pqu42EC7cb5Shg-glZaq6bBUUBE"; }
        else { urlString = b"https://arweave.net/eQkMD04T4tjZZZpXPa1x5_KPUK_Pk1FA_cSOlJCir98"; };

        return url::new_unsafe_from_bytes(urlString)
    }

    // PUBLIC ACCESSOR FUNCTIONS //

    public fun id(game: &Game8192): &UID {
      &game.id
    }

    public fun player(game: &Game8192): &address {
        &game.player
    }

    public fun moves(game: &Game8192): &vector<GameMove8192> {
        &game.moves
    }

    public fun top_tile(game: &Game8192): &u8 {
        let game_board = vector::borrow(&game.boards, vector::length(&game.boards) - 1);
        game_board_8192::top_tile(game_board)
    }

    public fun score(game: &Game8192): &u64 {
        let game_board = vector::borrow(&game.boards, vector::length(&game.boards) - 1);
        game_board_8192::score(game_board)
    }

    public fun url(game: &Game8192): &Url {
        &game.url
    }

    public fun move_count(game: &Game8192): u64 {
        vector::length(&game.moves)
    }

    public fun move_at(game: &Game8192, index: u64): (&u8, &address) {
        let moveItem = vector::borrow(&game.moves, index);
        (&moveItem.direction, &moveItem.player)
    }

    public fun board_at(game: &Game8192, index: u64): &GameBoard8192 {
        vector::borrow(&game.boards, index)
    }

    public fun leaderboard_game_count(game: &Game8192): u64 {
        vector::length(&game.leaderboard_games)
    }

    public fun leaderboard_game_at(game: &Game8192, index: u64): &LeaderboardGame8192 {
        vector::borrow(&game.leaderboard_games, index)
    }

    public fun leaderboard_game_position(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.position
    }

    public fun leaderboard_game_top_tile(leaderboard_game: &LeaderboardGame8192): &u8 {
        &leaderboard_game.top_tile
    }

    public fun leaderboard_game_score(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.score
    }

    public fun leaderboard_game_epoch(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.epoch
    }
}