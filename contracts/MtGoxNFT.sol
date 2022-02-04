// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFT is ERC721Enumerable, Ownable {
	mapping(address => bool) _issuers;

	// meta-data stored for each NFT
	struct MetaInfo {
		uint64 _fiatWeight;
		uint64 _satoshiWeight;
		uint32 _registrationDate;
	}
	mapping(uint256 => MetaInfo) private _meta;

	constructor() ERC721("MtGoxNFT", "MGN") {
	}

	function _baseURI() internal pure override returns (string memory) {
		return "https://token.mtgoxnft.net/info/";
	}

	// issue will issue a NFT based on a given message
	function issue(uint256 nftId, address recipient, uint64 fiatWeight, uint64 satoshiWeight, uint32 regDate, bytes memory signature) public {
		// first, check the signature using computeSignature
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(computeSignature(nftId, recipient, fiatWeight, satoshiWeight, regDate), signature);
		require(error == ECDSA.RecoverError.NoError && _issuers[recovered]);

		// success
		_mint(recipient, nftId); // _mint will fail if this NFT was already issued
		_meta[nftId] = MetaInfo({
			_fiatWeight: fiatWeight,
			_satoshiWeight: satoshiWeight,
			_registrationDate: regDate
		});
	}

	function computeSignature(uint256 nftId, address recipient, uint64 fiatWeight, uint64 satoshiWeight, uint32 regDate) public view returns (bytes32) {
		// The signature contains the following elements:
		// name() "MtGoxNFT", NULL, nftId, recipient(address), fiatWeight, satoshiWeight
		return ECDSA.toEthSignedMessageHash(abi.encode(name(), uint8(0), nftId, recipient, fiatWeight, satoshiWeight, regDate));
	}

	function tokenFiatWeight(uint256 tokenId) public view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent token");

		return _meta[tokenId]._fiatWeight;
	}

	function tokenSatoshiWeight(uint256 tokenId) public view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent token");

		return _meta[tokenId]._satoshiWeight;
	}

	function tokenRegistrationDate(uint256 tokenId) public view returns (uint32) {
		require(_exists(tokenId), "MtGoxNFT: registration datequery for nonexistent token");

		return _meta[tokenId]._registrationDate;
	}

	function grantIssuer(address account) public onlyOwner {
		_issuers[account] = true;
	}

	function revokeIssuer(address account) public onlyOwner {
		delete _issuers[account];
	}
}

