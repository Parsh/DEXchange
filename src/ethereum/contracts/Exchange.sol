pragma solidity ^0.4.21;

import "./interface/ERC20Interface.sol";
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
        uint offers_length;
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


    // ORDER BOOK - BID(BUY) ORDERS //

    function getBuyOrderBook(string _symbolName) public view returns (uint[], uint[]){
        uint8 tokenNameIndex = getSymbolIndexOrThrow(_symbolName);
        uint[] memory arrPricesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);
        uint[] memory arrVolumesBuy = new uint[](tokens[tokenNameIndex].amountBuyPrices);

        uint whilePrice = tokens[tokenNameIndex].lowestBuyPrice;
        uint counter = 0;
        
        if (tokens[tokenNameIndex].currentBuyPrice > 0) {
            while (whilePrice <= tokens[tokenNameIndex].currentBuyPrice) {
                arrPricesBuy[counter] = whilePrice;
                uint volumeAtPrice = 0;
                uint offers_key = 0;

                offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                
                while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                    offers_key++;
                }

                arrVolumesBuy[counter] = volumeAtPrice;

                // moving to next while price
                if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].higherPrice) {
                    break;
                }
                else {
                    whilePrice = tokens[tokenNameIndex].buyBook[whilePrice].higherPrice;
                }
                counter ++;
            }
        }
        return (arrPricesBuy, arrVolumesBuy);
    }

    // ORDER BOOK - ASK ORDER //
    function getSellOrderBook(string _symbolName) public view returns (uint[], uint[]){
        uint8 tokenNameIndex = getSymbolIndexOrThrow(_symbolName);
        uint[] memory arrPricesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[tokenNameIndex].amountSellPrices);
        uint sellWhilePrice = tokens[tokenNameIndex].currentSellPrice;
        uint sellCounter = 0;
        if (tokens[tokenNameIndex].currentSellPrice > 0) {
            while (sellWhilePrice <= tokens[tokenNameIndex].highestSellPrice) {
                arrPricesSell[sellCounter] = sellWhilePrice;
                uint sellVolumeAtPrice = 0;
                uint sell_offers_key = 0;

                sell_offers_key = tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_key;
                while (sell_offers_key <= tokens[tokenNameIndex].sellBook[sellWhilePrice].offers_length) {
                    sellVolumeAtPrice += tokens[tokenNameIndex].sellBook[sellWhilePrice].offers[sell_offers_key].amount;
                    sell_offers_key++;
                }

                arrVolumesSell[sellCounter] = sellVolumeAtPrice;

                // moving to the next whilePrice
                if (tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice == 0) {
                    break;
                }
                else {
                    sellWhilePrice = tokens[tokenNameIndex].sellBook[sellWhilePrice].higherPrice;
                }
                sellCounter++;

            }
        }

        //sell part
        return (arrPricesSell, arrVolumesSell);
    }


    // NEW ORDER - BID(BUY) ORDER //
    
    function buyToken(string _symbolName, uint _priceInWei, uint _amount) public {
        uint8 tokenNameIndex = getSymbolIndexOrThrow(_symbolName);
        uint total_amount_ether_necessary = 0;
        
        if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].currentSellPrice > _priceInWei){
            // Limit Order: We don't have enough offers to fulfill the order

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
            emit LimitBuyOrderCreated(tokenNameIndex, msg.sender, _amount, _priceInWei, tokens[tokenNameIndex].buyBook[_priceInWei].offers_length);
            
        }
        else {
            //Market Order: current sell price is smaller or equal to buy price.

            uint total_amount_ether_available = 0;
            uint whilePrice = tokens[tokenNameIndex].currentSellPrice;
            uint amountNecessary = _amount;
            uint offers_key;
            while (whilePrice <= _priceInWei && amountNecessary > 0) {//we start with the smallest sell price.
                offers_key = tokens[tokenNameIndex].sellBook[whilePrice].offers_key;
                while (offers_key <= tokens[tokenNameIndex].sellBook[whilePrice].offers_length && amountNecessary > 0) {//and the first order (FIFO)
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount;

                    if (volumeAtPriceFromAddress <= amountNecessary) {
                        total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;

                        //overflow checks
                        require(balanceEthForAddress[msg.sender] >= total_amount_ether_available, "Don't have enough ethers");
                        require(balanceEthForAddress[msg.sender] - total_amount_ether_available <= balanceEthForAddress[msg.sender], "Underflow check");
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[msg.sender][tokenNameIndex], "Token Overflow");
                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_available >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who], "Ether Overflow");

                        //this guy offers less or equal the volume that we ask for, so we use it up completely.
                        balanceEthForAddress[msg.sender] -= total_amount_ether_available;
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += volumeAtPriceFromAddress;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = 0;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_available;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers_key++;

                        emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                        amountNecessary -= volumeAtPriceFromAddress;
                    }
                    else {

                        total_amount_ether_necessary = amountNecessary * whilePrice;
                       
                        //overflow check
                        require(balanceEthForAddress[msg.sender] - total_amount_ether_necessary <= balanceEthForAddress[msg.sender], "Ether Underflow");
                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + total_amount_ether_necessary >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who], "Seller's Ether Overflow");
                        
                        //this seller offers more than the buyer ask for. Therefore, we reduce his stack and add the tokens to the buyer and the ether to him.
                        balanceEthForAddress[msg.sender] -= total_amount_ether_necessary;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += total_amount_ether_necessary;
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountNecessary;

                        amountNecessary = 0;
                        //fulfilled the buy order
                        emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);
                    }

                    
        }
    }
    
    // BID(BUY) LIMIT ORDER LOGIC //
    
    function addBuyOffer(uint8 _tokenIndex, uint _priceInWei, uint _amount, address _who) internal {
        tokens[_tokenIndex].buyBook[_priceInWei].offers_length++;
        tokens[_tokenIndex].buyBook[_priceInWei].offers[tokens[_tokenIndex].buyBook[_priceInWei].offers_length] = Offer({
            amount: _amount,
            who: _who
        });
        
        // If this is the first buyOffer in the buyBook corresponding to the given buy amount (_priceInWei) then..
        if (tokens[_tokenIndex].buyBook[_priceInWei].offers_length == 1) {
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
                
                uint buyPrice = tokens[_tokenIndex].currentBuyPrice;
                bool weFoundIt = false;
                
                // starting sellPrice as the highest price and moving down till we find the right spot
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
            emit LimitSellOrderCreated(tokenNameIndex, msg.sender, _amount, _priceInWei, tokens[tokenNameIndex].sellBook[_priceInWei].offers_length);
        }
        else {
            //Market Order: current buy price is bigger or equal to sell price!

            uint whilePrice = tokens[tokenNameIndex].currentBuyPrice;
            uint amountNecessary = _amount;
            uint offers_key;
            while (whilePrice >= _priceInWei && amountNecessary > 0) {//we start with the highest buy price.
                offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;
                while (offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length && amountNecessary > 0) {//and the first order (FIFO)
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;


                    if (volumeAtPriceFromAddress <= amountNecessary) {
                        //this guy offers less or equal the volume that we ask for, so we use it up completely.

                        total_amount_ether_available = volumeAtPriceFromAddress * whilePrice;

                        //overflow checks
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress, "Don't have enough token to sell");
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - volumeAtPriceFromAddress >= 0, "Token Underflow");
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + volumeAtPriceFromAddress >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex], "Buyer's Token Overflow");
                        require(balanceEthForAddress[msg.sender] + total_amount_ether_available >= balanceEthForAddress[msg.sender], "Ether Overflow");

                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= volumeAtPriceFromAddress;
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += volumeAtPriceFromAddress;

                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                        balanceEthForAddress[msg.sender] += total_amount_ether_available;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers_key++;
                        emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                        amountNecessary -= volumeAtPriceFromAddress;
                    }
                    else {
                        total_amount_ether_necessary = amountNecessary * whilePrice;
                        //we take the rest of the outstanding amount

                        //overflow check
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary, "Don't have enough tokens");
                        require(balanceEthForAddress[msg.sender] + total_amount_ether_necessary >= balanceEthForAddress[msg.sender], "Ether Overflow");
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + amountNecessary >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex], "Buyer's Token Overflow");

                        //this buyer wants to buy more than the seller has to sell. Therefore, we reduce buyer's stack, add the eth to seller and the token to the buyer.
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountNecessary;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                        balanceEthForAddress[msg.sender] += total_amount_ether_necessary;
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += amountNecessary;

                        emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);

                        amountNecessary = 0;
                        //we have fulfilled the sell order
                    }

                    //if it was the last offer for that price, we have to lower the currentBuyPrice.
                    // Additionally we now have one offer less...
                    if (
                    offers_key == tokens[tokenNameIndex].buyBook[whilePrice].offers_length &&
                    tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount == 0
                    ) {

                        tokens[tokenNameIndex].amountBuyPrices--;
                        //we have one price offer less here...
                        //next whilePrice
                        if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice || tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice == 0) {
                            tokens[tokenNameIndex].currentBuyPrice = 0;
                            //we have reached the last price
                        }
                        else {
                            tokens[tokenNameIndex].currentBuyPrice = tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice;
                            tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[tokenNameIndex].currentBuyPrice;
                        }
                    }
                    offers_key++;
                }
                // the currentBuyPrice is updated above, if we have completely used up the volume for the previous price.
                whilePrice = tokens[tokenNameIndex].currentBuyPrice;
            }

            if (amountNecessary > 0) {
                sellToken(_symbolName, _priceInWei, amountNecessary);
                //add a limit order, we couldn't fulfill all the orders!
            }

        }
    }
    
    // ASK(SELL) LIMIT ORDER LOGIC
    
    function addSellOffer(uint8 _tokenIndex, uint _priceInWei, uint _amount, address _who) internal {
        tokens[_tokenIndex].sellBook[_priceInWei].offers_length++;
        tokens[_tokenIndex].sellBook[_priceInWei].offers[tokens[_tokenIndex].sellBook[_priceInWei].offers_length] = Offer({
            amount: _amount,
            who: _who
        });
        
        // If this is the first sellOffer in the buyBook corresponding to the given sell amount (_priceInWei) then..
        if (tokens[_tokenIndex].sellBook[_priceInWei].offers_length == 1) {
            tokens[_tokenIndex].sellBook[_priceInWei].offers_key = 1;
            // we have a new sell order - increase the counter, so we can set the getOrderBook array later
            tokens[_tokenIndex].amountSellPrices++;
            
            // setting the lowerPrice (currentSellPrice is always the lowestSellPrice) and the higherPrice
            uint currentSellPrice = tokens[_tokenIndex].currentSellPrice;
            uint highestSellPrice = tokens[_tokenIndex].highestSellPrice;
            
            if (highestSellPrice == 0 || highestSellPrice < _priceInWei){
                if (currentSellPrice == 0){
                    // there is no sell order yet, we insert the first one
                    tokens[_tokenIndex].currentSellPrice = _priceInWei;
                    tokens[_tokenIndex].sellBook[_priceInWei].higherPrice = 0;
                    tokens[_tokenIndex].sellBook[_priceInWei].lowerPrice = 0;
                }
                else {
                    // this is highest sell order 
                    tokens[_tokenIndex].sellBook[highestSellPrice].higherPrice = _priceInWei;
                    tokens[_tokenIndex].sellBook[_priceInWei].lowerPrice = highestSellPrice;
                    tokens[_tokenIndex].sellBook[_priceInWei].higherPrice = 0;
                }
                tokens[_tokenIndex].highestSellPrice = _priceInWei;
            }
            else if (currentSellPrice > _priceInWei) {
                // the sell offer is the lowest one
                tokens[_tokenIndex].sellBook[currentSellPrice].lowerPrice = _priceInWei;
                tokens[_tokenIndex].sellBook[currentSellPrice].higherPrice = currentSellPrice;
                tokens[_tokenIndex].sellBook[currentSellPrice].lowerPrice = 0;
                tokens[_tokenIndex].currentSellPrice = _priceInWei;
            }
            else {
                // sell order is neither the highest nor the lowest, therefore, we would need to find the right spot
                uint sellPrice = tokens[_tokenIndex].currentSellPrice;
                bool weFoundIt = false;
                
                // starting sellPrice as the lowest price and moving up till we find the right spot
                while (sellPrice < _priceInWei && tokens[_tokenIndex].sellBook[sellPrice].higherPrice > _priceInWei) {
                    // set the new order-book entry's higher/lowerPrice
                    tokens[_tokenIndex].sellBook[_priceInWei].lowerPrice = sellPrice;
                    tokens[_tokenIndex].sellBook[_priceInWei].higherPrice = tokens[_tokenIndex].sellBook[sellPrice].higherPrice;
                    
                    // set the higherPrice'd order-book entry's lowerPrice to the current entry's price
                    tokens[_tokenIndex].sellBook[tokens[_tokenIndex].sellBook[sellPrice].higherPrice].lowerPrice = _priceInWei;
                    
                    //set the lowerPrice'd order-book entry's higherPrice to the current entry's price
                    tokens[_tokenIndex].sellBook[sellPrice].higherPrice = _priceInWei;
                    
                    weFoundIt = true;
                }
                sellPrice = tokens[_tokenIndex].sellBook[sellPrice].higherPrice;
            }
        }
    }

    // CANCEL LIMIT ORDER LOGIC //

    function cancelOrder(string _symbolName, bool _isSellOrder, uint _priceInWei, uint _offerKey) public {
        uint8 symbolNameIndex = getSymbolIndexOrThrow(_symbolName);
        if (_isSellOrder){
            require(tokens[symbolNameIndex].sellBook[_priceInWei].offers[_offerKey].who == msg.sender, "Only the creator of the sell order can cancel it");

            uint tokensAmount = tokens[symbolNameIndex].sellBook[_priceInWei].offers[_offerKey].amount;
            require(tokenBalanceForAddress[msg.sender][symbolNameIndex] + tokensAmount >= tokenBalanceForAddress[msg.sender][symbolNameIndex], "Token Overflow");

            tokens[symbolNameIndex].sellBook[_priceInWei].offers[_offerKey].amount = 0;
            tokenBalanceForAddress[msg.sender][symbolNameIndex] += tokensAmount;
            emit SellOrderCanceled(symbolNameIndex, _priceInWei, _offerKey);

        } else {
            require(tokens[symbolNameIndex].buyBook[_priceInWei].offers[_offerKey].who == msg.sender, "Only the creator of the buy order can cancel it");
            
            uint etherToRefund = tokens[symbolNameIndex].buyBook[_priceInWei].offers[_offerKey].amount * _priceInWei;
            require(balanceEthForAddress[msg.sender] + etherToRefund >= balanceEthForAddress[msg.sender], "Ether Overflow");

            tokens[symbolNameIndex].buyBook[_priceInWei].offers[_offerKey].amount = 0;
            balanceEthForAddress[msg.sender] += etherToRefund;
        }
    }
}