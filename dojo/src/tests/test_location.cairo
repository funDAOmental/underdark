#[cfg(test)]
mod tests {
    use underdark::types::location::{Location, LocationTrait, CONSTANTS};
    use underdark::types::constants::{REALM_ID, MANOR_COORD};
    use underdark::utils::bitwise::{U128Bitwise};
    use underdark::types::dir::{Dir};
    use debug::PrintTrait;

    #[test]
    #[available_gas(10_000_000)]
    fn test_location_equality() {
        let ok1 = Location{ realm_id:REALM_ID, room_id:1, over:3, under:0, north:3, east:3, west:0, south:0 };
        let ok2 = Location{ realm_id:REALM_ID, room_id:1, over:0, under:3, north:0, east:0, west:3, south:3 };
        assert(ok1 == ok1, 'ok1 == ok1');
        assert(ok2 == ok2, 'ok2 == ok2');
        assert(ok1 != ok2, 'ok1 != ok2');
    }

    #[test]
    #[available_gas(1_000_000)]
    fn test_location_constants() {
        assert(CONSTANTS::OFFSET::REALM_ID == (16 * 7), 'CONSTANTS::OFFSET::REALM_ID');
        assert(CONSTANTS::OFFSET::ROOM_ID == (16 * 6), 'CONSTANTS::OFFSET::ROOM_ID');
        assert(CONSTANTS::OFFSET::OVER == (16 * 5), 'CONSTANTS::OFFSET::OVER');
        assert(CONSTANTS::OFFSET::UNDER == (16 * 4), 'CONSTANTS::OFFSET::UNDER');
        assert(CONSTANTS::OFFSET::NORTH == (16 * 3), 'CONSTANTS::OFFSET::NORTH');
        assert(CONSTANTS::OFFSET::EAST == (16 * 2), 'CONSTANTS::OFFSET::EAST');
        assert(CONSTANTS::OFFSET::WEST == (16 * 1), 'CONSTANTS::OFFSET::WEST');
        assert(CONSTANTS::OFFSET::SOUTH == (16 * 0), 'CONSTANTS::OFFSET::SOUTH');
        assert(CONSTANTS::MASK::REALM_ID == U128Bitwise::shl(0xffff, 16 * 7), 'CONSTANTS::MASK::REALM_ID');
        assert(CONSTANTS::MASK::ROOM_ID == U128Bitwise::shl(0xffff, 16 * 6), 'CONSTANTS::MASK::ROOM_ID');
        assert(CONSTANTS::MASK::OVER == U128Bitwise::shl(0xffff, 16 * 5), 'CONSTANTS::MASK::OVER');
        assert(CONSTANTS::MASK::UNDER == U128Bitwise::shl(0xffff, 16 * 4), 'CONSTANTS::MASK::UNDER');
        assert(CONSTANTS::MASK::NORTH == U128Bitwise::shl(0xffff, 16 * 3), 'CONSTANTS::MASK::NORTH');
        assert(CONSTANTS::MASK::EAST == U128Bitwise::shl(0xffff, 16 * 2), 'CONSTANTS::MASK::EAST');
        assert(CONSTANTS::MASK::WEST == U128Bitwise::shl(0xffff, 16 * 1), 'CONSTANTS::MASK::WEST');
        assert(CONSTANTS::MASK::SOUTH == U128Bitwise::shl(0xffff, 16 * 0), 'CONSTANTS::MASK::SOUTH');
    }

