
module test_package::test {

use sui::id::{VersionedID};
use sui::transfer;
use sui::tx_context::{Self,TxContext};


struct Sword has key, store {
    id : VersionedID,
    magic : u64,
    strength : u64
}


struct Forge has key, store {
    id : VersionedID,
    swords_created : u64
}

public fun swords_created(self: &Forge) : u64 {
    self.swords_created
}


//module initialization
fun init(ctx : &mut TxContext) {

    let admin = Forge {
        id : tx_context::new_id(ctx),
        swords_created : 0
    };

    transfer::transfer(admin, tx_context::sender(ctx));
}


public fun magic(self : &Sword) :u64 {
    self.magic
}

public fun strength(self : &Sword) : u64 {
    self.strength
}


 
public entry fun create_sword(forged : &mut Forge, magic: u64, strength : u64 ,receipient : address, ctx : &mut TxContext) {

    let sword  = Sword {
        id : tx_context::new_id(ctx),
        strength : strength,
        magic : magic
    };

    transfer::transfer(sword, receipient);

    forged.swords_created = forged.swords_created + 1;
    
   // transfer::transfer(&forged, admin);
}

public entry fun transfer_sword(sword : Sword , recipient : address, _ctx : &mut TxContext) {
    transfer::transfer(sword, recipient);
}

// public entry fun transfer_forge(forge : Forge, recipient : address) {
//     transfer::transfer(forge, recipient);
// }


#[test]
public fun test_sword_create() {

    use sui::tx_context;
    use sui::transfer;

    let ctx =&mut tx_context::dummy();

    let sword = Sword {
        id : tx_context::new_id(ctx),
        strength : 43,
        magic : 120
    };

    assert!(magic(&sword) == 120 && strength(&sword) == 43, 1);

    transfer::transfer(sword, @0x123);

}

#[test]
public fun test_sword_transaction() {
    use sui::test_scenario;

    let admin = @0x23;
    let initial_owner = @0x33;
    let final_owner = @0x45;

    // first transaction executed by admin
    let scenario = &mut test_scenario::begin(&admin);
    {
        init(test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, &admin);
    {
         let forged = test_scenario::take_owned<Forge>(scenario);
        create_sword(&mut forged, 42, 7, initial_owner, test_scenario::ctx(scenario));
        test_scenario::return_owned(scenario, forged);

    };

    // second transaction executed by initial owner
    test_scenario::next_tx(scenario, &initial_owner);
    {
        let sword = test_scenario::take_owned<Sword>(scenario);
        transfer_sword(sword, final_owner, test_scenario::ctx(scenario));
    };

    //third transaction executed by final owner
    test_scenario::next_tx(scenario, &final_owner);
    {
        let sword = test_scenario::take_owned<Sword>(scenario);
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);
        
        test_scenario::return_owned(scenario, sword);

    };

}

#[test]
public fun test_module_init() {
        use sui::test_scenario;

    let admin = @0xAE1;

    let scenario = &mut test_scenario::begin(&admin);
    {
        init(test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, &admin);
    {
        let forge = test_scenario::take_owned<Forge>(scenario);

        assert!(swords_created(&forge) == 0, 1);
        test_scenario::return_owned(scenario, forge);
    }
}

}