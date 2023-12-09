use debug::PrintTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};
use core::option::OptionTrait;

use starknet::{ContractAddress, get_caller_address};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use underdark::systems::generate_chamber::{can_generate_chamber, get_chamber_map_data};
use underdark::models::chamber::{Chamber, Map, MapData, Score};
use underdark::models::tile::{Tile};
use underdark::types::dir::{Dir, DirTrait};
use underdark::utils::bitwise::{U256Bitwise};
use underdark::utils::bitmap::{Bitmap};
use underdark::utils::math::{Math8};
use underdark::types::constants::{LIGHT_MAX, LIGHT_STEP_DROP, SANITY_MAX, MONSTER_NEAR_DAMAGE, MONSTER_HIT_DAMAGE};


fn verify_level_proof(world: IWorldDispatcher,
    location_id: u128,
    proof: u256,
    moves_count: usize,
) -> bool {

    // panic if player cannot generate/play this level
    let caller: ContractAddress = starknet::get_caller_address();
    can_generate_chamber(world, caller, location_id);

    let (chamber, map, map_data) : (Chamber, Map, MapData) = get_chamber_map_data(world, location_id);
    
    let entry: u8 = map.over;
    let exit: u8 = map.under;

    // result is always verified!
    // panics if not
    verify_map(map, map_data, entry, exit, proof, moves_count);

    //---------------------
    // Update score
    //

    let score : Score = get!(world, (location_id, caller), (Score));
    if(score.moves == 0 || moves_count < score.moves) {
        set!(world, (
            Score {
                key_location_id: location_id,
                key_player: caller,
                location_id: location_id,
                player: caller,
                moves: moves_count,
            }
        ));
    }

    (true)
}

fn verify_map(
    map: Map,
    map_data: MapData,
    entry: u8,
    exit: u8,
    proof: u256,
    moves_count: usize,
) -> bool {
    if (map.generator_name == 'seed' || map.generator_name == 'empty') {
        return true; // for tests
    }

    // get all the moves from the proof big number
    let moves: Array<u8> = unpack_proof_moves(proof, moves_count);

    // reproduce moves step by step
    let mut pos: usize = entry.into();
    let mut sanity: u8 = SANITY_MAX;
    let mut light: u8 = LIGHT_MAX;
    let mut dark_tar: u256 = map_data.dark_tar;
    let mut i = 0;
// 'proofing......'.print();
    loop {
        // looking for a chest
        if (map_data.chest > 0 && Bitmap::is_set_tile(map_data.chest, pos)) {
            break; // win!!
        }

        // Recharge light with dark tar
        // unset pos bit to use only once
        if (Bitmap::is_set_tile(dark_tar, pos)) {
            light = LIGHT_MAX;
            dark_tar = Bitmap::unset_tile(dark_tar, pos);
        }

// pos.print();
        if (light > 0) {
            // when lights are on, monsters take your sanity
            if(Bitmap::is_set_tile(map_data.monsters, pos)) {
                sanity = sanity - Math8::min(MONSTER_HIT_DAMAGE, sanity);
            } else if (Bitmap::is_near_or_at_tile(map_data.monsters, pos)) {
                sanity = sanity - Math8::min(MONSTER_NEAR_DAMAGE, sanity);
            }
            assert(sanity > 0, 'Lost sanity!');
        } else {
            // when lights are off, Slenderduck kills instantly
            assert(Bitmap::is_near_or_at_tile(map_data.slender_duck, pos) == false, 'Slendered!');
        }

        // this proof method has a hard limit of 64 moves
        assert(i < 64, 'The Slenderduck found you!');

        // player ran out of moves before reaching the exit
        assert(i < moves.len(), 'Didnt find the exit!');

        // get next move
        let move: u8 = *moves[i];

        // Moves in four directions, mapping Dir::North .. Dir::South
        if (move < 4) {
            // no chest, looking for the exit
            if (map_data.chest == 0) {
                let dir: Option<Dir> = move.try_into();
                pos = Bitmap::move_tile(pos, dir.unwrap());
                if (pos == exit.into()) {
                    break; // win!!
                }
            }
            assert(Bitmap::is_set_tile(map.bitmap, pos) == true, 'Hit a wall!');
            // drop light at every step
            light = light - Math8::min(LIGHT_STEP_DROP, light);
        }

        // ok, go on
        i += 1;
    };

    // found the exit!
    (true)
}


fn pack_proof_moves(moves: Array<u8>) -> u256 {
    let mut result: u256 = 0;
    let mut i: usize = 0;
    loop {
        if(i >= 64 || i >= moves.len()) { break; }
        let move: u8 = *moves[i];
        result = result | U256Bitwise::shl(move.into(), i*4);
        i += 1;
    };
    (result)
}

// one u256 proof can hold 64 4-bit moves
fn unpack_proof_moves(proof: u256, moves_count: usize) -> Array<u8> {
    let mut result: Array<u8> = ArrayTrait::new();
    let mut i: usize = 0;
    loop {
        if (i >= moves_count || i >= 64) { break; }
        let move: u8 = (U256Bitwise::shr(proof, i * 4) & 0b1111).try_into().unwrap();
        result.append(move);
        i += 1;
    };
    (result)
}
