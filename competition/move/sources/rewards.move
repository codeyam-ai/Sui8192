/// This module is intended to distribute daily rewards on admin submission with
/// the following rules:
/// - An admin sends the addresses daily
/// - The number of addresses is fixed and set to X
/// - Addresses are sent in the specified order
/// - The order matches the reward distribution (1st place - 1st reward, etc.)
/// - The rewards amount is fixed and is calculated for 1 month
///
/// Notes:
/// - 5000 SUI per 30 days is ~ 167 SUI per day. For 10 users it's 16.7 SUI per day on average
module ethos::rewards {
    use sui::transfer::{share_object, public_transfer, transfer};
    use sui::tx_context::{sender, TxContext};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::vec_set;
    use std::vector;

    /// In case I don't know how to count to 10.
    const EIncorrectSetup: u64 = 0;
    /// In case the number of addresses is incorrect.
    const EIncorrectWinners: u64 = 1;
    /// In case there's a duplicate address.
    const EDuplicateAddress: u64 = 2;
    /// In case the pool is empty.
    const EEmptyPool: u64 = 3;
    /// Distribution is only allowed once per 20 hours. - think about making it 10
    const ETooEarlyToDistribute: u64 = 4;
    /// The distribution is only allowed X times.
    const ETooManyUses: u64 = 5;


    /// Roughly days per month.
    const DAYS_RUNNING: u8 = 30;
    /// The distribution interval is 20 hours.
    const TWENTY_HOURS_MS: u64 = 20 * 60 * 60 * 1000;
    /// Assuming there's 10 winners.
    const WINNERS_COUNT: u64 = 10;
    /// 10^9 MIST = 1 SUI
    const MIST_PER_SUI: u64 = 1_000_000_000;
    /// Total records = WINNERS_COUNT
    const DISTRIBUTION: vector<u64> = vector[
        60 * 1_000_000_000,
        30 * 1_000_000_000,
        15 * 1_000_000_000,
        15 * 1_000_000_000,
        10 * 1_000_000_000,
        10 * 1_000_000_000,
        10 * 1_000_000_000,
        5 * 1_000_000_000,
        5 * 1_000_000_000,
        5 * 1_000_000_000
    ];

    /// The `RewardsPool` object contains the pool of rewards for the current
    /// month calculated based on the number of addresses and the reward amount
    /// per address per day.
    struct RewardsPool has key {
        id: UID,
        pool: Balance<SUI>,
        uses: u8,
        last_use_timestamp_ms: u64
    }

    /// The capability to deposit liquidity into the pool. One time use.
    struct DepositCap has key, store { id: UID }

    /// The capability to withdraw liquidity from the pool. One time use.
    struct EmergencyCap has key, store { id: UID }

    /// The capability allowing the admin to submit the addresses for the distribution.
    struct DistributionCap has key, store { id: UID }

    /// Deposit funds into the pool. Performed by the sponsor of the event.
    /// May need to be composed as a non-signed transaction to execute via multisig.
    public fun deposit(
        deposit_cap: DepositCap,
        self: &mut RewardsPool,
        coin: Coin<SUI>
    ) {
        let DepositCap { id } = deposit_cap;
        coin::put(&mut self.pool, coin);
        object::delete(id);
    }

    /// Distribute the rewards from the pool to the winners.
    public fun distribute(
        _distribution_cap: &DistributionCap,
        self: &mut RewardsPool,
        winners: vector<address>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&self.pool) > 0, EEmptyPool);
        assert!(vector::length(&winners) == WINNERS_COUNT, EIncorrectWinners);
        assert!(self.last_use_timestamp_ms + TWENTY_HOURS_MS <= clock::timestamp_ms(clock), ETooEarlyToDistribute);
        assert!(self.uses > 0, ETooManyUses);

        // keeping this variable to make sure we don't have duplicates.
        let processed = vec_set::empty();

        // iterate through the winners and do the following:
        // 1. take an address from the end
        // 2. take the reward amount at matching index
        // 3. make sure the set does not contain duplicates
        while (vector::length(&winners) > 0) {
            let winner = vector::pop_back(&mut winners);
            let winner_idx = vector::length(&winners) - 1;

            assert!(vec_set::contains(&processed, &winner), EDuplicateAddress);

            let reward_amount = *vector::borrow(&DISTRIBUTION, winner_idx);
            let reward = coin::take(&mut self.pool, reward_amount, ctx);

            public_transfer(reward, winner);
            vec_set::insert(&mut processed, winner);
        };

        self.uses = self.uses - 1;
        self.last_use_timestamp_ms = clock::timestamp_ms(clock);
    }

    public fun emergency_withdraw(
        emergency_cap: EmergencyCap,
        self: &mut RewardsPool,
        ctx: &mut TxContext
    ) {
        let EmergencyCap { id } = emergency_cap;
        let amount = balance::value(&self.pool);
        let coin = coin::take(&mut self.pool, amount, ctx);

        public_transfer(coin, sender(ctx));
        object::delete(id)
    }

    /// In the initializer send everything to the transaction sender for the further
    /// distribution or power to admin parties.
    fun init(ctx: &mut TxContext) {
        assert!(vector::length(&DISTRIBUTION) == WINNERS_COUNT, EIncorrectSetup);

        share_object(RewardsPool {
            id: object::new(ctx),
            pool: balance::zero(),
            uses: DAYS_RUNNING,
            last_use_timestamp_ms: 0
        });

        transfer(DepositCap { id: object::new(ctx) }, sender(ctx));
        transfer(EmergencyCap { id: object::new(ctx) }, sender(ctx));
        transfer(DistributionCap { id: object::new(ctx) }, sender(ctx));
    }
}