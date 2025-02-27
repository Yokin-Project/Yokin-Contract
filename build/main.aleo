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
program yokin_test_1.aleo;

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

struct withdrawal_state:
    microcredits as u64;
    claim_block as u32;

struct Pool:
    pool_id as u64;
    total_deposit as u64;
    total_paleo as u64;
    total_players as u64;
    reward as u64;
    redeem_block as u32;
    deposit_deadline_height as u32;

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

mapping opened_pools:
    key as u64.public;
    value as boolean.public;

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
    output r1 as yokin_test_1.aleo/initialize.future;

finalize initialize:
    input r0 as address.public;
    get.or_use initialized[0u8] false into r1;
    not r1 into r2;
    assert.eq r2 true;
    set r0 into admin[0u8];
    set true into initialized[0u8];

function create_pool_public:
    input r0 as u32.private;
    async create_pool_public self.caller r0 into r1;
    output r1 as yokin_test_1.aleo/create_pool_public.future;

finalize create_pool_public:
    input r0 as address.public;
    input r1 as u32.public;
    get admin[0u8] into r2;
    is.eq r0 r2 into r3;
    assert.eq r3 true;
    get.or_use pool_count[0u8] 0u64 into r4;
    add r4 1u64 into r5;
    cast r5 0u64 0u64 0u64 0u64 0u32 r1 into r6 as Pool;
    set r6 into pools[r5];
    set r5 into pool_count[0u8];

function join_pool_public:
    input r0 as u64.public;
    input r1 as u64.public;
    input r2 as u64.public;
    call pondo_protocol.aleo/deposit_public_as_signer r1 r2 yokin_test_1.aleo into r3;
    cast r2 into r4 as u128;
    call token_registry.aleo/transfer_public_as_signer 1751493913335802797273486270793650302076377624243810059080883537084141842600field yokin_test_1.aleo r4 into r5;
    async join_pool_public r3 r5 r0 self.signer r1 r2 into r6;
    output r6 as yokin_test_1.aleo/join_pool_public.future;

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
    lt block.height r6.deposit_deadline_height into r7;
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
    cast r2 r14 r15 r16 0u64 0u32 r6.deposit_deadline_height into r17 as Pool;
    set r17 into pools[r2];

function select_winner_public:
    input r0 as u64.public;
    input r1 as u64.public;
    call pondo_protocol.aleo/withdraw_public r1 into r2;
    async select_winner_public r2 r0 self.caller r1 into r3;
    output r3 as yokin_test_1.aleo/select_winner_public.future;

finalize select_winner_public:
    input r0 as pondo_protocol.aleo/withdraw_public.future;
    input r1 as u64.public;
    input r2 as address.public;
    input r3 as u64.public;
    await r0;
    get admin[0u8] into r4;
    is.eq r2 r4 into r5;
    assert.eq r5 true;
    rand.chacha into r6 as u64;
    get pools[r1] into r7;
    gt block.height r7.deposit_deadline_height into r8;
    is.eq r7.redeem_block 0u32 into r9;
    and r8 r9 into r10;
    assert.eq r10 true;
    is.eq r7.total_paleo r3 into r11;
    assert.eq r11 true;
    rem r6 r7.total_players into r12;
    cast r1 r12 into r13 as PlayerSlot;
    hash.bhp256 r13 into r14 as field;
    get player_slots[r14] into r15;
    set r15 into pool_winner[r1];
    get pondo_protocol.aleo/withdrawals[yokin_test_1.aleo] into r16;
    gt r16.microcredits r7.total_deposit into r17;
    assert.eq r17 true;
    sub r16.microcredits r7.total_deposit into r18;
    cast r7.pool_id r7.total_deposit r7.total_paleo r7.total_players r18 r16.claim_block r7.deposit_deadline_height into r19 as Pool;
    set r19 into pools[r7.pool_id];

function redeem_public:
    input r0 as u64.public;
    input r1 as address.public;
    input r2 as u64.public;
    call credits.aleo/transfer_public r1 r2 into r3;
    async redeem_public r3 r0 r1 r2 into r4;
    output r4 as yokin_test_1.aleo/redeem_public.future;

finalize redeem_public:
    input r0 as credits.aleo/transfer_public.future;
    input r1 as u64.public;
    input r2 as address.public;
    input r3 as u64.public;
    await r0;
    get pools[r1] into r4;
    is.neq r4.redeem_block 0u32 into r5;
    gte block.height r4.redeem_block into r6;
    and r5 r6 into r7;
    assert.eq r7 true;
    cast r2 r1 into r8 as PlayerPool;
    hash.bhp256 r8 into r9 as field;
    get balances[r9] into r10;
    get pool_winner[r1] into r11;
    is.eq r2 r11 into r12;
    branch.eq r12 false to end_then_0_0;
    add r10 r4.reward into r13;
    is.eq r3 r13 into r14;
    assert.eq r14 true;
    branch.eq true true to end_otherwise_0_1;
    position end_then_0_0;
    is.eq r3 r10 into r15;
    assert.eq r15 true;
    position end_otherwise_0_1;
    set 0u64 into balances[r9];

function update_admin_public:
    input r0 as address.public;
    async update_admin_public self.caller r0 into r1;
    output r1 as yokin_test_1.aleo/update_admin_public.future;

finalize update_admin_public:
    input r0 as address.public;
    input r1 as address.public;
    get admin[0u8] into r2;
    is.eq r0 r2 into r3;
    assert.eq r3 true;
    set r1 into admin[0u8];
