// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "src/VersionConfigurator.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestVersionConfigurator is Test {
    using ECDSA for bytes32;
    address admin;
    VersionConfigurator versionConfig;

    function setUp() public {
        
        uint256 privKeyAdmin = 0xabc123;
        admin = vm.addr(privKeyAdmin);

        versionConfig = new VersionConfigurator(admin);
    }

    // Generates version number
    function _generateVersionNum(uint8 _num) internal pure
        returns (bytes memory _versionNum) {

        if (_num == 1)
            _versionNum = abi.encodePacked(_num);
        else if (_num == 2) 
            _versionNum = abi.encodePacked(_num);
    }

    // Generates state for a version
    function _generateState(uint8 _num) internal pure
        returns (bytes memory _versionState) {

        bytes32 trustAnchor;
        uint256 amount;
        uint256 numberOfTokens;
        uint256 withdrawAfterBlocks;

        if (_num == 1) {
            amount = 20000;
            numberOfTokens = 4000;
            withdrawAfterBlocks = 100;

            _versionState = abi.encodePacked(trustAnchor, amount,
                            numberOfTokens, withdrawAfterBlocks);
        }
        else if (_num == 2) {
            amount = 30000;
            numberOfTokens = 5000;
            withdrawAfterBlocks = 200;

            _versionState = abi.encodePacked(trustAnchor, amount,
                            numberOfTokens, withdrawAfterBlocks);            
        }
    }

    // Generates symbols for a version
    function _generateSymbols(uint8 _num) internal pure
        returns (bytes memory _versionSymbols) {

        if (_num == 1) {
            bytes6 createChannelV1 = bytes6(abi.encodePacked(hex"f26be922", "V1"));
            bytes6 withdrawChannelV1 = bytes6(abi.encodePacked(hex"8d7cb017", "V1"));
            _versionSymbols = abi.encodePacked(createChannelV1, withdrawChannelV1);
        }
        else if (_num == 2) {
            bytes6 createChannelV2 = bytes6(abi.encodePacked(hex"f26be922", "V2"));
            bytes6 withdrawChannelV2 = bytes6(abi.encodePacked(hex"8d7cb017", "V2"));
            _versionSymbols = abi.encodePacked(createChannelV2, withdrawChannelV2);
        }
    }

    // Test if the contract was created properly
    function test_levelCofigurator() external {


    }

    // Test Version contents
    function test__checkVersionValidity() external {

        bytes memory number = _generateVersionNum(1);
        bytes memory state = _generateState(1);
        bytes memory symbols = _generateSymbols(1);

        versionConfig._checkVersionValidity(number, state, symbols);
    }

}