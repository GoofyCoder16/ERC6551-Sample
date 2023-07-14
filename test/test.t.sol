//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {WalletUser} from "../src/Wallet.sol";
import {ERC6551Registry} from "../src/ERC6551Registry.sol";
import {CentralPay} from "../src/CentralPay.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract test is Test {
    Deploy deployer;
    WalletUser walletUser;
    ERC6551Registry erc551Registry;
    CentralPay centralPay;

    address USER = makeAddr("user");
    address USER_DIFF = makeAddr("user_diff");
    address ADMIN = makeAddr("admin");

    function setUp() external {
        deployer = new Deploy();
        erc551Registry = new ERC6551Registry();
        (walletUser, centralPay) = deployer.run();
    }

    //checks for proper functioning of the newWalletForNft method with an arbitrary tokenId and name and also checks that ownerOf(tokenId) has to be equal to msg.sender
    function testFailNewWalletForNft() external {
        vm.prank(USER);
        string memory name = "Bob";
        centralPay.newNFT(name);

        centralPay.newWalletforNFT(0, name);
        address addr = address(0xab);
        assert(centralPay.ownerOf(0) == addr);
    }

    //checks if the getAccount method fails when the name is not present in the s_nameToWalletAddr mapping.
    function testFailGetACcount() external {
        vm.startBroadcast();
        centralPay.getAccount("example");
        vm.stopBroadcast();
    }

    //checks whether the depositEthByAdmin method is functioning properly with arbitrary parameters.
    function testDepositEthByAdmin() external {
        uint256[] memory value = new uint256[](2);
        string[] memory name = new string[](2);
        address[] memory useCase = new address[](2);
        uint256 timePeriod = 10;

        value[0] = 1;
        value[1] = 2;

        name[0] = "A";
        name[1] = "B";

        useCase[0] = address(0xab);
        useCase[1] = address(0xcd);

        centralPay.depositEThByAdmin(value, name, useCase, timePeriod);
    }

    //checks if the withdraw method fails if the names present in the name[] list are not a part of the s_nameToWalletAddr mapping.
    function testFailWithdraw() external {
        string[] memory name = new string[](2);
        name[0] = "A";
        name[1] = "B";
        centralPay.withdraw(name);
    }

    //checks if the account method runs given arbitrary parameters of the concerned data types.
    function testAccount() external {
        vm.startBroadcast();
        erc551Registry.account(address(this), 31337, address(this), 123, 1000);
        vm.stopBroadcast();
    }

    //checks if the contructor of the wallet.sol contract correctly sets the value of i_owner.
    function testWalletConstructor() external {
        vm.startPrank(USER);
        walletUser = new WalletUser();
        address expectedResult = payable(USER);
        address payable actualResult = walletUser.i_owner();
        vm.stopPrank();

        assert(
            keccak256(abi.encodePacked(expectedResult)) ==
                keccak256(abi.encodePacked(actualResult))
        );
    }

    //Checks if given function fails when not called by the admin address.
    function testFailWithdrawEthByAdmin() external {
        vm.prank(USER);
        walletUser.withdrawEthByAdmin(USER);
    }

    function testFailSendEthToUseCase() external {
        vm.prank(USER);
        walletUser = new WalletUser();
    }
}
