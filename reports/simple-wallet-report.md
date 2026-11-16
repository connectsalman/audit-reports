# Audit Report: SimpleWallet

## Summary
SimpleWallet lets anyone deposit ETH and lets only the owner withdraw all of it. This practice review found 5 issues: 2 Low and 3 Informational. No High or Medium issues were found.

## Scope
- File: SimpleWallet.sol (from the simple-wallet repo)
- Solidity ^0.8.20
- Method: manual review

## Findings Overview

| ID | Title | Severity |
|----|-------|----------|
| L-1 | No way to change the owner | Low |
| L-2 | Owner can be a contract that rejects ETH | Low |
| I-1 | No `receive()` function | Informational |
| I-2 | `withdraw` works with a zero balance | Informational |
| I-3 | Floating pragma | Informational |

## Findings

### [L-1] No way to change the owner

- Severity: Low
- Location: SimpleWallet.sol, `owner`

**Description**
`owner` is set once in the constructor, and no function can change it.

**Impact**
If the owner loses their key, the ETH in the wallet is locked forever.

**Proof of Concept**
1. Someone deposits ETH.
2. The owner loses access to their account.
3. Nobody else can call `withdraw`.

**Recommendation**
Add a `transferOwnership(address newOwner)` function protected by `onlyOwner`, and reject `address(0)`.

### [L-2] Owner can be a contract that rejects ETH

- Severity: Low
- Location: SimpleWallet.sol, `withdraw()`

**Description**
`withdraw` sends ETH to `owner` with a low-level call and reverts if it fails.

**Impact**
If the owner is a contract without a `receive()` function, `withdraw` always fails and the funds are stuck.

**Proof of Concept**
1. Deploy the wallet from a contract that cannot receive ETH.
2. Deposit ETH.
3. Call `withdraw`. It reverts with "Withdraw failed".

Foundry test: `poc/test/L2.t.sol` (`test_L2_fundsStuckIfOwnerRejectsEth`)

**Recommendation**
Allow the owner to be changed (see L-1), or add a `withdrawTo(address)` function.

### [I-1] No `receive()` function

- Severity: Informational
- Location: SimpleWallet.sol

**Description**
The wallet accepts ETH only through `deposit()`.

**Impact**
A plain ETH transfer to the wallet address is rejected. This is safe, but it can surprise users.

**Proof of Concept**
Send ETH to the wallet address from a normal wallet. The transfer fails.

**Recommendation**
Add a `receive()` function that does the same as `deposit()`, or document that only `deposit()` works.

### [I-2] `withdraw` works with a zero balance

- Severity: Informational
- Location: SimpleWallet.sol, `withdraw()`

**Description**
When the balance is 0, `withdraw` still sends 0 ETH and emits `Withdrawn(owner, 0)`.

**Impact**
There is no loss, but the event is misleading.

**Proof of Concept**
Call `withdraw` on a new wallet. It succeeds and emits an event with amount 0.

**Recommendation**
Add `require(amount > 0, "Nothing to withdraw");`.

### [I-3] Floating pragma

- Severity: Informational
- Location: SimpleWallet.sol, line 2

**Description**
`pragma solidity ^0.8.20;` allows many compiler versions.

**Impact**
The contract could be compiled with a different version than the one it was tested with.

**Proof of Concept**
Not needed, this is a code-style issue.

**Recommendation**
Pin the version, for example `pragma solidity 0.8.20;`.