//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

contract MyContract {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        address owner = _msgSender();
        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "TokenContract: allowance from owner must be greater than amount");
            _allowances[owner][spender] -= amount;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "TokenContract: balance from owner must be greater than transfer amount");
        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _msgSender() internal view returns (address) {
      return msg.sender;
    }
}
