# winter-protocol

# Winter Protocol

A set of Plutus V2 smart contracts written in Aiken for the Cardano blockchain. The Winter Protocol provides a secure and verifiable on-chain data management solution, allowing for the creation, update, and eventual destruction of a unique state object.

## Table of Contents
- [Overview](#overview)
- [Core Concepts](#core-concepts)
  - [The Singleton Token](#the-singleton-token)
  - [The Object Event UTXO](#the-object-event-utxo)
  - [The Datum](#the-datum)
- [Validators](#validators)
  - [1. `singleton`](#1-singleton)
  - [2. `object_event`](#2-object_event)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Building](#building)
  - [Testing](#testing)
- [License](#license)
- [Contributing](#contributing)


## Overview

The Winter Protocol is designed to anchor a unique, evolving piece of data to the blockchain. This is achieved through a combination of two validators: a `singleton` minting policy to create a unique NFT that acts as an access token, and an `object_event` validator that governs the stateful UTXO holding the data and the singleton NFT.

This system ensures that:
- A unique on-chain object can be created and identified.
- The object's associated data can be updated under strict, predefined rules.
- Only authorized parties (signers) can perform these actions.
- The entire system can be cleanly dismantled, burning the unique token.

## Core Concepts

### The Singleton Token
A key component of this protocol is a unique Non-Fungible Token (NFT), referred to as the "singleton". This token is minted by the `singleton` validator and its uniqueness is guaranteed by consuming a specific, one-time-use UTXO (`utxo_ref`) during its creation.

The singleton token always resides within the `object_event` UTXO, acting as a key and ensuring that only one such stateful UTXO can exist for a given singleton.

### The Object Event UTXO
This is the main stateful UTXO of the protocol, locked by the `object_event` validator. It holds:
1. The singleton token.
2. The `ObjectDatum`, which contains the protocol's state.
3. A minimum amount of lovelace.

### The Datum
The on-chain state is stored in the `ObjectDatum`. It has the following structure:

```aiken
// from lib/winter_protocol/datums.ak
pub type ObjectDatum {
  protocol_version: Int,
  data_reference: ByteArray,
  event_creation_info: Hash<Blake2b_256, Transaction>,
  signers: List<VerificationKeyHash>,
}
```
- `protocol_version`: A version number for the protocol, allowing for future upgrades.
- `data_reference`: A reference to the off-chain or on-chain data being anchored. This is the field that is expected to change during a "recreation" event.
- `event_creation_info`: The transaction ID of the initial creation transaction. This is set on the first recreation and remains immutable thereafter, acting as a permanent anchor to the object's origin.
- `signers`: A list of public key hashes of authorized parties who can sign for transactions that interact with the contract.

## Validators

### 1. `singleton`
This is a minting policy that controls the creation and destruction of the unique singleton token.

- **Purpose**: To guarantee that only one token with a specific `token_name` can ever be minted.
- **Redeemers**:
  - `Mint`: Allows minting exactly one token. Requires a specific `utxo_ref` to be spent in the same transaction, ensuring one-time minting.
  - `Burn`: Allows burning the token, which is required when the `object_event` UTXO is destroyed.
- **Source**: `validators/singleton.ak`

### 2. `object_event`
This validator script locks the stateful UTXO and enforces the core logic of the protocol.

- **Purpose**: Manages the lifecycle of the on-chain object, handling its recreation (update) and destruction.
- **Redeemers**:
  - `RecreateEvent`: To update the `ObjectDatum`.
  - `SpendEvent`: To destroy the contract state and burn the singleton.
- **Source**: `validators/object_event.ak`

#### `RecreateEvent` Rules
This action allows updating the `data_reference` for error correction or other state changes.
- The transaction must be signed by at least one of the authorized `signers` from the datum.
- A new `object_event` UTXO must be created at the same script address.
- The singleton token must be passed from the old UTXO to the new one.
- The lovelace value in the new UTXO must be greater than or equal to the lovelace in the current UTXO.
- The `ObjectDatum` must be correctly preserved or updated:
  - `protocol_version` and `signers` must remain the same.
  - `data_reference` must be different (as this is the point of recreation).
  - `event_creation_info` must be preserved (or set to the initial transaction ID if it was previously empty).
- A protocol fee must be paid to a predefined address.

#### `SpendEvent` Rules
This action allows the destruction of the on-chain object.
- The transaction must be signed by at least one of the authorized `signers` from the datum.
- The singleton token must be burned in the same transaction (amount = -1).
- A protocol fee must be paid to a predefined address.

## Getting Started

### Prerequisites
You need to have the [Aiken compiler](https://aiken-lang.org/getting-started/installation) installed and configured on your system. This project is configured to use Aiken `v1.0.26-alpha`.

### Building
To compile the contracts, run the following command from the root of the repository:
```bash
aiken build
```

This command type-checks the code and generates the compiled Plutus scripts and their metadata in the plutus.json file. This file is essential for building off-chain code and constructing transactions.

### Testing
run as such

```bash
aiken check
```

To run only tests matching a specific string, for example `foo`, use the `-m` flag:

```bash
aiken check -m foo
```

## License
[View License](LICENSE)

## Contributing
Contributions are welcome! If you find a bug or have a feature request, please open an issue. If you'd like to contribute code, please open a pull request.