    #[test]
    #[available_gas(10_000_000)]
    fn test_location_validate() {
        // fails
        assert(Location{ realm_id:REALM_ID, room_id:1, over:0, under:0, north:0, east:0, west:0, south:0 }.validate() == false, 'zeros');
        // oks
        let mut oks = ArrayTrait::new();
        let mut noks = ArrayTrait::new();
        oks.append(Location{ realm_id:REALM_ID, room_id:1, over:0, under:1, north:1, east:1, west:0, south:0 });
        oks.append(Location{ realm_id:REALM_ID, room_id:1, over:0, under:1, north:1, east:0, west:1, south:0 });
        oks.append(Location{ realm_id:REALM_ID, room_id:1, over:0, under:1, north:0, east:1, west:0, south:1 });
        oks.append(Location{ realm_id:REALM_ID, room_id:1, over:0, under:1, north:0, east:0, west:1, south:1 });
        noks.append(Location{ realm_id:REALM_ID, room_id:1, over:1, under:0, north:1, east:1, west:0, south:0 });
        noks.append(Location{ realm_id:REALM_ID, room_id:1, over:1, under:0, north:1, east:0, west:1, south:0 });
        noks.append(Location{ realm_id:REALM_ID, room_id:1, over:1, under:0, north:0, east:1, west:0, south:1 });
        noks.append(Location{ realm_id:REALM_ID, room_id:1, over:1, under:0, north:0, east:0, west:1, south:1 });
        let mut i: usize = 0;
        loop {
            if(i == oks.len()) { break; }
            let ok = *oks[i];
            let mut loc = ok;
            assert(loc.validate() == true, 'ok');
            if(ok.over > 0) {
                loc = ok; loc.over = 0;
                assert(loc.validate() == false, '!over');
            }
            if(ok.under > 0) {
                loc = ok; loc.under = 0;
                assert(loc.validate() == false, '!under');
            }
            if(ok.north > 0) {
                loc = ok; loc.north = 0;
                assert(loc.validate() == false, '!north');
            }
            if(ok.east > 0) {
                loc = ok; loc.east = 0;
                assert(loc.validate() == false, '!east');
            }
            if(ok.west > 0) {
                loc = ok; loc.west = 0;
                assert(loc.validate() == false, '!west');
            }
            if(ok.south > 0) {
                loc = ok; loc.south = 0;
                assert(loc.validate() == false, '!south');
            }
            i += 1;
        };
        let mut i: usize = 0;
        loop {
            if(i == noks.len()) { break; }
            let nok = *noks[i];
            assert(nok.validate() == false, 'ok');
            i += 1;
        };
    }

    #[test]
    #[available_gas(10_000_000)]
    fn test_location_id() {
        let base = Location {
            realm_id: REALM_ID,
            room_id: 1,
            over: 0x8333,
            under: 0x8444,
            north: 0x8555,
            east: 0x8666,
            west: 0x8777,
            south: 0x8fff,
        };
        assert(base.validate() == false, 'validate');
        let id: u128 = base.to_id();
        assert(id & CONSTANTS::MASK::ROOM_ID == U128Bitwise::shl(base.room_id.into(), CONSTANTS::OFFSET::ROOM_ID), 'id.room_id');
        assert(id & CONSTANTS::MASK::REALM_ID == U128Bitwise::shl(base.realm_id.into(), CONSTANTS::OFFSET::REALM_ID), 'id.realm_id');
        assert(id & CONSTANTS::MASK::OVER == U128Bitwise::shl(base.over.into(), CONSTANTS::OFFSET::OVER), 'id.over');
        assert(id & CONSTANTS::MASK::UNDER == U128Bitwise::shl(base.under.into(), CONSTANTS::OFFSET::UNDER), 'id.under');
        assert(id & CONSTANTS::MASK::NORTH == U128Bitwise::shl(base.north.into(), CONSTANTS::OFFSET::NORTH), 'id.north');
        assert(id & CONSTANTS::MASK::EAST == U128Bitwise::shl(base.east.into(), CONSTANTS::OFFSET::EAST), 'id.east');
        assert(id & CONSTANTS::MASK::WEST == U128Bitwise::shl(base.west.into(), CONSTANTS::OFFSET::WEST), 'id.west');
        assert(id & CONSTANTS::MASK::SOUTH == U128Bitwise::shl(base.south.into(), CONSTANTS::OFFSET::SOUTH), 'id.south');
        let loc: Location = LocationTrait::from_id(id);
        assert(loc.room_id == base.room_id, 'loc.room_id');
        assert(loc.realm_id == base.realm_id, 'loc.realm_id');
        assert(loc.over == base.over, 'loc.over');
        assert(loc.under == base.under, 'loc.under');
        assert(loc.north == base.north, 'loc.north');
        assert(loc.east == base.east, 'loc.east');
        assert(loc.west == base.west, 'loc.west');
        assert(loc.south == base.south, 'loc.south');
    }

