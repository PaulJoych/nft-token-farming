// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@pancakeswap/core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap/periphery/contracts/interfaces/IPancakeRouter02.sol";

contract RimbaFarm is Ownable, ERC20, ERC721Holder {
    error NotRimbaToken();
    error NotTokenOwner();
    error NotEligibleToClaimReward();

    IERC721 sangRimbaNFT;

    address public rimbaV2Pair;

    uint256 stakingPeriod;
    uint256 stakingReward;

    IPancakeFactory public pancakeV2Factory;
    IPancakeRouter02 public pancakeV2Router;

    struct StakeInfo {
        address owner;
        uint256 stakedTimeStamp;
        uint256 lastClaim;
    }

    mapping(uint256 => uint8) RimbaTokenList;
    mapping(uint256 => StakeInfo) RimbaStakedList;

    constructor(address pancakeV2Router_, address sangRimbaNFT_)
        ERC20("Rimba Meat", "rMeat")
    {
        sangRimbaNFT = IERC721(sangRimbaNFT_);

        pancakeV2Router = IPancakeRouter02(pancakeV2Router_);
        pancakeV2Factory = IPancakeFactory(pancakeV2Router.factory());

        rimbaV2Pair = pancakeV2Factory.createPair(
            address(this),
            pancakeV2Router.WETH()
        );
    }

    function setRimbaTokenList(uint64[] memory ids_) external onlyOwner {
        unchecked {
            uint64[] memory list = ids_;
            for (uint256 i = 0; i < list.length; i++) {
                RimbaTokenList[list[i]] = 1;
            }
        }
    }

    function setStakingSetting(uint256 stakingPeriod_, uint256 stakingReward_)
        external
        onlyOwner
    {
        stakingPeriod = stakingPeriod_;
        stakingReward = stakingReward_;
    }

    function stakeRimba(uint256 tokenId_) external {
        if (RimbaTokenList[tokenId_] != 1) revert NotRimbaToken();

        StakeInfo memory data = RimbaStakedList[tokenId_];

        if (data.owner != address(0)) revert();
        if (sangRimbaNFT.ownerOf(tokenId_) != msg.sender) revert NotTokenOwner();

        RimbaStakedList[tokenId_].owner = msg.sender;
        RimbaStakedList[tokenId_].stakedTimeStamp = block.timestamp;
        RimbaStakedList[tokenId_].lastClaim = block.timestamp;

        // sangRimbaNFT.approve(address(this), tokenId_);
        sangRimbaNFT.safeTransferFrom(msg.sender, address(this), tokenId_);
    }

    function unStakeRimba(uint256 tokenId_) external {
        if (RimbaTokenList[tokenId_] != 1) revert NotRimbaToken();

        StakeInfo memory data = RimbaStakedList[tokenId_];
        if (data.owner != msg.sender) revert NotTokenOwner();

        delete RimbaStakedList[tokenId_];

        uint256 meatReward = callculateMeat(data.lastClaim);
        _mint(msg.sender, meatReward);

        // sangRimbaNFT.approve(msg.sender, tokenId_);
        sangRimbaNFT.safeTransferFrom(address(this), msg.sender, tokenId_);
    }

    function farmMeat(uint256 tokenId_) external {
        if (RimbaTokenList[tokenId_] != 1) revert NotRimbaToken();

        StakeInfo memory data = RimbaStakedList[tokenId_];

        if (!timeCheck(data.lastClaim)) revert NotEligibleToClaimReward();
        if (data.owner != msg.sender) revert NotTokenOwner();

        RimbaStakedList[tokenId_].lastClaim = block.timestamp;

        uint256 meatReward = callculateMeat(data.lastClaim);
        _mint(msg.sender, meatReward);
    }

    function callculateMeat(uint256 lastClaim_)
        internal
        view
        returns (uint256)
    {
        return
            ((block.timestamp - lastClaim_) / (stakingPeriod * 1 days)) *
            (stakingReward);
    }

    function timeCheck(uint256 lastClaim_)
        internal
        view
        returns (bool)
    {
        return (block.timestamp - lastClaim_) >= (stakingPeriod * 1 days);
    }
}
