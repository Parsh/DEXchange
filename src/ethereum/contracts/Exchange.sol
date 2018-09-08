pragma solidity ^0.4.21;

import "./DEXtoken.sol";

contract Exchange {

    address public owner;

    constructor () public {
        owner = msg.sender;
    }
}