pragma solidity ^0.4.21;

import "./ERC20Interface.sol";
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
        require(balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender], "Ether overflow");
        balanceEthForAddress[msg.sender] += msg.value;
        emit DepositForEthRecieved(msg.sender, msg.value, now);
    }

    function withdrawEther(uint _amountInWei) public {
        require(balanceEthForAddress[msg.sender] - _amountInWei > 0, "Insufficient Eth Balance");
        require(balanceEthForAddress[msg.sender] - _amountInWei <= balanceEthForAddress[msg.sender], "Ether underflow");
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
        require(tokenIndex + 1 > tokenIndex, "Token Index Overflow");
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
    
    // DEPOSIT AND WITHDRAWAL TOKEN //
    
    function depositToken(string _symbolName, uint _amount) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(_symbolName);
        require(tokens[symbolNameIndex].tokenContract != address(0), "Token contract doesn't exist"); // redundant testing to asertain token existense

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);
        
        require(token.transferFrom(msg.sender, address(this), _amount) == true, "Insufficient allowance: can not transfer the give amount");
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + _amount >= tokenBalanceForAddress[msg.sender][symbolNameIndex], " Token Overflow");
        tokenBalanceForAddress[msg.sender][symbolNameIndex] += _amount;
        emit DepositForTokenReceived(msg.sender, symbolNameIndex, _amount, now);
    }
    
    function withdrawToken(string _symbolName, uint _amount) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(_symbolName);
        require(tokens[symbolNameIndex].tokenContract != address(0), "Token contract doesn't exist"); // redundant testing to asertain token existense

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);
        
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - _amount >= 0, "Insufficient tokens: cannot withdraw the given amount");
        require(tokenBalanceForAddress[msg.sender][symbolNameIndex] - _amount <= tokenBalanceForAddress[msg.sender][symbolNameIndex], "Token Underflow");
        
        tokenBalanceForAddress[msg.sender][symbolNameIndex] -= _amount;
        require(token.transfer(msg.sender, _amount) == true);
        emit WithdrawalToken(msg.sender, symbolNameIndex, _amount ,now);
    }
    
    function getTokenBalance(string _symbolName) public view returns (uint){
        uint8 symbolNameIndex = getSymbolIndexOrThrow(_symbolName);
        return tokenBalanceForAddress[msg.sender][symbolNameIndex];
    }
    
    // NEW ORDER - BID ORDER //
    
    function buyToken(string _symbolName, uint _priceInWei, uint _amount) public {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(_symbolName);
        uint total_amount_ether_necessary = 0;
        
        if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].currentSellPrice > _priceInWei){
            // Limit order: We don't have enough offers to fulfill the order

            // ethers required to buy the given amount of tokens
            total_amount_ether_necessary = _amount * _priceInWei;
            
            // overflow checks
            require(total_amount_ether_necessary >= _amount);
            require(total_amount_ether_necessary >= _priceInWei);
            require(balanceEthForAddress[msg.sender] >= total_amount_ether_necessary, "Insufficient ethers to buy the tokens");
            require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary >= 0, "Insufficient ethers to buy the tokens");
            require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary <= balanceEthForAddress[msg.sender], "Ether Underflow");
            
            // deduct the amount of ether from msg.sender's balance
            balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;
            
            // add the order to the OrderBook
            addBuyOffer(tokenNameIndex, _priceInWei, _amount, msg.sender);
            emit LimitBuyOrderCreated(tokenNameIndex, msg.sender, _amount, _priceInWei, tokens[tokenNameIndex].buyBook[_priceInWei].offers_lenght);
            
        }
        else {
            // TODO: Code for Market order
        }
    }
    
    // BID LIMIT ORDER LOGIC //
    
    function addBuyOffer(uint8 _tokenIndex, uint _priceInWei, uint _amount, address _who) internal {
        tokens[_tokenIndex].buyBook[_priceInWei].offers_lenght++;
        tokens[_tokenIndex].buyBook[_priceInWei].offers[tokens[_tokenIndex].buyBook[_priceInWei].offers_lenght] = Offer({
            amount: _amount,
            who: _who
        });
        
        // If this is the first buyOffer in the buyBook corresponding to the given amount (_priceInWei) then..
        if (tokens[_tokenIndex].buyBook[_priceInWei].offers_lenght == 1) {
            tokens[_tokenIndex].buyBook[_priceInWei].offers_key = 1;
            // we have a new buy order - increase the counter, so we can set the getOrderBook array later 
            tokens[_tokenIndex].amountBuyPrices++;
            
            // lowerPrice and higherPrice(highest price is always the current buy price) have to be set
            uint currentBuyPrice = tokens[_tokenIndex].currentBuyPrice;
            uint lowestBuyPrice = tokens[_tokenIndex].lowestBuyPrice;
            
            if (lowestBuyPrice == 0 || lowestBuyPrice > _priceInWei){
                if (currentBuyPrice == 0){
                    // there is no buy order yet, we are inserting the first one...
                    tokens[_tokenIndex].currentBuyPrice = _priceInWei;
                    tokens[_tokenIndex].buyBook[_priceInWei].higherPrice = _priceInWei;
                    tokens[_tokenIndex].buyBook[_priceInWei].lowerPrice = 0;
                }
                else {
                    // we are inserting the lowest buy order
                    tokens[_tokenIndex].buyBook[lowestBuyPrice].lowerPrice = _priceInWei;
                    tokens[_tokenIndex].buyBook[_priceInWei].higherPrice = lowestBuyPrice;
                    tokens[_tokenIndex].buyBook[_priceInWei].lowerPrice = 0;
                }
                tokens[_tokenIndex].lowestBuyPrice = _priceInWei;
            }
            else if (currentBuyPrice < _priceInWei){
                // the offer to buy is the highest one, therefore, inserting at the top
                tokens[_tokenIndex].buyBook[currentBuyPrice].higherPrice = _priceInWei;
                tokens[_tokenIndex].buyBook[_priceInWei].higherPrice = _priceInWei;
                tokens[_tokenIndex].buyBook[_priceInWei].lowerPrice = currentBuyPrice;
                tokens[_tokenIndex].currentBuyPrice = _priceInWei;
            }
            else {
                // the offer is neither the lowest nor highest, it's somewhere in the middle, therefore we need to find the right spot
                
                uint buyPrice = tokens[_tokenIndex].currentBuyPrice; // starting the buy price from the highest price
                bool weFoundIt = false;
                while (buyPrice > 0 && !weFoundIt) {
                    if (buyPrice < _priceInWei && tokens[_tokenIndex].buyBook[buyPrice].higherPrice > _priceInWei) {
                        // set the new order-book entry's higher/lowerPrice
                        tokens[_tokenIndex].buyBook[_priceInWei].lowerPrice = buyPrice;
                        tokens[_tokenIndex].buyBook[_priceInWei].higherPrice = tokens[_tokenIndex].buyBook[buyPrice].higherPrice;
                        
                        // set the higherPrice'd order-book entry's lowerPrice to the current entry's price
                        tokens[_tokenIndex].buyBook[tokens[_tokenIndex].buyBook[buyPrice].higherPrice].lowerPrice = _priceInWei;
                        
                        // set the lowerPrice'd order-book entry's higherPrice to the current entry's price
                        tokens[_tokenIndex].buyBook[buyPrice].higherPrice = _priceInWei;
                        
                        weFoundIt = true;
                    }
                    buyPrice = tokens[_tokenIndex].buyBook[buyPrice].lowerPrice;
                }
            }
        }   
    }
    
    // NEW ORDER - ASK(SELL) ORDER //
    
    function sellToken(string _symbolName, uint _priceInWei, uint _amount) public {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(_symbolName);
        uint total_amount_ether_necessary = 0;
        uint total_amount_ether_available = 0;
        
        if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].currentBuyPrice < _priceInWei){
            // Limit Order: We don't have enough offers to fulfill this sell order
            
            // if we have enough ether, we can buy that
            total_amount_ether_necessary = _amount * _priceInWei;
            
            // overflow checks
            require(total_amount_ether_necessary >= _amount);
            require(total_amount_ether_necessary >= _priceInWei);
            require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= _amount, "Insufficient token balance");
            require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - _amount >= 0, "Insufficient token balance");
            require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender], "Ether Overflow");
            
            // debit the amount of tokens
            tokenBalanceForAddress[msg.sender][tokenNameIndex]  -= _amount;
               
            // add the order to the orderBook
            addSellOffer(tokenNameIndex, _priceInWei, _amount, msg.sender);
            emit LimitSellOrderCreated(tokenNameIndex, msg.sender, _amount, _priceInWei, tokens[tokenNameIndex].sellBook[_priceInWei].offers_lenght);
        }
    }
}