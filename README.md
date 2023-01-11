# Split Estate
Blockchain-based platform that allows anyone to be a landlord. It allows individuals to purchase fractions of apartment complexes, and earn a portion of the rent paid by tenants each month. Automates certain processes such as rent collection and distribution of profits.



![ESTATEsol](https://user-images.githubusercontent.com/100609687/211211693-534ef820-f1d5-4662-8175-8904f0db1726.png)


This protocol consists of three contracts.
1. Core
2. Property
3. Marketplace

# 1. Core 
Contract that acts as a router, and factory for deploying `Property` contracts. Most `Property` methods can ONLY be accessed through this contract.

<h2> Elements </h2>

uint8 `propertyCounter` - counter to increment id number

mapping(uint => address) `IDToProperty` -  mapping of property id number to property contract address.

<h2> Methods </h2>

```solidity
  function listProperty(string memory _location, uint256 _salePrice ) public 
```
**listProperty()** - allows users to sell properties to the contract shareholders. Deploys a new contract. takes arguments for location and sale price.

```solidity
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
```

Methods that allows users to interact with any Property of choice. Elements and functions called in this function are defined in `Property` contract. This improves ease of use and security.

# 2. Property
Contract that represents each property. implements erc20 methods.
<h2> Elements </h2>

uint256 `propertyID` - property ID number.

string `location` - location of property, set by owner in constructor.

uint256 `salePrice` - price of property in initial sale.

uint256 `profit` - estimate of profit per month. totalRent - monthlyBills = profit.

uint256 `deadline` - deadline to be sold by.

uint256 `sold` - indicator if property was successfully sold to SplitEstate (this contract, the shareholders).

uint256 `rentPaid` - indicator to show if all rent is paid each month.

uint256 `rentCounter` - counter to manage tenant rent payments.

uint256 `core` - instance of Core contract

uint256 `USDC` - instance of USDC token, always pegged to $1.

mapping(address=>uint) public `timeHeld` - mapping that tracks the length of time held by user, gets reset in transfer.

mapping(address=>uint) public `amtHeld` - mapping that tracks the amount fo time held by user, gets updated when calling claiming rent payments.
   
`Miscellaneous` erc20 elements like balances, allowances, totalSupply etc.


Generic erc20 functions:

<h2> Methods </h2>

```solidity

constructor(string memory _location, uint256 _salePrice, uint256 _propertyID ,string memory _ticker, address _owner, address _coreAddress) 
``` 
**Constructor()** Constructor that can only be called by core contract. Takes arguments for location, sale price, property id, the property id parsed into a string for the ticker, the owner of the property, and the address of the core contract.

```solidity
 function deposit(uint256 amount) public
```
**Deposit()** - Lets investors group buy a property. requires asking price has not been met yet. Transfers USDC tokens to be locked into contract. mints erc20 to represent share in property.


```solidity
    function soldWithdraw() public onlyOwner
```
**soldWithdraw()** - Method property owner would call to finalize sale. transfers USDC deposited by investors to seller. Sets ownership to shareholders.

```solidity
    function unsoldWithdraw() public
```
**unsoldwithDraw()** - method investors can call to claim their money back in a sale of a property has failed to be sold within the deadline.

```solidity

 function claimProfit() public

  function payRent(uint amount) public 
```
**payRent()** - method tenants can call to make rent payments.

```solidity
  function claimProfit() public
```
**claimProfit()** - Lets investors claim their rent profits. Can only be called once every 5 weeks. *Math logic in this method must be redone to work in solidity.*
calculates the amount of rent eligible for month, updates appropriate balances.

```solidity
  function _transfer(address from, address to, uint256 amount) internal virtual
```

**_transfer()** - custom erc20 function that resets timeHeld mappings.

```solidity
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }

.... continued
```

**Miscellaneous Methods** - generic erc20 functions 

# 3. Marketplace

An easy way for users to buy and sell shares of a property. Acts as an escrow which manages traditional english auction.

<h2> Elements </h2>

mapping(uint8=>sale) **IDtoSale** - mapping of sale/listing ID to sale struct.

uint8 `IDCounter` - increments Id number

```solidity
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
```

**sale** struct. Data structure which holds the saleID, the contract address of the property, the address of the seller, the price for the amount of shares, the deadline to be sold, the buyer of the sale, and an indicator marking if the shares are up for sale.

<h2> Methods </h2>

```solidity
  function newSale(address _property, uint256 price, uint256 amount, uint256 _deadline) public
```

**newSale()** - allows users to sell their shares, arguments are which property to sell, the price for the shares being sold, and the deadline to be sold. creates new `sale` struct.

```solidity
 function endSale(uint8 _saleID) public
```
**endsale()** - if a seller wants to end a sale

```solidity
  function buy(uint8 _saleID) public
```

**buy()** - allows a user to buy shares of a property another users is selling. transfers USDC payment to seller. buyer receives propery shares.







