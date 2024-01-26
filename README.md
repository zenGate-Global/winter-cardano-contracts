# winter-protocol

These contracts allow data to be securly and immutably saved and saved.

## Main requirements

These are the main requirements the contracts need to fulfil:

- Allow minting and burning of singleton
- Preserve datum data during recreation
- Allow authorized addresses to interact with contract
- Allow destruction of contract

## Validators

### singleton

This validator ensures onlt one unique singleton can be minted. 
It also allows for burn of respective singleton.

## object_event

This validator allows for two things: 

- Recreation of utxo where datum is preserved and singleton is transferred
- Destruction of utxo where lovelace is extracted and singleton is burned

### Recreation

- lovelace of new utxo is greater than or equal to current utxo
- singleton is transferred
- datum is preserved
   - creation info is the txId of the original tx. Only the first utxo is empty, the rest must
     always point to the original tx.
- At least one signer in datum must be facilitating the transaction
- winter fee must be paid

### Spending

- singleton must be burned
- winter fee must be paid
- At least one signer in datum must be facilitating the transaction

## Building

```sh
aiken build
```

## Testing

To run all tests, simply do:

```sh
aiken check
```

To run only tests matching the string `foo`, do:

```sh
aiken check -m foo
```
