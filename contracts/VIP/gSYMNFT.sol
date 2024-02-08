// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title gSYMNFT
 * @dev This contract allows the creation of governance NFTs that represent staked SYM tokens.
 */
contract gSYMNFT is ERC721Enumerable, Ownable {
    mapping(uint256 => uint256) private _stakedSYM;

    event gSYMMinted(address indexed to, uint256 indexed tokenId, uint256 stakedAmount);
    event gSYMUpdated(uint256 indexed tokenId, uint256 newStakedAmount);

    constructor() ERC721("gSYMGovernanceToken", "gSYM") {}

    function mint(address to, uint256 tokenId, uint256 stakedAmount) public onlyOwner {
        require(to != address(0), "gSYMNFT: mint to the zero address");
        require(!_exists(tokenId), "gSYMNFT: token already minted");

        _mint(to, tokenId);
        _stakedSYM[tokenId] = stakedAmount;
        
        emit gSYMMinted(to, tokenId, stakedAmount);
    }

    function updateStakedSYM(uint256 tokenId, uint256 newStakedAmount) public onlyOwner {
        require(_exists(tokenId), "gSYMNFT: tokenId does not exist");
        
        _stakedSYM[tokenId] = newStakedAmount;
        
        emit gSYMUpdated(tokenId, newStakedAmount);
    }

    function getStakedSYM(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "gSYMNFT: tokenId does not exist");

        return _stakedSYM[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