    #[test]
    #[available_gas(10_000_000)]
    fn test_location_from_coord() {
        let base = Location {
            realm_id: 111,
            room_id: 222,
            over: 0x8333,
            under: 0x8444,
            north: 0x8555,
            east: 0x8666,
            west: 0x8777,
            south: 0x8fff,
        };
        let coord: u128 = base.to_id();
        let loc: Location = LocationTrait::from_coord(REALM_ID, 1, 2, coord);
        assert(loc.realm_id == REALM_ID, 'loc.realm_id');
        assert(loc.room_id == 1, 'loc.room_id');
        assert(loc.over == 0, 'loc.over');
        assert(loc.under == 2, 'loc.under');
        assert(loc.north == base.north, 'loc.north');
        assert(loc.east == base.east, 'loc.east');
        assert(loc.west == base.west, 'loc.west');
        assert(loc.south == base.south, 'loc.south');
        // assert(loc == base, 'loc != base');
    }

    #[test]
    #[available_gas(10_000_000)]
    fn test_location_offset() {
        let ok1 = Location{ realm_id:REALM_ID, room_id:1, over:0, under:1, north:3, east:3, west:0, south:0 };
        let ok2 = Location{ realm_id:REALM_ID, room_id:1, over:0, under:6, north:0, east:0, west:3, south:3 };
        assert(ok1.validate() == true, 'ok1 is ok');
        assert(ok2.validate() == true, 'ok2 is ok');
        // up to ok2
        let mut loc = ok1;
        let mut i: u16 = 0;
        loop {
            if (i == 5) { break; }
            loc = loc.offset(Dir::Under);
            assert(loc.validate() == true, 'Dir::Under');
            loc = loc.offset(Dir::South);
            assert(loc.validate() == true, 'Dir::South');
            loc = loc.offset(Dir::West);
            assert(loc.validate() == true, 'Dir::Under');
            if (i < 2) {
                // 0 > 2
                // 1 > 1
                let value: u16 = 2 - i;
                // assert(loc.over == value, 'loc.over+');
                assert(loc.north == value, 'loc.north+');
                assert(loc.east == value, 'loc.east+');
                // assert(loc.under == 0, 'loc.under-');
                assert(loc.south == 0, 'loc.south-');
                assert(loc.west == 0, 'loc.west-');
            } else {
                // 2 > 1
                // 3 > 2
                // 4 > 3
                let value: u16 = i - 1;
                // assert(loc.over == 0, 'loc.over-');
                assert(loc.north == 0, 'loc.north-');
                assert(loc.east == 0, 'loc.east-');
                // assert(loc.under == value, 'loc.under+');
                assert(loc.south == value, 'loc.south+');
                assert(loc.west == value, 'loc.west+');
            }
            assert(loc.over == 0, 'loc.over-');
            assert(loc.under == 1 + i + 1, 'loc.under+');
            i += 1;
        };
        assert(loc == ok2, 'loc == ok2');
        // back to ok1
        i = 0;
        loop {
            if (i == 5) { break; }
            loc = loc.offset(Dir::Over);
            assert(loc.validate() == true, 'Dir::Over');
            loc = loc.offset(Dir::North);
            assert(loc.validate() == true, 'Dir::North');
            loc = loc.offset(Dir::East);
            assert(loc.validate() == true, 'Dir::East');
            if (i < 2) {
                // 0 > 2
                // 1 > 1
                let value: u16 = 2 - i;
                // assert(loc.over == 0, '_loc.over-');
                assert(loc.north == 0, '_loc.north-');
                assert(loc.east == 0, '_loc.east-');
                // assert(loc.under == value, '_loc.under+');
                assert(loc.south == value, '_loc.south+');
                assert(loc.west == value, '_loc.west+');
            } else {
                // 2 > 1
                // 3 > 2
                // 4 > 3
                let value: u16 = i - 1;
                // assert(loc.over == value, '_loc.over+');
                assert(loc.north == value, '_loc.north+');
                assert(loc.east == value, '_loc.east+');
                // assert(loc.under == 0, '_loc.under-');
                assert(loc.south == 0, '_loc.south-');
                assert(loc.west == 0, '_loc.west-');
            }
            assert(loc.over == 0, '_loc.over-');
            assert(loc.under == 6 - i - 1, '_loc.under+');
            i += 1;
        };
        assert(loc == ok1, 'loc == ok1');
    }
}
