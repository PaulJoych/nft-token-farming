// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/mocks/ERC721Mock.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


import { DSTest } from "ds-test/test.sol";

import { RimbaFarm } from "../RimbaFarm.sol";

interface CheatCodes {
    function warp(uint256) external;
}

contract ContractTest is DSTest, ERC721Holder{
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);


    RimbaFarm internal rimbaFarm;
    ERC721Mock internal rimbaNft;

    function setUp() public {
        rimbaNft = new ERC721Mock("Rimba NFT", "RMB");
        rimbaFarm = new RimbaFarm(0x10ED43C718714eb63d5aA57B78B54704E256024E, address(rimbaNft));

        rimbaFarm.setStakingSetting(1, 10);
    }

    function test_rimbapair() public {
        emit log_address(rimbaFarm.rimbaV2Pair());
    }

    function test_stakeRimba() public {
        uint64[] memory arr = new uint64[](1);
        arr[0] = 1;

        rimbaNft.safeMint(address(this), 1);
        rimbaNft.approve(address(rimbaFarm), 1);
        rimbaFarm.setRimbaTokenList(arr);
        rimbaFarm.stakeRimba(1);

        cheats.warp(block.timestamp + 1 days);
        rimbaFarm.farmMeat(1);

        assertEq(rimbaFarm.balanceOf(address(this)), 10);

        cheats.warp(block.timestamp + 5 days);
        rimbaFarm.farmMeat(1);

        assertEq(rimbaFarm.balanceOf(address(this)), 60);
    }

    function test_unstake() public {
        test_stakeRimba();

        rimbaFarm.unStakeRimba(1);
        assertEq(rimbaFarm.balanceOf(address(this)), 60);
        assertEq(rimbaNft.ownerOf(1), address(this));
    }
}
