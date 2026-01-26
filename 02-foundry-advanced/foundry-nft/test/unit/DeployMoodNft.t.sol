// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../../script/DeployMoodNft.s.sol";

//import {MoodNft} from "../src/MoodNft.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft public deployer;

    function setUp() public {
        deployer = new DeployMoodNft();
    }

    function testConvertSvgToUri() public view {
        string
            memory expectedUri = "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgMjAwIDIwMCIgd2lkdGg9IjQwMCIgaGVpZ2h0PSI0MDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+IDxjaXJjbGUgY3g9IjEwMCIgY3k9IjEwMCIgZmlsbD0ieWVsbG93IiByPSI3OCIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIzIiAvPjxnIGNsYXNzPSJleWVzIj4gPGNpcmNsZSBjeD0iNzAiIGN5PSI4MiIgcj0iMTIiIC8+ICA8Y2lyY2xlIGN4PSIxMjciIGN5PSI4MiIgcj0iMTIiIC8+IDwvZz48cGF0aCBkPSJtMTM2LjgxIDExNi41M2MuNjkgMjYuMTctNjQuMTEgNDItODEuNTItLjczIiBzdHlsZT0iZmlsbDpub25lOyBzdHJva2U6IGJsYWNrO3N0cm9rZS13aWR0aDogMzsiIC8+PC9zdmc+";

        string
            memory svg = '<svg viewBox="0 0 200 200" width="400" height="400" xmlns="http://www.w3.org/2000/svg"> <circle cx="100" cy="100" fill="yellow" r="78" stroke="black" stroke-width="3" /><g class="eyes"> <circle cx="70" cy="82" r="12" />  <circle cx="127" cy="82" r="12" /> </g><path d="m136.81 116.53c.69 26.17-64.11 42-81.52-.73" style="fill:none; stroke: black;stroke-width: 3;" /></svg>';

        string memory actualUri = deployer.svgToImageURI(svg);

        assert(
            keccak256(abi.encodePacked(expectedUri)) ==
                keccak256(abi.encodePacked(actualUri))
        );
    }
}
