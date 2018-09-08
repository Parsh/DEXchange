pragma solidity ^0.4.21;

import "./DEXtoken.sol";

contract Exchange {

    // GENERAL STRUCTURE //
    
    struct Offer {
        uint amount;
        address who;
    }

    struct OrderBook {
        uint higherPrice;
        uint lowerPrice;

        mapping (uint => Offer) offers;

        uint offers_key;
        uint offers_lenght;
    }

    struct Token {
        address tokenContract;
        string symbolName;

        mapping (uint => OrderBook) buyBook;

        uint currentBuyPrice;
        uint lowestBuyPrice;
        uint amountBuyPrices;

        mapping (uint => OrderBook) sellBook;
        uint currentSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;

    }

    // supporting a max of 255 tokens...
    mapping (uint8 => Token) tokens;
    uint8 tokenIndex;

    // setting up the owner
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    // BALANCES //
    mapping (address => mapping (uint8 => uint)) tokenBalanceForAddress;
    mapping (address => uint) balanceEthForAddress;

    // EVENTS //

    // Deposit/Withdrawal Events
    event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event WithdrawalToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event DepositForEthRecieved(address indexed _from, uint _amount, uint _timestamp);
    event WithdrawalEth(address indexed _to, uint _amount, uint _timestamp);

    // Management Events
    event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);
}