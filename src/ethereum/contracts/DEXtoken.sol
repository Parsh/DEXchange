pragma solidity ^0.4.21;

import "./ERC20Interface.sol";

contract DEXtoken is ERC20Interface {
    string public constant symbol = "DEX";
    string public constant name = "DEX Token";
    uint8 public constant decimals = 0;
    uint256 public totalSupply = 1000000;

    address public owner;

    // Balances for each account
    mapping (address => uint256) balances;

    // Allowance from an owner's account to another account
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyOwner(){
        require(msg.sender == owner, "Access is limited to the owner of this account");
        _;
    }

    constructor () public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply;
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
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
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

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount. 
    //If this function is called again then it overwrites the current allowance.
    function approve(address _spender, uint256 _amount) public onlyOwner() returns (bool success){
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}

