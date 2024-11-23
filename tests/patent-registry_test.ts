import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new patent",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('patent-registry', 'register-patent', [
                types.ascii("Test Patent"),
                types.ascii("Test Description"),
                types.uint(1000)
            ], wallet_1.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Can list patent for sale and purchase it",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('patent-registry', 'register-patent', [
                types.ascii("Test Patent"),
                types.ascii("Test Description"),
                types.uint(1000)
            ], wallet_1.address),
            Tx.contractCall('patent-registry', 'list-for-sale', [
                types.uint(0)
            ], wallet_1.address)
        ]);

        let block2 = chain.mineBlock([
            Tx.contractCall('patent-registry', 'purchase-patent', [
                types.uint(0),
                types.uint(1000)
            ], wallet_2.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectBool(true);
    }
});
