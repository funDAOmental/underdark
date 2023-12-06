use starknet::{ContractAddress, ClassHash};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use underdark::models::chamber::{MapData};
use underdark::types::dir::{Dir, DIR, DirTrait};

// define the interface
#[starknet::interface]
trait IActions<TContractState> {
    fn generate_level(self: @TContractState,
        realm_id: u16,
        room_id: u16,
        level_number: u16,
        manor_coord: u128,
        generator_name: felt252,
        generator_value_u128: u128,
    );
    fn finish_level(self: @TContractState,
        location_id: u128,
        proof_low: u128,
        proof_high: u128,
        moves_count: usize,
    );
    // read-only calls
    fn generate_map_data(self: @TContractState,
        location_id: u128,
    ) -> MapData;
}

#[dojo::contract]
mod actions {
    use super::IActions;
    use traits::{Into, TryInto};
    use core::option::OptionTrait;

    use underdark::systems::generate_chamber::{generate_chamber, get_chamber_map_data};
    use underdark::systems::verify_level_proof::{verify_level_proof};
    use underdark::models::chamber::{Chamber, Map, MapData};
    use underdark::types::location::{Location, LocationTrait};
    use underdark::types::dir::{Dir, DIR, DirTrait};

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn generate_level(self: @ContractState,
            realm_id: u16,
            room_id: u16,
            level_number: u16,
            manor_coord: u128,
            generator_name: felt252,
            generator_value_u128: u128,
        ) {
            let world: IWorldDispatcher = self.world_dispatcher.read();
            let location: Location = LocationTrait::from_coord(realm_id, room_id, level_number, manor_coord);
            generate_chamber(world, room_id, level_number, location, generator_name, generator_value_u128.try_into().unwrap());
            return ();
        }

        fn finish_level(self: @ContractState,
            location_id: u128,
            proof_low: u128,
            proof_high: u128,
            moves_count: usize,
        ) {
            let world: IWorldDispatcher = self.world_dispatcher.read();
            let caller = starknet::get_caller_address();

            let proof = u256 {
                low: proof_low,
                high: proof_high,
            };
            verify_level_proof(world, location_id, caller, proof, moves_count);

            return ();
        }

        //
        // read-only calls
        //

        fn generate_map_data(self: @ContractState,
            location_id: u128,
        ) -> MapData {
            let world: IWorldDispatcher = self.world_dispatcher.read();

            // Get and generate all data
            let (chamber, map, map_data) : (Chamber, Map, MapData) = get_chamber_map_data(world, location_id);

            (map_data)
        }



    }
}
