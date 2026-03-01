---
title: PasswordStore Vulnerability Assessment
author: Cyfrin.io-Student-Elechukwu
date: January 22, 2026

header-includes:
  - \usepackage{longtable}
  - \makeatletter
  - \def\LTcaptype{table}
  - \makeatother
  - 
---

<!-- Your report starts here! -->

Prepared by: [Cyfrin][Elechukwu](https://cyfrin.io)(https://github.com/Azel-C/Blockchain-Training)
Lead Auditors: 
- xxxxxxx

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
    - [\[H-1\] Storing the password on-chain makes it visible to anyone, and no longer private](#h-1-storing-the-password-on-chain-makes-it-visible-to-anyone-and-no-longer-private)
    - [\[H-2\] `PasswordStore::setPassword` has no access controls, meaning non-owner could change the password.](#h-2-passwordstoresetpassword-has-no-access-controls-meaning-non-owner-could-change-the-password)
  - [Informational](#informational)
    - [\[I-1\] The `PasswordStore::setPassword` natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect.](#i-1-the-passwordstoresetpassword-natspec-indicates-a-parameter-that-doesnt-exist-causing-the-natspec-to-be-incorrect)

# Protocol Summary

PasswordStore is a protocol dedicated to storage and retrival of user's passwords. The protocol is designed to be used by a single user, and not designed to be used by multiple user's. Only the owner should be able to set and access the password.


# Disclaimer

The Elechukwu team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 

**The findings described in this document correspond the following commit hash:**
```
    2e8f81e263b3a9d18fab4fb5c46805ffc10a9990
```

## Scope 
```
./src/
#-- PasswordStore.sol
```

## Roles

- Owner: The user who can set the password and read the password.
- Outsider: No one else should be able to read or update the password.
  
# Executive Summary

## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| Highs    | 2                      |
| Mediums  | 0                      |
| Lows     | 0                      |
| Info     | 1                      |
| Total    | 3                      |

# Findings

## High
### [H-1] Storing the password on-chain makes it visible to anyone, and no longer private

**Description:** All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` varible is intended to be a private varible and only accessed through the `PasswordStore::getPassword` function, which is intened to be only called by the owner of the contract.

We show one such method of reading data off chain below.


**Impact:** Anyone can read the private password, which severly break the functionality of the protocol.


**Proof of Concept:** (Proof of Code)

The below test case shows anyone can read the password directly from the blockchain. 

1. Create a locally runing chain
```bash
make Anvil
```

2. Deploy the contract to chain
```
make deploy
```

3. Run the storage tool
we use `1` because that's the stroage slot of `s_password` in the contract.

```
cast storage <ADDRESS_HERE> 1 --rpc-url http://127.0.0.1:8545

```
you'll get an output like this

`0x6d7950617373776f726400000000000000000000000000000000000000000014`

you can then parse the hex to a string, like this:

```
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014

```
And get an output of:

```
myPassword
```

**Recommended Mitigation:**  Due to this, the overall architecture of the contract should be rethought. one could encrypt the password of-chain, and then strore the encrypted password on-chain. this will require the user to remember another password off-chain to decrypt the password. However, you'd also want to remove the view function, as you wouldn't want the user to accidentally send transaction with the password that decrypts your password.




### [H-2] `PasswordStore::setPassword` has no access controls, meaning non-owner could change the password.

**Description:** The `PasswordStore::setPassword` function is set to be an external function, howerver, the natspec of the function and overall purpose of the Smart Contract is that `This function allows only the owner to set a new password.`

```javascript
function setPassword(string memory newPassword) external {
@>  // @audit: There is no access controls
        s_password = newPassword;
        emit SetNetPassword();
    }
```

**Impact:** Anyone can set/change the password of the contract, severly breaking the contract intended functionality.

**Proof of Concept:** Add the following to `PasswordStore.t.sol` test file.
<details>
<summary>Code</summary>

```javascript
function test_anyone_can_set_password(address randomAddress) public {
        vm.assume(randomAddress != owner);
        vm.prank(randomAddress);
        string memory newPassword = "hackedPassword";
        passwordStore.setPassword(newPassword);

        vm.prank(owner);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, newPassword);
    }
```    
</details>

**Recommended Mitigation:**  Add an access control conditional to the `setPassword` function.

```javascript

if(msg.sender != s_owner){
  revert PasswordStore_NotOwner
}
```

 
## Informational
 ### [I-1] The `PasswordStore::setPassword` natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect.

**Description:** 

```javascript
    /*
     * @notice This allows only the owner to retrieve the password.
     * @param newPassword The new password to set.
     */
    function getPassword() external view returns (string memory) {
``` 

The `PasswordStore::getPassword` function signature is `getPassword` which the natspec say it should be `getPassword(string)`.

**Impact:**  The natspec is incorrect.


**Recommended Mitigation:**  Remove the incorrect natspec line.

```diff
-  * @param newPassword The new password to set.
```