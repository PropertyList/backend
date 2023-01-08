// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract Property is Ownable {
    
    //property id number
    uint256 propertyID;
    //location of property, set by owner
    // 493 Apartment Way, Cleveland Ohio 48854
    string location;
    //price of property, set by owner
    uint256 salePrice;
    //amount of funds raised by potential owners on group buy
    // uint256 totalSupply will account for amount of ownership  (defined in ERC20.sol)
    //cost of rent estimate
    uint256 totalRent;
    //monthly bill estimate
    uint256 monthlyBills;
    //estimate of profit
    uint256 profit = totalRent - monthlyBills;
    //deadline to be sold by
    uint256 deadline;
    //indicator if property was successfully sold
    bool sold;
    //indicator to show if all rent is paid
    bool rentPaid;
    uint256 rentCounter;

    //track time held per investor
    //gets set to 0 every time there is a transfer
    mapping(address=>uint) public timeHeld;
    mapping(address=>uint) public amtHeld;
    
    address coreAddress;
    Core core = Core(coreAddress);

    //USDC instance on Polygon PoS
    IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);


    //ERC20 members
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;


    constructor(string memory _location, uint256 _salePrice, uint256 _propertyID ,string memory _ticker, address _owner, address _coreAddress) {
        
        location = _location;
        salePrice = _salePrice;
        propertyID = _propertyID;
        //sets seller as owner
        transferOwnership(_owner);


        coreAddress = _coreAddress;
        _symbol = _ticker;
        _name = "fractionalHome";
    }

    //lets users invest in a group buy
    function deposit(uint256 amount) public {
        // ADD require msg.sender is core
        require(msg.sender == coreAddress);
        //require asking price has not been met yet
        require(totalSupply() < salePrice);
        //transfer USDC tokens to be locked in contract
        USDC.transferFrom(tx.origin, address(this), amount);
        //mints erc20 as proof of investment/locking
        _mint(tx.origin, amount);
        //track owner hold time
        timeHeld[msg.sender] = block.timestamp;
    }

    //can only be called by seller if contract is sold
    function soldWithdraw() public onlyOwner {
      //can be called through core or directly
      require(msg.sender == owner() || tx.origin == owner());
      USDC.transferFrom(address(this), owner(), balanceOf(owner()));
      transferOwnership(address(this));
    }

    //function users can activate withdrawals if the auction fails
    function unsoldWithdraw() public {
        // ADD require msg.sender is core
        require(msg.sender == coreAddress);
        //require deadline for sale has passed
        require(block.timestamp > deadline);
        //require that property is unsold
        require(!sold);
        //get amount of shares to burn before burning (entire user balance)
        uint256 burnAmt = balanceOf(tx.origin);
        //burn tokens
        _burn(tx.origin, burnAmt);
        //transfer funds back to user
        USDC.transferFrom(address(this), tx.origin, burnAmt);
    }

    //tenants pay rent
    function payRent(uint amount) public {
        USDC.transferFrom(tx.origin,address(this),amount);
        rentCounter += amount;
        if(rentCounter == totalRent) {
            rentPaid = true;
        }
    }



    //for investors to claim profits
    function claimProfit() public {

        //needs to be redone for solidity math

        //timeHeld gets reset/ assigned every time claimProfit is called
        require(timeHeld[msg.sender] >= block.timestamp + 5 weeks);

        //calculate amount of rent eligble for per month
        //percentage of tokens owned
        uint shareOfRent = amtHeld[msg.sender] / totalSupply();

        //Amount of seconds held
        uint256 amtSecHeld =  block.timestamp - timeHeld[msg.sender];

        //amount of months held
        uint256 monthsHeld = amtSecHeld / 4 weeks;

        //amount of $ per month expected
        uint256 monthlyEstimate = totalRent * shareOfRent;

        //amount in $ sender is eligble for
        uint256 eligbleFor = monthlyEstimate * monthsHeld;

        //resets every claim
        timeHeld[msg.sender] = block.timestamp;

        //updates amount of tokens held
        amtHeld[msg.sender] = balanceOf(msg.sender);

        //send profit to sender
        USDC.transferFrom(address(this), msg.sender, eligbleFor);
    }


    //custom transfer function, resets timeHeld mapping
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
        //resets ownership time
        timeHeld[from] = 0;
        timeHeld[to] = block.timestamp;

        _spendAllowance(from, to, amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }


    //ERC20 methods

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
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);



}

