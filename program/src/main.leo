import credits.aleo;
import pondo_protocol.aleo;
import token_registry.aleo;

program yokin_pool_5_test.aleo {
    const PALEO_TOKEN_ID: field = 1751493913335802797273486270793650302076377624243810059080883537084141842600field;

    struct Pool {
        pool_id: u64,
        total_deposit: u64,
        total_paleo: u64,
        total_players: u64,
        reward: u64,
        deposit_deadline_timestamp: u32,
        withdrawal_start_timestamp: u32,
        deposit_deadline_block: u32,
        withdrawal_start_block: u32,
        winner: address,
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
    
    mapping initialized: u8 => bool;
    mapping admin: u8 => address;
    
    mapping pools: u64 => Pool;
    mapping pool_count: u8 => u64;

    mapping balances: field => u64;
    mapping player_slots: field => address;
    mapping pool_winner: u64 => address;

    async transition initialize(public init_admin: address) -> Future {
        return finalize_initialize(init_admin);
    }

    async function finalize_initialize(public init_admin: address) {
        let is_initialized: bool = initialized.get_or_use(DEFAULT_KEY, false);
        assert(!is_initialized);

        admin.set(DEFAULT_KEY, init_admin);
        initialized.set(DEFAULT_KEY, true);
    }

    async transition create_pool_public(current_timestamp: u32, deposit_deadline_timestamp: u32, est_withdrawal_start_timestamp: u32) -> Future {
        return finalize_create_pool_public(self.caller, current_timestamp, deposit_deadline_timestamp, est_withdrawal_start_timestamp);
    }

    async function finalize_create_pool_public(
        public caller: address,
        current_timestamp: u32,
        deposit_deadline_timestamp: u32,
        est_withdrawal_start_timestamp: u32
    ) {
        assert(caller == admin.get(DEFAULT_KEY));

        // Get current count (or 0 if not set)
        let count: u64 = pool_count.get_or_use(0u8, 0u64);
        let new_id: u64 = count + 1u64;

        let deposit_deadline_block: u32 = block.height + ((deposit_deadline_timestamp - current_timestamp)/3u32);

        let new_pool: Pool = Pool {
            pool_id: new_id,
            total_deposit: 0u64,
            total_paleo: 0u64,
            total_players: 0u64,
            reward: 0u64,
            deposit_deadline_timestamp: deposit_deadline_timestamp,
            withdrawal_start_timestamp: est_withdrawal_start_timestamp,
            deposit_deadline_block: deposit_deadline_block, 
            withdrawal_start_block: 0u32,
            winner: aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc,
        };

        pools.set(new_id, new_pool);
        pool_count.set(0u8, new_id);
    }

    async transition join_pool_public(
        public pool_id: u64,
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) -> Future {
        // deposit credits
        let f0: Future = pondo_protocol.aleo/deposit_public_as_signer(credits_deposit, expected_paleo_mint, self.address);
        let f1: Future = token_registry.aleo/transfer_public_as_signer(PALEO_TOKEN_ID, self.address, expected_paleo_mint as u128);

        return finalize_join_pool_public(f0, f1, pool_id, self.signer, credits_deposit, expected_paleo_mint);
    }

    async function finalize_join_pool_public(
        public f0: Future,
        public f1: Future,
        public pool_id: u64,
        public player: address,
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) {
        f0.await();
        f1.await();

        let current_pool: Pool = pools.get(pool_id);

        // Ensure pool is still open for deposits:
        // Current block height must be less than deposit_deadline_block.
        assert(block.height < current_pool.deposit_deadline_block);

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
            total_deposit: current_pool.total_deposit + credits_deposit,
            total_paleo: current_pool.total_paleo + expected_paleo_mint,
            total_players: current_pool.total_players + 1u64,
            reward: 0u64,
            deposit_deadline_timestamp: current_pool.deposit_deadline_timestamp,
            withdrawal_start_timestamp: current_pool.withdrawal_start_timestamp,
            deposit_deadline_block: current_pool.deposit_deadline_block,
            withdrawal_start_block: current_pool.withdrawal_start_block,
            winner: current_pool.winner,
        };
        pools.set(pool_id, new_pool);
    }

    async transition slow_withdraw_public (
        public pool_id: u64,
        public paleo_burn_amount: u64,
        public current_timestamp: u32
    ) -> Future {
        // call withdraw paleo
        let f0: Future = pondo_protocol.aleo/withdraw_public(paleo_burn_amount);
        return finalize_slow_withdraw_public(f0, pool_id, self.caller, paleo_burn_amount, current_timestamp);
    }

    async function finalize_slow_withdraw_public(
        public f0: Future,
        public pool_id: u64,
        public caller: address,
        public paleo_burn_amount: u64,
        public current_timestamp: u32
    ) {
        f0.await();

        assert(caller == admin.get(DEFAULT_KEY));

        let current_pool: Pool = pools.get(pool_id);

        // Ensure deposit period is over and the pool hasn't been finalized.
        // Current block height must be greater than deposit_deadline_block.
        assert(block.height > current_pool.deposit_deadline_block && current_pool.withdrawal_start_block == 0u32);
        assert(current_pool.total_paleo == paleo_burn_amount);

        let withdrawal: withdrawal_state = pondo_protocol.aleo/withdrawals.get(self.address);

        // TODO remove as just testing
        // assert(withdrawal.microcredits > current_pool.total_deposit);
        // let reward: u64 = withdrawal.microcredits - current_pool.total_deposit;

        let estimated_withdrawal_timestamp: u32 = current_timestamp + ((withdrawal.claim_block - block.height) * 3u32);

        let new_pool: Pool = Pool {
            pool_id: current_pool.pool_id,
            total_deposit: current_pool.total_deposit,
            total_paleo: current_pool.total_paleo,
            total_players: current_pool.total_players,
            reward: current_pool.reward,
            deposit_deadline_timestamp: current_pool.deposit_deadline_timestamp,
            withdrawal_start_timestamp: estimated_withdrawal_timestamp,
            deposit_deadline_block: current_pool.deposit_deadline_block,
            withdrawal_start_block: withdrawal.claim_block,
            winner: current_pool.winner,
        };
        pools.set(current_pool.pool_id, new_pool);
    }

    async transition claim_withdraw_public (public pool_id: u64, public paleo_burn_amount: u64) -> Future {
        let f0: Future = pondo_protocol.aleo/claim_withdrawal_public(self.address, paleo_burn_amount);
        return finalize_claim_withdraw_public(f0, pool_id, paleo_burn_amount);
    }

    async function finalize_claim_withdraw_public(
        public f0: Future,
        public pool_id: u64,
        public paleo_burn_amount: u64,
    ) {
        f0.await();
        let current_pool: Pool = pools.get(pool_id);
        assert(current_pool.total_paleo == paleo_burn_amount);
    }
    
    async transition random_winner_public(
        public pool_id: u64,
    ) -> Future {
        return finalize_random_winner_public(pool_id, self.caller);
    }

    async function finalize_random_winner_public(
        public pool_id: u64,
        public caller: address,
    ) {
        assert(caller == admin.get(DEFAULT_KEY));

        let random_number: u64 = ChaCha::rand_u64();
        let current_pool: Pool = pools.get(pool_id);

        // TODO: remove this once we have a better way to check if empty pool winner.
        // meaning no winner has been set yet
        assert(current_pool.winner == aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc); 

        let winner_slot: PlayerSlot = PlayerSlot {
            pool_id: pool_id,
            player_id: random_number % current_pool.total_players
        };
        let winner_slot_hash: field = BHP256::hash_to_field(winner_slot);
        let winner: address = player_slots.get(winner_slot_hash);
        pool_winner.set(pool_id, winner);

        let new_pool: Pool = Pool {
            pool_id: current_pool.pool_id,
            total_deposit: current_pool.total_deposit,
            total_paleo: current_pool.total_paleo,
            total_players: current_pool.total_players,
            reward: current_pool.reward,
            deposit_deadline_timestamp: current_pool.deposit_deadline_timestamp,
            withdrawal_start_timestamp: current_pool.withdrawal_start_timestamp,
            deposit_deadline_block: current_pool.deposit_deadline_block,
            withdrawal_start_block: current_pool.withdrawal_start_block,
            winner: winner,
        };
        pools.set(current_pool.pool_id, new_pool);
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
        // Ensure redemption is allowed:
        // withdrawal_start_block must be set and the current block height must be at or past withdrawal_start_block.
        assert(current_pool.withdrawal_start_block != 0u32 && block.height > current_pool.withdrawal_start_block);
        
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