program player_pool_hash.aleo;

struct PlayerPool:
    player as address;
    pool_id as u64;

function get_player_pool_hash:
    input r0 as u64.public;
    input r1 as address.public;
    cast r1 r0 into r2 as PlayerPool;
    hash.bhp256 r2 into r3 as field;
    output r3 as field.private;
