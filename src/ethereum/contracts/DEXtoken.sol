pragma solidity ^0.4.21;

import "./interface/ERC20.sol";

contract DEXtoken is ERC20 {
    string public constant symbol = "DEX";
    string public constant name = "DEX Token";
    uint8 public constant decimals = 0;
    uint256 public totalSupply = 1000000;

    address public owner;

    // Balances for each account
    mapping (address => uint256) balances;

    // Owner of an account approves the tranfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyOwner(){
        require(msg.sender == owner, "Access is limited to the owner of this account");
        _;
    }

    constructor () public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    // Gets the balance of a particular account
    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success){
        if (balances[msg.sender] >= _amount && _amount > 0 
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
            }
        else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to 
    // Pre-requisite: sender must have been approved (by _from) to transfer the tokens
    function tranferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount 
        && _amount > 0 && balances[_to] + _amount > balances[_to]){
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
}

