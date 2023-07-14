//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {WalletUser} from "../src/Wallet.sol";
import {CentralPay} from "../src/CentralPay.sol";

contract Deploy is Script {
    function run() external returns (WalletUser, CentralPay) {
        uint256 privateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        WalletUser walletUser = new WalletUser();
        CentralPay centralPay = new CentralPay(
            address(walletUser),
            0x1c282ad416B28b88A311f72F4eC69270fF859Aa1,
            "tokenuri"
        );

        vm.stopBroadcast();
        return (walletUser, centralPay);
    }
}
