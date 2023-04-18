// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Three.sol";
import "forge-std/Script.sol";

contract ThreeScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // Three completely random tokens and one completely random owner address
        Three three = new Three(
            0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84, // stETH
            0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32, // LDO
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
            0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c // Random button mashing
        );

        // three.file(5 * 10 ** 15, 975 * 10 * 15); Needs the owner to set this rate

        vm.stopBroadcast();
        vm.broadcast();
    }
}
