package hr.fer.rgkk.transactions;

import org.bitcoinj.core.*;
import org.bitcoinj.core.Utils;
import org.bitcoinj.crypto.DeterministicKey;
import org.bitcoinj.crypto.TransactionSignature;
import org.bitcoinj.script.Script;
import org.bitcoinj.script.ScriptBuilder;

import static org.bitcoinj.script.ScriptOpCodes.*;

public class PayToPubKeyHash extends ScriptTransaction {

    private ECKey key; // elliptic curve key

    public PayToPubKeyHash(WalletKit walletKit, NetworkParameters parameters) {
        super(walletKit, parameters);
        key = randKey();
    }

    @Override
    public Script createLockingScript() {
        // TODO: Create Locking script (scriptPubKey)
        return new ScriptBuilder()
                .op(OP_DUP)
                .op(OP_HASH160)
                .data(key.getPubKeyHash())
                .op(OP_EQUALVERIFY)
                .op(OP_CHECKSIG)
                .build();
    }

    @Override
    public Script createUnlockingScript(Transaction unsignedTransaction) {
        // TODO: Create Unlocking script (scriptSig)
        byte[] signature = sign(unsignedTransaction, key).encodeToBitcoin(); // potpisi transakciju sa ECKeyem
        return new ScriptBuilder()
                .data(signature)
                .data(key.getPubKey())
                .build();
        // sign vraca 2 komponenete koje encodeToBitcoin spaja u 1 (u 1 niz bajtova)
    }
}
