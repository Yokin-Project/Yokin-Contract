import credits.aleo;
import pondo_protocol.aleo;
import token_registry.aleo;

program pool_together_test_1.aleo {
    const PALEO_TOKEN_ID: field = 1751493913335802797273486270793650302076377624243810059080883537084141842600field;

    struct Pool {
        pool_id: u64,
        total_credits: u64,
        total_paleo: u64,
        total_players: u64,
        reward: u64,
        redeem_block: u32,
        closed: bool,
    }

    struct PlayerPool {
        player: address,
        pool_id: u64,
    }

    struct PlayerSlot {
        pool_id: u64,
        player_id: u64,
    }

    struct withdrawal_state {
        microcredits: u64,
        claim_block: u32
    }

    const DEFAULT_KEY: u8 = 0u8;

    mapping admin: u8 => address;
    mapping pool_counter: u8 => u64;
    mapping pools: u64 => Pool;
    mapping balances: field => u64;
    mapping player_slots: field => address;
    mapping pool_winner: u64 => address;

    async transition initialize_pool_public(public init_admin: address) -> Future {
        return finalize_initialize_pool_public(init_admin);
    }

    async function finalize_initialize_pool_public(public init_admin: address) {
        admin.set(DEFAULT_KEY, init_admin);

        pool_counter.set(DEFAULT_KEY, 1u64);
        pools.set(DEFAULT_KEY as u64, Pool {
            pool_id: 1u64,
            total_credits: 0u64,
            total_paleo: 0u64,
            total_players: 0u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        });
    }

    async transition join_pool_public(
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) -> Future {
        // deposit credits
        let f0: Future = pondo_protocol.aleo/deposit_public_as_signer(credits_deposit, expected_paleo_mint, self.address);
        let f1: Future = token_registry.aleo/transfer_public_as_signer(PALEO_TOKEN_ID, self.address, expected_paleo_mint as u128);

        return finalize_join_pool_public(f0, f1, self.signer, credits_deposit, expected_paleo_mint);
    }

    async function finalize_join_pool_public(
        public f0: Future,
        public f1: Future,
        public player: address,
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) {
        f0.await();
        f1.await();

        let pool_id: u64 = pool_counter.get(DEFAULT_KEY);
        let current_pool: Pool = pools.get_or_use(pool_id, Pool {
            pool_id: 0u64,
            total_credits: 0u64,
            total_paleo: 0u64,
            total_players: 0u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        });

        assert(!current_pool.closed);

        let player_pool: PlayerPool = PlayerPool {
            player: player,
            pool_id: pool_id
        };
        let player_pool_hash: field = BHP256::hash_to_field(player_pool);
        let player_balance: u64 = balances.get_or_use(player_pool_hash, 0u64);
        let new_player_balance: u64 = player_balance + credits_deposit;
        balances.set(player_pool_hash, new_player_balance);

        let player_slot: PlayerSlot = PlayerSlot {
            pool_id: pool_id,
            player_id: current_pool.total_players
        };
        let player_slot_hash: field = BHP256::hash_to_field(player_slot);
        player_slots.set(player_slot_hash, player);

        let new_pool: Pool = Pool {
            pool_id: pool_id,
            total_credits: current_pool.total_credits + credits_deposit as u64,
            total_paleo: current_pool.total_paleo + expected_paleo_mint as u64,
            total_players: current_pool.total_players + 1u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        };
        pools.set(pool_id, new_pool);
    }

    async transition select_winner_public(
        public paleo_burn_amount: u64
    ) -> Future {
        // call withdraw paleo
        let f0: Future = pondo_protocol.aleo/withdraw_public(paleo_burn_amount);

        return finalize_select_winner_public(f0, self.caller, paleo_burn_amount);
    }

    async function finalize_select_winner_public(
        public f0: Future,
        public caller: address,
        public paleo_burn_amount: u64
    ) {
        f0.await();

        assert(caller == admin.get(DEFAULT_KEY));

        let random_number: u64 = ChaCha::rand_u64();
        let pool_id: u64 = pool_counter.get(DEFAULT_KEY);
        let current_pool: Pool = pools.get(pool_id);

        assert(!current_pool.closed);
        assert(current_pool.total_paleo == paleo_burn_amount);

        let winner_slot: PlayerSlot = PlayerSlot {
            pool_id: pool_id,
            player_id: random_number % current_pool.total_players
        };
        let winner_slot_hash: field = BHP256::hash_to_field(winner_slot);
        let winner: address = player_slots.get(winner_slot_hash);
        pool_winner.set(pool_id, winner);

        let withdrawal: withdrawal_state = pondo_protocol.aleo/withdrawals.get(self.address);
        let reward: u64 = current_pool.total_credits - withdrawal.microcredits;

        let new_pool: Pool = Pool {
            pool_id: current_pool.pool_id,
            total_credits: current_pool.total_credits,
            total_paleo: current_pool.total_paleo,
            total_players: current_pool.total_players,
            reward: reward,
            redeem_block: withdrawal.claim_block,
            closed: true
        };
        pools.set(current_pool.pool_id, new_pool);
        pool_counter.set(DEFAULT_KEY, pool_id + 1u64);
    }

    async transition redeem_public(
        public pool_id: u64,
        public player: address,
        public credits_redeem: u64,
    ) -> Future {
        // call withdraw paleo
        let f0: Future = credits.aleo/transfer_public(player, credits_redeem);

        return finalize_redeem_public(f0, pool_id, player, credits_redeem);
    }

    async function finalize_redeem_public(
        public f0: Future, 
        public pool_id: u64,
        public player: address,
        public credits_redeem: u64,
    ) {
        f0.await();

        let current_pool: Pool = pools.get(pool_id);
        assert(current_pool.closed);
        assert(block.height >= current_pool.redeem_block);
        
        let player_pool: PlayerPool = PlayerPool {
            player: player,
            pool_id: pool_id
        };
        let player_pool_hash: field = BHP256::hash_to_field(player_pool);
        let deposit_amount: u64 = balances.get(player_pool_hash);

        let winner: address = pool_winner.get(pool_id);
        if player == winner {
            let reward: u64 = current_pool.reward;
            assert(credits_redeem == deposit_amount + reward);
        } else {
            assert(credits_redeem == deposit_amount);
        }

        balances.set(player_pool_hash, 0u64);
    }

    async transition update_admin_public(public new_admin: address) -> Future {
        return finalize_update_admin_public(self.caller, new_admin);
    }

    async function finalize_update_admin_public(
        public caller: address, 
        public new_admin: address
    ) {
        assert(caller == admin.get(DEFAULT_KEY));
        admin.set(DEFAULT_KEY, new_admin);
    }
}