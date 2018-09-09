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

    // BALANCES //
    
    mapping (address => mapping (uint8 => uint)) tokenBalanceForAddress;
    mapping (address => uint) balanceEthForAddress;

    // EVENTS //

    // Deposit/Withdrawal Events
    event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event WithdrawalToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);

    event DepositForEthRecieved(address indexed _from, uint _amount, uint _timestamp);
    event WithdrawalEth(address indexed _to, uint _amount, uint _timestamp);

    // Order Events
    event LimitSellOrderCreated(uint indexed _sumbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);

    event SellOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);

    event SellOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

    event LimitBuyOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);

    event BuyOrderCanceled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

    // Management Events
    event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);
    
    // setting up the owner
    address public owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner of the Exchange is allowed to perform the following operation");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    // DEPOSIT AND WITHDRAWAL ETHER //
    
    function depositEther() public payable{
        require(balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender], "Checking for overflow");
        balanceEthForAddress[msg.sender] += msg.value;
        emit DepositForEthRecieved(msg.sender, msg.value, now);
    }

    function withdrawEther(uint _amountInWei) public {
        require(balanceEthForAddress[msg.sender] - _amountInWei > 0, "Insufficient Eth Balance");
        require(balanceEthForAddress[msg.sender] - _amountInWei <= balanceEthForAddress[msg.sender], "Checking for underflow");
        balanceEthForAddress[msg.sender] -= _amountInWei;
        msg.sender.transfer(_amountInWei);
        emit WithdrawalEth(msg.sender, _amountInWei, now);
    }

    function getEthBalanceInWei() public view returns (uint){
        return balanceEthForAddress[msg.sender];
    }

    // TOKEN MANAGEMENT //
    
    function addToken(string _symbolName, address _erc20TokenAddress) public onlyOwner {
        require(!hasToken(_symbolName), "Token already present");
        require(tokenIndex + 1 > tokenIndex, "Chekcing for overflow");
        tokenIndex++;
        
        tokens[tokenIndex].symbolName = _symbolName;
        tokens[tokenIndex].tokenContract = _erc20TokenAddress;
        emit TokenAddedToSystem(tokenIndex, _symbolName, now);
    }
    
    function hasToken(string _symbolName) view public returns (bool) {
        uint8 index = getSymbolIndex(_symbolName);
        if (index == 0){
            return false; //Token is not present
        }
        return true;
    }
    
    function getSymbolIndex(string _symbolName) internal view returns (uint8) {
        for (uint8 i = 1; i <= tokenIndex; i++){
            if (stringsEqual(tokens[i].symbolName, _symbolName)){
                return i;
            }
        }
        return 0;
    }
    
    function getSymbolIndexOrThrow(string _symbolName) public view returns (uint8) {
        uint8 index = getSymbolIndex(_symbolName);
        require(index > 0, "Token not present");
        return index;
    }
    
    function stringsEqual(string _a, string _b) internal pure returns (bool) {
        return keccak256(_a) == keccak256(_b);
    }
    
}