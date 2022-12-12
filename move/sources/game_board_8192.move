module ethos::game_board_8192 {
    use std::option::{Self, Option};
    use std::vector;
    use sui::vec_map::{Self, VecMap};
    
    friend ethos::game_8192;
    #[test_only]
    friend ethos::game_8192_tests;
    
    #[test_only]
    friend ethos::leaderboard_8192_tests;

    const LEFT: u64 = 0;
    const RIGHT: u64 = 1;
    const UP: u64 = 2;
    const DOWN: u64 = 3;

    const TILE2: u64 = 0;
    const TILE4: u64 = 1;
    const TILE8: u64 = 2;
    const TILE16: u64 = 3;
    const TILE32: u64 = 4;
    const TILE64: u64 = 5;
    const TILE128: u64 = 6;
    const TILE256: u64 = 7;
    const TILE512: u64 = 8;
    const TILE1024: u64 = 9;
    const TILE2048: u64 = 10;
    const TILE4096: u64 = 11;
    const TILE8192: u64 = 12;

    const ESpaceEmpty: u64 = 0;
    const ESpaceNotEmpty: u64 = 1;
    const ENoEmptySpaces: u64 = 2;
    const EGameOver: u64 = 3;

    struct GameBoard8192 has store, copy, drop{
        spaces: vector<vector<Option<u64>>>,
        score: u64,
        last_tile: vector<u64>,
        top_tile: u64,
        game_over: bool
    }

    struct SpacePosition has copy, drop {
        row: u64,
        column: u64
    }

    public fun left(): u64 { LEFT }
    public fun right(): u64 { RIGHT }
    public fun up(): u64 { UP }
    public fun down(): u64 { DOWN }

    // PUBLIC FRIEND FUNCTIONS //

    public(friend) fun default(random: vector<u8>): GameBoard8192 {
        let spaces = vector[
            vector[option::none(), option::none(), option::none(), option::none()],
            vector[option::none(), option::none(), option::none(), option::none()],
            vector[option::none(), option::none(), option::none(), option::none()],
            vector[option::none(), option::none(), option::none(), option::none()]
        ];

        let row1 = ((*vector::borrow(&random, 1) % 2) as u64);
        let column1 = ((*vector::borrow(&random, 2) % 4) as u64);
        fill_in_space_at(&mut spaces, row1, column1, TILE2);

        let row2 = (((*vector::borrow(&random, 3) % 2) + 2) as u64);
        let column2 = ((*vector::borrow(&random, 4) % 4) as u64);
        fill_in_space_at(&mut spaces, row2, column2, TILE2);

        let game_board = GameBoard8192 { 
          spaces, 
          score: 0,
          last_tile: vector[3, 1, (TILE2 as u64)],
          top_tile: TILE2,
          game_over: false
        };

        game_board 
    }

    public(friend) fun move_direction(game_board: &mut GameBoard8192, direction: u64, random: vector<u8>) {
        assert!(!game_board.game_over, 3);
        
        let existing_spaces = *&game_board.spaces;

        let top_tile = move_spaces(&mut game_board.spaces, direction);

        if (existing_spaces == game_board.spaces) {
            if (!move_possible(game_board)) {
                game_board.game_over = true;
            };
            
            return
        };
        
        let add = score_add(&existing_spaces, &game_board.spaces);
        game_board.score = game_board.score + add;
        
        let new_tile = add_new_tile(game_board, random);

        if (new_tile > top_tile) {
            top_tile = new_tile;
        };

        game_board.top_tile = top_tile; 

        if (!move_possible(game_board)) {
            game_board.game_over = true;
        };
    }

    public(friend) fun spaces(game_board: &GameBoard8192): &vector<vector<Option<u64>>> { 
        &game_board.spaces 
    }

    public(friend) fun score(game_board: &GameBoard8192): &u64 { 
        &game_board.score 
    }

    public(friend) fun last_tile(game_board: &GameBoard8192): &vector<u64> {
        &game_board.last_tile
    }

    public(friend) fun top_tile(game_board: &GameBoard8192): &u64 {
        &game_board.top_tile
    }

    public(friend) fun game_over(game_board: &GameBoard8192): &bool {
        &game_board.game_over
    }

    public(friend) fun row_count(game_board: &GameBoard8192): u64 {
        vector::length(&game_board.spaces)
    }

    public(friend) fun row_at(game_board: &GameBoard8192, index: u64): &vector<Option<u64>> {
        vector::borrow(&game_board.spaces, index)
    }

    public(friend) fun row_at_mut(game_board: &mut GameBoard8192, index: u64): &mut vector<Option<u64>> {
        vector::borrow_mut(&mut game_board.spaces, index)
    }

    public(friend) fun column_count(game_board: &GameBoard8192): u64 {
        let row = vector::borrow(&game_board.spaces, 0);
        vector::length(row)
    }

    public(friend) fun space_at(game_board: &GameBoard8192, row_index: u64, column_index: u64): &Option<u64> {
        spaces_at(&game_board.spaces, row_index, column_index)
    }

    public(friend) fun space_at_mut(game_board: &mut GameBoard8192, row_index: u64, column_index: u64): &mut Option<u64> {
        spaces_at_mut(&mut game_board.spaces, row_index, column_index)
    }

    public(friend) fun empty_space_positions(game_board: &GameBoard8192): vector<SpacePosition> {
        let empty_spaces = vector<SpacePosition>[];

        let rows = row_count(game_board);
        let columns = column_count(game_board);
        
        let row = 0;
        while (row < rows) {
          let column = 0;
          while (column < columns) {
            let space = space_at(game_board, row, column);
            if (option::is_none(space)) {
              vector::push_back(&mut empty_spaces, SpacePosition { row, column })
            };
            column = column + 1;
          };
          row = row + 1;
        };

        empty_spaces
    }

    public(friend) fun empty_space_count(game_board: &GameBoard8192): u64 {
        vector::length(&empty_space_positions(game_board))
    }


    // PRIVATE FUNCTIONS //

    fun remove_value_or_combined(tiles: &mut vector<u64>, value: u64, start: bool): u64 {
        let score_value = 0;
        let (contains, index) = vector::index_of(tiles, &value);
        if (contains) {
            vector::remove(tiles, index);
        } else {
            remove_value_or_combined(tiles, value - 1, false);
            remove_value_or_combined(tiles, value - 1, false);

            if (start) {
                score_value = 2;
                while (value > 0) {
                    score_value = score_value * 2;
                    value = value - 1;
                };       
            }
        };
        score_value
    }

    fun score_add(old_spaces: &vector<vector<Option<u64>>>, new_spaces: &vector<vector<Option<u64>>>): u64 {
        let old_tiles = vector[];
        
        let row_index = 0;
        while (row_index < vector::length(old_spaces)) {
            let old_row = vector::borrow(old_spaces, row_index);
            
            let column_index = 0;
            while (column_index < vector::length(old_row)) {
                let old_option = vector::borrow(old_row, column_index);
            
                if (option::is_some(old_option)) {
                    vector::push_back(&mut old_tiles, *option::borrow(old_option));
                };

                column_index = column_index + 1;
            };
            row_index = row_index + 1;
        };

        let total_score_value: u64 = 0;
        let row_index = 0;
        while (row_index < vector::length(new_spaces)) {
            let new_row = vector::borrow(new_spaces, row_index);
            
            let column_index = 0;
            while (column_index < vector::length(new_row)) {
                let new_option = vector::borrow(new_row, column_index);
                
                if (option::is_some(new_option)) {
                    let value = *option::borrow(new_option);
                    let score = remove_value_or_combined(
                        &mut old_tiles, 
                        value, 
                        true
                    );
                    total_score_value = total_score_value + score;
                };
                column_index = column_index + 1;
            };
            row_index = row_index + 1;
        };
        
        total_score_value
    }

    fun move_possible(game_board: &GameBoard8192): bool {
        if (empty_space_available(game_board)) {
          return true
        };

        let rows = row_count(game_board);
        let columns = column_count(game_board);
        
        let row = 0;
        while (row < rows) {
          let column = 0;
          while (column < columns) {
            let space = space_at(game_board, row, column);
            if (option::is_none(space)) {
              return true
            };

            let value = option::borrow(space);
            if (column < columns - 1) {
              let right_space = space_at(game_board, row, column + 1);
              if (option::is_some(right_space) && option::contains(right_space, value)) {
                return true
              }
            };

            if (row < rows - 1) {
              let down_space = space_at(game_board, row + 1, column);
              if (option::is_some(down_space) && option::contains(down_space, value)) {
                return true
              }
            };
            
            column = column + 1;
          };
          row = row + 1;
        };

        return false
    }

    fun add_new_tile(game_board: &mut GameBoard8192, random: vector<u8>): u64 {
        let empty_spaces = empty_space_positions(game_board);
        let empty_spaces_count = vector::length(&empty_spaces);
        assert!(empty_spaces_count > 0, ENoEmptySpaces);

        let tile = TILE2;
        let top = *top_tile(game_board);
        if (top >= TILE8192 && *vector::borrow(&random, 0) % 6 == 0) {
            tile = TILE32; 
        } else if (top >= TILE4096 && *vector::borrow(&random, 0) % 5 == 0) {
            tile = TILE16; 
        } else if (top >= TILE2048 && *vector::borrow(&random, 0) % 4 == 0) {
            tile = TILE8; 
        } else if (*vector::borrow(&random, 0) % 4 == 0) {
            tile = TILE4; 
        };

        let random_empty_position = (*vector::borrow(&random, 1) as u64) % empty_spaces_count;
        let empty_space = vector::borrow(&empty_spaces, random_empty_position);

        fill_in_space_at(&mut game_board.spaces, empty_space.row, empty_space.column, tile);
        game_board.last_tile = vector[empty_space.row, empty_space.column, (tile as u64)];

        tile
    }

    fun spaces_at(spaces: &vector<vector<Option<u64>>>, row_index: u64, column_index: u64): &Option<u64> {
        let row = vector::borrow(spaces, row_index);
        vector::borrow(row, column_index)
    }

    fun spaces_at_mut(spaces: &mut vector<vector<Option<u64>>>, row_index: u64, column_index: u64): &mut Option<u64> {
        let row = vector::borrow_mut(spaces, row_index);
        vector::borrow_mut(row, column_index)
    }

    fun empty_space_available(game_board: &GameBoard8192): bool {
        let rows = row_count(game_board);
        let columns = column_count(game_board);
        
        let row = 0;
        while (row < rows) {
          let column = 0;
          while (column < columns) {
            let space = space_at(game_board, row, column);
            if (option::is_none(space)) {
              return true
            };
            column = column + 1;
          };
          row = row + 1;
        };

        return false
    }

    fun fill_in_space_at(spaces: &mut vector<vector<Option<u64>>>, row_index: u64, column_index: u64, value: u64) {
        let space = spaces_at_mut(spaces, row_index, column_index);
        option::fill(space, value);
    }

    fun increment_space_at(spaces: &mut vector<vector<Option<u64>>>, row_index: u64, column_index: u64): u64 {
        let space = spaces_at_mut(spaces, row_index, column_index);
        assert!(option::is_some(space), ESpaceEmpty);
        let current = option::extract(space);
        let new_value = current + 1;
        option::fill(space, new_value);
        new_value
    }

    fun clear_space_at(spaces: &mut vector<vector<Option<u64>>>, row_index: u64, column_index: u64): u64 {
        let space = spaces_at_mut(spaces, row_index, column_index);
        assert!(option::is_some(space), ESpaceEmpty);
        option::extract(space)
    }

    fun combine_spaces(spaces: &mut vector<vector<Option<u64>>>, row_index: u64, column_index: u64, combine_into_row_index: u64, combine_into_column_index: u64): u64 {
        let space1value = option::borrow(spaces_at(spaces, row_index, column_index));
        let space2 = spaces_at(spaces, combine_into_row_index, combine_into_column_index);
        assert!(option::contains(space2, space1value), 1);
        clear_space_at(spaces, row_index, column_index);
        increment_space_at(spaces, combine_into_row_index, combine_into_column_index)
    }

    fun is_vertical(direction: u64): bool {
        direction == UP || direction == DOWN
    }

    fun is_reverse(direction: u64): bool {
        direction == RIGHT || direction == DOWN
    }

    fun check_combined(combined_map: &VecMap<SpacePosition, bool>, position: SpacePosition): bool {
        vec_map::contains(combined_map, &position)
    }

    fun set_combined(combined_map: &mut VecMap<SpacePosition, bool>, position: SpacePosition) {
        if (!vec_map::contains(combined_map, &position)) {
            vec_map::insert(combined_map, position, true);
        }   
    }

    fun move_space_direction_at(
      spaces: &mut vector<vector<Option<u64>>>, 
      direction: u64, 
      row_index: u64, 
      column_index: u64,
      combine_map: &mut VecMap<SpacePosition, bool>
    ): (bool, u64) {    
        let space = spaces_at(spaces, row_index, column_index);
        let space_value = *option::borrow(space);
        if (is_vertical(direction)) {
            if (row_index == 0) {
                return (true, space_value)
            };
        } else {
            if (column_index == 0) {
                return (true, space_value)
            };   
        };

        let previous_column_index = column_index;
        let previous_row_index = row_index;

        if (is_vertical(direction)) {
            previous_row_index = row_index - 1;
        } else {
            previous_column_index = column_index - 1;
        };

        let previous = spaces_at(spaces, previous_row_index, previous_column_index);
        if (option::is_some(previous)) {
            if (option::borrow(previous) == &space_value) {
                let previous_space_position = SpacePosition {
                  row: previous_row_index,
                  column: previous_column_index
                };

                if (check_combined(combine_map, previous_space_position)) {
                    return (true, space_value)
                };

                space_value  = combine_spaces(spaces, row_index, column_index, previous_row_index, previous_column_index);
                
                set_combined(combine_map, previous_space_position);
                
                return (true, space_value)
            }
        } else {
            let value = clear_space_at(spaces, row_index, column_index);
            fill_in_space_at(spaces, previous_row_index, previous_column_index, value);
            return (false, space_value)
        };
        return (true, space_value)
    }

    fun move_spaces(spaces: &mut vector<vector<Option<u64>>>, direction: u64): u64 {
        let rows = vector::length(spaces);
        let columns = vector::length(vector::borrow(spaces, 0));
        
        let current_direction = direction;
        
        if (direction == RIGHT) {
            current_direction = LEFT;
        } else if (direction == DOWN) {
            current_direction = UP;
            vector::reverse(spaces);
        };
        
        let top_tile: u64 = 0;

        let combined_map = vec_map::empty<SpacePosition, bool>();
        let row = 0;
        while (row < rows) {
            let column = 0;

            if (direction == RIGHT) {
                vector::reverse(vector::borrow_mut(spaces, row))
            };

            while (column < columns) {
                let space = spaces_at(spaces, row, column);
                
                if (option::is_some(space)) {
                    let current_row = row;
                    let current_column = column;
                    loop {
                        let (stop, tile_value) = move_space_direction_at(
                          spaces, 
                          current_direction, 
                          current_row, 
                          current_column, 
                          &mut combined_map
                        );

                        if (tile_value > top_tile) {
                          top_tile = tile_value;
                        };

                        if (stop) {
                          break
                        };

                        if (is_vertical(current_direction)) {
                            current_row = current_row - 1;
                        } else {
                            current_column = current_column - 1;
                        };
                    }
                };
                column = column + 1;
            };

            if (direction == RIGHT) {
                vector::reverse(vector::borrow_mut(spaces, row))
            };

            row = row + 1;
        };

        if (direction == DOWN) {
            vector::reverse(spaces);
        };

        top_tile
    }

    // TESTS //

    // In here due to number of constants

    #[test_only]
    const EMPTY: u64 = 99;

    #[test_only]
    fun o(value: u64): Option<u64> {
        if (value == EMPTY) {
          return option::none()
        };
        option::some(value)
    }

    #[test_only]
    fun print_board(board: &GameBoard8192) {
        let spaces = spaces(board);
        
        let row_index = 0;
        while (row_index < vector::length(spaces)) {
            let row = vector::borrow(spaces, row_index);

            let printable_row = vector<u64>[];
            let column_index = 0;
            while (column_index < vector::length(row)) {
                let space = vector::borrow(row, column_index);
                if (option::is_none(space)) {
                    vector::push_back(&mut printable_row, 99);
                } else {
                    vector::push_back(&mut printable_row, *option::borrow(space));
                };

                column_index = column_index + 1;
            };

            std::debug::print(&printable_row);
            row_index = row_index + 1;
        }
    }

    #[test_only]
    fun game_board_matches(game_board: &GameBoard8192, expected_spaces: vector<u64>): bool {
        let rows = row_count(game_board);
        let columns = column_count(game_board);
        
        let row=0;
        while (row < rows) {
            let column=0;
            while (column < columns) {
                let index = (row * columns) + column;
                let space = space_at(game_board, row, column);
                let expected = vector::borrow(&expected_spaces, index);
                if (option::is_none(space)) {
                    if(expected != &EMPTY) {
                        return false
                    }
                } else {
                    if (option::borrow(space) != expected) {
                        return false
                    }
                };
                column = column + 1;
            };
            row = row + 1;
        };

        true
    }

    #[test]
    fun test_default_game_board() {
        let game_board = default(vector[1,2,3,4,5,6]);
        assert!(row_count(&game_board) == 4, row_count(&game_board));
        assert!(column_count(&game_board) == 4, column_count(&game_board));
        let empty_space_count = empty_space_count(&game_board);
        assert!(empty_space_count == 14, empty_space_count);
    }

    #[test]
    fun test_move_left() {
        let game_board = default(vector[1,2,3,4,5,6]);
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(0 as u64), (3 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            TILE2, EMPTY, EMPTY, TILE2,
            EMPTY, EMPTY, EMPTY, EMPTY,
            TILE2, EMPTY, EMPTY, EMPTY,
            EMPTY, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move_left__complex() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE16), o(EMPTY), o(TILE128), o(TILE128)],
                vector[o(EMPTY), o(EMPTY), o(EMPTY), o(TILE256)],
                vector[o(EMPTY), o(TILE8), o(TILE8), o(TILE8)],
                vector[o(TILE32), o(EMPTY), o(EMPTY), o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE128,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(1 as u64), (1 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            TILE16,  TILE256, EMPTY, EMPTY,
            TILE256, TILE2,   EMPTY, EMPTY,
            TILE16,  TILE8,   EMPTY, EMPTY,
            TILE64,  EMPTY,   EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move_right() {
        let game_board = default(vector[1,2,3,4,5,6]);
        move_direction(&mut game_board, RIGHT, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(0 as u64), (2 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            EMPTY, EMPTY, TILE2, TILE2,
            EMPTY, EMPTY, EMPTY, EMPTY,
            EMPTY, EMPTY, EMPTY, TILE2,
            EMPTY, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move_right__complex() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE16), o(EMPTY), o(TILE128), o(TILE128)],
                vector[o(EMPTY), o(TILE256), o(EMPTY), o(EMPTY)],
                vector[o(EMPTY), o(TILE8), o(TILE8), o(TILE8)],
                vector[o(TILE32), o(EMPTY), o(EMPTY), o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE128,
            game_over: false
        };
        move_direction(&mut game_board, RIGHT, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(1 as u64), (0 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            EMPTY, EMPTY, TILE16, TILE256, 
            TILE2, EMPTY, EMPTY, TILE256,
            EMPTY, EMPTY, TILE8, TILE16, 
            EMPTY, EMPTY, EMPTY, TILE64
        ]), 1);
    }

    #[test]
    fun test_move_up() {
        let game_board = default(vector[1,2,3,4,5,6]);
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(1 as u64), (0 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            EMPTY, TILE2, EMPTY, TILE2,
            TILE2, EMPTY, EMPTY, EMPTY,
            EMPTY, EMPTY, EMPTY, EMPTY,
            EMPTY, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move_up__complex() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE16),  o(EMPTY),   o(EMPTY), o(TILE32)],
                vector[o(EMPTY),   o(EMPTY),   o(TILE8), o(EMPTY)],
                vector[o(TILE128), o(TILE256), o(TILE8), o(EMPTY)],
                vector[o(TILE128), o(EMPTY),   o(TILE8), o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE256,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(2 as u64), (0 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            TILE16,  TILE256, TILE16, TILE64, 
            TILE256, EMPTY,   TILE8,  EMPTY,
            TILE2,   EMPTY,   EMPTY,  EMPTY, 
            EMPTY,   EMPTY,   EMPTY,  EMPTY
        ]), 1);
    }

    #[test]
    fun test_move_down() {
        let game_board = default(vector[1,2,3,4,5,6]);
        move_direction(&mut game_board, DOWN, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(0 as u64), (2 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            EMPTY, EMPTY, TILE2, EMPTY,
            EMPTY, EMPTY, EMPTY, EMPTY,
            EMPTY, EMPTY, EMPTY, EMPTY,
            EMPTY, TILE2, EMPTY, TILE2
        ]), 1);
    }

    #[test]
    fun test_move_down__complex() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE16),  o(EMPTY),   o(EMPTY), o(TILE32)],
                vector[o(EMPTY),   o(EMPTY),   o(TILE8), o(EMPTY)],
                vector[o(TILE128), o(TILE256), o(TILE8), o(EMPTY)],
                vector[o(TILE128), o(EMPTY),   o(TILE8), o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE256,
            game_over: false
        };
        move_direction(&mut game_board, DOWN, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(0 as u64), (2 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
            EMPTY,   EMPTY,   TILE2,  EMPTY, 
            EMPTY,   EMPTY,   EMPTY,  EMPTY,
            TILE16,  EMPTY,   TILE8,  EMPTY, 
            TILE256, TILE256, TILE16, TILE64
        ]), 1);
    }

    #[test]
    fun test_stop_scenario() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE4), o(TILE2), o(TILE2), o(EMPTY)],
                vector[o(TILE2), o(TILE2), o(TILE4), o(TILE8)],
                vector[o(TILE2), o(TILE2), o(TILE4), o(TILE4)],
                vector[o(EMPTY), o(TILE2), o(TILE2), o(TILE4)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE8,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(2 as u64), (3 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
          TILE4, TILE4, TILE2, TILE8, 
          TILE4, TILE4, TILE8, TILE8,
          EMPTY, EMPTY, TILE2, TILE2, 
          EMPTY, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_stop_scenario__left() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE4),  o(TILE2), o(TILE2), o(EMPTY)],
                vector[o(TILE2),  o(TILE2), o(TILE4), o(TILE8)],
                vector[o(TILE2),  o(TILE2), o(TILE4), o(TILE4)],
                vector[o(TILE16), o(TILE2), o(TILE2), o(TILE4)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE16,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(1 as u64), (3 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
          TILE4,  TILE4, EMPTY, EMPTY, 
          TILE4,  TILE4, TILE8, TILE2,
          TILE4,  TILE8, EMPTY, EMPTY, 
          TILE16, TILE4, TILE4, EMPTY
        ]), 1);
    }

    #[test]
    fun test_stop_scenario__up_inward() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE4), o(TILE2), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(TILE2), o(EMPTY), o(EMPTY)],
                vector[o(TILE8), o(TILE4), o(EMPTY), o(EMPTY)],
                vector[o(EMPTY), o(TILE8), o(EMPTY), o(EMPTY)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE8,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(last_tile(&game_board) == &vector[(1 as u64), (2 as u64), (0 as u64)], 1);
        assert!(game_board_matches(&game_board, vector[
          TILE8, TILE4, EMPTY, EMPTY, 
          TILE8, TILE4, TILE2, EMPTY,
          EMPTY, TILE8, EMPTY, EMPTY, 
          EMPTY, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    #[expected_failure(abort_code = EGameOver)]
    fun test_can_not_move_if_game_over() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(EMPTY),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE16),  o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE8,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);

        assert!(*game_over(&game_board), 1);

        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
    }  

    #[test]
    fun test_game_not_over_if_move_can_be_made() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE2),   o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(EMPTY),   o(TILE2)],
                vector[o(TILE4),   o(TILE8),    o(TILE4),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE8,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);

        assert!(!*game_over(&game_board), 1);
    }

    #[test]
    fun test_move_possible() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(EMPTY),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE4),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(move_possible(&game_board), 1);
    }

    #[test]
    fun test_move_possible_no_move_possible() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE32)],
                vector[o(TILE512), o(TILE1024), o(TILE16),  o(TILE512)],
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(!move_possible(&game_board), 1);
    }

    #[test]
    fun test_move_possible_move_possible_down() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(TILE16),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE16),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(move_possible(&game_board), 1);
    }

    #[test]
    fun test_move_possible_move_possible_right() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(TILE16),  o(TILE16)],
                vector[o(TILE4),   o(TILE8),    o(TILE2),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(move_possible(&game_board), 1);
    }

    #[test]
    fun test_move_possible_move_possible_left() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE128), o(TILE256)],
                vector[o(TILE512), o(TILE16),   o(TILE16),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE2),   o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(move_possible(&game_board), 1);
    }

    #[test]
    fun test_move_possible_move_possible_up() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(TILE64),   o(TILE16),   o(TILE256)],
                vector[o(TILE512), o(TILE1024), o(TILE16),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE4),    o(TILE32)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        assert!(move_possible(&game_board), 1);
    }

    #[test]
    fun test_increments_score() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),  o(TILE4), o(TILE8), o(TILE16)],
                vector[o(TILE32), o(EMPTY), o(TILE4), o(TILE256)],
                vector[o(TILE32), o(EMPTY), o(EMPTY), o(TILE512)],
                vector[o(TILE4),  o(TILE8), o(TILE4), o(TILE32)]
            ],
            score: 500,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(score(&game_board) == &572, *score(&game_board));

        move_direction(&mut game_board, UP, vector[4,5,6,7,8,9]);
        assert!(score(&game_board) == &588, *score(&game_board));
    } 

    #[test]
    fun test_increments_top_tile() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2),   o(TILE4),    o(TILE8),   o(TILE16)],
                vector[o(TILE32),  o(EMPTY),   o(EMPTY),   o(TILE256)],
                vector[o(EMPTY), o(EMPTY), o(TILE16),   o(TILE512)],
                vector[o(TILE4),   o(TILE8),    o(TILE4),    o(TILE32)]
            ],
            score: 500,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(top_tile(&game_board) == &8, (*top_tile(&game_board) as u64));
    }   

    #[test]
    fun test_increments_top_tile__with_new_tile() {
        let game_board = default(vector[1,2,3,4,5,6]);
        assert!(top_tile(&game_board) == &0, (*top_tile(&game_board) as u64));
        move_direction(&mut game_board, UP, vector[4,5,6,7,8,9]);
        assert!(top_tile(&game_board) == &1, (*top_tile(&game_board) as u64));
    }  

    #[test]
    fun test_increments_top_tile__with_combine() {
        let game_board = default(vector[1,2,3,4,5,6]);
        assert!(top_tile(&game_board) == &0, (*top_tile(&game_board) as u64));
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(top_tile(&game_board) == &1, (*top_tile(&game_board) as u64));
    } 

    #[test]
    fun test_no_tile_added_if_no_move_made() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE8), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(EMPTY), o(EMPTY), o(EMPTY)]
            ],
            score: 500,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(empty_space_count(&game_board) == (12 as u64), empty_space_count(&game_board));
    }  

    #[test]
    fun test_move_high_gas() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE256),  o(TILE256), o(TILE64), o(TILE64)],
                vector[o(TILE4),    o(TILE4),   o(TILE8),  o(TILE8)],
                vector[o(TILE1024), o(TILE1024),   o(TILE8),  o(TILE8)],
                vector[o(TILE1024), o(TILE1024),   o(TILE8),  o(TILE8)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE512,    TILE128,  EMPTY,   EMPTY,
            TILE8,      TILE16,   TILE2,   EMPTY,
            TILE2048,   TILE16,   EMPTY,   EMPTY,
            TILE2048,   TILE16,   EMPTY,   EMPTY
        ]), 1);
    }

    #[test]
    fun test_move__vector_error() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE2048), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE512), o(TILE4), o(TILE2), o(EMPTY)],
                vector[o(TILE128), o(TILE16), o(TILE4), o(TILE2)],
                vector[o(TILE16), o(TILE2), o(TILE4), o(TILE2)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE2048,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE2048, TILE4, TILE2, TILE4, 
            TILE512, TILE16, TILE8, EMPTY,
            TILE128, TILE2, EMPTY, TILE2, 
            TILE16, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move__vector_error_2() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(EMPTY), o(EMPTY), o(EMPTY), o(TILE16)],
                vector[o(EMPTY), o(TILE2), o(TILE4), o(TILE256)],
                vector[o(TILE2), o(TILE4), o(TILE8), o(TILE512)],
                vector[o(TILE2), o(TILE4), o(TILE8), o(TILE128)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE512,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE4, TILE2, TILE4, TILE16, 
            EMPTY, TILE8, TILE16, TILE256,
            EMPTY, TILE2, EMPTY, TILE512, 
            EMPTY, EMPTY, EMPTY, TILE128
        ]), 1);
    }

    #[test]
    fun test_move__MovePrimitiveRuntimeError_error() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE8), o(TILE2), o(EMPTY), o(TILE2)],
                vector[o(TILE32), o(TILE8), o(TILE8), o(EMPTY)],
                vector[o(TILE64), o(TILE16), o(TILE16), o(TILE4)],
                vector[o(TILE128), o(TILE2), o(TILE2), o(TILE2)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE128,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[1,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE8, TILE4, EMPTY, EMPTY, 
            TILE32, TILE16, TILE2, EMPTY,
            TILE64, TILE32, TILE4, EMPTY, 
            TILE128, TILE4, TILE2, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move__adds_higher_value_tile_2048() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(EMPTY), o(EMPTY), o(TILE2048), o(EMPTY)],
                vector[o(EMPTY), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE2), o(EMPTY), o(EMPTY), o(EMPTY)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE2048,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[4,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE2048, EMPTY, EMPTY, TILE8, 
            EMPTY, EMPTY, EMPTY, EMPTY,
            TILE4, EMPTY, EMPTY, EMPTY, 
            TILE2, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move__adds_higher_value_tile_4096() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(EMPTY), o(EMPTY), o(TILE4096), o(EMPTY)],
                vector[o(EMPTY), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE2), o(EMPTY), o(EMPTY), o(EMPTY)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE4096,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[5,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE4096, EMPTY, EMPTY, TILE16, 
            EMPTY, EMPTY, EMPTY, EMPTY,
            TILE4, EMPTY, EMPTY, EMPTY, 
            TILE2, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    fun test_move__adds_higher_value_tile_8192() {
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(EMPTY), o(EMPTY), o(TILE8192), o(EMPTY)],
                vector[o(EMPTY), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE4), o(EMPTY), o(EMPTY), o(EMPTY)],
                vector[o(TILE2), o(EMPTY), o(EMPTY), o(EMPTY)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE8192,
            game_over: false
        };
        move_direction(&mut game_board, LEFT, vector[6,2,3,4,5,6]);
        assert!(game_board_matches(&game_board, vector[
            TILE8192, EMPTY, EMPTY, TILE32, 
            EMPTY, EMPTY, EMPTY, EMPTY,
            TILE4, EMPTY, EMPTY, EMPTY, 
            TILE2, EMPTY, EMPTY, EMPTY
        ]), 1);
    }

    #[test]
    #[expected_failure(abort_code = EGameOver)]
    fun test_game_over_move_error() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE1024), o(TILE8),    o(TILE4),   o(TILE2)],
                vector[o(TILE512),  o(TILE4),    o(TILE16),  o(TILE4)],
                vector[o(TILE256),  o(TILE32),   o(TILE8),   o(TILE2)],
                vector[o(TILE64),   o(TILE16),   o(TILE2),   o(TILE16)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);

        assert!(*game_over(&game_board), 1);

        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
    }  

    #[test]
    fun test_game_over() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE1024), o(TILE8),    o(EMPTY),   o(TILE2)],
                vector[o(TILE512),  o(TILE4),    o(TILE16),  o(TILE4)],
                vector[o(TILE256),  o(TILE32),   o(TILE8),   o(TILE128)],
                vector[o(TILE64),   o(TILE16),   o(TILE64),   o(TILE16)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
        assert!(*game_over(&game_board), 1);
    }  

    #[test]
    #[expected_failure(abort_code = EGameOver)]
    fun test_next_move_game_over_move_error() {        
        let game_board = GameBoard8192 {
            spaces: vector[
                vector[o(TILE1024), o(TILE8),    o(TILE4),   o(TILE2)],
                vector[o(TILE512),  o(TILE4),    o(TILE16),  o(TILE4)],
                vector[o(EMPTY),    o(TILE32),   o(TILE8),   o(TILE2)],
                vector[o(TILE64),   o(TILE16),   o(TILE2),   o(TILE16)]
            ],
            score: 0,
            last_tile: vector[],
            top_tile: TILE1024,
            game_over: false
        };
        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);

        assert!(*game_over(&game_board), 1);

        move_direction(&mut game_board, UP, vector[1,2,3,4,5,6]);
    }  
}