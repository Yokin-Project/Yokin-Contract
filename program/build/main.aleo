import credits.aleo;
import token_registry.aleo;
import wrapped_credits.aleo;
import validator_oracle.aleo;
import paleo_token.aleo;
import pondo_protocol_token.aleo;
import delegator1.aleo;
import delegator2.aleo;
import delegator3.aleo;
import delegator4.aleo;
import delegator5.aleo;
import pondo_protocol.aleo;
program yokin_pool_5_test.aleo;

struct TokenMetadata:
    token_id as field;
    name as u128;
    symbol as u128;
    decimals as u8;
    supply as u128;
    max_supply as u128;
    admin as address;
    external_authorization_required as boolean;
    external_authorization_party as address;

struct TokenOwner:
    account as address;
    token_id as field;

struct admin_operation:
    arg as field;
    op_type as u8;
    request_id as u64;

struct validator_state:
    validator as address;
    commission as u8;

struct Pool:
    pool_id as u64;
    total_deposit as u64;
    total_paleo as u64;
    total_players as u64;
    reward as u64;
    deposit_deadline_timestamp as u32;
    withdrawal_start_timestamp as u32;
    deposit_deadline_block as u32;
    withdrawal_start_block as u32;
    winner as address;

struct PlayerPool:
    player as address;
    pool_id as u64;

struct PlayerSlot:
    pool_id as u64;
    player_id as u64;

mapping initialized:
    key as u8.public;
    value as boolean.public;

mapping admin:
    key as u8.public;
    value as address.public;

mapping pools:
    key as u64.public;
    value as Pool.public;

mapping pool_count:
    key as u8.public;
    value as u64.public;

mapping balances:
    key as field.public;
    value as u64.public;

mapping player_slots:
    key as field.public;
    value as address.public;

mapping pool_winner:
    key as u64.public;
    value as address.public;

function initialize:
    input r0 as address.public;
    async initialize r0 into r1;
    output r1 as yokin_pool_5_test.aleo/initialize.future;

finalize initialize:
    input r0 as address.public;
    get.or_use initialized[0u8] false into r1;
    not r1 into r2;
    assert.eq r2 true;
    set r0 into admin[0u8];
    set true into initialized[0u8];

function create_pool_public:
    input r0 as u32.private;
    input r1 as u32.private;
    input r2 as u32.private;
    async create_pool_public self.caller r0 r1 r2 into r3;
    output r3 as yokin_pool_5_test.aleo/create_pool_public.future;

finalize create_pool_public:
    input r0 as address.public;
    input r1 as u32.public;
    input r2 as u32.public;
    input r3 as u32.public;
    get admin[0u8] into r4;
    is.eq r0 r4 into r5;
    assert.eq r5 true;
    get.or_use pool_count[0u8] 0u64 into r6;
    add r6 1u64 into r7;
    sub r2 r1 into r8;
    div r8 3u32 into r9;
    add block.height r9 into r10;
    cast r7 0u64 0u64 0u64 0u64 r2 r3 r10 0u32 aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc into r11 as Pool;
    set r11 into pools[r7];
    set r7 into pool_count[0u8];

function join_pool_public:
    input r0 as u64.public;
    input r1 as u64.public;
    input r2 as u64.public;
    call pondo_protocol.aleo/deposit_public_as_signer r1 r2 yokin_pool_5_test.aleo into r3;
    cast r2 into r4 as u128;
    call token_registry.aleo/transfer_public_as_signer 1751493913335802797273486270793650302076377624243810059080883537084141842600field yokin_pool_5_test.aleo r4 into r5;
    async join_pool_public r3 r5 r0 self.signer r1 r2 into r6;
    output r6 as yokin_pool_5_test.aleo/join_pool_public.future;

finalize join_pool_public:
    input r0 as pondo_protocol.aleo/deposit_public_as_signer.future;
    input r1 as token_registry.aleo/transfer_public_as_signer.future;
    input r2 as u64.public;
    input r3 as address.public;
    input r4 as u64.public;
    input r5 as u64.public;
    await r0;
    await r1;
    get pools[r2] into r6;
    lt block.height r6.deposit_deadline_block into r7;
    assert.eq r7 true;
    cast r3 r2 into r8 as PlayerPool;
    hash.bhp256 r8 into r9 as field;
    get.or_use balances[r9] 0u64 into r10;
    add r10 r4 into r11;
    set r11 into balances[r9];
    cast r2 r6.total_players into r12 as PlayerSlot;
    hash.bhp256 r12 into r13 as field;
    set r3 into player_slots[r13];
    add r6.total_deposit r4 into r14;
    add r6.total_paleo r5 into r15;
    add r6.total_players 1u64 into r16;
    cast r2 r14 r15 r16 0u64 r6.deposit_deadline_timestamp r6.withdrawal_start_timestamp r6.deposit_deadline_block r6.withdrawal_start_block r6.winner into r17 as Pool;
    set r17 into pools[r2];

function random_winner_public:
    input r0 as u64.public;
    async random_winner_public r0 self.caller into r1;
    output r1 as yokin_pool_5_test.aleo/random_winner_public.future;

finalize random_winner_public:
    input r0 as u64.public;
    input r1 as address.public;
    get admin[0u8] into r2;
    is.eq r1 r2 into r3;
    assert.eq r3 true;
    rand.chacha into r4 as u64;
    get pools[r0] into r5;
    rem r4 r5.total_players into r6;
    cast r0 r6 into r7 as PlayerSlot;
    hash.bhp256 r7 into r8 as field;
    get player_slots[r8] into r9;
    set r9 into pool_winner[r0];
    cast r5.pool_id r5.total_deposit r5.total_paleo r5.total_players r5.reward r5.deposit_deadline_timestamp r5.withdrawal_start_timestamp r5.deposit_deadline_block r5.withdrawal_start_block r9 into r10 as Pool;
    set r10 into pools[r5.pool_id];
