#[cfg(test)]
mod tests {
    use core::traits::Into;
    use array::ArrayTrait;
    use debug::PrintTrait;

    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};

    use underdark::models::chamber::{Chamber};
    use underdark::types::location::{Location, LocationTrait};
    use underdark::types::dir::{Dir, DirTrait, DIR};
    use underdark::types::tile_type::{TileType, TILE};
    use underdark::types::constants::{REALM_ID, MANOR_COORD};
    use underdark::tests::utils::utils::{
        setup_world,
        execute_generate_level,
        generate_level_get_chamber,
        get_world_Chamber,
        get_world_Map,
        force_verify_level,
    };

    #[test]
    #[available_gas(1_000_000_000)]
    fn test_generate_level() {
        let (world, system) = setup_world();
        execute_generate_level(world, system, REALM_ID, 1, 1, MANOR_COORD, 'entry', 0);

        // check Chamber component
        let location: Location = LocationTrait::from_coord(REALM_ID, 1, 1, MANOR_COORD);
        let chamber = get_world_Chamber(world, location.to_id());
        assert(chamber.seed != 0, 'Chamber: bad seed');
        assert(chamber.seed.low != chamber.seed.high, 'Chamber: seed.low != seed.high');
        assert(chamber.yonder == 1, 'Chamber: bad yonder');

        // check Map component
        let map = get_world_Map(world, location.to_id());
        assert(map.bitmap != 0, 'Map: map != 0');
        assert(map.bitmap.low != map.bitmap.high, 'Map: map.low != map.high');
        assert(map.bitmap != chamber.seed, 'Map: map.high != seed.high');
        assert(map.generator_name == 'entry', 'Map: generator name');
        assert(map.generator_value == 0, 'Map: generator value');
    }

    #[test]
    #[should_panic(expected:('Invalid generator','ENTRYPOINT_FAILED'))]
    #[available_gas(1_000_000_000)]
    fn test_mint_realms_invalid_generator() {
        let (world, system) = setup_world();
        // first chamber will always use the 'entry' generator (not on Underdark!)
        let chamber1: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 1, MANOR_COORD, 'the_invalid_generator', 0);
        // now a bad generator to panic...
        // let chamber2 = generate_level_get_chamber(world, system, 1, 2, 'the_invalid_generator', 0);
    }

    #[test]
    #[available_gas(10_000_000_000)]
    fn test_yonder() {
        let (world, system) = setup_world();
        let chamber_y1: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 1, MANOR_COORD, 'seed', 0);
        force_verify_level(world, chamber_y1.location_id);
        let chamber_y2: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 2, MANOR_COORD, 'seed', 0);
        force_verify_level(world, chamber_y2.location_id);
        let chamber_y3: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 3, MANOR_COORD, 'seed', 0);
        assert(chamber_y1.yonder == 1, 'chamber_y1');
        assert(chamber_y2.yonder == 2, 'chamber_y2');
        assert(chamber_y3.yonder == 3, 'chamber_y3');
    }

    #[test]
    #[should_panic(expected:('Chamber already exists','ENTRYPOINT_FAILED'))]
    #[available_gas(1_000_000_000)]
    fn test_generate_level_already_exists() {
        let (world, system) = setup_world();
        execute_generate_level(world, system, REALM_ID, 1, 1, MANOR_COORD, 'entry', 0);
        execute_generate_level(world, system, REALM_ID, 1, 1, MANOR_COORD, 'entry', 0);
    }

    #[test]
    #[should_panic(expected:('Invalid location','ENTRYPOINT_FAILED'))]
    #[available_gas(1_000_000_000)]
    fn test_generate_level_invalid() {
        let (world, system) = setup_world();
        execute_generate_level(world, system, REALM_ID, 1, 0, MANOR_COORD, 'entry', 0);
    }

    #[test]
    #[should_panic(expected:('Over level is closed','ENTRYPOINT_FAILED'))]
    #[available_gas(1_000_000_000)]
    fn test_generate_level_not_over_closed() {
        let (world, system) = setup_world();
        execute_generate_level(world, system, REALM_ID, 1, 2, MANOR_COORD, 'entry', 0);
    }

    #[test]
    #[should_panic(expected:('Complete over level first','ENTRYPOINT_FAILED'))]
    #[available_gas(1_000_000_000)]
    fn test_generate_level_over_not_cleared() {
        let (world, system) = setup_world();
        execute_generate_level(world, system, REALM_ID, 1, 1, MANOR_COORD, 'entry', 0);
        execute_generate_level(world, system, REALM_ID, 1, 2, MANOR_COORD, 'entry', 0);
    }

    #[test]
    #[available_gas(1_000_000_000)]
    fn test_generate_level_over_is_cleared_ok() {
        let (world, system) = setup_world();
        let chamber1: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 1, MANOR_COORD, 'seed', 0);
        force_verify_level(world, chamber1.location_id);
        execute_generate_level(world, system, REALM_ID, 1, 2, MANOR_COORD, 'entry', 0);
    }

    #[test]
    #[available_gas(1_000_000_000)]
    fn test_seed_diversity() {
        let (world, system) = setup_world();
        let chamber1: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 1, MANOR_COORD, 'seed', 0);
        force_verify_level(world, chamber1.location_id);
        let chamber2: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 2, MANOR_COORD, 'entry', 0);
        let chamber3: Chamber = generate_level_get_chamber(world, system, REALM_ID, 2, 1, MANOR_COORD, 'entry', 0);
        let chamber4: Chamber = generate_level_get_chamber(world, system, REALM_ID+1, 1, 1, MANOR_COORD, 'entry', 0);
        let chamber5: Chamber = generate_level_get_chamber(world, system, REALM_ID, 1, 1, MANOR_COORD+1, 'entry', 0);
        assert(chamber1.seed != chamber2.seed, 'Chamber: bad seed 1 == 2');
        assert(chamber1.seed != chamber3.seed, 'Chamber: bad seed 1 == 3');
        assert(chamber1.seed != chamber4.seed, 'Chamber: bad seed 1 == 4');
        assert(chamber1.seed != chamber5.seed, 'Chamber: bad seed 1 == 5');
        assert(chamber2.seed != chamber3.seed, 'Chamber: bad seed 2 == 3');
        assert(chamber2.seed != chamber4.seed, 'Chamber: bad seed 2 == 4');
        assert(chamber2.seed != chamber5.seed, 'Chamber: bad seed 2 == 5');
        assert(chamber3.seed != chamber4.seed, 'Chamber: bad seed 3 == 4');
        assert(chamber3.seed != chamber5.seed, 'Chamber: bad seed 3 == 5');
        assert(chamber4.seed != chamber5.seed, 'Chamber: bad seed 4 == 5');
    }

}
