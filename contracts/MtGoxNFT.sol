// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./strings.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFT is ERC721Enumerable, Ownable {
	using strings for *;

	mapping(uint256 => uint256) _fiatWeight;
	mapping(uint256 => uint256) _satoshiWeight;
	mapping(address => bool) _issuers;

	constructor() ERC721("MtGoxNFT", "MGN") {
	}

	function _baseURI() internal pure override returns (string memory) {
		return "https://token.mtgoxnft.net/info/";
	}

	// issue will issue a NFT based on a given message
	function issue(string memory message, bytes memory signature) public {
		bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked(message));
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
		require(error == ECDSA.RecoverError.NoError && _issuers[recovered]);

		// parse message so we know the recipient addr, nft id, fiat balance and satoshi balance
		// Format: MtGoxNFT,NFT_ID,address,fiat_weight,satoshi_weight
		// Example: MtGoxNFT,999999,0x17Ab1f88C4C90E5A5290cFb8550CDa1279E84531,123456789,123456789

		strings.slice memory s = message.toSlice();
		strings.slice memory delim = ",".toSlice();
		string[] memory parts = new string[](s.count(delim) + 1);

		for(uint i = 0; i < parts.length; i++) {
			parts[i] = s.split(delim).toString();
		}

		// success
		_mint(_msgSender(), 1); // _mint will fail if this NFT was already issued
		_fiatWeight[1] = 1;
		_satoshiWeight[1] = 1;
	}

	function tokenFiatWeight(uint256 tokenId) public view returns (uint256) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent token");

		return _fiatWeight[tokenId];
	}

	function tokenSatoshiWeight(uint256 tokenId) public view returns (uint256) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent token");

		return _satoshiWeight[tokenId];
	}

	function grantIssuer(address account) public onlyOwner {
		_issuers[account] = true;
	}

	function revokeIssuer(address account) public onlyOwner {
		delete _issuers[account];
	}
}

