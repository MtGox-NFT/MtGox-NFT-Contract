// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFT is ERC721Enumerable, Votes, Ownable {
	mapping(address => bool) _issuers;

	// meta-data stored for each NFT
	struct MetaInfo {
		uint64 fiatWeight;
		uint64 satoshiWeight;
		uint32 registrationDate;
	}
	mapping(uint256 => MetaInfo) private _meta;

	constructor() ERC721("MtGoxNFT", "MGN") EIP712("MtGoxNFT", "1") {
	}

	function _baseURI() internal pure override returns (string memory) {
		return "https://data.mtgoxnft.net/by-id/";
	}

	// issue will issue a NFT based on a given message
	function issue(uint256 tokenId, address recipient, uint64 paramFiatWeight, uint64 paramSatoshiWeight, uint32 paramRegDate, bytes memory signature) public {
		// first, check the signature using computeSignature
		(address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(computeSignature(tokenId, recipient, paramFiatWeight, paramSatoshiWeight, paramRegDate), signature);
		require(error == ECDSA.RecoverError.NoError && _issuers[recovered]);

		// success
		_mint(recipient, tokenId); // _mint will fail if this NFT was already issued
		_meta[tokenId] = MetaInfo({
			fiatWeight: paramFiatWeight,
			satoshiWeight: paramSatoshiWeight,
			registrationDate: paramRegDate
		});
	}

	function computeSignature(uint256 tokenId, address recipient, uint64 paramFiatWeight, uint64 paramSatoshiWeight, uint32 paramRegDate) public view returns (bytes32) {
		// The signature contains the following elements:
		// name() "MtGoxNFT", NULL, tokenId, recipient(address), fiatWeight, satoshiWeight
		return ECDSA.toEthSignedMessageHash(abi.encode(name(), uint8(0), block.chainid, address(this), tokenId, recipient, paramFiatWeight, paramSatoshiWeight, paramRegDate));
	}

	function fiatWeight(uint256 tokenId) public view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].fiatWeight;
	}

	function satoshiWeight(uint256 tokenId) public view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].satoshiWeight;
	}

	function registrationDate(uint256 tokenId) public view returns (uint32) {
		require(_exists(tokenId), "MtGoxNFT: registration datequery for nonexistent NFT");

		return _meta[tokenId].registrationDate;
	}

	function grantIssuer(address account) public onlyOwner {
		_issuers[account] = true;
	}

	function revokeIssuer(address account) public onlyOwner {
		delete _issuers[account];
	}

	// for votes
	function _afterTokenTransfer(
		address from,
		address to,
		uint256
	) internal virtual override {
		_transferVotingUnits(from, to, 1);
	}

	function _getVotingUnits(address account) internal virtual override returns (uint256) {
		return balanceOf(account);
	}
}
