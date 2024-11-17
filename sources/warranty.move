/// Module: warranty
module warranty::warranty;

// === Imports ===
use std::string::{Self, String};
use sui::table::{Self, Table};


// === Errors ===
const ENotBrandOnwer: u64 = 1;
const EEmptyName: u64 = 2;
const EExpired: u64 = 3;

// === Structs ===
public struct Warranty has key, store {
    id: UID,
    brand_owner: ID,
}

public struct BrandOwnerCap has key {
    id: UID,
}

public struct Card has key, store {
    id: UID,
    product_serise_number: String,
    // The warranty expire timestamp in ms
    warranty_expiring_at: u64,

    // When reparing, send card to the service provider by send_card_to_repairing_provider
    original_owner: Option<address>,

    repairing_records: Table<u64, RepairingRecord>
}

public struct RepairingRecord has key, store {
    id: UID,
    provider: address,
    description: String
}

// Set up a Brand, so the brand owner, known as publisher, can issue warranty for the brand after init
fun init(ctx: &mut TxContext) {
    let brand_owner_cap = BrandOwnerCap {
            id: object::new(ctx),
    };

    transfer::share_object(Warranty {
        id: object::new(ctx),
        brand_owner: object::id(&brand_owner_cap),
    });

    transfer::transfer(brand_owner_cap, tx_context::sender(ctx));
}

// === Method Aliases ===
public use fun verify_card as Card.verify;
public use fun send_card_to_repairing_provider as Card.in_repair;
public use fun add_repairing_record_and_reutrn as Card.complete_repiar;


// === Public-Mutative Functions ===
// When repairing the product, the warranty card will send to the reparing service provider
#[allow(lint(custom_state_change))]
public fun send_card_to_repairing_provider(
    mut card: Card,
      repairing_provider: address,
      ctx: &mut TxContext
    ) {
    assert!(card.verify(ctx.epoch_timestamp_ms()), EExpired);
    card.original_owner = option::some(tx_context::sender(ctx));
    transfer::transfer(card, repairing_provider);
}

// Once the product is repaired, the reparing table of the card will be updated,
// then the warranty card will send back to the owner
#[allow(lint(custom_state_change))]
public fun add_repairing_record_and_reutrn(
    mut card: Card,
    description: String,
    ctx: &mut TxContext
    ) {
    let current = ctx.epoch_timestamp_ms();

    let record = RepairingRecord {
      id: object::new(ctx),
      provider: tx_context::sender(ctx),
      description,
    };
    let original_owner = card.original_owner.extract();
    card.repairing_records.add(current, record);
    transfer::transfer(card, original_owner);
}

// === Public-View Functions ===
// Check the card still valid
public fun verify_card(
    card: &Card,
    now: u64,
): bool {
    card.warranty_expiring_at > now
}

// === Admin Functions ===
public fun issue(
    warranty: &Warranty,
    brand_owner_cap: &BrandOwnerCap,
    product_serise_number: String,
    buyer: address,
    warranty_time_in_ms: u64,
    ctx: &mut TxContext,
) {
    assert!(warranty.brand_owner == object::id(brand_owner_cap), ENotBrandOnwer);
    assert!(!string::is_empty(&product_serise_number), EEmptyName);

    let warranty_card = Card {
        id: object::new(ctx),
        product_serise_number,
        warranty_expiring_at: ctx.epoch_timestamp_ms() + warranty_time_in_ms,
        original_owner: option::none<address>(),
        repairing_records: table::new<u64, RepairingRecord>(ctx)
    };

    transfer::transfer(warranty_card, buyer);
}