//Acts as factory and router
//most property methods can only be accessed through this contract
contract Core {

    uint8 propertyCounter;

    mapping(uint8 => address) public IDToProperty;

    function listProperty(string memory _location, uint256 _salePrice ) public {
        

        //increment property counter
        propertyCounter++;

        //convert property number to 
        string memory _tickerString = Strings.toString(uint256(propertyCounter));

        //deploy new property contract
       // constructor(bytes memory _location, uint256 _salePrice, uint256 _propertyID ,string memory _ticker, address _owner, address _coreAddress)
        Property property = new Property(_location, _salePrice, propertyCounter, _tickerString, msg.sender, address(this));
        //assign property number to property
        IDToProperty[propertyCounter] = address(property);
    }

    function getProperty(uint8 id) public view returns (address) {
        return(IDToProperty[id]);
    }

    //most property methods can only be accessed through this contract
    function _deposit(uint8 id, uint amount) public {
        Property(IDToProperty[id]).deposit(amount);
    }

    function _soldWithdraw(uint8 id) public {
        Property(IDToProperty[id]).soldWithdraw();
    }

    function _unsoldWithdraw(uint8 id) public {
        Property(IDToProperty[id]).unsoldWithdraw();
    }

    function _payRent(uint8 id, uint256 _amount) public {
        Property(IDToProperty[id]).payRent(_amount);
    }

    function _claimProfit(uint8 id) public {
        Property(IDToProperty[id]).claimProfit();
    }

    //add a bunch of getter functions for frontend eventually


}


//Marketplace for users to buy and sell property
contract Marketplace {

    mapping(uint8=>sale) public IDtoSale;
    uint8 public IDcounter;
    //USDC instance on Polygon PoS
    IERC20 USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    struct sale {
        uint8 saleID;
        address property;
        address seller;
        uint256 salePrice;
        uint256 amount;
        uint256 deadline;
        //maybe add where you can have a custom buyer
        address buyer;
        bool forSale;
    }


    function newSale(address _property, uint256 price, uint256 amount, uint256 _deadline) public {
        //increment Id counter
        IDcounter++;
        //make new property instance depending on input address
        Property property = Property(_property);
        //transfer property tokens to this contract
        property.transferFrom(msg.sender, address(this), amount);

        //make new sale struct
        sale memory _sale = sale(IDcounter, _property, msg.sender, price, amount, _deadline, address(0), true);

        //map sale struct to ID
        IDtoSale[IDcounter] = _sale;

    }

    function endSale(uint8 _saleID) public {
        require(msg.sender == IDtoSale[_saleID].seller);
        IDtoSale[_saleID].forSale = false;
        address _property = IDtoSale[_saleID].property;
        Property(_property).transferFrom(address(this), IDtoSale[_saleID].seller, IDtoSale[_saleID].amount);
    }

    function buy(uint8 _saleID) public {

        //create instance of property
        Property _property = Property(IDtoSale[_saleID].property);

        //transfer USDC to seller
        USDC.transferFrom(msg.sender, IDtoSale[_saleID].seller, IDtoSale[_saleID].salePrice);

        //transfer property tokens to buyer
        _property.transferFrom(address(this), msg.sender, IDtoSale[_saleID].amount);

        //assign for sale status to false
        IDtoSale[_saleID].forSale = false;
        //records buyer of the auction
        IDtoSale[_saleID].buyer = msg.sender;

    }

}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
