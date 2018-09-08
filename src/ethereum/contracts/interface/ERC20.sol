pragma solidity ^0.4.21;

interface ERC20{
    // Gets the total token supply
    function totalSuply() external view returns (uint256);

    // Gets the account balance for a supplied address(_owner)
    function balanceOf(address _owner) external view returns (uint256);

    // Transfers a supplied amount(_value) to the given address(_to)
    function transfer(address _to, uint256 _value) external returns (bool success);

    // Transfers the amount(_value) from one address(_from) to other(_to)
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    // Allows _spender to withdraw from your account, multiple times, up to the _value amount.
    // If the function is called again then it overwrites the current allowance with _value
    function approve(address _spender, uint256 _value) external returns (bool success);

    // Returns the amount that a spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // Triggered when tokens are transfered
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve function is called
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}