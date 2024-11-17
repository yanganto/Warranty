/// Module: warranty
module warranty::warranty;

// === Imports ===
use std::string::{Self, String};


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
    // TODO: add warranty expiring date
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
public use fun card_valid as Card.valid;

// === Public-View Functions ===
// Check the card still valid
public fun card_valid(
    _card: &Card,
): bool {
    // TODO: check warranty expiring date
    true
}

// === Admin Functions ===
public fun issue(
    warranty: &Warranty,
    brand_owner_cap: &BrandOwnerCap,
    product_serise_number: String,
    buyer: address,
    ctx: &mut TxContext
) {
    assert!(warranty.brand_owner == object::id(brand_owner_cap), ENotBrandOnwer);
    assert!(!string::is_empty(&product_serise_number), EEmptyName);

    let warranty_card = Card {
        id: object::new(ctx),
        product_serise_number,
    };

    transfer::transfer(warranty_card, buyer);
}
