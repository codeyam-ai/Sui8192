module ethos::game_8192 {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use std::string::{utf8};
    use sui::event;
    use sui::transfer::{transfer, public_transfer};
    use sui::table::{Self, Table};
    use ethos::game_board_8192::{Self, GameBoard8192};
    
    use sui::package;
    use sui::display;

    friend ethos::leaderboard_8192;

    #[test_only]
    friend ethos::game_8192_tests;

    const EInvalidPlayer: u64 = 0;

    /// One-Time-Witness for the module.
    struct GAME_8192 has drop {}

    struct Game8192 has key, store {
        id: UID,
        player: address,
        active_board: GameBoard8192,
        boards: Table<u64, GameBoard8192>,
        moves: Table<u64, GameMove8192>,
        leaderboard_games: Table<u64, LeaderboardGame8192>,
        score: u64,
        top_tile: u64,      
        game_over: bool
    }

    struct GameMove8192 has store {
        direction: u64,
        player: address
    }

    struct LeaderboardGame8192 has store, copy, drop {
        leaderboard_id: ID,
        top_tile: u64,
        score: u64,
        position: u64
    }

    struct NewGameEvent8192 has copy, drop {
        game_id: ID,
        player: address,
        score: u64
    }

    struct GameMoveEvent8192 has copy, drop {
        game_id: ID,
        direction: u64,
        move_count: u64
    }

    struct GameOverEvent8192 has copy, drop {
        game_id: ID,
        top_tile: u64,
        score: u64
    }

    fun init(otw: GAME_8192, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"Sui 8192"),
            utf8(b"https://sui8192.s3.amazonaws.com/{top_tile}.png"),
            utf8(b"Sui 8192 is a fun, 100% on-chain game. Combine the tiles to get a high score!"),
            utf8(b"https://ethoswallet.github.io/Sui8192/"),
            utf8(b"Ethos")
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        // Get a new `Display` object for the `Hero` type.
        let display = display::new_with_fields<Game8192>(
            &publisher, keys, values, ctx
        );

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);

        public_transfer(publisher, sender(ctx));
        public_transfer(display, sender(ctx));
    }

    // PUBLIC ENTRY FUNCTIONS //
    
    public entry fun create(ctx: &mut TxContext) {
        let player = tx_context::sender(ctx);
        let uid = object::new(ctx);
        let random = object::uid_to_bytes(&uid);
        let initial_game_board = game_board_8192::default(random);

        let score = *game_board_8192::score(&initial_game_board);
        let top_tile = *game_board_8192::top_tile(&initial_game_board);

        let game = Game8192 {
            id: uid,
            player,
            score,
            top_tile,
            active_board: initial_game_board,
            boards: table::new<u64, GameBoard8192>(ctx),
            moves: table::new<u64, GameMove8192>(ctx),
            game_over: false,
            leaderboard_games: table::new<u64, LeaderboardGame8192>(ctx),
        };

        table::add(&mut game.boards, 0, initial_game_board);

        event::emit(NewGameEvent8192 {
            game_id: object::uid_to_inner(&game.id),
            player,
            score
        });
        
        transfer(game, player);
    }

    public entry fun make_move(game: &mut Game8192, direction: u64, ctx: &mut TxContext)  {
        let new_board;
        {
            new_board = *&game.active_board;

            let uid = object::new(ctx);
            let random = object::uid_to_bytes(&uid);
            object::delete(uid);
            game_board_8192::move_direction(&mut new_board, direction, random);
        };

        let top_tile = *game_board_8192::top_tile(&new_board);
        let score = *game_board_8192::score(&new_board);
        let game_over = *game_board_8192::game_over(&new_board);

        event::emit(GameMoveEvent8192 {
            game_id: object::uid_to_inner(&game.id),
            direction: direction,
            move_count: table::length(&game.moves),
        });

        if (game_over) {            
            event::emit(GameOverEvent8192 {
                game_id: object::uid_to_inner(&game.id),
                top_tile,
                score
            });
        };

        let new_move = GameMove8192 {
            direction: direction,
            player: tx_context::sender(ctx)
        };

        let moveIndex = table::length(&game.moves);
        table::add(&mut game.moves, moveIndex, new_move);

        let boardIndex = table::length(&game.boards);
        table::add(&mut game.boards, boardIndex, new_board);

        game.active_board = new_board;
        game.score = score;
        game.top_tile = top_tile;
        game.game_over = game_over;
    }

    // FRIEND FUNCTIONS //

    public (friend) fun record_leaderboard_game(game: &mut Game8192, leaderboard_id: ID, position: u64) {
        let leaderboard_game = LeaderboardGame8192 {
            leaderboard_id,
            score: game.score,
            top_tile: game.top_tile,
            position
        };

        let index = table::length(&game.leaderboard_games);
        table::add(&mut game.leaderboard_games, index, leaderboard_game);
    }
 
    // PUBLIC ACCESSOR FUNCTIONS //

    public fun id(game: &Game8192): &UID {
        &game.id
    }

    public fun player(game: &Game8192): &address {
        &game.player
    }

    public fun active_board(game: &Game8192): &GameBoard8192 {
        &game.active_board
    }

    public fun top_tile(game: &Game8192): &u64 {
        let game_board = active_board(game);
        game_board_8192::top_tile(game_board)
    }

    public fun score(game: &Game8192): &u64 {
        let game_board = active_board(game);
        game_board_8192::score(game_board)
    }

    public fun move_count(game: &Game8192): u64 {
        table::length(&game.moves)
    }

    public fun move_at(game: &Game8192, index: u64): (&u64, &address) {
        let moveItem = table::borrow(&game.moves, index);
        (&moveItem.direction, &moveItem.player)
    }

    public fun board_at(game: &Game8192, index: u64): &GameBoard8192 {
        table::borrow(&game.boards, index)
    }

    public fun leaderboard_game_count(game: &Game8192): u64 {
        table::length(&game.leaderboard_games)
    }

    public fun leaderboard_game_at(game: &Game8192, index: u64): &LeaderboardGame8192 {
        table::borrow(&game.leaderboard_games, index)
    }

    public fun leaderboard_game_position(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.position
    }

    public fun leaderboard_game_top_tile(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.top_tile
    }

    public fun leaderboard_game_score(leaderboard_game: &LeaderboardGame8192): &u64 {
        &leaderboard_game.score
    }
}