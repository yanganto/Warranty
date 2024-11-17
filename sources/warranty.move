/// Module: warranty
module warranty::warranty;

// === Imports ===
use std::string::{Self, String};
use sui::clock::{Self, Clock};


// === Errors ===
const ENotBrandOnwer: u64 = 1;
const EEmptyName: u64 = 2;

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

// === Public-View Functions ===
// Check the card still valid
public fun verify_card(
    card: &Card,
    now: &Clock,
): bool {
    card.warranty_expiring_at > clock::timestamp_ms(now)
}

// === Admin Functions ===
public fun issue(
    warranty: &Warranty,
    brand_owner_cap: &BrandOwnerCap,
    product_serise_number: String,
    buyer: address,
    ctx: &mut TxContext,
    warranty_time_in_ms: u64
) {
    assert!(warranty.brand_owner == object::id(brand_owner_cap), ENotBrandOnwer);
    assert!(!string::is_empty(&product_serise_number), EEmptyName);

    let warranty_card = Card {
        id: object::new(ctx),
        product_serise_number,
        warranty_expiring_at: ctx.epoch_timestamp_ms() + warranty_time_in_ms
    };

    transfer::transfer(warranty_card, buyer);
}
