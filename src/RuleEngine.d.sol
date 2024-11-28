// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.27;
import {console} from "forge-std/console.sol";
import "./BaseVersion.d.sol";
import "./BaseState.d.sol";
import "./BaseSymbol.d.sol";
import { IPayment } from "./IPayment.sol";

error RuleInvalid();

// Applies rules across all versions
contract RuleEngine {

    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

	// Rules (cell value vs function sel of rule in version)
	mapping(uint8 => bytes4) rules;

	// Add a rule
	function addRules(address codeAddress, BaseSymbolD.Symbols memory symbols) external {

		(bool ret, bytes memory selectors) = codeAddress.call(
			abi.encodeWithSignature("supportedStates()"));

		if (ret == false) {
			revert RuleInvalid();
		}

		// Check for number of symbols, it should be equal to number of states
		uint8 numSelectors;
		assembly {
			numSelectors := div(mload(add(selectors, 0x40)), 4) 
		}

		uint8 numSymbols;
		assembly {
			numSymbols := mload(add(symbols, 0x20))
		}
		assert(numSymbols == numSelectors);

		for (uint8 i = numSymbols; i > 0; i--) {

			// Append state symbol to default set cell call
			bytes4 _symbol;
			bytes2 _version;
			bytes6 _val;
			assembly {
				let ptr := add(symbols, 0x20)
				_val := mload(add(ptr, mul(i, 0x20)))
				_symbol := _val
				_version := shl(32, _val)
			}

			bytes memory func;

			if (_symbol == IPayment(address(this)).createChannel.selector) {
				func = abi.encodePacked("createChannel");
			}
			else if (_symbol == IPayment(address(this)).withdrawChannel.selector) {
				func = abi.encodePacked("withdrawChannel");
			}
			else {
				revert RuleInvalid();
			}

			func = abi.encodePacked(func, _version/*toSymbolString(_version, 2)*/);

			if (_symbol == IPayment(address(this)).createChannel.selector) {
				func = abi.encodePacked(func, "(address,bytes32,uint256,uint256,uint256)");
			}
			else if (_symbol == IPayment(address(this)).withdrawChannel.selector) {
				func = abi.encodePacked(func, "(address,bytes32,uint256)");
			}
				
			// Calulate the signature for set call function
			bytes4 sel = bytes4(keccak256(abi.encodePacked(func)));

			// Check if rule exists in the level contract
			bytes4 versionSel;
			assembly {
				let word := mload(add(selectors, 0x60))
				let shift := shr(sub(256, mul(i, 32)), word)
				versionSel := shl(224, and(shift, 0xFFFFFFFFFFFFFFFF))
			}

			assert(versionSel == sel);

			// Add the rule
			rules[i] = versionSel;
		}
	}

	// Setting a payment value as per the rule
	function setPayment(address versionAddress, uint8 a, uint8 b, uint8 c)
		internal returns(bool success) {

		// Check for valid address
		if (versionAddress == address(0)) {
			revert();
		}

		// Check if version contract exists
		assembly {
			if iszero(extcodesize(versionAddress)) {
				revert(0, 0)
			}
		}

		// Check for valid input state

		// Call version function to set payment via its selector
		bytes4 sel = rules[c];

		(success, ) = versionAddress.delegatecall(
						abi.encodeWithSelector(sel, a, b, c));
	}

	// 
	function toSymbolString(uint256 value, uint256 length) internal pure returns (string memory) {
	    uint256 localValue = value>>(30*8);

	    bytes memory buffer = new bytes(2 * length);
	    for (uint256 i = 0; i < (2 * length); i++) {
	        buffer[(2 * length) - 1 - i] = HEX_DIGITS[localValue & 0xf];
	        localValue >>= 4;
	    }
	    if (localValue != 0) {
	        revert ();
	    }
	    return string(buffer);
	}	
}