// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface MtGoxInfoApi {
	function fiatWeight(uint256) external view returns (uint64);
	function satoshiWeight(uint256) external view returns (uint64);
	function registrationDate(uint256) external view returns (uint32);
	function tradeVolume(uint256) external view returns (uint256);
	function getUrl(uint256) external view returns (string memory);
}

interface MtGoxNFTmetaLinkInterface {
	function tokenURI(MtGoxInfoApi, uint256) external view returns (string memory);
	function contractURI(MtGoxInfoApi) external view returns (string memory);
}
