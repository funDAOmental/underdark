use debug::PrintTrait;
use traits::{Into, TryInto};

use starknet::{ContractAddress, get_caller_address};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use underdark::systems::generate_doors::{generate_doors};
use underdark::models::chamber::{Chamber, Map, MapData};
use underdark::core::randomizer::{randomize_door_permissions, randomize_monsters};
use underdark::types::location::{Location, LocationTrait};
use underdark::types::dir::{Dir, DirTrait};
use underdark::types::doors::{Doors};
use underdark::core::seeder::{make_seed};
use underdark::core::generator::{generate};

#[inline(always)]
fn generate_chamber(world: IWorldDispatcher,
    room_id: u16,
    level_number: u16,
    location: Location,
    mut generator_name: felt252,
    mut generator_value: u32,
) -> u128 {

    let location_id: u128 = location.to_id();

    // assert chamber is new
    let chamber: Chamber = get!(world, location_id, (Chamber));
    assert(chamber.yonder == 0, 'Chamber already exists');


    //---------------------
    // Chamber
    //
    // create seed, the initial bitmap state that is used to sculpt it
    let seed: u256 = make_seed(location_id);
    // clone seed for value randomization
    let mut rnd: u256 = seed;

    // increment yonder
    let yonder: u16 = level_number.try_into().unwrap();


    //---------------------
    // Doors
    //
    let permissions: u8 = 0b000100;
    let (doors, protected): (Doors, u256) = generate_doors(world, location, location_id, ref rnd, permissions, generator_name);

    //---------------------
    // Generate Bitmap
    //
    let bitmap: u256= generate(seed, protected, generator_name, generator_value);
    assert(bitmap != 0, 'Chamber is empty');

    //---------------------
    // Map Component
    //
    set!(world, (
        Chamber {
            location_id,
            seed,
            room_id,
            level_number,
            yonder,
        },
        Map {
            entity_id: location_id,
            bitmap,
            protected,
            generator_name,
            generator_value,
            north: doors.north,
            east: doors.east,
            west: doors.west,
            south: doors.south,
            over: doors.over,
            under: doors.under,
        },
    ) );

    location_id
}

#[inline(always)]
fn get_chamber_map_data(world: IWorldDispatcher,
    location_id: u128,
) -> (Chamber, Map, MapData) {

    // assert chamber exists
    let chamber: Chamber = get!(world, location_id, (Chamber));
    assert(chamber.yonder > 0, 'Chamber does not exist!');

    // Get Map
    let map: Map = get!(world, location_id, (Map));

    // Generate MapData
    let mut rnd = chamber.seed;
    let (monsters, slender_duck, dark_tar): (u256, u256, u256) = randomize_monsters(ref rnd, map, chamber.level_number);
    let map_data = MapData {
        location_id,
        monsters,
        slender_duck,
        dark_tar,
        chest: 0,
    };

    (chamber, map, map_data)
}
